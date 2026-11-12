<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Event;
use App\Models\EventApproval;
use App\Models\User;
use App\Services\EventNotificationService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EventController extends Controller
{
    /**
     * List Events with Search & Filters
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Event::with('organizer:id,email');

        // Organizer "My Events" filter
        if ($request->boolean('my_events') && !$user->isStudent()) {
            $query->where('organizer_id', $user->id);
        }

        // Role-based visibility
        if ($user->isStudent()) {
            $query->whereIn('status', ['published', 'ongoing']);

            // Filters
            if ($request->filled('search')) {
                $search = $request->query('search');
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('venue', 'like', "%{$search}%");
                });
            }

            if ($request->filled('date_from')) {
                $query->where('event_date', '>=', $request->query('date_from'));
            }

            if ($request->filled('date_to')) {
                $query->where('event_date', '<=', $request->query('date_to'));
            }

            $allEvents = $query->orderBy('event_date', 'asc')
                ->orderBy('start_time', 'asc')
                ->get()
                ->filter(function ($event) use ($user) {
                    return $event->isStudentEligible($user->student);
                })
                ->values();

            $perPage = max(1, min(100, (int) $request->query('per_page', 15)));
            $page = max(1, (int) $request->query('page', 1));
            $total = $allEvents->count();
            $items = $allEvents->slice(($page - 1) * $perPage, $perPage)->values();

            $studentId = $user->student?->id;
            $items->transform(function ($event) use ($studentId) {
                $registeredCount = $event->activeRegistrations()->count();
                $event->current_registered_count = $registeredCount;
                $event->remaining_slots = is_null($event->max_participants) ? null : max(0, $event->max_participants - $registeredCount);

                if ($studentId) {
                    $reg = $event->registrations()->where('student_id', $studentId)->first();
                    $event->user_registration_status = $reg?->status;
                    $event->user_waiting_position = $reg?->waiting_list_position;
                }

                return $event;
            });

            return response()->json([
                'success' => true,
                'data' => $items,
                'meta' => [
                    'current_page' => $page,
                    'last_page' => max(1, (int) ceil($total / $perPage)),
                    'per_page' => $perPage,
                    'total' => $total,
                ],
            ]);
        } elseif ($request->filled('status')) {
            $statuses = array_filter(explode(',', $request->query('status')));
            if (count($statuses) > 1) {
                $query->whereIn('status', $statuses);
            } else {
                $query->where('status', $statuses[0]);
            }
        }

        // Filters
        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('venue', 'like', "%{$search}%");
            });
        }

        if ($request->filled('date_from')) {
            $query->where('event_date', '>=', $request->query('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->where('event_date', '<=', $request->query('date_to'));
        }

        $events = $query->orderBy('event_date', 'asc')
            ->orderBy('start_time', 'asc')
            ->paginate($request->query('per_page', 15));

        // Append user-specific registration status and slot counts
        $studentId = $user->student?->id;
        $events->getCollection()->transform(function ($event) use ($studentId) {
            $registeredCount = $event->activeRegistrations()->count();
            $event->current_registered_count = $registeredCount;
            $event->remaining_slots = is_null($event->max_participants) ? null : max(0, $event->max_participants - $registeredCount);

            if ($studentId) {
                $reg = $event->registrations()->where('student_id', $studentId)->first();
                $event->user_registration_status = $reg?->status;
                $event->user_waiting_position = $reg?->waiting_list_position;
            }

            return $event;
        });

        return response()->json([
            'success' => true,
            'data' => $events->items(),
            'meta' => [
                'current_page' => $events->currentPage(),
                'last_page' => $events->lastPage(),
                'per_page' => $events->perPage(),
                'total' => $events->total(),
            ],
        ]);
    }

    /**
     * Audience Options for Event Targeting
     */
    public function audienceOptions(Request $request): JsonResponse
    {
        $defaultCourses = [
            'BS Information Technology',
            'BS Computer Science',
            'BS Civil Engineering',
            'BS Computer Engineering',
            'BS Accountancy',
            'BS Nursing',
            'BS Information Systems',
            'BS Business Administration',
            'BS Secondary Education',
        ];

        $defaultYearLevels = [
            '1st Year',
            '2nd Year',
            '3rd Year',
            '4th Year',
        ];

        $defaultCategories = [
            'Academic',
            'Cultural',
            'Sports',
            'Workshop',
            'Seminar',
            'General',
            'Career',
            'Community',
        ];

        $dbCourses = DB::table('students')
            ->whereNotNull('course')
            ->where('course', '!=', '')
            ->distinct()
            ->pluck('course')
            ->toArray();

        $dbYearLevels = DB::table('students')
            ->whereNotNull('year_level')
            ->where('year_level', '!=', '')
            ->distinct()
            ->pluck('year_level')
            ->toArray();

        $dbSections = DB::table('students')
            ->whereNotNull('section')
            ->where('section', '!=', '')
            ->distinct()
            ->pluck('section')
            ->toArray();

        $courses = array_values(array_unique(array_merge($defaultCourses, $dbCourses)));
        $yearLevels = array_values(array_unique(array_merge($defaultYearLevels, $dbYearLevels)));
        $sections = array_values(array_unique($dbSections));
        sort($sections);

        return response()->json([
            'success' => true,
            'data' => [
                'courses' => $courses,
                'year_levels' => $yearLevels,
                'sections' => $sections,
                'categories' => $defaultCategories,
            ],
        ]);
    }

    /**
     * View Single Event Details
     */
    public function show(int $id, Request $request): JsonResponse
    {
        $user = $request->user();
        $event = Event::with(['organizer:id,email', 'approvals'])->findOrFail($id);

        if ($user->isStudent()) {
            $hasHistory = $user->student && $event->registrations()->where('student_id', $user->student->id)->exists();
            if (!in_array($event->status, ['published', 'ongoing', 'completed'], true) && !$hasHistory) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_EVENT_NOT_ACTIVE',
                    'message' => 'This event is not published or available for viewing.',
                ], 403);
            }

            if (!$event->isStudentEligible($user->student)) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_AUDIENCE_INELIGIBLE',
                    'message' => 'You are not eligible to view or register for this event based on audience criteria.',
                ], 403);
            }
        } elseif (!$user->isAdmin() && !$user->isManagement()) {
            if (in_array($event->status, ['draft', 'pending_approval'], true) && $event->organizer_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_FORBIDDEN',
                    'message' => 'You do not have permission to view this unpublished event.',
                ], 403);
            }
        }

        $registeredCount = $event->activeRegistrations()->count();
        $eventData = $event->toArray();
        $eventData['current_registered_count'] = $registeredCount;
        $eventData['remaining_slots'] = is_null($event->max_participants) ? null : max(0, $event->max_participants - $registeredCount);

        if ($user->student) {
            $reg = $event->registrations()->where('student_id', $user->student->id)->first();
            $eventData['user_registration_status'] = $reg?->status;
            $eventData['user_waiting_position'] = $reg?->waiting_list_position;
        }

        return response()->json([
            'success' => true,
            'data' => $eventData,
        ]);
    }

    /**
     * Create New Event (Initial Status: draft)
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:200'],
            'description' => ['required', 'string'],
            'category' => ['nullable', 'string', 'max:50'],
            'cover_image_path' => ['nullable', 'string', 'max:255'],
            'venue' => ['required', 'string', 'max:200'],
            'event_date' => ['required', 'date', 'after_or_equal:today'],
            'start_time' => ['required', 'date_format:H:i:s,H:i'],
            'end_time' => ['required', 'date_format:H:i:s,H:i', 'after:start_time'],
            'registration_start' => ['required', 'date'],
            'registration_end' => ['required', 'date', 'after:registration_start'],
            'max_participants' => ['nullable', 'integer', 'min:1'],
            'late_grace_period_minutes' => ['nullable', 'integer', 'min:0', 'max:120'],
            'walk_in_allowed' => ['nullable', 'boolean'],
            'target_audience_type' => ['nullable', 'string', 'in:all,course,year_level,custom'],
            'target_courses' => ['nullable', 'array'],
            'target_courses.*' => ['string'],
            'target_year_levels' => ['nullable', 'array'],
            'target_year_levels.*' => ['string'],
            'target_sections' => ['nullable', 'array'],
            'target_sections.*' => ['string'],
            'target_rules' => ['nullable', 'array'],
            'target_rules.*' => ['array'],
            'send_announcement' => ['nullable', 'boolean'],
        ]);

        $validated['organizer_id'] = $request->user()->id;
        $validated['category'] = $validated['category'] ?? 'General';
        $validated['late_grace_period_minutes'] = $validated['late_grace_period_minutes'] ?? 15;
        $validated['walk_in_allowed'] = $validated['walk_in_allowed'] ?? false;
        $validated['target_audience_type'] = $validated['target_audience_type'] ?? 'all';
        $validated['send_announcement'] = $request->has('send_announcement') ? $request->boolean('send_announcement') : true;
        $validated['status'] = $request->boolean('save_as_draft') ? 'draft' : 'pending_approval';

        $event = Event::create($validated);

        ActivityLog::log('event_created', 'events', $event->id, [
            'title' => $event->title,
            'status' => $validated['status'],
        ]);

        return response()->json([
            'success' => true,
            'message' => $event->status === 'draft'
                ? 'Event draft saved. Submit for admin approval when ready.'
                : 'Event submitted for administrator review and approval.',
            'data' => $event,
        ], 201);
    }

    /**
     * Update Event Information
     */
    public function update(int $id, Request $request): JsonResponse
    {
        $event = Event::findOrFail($id);
        $user = $request->user();

        if (!$user->isAdmin() && $event->organizer_id !== $user->id) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'You may only edit events you organized.',
            ], 403);
        }

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:200'],
            'description' => ['sometimes', 'string'],
            'category' => ['sometimes', 'nullable', 'string', 'max:50'],
            'cover_image_path' => ['sometimes', 'nullable', 'string', 'max:255'],
            'venue' => ['sometimes', 'string', 'max:200'],
            'event_date' => ['sometimes', 'date'],
            'start_time' => ['sometimes', 'date_format:H:i:s,H:i'],
            'end_time' => ['sometimes', 'date_format:H:i:s,H:i'],
            'registration_start' => ['sometimes', 'date'],
            'registration_end' => ['sometimes', 'date'],
            'max_participants' => ['nullable', 'integer', 'min:1'],
            'late_grace_period_minutes' => ['sometimes', 'integer', 'min:0'],
            'walk_in_allowed' => ['sometimes', 'boolean'],
            'target_audience_type' => ['sometimes', 'string', 'in:all,course,year_level,custom'],
            'target_courses' => ['sometimes', 'nullable', 'array'],
            'target_courses.*' => ['string'],
            'target_year_levels' => ['sometimes', 'nullable', 'array'],
            'target_year_levels.*' => ['string'],
            'target_sections' => ['sometimes', 'nullable', 'array'],
            'target_sections.*' => ['string'],
            'target_rules' => ['sometimes', 'nullable', 'array'],
            'target_rules.*' => ['array'],
            'send_announcement' => ['sometimes', 'boolean'],
        ]);

        $event->update($validated);

        if ($event->status === 'published') {
            // Only students validly registered for this exact event are notified.
            EventNotificationService::notifyRegistered(
                $event,
                "Event Updated: {$event->title}",
                "Details for '{$event->title}' have been updated. Please check the event page for changes.",
                'event_updates'
            );
        }

        ActivityLog::log('event_updated', 'events', $event->id, [
            'title' => $event->title,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Event updated successfully.',
            'data' => $event,
        ]);
    }

    /**
     * Submit Event for Admin Publishing Approval
     */
    public function submitApproval(int $id, Request $request): JsonResponse
    {
        $event = Event::findOrFail($id);
        $user = $request->user();

        if ($event->organizer_id !== $user->id && !$user->isAdmin()) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'Only the event organizer or an admin may submit for approval.',
            ], 403);
        }

        if ($event->status !== 'draft') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_INVALID_STATE',
                'message' => 'Only draft events can be submitted for approval.',
            ], 422);
        }

        $event->update(['status' => 'pending_approval']);

        ActivityLog::log('event_submitted_for_approval', 'events', $event->id, [
            'title' => $event->title,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Event submitted for administrator review and approval.',
            'data' => ['status' => $event->status],
        ]);
    }

    /**
     * Admin Review Event Publishing (Approve or Reject)
     */
    public function reviewApproval(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'action' => ['required', 'in:approved,rejected'],
            'remarks' => ['nullable', 'string'],
        ]);

        $event = Event::findOrFail($id);

        if ($event->status !== 'pending_approval') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_INVALID_STATE',
                'message' => 'Event is not awaiting approval.',
            ], 422);
        }

        DB::transaction(function () use ($event, $validated, $request) {
            $newStatus = $validated['action'] === 'approved' ? 'published' : 'draft';
            $event->update(['status' => $newStatus]);

            EventApproval::create([
                'event_id' => $event->id,
                'admin_id' => $request->user()->id,
                'approval_type' => 'publish',
                'status' => $validated['action'],
                'remarks' => $validated['remarks'] ?? null,
            ]);

            if ($validated['action'] === 'approved') {
                if ($event->send_announcement) {
                    $eligibleUserIds = $event->eligibleStudentUserIds();

                    if ($eligibleUserIds->isNotEmpty()) {
                        NotificationService::sendToMany(
                            $eligibleUserIds,
                            "New Event Published: {$event->title}",
                            "Registration is now open for '{$event->title}' on {$event->event_date->format('M d, Y')} at {$event->venue}.",
                            'new_event_published',
                            ['event_id' => $event->id]
                        );
                    }
                }
            }

            ActivityLog::log("event_publish_{$validated['action']}", 'events', $event->id, [
                'title' => $event->title,
                'remarks' => $validated['remarks'] ?? null,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => "Event publishing has been {$validated['action']}.",
            'data' => ['status' => $event->status],
        ]);
    }

    /**
     * Organizer Request Cancellation
     */
    public function requestCancellation(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'reason' => ['required', 'string'],
        ]);

        $event = Event::findOrFail($id);
        $user = $request->user();

        if (!$user->isAdmin() && $event->organizer_id !== $user->id) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'You can only request cancellation for your own events.',
            ], 403);
        }

        ActivityLog::log('event_cancellation_requested', 'events', $event->id, [
            'reason' => $validated['reason'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cancellation request recorded. Awaiting administrator approval.',
        ]);
    }

    /**
     * Admin Review Cancellation
     */
    public function reviewCancellation(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'action' => ['required', 'in:approved,rejected'],
            'remarks' => ['nullable', 'string'],
        ]);

        $event = Event::findOrFail($id);

        if ($validated['action'] === 'approved') {
            DB::transaction(function () use ($event, $validated, $request) {
                $event->update(['status' => 'cancelled']);

                EventApproval::create([
                    'event_id' => $event->id,
                    'admin_id' => $request->user()->id,
                    'approval_type' => 'cancellation',
                    'status' => 'approved',
                    'remarks' => $validated['remarks'] ?? null,
                ]);

                // Notify registered attendees of cancellation (mandatory notification).
                // Recipients come solely from the backend eligibility gate.
                $notified = EventNotificationService::notifyRegistered(
                    $event,
                    "Event Cancelled: {$event->title}",
                    "The event '{$event->title}' scheduled for {$event->event_date} has been cancelled.",
                    'event_cancellation'
                );

                ActivityLog::log('event_cancellation_approved', 'events', $event->id, [
                    'notified_attendees' => $notified,
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'Event has been cancelled and attendees have been notified.',
            ]);
        }

        DB::transaction(function () use ($event, $validated, $request) {
            EventApproval::create([
                'event_id' => $event->id,
                'admin_id' => $request->user()->id,
                'approval_type' => 'cancellation',
                'status' => 'rejected',
                'remarks' => $validated['remarks'] ?? null,
            ]);

            ActivityLog::log('event_cancellation_rejected', 'events', $event->id, [
                'remarks' => $validated['remarks'] ?? null,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Cancellation request rejected. Event remains active.',
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Event;
use App\Models\EventApproval;
use App\Models\Notification;
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

        // Role-based visibility
        if ($user->isStudent()) {
            $query->whereIn('status', ['published', 'ongoing']);
        } elseif ($request->filled('status')) {
            $query->where('status', $request->query('status'));
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
     * View Single Event Details
     */
    public function show(int $id, Request $request): JsonResponse
    {
        $user = $request->user();
        $event = Event::with(['organizer:id,email', 'approvals'])->findOrFail($id);

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
            'venue' => ['required', 'string', 'max:200'],
            'event_date' => ['required', 'date', 'after_or_equal:today'],
            'start_time' => ['required', 'date_format:H:i:s,H:i'],
            'end_time' => ['required', 'date_format:H:i:s,H:i', 'after:start_time'],
            'registration_start' => ['required', 'date'],
            'registration_end' => ['required', 'date', 'after:registration_start'],
            'max_participants' => ['nullable', 'integer', 'min:1'],
            'late_grace_period_minutes' => ['nullable', 'integer', 'min:0', 'max:120'],
            'walk_in_allowed' => ['nullable', 'boolean'],
        ]);

        $validated['organizer_id'] = $request->user()->id;
        $validated['late_grace_period_minutes'] = $validated['late_grace_period_minutes'] ?? 15;
        $validated['walk_in_allowed'] = $validated['walk_in_allowed'] ?? false;
        $validated['status'] = 'draft';

        $event = Event::create($validated);

        ActivityLog::log('event_created', 'events', $event->id, [
            'title' => $event->title,
            'status' => 'draft',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Event draft created successfully. Submit for admin approval when ready to publish.',
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
            'venue' => ['sometimes', 'string', 'max:200'],
            'event_date' => ['sometimes', 'date'],
            'start_time' => ['sometimes', 'date_format:H:i:s,H:i'],
            'end_time' => ['sometimes', 'date_format:H:i:s,H:i'],
            'registration_start' => ['sometimes', 'date'],
            'registration_end' => ['sometimes', 'date'],
            'max_participants' => ['nullable', 'integer', 'min:1'],
            'late_grace_period_minutes' => ['sometimes', 'integer', 'min:0'],
            'walk_in_allowed' => ['sometimes', 'boolean'],
        ]);

        $event->update($validated);

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

                // Notify all registered attendees of cancellation
                $registrations = $event->activeRegistrations()->with('student.user')->get();
                foreach ($registrations as $reg) {
                    if ($reg->student?->user) {
                        Notification::create([
                            'user_id' => $reg->student->user->id,
                            'title' => "Event Cancelled: {$event->title}",
                            'message' => "The event '{$event->title}' scheduled for {$event->event_date} has been cancelled.",
                            'notification_type' => 'event_cancellation',
                            'payload' => ['event_id' => $event->id],
                        ]);
                    }
                }

                ActivityLog::log('event_cancellation_approved', 'events', $event->id, [
                    'notified_attendees' => $registrations->count(),
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'Event has been cancelled and attendees have been notified.',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Cancellation request rejected. Event remains active.',
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Notification;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RegistrationController extends Controller
{
    /**
     * Register for Event / Join Waiting List
     */
    public function register(int $eventId, Request $request): JsonResponse
    {
        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_PROFILE_REQUIRED',
                'message' => 'Only student accounts may register for events.',
            ], 403);
        }

        $event = Event::findOrFail($eventId);

        if ($event->status !== 'published') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_EVENT_NOT_OPEN',
                'message' => 'This event is not currently open for registration.',
            ], 422);
        }

        $now = now();
        if ($now->lt($event->registration_start)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_REGISTRATION_NOT_STARTED',
                'message' => "Registration opens on {$event->registration_start->toDayDateTimeString()}.",
            ], 422);
        }

        if ($now->gt($event->registration_end)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_REGISTRATION_DEADLINE_PASSED',
                'message' => 'The registration cutoff deadline for this event has passed.',
            ], 422);
        }

        // Check existing registration
        $existing = EventRegistration::where('event_id', $event->id)
            ->where('student_id', $student->id)
            ->first();

        if ($existing && in_array($existing->status, ['registered', 'waiting_list'])) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_DUPLICATE_REGISTRATION',
                'message' => $existing->status === 'registered' 
                    ? 'You are already registered for this event.' 
                    : "You are already on the waiting list (Position: #{$existing->waiting_list_position}).",
            ], 409);
        }

        // Atomic registration transaction
        $registration = DB::transaction(function () use ($event, $student, $existing) {
            $isFull = $event->isCapacityFull();

            if ($isFull) {
                // Placed on Waiting List
                $nextPosition = EventRegistration::where('event_id', $event->id)
                    ->where('status', 'waiting_list')
                    ->count() + 1;

                $regData = [
                    'event_id' => $event->id,
                    'student_id' => $student->id,
                    'status' => 'waiting_list',
                    'waiting_list_position' => $nextPosition,
                    'registered_at' => now(),
                    'cancelled_at' => null,
                ];

                $reg = $existing ? tap($existing)->update($regData) : EventRegistration::create($regData);

                Notification::create([
                    'user_id' => $student->user_id,
                    'title' => 'Placed on Waiting List',
                    'message' => "You have joined the waiting list for '{$event->title}' at position #{$nextPosition}.",
                    'notification_type' => 'waiting_list_joined',
                    'payload' => ['event_id' => $event->id, 'waiting_position' => $nextPosition],
                ]);

                ActivityLog::log('waiting_list_joined', 'registration', $reg->id, [
                    'event_id' => $event->id,
                    'position' => $nextPosition,
                ]);

                return $reg;
            } else {
                // Normal Registration Confirmed
                $regData = [
                    'event_id' => $event->id,
                    'student_id' => $student->id,
                    'status' => 'registered',
                    'waiting_list_position' => null,
                    'registered_at' => now(),
                    'cancelled_at' => null,
                ];

                $reg = $existing ? tap($existing)->update($regData) : EventRegistration::create($regData);

                Notification::create([
                    'user_id' => $student->user_id,
                    'title' => 'Registration Confirmed',
                    'message' => "You are registered for '{$event->title}' on {$event->event_date->format('M d, Y')}.",
                    'notification_type' => 'registration_confirmed',
                    'payload' => ['event_id' => $event->id],
                ]);

                ActivityLog::log('event_registered', 'registration', $reg->id, [
                    'event_id' => $event->id,
                ]);

                return $reg;
            }
        });

        $isWaiting = $registration->status === 'waiting_list';

        return response()->json([
            'success' => true,
            'message' => $isWaiting 
                ? "Event capacity reached. You are at position #{$registration->waiting_list_position} on the waiting list."
                : 'Registration successful. Present your permanent QR code at the venue check-in.',
            'data' => [
                'registration_id' => $registration->id,
                'event_id' => $event->id,
                'status' => $registration->status,
                'waiting_list_position' => $registration->waiting_list_position,
                'registered_at' => $registration->registered_at->toIso8601String(),
            ],
        ], 201);
    }

    /**
     * Cancel Event Registration (Student)
     * Auto-promotes the next student on the waiting list if applicable.
     */
    public function cancelRegistration(int $eventId, Request $request): JsonResponse
    {
        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_REQUIRED',
                'message' => 'Student profile required.',
            ], 403);
        }

        $event = Event::findOrFail($eventId);

        // Disallow cancellation once event has started
        $eventStart = Carbon::parse("{$event->event_date->format('Y-m-d')} {$event->start_time}");
        if (now()->gte($eventStart)) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_CANNOT_CANCEL_ONGOING',
                'message' => 'Registrations cannot be cancelled after the event has started.',
            ], 422);
        }

        $registration = EventRegistration::where('event_id', $event->id)
            ->where('student_id', $student->id)
            ->whereIn('status', ['registered', 'waiting_list'])
            ->first();

        if (!$registration) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_REGISTRATION_NOT_FOUND',
                'message' => 'No active registration or waiting list entry found for this event.',
            ], 404);
        }

        $wasRegistered = $registration->status === 'registered';

        DB::transaction(function () use ($registration, $event, $wasRegistered) {
            // Cancel current registration
            $registration->update([
                'status' => 'cancelled',
                'waiting_list_position' => null,
                'cancelled_at' => now(),
            ]);

            ActivityLog::log('registration_cancelled', 'registration', $registration->id, [
                'event_id' => $event->id,
            ]);

            // If an active registered slot was vacated, auto-promote next in line
            if ($wasRegistered) {
                $nextCandidate = EventRegistration::where('event_id', $event->id)
                    ->where('status', 'waiting_list')
                    ->orderBy('waiting_list_position', 'asc')
                    ->first();

                if ($nextCandidate) {
                    $nextCandidate->update([
                        'status' => 'registered',
                        'waiting_list_position' => null,
                        'registered_at' => now(),
                    ]);

                    // Re-index remaining waiting list
                    EventRegistration::where('event_id', $event->id)
                        ->where('status', 'waiting_list')
                        ->where('waiting_list_position', '>', 1)
                        ->decrement('waiting_list_position');

                    // Notify promoted student
                    if ($nextCandidate->student?->user) {
                        Notification::create([
                            'user_id' => $nextCandidate->student->user->id,
                            'title' => "Slot Available: {$event->title}",
                            'message' => "A slot opened up! You have been promoted from the waiting list to registered attendee for '{$event->title}'.",
                            'notification_type' => 'waiting_list_promoted',
                            'payload' => ['event_id' => $event->id],
                        ]);
                    }

                    ActivityLog::log('waiting_list_promoted', 'registration', $nextCandidate->id, [
                        'event_id' => $event->id,
                        'promoted_student_id' => $nextCandidate->student_id,
                    ]);
                }
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Registration cancelled successfully.',
        ]);
    }

    /**
     * List Attendees for an Event (Organizer/Admin/Management)
     */
    public function index(int $eventId, Request $request): JsonResponse
    {
        $event = Event::findOrFail($eventId);
        $query = $event->registrations()->with(['student.user', 'attendance']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        $registrations = $query->paginate($request->query('per_page', 25));

        return response()->json([
            'success' => true,
            'data' => $registrations->items(),
            'meta' => [
                'current_page' => $registrations->currentPage(),
                'last_page' => $registrations->lastPage(),
                'total' => $registrations->total(),
            ],
        ]);
    }

    /**
     * Authenticated Student's Event Registrations
     */
    public function studentRegistrations(Request $request): JsonResponse
    {
        $student = $request->user()->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'data' => [],
            ]);
        }

        $registrations = EventRegistration::with(['event', 'attendance'])
            ->where('student_id', $student->id)
            ->orderBy('created_at', 'desc')
            ->paginate($request->query('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => $registrations->items(),
            'meta' => [
                'current_page' => $registrations->currentPage(),
                'last_page' => $registrations->lastPage(),
                'total' => $registrations->total(),
            ],
        ]);
    }
}

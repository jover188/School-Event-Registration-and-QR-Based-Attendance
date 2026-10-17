<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\AttendanceCorrection;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Student;
use App\Models\StudentQR;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    /**
     * QR Attendance Scanner Endpoint
     * Handles Check-In (with automatic late detection & walk-in handling) and Check-Out.
     * Returns student photo and verification details for on-screen physical identity confirmation.
     */
    public function scan(int $eventId, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'qr_token' => ['required', 'string', 'size:64'],
            'mode' => ['required', 'in:check_in,check_out'],
        ]);

        $event = Event::findOrFail($eventId);

        if (in_array($event->status, ['draft', 'pending_approval', 'cancelled'])) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_EVENT_NOT_ACTIVE',
                'message' => "Attendance cannot be recorded for an event in '{$event->status}' status.",
            ], 422);
        }

        // 1. Identify Student by QR Token
        $qrRecord = StudentQR::with('student.user')
            ->where('qr_token', $validated['qr_token'])
            ->first();

        if (!$qrRecord || $qrRecord->status !== 'active') {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_QR_INVALID_OR_REVOKED',
                'message' => 'The scanned QR code is invalid, inactive, or has been revoked.',
            ], 422);
        }

        $student = $qrRecord->student;
        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_NOT_FOUND',
                'message' => 'No active student is associated with this QR token.',
            ], 404);
        }

        $scannerUser = $request->user();

        // 2. CHECK-OUT MODE
        if ($validated['mode'] === 'check_out') {
            $attendance = Attendance::where('event_id', $event->id)
                ->where('student_id', $student->id)
                ->first();

            if (!$attendance) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_NO_CHECK_IN_RECORD',
                    'message' => "Cannot check out: {$student->full_name} does not have an existing check-in record for this event.",
                ], 422);
            }

            if ($attendance->check_out_time) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_ALREADY_CHECKED_OUT',
                    'message' => "{$student->full_name} has already checked out at {$attendance->check_out_time->format('h:i A')}.",
                ], 409);
            }

            $attendance->update([
                'check_out_time' => now(),
            ]);

            ActivityLog::log('attendance_check_out', 'attendance', $attendance->id, [
                'event_id' => $event->id,
                'student_id' => $student->id,
            ]);

            return response()->json([
                'success' => true,
                'message' => "Check-out successfully recorded for {$student->full_name}.",
                'data' => [
                    'attendance_id' => $attendance->id,
                    'mode' => 'check_out',
                    'status' => $attendance->status,
                    'check_in_time' => $attendance->check_in_time?->toIso8601String(),
                    'check_out_time' => $attendance->check_out_time->toIso8601String(),
                    'student' => [
                        'id' => $student->id,
                        'student_id_number' => $student->student_id_number,
                        'full_name' => $student->full_name,
                        'course' => $student->course,
                        'year_level' => $student->year_level,
                        'section' => $student->section,
                        'department' => $student->department,
                        'profile_photo_url' => $student->profile_photo_url,
                    ],
                ],
            ]);
        }

        // 3. CHECK-IN MODE
        // Check duplicate check-in
        $existingAttendance = Attendance::where('event_id', $event->id)
            ->where('student_id', $student->id)
            ->first();

        if ($existingAttendance) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_DUPLICATE_CHECK_IN',
                'message' => "Check-in was already recorded for {$student->full_name} at {$existingAttendance->check_in_time?->format('h:i A')} (Status: " . strtoupper($existingAttendance->status) . ").",
                'data' => [
                    'check_in_time' => $existingAttendance->check_in_time?->toIso8601String(),
                    'status' => $existingAttendance->status,
                    'student' => [
                        'id' => $student->id,
                        'student_id_number' => $student->student_id_number,
                        'full_name' => $student->full_name,
                        'profile_photo_url' => $student->profile_photo_url,
                    ],
                ],
            ], 409);
        }

        // Verify registration
        $registration = EventRegistration::where('event_id', $event->id)
            ->where('student_id', $student->id)
            ->first();

        $isWalkIn = false;
        $attendanceStatus = 'present';

        if (!$registration || $registration->status !== 'registered') {
            // Student is not normally registered
            if (!$event->walk_in_allowed) {
                return response()->json([
                    'success' => false,
                    'error_code' => 'ERR_WALK_IN_NOT_ALLOWED',
                    'message' => "{$student->full_name} is not registered for this event, and walk-in attendance is not permitted.",
                    'data' => [
                        'student' => [
                            'student_id_number' => $student->student_id_number,
                            'full_name' => $student->full_name,
                        ],
                    ],
                ], 403);
            }

            // Walk-in is allowed: create or update registration as walk_in
            $isWalkIn = true;
            $attendanceStatus = 'walk_in';
        } else {
            // Student is registered: Evaluate late arrival grace period
            $eventStart = Carbon::parse("{$event->event_date->format('Y-m-d')} {$event->start_time}");
            $graceLimit = $eventStart->copy()->addMinutes($event->late_grace_period_minutes);

            if (now()->gt($graceLimit)) {
                $attendanceStatus = 'late';
            } else {
                $attendanceStatus = 'present';
            }
        }

        // Atomic attendance recording
        $attendance = DB::transaction(function () use ($event, $student, $registration, $isWalkIn, $attendanceStatus, $scannerUser) {
            $regRecord = $registration;

            if ($isWalkIn) {
                $wasWaiting = $registration && $registration->status === 'waiting_list';
                $oldPosition = $wasWaiting ? $registration->waiting_list_position : null;

                $regRecord = EventRegistration::updateOrCreate(
                    ['event_id' => $event->id, 'student_id' => $student->id],
                    [
                        'status' => 'walk_in',
                        'waiting_list_position' => null,
                        'registered_at' => now(),
                        'cancelled_at' => null,
                    ]
                );

                if ($wasWaiting && !is_null($oldPosition)) {
                    EventRegistration::where('event_id', $event->id)
                        ->where('status', 'waiting_list')
                        ->where('waiting_list_position', '>', $oldPosition)
                        ->decrement('waiting_list_position');
                }
            }

            $createdAttendance = Attendance::create([
                'event_id' => $event->id,
                'student_id' => $student->id,
                'event_registration_id' => $regRecord->id,
                'check_in_time' => now(),
                'status' => $attendanceStatus,
                'scanner_id' => $scannerUser->id,
            ]);

            // Notify Student (mandatory notification)
            if ($student->user) {
                NotificationService::send(
                    $student->user->id,
                    'Attendance Recorded',
                    "Your attendance for '{$event->title}' has been recorded as " . strtoupper($attendanceStatus) . '.',
                    'attendance_recorded',
                    [
                        'event_id' => $event->id,
                        'status' => $attendanceStatus,
                    ]
                );
            }

            ActivityLog::log('attendance_recorded', 'attendance', $createdAttendance->id, [
                'event_id' => $event->id,
                'student_id' => $student->id,
                'status' => $attendanceStatus,
            ]);

            return $createdAttendance;
        });

        $statusLabel = strtoupper($attendanceStatus);
        $message = "Check-in recorded as {$statusLabel} for {$student->full_name}.";
        if ($attendanceStatus === 'late') {
            $message .= " (Exceeded {$event->late_grace_period_minutes}-minute grace period).";
        } elseif ($attendanceStatus === 'walk_in') {
            $message .= ' (Walk-in attendee).';
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => [
                'attendance_id' => $attendance->id,
                'mode' => 'check_in',
                'status' => $attendance->status,
                'check_in_time' => $attendance->check_in_time->toIso8601String(),
                'check_out_time' => null,
                'student' => [
                    'id' => $student->id,
                    'student_id_number' => $student->student_id_number,
                    'full_name' => $student->full_name,
                    'course' => $student->course,
                    'year_level' => $student->year_level,
                    'section' => $student->section,
                    'department' => $student->department,
                    'profile_photo_url' => $student->profile_photo_url,
                ],
            ],
        ]);
    }

    /**
     * Manual Attendance Mark for Registered / Unscanned Student (Admin / Organizer)
     */
    public function mark(int $eventId, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'student_id' => ['required', 'integer', 'exists:students,id'],
            'status' => ['required', 'in:present,absent,late,excused,walk_in'],
            'reason' => ['required', 'string', 'min:5', 'max:500'],
        ]);

        $event = Event::findOrFail($eventId);
        $user = $request->user();

        if (!$user->isAdmin() && $event->organizer_id !== $user->id) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'You do not have permission to mark attendance for this event.',
            ], 403);
        }

        $student = Student::with('user')->findOrFail($validated['student_id']);

        $attendance = DB::transaction(function () use ($event, $student, $validated, $user) {
            $reg = EventRegistration::firstOrCreate(
                ['event_id' => $event->id, 'student_id' => $student->id],
                [
                    'status' => $validated['status'] === 'walk_in' ? 'walk_in' : 'registered',
                    'registered_at' => now(),
                ]
            );

            $existing = Attendance::where('event_id', $event->id)
                ->where('student_id', $student->id)
                ->first();

            $originalStatus = $existing ? $existing->status : 'absent';
            $checkInTime = $validated['status'] === 'absent'
                ? null
                : ($existing?->check_in_time ?? now());

            $att = Attendance::updateOrCreate(
                ['event_id' => $event->id, 'student_id' => $student->id],
                [
                    'event_registration_id' => $reg->id,
                    'check_in_time' => $checkInTime,
                    'status' => $validated['status'],
                    'scanner_id' => $user->id,
                ]
            );

            AttendanceCorrection::create([
                'attendance_id' => $att->id,
                'corrected_by' => $user->id,
                'original_status' => $originalStatus,
                'new_status' => $validated['status'],
                'reason' => $validated['reason'],
            ]);

            if ($student->user) {
                NotificationService::send(
                    $student->user->id,
                    'Attendance Recorded',
                    "Your attendance for '{$event->title}' has been marked as " . strtoupper($validated['status']) . '.',
                    'attendance_recorded',
                    [
                        'event_id' => $event->id,
                        'status' => $validated['status'],
                    ]
                );
            }

            ActivityLog::log('attendance_manually_marked', 'attendance', $att->id, [
                'event_id' => $event->id,
                'student_id' => $student->id,
                'original_status' => $originalStatus,
                'new_status' => $validated['status'],
                'reason' => $validated['reason'],
            ]);

            return $att;
        });

        return response()->json([
            'success' => true,
            'message' => "Attendance manually marked as '{$validated['status']}' for {$student->full_name}.",
            'data' => [
                'attendance_id' => $attendance->id,
                'event_id' => $event->id,
                'student_id' => $student->id,
                'status' => $attendance->status,
                'check_in_time' => $attendance->check_in_time?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Real-Time Attendance Monitoring (Organizer/Admin/Management)
     */
    public function index(int $eventId, Request $request): JsonResponse
    {
        $event = Event::findOrFail($eventId);
        $query = $event->attendances()->with(['student.user', 'scanner:id,email']);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->whereHas('student', function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhere('student_id_number', 'like', "%{$search}%");
            });
        }

        $attendances = $query->orderBy('check_in_time', 'desc')
            ->paginate($request->query('per_page', 25));

        // Summary counts
        $counts = [
            'total_checked_in' => $event->attendances()->count(),
            'present' => $event->attendances()->where('status', 'present')->count(),
            'late' => $event->attendances()->where('status', 'late')->count(),
            'walk_in' => $event->attendances()->where('status', 'walk_in')->count(),
            'excused' => $event->attendances()->where('status', 'excused')->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $attendances->items(),
            'summary' => $counts,
            'meta' => [
                'current_page' => $attendances->currentPage(),
                'last_page' => $attendances->lastPage(),
                'total' => $attendances->total(),
            ],
        ]);
    }

    /**
     * Correct Attendance Record (Admin / Organizer)
     */
    public function correct(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'new_status' => ['required', 'in:present,absent,late,excused,walk_in'],
            'reason' => ['required', 'string', 'min:5', 'max:500'],
        ]);

        $attendance = Attendance::with(['event', 'student'])->findOrFail($id);
        $user = $request->user();

        // Check permission: Admin or organizer of the event
        if (!$user->isAdmin() && $attendance->event->organizer_id !== $user->id) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_FORBIDDEN',
                'message' => 'You do not have permission to correct attendance for this event.',
            ], 403);
        }

        $originalStatus = $attendance->status;

        DB::transaction(function () use ($attendance, $validated, $user, $originalStatus) {
            $attendance->update([
                'status' => $validated['new_status'],
            ]);

            AttendanceCorrection::create([
                'attendance_id' => $attendance->id,
                'corrected_by' => $user->id,
                'original_status' => $originalStatus,
                'new_status' => $validated['new_status'],
                'reason' => $validated['reason'],
            ]);

            ActivityLog::log('attendance_corrected', 'attendance', $attendance->id, [
                'original_status' => $originalStatus,
                'new_status' => $validated['new_status'],
                'reason' => $validated['reason'],
                'student_id' => $attendance->student_id,
                'event_id' => $attendance->event_id,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => "Attendance status updated from '{$originalStatus}' to '{$validated['new_status']}'.",
            'data' => [
                'attendance_id' => $attendance->id,
                'status' => $attendance->status,
            ],
        ]);
    }

    /**
     * Student's Personal Attendance History
     */
    public function studentHistory(Request $request): JsonResponse
    {
        $student = $request->user()->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'data' => [],
            ]);
        }

        $attendances = Attendance::with('event')
            ->where('student_id', $student->id)
            ->orderBy('check_in_time', 'desc')
            ->paginate($request->query('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => $attendances->items(),
            'meta' => [
                'current_page' => $attendances->currentPage(),
                'last_page' => $attendances->lastPage(),
                'total' => $attendances->total(),
            ],
        ]);
    }
}

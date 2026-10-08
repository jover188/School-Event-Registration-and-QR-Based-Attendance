<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    /**
     * 1. Event Attendance Report (JSON)
     */
    public function eventAttendance(int $eventId): JsonResponse
    {
        $event = Event::with('organizer:id,email')->findOrFail($eventId);

        $attendances = Attendance::with(['student', 'scanner:id,email'])
            ->where('event_id', $event->id)
            ->orderBy('check_in_time', 'asc')
            ->get();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'event_attendance',
        ]);

        return response()->json([
            'success' => true,
            'event' => [
                'id' => $event->id,
                'title' => $event->title,
                'event_date' => $event->event_date->format('Y-m-d'),
                'venue' => $event->venue,
            ],
            'total_attendees' => $attendances->count(),
            'data' => $attendances,
        ]);
    }

    /**
     * 2. Student History Report (JSON)
     */
    public function studentHistory(int $studentId): JsonResponse
    {
        $student = Student::with('user:id,email')->findOrFail($studentId);

        $history = Attendance::with('event')
            ->where('student_id', $student->id)
            ->orderBy('check_in_time', 'desc')
            ->get();

        ActivityLog::log('report_viewed', 'reports', $student->id, [
            'type' => 'student_history',
        ]);

        return response()->json([
            'success' => true,
            'student' => [
                'id' => $student->id,
                'student_id_number' => $student->student_id_number,
                'full_name' => $student->full_name,
                'course' => $student->course,
                'department' => $student->department,
            ],
            'total_events_attended' => $history->count(),
            'data' => $history,
        ]);
    }

    /**
     * 3. Registration Summary Report (JSON)
     */
    public function registrationSummary(int $eventId): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        $registered = EventRegistration::where('event_id', $event->id)->where('status', 'registered')->count();
        $waiting = EventRegistration::where('event_id', $event->id)->where('status', 'waiting_list')->count();
        $cancelled = EventRegistration::where('event_id', $event->id)->where('status', 'cancelled')->count();
        $walkIn = EventRegistration::where('event_id', $event->id)->where('status', 'walk_in')->count();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'registration_summary',
        ]);

        return response()->json([
            'success' => true,
            'event_id' => $event->id,
            'title' => $event->title,
            'summary' => [
                'max_capacity' => $event->max_participants,
                'registered' => $registered,
                'waiting_list' => $waiting,
                'cancelled' => $cancelled,
                'walk_in' => $walkIn,
            ],
        ]);
    }

    /**
     * 4. Institutional Participation Summary (JSON)
     */
    public function participationSummary(): JsonResponse
    {
        $totalEvents = Event::whereIn('status', ['published', 'ongoing', 'completed'])->count();
        $totalRegistrations = EventRegistration::where('status', 'registered')->count();
        $totalAttendances = Attendance::count();

        ActivityLog::log('report_viewed', 'reports', null, [
            'type' => 'participation_summary',
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'total_events' => $totalEvents,
                'total_registrations' => $totalRegistrations,
                'total_attendances' => $totalAttendances,
                'turnout_percentage' => $totalRegistrations > 0 ? round(($totalAttendances / $totalRegistrations) * 100, 2) : 0,
            ],
        ]);
    }

    /**
     * 5. Absentee Report (JSON)
     */
    public function absentee(int $eventId): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        // Students registered who have NO attendance record
        $absentees = EventRegistration::with('student')
            ->where('event_id', $event->id)
            ->where('status', 'registered')
            ->whereDoesntHave('attendance')
            ->get();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'absentee',
        ]);

        return response()->json([
            'success' => true,
            'event_id' => $event->id,
            'event_title' => $event->title,
            'absentee_count' => $absentees->count(),
            'data' => $absentees,
        ]);
    }

    /**
     * 6. Walk-In Report (JSON)
     */
    public function walkIn(int $eventId): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        $walkIns = Attendance::with('student')
            ->where('event_id', $event->id)
            ->where('status', 'walk_in')
            ->get();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'walk_in',
        ]);

        return response()->json([
            'success' => true,
            'event_id' => $event->id,
            'event_title' => $event->title,
            'walk_in_count' => $walkIns->count(),
            'data' => $walkIns,
        ]);
    }

    /**
     * 7. Organizer Summary (JSON)
     */
    public function organizerSummary(): JsonResponse
    {
        $organizers = User::where('role_id', 2)
            ->withCount(['organizedEvents as events_count'])
            ->get();

        ActivityLog::log('report_viewed', 'reports', null, [
            'type' => 'organizer_summary',
        ]);

        return response()->json([
            'success' => true,
            'data' => $organizers,
        ]);
    }

    /**
     * Export Reports (CSV Stream)
     */
    public function export(Request $request): StreamedResponse|JsonResponse
    {
        $validated = $request->validate([
            'report_type' => ['required', 'in:event_attendance,student_history,absentee,walk_in'],
            'format' => ['required', 'in:csv,json'],
            'event_id' => ['required_if:report_type,event_attendance,absentee,walk_in', 'nullable', 'integer'],
            'student_id' => ['required_if:report_type,student_history', 'nullable', 'integer'],
        ]);

        $reportType = $validated['report_type'];
        $format = $validated['format'];

        ActivityLog::log('report_exported', 'reports', $validated['event_id'] ?? $validated['student_id'], [
            'report_type' => $reportType,
            'format' => $format,
        ]);

        $filename = "report_{$reportType}_" . date('Ymd_His') . ".csv";

        return response()->streamDownload(function () use ($reportType, $validated) {
            $handle = fopen('php://output', 'w');

            if ($reportType === 'event_attendance') {
                fputcsv($handle, ['Student ID', 'Full Name', 'Course', 'Year Level', 'Status', 'Check-In Time', 'Check-Out Time']);
                $records = Attendance::with('student')
                    ->where('event_id', $validated['event_id'])
                    ->orderBy('check_in_time', 'asc')
                    ->cursor();

                foreach ($records as $att) {
                    fputcsv($handle, [
                        $att->student?->student_id_number,
                        $att->student?->full_name,
                        $att->student?->course,
                        $att->student?->year_level,
                        strtoupper($att->status),
                        $att->check_in_time?->format('Y-m-d H:i:s'),
                        $att->check_out_time?->format('Y-m-d H:i:s') ?? 'N/A',
                    ]);
                }
            } elseif ($reportType === 'absentee') {
                fputcsv($handle, ['Student ID', 'Full Name', 'Course', 'Department', 'Contact Number']);
                $absentees = EventRegistration::with('student')
                    ->where('event_id', $validated['event_id'])
                    ->where('status', 'registered')
                    ->whereDoesntHave('attendance')
                    ->cursor();

                foreach ($absentees as $reg) {
                    fputcsv($handle, [
                        $reg->student?->student_id_number,
                        $reg->student?->full_name,
                        $reg->student?->course,
                        $reg->student?->department,
                        $reg->student?->contact_number,
                    ]);
                }
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}

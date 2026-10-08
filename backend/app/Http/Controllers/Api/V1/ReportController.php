<?php

namespace App\Http\Controllers\Api\V1;

use App\Exports\AbsenteeExport;
use App\Exports\EventAttendanceExport;
use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Student;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
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
     * Export Reports — supports csv, pdf, xlsx
     *
     * Query params:
     *   report_type  : event_attendance | absentee | student_history | walk_in
     *   format       : csv | pdf | xlsx
     *   event_id     : required for event_attendance, absentee, walk_in
     *   student_id   : required for student_history
     */
    public function export(Request $request): StreamedResponse|BinaryFileResponse|Response|JsonResponse
    {
        $validated = $request->validate([
            'report_type' => ['required', 'in:event_attendance,student_history,absentee,walk_in'],
            'format'      => ['required', 'in:csv,pdf,xlsx'],
            'event_id'    => ['required_if:report_type,event_attendance,absentee,walk_in', 'nullable', 'integer'],
            'student_id'  => ['required_if:report_type,student_history', 'nullable', 'integer'],
        ]);

        $reportType  = $validated['report_type'];
        $format      = $validated['format'];
        $generatedBy = $request->user()?->email ?? 'system';

        ActivityLog::log('report_exported', 'reports', $validated['event_id'] ?? $validated['student_id'] ?? null, [
            'report_type' => $reportType,
            'format'      => $format,
        ]);

        $timestamp = now()->format('Ymd_His');

        // ── PDF export ────────────────────────────────────────────────────────
        if ($format === 'pdf') {
            return $this->exportPdf($reportType, $validated, $generatedBy, $timestamp);
        }

        // ── Excel (.xlsx) export ──────────────────────────────────────────────
        if ($format === 'xlsx') {
            return $this->exportXlsx($reportType, $validated, $generatedBy, $timestamp);
        }

        // ── CSV stream export ─────────────────────────────────────────────────
        $filename = "report_{$reportType}_{$timestamp}.csv";

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
            } elseif ($reportType === 'walk_in') {
                fputcsv($handle, ['Student ID', 'Full Name', 'Course', 'Check-In Time']);
                $walkIns = Attendance::with('student')
                    ->where('event_id', $validated['event_id'])
                    ->where('status', 'walk_in')
                    ->cursor();

                foreach ($walkIns as $att) {
                    fputcsv($handle, [
                        $att->student?->student_id_number,
                        $att->student?->full_name,
                        $att->student?->course,
                        $att->check_in_time?->format('Y-m-d H:i:s'),
                    ]);
                }
            }

            fclose($handle);
        }, $filename, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private function exportPdf(string $reportType, array $params, string $generatedBy, string $timestamp): Response
    {
        if ($reportType === 'event_attendance') {
            $event       = Event::with('organizer:id,email')->findOrFail($params['event_id']);
            $attendances = Attendance::with('student')
                ->where('event_id', $event->id)
                ->orderBy('check_in_time', 'asc')
                ->get();

            $pdf = Pdf::loadView('reports.event_attendance', [
                'event'          => $event,
                'attendances'    => $attendances,
                'totalAttendees' => $attendances->count(),
                'presentCount'   => $attendances->where('status', 'present')->count(),
                'lateCount'      => $attendances->where('status', 'late')->count(),
                'walkInCount'    => $attendances->where('status', 'walk_in')->count(),
                'generatedBy'    => $generatedBy,
            ])->setPaper('a4', 'landscape');

            return $pdf->download("attendance_{$event->id}_{$timestamp}.pdf");
        }

        if ($reportType === 'absentee') {
            $event     = Event::findOrFail($params['event_id']);
            $absentees = EventRegistration::with('student')
                ->where('event_id', $event->id)
                ->where('status', 'registered')
                ->whereDoesntHave('attendance')
                ->get();

            $pdf = Pdf::loadView('reports.absentee', [
                'event'       => $event,
                'absentees'   => $absentees,
                'generatedBy' => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("absentee_{$event->id}_{$timestamp}.pdf");
        }

        abort(422, "PDF export not supported for report type: {$reportType}");
    }

    private function exportXlsx(string $reportType, array $params, string $generatedBy, string $timestamp): BinaryFileResponse
    {
        if ($reportType === 'event_attendance') {
            $event    = Event::findOrFail($params['event_id']);
            $filename = "attendance_{$event->id}_{$timestamp}.xlsx";

            return Excel::download(new EventAttendanceExport($event, $generatedBy), $filename);
        }

        if ($reportType === 'absentee') {
            $event    = Event::findOrFail($params['event_id']);
            $filename = "absentee_{$event->id}_{$timestamp}.xlsx";

            return Excel::download(new AbsenteeExport($event, $generatedBy), $filename);
        }

        abort(422, "Excel export not supported for report type: {$reportType}");
    }
}


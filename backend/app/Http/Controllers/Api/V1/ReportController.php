<?php

namespace App\Http\Controllers\Api\V1;

use App\Exports\AbsenteeExport;
use App\Exports\EventAttendanceExport;
use App\Exports\OrganizerSummaryExport;
use App\Exports\ParticipationSummaryExport;
use App\Exports\RegistrationSummaryExport;
use App\Exports\StudentHistoryExport;
use App\Exports\WalkInExport;
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
    public function eventAttendance(int $eventId, Request $request): JsonResponse
    {
        $event = Event::with('organizer:id,email')->findOrFail($eventId);

        $attQuery = Attendance::with(['student', 'scanner:id,email'])
            ->where('event_id', $event->id)
            ->orderBy('check_in_time', 'asc');

        $absQuery = EventRegistration::with('student')
            ->where('event_id', $event->id)
            ->where('status', 'registered')
            ->whereDoesntHave('attendance');

        if ($request->filled('department')) {
            $dept = $request->query('department');
            $attQuery->whereHas('student', fn ($q) => $q->where('department', $dept));
            $absQuery->whereHas('student', fn ($q) => $q->where('department', $dept));
        }

        if ($request->filled('year_level')) {
            $yr = $request->query('year_level');
            $attQuery->whereHas('student', fn ($q) => $q->where('year_level', $yr));
            $absQuery->whereHas('student', fn ($q) => $q->where('year_level', $yr));
        }

        $attendances = $attQuery->get();
        $absentRegistrations = $absQuery->get();

        $synthesizedAbsentees = $absentRegistrations->map(function ($reg) use ($event) {
            return [
                'id'                    => null,
                'event_id'              => $event->id,
                'student_id'            => $reg->student_id,
                'event_registration_id' => $reg->id,
                'check_in_time'         => null,
                'check_out_time'        => null,
                'status'                => 'absent',
                'scanner_id'            => null,
                'student'               => $reg->student,
                'scanner'               => null,
            ];
        });

        $allRecords = $attendances->map(fn ($a) => $a->toArray())->concat($synthesizedAbsentees)->values();

        $presentCount = $allRecords->where('status', 'present')->count();
        $lateCount    = $allRecords->where('status', 'late')->count();
        $walkInCount  = $allRecords->where('status', 'walk_in')->count();
        $absentCount  = $allRecords->where('status', 'absent')->count();
        $excusedCount = $allRecords->where('status', 'excused')->count();

        if ($request->filled('status')) {
            $statusFilter = $request->query('status');
            $allRecords = $allRecords->where('status', $statusFilter)->values();
        }

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'event_attendance',
        ]);

        return response()->json([
            'success'         => true,
            'event'           => [
                'id'         => $event->id,
                'title'      => $event->title,
                'event_date' => $event->event_date->format('Y-m-d'),
                'venue'      => $event->venue,
            ],
            'total_attendees' => $presentCount + $lateCount + $walkInCount,
            'present_count'   => $presentCount,
            'late_count'      => $lateCount,
            'walk_in_count'   => $walkInCount,
            'absent_count'    => $absentCount,
            'excused_count'   => $excusedCount,
            'data'            => $allRecords,
        ]);
    }

    /**
     * 2. Student History Report (JSON)
     */
    public function studentHistory(int $studentId, Request $request): JsonResponse
    {
        $student = Student::with('user:id,email')->findOrFail($studentId);

        $query = Attendance::with('event')
            ->where('student_id', $student->id);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('date_from')) {
            $dateFrom = $request->query('date_from');
            $query->whereHas('event', fn ($q) => $q->where('event_date', '>=', $dateFrom));
        }

        if ($request->filled('date_to')) {
            $dateTo = $request->query('date_to');
            $query->whereHas('event', fn ($q) => $q->where('event_date', '<=', $dateTo));
        }

        $history = $query->orderBy('check_in_time', 'desc')->get();

        ActivityLog::log('report_viewed', 'reports', $student->id, [
            'type' => 'student_history',
        ]);

        return response()->json([
            'success' => true,
            'student' => [
                'id'                => $student->id,
                'student_id_number' => $student->student_id_number,
                'full_name'         => $student->full_name,
                'course'            => $student->course,
                'department'        => $student->department,
            ],
            'total_events_attended' => $history->count(),
            'data'                  => $history,
        ]);
    }

    /**
     * 3. Registration Summary Report (JSON)
     */
    public function registrationSummary(int $eventId, Request $request): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        $baseQuery = fn () => EventRegistration::where('event_id', $event->id)
            ->when($request->filled('department'), function ($q) use ($request) {
                $q->whereHas('student', fn ($sq) => $sq->where('department', $request->query('department')));
            })
            ->when($request->filled('year_level'), function ($q) use ($request) {
                $q->whereHas('student', fn ($sq) => $sq->where('year_level', $request->query('year_level')));
            });

        $registered = $baseQuery()->where('status', 'registered')->count();
        $waiting    = $baseQuery()->where('status', 'waiting_list')->count();
        $cancelled  = $baseQuery()->where('status', 'cancelled')->count();
        $walkIn     = $baseQuery()->where('status', 'walk_in')->count();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'registration_summary',
        ]);

        return response()->json([
            'success'  => true,
            'event_id' => $event->id,
            'title'    => $event->title,
            'summary'  => [
                'max_capacity' => $event->max_participants,
                'registered'   => $registered,
                'waiting_list' => $waiting,
                'cancelled'    => $cancelled,
                'walk_in'      => $walkIn,
            ],
        ]);
    }

    /**
     * 4. Institutional Participation Summary (JSON)
     */
    public function participationSummary(Request $request): JsonResponse
    {
        $eventsQuery = Event::whereIn('status', ['published', 'ongoing', 'completed']);

        if ($request->filled('date_from')) {
            $eventsQuery->where('event_date', '>=', $request->query('date_from'));
        }
        if ($request->filled('date_to')) {
            $eventsQuery->where('event_date', '<=', $request->query('date_to'));
        }

        $eventIds    = (clone $eventsQuery)->pluck('id');
        $totalEvents = $eventIds->count();

        $regQuery = EventRegistration::whereIn('event_id', $eventIds)
            ->where('status', 'registered');
        $attQuery = Attendance::whereIn('event_id', $eventIds)
            ->where('status', '!=', 'absent');

        if ($request->filled('department')) {
            $dept = $request->query('department');
            $regQuery->whereHas('student', fn ($q) => $q->where('department', $dept));
            $attQuery->whereHas('student', fn ($q) => $q->where('department', $dept));
        }

        if ($request->filled('year_level')) {
            $yr = $request->query('year_level');
            $regQuery->whereHas('student', fn ($q) => $q->where('year_level', $yr));
            $attQuery->whereHas('student', fn ($q) => $q->where('year_level', $yr));
        }

        $totalRegistrations = $regQuery->count();
        $totalAttendances   = $attQuery->count();

        $eventsBreakdown = (clone $eventsQuery)
            ->withCount([
                'registrations as registered_count' => fn ($q) => $q->where('status', 'registered'),
                'attendances as attended_count'     => fn ($q) => $q->where('status', '!=', 'absent'),
            ])
            ->orderBy('event_date', 'desc')
            ->get();

        ActivityLog::log('report_viewed', 'reports', null, [
            'type' => 'participation_summary',
        ]);

        return response()->json([
            'success' => true,
            'data'    => [
                'total_events'        => $totalEvents,
                'total_registrations' => $totalRegistrations,
                'total_attendances'   => $totalAttendances,
                'turnout_percentage'  => $totalRegistrations > 0 ? round(($totalAttendances / $totalRegistrations) * 100, 2) : 0,
            ],
            'events'  => $eventsBreakdown,
        ]);
    }

    /**
     * 5. Absentee Report (JSON)
     */
    public function absentee(int $eventId, Request $request): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        $query = EventRegistration::with('student')
            ->where('event_id', $event->id)
            ->where('status', 'registered')
            ->whereDoesntHave('attendance');

        if ($request->filled('department')) {
            $dept = $request->query('department');
            $query->whereHas('student', fn ($q) => $q->where('department', $dept));
        }

        if ($request->filled('year_level')) {
            $yr = $request->query('year_level');
            $query->whereHas('student', fn ($q) => $q->where('year_level', $yr));
        }

        $absentees = $query->get();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'absentee',
        ]);

        return response()->json([
            'success'        => true,
            'event_id'       => $event->id,
            'event_title'    => $event->title,
            'absentee_count' => $absentees->count(),
            'data'           => $absentees,
        ]);
    }

    /**
     * 6. Walk-In Report (JSON)
     */
    public function walkIn(int $eventId, Request $request): JsonResponse
    {
        $event = Event::findOrFail($eventId);

        $query = Attendance::with('student')
            ->where('event_id', $event->id)
            ->where('status', 'walk_in');

        if ($request->filled('department')) {
            $dept = $request->query('department');
            $query->whereHas('student', fn ($q) => $q->where('department', $dept));
        }

        if ($request->filled('year_level')) {
            $yr = $request->query('year_level');
            $query->whereHas('student', fn ($q) => $q->where('year_level', $yr));
        }

        $walkIns = $query->get();

        ActivityLog::log('report_viewed', 'reports', $event->id, [
            'type' => 'walk_in',
        ]);

        return response()->json([
            'success'       => true,
            'event_id'      => $event->id,
            'event_title'   => $event->title,
            'walk_in_count' => $walkIns->count(),
            'data'          => $walkIns,
        ]);
    }

    /**
     * 7. Organizer Summary (JSON)
     */
    public function organizerSummary(Request $request): JsonResponse
    {
        $dateFrom = $request->query('date_from');
        $dateTo   = $request->query('date_to');

        $organizers = User::where('role_id', 2)
            ->get()
            ->map(function (User $organizer) use ($dateFrom, $dateTo) {
                $eventsQuery = $organizer->organizedEvents();
                if ($dateFrom) {
                    $eventsQuery->where('event_date', '>=', $dateFrom);
                }
                if ($dateTo) {
                    $eventsQuery->where('event_date', '<=', $dateTo);
                }

                $eventIds = $eventsQuery->pluck('id');
                $organizer->events_count = $eventIds->count();
                $organizer->total_registrations = EventRegistration::whereIn('event_id', $eventIds)
                    ->where('status', 'registered')
                    ->count();
                $organizer->total_attendances = Attendance::whereIn('event_id', $eventIds)
                    ->where('status', '!=', 'absent')
                    ->count();
                return $organizer;
            });

        ActivityLog::log('report_viewed', 'reports', null, [
            'type' => 'organizer_summary',
        ]);

        return response()->json([
            'success' => true,
            'data'    => $organizers,
        ]);
    }

    /**
     * Export Reports — supports all 7 report types in csv, pdf, xlsx
     */
    public function export(Request $request): StreamedResponse|BinaryFileResponse|Response|JsonResponse
    {
        $validated = $request->validate([
            'report_type' => [
                'required',
                'in:event_attendance,student_history,registration_summary,participation_summary,absentee,walk_in,organizer_summary',
            ],
            'format'      => ['required', 'in:csv,pdf,xlsx'],
            'event_id'    => ['required_if:report_type,event_attendance,registration_summary,absentee,walk_in', 'nullable', 'integer'],
            'student_id'  => ['required_if:report_type,student_history', 'nullable', 'integer'],
            'date_from'   => ['nullable', 'date'],
            'date_to'     => ['nullable', 'date'],
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
                        $att->check_in_time?->format('Y-m-d H:i:s') ?? '—',
                        $att->check_out_time?->format('Y-m-d H:i:s') ?? 'N/A',
                    ]);
                }

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
                        $reg->student?->year_level,
                        'ABSENT',
                        '—',
                        'N/A',
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
            } elseif ($reportType === 'student_history') {
                fputcsv($handle, ['Event Title', 'Event Date', 'Venue', 'Status', 'Check-In Time', 'Check-Out Time']);
                $history = Attendance::with('event')
                    ->where('student_id', $validated['student_id'])
                    ->orderBy('check_in_time', 'desc')
                    ->cursor();

                foreach ($history as $att) {
                    fputcsv($handle, [
                        $att->event?->title,
                        $att->event?->event_date?->format('Y-m-d'),
                        $att->event?->venue,
                        strtoupper($att->status),
                        $att->check_in_time?->format('Y-m-d H:i:s') ?? '—',
                        $att->check_out_time?->format('Y-m-d H:i:s') ?? 'N/A',
                    ]);
                }
            } elseif ($reportType === 'registration_summary') {
                fputcsv($handle, ['Student ID', 'Full Name', 'Course', 'Department', 'Year Level', 'Status', 'Waiting List Position', 'Registered At']);
                $registrations = EventRegistration::with('student')
                    ->where('event_id', $validated['event_id'])
                    ->orderBy('created_at', 'asc')
                    ->cursor();

                foreach ($registrations as $reg) {
                    fputcsv($handle, [
                        $reg->student?->student_id_number,
                        $reg->student?->full_name,
                        $reg->student?->course,
                        $reg->student?->department,
                        $reg->student?->year_level,
                        strtoupper($reg->status),
                        $reg->waiting_list_position ?? '—',
                        $reg->registered_at?->format('Y-m-d H:i:s'),
                    ]);
                }
            } elseif ($reportType === 'participation_summary') {
                fputcsv($handle, ['Event Title', 'Event Date', 'Venue', 'Status', 'Registered Count', 'Attended Count', 'Turnout (%)']);
                $events = Event::whereIn('status', ['published', 'ongoing', 'completed'])
                    ->withCount([
                        'registrations as registered_count' => fn ($q) => $q->where('status', 'registered'),
                        'attendances as attended_count'     => fn ($q) => $q->where('status', '!=', 'absent'),
                    ])
                    ->orderBy('event_date', 'desc')
                    ->get();

                foreach ($events as $ev) {
                    $turnout = $ev->registered_count > 0
                        ? round(($ev->attended_count / $ev->registered_count) * 100, 2)
                        : 0;
                    fputcsv($handle, [
                        $ev->title,
                        $ev->event_date?->format('Y-m-d'),
                        $ev->venue,
                        strtoupper($ev->status),
                        $ev->registered_count,
                        $ev->attended_count,
                        "{$turnout}%",
                    ]);
                }
            } elseif ($reportType === 'organizer_summary') {
                fputcsv($handle, ['Organizer Email', 'Status', 'Events Organized', 'Total Registrations', 'Total Attendances']);
                $organizers = User::where('role_id', 2)->get();

                foreach ($organizers as $org) {
                    $eventIds = $org->organizedEvents()->pluck('id');
                    $regCount = EventRegistration::whereIn('event_id', $eventIds)->where('status', 'registered')->count();
                    $attCount = Attendance::whereIn('event_id', $eventIds)->where('status', '!=', 'absent')->count();
                    fputcsv($handle, [
                        $org->email,
                        strtoupper($org->status),
                        $eventIds->count(),
                        $regCount,
                        $attCount,
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

            $absentees = EventRegistration::with('student')
                ->where('event_id', $event->id)
                ->where('status', 'registered')
                ->whereDoesntHave('attendance')
                ->get()
                ->map(fn ($reg) => (object) [
                    'student'        => $reg->student,
                    'status'         => 'absent',
                    'check_in_time'  => null,
                    'check_out_time' => null,
                ]);

            $merged = $attendances->concat($absentees);

            $pdf = Pdf::loadView('reports.event_attendance', [
                'event'          => $event,
                'attendances'    => $merged,
                'totalAttendees' => $merged->count(),
                'presentCount'   => $attendances->where('status', 'present')->count(),
                'lateCount'      => $attendances->where('status', 'late')->count(),
                'walkInCount'    => $attendances->where('status', 'walk_in')->count(),
                'absentCount'    => $absentees->count() + $attendances->where('status', 'absent')->count(),
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

        if ($reportType === 'student_history') {
            $student = Student::findOrFail($params['student_id']);
            $history = Attendance::with('event')
                ->where('student_id', $student->id)
                ->orderBy('check_in_time', 'desc')
                ->get();

            $pdf = Pdf::loadView('reports.student_history', [
                'student'     => $student,
                'history'     => $history,
                'generatedBy' => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("student_history_{$student->id}_{$timestamp}.pdf");
        }

        if ($reportType === 'registration_summary') {
            $event         = Event::findOrFail($params['event_id']);
            $registrations = EventRegistration::with('student')
                ->where('event_id', $event->id)
                ->orderBy('created_at', 'asc')
                ->get();

            $summary = [
                'max_capacity' => $event->max_participants,
                'registered'   => $registrations->where('status', 'registered')->count(),
                'waiting_list' => $registrations->where('status', 'waiting_list')->count(),
                'cancelled'    => $registrations->where('status', 'cancelled')->count(),
                'walk_in'      => $registrations->where('status', 'walk_in')->count(),
            ];

            $pdf = Pdf::loadView('reports.registration_summary', [
                'event'         => $event,
                'summary'       => $summary,
                'registrations' => $registrations,
                'generatedBy'   => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("registration_summary_{$event->id}_{$timestamp}.pdf");
        }

        if ($reportType === 'participation_summary') {
            $events = Event::whereIn('status', ['published', 'ongoing', 'completed'])
                ->withCount([
                    'registrations as registered_count' => fn ($q) => $q->where('status', 'registered'),
                    'attendances as attended_count'     => fn ($q) => $q->where('status', '!=', 'absent'),
                ])
                ->orderBy('event_date', 'desc')
                ->get();

            $totalReg = $events->sum('registered_count');
            $totalAtt = $events->sum('attended_count');

            $summary = [
                'total_events'        => $events->count(),
                'total_registrations' => $totalReg,
                'total_attendances'   => $totalAtt,
                'turnout_percentage'  => $totalReg > 0 ? round(($totalAtt / $totalReg) * 100, 2) : 0,
            ];

            $pdf = Pdf::loadView('reports.participation_summary', [
                'summary'     => $summary,
                'events'      => $events,
                'generatedBy' => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("participation_summary_{$timestamp}.pdf");
        }

        if ($reportType === 'walk_in') {
            $event   = Event::findOrFail($params['event_id']);
            $walkIns = Attendance::with('student')
                ->where('event_id', $event->id)
                ->where('status', 'walk_in')
                ->get();

            $pdf = Pdf::loadView('reports.walk_in', [
                'event'       => $event,
                'walkIns'     => $walkIns,
                'generatedBy' => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("walk_in_{$event->id}_{$timestamp}.pdf");
        }

        if ($reportType === 'organizer_summary') {
            $organizers = User::where('role_id', 2)
                ->get()
                ->map(function (User $organizer) {
                    $eventIds = $organizer->organizedEvents()->pluck('id');
                    $organizer->events_count = $eventIds->count();
                    $organizer->total_registrations = EventRegistration::whereIn('event_id', $eventIds)
                        ->where('status', 'registered')
                        ->count();
                    $organizer->total_attendances = Attendance::whereIn('event_id', $eventIds)
                        ->where('status', '!=', 'absent')
                        ->count();
                    return $organizer;
                });

            $pdf = Pdf::loadView('reports.organizer_summary', [
                'organizers'  => $organizers,
                'generatedBy' => $generatedBy,
            ])->setPaper('a4', 'portrait');

            return $pdf->download("organizer_summary_{$timestamp}.pdf");
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

        if ($reportType === 'student_history') {
            $student  = Student::findOrFail($params['student_id']);
            $filename = "student_history_{$student->id}_{$timestamp}.xlsx";

            return Excel::download(new StudentHistoryExport($student, $generatedBy), $filename);
        }

        if ($reportType === 'registration_summary') {
            $event    = Event::findOrFail($params['event_id']);
            $filename = "registration_summary_{$event->id}_{$timestamp}.xlsx";

            return Excel::download(new RegistrationSummaryExport($event, $generatedBy), $filename);
        }

        if ($reportType === 'participation_summary') {
            $filename = "participation_summary_{$timestamp}.xlsx";

            return Excel::download(
                new ParticipationSummaryExport($generatedBy, $params['date_from'] ?? null, $params['date_to'] ?? null),
                $filename
            );
        }

        if ($reportType === 'walk_in') {
            $event    = Event::findOrFail($params['event_id']);
            $filename = "walk_in_{$event->id}_{$timestamp}.xlsx";

            return Excel::download(new WalkInExport($event, $generatedBy), $filename);
        }

        if ($reportType === 'organizer_summary') {
            $filename = "organizer_summary_{$timestamp}.xlsx";

            return Excel::download(
                new OrganizerSummaryExport($generatedBy, $params['date_from'] ?? null, $params['date_to'] ?? null),
                $filename
            );
        }

        abort(422, "Excel export not supported for report type: {$reportType}");
    }
}

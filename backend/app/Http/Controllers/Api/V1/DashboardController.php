<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Models\Notification;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Student Dashboard Metrics
     */
    public function student(Request $request): JsonResponse
    {
        $user = $request->user();
        $student = $user->student;

        if (!$student) {
            return response()->json([
                'success' => false,
                'error_code' => 'ERR_STUDENT_REQUIRED',
                'message' => 'Student profile not found.',
            ], 404);
        }

        // Upcoming events registered
        $upcomingRegistrations = EventRegistration::with('event')
            ->where('student_id', $student->id)
            ->whereIn('status', ['registered', 'waiting_list'])
            ->whereHas('event', function ($q) {
                $q->where('event_date', '>=', now()->toDateString())
                  ->whereIn('status', ['published', 'ongoing']);
            })
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();

        $totalAttended = Attendance::where('student_id', $student->id)->count();
        $totalRegistered = EventRegistration::where('student_id', $student->id)->where('status', 'registered')->count();
        $unreadNotifications = Notification::where('user_id', $user->id)->where('is_read', false)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'student' => [
                    'id' => $student->id,
                    'student_id_number' => $student->student_id_number,
                    'full_name' => $student->full_name,
                    'course' => $student->course,
                    'profile_photo_url' => $student->profile_photo_url,
                ],
                'stats' => [
                    'total_registered_events' => $totalRegistered,
                    'total_attended_events' => $totalAttended,
                    'unread_notifications' => $unreadNotifications,
                ],
                'active_qr_token' => $student->activeQr?->qr_token,
                'upcoming_events' => $upcomingRegistrations,
            ],
        ]);
    }

    /**
     * Organizer Dashboard Metrics
     */
    public function organizer(Request $request): JsonResponse
    {
        $user = $request->user();
        $organizedQuery = Event::where('organizer_id', $user->id);

        $myEventsCount = (clone $organizedQuery)->count();
        $publishedCount = (clone $organizedQuery)->where('status', 'published')->count();
        $ongoingCount = (clone $organizedQuery)->where('status', 'ongoing')->count();
        $draftCount = (clone $organizedQuery)->where('status', 'draft')->count();

        // Recent organized events with attendance tallies
        $recentEvents = (clone $organizedQuery)
            ->withCount(['activeRegistrations as registrations_count', 'attendances as attendances_count'])
            ->orderBy('event_date', 'desc')
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_events' => $myEventsCount,
                    'published_events' => $publishedCount,
                    'ongoing_events' => $ongoingCount,
                    'draft_events' => $draftCount,
                ],
                'recent_events' => $recentEvents,
            ],
        ]);
    }

    /**
     * School Management Dashboard Metrics (Strictly Read-Only)
     */
    public function management(): JsonResponse
    {
        $totalEvents = Event::whereIn('status', ['published', 'ongoing', 'completed'])->count();
        $totalRegistrations = EventRegistration::where('status', 'registered')->count();
        $totalAttendances = Attendance::count();
        $turnoutRate = $totalRegistrations > 0 ? round(($totalAttendances / $totalRegistrations) * 100, 1) : 0;

        $attendanceByStatus = [
            'present' => Attendance::where('status', 'present')->count(),
            'late' => Attendance::where('status', 'late')->count(),
            'walk_in' => Attendance::where('status', 'walk_in')->count(),
            'excused' => Attendance::where('status', 'excused')->count(),
        ];

        // Breakdown by department
        $departmentStats = Student::select('department')
            ->selectRaw('count(distinct students.id) as student_count')
            ->groupBy('department')
            ->get();

        $recentEvents = Event::whereIn('status', ['published', 'ongoing', 'completed'])
            ->withCount(['activeRegistrations as registrations_count', 'attendances as attendances_count'])
            ->orderBy('event_date', 'desc')
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'overall_metrics' => [
                    'total_events' => $totalEvents,
                    'total_registrations' => $totalRegistrations,
                    'total_attendances' => $totalAttendances,
                    'overall_turnout_rate' => "{$turnoutRate}%",
                ],
                'attendance_by_status' => $attendanceByStatus,
                'department_distribution' => $departmentStats,
                'recent_events' => $recentEvents,
            ],
        ]);
    }

    /**
     * Administrator Dashboard Metrics
     */
    public function admin(): JsonResponse
    {
        $pendingApprovals = Event::where('status', 'pending_approval')->count();
        $totalUsers = User::count();
        $totalStudents = Student::count();
        $totalOrganizers = User::where('role_id', 2)->count();
        $activeQrs = \App\Models\StudentQR::where('status', 'active')->count();

        $recentLogs = ActivityLog::with('user:id,email')
            ->orderBy('created_at', 'desc')
            ->take(8)
            ->get();

        $pendingApprovalEvents = Event::with('organizer:id,email')
            ->where('status', 'pending_approval')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'pending_event_approvals' => $pendingApprovals,
                    'total_users' => $totalUsers,
                    'total_students' => $totalStudents,
                    'total_organizers' => $totalOrganizers,
                    'active_permanent_qrs' => $activeQrs,
                ],
                'pending_approval_events' => $pendingApprovalEvents,
                'recent_activity_logs' => $recentLogs,
            ],
        ]);
    }
}

<?php

use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\AttendanceController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\EventController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\RegistrationController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\StudentQRController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes (v1)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ========================================================================
    // 1. Public Authentication Routes
    // ========================================================================
    Route::prefix('auth')->group(function () {
        Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
        Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    });

    // ========================================================================
    // 2. Protected Authenticated Routes (Requires Sanctum Token + Single Session)
    // ========================================================================
    Route::middleware(['auth:sanctum', 'single.session'])->group(function () {

        // Session & Profile
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/profile', [AuthController::class, 'profile']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile/change-password', [AuthController::class, 'changePassword']);

        // Notifications & Device Registration
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/notifications/mark-all-read', [NotificationController::class, 'markAllAsRead']);
        Route::get('/notifications/preferences', [NotificationController::class, 'getPreferences']);
        Route::put('/notifications/preferences', [NotificationController::class, 'updatePreferences']);
        Route::post('/device-tokens', [NotificationController::class, 'storeDeviceToken']);
        Route::delete('/device-tokens', [NotificationController::class, 'destroyDeviceToken']);

        // General Event Discovery (Available to all authenticated roles)
        Route::get('/events', [EventController::class, 'index']);
        Route::get('/events/{id}', [EventController::class, 'show']);

        // ====================================================================
        // Role: Student Only
        // ====================================================================
        Route::middleware('role:student')->group(function () {
            // Permanent QR
            Route::get('/student/qr', [StudentQRController::class, 'show']);
            Route::post('/student/qr/reissue', [StudentQRController::class, 'reissue']);

            // Event Registration
            Route::post('/events/{id}/register', [RegistrationController::class, 'register']);
            Route::delete('/events/{id}/cancel-registration', [RegistrationController::class, 'cancelRegistration']);
            Route::get('/student/registrations', [RegistrationController::class, 'studentRegistrations']);
            Route::get('/student/attendance-history', [AttendanceController::class, 'studentHistory']);

            // Student Dashboard
            Route::get('/dashboard/student', [DashboardController::class, 'student']);
        });

        // ====================================================================
        // Role: Organizer & Administrator
        // ====================================================================
        Route::middleware('role:administrator,organizer')->group(function () {
            // Event Management
            Route::post('/events', [EventController::class, 'store']);
            Route::put('/events/{id}', [EventController::class, 'update']);
            Route::post('/events/{id}/submit-approval', [EventController::class, 'submitApproval']);
            Route::post('/events/{id}/request-cancellation', [EventController::class, 'requestCancellation']);

            // Staff Registration Management
            Route::delete('/events/{id}/registrations/{registrationId}', [RegistrationController::class, 'cancelByStaff']);

            // QR Attendance Scanner & Manual Marking
            Route::post('/events/{id}/attendance/scan', [AttendanceController::class, 'scan'])->middleware('throttle:60,1');
            Route::post('/events/{id}/attendance/mark', [AttendanceController::class, 'mark']);
            Route::put('/attendance/{id}/correct', [AttendanceController::class, 'correct']);

            // Organizer Dashboard
            Route::get('/dashboard/organizer', [DashboardController::class, 'organizer']);
        });

        // ====================================================================
        // Role: Administrator Only
        // ====================================================================
        Route::middleware('role:administrator')->group(function () {
            // Event Approvals
            Route::post('/admin/events/{id}/review', [EventController::class, 'reviewApproval']);
            Route::post('/admin/events/{id}/review-cancellation', [EventController::class, 'reviewCancellation']);

            // User Management
            Route::get('/admin/users', [AdminController::class, 'listUsers']);
            Route::post('/admin/users', [AdminController::class, 'createUser']);
            Route::patch('/admin/users/{id}/status', [AdminController::class, 'toggleStatus']);
            Route::post('/admin/users/{id}/reset-password', [AdminController::class, 'resetPassword']);

            // QR Inspection & Reissue
            Route::get('/admin/students/{id}/qr', [StudentQRController::class, 'inspect']);
            Route::post('/admin/students/{id}/qr/reissue', [StudentQRController::class, 'adminReissue']);

            // System Announcements
            Route::post('/admin/announcements', [AdminController::class, 'sendAnnouncement']);

            // Audit Logs & Admin Dashboard
            Route::get('/admin/logs', [AdminController::class, 'activityLogs']);
            Route::get('/dashboard/admin', [DashboardController::class, 'admin']);
        });

        // ====================================================================
        // Role: School Management, Organizer, & Administrator (Read-Only / Monitoring)
        // ====================================================================
        Route::middleware('role:administrator,organizer,management')->group(function () {
            // Attendee / Registration List & Live Attendance Monitor
            Route::get('/events/{id}/registrations', [RegistrationController::class, 'index']);
            Route::get('/events/{id}/attendance', [AttendanceController::class, 'index']);

            // Reports
            Route::get('/reports/event-attendance/{id}', [ReportController::class, 'eventAttendance']);
            Route::get('/reports/student-history/{id}', [ReportController::class, 'studentHistory']);
            Route::get('/reports/registration-summary/{id}', [ReportController::class, 'registrationSummary']);
            Route::get('/reports/participation-summary', [ReportController::class, 'participationSummary']);
            Route::get('/reports/absentee/{id}', [ReportController::class, 'absentee']);
            Route::get('/reports/walk-in/{id}', [ReportController::class, 'walkIn']);
            Route::get('/reports/organizer-summary', [ReportController::class, 'organizerSummary']);
            Route::get('/reports/export', [ReportController::class, 'export']);

            // Management Dashboard
            Route::get('/dashboard/management', [DashboardController::class, 'management']);
        });
    });
});

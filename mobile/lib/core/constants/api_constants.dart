import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  const ApiConstants._();

  /// Base URL for API v1 requests.
  /// Uses 10.0.2.2 for Android Emulator, or 127.0.0.1 for iOS/desktop/web.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  // ===========================================================================
  // Auth & Profile
  // ===========================================================================
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String changePassword = '/profile/change-password';

  // ===========================================================================
  // Student QR
  // ===========================================================================
  static const String studentQr = '/student/qr';
  static const String reissueQr = '/student/qr/reissue';
  static String adminStudentQr(int studentId) =>
      '/admin/students/$studentId/qr';
  static String adminReissueStudentQr(int studentId) =>
      '/admin/students/$studentId/qr/reissue';

  // ===========================================================================
  // Events & Approvals
  // ===========================================================================
  static const String events = '/events';
  static String eventDetail(int id) => '/events/$id';
  static String eventDetails(int id) => '/events/$id';
  static String submitEventApproval(int id) => '/events/$id/submit-approval';
  static String requestEventCancellation(int id) =>
      '/events/$id/request-cancellation';
  static String adminReviewEvent(int id) => '/admin/events/$id/review';
  static String adminReviewCancellation(int id) =>
      '/admin/events/$id/review-cancellation';

  // ===========================================================================
  // Registrations
  // ===========================================================================
  static const String studentRegistrations = '/student/registrations';
  static const String myRegistrations = '/student/registrations';
  static String eventRegistrations(int eventId) =>
      '/events/$eventId/registrations';
  static String registerEvent(int eventId) => '/events/$eventId/register';
  static String cancelRegistration(int eventId) =>
      '/events/$eventId/cancel-registration';
  static String staffCancelRegistration(int eventId, int regId) =>
      '/events/$eventId/registrations/$regId';

  // ===========================================================================
  // Attendance
  // ===========================================================================
  static String scanAttendance(int eventId) =>
      '/events/$eventId/attendance/scan';
  static String eventAttendance(int eventId) => '/events/$eventId/attendance';
  static String liveAttendance(int id) => '/events/$id/attendance';
  static String markAttendance(int eventId) =>
      '/events/$eventId/attendance/mark';
  static String correctAttendance(int attendanceId) =>
      '/attendance/$attendanceId/correct';
  static const String studentAttendanceHistory = '/student/attendance-history';
  static const String myAttendanceHistory = '/student/attendance-history';

  // ===========================================================================
  // Dashboards
  // ===========================================================================
  static String dashboard(String role) => '/dashboard/$role';
  static const String studentDashboard = '/dashboard/student';
  static const String organizerDashboard = '/dashboard/organizer';
  static const String managementDashboard = '/dashboard/management';
  static const String adminDashboard = '/dashboard/admin';

  // ===========================================================================
  // Notifications
  // ===========================================================================
  static const String notifications = '/notifications';
  static String markNotificationRead(int id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';
  static const String notificationPreferences = '/notifications/preferences';
  static const String deviceTokens = '/device-tokens';

  // ===========================================================================
  // Reports
  // ===========================================================================
  static String reportEventAttendance(int eventId) =>
      '/reports/event-attendance/$eventId';
  static String reportStudentHistory(int studentId) =>
      '/reports/student-history/$studentId';
  static String reportRegistrationSummary(int eventId) =>
      '/reports/registration-summary/$eventId';
  static const String reportParticipationSummary =
      '/reports/participation-summary';
  static String reportAbsentee(int eventId) => '/reports/absentee/$eventId';
  static String reportWalkIn(int eventId) => '/reports/walk-in/$eventId';
  static const String reportOrganizerSummary = '/reports/organizer-summary';
  static const String exportReport = '/reports/export';

  // ===========================================================================
  // Admin
  // ===========================================================================
  static const String adminUsers = '/admin/users';
  static String adminUserStatus(int id) => '/admin/users/$id/status';
  static String adminResetPassword(int id) => '/admin/users/$id/reset-password';
  static const String adminLogs = '/admin/logs';
  static const String adminAnnouncements = '/admin/announcements';
}

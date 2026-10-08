import 'dart:io';

class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/desktop, or custom LAN IP for physical phone
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://127.0.0.1:8000/api/v1';
    }
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/profile';
  static const String updateProfile = '/profile';
  static const String changePassword = '/profile/change-password';

  // QR
  static const String studentQr = '/student/qr';
  static const String reissueQr = '/student/qr/reissue';

  // Events & Registration
  static const String events = '/events';
  static String eventDetails(int id) => '/events/$id';
  static String registerEvent(int id) => '/events/$id/register';
  static String cancelRegistration(int id) => '/events/$id/cancel-registration';
  static const String myRegistrations = '/student/registrations';

  // Attendance
  static String scanAttendance(int id) => '/events/$id/attendance/scan';
  static String liveAttendance(int id) => '/events/$id/attendance';
  static const String myAttendanceHistory = '/student/attendance-history';

  // Dashboard
  static String dashboard(String role) => '/dashboard/$role';

  // Notifications
  static const String notifications = '/notifications';
  static const String deviceTokens = '/device-tokens';
}

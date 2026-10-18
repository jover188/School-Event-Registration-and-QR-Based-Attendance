import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/core/widgets/empty_state_view.dart';
import 'package:school_event_attendance/core/widgets/error_state_view.dart';
import 'package:school_event_attendance/core/widgets/event_card.dart';
import 'package:school_event_attendance/core/widgets/section_header.dart';
import 'package:school_event_attendance/core/widgets/stat_metric_card.dart';
import 'package:school_event_attendance/core/widgets/status_badge.dart';
import 'package:school_event_attendance/models/attendance_model.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/models/user_model.dart';
import 'package:school_event_attendance/screens/auth/login_screen.dart';
import 'package:school_event_attendance/screens/organizer/event_form_screen.dart';
import 'support/app_test_host.dart';

void main() {
  group('Model Parsing Tests', () {
    test('UserModel.fromJson parses student profile and user fields accurately',
        () {
      final json = {
        'id': 4,
        'email': 'juan.delacruz@school.edu',
        'role': 'student',
        'status': 'active',
        'student_profile': {
          'id': 1,
          'student_id_number': '20260001',
          'full_name': 'Juan M. Dela Cruz',
          'course': 'BS Computer Science',
          'year_level': '3rd Year',
          'section': 'CS-3A',
          'department': 'College of Computer Studies',
          'contact_number': '+639171234567',
          'profile_photo_url': 'https://example.com/photo.jpg',
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 4);
      expect(user.email, 'juan.delacruz@school.edu');
      expect(user.role, 'student');
      expect(user.status, 'active');
      expect(user.studentProfile, isNotNull);
      expect(user.studentProfile!.studentIdNumber, '20260001');
      expect(user.studentProfile!.fullName, 'Juan M. Dela Cruz');
      expect(user.studentProfile!.course, 'BS Computer Science');
    });

    test(
        'EventModel.fromJson parses capacity, walk-in, and registration status',
        () {
      final json = {
        'id': 12,
        'title': 'Annual IT Symposium 2026',
        'description': 'Flagship symposium',
        'venue': 'University Main Auditorium',
        'event_date': '2026-10-15',
        'start_time': '08:00:00',
        'end_time': '17:00:00',
        'max_participants': 200,
        'remaining_slots': 58,
        'current_registered_count': 142,
        'late_grace_period_minutes': 15,
        'walk_in_allowed': 1,
        'status': 'published',
        'user_registration_status': 'registered',
        'user_waiting_position': null,
      };

      final event = EventModel.fromJson(json);
      expect(event.id, 12);
      expect(event.title, 'Annual IT Symposium 2026');
      expect(event.walkInAllowed, isTrue);
      expect(event.isRegistered, isTrue);
      expect(event.isWaitingList, isFalse);
      expect(event.remainingSlots, 58);
    });

    test('AttendanceModel.fromJson parses check-in and check-out timestamps',
        () {
      final json = {
        'attendance_id': 98,
        'status': 'present',
        'check_in_time': '2026-10-15T08:04:12+08:00',
        'check_out_time': '2026-10-15T17:01:00+08:00',
        'student': {
          'id': 1,
          'student_id_number': '20260001',
          'full_name': 'Juan M. Dela Cruz',
          'course': 'BS Computer Science',
        },
      };

      final attendance = AttendanceModel.fromJson(json);
      expect(attendance.id, 98);
      expect(attendance.status, 'present');
      expect(attendance.checkInTime, '2026-10-15T08:04:12+08:00');
      expect(attendance.checkOutTime, '2026-10-15T17:01:00+08:00');
      expect(attendance.student?.studentIdNumber, '20260001');
    });
  });

  group('Design Tokens & ApiConstants Tests', () {
    test('AppColors status helpers return semantic colors', () {
      expect(AppColors.statusColor('present'), AppColors.present);
      expect(AppColors.statusColor('published'), AppColors.present);
      expect(AppColors.statusColor('late'), AppColors.late);
      expect(AppColors.statusColor('pending_approval'), AppColors.late);
      expect(AppColors.statusColor('waiting_list'), AppColors.waiting);
      expect(AppColors.statusColor('walk_in'), AppColors.walkIn);
      expect(AppColors.statusColor('excused'), AppColors.excused);
      expect(AppColors.statusColor('absent'), AppColors.absent);
      expect(AppColors.statusColor('cancelled'), AppColors.absent);
      expect(AppTheme.primaryColor, AppColors.primary);
      expect(AppTheme.secondaryColor, AppColors.secondary);
      expect(AppTheme.waitingColor, AppColors.waiting);
    });

    test('ApiConstants defines complete v1 route paths', () {
      expect(ApiConstants.login, '/auth/login');
      expect(ApiConstants.verifyEmail, '/auth/verify-email');
      expect(ApiConstants.adminStudentQr(5), '/admin/students/5/qr');
      expect(
        ApiConstants.adminReissueStudentQr(5),
        '/admin/students/5/qr/reissue',
      );
      expect(ApiConstants.eventDetail(10), '/events/10');
      expect(
        ApiConstants.submitEventApproval(10),
        '/events/10/submit-approval',
      );
      expect(
        ApiConstants.requestEventCancellation(10),
        '/events/10/request-cancellation',
      );
      expect(ApiConstants.adminReviewEvent(10), '/admin/events/10/review');
      expect(
        ApiConstants.adminReviewCancellation(10),
        '/admin/events/10/review-cancellation',
      );
      expect(
        ApiConstants.staffCancelRegistration(10, 42),
        '/events/10/registrations/42',
      );
      expect(ApiConstants.markAttendance(10), '/events/10/attendance/mark');
      expect(ApiConstants.correctAttendance(99), '/attendance/99/correct');
      expect(ApiConstants.markNotificationRead(3), '/notifications/3/read');
      expect(
        ApiConstants.reportEventAttendance(10),
        '/reports/event-attendance/10',
      );
      expect(ApiConstants.exportReport, '/reports/export');
      expect(ApiConstants.adminUsers, '/admin/users');
      expect(ApiConstants.adminAnnouncements, '/admin/announcements');
    });

    test('ApiClient token storage falls back cleanly in test environment',
        () async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient().saveToken('test-token-123', 'organizer');
      expect(await ApiClient().getToken(), 'test-token-123');
      expect(await ApiClient().getUserRole(), 'organizer');
      await ApiClient().clearToken();
      expect(await ApiClient().getToken(), isNull);
    });
  });

  group('Reusable Widget Component Library Tests', () {
    testWidgets('StatusBadge renders uppercase label and semantic status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'pending_approval'),
          ),
        ),
      );

      expect(find.text('PENDING APPROVAL'), findsOneWidget);
    });

    testWidgets('StatMetricCard renders label, value, and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatMetricCard(
              label: 'Registered',
              value: '42',
              icon: Icons.event_available,
              subtitle: 'This semester',
            ),
          ),
        ),
      );

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('This semester'), findsOneWidget);
    });

    testWidgets('EmptyStateView and ErrorStateView trigger callbacks',
        (WidgetTester tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const EmptyStateView(
                  title: 'No events found',
                  message: 'Check back later',
                ),
                ErrorStateView(
                  message: 'Connection failed',
                  onRetry: () => retried = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No events found'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('SectionHeader and EventCard render event metadata accurately',
        (WidgetTester tester) async {
      final event = EventModel(
        id: 7,
        title: 'Cybersecurity Workshop',
        description: 'Hands-on defense workshop',
        venue: 'Lab 302',
        eventDate: '2026-11-05',
        startTime: '09:00:00',
        endTime: '12:00:00',
        maxParticipants: 100,
        remainingSlots: 20,
        currentRegisteredCount: 80,
        lateGracePeriodMinutes: 15,
        walkInAllowed: true,
        status: 'published',
        userRegistrationStatus: 'registered',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SectionHeader(
                  title: 'Upcoming Events',
                  subtitle: 'Campus schedule',
                ),
                EventCard(
                  event: event,
                  showCapacity: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Cybersecurity Workshop'), findsOneWidget);
      expect(find.text('REGISTERED'), findsOneWidget);
      expect(find.text('Registered: 80 / 100'), findsOneWidget);
    });
  });

  testWidgets('LoginScreen renders branded header and form inputs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: LoginScreen(),
      ),
    );

    expect(
      find.byKey(const ValueKey('attendify-login-logo')),
      findsOneWidget,
    );
    expect(find.text('Welcome back! Log in to continue.'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-submit-button')), findsOneWidget);
    expect(find.text('ID or email'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsNothing);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.byKey(const ValueKey('forgot-password-action')), findsNothing);
    expect(find.textContaining('pre-provisioned'), findsNothing);
    expect(find.text('Register Here'), findsNothing);
  });

  testWidgets('EventFormScreen renders create and edit draft controls',
      (WidgetTester tester) async {
    final draftEvent = EventModel(
      id: 21,
      title: 'Draft Seminar',
      description: 'Draft description',
      venue: 'Room 101',
      eventDate: '2026-12-01',
      startTime: '09:00:00',
      endTime: '12:00:00',
      maxParticipants: 50,
      remainingSlots: 50,
      currentRegisteredCount: 0,
      lateGracePeriodMinutes: 15,
      walkInAllowed: false,
      status: 'draft',
    );

    await tester.pumpWidget(
      AppTestHost(
        child: EventFormScreen(event: draftEvent),
      ),
    );

    expect(find.text('Edit Event'), findsOneWidget);
    expect(find.text('Draft Seminar'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit for Admin Approval'));
    await tester.pumpAndSettle();

    expect(find.text('Submit for Admin Approval'), findsOneWidget);
  });
}

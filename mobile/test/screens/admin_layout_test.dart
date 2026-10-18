import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/screens/admin/activity_logs_screen.dart';
import 'package:school_event_attendance/screens/admin/admin_dashboard_screen.dart';
import 'package:school_event_attendance/screens/admin/student_qr_inspect_screen.dart';
import 'package:school_event_attendance/screens/admin/user_management_screen.dart';
import '../support/app_test_host.dart';

void main() {
  const sampleUsers = <Map<String, dynamic>>[
    {
      'id': 11,
      'email': 'organizer.santos@school.edu',
      'status': 'active',
      'role': {'slug': 'organizer'},
    },
    {
      'id': 12,
      'email': 'juan.delacruz@school.edu',
      'status': 'active',
      'role': {'slug': 'student'},
      'student': {
        'id': 42,
        'student_id_number': '20260042',
        'full_name': 'Juan M. Dela Cruz',
        'course': 'BS Computer Science',
      },
    },
  ];

  const sampleLogs = <Map<String, dynamic>>[
    {
      'id': 501,
      'action': 'attendance_corrected_by_organizer',
      'module': 'attendance',
      'record_id': 987,
      'ip_address': '192.168.10.45',
      'created_at': '2026-10-17T09:15:22Z',
      'user': {'id': 2, 'email': 'organizer.very.long.address@school.edu.ph'},
      'metadata': {
        'previous_status': 'absent',
        'updated_status': 'excused',
        'reason':
            'Official inter-university competition endorsement signed by the Dean of Student Affairs and verified by department chair with attached supporting medical/travel documentation.',
        'correlation_trace':
            'trace-id-00918273645546372819-audit-verification-segment-alpha-omega',
      },
    },
  ];

  testWidgets(
    'AdminDashboardScreen navigates across compact More sheet (390x844) and expanded sidebar (1440x900)',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AppTestHost(
          child: AdminDashboardScreen(
            initialCounts: {
              'pending_event_approvals': 2,
              'total_users': 148,
              'total_students': 140,
              'active_permanent_qrs': 138,
            },
            initialUsersByRole: {
              'administrator': 1,
              'organizer': 5,
              'student': 140,
              'management': 2,
            },
            initialEventsByStatus: {
              'pending_approval': 2,
              'published': 6,
              'ongoing': 1,
              'completed': 12,
            },
            initialPendingEvents: [
              {
                'id': 301,
                'title': 'Annual Research Colloquium',
                'venue': 'Main Auditorium',
                'event_date': '2026-11-12',
                'status': 'pending_approval',
                'organizer': {'email': 'research.org@school.edu'},
              },
            ],
            initialUsers: sampleUsers,
            initialLogs: sampleLogs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Primary destinations visible in compact bottom bar; secondary tucked into More.
      expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-reviews')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-users')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-more')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('destination-qr-records')),
        findsNothing,
      );

      // Open More dialog and navigate to QR Records.
      await tester.tap(find.byKey(const ValueKey('destination-more')));
      await tester.pumpAndSettle();
      expect(find.text('QR Records'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Activity'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('destination-qr-records')));
      await tester.pumpAndSettle();
      expect(
        find.text('Student QR Identity Directory'),
        findsOneWidget,
      );

      // Open More again and navigate to Activity logs.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Activity'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('destination-activity')));
      await tester.pumpAndSettle();
      expect(find.text('Audit Trail & Activity Logs'), findsOneWidget);

      // Resize to 1440x900 desktop and verify all 6 destinations are directly visible in sidebar.
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-reviews')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-users')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('destination-qr-records')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('destination-reports')), findsOneWidget);
      expect(find.byKey(const ValueKey('destination-activity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AdminDashboardScreen reviews destination handles Approve & Publish and Reject remarks dialogs',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AppTestHost(
          child: AdminDashboardScreen(
            initialDestinationId: 'reviews',
            initialCounts: {'pending_event_approvals': 2},
            initialPendingEvents: [
              {
                'id': 101,
                'title': 'Campus Cybersecurity Summit',
                'venue': 'Engineering Hall',
                'event_date': '2026-11-18',
                'status': 'pending_approval',
                'organizer': {'email': 'sec.org@school.edu'},
              },
              {
                'id': 102,
                'title': 'Incomplete Draft Submission',
                'venue': 'Room 204',
                'event_date': '2026-11-20',
                'status': 'pending_approval',
                'organizer': {'email': 'draft.org@school.edu'},
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Campus Cybersecurity Summit'), findsOneWidget);
      expect(find.text('Incomplete Draft Submission'), findsOneWidget);

      // Approve event #101 with remarks
      await tester.tap(find.byKey(const ValueKey('approve-event-101')));
      await tester.pumpAndSettle();
      expect(find.text('Approve Event?'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('review-remarks-field')),
        'Venue and security plan verified.',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-review-approved')));
      await tester.pumpAndSettle();

      expect(find.text('Campus Cybersecurity Summit'), findsNothing);
      expect(find.text('Incomplete Draft Submission'), findsOneWidget);

      // Reject event #102 with remarks
      await tester.tap(find.byKey(const ValueKey('reject-event-102')));
      await tester.pumpAndSettle();
      expect(find.text('Reject Event?'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('review-remarks-field')),
        'Please attach speaker confirmation.',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-review-rejected')));
      await tester.pumpAndSettle();

      expect(find.text('Incomplete Draft Submission'), findsNothing);
      expect(find.text('No events currently pending review.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UserManagementScreen status change and password reset confirmations fit at 320x568 (2x text) and 1440x900',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AppTestHost(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: UserManagementScreen(
              initialUsers: sampleUsers,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll to user #11 status button and open confirmation dialog at 320px 2x text
      final toggleBtn = find.byKey(const ValueKey('toggle-user-status-11'));
      await tester.scrollUntilVisible(
        toggleBtn,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Deactivate User Account?'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final confirmStatusBtn = find.byKey(
        const ValueKey('confirm-user-status-button'),
      );
      await tester.ensureVisible(confirmStatusBtn);
      await tester.tap(confirmStatusBtn);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Open Reset Password dialog at 320px 2x text
      final resetBtn = find.byKey(const ValueKey('reset-user-password-11'));
      await tester.scrollUntilVisible(
        resetBtn,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset User Password'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('reset-password-field')),
        'NewStrongPass123!',
      );
      final confirmResetBtn = find.byKey(
        const ValueKey('confirm-reset-password-button'),
      );
      await tester.ensureVisible(confirmResetBtn);
      await tester.tap(confirmResetBtn);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify at 1440x900 desktop as well
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(
        const AppTestHost(
          child: UserManagementScreen(
            initialUsers: sampleUsers,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('organizer.santos@school.edu'), findsOneWidget);
      expect(find.text('juan.delacruz@school.edu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'StudentQrInspectScreen renders capped QR frame and scrollable replacement confirmation at 320x568 (2x text) and 1440x900',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const qrPayload = <String, dynamic>{
        'student_id': 42,
        'student_id_number': '20260042',
        'full_name': 'Juan M. Dela Cruz',
        'active_qr': {
          'qr_token':
              'a1b2c3d4e5f60718a1b2c3d4e5f60718a1b2c3d4e5f60718a1b2c3d4e5f60718',
          'status': 'active',
          'created_at': '2026-09-01T08:00:00Z',
        },
        'qr_history': [
          {
            'qr_token':
                '0011223344556677001122334455667700112233445566770011223344556677',
            'status': 'revoked',
            'created_at': '2026-06-01T08:00:00Z',
            'revoked_at': '2026-09-01T08:00:00Z',
          },
        ],
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: StudentQrInspectScreen(
              studentId: 42,
              studentLabel: 'Juan M. Dela Cruz',
              initialData: qrPayload,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final reissueBtn = find.byKey(const ValueKey('force-reissue-qr-button'));
      await tester.ensureVisible(reissueBtn);
      await tester.pumpAndSettle();
      await tester.tap(reissueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Force Reissue Permanent QR?'), findsOneWidget);
      expect(find.textContaining('immediately revoke'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final confirmBtn = find.byKey(
        const ValueKey('confirm-force-reissue-button'),
      );
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify at 1440x900 desktop
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(
        const AppTestHost(
          child: StudentQrInspectScreen(
            studentId: 42,
            studentLabel: 'Juan M. Dela Cruz',
            initialData: qrPayload,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Juan M. Dela Cruz'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ActivityLogsScreen wraps and expands long metadata payloads cleanly at 320x568 at 2x text scale',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AppTestHost(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: ActivityLogsScreen(
              initialLogs: sampleLogs,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final expandBtn = find.text('Expand Full Metadata');
      await tester.scrollUntilVisible(
        expandBtn,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      expect(find.text('Show Less'), findsOneWidget);
      expect(
        find.textContaining('correlation_trace'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

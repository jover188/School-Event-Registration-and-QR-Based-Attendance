import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/screens/management/management_dashboard_screen.dart';
import 'package:school_event_attendance/screens/organizer/event_registrations_screen.dart';
import 'package:school_event_attendance/screens/organizer/live_attendance_screen.dart';
import '../support/app_test_host.dart';

const Map<String, dynamic> _fixtureMetrics = {
  'overall_turnout_rate': '88.4%',
  'total_events': 14,
  'total_registrations': 1240,
  'total_attendances': 1096,
};

const Map<String, dynamic> _fixtureBreakdown = {
  'present': 940,
  'late': 92,
  'walk_in': 44,
  'excused': 20,
};

const List<Map<String, dynamic>> _fixtureEvents = [
  {
    'id': 101,
    'title':
        'Annual University Research & Innovation Colloquium for Computing Sciences',
    'event_date': '2026-10-20T08:00:00Z',
    'venue': 'Main Academic Auditorium & Conference Complex',
    'attendances_count': 245,
  },
  {
    'id': 102,
    'title': 'Campus Cybersecurity Readiness Seminar',
    'event_date': '2026-11-04T09:00:00Z',
    'venue': 'Engineering Lecture Hall B',
    'attendances_count': 118,
  },
];

const List<String> _forbiddenMutations = [
  'Create Event',
  'Edit Event',
  'Scan QR',
  'Correct',
  'Cancel Registration',
  'User Management',
];

void _assertNoMutationControls() {
  for (final label in _forbiddenMutations) {
    expect(
      find.text(label),
      findsNothing,
      reason: 'Management must never display "$label"',
    );
  }
}

void main() {
  group('ManagementDashboardScreen responsive & RBAC layout tests', () {
    testWidgets(
      'adapts across compact (390x844), medium (768x1024), and expanded (1440x900) without mutation controls',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final size in const [
          Size(390, 844),
          Size(768, 1024),
          Size(1440, 900),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            AppTestHost(
              child: MediaQuery(
                data: MediaQueryData(size: size),
                child: const ManagementDashboardScreen(
                  initialMetrics: _fixtureMetrics,
                  initialStatusBreakdown: _fixtureBreakdown,
                  initialRecentEvents: _fixtureEvents,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'size $size');
          expect(find.text('88.4%'), findsOneWidget);
          expect(find.text('1240'), findsOneWidget);
          expect(find.byTooltip('Notifications'), findsOneWidget);
          expect(find.byTooltip('My Profile'), findsOneWidget);
          _assertNoMutationControls();
        }
      },
    );

    testWidgets(
      'switches cleanly between overview, events, and reports destinations and retains search state',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1440, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(size: Size(1440, 900)),
              child: ManagementDashboardScreen(
                initialMetrics: _fixtureMetrics,
                initialStatusBreakdown: _fixtureBreakdown,
                initialRecentEvents: _fixtureEvents,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('School Management (Read-Only)'), findsOneWidget);
        _assertNoMutationControls();

        // Switch to Events destination
        await tester.tap(find.byKey(const ValueKey('destination-events')));
        await tester.pumpAndSettle();

        expect(find.text('Campus Events (Read-Only)'), findsOneWidget);
        expect(find.text('Institutional Events Directory'), findsOneWidget);
        _assertNoMutationControls();

        // Filter events in the Events destination
        await tester.enterText(
          find.byKey(const ValueKey<String>('management-event-search-field')),
          'Cybersecurity',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Campus Cybersecurity Readiness Seminar'),
          findsOneWidget,
        );

        // Switch to Reports destination
        await tester.tap(find.byKey(const ValueKey('destination-reports')));
        await tester.pumpAndSettle();

        expect(find.text('Reports & Analytics'), findsOneWidget);
        expect(find.text('Report Configuration'), findsOneWidget);
        _assertNoMutationControls();

        // Switch back to Events destination and verify search filter was preserved
        await tester.tap(find.byKey(const ValueKey('destination-events')));
        await tester.pumpAndSettle();
        expect(find.text('Cybersecurity'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders 320x568 at 2x text scale without overflow and keeps More menu strictly read-only',
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
                textScaler: TextScaler.linear(2.0),
              ),
              child: ManagementDashboardScreen(
                initialMetrics: _fixtureMetrics,
                initialStatusBreakdown: _fixtureBreakdown,
                initialRecentEvents: _fixtureEvents,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        _assertNoMutationControls();

        // At 2x text scale on 320x568, Overview and Reports are essential and Events is in More
        expect(find.byKey(const ValueKey('destination-more')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('destination-more')));
        await tester.pumpAndSettle();

        _assertNoMutationControls();
        expect(find.text('Events'), findsOneWidget);
        await tester.tap(find.text('Events'));
        await tester.pumpAndSettle();

        expect(find.text('Campus Events (Read-Only)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        _assertNoMutationControls();
      },
    );

    testWidgets(
      'passes canCancel: false to EventRegistrationsScreen and canCorrect: false to LiveAttendanceScreen',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1024, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(size: Size(1024, 900)),
              child: ManagementDashboardScreen(
                initialMetrics: _fixtureMetrics,
                initialStatusBreakdown: _fixtureBreakdown,
                initialRecentEvents: _fixtureEvents,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Registrations (RO)').first);
        await tester.tap(find.text('Registrations (RO)').first);
        await tester.pumpAndSettle();

        final regScreen = tester.widget<EventRegistrationsScreen>(
          find.byType(EventRegistrationsScreen),
        );
        expect(regScreen.canCancel, isFalse);

        Navigator.of(tester.element(find.byType(EventRegistrationsScreen)))
            .pop();
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Attendance (RO)').first);
        await tester.tap(find.text('Attendance (RO)').first);
        await tester.pumpAndSettle();

        final attScreen = tester.widget<LiveAttendanceScreen>(
          find.byType(LiveAttendanceScreen),
        );
        expect(attScreen.canCorrect, isFalse);
      },
    );
  });
}

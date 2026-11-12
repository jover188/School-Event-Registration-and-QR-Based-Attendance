import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/screens/admin/admin_dashboard_screen.dart';
import 'package:school_event_attendance/screens/management/management_dashboard_screen.dart';
import 'package:school_event_attendance/screens/organizer/organizer_dashboard_screen.dart';
import 'package:school_event_attendance/screens/student/student_dashboard_screen.dart';
import '../support/app_test_host.dart';

void main() {
  group('Attendify - 3-Item Bottom Navigation Simplification Suite', () {
    const compactMobileSize = Size(390, 844);
    const desktopSize = Size(1440, 900);

    testWidgets(
      'Admin Dashboard: has EXACTLY 3 bottom nav items (Overview, Reviews, Users), no More button, secondary in sidebar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = compactMobileSize;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: AdminDashboardScreen(
              initialCounts: {
                'pending_event_approvals': 1,
                'total_users': 20,
                'total_students': 15,
                'active_permanent_qrs': 15,
              },
              initialUsers: [],
              initialLogs: [],
              initialPendingEvents: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify EXACTLY 3 bottom navigation items exist
        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-reviews')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-users')), findsOneWidget);

        // Verify More button is NOT present in bottom nav
        expect(find.byKey(const ValueKey('destination-more')), findsNothing);

        // Verify secondary items are NOT in bottom navigation bar
        expect(find.byKey(const ValueKey('destination-reports')), findsNothing);
        expect(find.byKey(const ValueKey('destination-qr-records')), findsNothing);
        expect(find.byKey(const ValueKey('destination-activity')), findsNothing);

        // Open mobile slide-over drawer via header logo trigger
        final drawerTrigger = find.byKey(const ValueKey('mobile-drawer-trigger'));
        expect(drawerTrigger, findsOneWidget);
        await tester.tap(drawerTrigger);
        await tester.pumpAndSettle();

        // Verify secondary features moved to sidebar are accessible in mobile drawer
        expect(find.byKey(const ValueKey('drawer-destination-reports')), findsOneWidget);
        expect(find.byKey(const ValueKey('drawer-destination-qr-records')), findsOneWidget);
        expect(find.byKey(const ValueKey('drawer-destination-activity')), findsOneWidget);
        expect(find.byKey(const ValueKey('drawer-destination-calendar')), findsOneWidget);

        // Dismiss drawer
        await tester.tap(find.byTooltip('Close navigation drawer'));
        await tester.pumpAndSettle();

        // Resize to desktop and verify all sidebar items are present
        tester.view.physicalSize = desktopSize;
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-reviews')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-users')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-reports')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-qr-records')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-activity')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
      },
    );

    testWidgets(
      'Organizer Dashboard: has EXACTLY 3 bottom nav items (Overview, Calendar, My Events), Reports in sidebar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = compactMobileSize;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: OrganizerDashboardScreen(
              initialEvents: [],
              initialSummary: {
                'total_events': 3,
                'published_events': 2,
                'ongoing_events': 1,
                'pending_events': 0,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify EXACTLY 3 bottom navigation items exist
        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);

        // Verify Reports and More are NOT in bottom navigation bar
        expect(find.byKey(const ValueKey('destination-reports')), findsNothing);
        expect(find.byKey(const ValueKey('destination-more')), findsNothing);

        // Open mobile slide-over drawer
        final drawerTrigger = find.byKey(const ValueKey('mobile-drawer-trigger'));
        expect(drawerTrigger, findsOneWidget);
        await tester.tap(drawerTrigger);
        await tester.pumpAndSettle();

        // Reports moved to sidebar is accessible in drawer
        expect(find.byKey(const ValueKey('drawer-destination-reports')), findsOneWidget);

        // Dismiss drawer
        await tester.tap(find.byTooltip('Close navigation drawer'));
        await tester.pumpAndSettle();

        // Resize to desktop and verify sidebar has Overview, Calendar, My Events, Reports
        tester.view.physicalSize = desktopSize;
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-reports')), findsOneWidget);
      },
    );

    testWidgets(
      'Student Dashboard: has EXACTLY 3 bottom nav items (Events, Calendar, My Registration), My QR in sidebar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = compactMobileSize;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: StudentDashboardScreen(
              initialEvents: [],
              initialStats: {
                'total_registered_events': 1,
                'total_attended_events': 2,
                'waiting_list_count': 0,
              },
              initialRegistrations: [],
              initialQrData: {
                'qr_token': 'sample_qr_token_64_characters_long_0123456789abcdef0123456789abcdef',
                'full_name': 'Maria Santos',
                'student_id_number': '20260099',
                'status': 'active',
              },
              initialAttendanceRecords: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify EXACTLY 3 bottom navigation items exist
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-registrations')), findsOneWidget);

        // Verify My QR, Profile, History, More are NOT in bottom bar
        expect(find.byKey(const ValueKey('destination-qr')), findsNothing);
        expect(find.byKey(const ValueKey('destination-profile')), findsNothing);
        expect(find.byKey(const ValueKey('destination-history')), findsNothing);
        expect(find.byKey(const ValueKey('destination-more')), findsNothing);

        // Open mobile slide-over drawer
        final drawerTrigger = find.byKey(const ValueKey('mobile-drawer-trigger'));
        expect(drawerTrigger, findsOneWidget);
        await tester.tap(drawerTrigger);
        await tester.pumpAndSettle();

        // My QR, Profile, History are accessible in drawer
        expect(find.byKey(const ValueKey('drawer-destination-qr')), findsOneWidget);
        expect(find.byKey(const ValueKey('drawer-destination-profile')), findsOneWidget);
        expect(find.byKey(const ValueKey('drawer-destination-history')), findsOneWidget);

        // Dismiss drawer
        await tester.tap(find.byTooltip('Close navigation drawer'));
        await tester.pumpAndSettle();

        // Resize to desktop and verify all sidebar destinations
        tester.view.physicalSize = desktopSize;
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-registrations')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-qr')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-profile')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-history')), findsOneWidget);
      },
    );

    testWidgets(
      'Management Dashboard: has EXACTLY 3 bottom nav items (Overview, Events, Calendar), Reports in sidebar',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = compactMobileSize;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: ManagementDashboardScreen(
              initialMetrics: {
                'overall_turnout_rate': '91.2%',
                'total_events': 12,
                'total_registrations': 800,
                'total_attendances': 730,
              },
              initialStatusBreakdown: {
                'present': 650,
                'late': 50,
                'walk_in': 30,
              },
              initialRecentEvents: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify EXACTLY 3 bottom navigation items exist
        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);

        // Verify Reports and More are NOT in bottom navigation bar
        expect(find.byKey(const ValueKey('destination-reports')), findsNothing);
        expect(find.byKey(const ValueKey('destination-more')), findsNothing);

        // Open mobile slide-over drawer
        final drawerTrigger = find.byKey(const ValueKey('mobile-drawer-trigger'));
        expect(drawerTrigger, findsOneWidget);
        await tester.tap(drawerTrigger);
        await tester.pumpAndSettle();

        // Reports moved to sidebar is accessible in drawer
        expect(find.byKey(const ValueKey('drawer-destination-reports')), findsOneWidget);

        // Dismiss drawer
        await tester.tap(find.byTooltip('Close navigation drawer'));
        await tester.pumpAndSettle();

        // Resize to desktop and verify all sidebar destinations
        tester.view.physicalSize = desktopSize;
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('destination-overview')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-calendar')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-reports')), findsOneWidget);
      },
    );
  });
}

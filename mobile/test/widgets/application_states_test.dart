import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/app_skeleton.dart';
import 'package:school_event_attendance/core/widgets/empty_state_view.dart';
import 'package:school_event_attendance/core/widgets/error_state_view.dart';
import 'package:school_event_attendance/core/widgets/offline_state_view.dart';
import 'package:school_event_attendance/core/widgets/server_unavailable_view.dart';
import 'package:school_event_attendance/screens/common/not_found_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../support/app_test_host.dart';

void main() {
  group('AppSkeleton and skeleton components', () {
    testWidgets('AppSkeleton renders with custom dimensions and shape',
        (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: Scaffold(
            body: Center(
              child: AppSkeleton(
                width: 120,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
    });

    testWidgets('AppSkeletonMetricCard matches StatMetricCard layout',
        (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: Scaffold(
            body: AppSkeletonMetricCard(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeletonMetricCard), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNWidgets(4));
    });

    testWidgets('AppSkeletonEventCard renders event placeholder layout',
        (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: Scaffold(
            body: AppSkeletonEventCard(showCapacity: true),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeletonEventCard), findsOneWidget);
      // Date tile, title lines, badges, venue, time, capacity bar
      expect(find.byType(AppSkeleton), findsWidgets);
    });

    testWidgets('AppSkeletonList renders multiple skeleton rows in sync',
        (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: Scaffold(
            body: AppSkeletonList(itemCount: 5),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeletonList), findsOneWidget);
      expect(find.byType(AppShimmer), findsOneWidget);
    });

    testWidgets('AppSkeleton adapts smoothly in dark mode', (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          themeMode: ThemeMode.dark,
          child: Scaffold(
            body: AppSkeletonMetricCard(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeletonMetricCard), findsOneWidget);
    });
  });

  group('OfflineStateView', () {
    testWidgets('renders icon, title, message, status badge, and retry button',
        (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: OfflineStateView(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text(
          'Unable to connect to the campus network. Please check your Wi-Fi or cellular data and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });
  });

  group('ServerUnavailableView', () {
    testWidgets(
        'renders icon, title, message, status badge, and invokes onRetry',
        (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: ServerUnavailableView(
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
      expect(find.text('Service Temporarily Unavailable'), findsOneWidget);
      expect(
        find.text(
          'The attendance server could not be reached. Please verify your connection or try again shortly.',
        ),
        findsOneWidget,
      );
      expect(find.text('UNREACHABLE'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });

    testWidgets('sanitizes SQL / database errors from raw error strings',
        (tester) async {
      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: ServerUnavailableView(
              message:
                  'SQLSTATE[HY000] [2002] Connection refused (PDOException: SQL select * from users)',
              onRetry: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('PDOException'), findsNothing);
      expect(
        find.text(
          'The attendance server encountered a temporary issue. Please try again in a few moments.',
        ),
        findsOneWidget,
      );
    });
  });

  group('NotFoundScreen', () {
    testWidgets('renders 404 display typography, title, and handles return home',
        (tester) async {
      var returnHomeCalled = false;

      await tester.pumpWidget(
        AppTestHost(
          child: NotFoundScreen(
            onReturnHome: () => returnHomeCalled = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
      expect(find.text('Page Not Found'), findsWidgets);
      expect(
        find.text('The requested screen does not exist or has been moved.'),
        findsOneWidget,
      );
      expect(find.text('Return to Home'), findsOneWidget);

      await tester.tap(find.text('Return to Home'));
      await tester.pump();
      expect(returnHomeCalled, isTrue);
    });
  });

  group('Modernized EmptyStateView and ErrorStateView', () {
    testWidgets('EmptyStateView renders with subtle entrance and accessibility',
        (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: EmptyStateView(
              icon: LucideIcons.calendar,
              title: 'No Events Scheduled',
              message: 'Check back later for newly announced institutional events.',
              actionLabel: 'Check Upcoming',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.text('No Events Scheduled'), findsOneWidget);
      expect(
        find.text(
            'Check back later for newly announced institutional events.'),
        findsOneWidget,
      );
      expect(find.text('Check Upcoming'), findsOneWidget);

      await tester.tap(find.text('Check Upcoming'));
      await tester.pump();
      expect(actionCalled, isTrue);
    });

    testWidgets('ErrorStateView renders with sanitized message and retry action',
        (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: ErrorStateView(
              title: 'Sync Failed',
              message:
                  'Critical PDOException: Table "attendances" not found in mysql',
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
      expect(find.text('Sync Failed'), findsOneWidget);
      expect(find.textContaining('PDOException'), findsNothing);
      expect(
        find.text(
          'An unexpected error occurred while communicating with the service. Please try again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });
  });
}

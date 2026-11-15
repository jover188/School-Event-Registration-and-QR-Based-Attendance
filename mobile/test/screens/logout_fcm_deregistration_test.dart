import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/services/push_notification_service.dart';
import 'package:school_event_attendance/core/services/realtime_notification_service.dart';
import 'package:school_event_attendance/screens/admin/admin_dashboard_screen.dart';
import 'package:school_event_attendance/screens/management/management_dashboard_screen.dart';
import 'package:school_event_attendance/screens/organizer/organizer_dashboard_screen.dart';
import 'package:school_event_attendance/screens/student/student_dashboard_screen.dart';

import '../support/app_test_host.dart';

void main() {
  setUp(() {
    PushNotificationService().resetStateForTesting();
    RealtimeNotificationService().resetState();
  });

  tearDown(() {
    ApiClient.mockHandler = null;
    PushNotificationService().resetStateForTesting();
    RealtimeNotificationService().resetState();
  });

  group('FCM Token Deregistration on Logout Tests', () {
    testWidgets('Student logout deregisters FCM token if present', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      PushNotificationService().setTokenForTesting('fcm_student_token_123');

      final calls = <String>[];
      Map<String, dynamic>? deletedBody;

      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        if (method == 'DELETE' && endpoint == ApiConstants.deviceTokens) {
          deletedBody = body as Map<String, dynamic>?;
          return ApiResponse(success: true, statusCode: 200);
        }
        if (method == 'POST' && endpoint == ApiConstants.logout) {
          return ApiResponse(success: true, statusCode: 200);
        }
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: StudentDashboardScreen(
            initialEvents: [],
            initialStats: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(calls, contains('DELETE ${ApiConstants.deviceTokens}'));
      expect(calls, contains('POST ${ApiConstants.logout}'));
      expect(deletedBody, {'fcm_token': 'fcm_student_token_123'});
    });

    testWidgets('Admin logout deregisters FCM token if present', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      PushNotificationService().setTokenForTesting('fcm_admin_token_456');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: AdminDashboardScreen(
            initialCounts: {},
            initialUsersByRole: {},
            initialEventsByStatus: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(calls, contains('DELETE ${ApiConstants.deviceTokens}'));
      expect(calls, contains('POST ${ApiConstants.logout}'));
    });

    testWidgets('Organizer logout deregisters FCM token if present', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      PushNotificationService().setTokenForTesting('fcm_organizer_token_789');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: OrganizerDashboardScreen(
            initialEvents: [],
            initialSummary: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(calls, contains('DELETE ${ApiConstants.deviceTokens}'));
      expect(calls, contains('POST ${ApiConstants.logout}'));
    });

    testWidgets('Management logout deregisters FCM token if present', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      PushNotificationService().setTokenForTesting('fcm_management_token_000');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: ManagementDashboardScreen(
            initialMetrics: {},
            initialStatusBreakdown: {},
            initialRecentEvents: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(calls, contains('DELETE ${ApiConstants.deviceTokens}'));
      expect(calls, contains('POST ${ApiConstants.logout}'));
    });

    testWidgets('Logout skips deregistration if fcmToken is null', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      // Explicitly null token
      PushNotificationService().setTokenForTesting(null);

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: StudentDashboardScreen(
            initialEvents: [],
            initialStats: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(calls.contains('DELETE ${ApiConstants.deviceTokens}'), isFalse);
      expect(calls, contains('POST ${ApiConstants.logout}'));
    });

    testWidgets('Logout succeeds even if deregisterDeviceToken throws', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.reset);

      PushNotificationService().setTokenForTesting('fcm_faulty_token');

      final calls = <String>[];
      ApiClient.mockHandler = (method, endpoint, body) async {
        calls.add('$method $endpoint');
        if (method == 'DELETE' && endpoint == ApiConstants.deviceTokens) {
          throw Exception('Network timeout during token deregistration');
        }
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        const AppTestHost(
          child: StudentDashboardScreen(
            initialEvents: [],
            initialStats: {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const ValueKey('destination-logout'));
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Ensure logout continued past the exception
      expect(calls, contains('POST ${ApiConstants.logout}'));
    });
  });
}

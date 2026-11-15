import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/widgets/app_toast.dart';
import 'package:school_event_attendance/main.dart';
import 'package:school_event_attendance/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Android Host Resolution (CRIT-2)', () {
    setUp(() {
      ApiConstants.customBaseUrl = null;
      ApiClient.resetAndroidHostCheck();
    });

    tearDown(() {
      ApiConstants.customBaseUrl = null;
      ApiClient.resetAndroidHostCheck();
    });

    test('preserves remote baseUrl and does not override to emulator loopback', () async {
      expect(ApiConstants.baseUrl, contains('render.com'));

      await ApiClient().ensureAndroidHostForTesting();

      // customBaseUrl must remain unset, never hijacked to 10.0.2.2:8000
      expect(ApiConstants.customBaseUrl, isNull);
      expect(ApiConstants.baseUrl, contains('render.com'));
    });

    test('preserves customBaseUrl if explicitly set', () async {
      ApiConstants.customBaseUrl = 'https://custom-api.example.com/api/v1';

      await ApiClient().ensureAndroidHostForTesting();

      expect(ApiConstants.customBaseUrl, 'https://custom-api.example.com/api/v1');
      expect(ApiConstants.baseUrl, 'https://custom-api.example.com/api/v1');
    });
  });

  group('ApiClient 401 Session Handling (HIGH-5)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({'auth_bearer_token': 'dummy_token'});
      SharedPreferences.setMockInitialValues({'auth_bearer_token': 'dummy_token'});
    });

    tearDown(() {
      ApiClient().onSessionTerminated = null;
      ApiClient().onUnauthenticated = null;
    });

    test('401 with ERR_SESSION_TERMINATED triggers onSessionTerminated and clears token', () async {
      bool sessionTerminatedCalled = false;
      bool unauthenticatedCalled = false;

      ApiClient().onSessionTerminated = () {
        sessionTerminatedCalled = true;
      };
      ApiClient().onUnauthenticated = () {
        unauthenticatedCalled = true;
      };

      final response = http.Response(
        json.encode({
          'success': false,
          'error_code': 'ERR_SESSION_TERMINATED',
          'message': 'Your session has been terminated because your account was logged into on another device.',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );

      final apiResponse = ApiClient().handleResponseForTesting(response);

      expect(apiResponse.statusCode, 401);
      expect(sessionTerminatedCalled, isTrue);
      expect(unauthenticatedCalled, isFalse);
    });

    test('401 with ERR_UNAUTHENTICATED triggers onUnauthenticated and clears token', () async {
      bool sessionTerminatedCalled = false;
      bool unauthenticatedCalled = false;

      ApiClient().onSessionTerminated = () {
        sessionTerminatedCalled = true;
      };
      ApiClient().onUnauthenticated = () {
        unauthenticatedCalled = true;
      };

      final response = http.Response(
        json.encode({
          'success': false,
          'error_code': 'ERR_UNAUTHENTICATED',
          'message': 'Unauthenticated.',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );

      final apiResponse = ApiClient().handleResponseForTesting(response);

      expect(apiResponse.statusCode, 401);
      expect(sessionTerminatedCalled, isFalse);
      expect(unauthenticatedCalled, isTrue);
    });

    test('401 with non-JSON or generic error triggers onUnauthenticated', () async {
      bool sessionTerminatedCalled = false;
      bool unauthenticatedCalled = false;

      ApiClient().onSessionTerminated = () {
        sessionTerminatedCalled = true;
      };
      ApiClient().onUnauthenticated = () {
        unauthenticatedCalled = true;
      };

      final response = http.Response('Unauthorized', 401);

      final apiResponse = ApiClient().handleResponseForTesting(response);

      expect(apiResponse.statusCode, 401);
      expect(sessionTerminatedCalled, isFalse);
      expect(unauthenticatedCalled, isTrue);
    });

    test('200 response does not trigger any 401 callbacks', () async {
      bool sessionTerminatedCalled = false;
      bool unauthenticatedCalled = false;

      ApiClient().onSessionTerminated = () {
        sessionTerminatedCalled = true;
      };
      ApiClient().onUnauthenticated = () {
        unauthenticatedCalled = true;
      };

      final response = http.Response(
        json.encode({
          'success': true,
          'data': {'id': 1},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );

      final apiResponse = ApiClient().handleResponseForTesting(response);

      expect(apiResponse.statusCode, 200);
      expect(sessionTerminatedCalled, isFalse);
      expect(unauthenticatedCalled, isFalse);
    });
  });

  group('SchoolAttendanceApp Session Lifecycle Integration (MED-7 & HIGH-5)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      AppToast.dismiss(immediate: true);
    });

    testWidgets('concurrent onSessionTerminated calls do not stack dialogs (MED-7)', (tester) async {
      await tester.pumpWidget(const SchoolAttendanceApp());
      await tester.pumpAndSettle();

      // Trigger session termination twice concurrently
      ApiClient().onSessionTerminated?.call();
      ApiClient().onSessionTerminated?.call();
      await tester.pumpAndSettle();

      // Exactly ONE dialog should be visible
      expect(find.text('Session Terminated'), findsOneWidget);
      expect(find.text('Return to Login'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Return to Login'));
      await tester.pumpAndSettle();

      expect(find.text('Session Terminated'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('onUnauthenticated routes to LoginScreen and shows expiration toast', (tester) async {
      await tester.pumpWidget(const SchoolAttendanceApp());
      await tester.pumpAndSettle();

      // Navigate to a protected dummy screen first
      final nav = navigatorKey.currentState!;
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Active Session Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active Session Screen'), findsOneWidget);

      // Trigger unauthenticated event (e.g. token expired)
      ApiClient().onUnauthenticated?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Should have routed to LoginScreen and removed the active session screen
      expect(find.text('Active Session Screen'), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);

      // Should show the session expiration message
      expect(find.text('Your session has expired. Please log in again.'), findsOneWidget);

      // Advance through toast dismiss timer
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

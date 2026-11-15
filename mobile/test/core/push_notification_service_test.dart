import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/services/push_notification_service.dart';
import 'package:school_event_attendance/main.dart';
import 'package:school_event_attendance/screens/common/notifications_screen.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PushNotificationService().resetStateForTesting();
  });

  group('PushNotificationService Singleton & State Tests', () {
    test('PushNotificationService returns identical singleton instance', () {
      final instance1 = PushNotificationService();
      final instance2 = PushNotificationService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('PushNotificationService initializes with default uninitialized state', () {
      final service = PushNotificationService();
      expect(service.isInitialized, isFalse);
      expect(service.fcmToken, isNull);
    });

    test('fcmToken getter reflects token and resetStateForTesting clears it', () {
      final service = PushNotificationService();
      expect(service.fcmToken, isNull);
      service.setTokenForTesting('fcm_test_device_token_xyz');
      expect(service.fcmToken, 'fcm_test_device_token_xyz');
      service.resetStateForTesting();
      expect(service.fcmToken, isNull);
    });

    test('initialize() fails gracefully and does not throw when Firebase is not configured', () async {
      final service = PushNotificationService();
      // In a headless unit test without Firebase App, initialize() should catch error gracefully
      await expectLater(service.initialize(), completes);
      expect(service.isInitialized, isFalse);
    });

    test('firebaseMessagingBackgroundHandler handles message gracefully', () async {
      const message = RemoteMessage(
        messageId: 'test_msg_001',
        data: {'key': 'value'},
      );
      await expectLater(firebaseMessagingBackgroundHandler(message), completes);
    });
  });

  group('PushNotificationService Navigation Routing Tests', () {
    testWidgets('routes to EventDetailScreen when event_id is present', (tester) async {
      final service = PushNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );
      await tester.pump();

      const message = RemoteMessage(
        messageId: 'msg_event_101',
        data: {
          'event_id': '42',
          'type': 'event_reminder_1h',
        },
      );

      service.handleNotificationTapForTesting(message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EventDetailScreen), findsOneWidget);
    });

    testWidgets('routes to NotificationsScreen when event_id is omitted or null', (tester) async {
      final service = PushNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );
      await tester.pump();

      const message = RemoteMessage(
        messageId: 'msg_announcement_202',
        data: {
          'type': 'admin_announcement',
          'title': 'School Holiday Notice',
        },
      );

      service.handleNotificationTapForTesting(message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}

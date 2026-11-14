import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/utils/notification_sound_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('com.school.attendify/notifications');
  final List<MethodCall> methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    NotificationSoundHelper.resetPlayedIds();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      methodCalls.add(methodCall);
      if (methodCall.method == 'playChimeSound') {
        return true;
      }
      if (methodCall.method == 'isChannelConfigured') {
        return <String, dynamic>{
          'channel_id': 'attendify_important_v1',
          'configured': true,
          'has_sound': true,
          'sound_name': 'sfxmint_ready_chime_07',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NotificationSoundHelper Tests', () {
    test('plays chime sound for new_event_published announcement', () async {
      final played = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 101,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'new_event_published',
      );

      expect(played, isTrue);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);
    });

    test('plays chime sound for admin_announcement', () async {
      final played = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 102,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'admin_announcement',
      );

      expect(played, isTrue);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);
    });

    test('plays chime sound for event reminders (24h and 1h)', () async {
      final played24h = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 103,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'event_reminder_24h',
      );
      final played1h = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 104,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'event_reminder_1h',
      );

      expect(played24h, isTrue);
      expect(played1h, isTrue);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 2);
    });

    test('plays chime sound for event_cancellation', () async {
      final played = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 105,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'event_cancellation',
      );

      expect(played, isTrue);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);
    });

    test('does NOT play sound for non-eligible notification types', () async {
      final r1 = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 201,
        soundName: null,
        notificationType: 'attendance_recorded',
      );
      final r2 = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 202,
        soundName: null,
        notificationType: 'registration_confirmed',
      );
      final r3 = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 203,
        soundName: null,
        notificationType: 'waiting_list_promoted',
      );

      expect(r1, isFalse);
      expect(r2, isFalse);
      expect(r3, isFalse);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 0);
    });

    test('prevents duplicate sound playback for the same notification ID', () async {
      // First attempt: should play
      final firstPlay = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 301,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'admin_announcement',
      );
      expect(firstPlay, isTrue);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);

      // Second attempt with exact same notification ID: should be suppressed
      final secondPlay = await NotificationSoundHelper.playIfSoundEnabled(
        notificationId: 301,
        soundName: 'sfxmint_ready_chime_07',
        notificationType: 'admin_announcement',
      );
      expect(secondPlay, isFalse);
      expect(methodCalls.where((c) => c.method == 'playChimeSound').length, 1);
    });

    test('verifies Android notification channel inspection', () async {
      final channelStatus = await NotificationSoundHelper.checkAndroidChannel();

      expect(channelStatus, isNotNull);
      expect(channelStatus!['channel_id'], 'attendify_important_v1');
      expect(channelStatus['configured'], isTrue);
      expect(channelStatus['has_sound'], isTrue);
      expect(channelStatus['sound_name'], 'sfxmint_ready_chime_07');
    });
  });
}

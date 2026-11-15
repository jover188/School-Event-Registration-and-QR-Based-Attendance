import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/services/push_notification_service.dart';
import 'package:school_event_attendance/core/services/realtime_notification_service.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.mockHandler = null;
    PushNotificationService().resetStateForTesting();
    RealtimeNotificationService().resetState();
    AppThemeController().resetForTesting(mode: ThemeMode.system);
  });

  tearDown(() {
    RealtimeNotificationService().stop();
    RealtimeNotificationService().resetState();
    PushNotificationService().resetStateForTesting();
    AppThemeController().resetForTesting(mode: ThemeMode.system);
  });

  group('Theme Integration Tests', () {
    testWidgets(
        'SchoolAttendanceApp mounts with themeMode: ThemeMode.light when saved as light',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'light',
      });
      await AppThemeController().initialize();

      await tester.pumpWidget(const SchoolAttendanceApp());
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);

      final shadApp = tester.widget<ShadApp>(find.byType(ShadApp));
      expect(shadApp.themeMode, ThemeMode.light);

      RealtimeNotificationService().stop();
    });

    testWidgets(
        'AppThemeController().setThemeMode(ThemeMode.dark) dynamically updates MaterialApp and ShadApp themeMode to dark',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'light',
      });
      await AppThemeController().initialize();

      await tester.pumpWidget(const SchoolAttendanceApp());
      await tester.pump();

      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);

      var shadApp = tester.widget<ShadApp>(find.byType(ShadApp));
      expect(shadApp.themeMode, ThemeMode.light);

      await AppThemeController().setThemeMode(ThemeMode.dark);
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);

      shadApp = tester.widget<ShadApp>(find.byType(ShadApp));
      expect(shadApp.themeMode, ThemeMode.dark);

      RealtimeNotificationService().stop();
    });

    testWidgets(
        'AppThemeController().setThemeMode(ThemeMode.system) dynamically updates MaterialApp and ShadApp themeMode to system',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'dark',
      });
      await AppThemeController().initialize();

      await tester.pumpWidget(const SchoolAttendanceApp());
      await tester.pump();

      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);

      var shadApp = tester.widget<ShadApp>(find.byType(ShadApp));
      expect(shadApp.themeMode, ThemeMode.dark);

      await AppThemeController().setThemeMode(ThemeMode.system);
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);

      shadApp = tester.widget<ShadApp>(find.byType(ShadApp));
      expect(shadApp.themeMode, ThemeMode.system);

      RealtimeNotificationService().stop();
    });
  });
}

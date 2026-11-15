import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppThemeController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = AppThemeController();
    controller.resetForTesting(mode: ThemeMode.system);
  });

  tearDown(() {
    controller.resetForTesting(mode: ThemeMode.system);
  });

  group('AppThemeController', () {
    test('singleton returns the same instance', () {
      final a = AppThemeController();
      final b = AppThemeController();
      expect(identical(a, b), isTrue);
    });

    test('default theme mode is ThemeMode.system', () {
      expect(controller.themeMode, ThemeMode.system);
    });

    test('initialize loads "light" mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'light',
      });

      var notified = false;
      controller.addListener(() => notified = true);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.light);
      expect(notified, isTrue);
    });

    test('initialize loads "dark" mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'dark',
      });

      var notified = false;
      controller.addListener(() => notified = true);

      await controller.initialize();

      expect(controller.themeMode, ThemeMode.dark);
      expect(notified, isTrue);
    });

    test('initialize loads "system" mode when null or system', () async {
      SharedPreferences.setMockInitialValues({});

      await controller.initialize();
      expect(controller.themeMode, ThemeMode.system);

      SharedPreferences.setMockInitialValues({
        AppThemeController.storageKey: 'system',
      });

      await controller.initialize();
      expect(controller.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state, notifies listeners, and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(notificationCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppThemeController.storageKey), 'dark');

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(notificationCount, 2);
      expect(prefs.getString(AppThemeController.storageKey), 'light');

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);
      expect(notificationCount, 3);
      expect(prefs.getString(AppThemeController.storageKey), 'system');
    });

    testWidgets('isDarkMode reflects explicit mode and system brightness fallback', (tester) async {
      // Explicit dark
      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);

      // Explicit light
      await controller.setThemeMode(ThemeMode.light);
      expect(controller.isDarkMode, isFalse);

      // System fallback to light
      await controller.setThemeMode(ThemeMode.system);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      expect(controller.isDarkMode, isFalse);

      // System fallback to dark
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      expect(controller.isDarkMode, isTrue);

      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('toggleLightDark toggles between light and dark modes', (tester) async {
      // When dark, toggle switches to light
      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);

      await controller.toggleLightDark();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppThemeController.storageKey), 'light');

      // When light, toggle switches to dark
      await controller.toggleLightDark();
      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(prefs.getString(AppThemeController.storageKey), 'dark');
    });
  });

  group('Adaptive AppDesignTokens Auth Colors', () {
    test('Light mode tokens match expected values', () {
      const light = AppDesignTokens.light;
      expect(light.isDark, isFalse);
      expect(light.authPage, const Color(0xFFE6E6E4));
      expect(light.authSurface, const Color(0xFFF6F6F4));
      expect(light.authDark, const Color(0xFF0A0A0A));
      expect(light.authDarkSelection, const Color(0x240A0A0A));
      expect(light.authLight, const Color(0xFFFFFFFF));
    });

    test('Dark mode tokens match expected values', () {
      const dark = AppDesignTokens.dark;
      expect(dark.isDark, isTrue);
      expect(dark.authPage, const Color(0xFF09090B));
      expect(dark.authSurface, const Color(0xFF121214));
      expect(dark.authDark, const Color(0xFFFAFAFA));
      expect(dark.authDarkSelection, const Color(0x24FAFAFA));
      expect(dark.authLight, const Color(0xFF18181B));
    });
  });
}

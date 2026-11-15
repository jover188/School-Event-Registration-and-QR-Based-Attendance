import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/core/widgets/theme_toggle_button.dart';

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

  Widget buildHarness({
    Widget child = const ThemeToggleIconButton(),
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(
          actions: [child],
        ),
        body: const Center(child: Text('Content')),
      ),
    );
  }

  group('ThemeToggleIconButton Widget Tests', () {
    testWidgets('renders with default key header-theme-toggle-button', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('header-theme-toggle-button')),
        findsOneWidget,
      );
      expect(find.byType(ThemeToggleIconButton), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('displays LucideIcons.moon and "Switch to Dark Mode" in light mode', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      expect(find.byIcon(LucideIcons.sun), findsNothing);
      expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);
    });

    testWidgets('displays LucideIcons.sun and "Switch to Light Mode" in dark mode', (tester) async {
      await controller.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.byIcon(LucideIcons.sun), findsOneWidget);
      expect(find.byIcon(LucideIcons.moon), findsNothing);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);
    });

    testWidgets('respects system brightness when themeMode is system', (tester) async {
      await controller.setThemeMode(ThemeMode.system);

      // System brightness = light
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      expect(find.byIcon(LucideIcons.sun), findsNothing);
      expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);

      // System brightness = dark
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.byIcon(LucideIcons.sun), findsOneWidget);
      expect(find.byIcon(LucideIcons.moon), findsNothing);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('tapping toggle button switches from light to dark mode', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      expect(controller.isDarkMode, isFalse);

      // Tap toggle button
      await tester.tap(find.byKey(const ValueKey<String>('header-theme-toggle-button')));
      await tester.pump();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, isTrue);
      expect(find.byIcon(LucideIcons.sun), findsOneWidget);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppThemeController.storageKey), 'dark');
    });

    testWidgets('tapping toggle button twice cycles back to light mode', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildHarness());
      await tester.pump();

      // Tap 1 -> to dark
      await tester.tap(find.byKey(const ValueKey<String>('header-theme-toggle-button')));
      await tester.pump();

      expect(controller.themeMode, ThemeMode.dark);
      expect(find.byIcon(LucideIcons.sun), findsOneWidget);

      // Tap 2 -> to light
      await tester.tap(find.byKey(const ValueKey<String>('header-theme-toggle-button')));
      await tester.pump();

      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, isFalse);
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppThemeController.storageKey), 'light');
    });

    testWidgets('configurable iconSize and custom color are applied', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      const customColor = Color(0xFF123456);
      await tester.pumpWidget(buildHarness(
        child: const ThemeToggleIconButton(
          iconSize: 26,
          color: customColor,
        ),
      ));
      await tester.pump();

      final iconWidget = tester.widget<Icon>(find.byIcon(LucideIcons.moon));
      expect(iconWidget.size, 26);
      expect(iconWidget.color, customColor);
    });

    testWidgets('uses context.design.primary as default color', (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildHarness(
        theme: AppTheme.lightTheme,
      ));
      await tester.pump();

      final iconWidget = tester.widget<Icon>(find.byIcon(LucideIcons.moon));
      expect(iconWidget.color, AppDesignTokens.light.primary);
    });

    testWidgets(
        'integrates in dashboard header sequence: Bell -> Theme Toggle -> Profile',
        (tester) async {
      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const ValueKey('notifications-bell-action'),
                  icon: const Icon(LucideIcons.bell),
                  onPressed: () {},
                ),
                const ThemeToggleIconButton(),
                IconButton(
                  key: const ValueKey('profile-action'),
                  icon: const Icon(LucideIcons.user),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final bellFinder = find.byKey(const ValueKey('notifications-bell-action'));
      final toggleFinder = find.byKey(const ValueKey<String>('header-theme-toggle-button'));
      final profileFinder = find.byKey(const ValueKey('profile-action'));

      expect(bellFinder, findsOneWidget);
      expect(toggleFinder, findsOneWidget);
      expect(profileFinder, findsOneWidget);

      final bellX = tester.getTopLeft(bellFinder).dx;
      final toggleX = tester.getTopLeft(toggleFinder).dx;
      final profileX = tester.getTopLeft(profileFinder).dx;

      expect(bellX < toggleX, isTrue, reason: 'Bell must be to the left of Theme Toggle');
      expect(toggleX < profileX, isTrue, reason: 'Theme Toggle must be to the left of Profile');
    });
  });
}

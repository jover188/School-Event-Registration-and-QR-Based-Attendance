import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/screens/common/profile_screen.dart';

import '../support/app_test_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppThemeController controller;

  final testProfileData = {
    'user': {
      'id': 101,
      'name': 'Thea Queen',
      'email': 'thea@school.edu',
      'role': 'student',
      'status': 'active',
    },
    'student_profile': {
      'student_id_number': '2026-0001',
      'first_name': 'Thea',
      'last_name': 'Queen',
      'middle_name': 'DeMerteuil',
      'course': 'BS Computer Science',
      'year_level': '3rd Year',
      'section': 'CS-3A',
      'contact_number': '+639123456789',
      'department': 'College of Computer Studies',
    },
  };

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.mockHandler = null;
    controller = AppThemeController();
    controller.resetForTesting(mode: ThemeMode.system);
  });

  tearDown(() {
    controller.resetForTesting(mode: ThemeMode.system);
    ApiClient.mockHandler = null;
  });

  Widget buildProfileHarness({Size size = const Size(800, 1200)}) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AppTestHost(
          themeMode: controller.themeMode,
          child: ProfileScreen(
            initialData: testProfileData,
          ),
        );
      },
    );
  }

  group('ProfileScreen Appearance & Theme Settings Card', () {
    testWidgets('renders Appearance & Theme header with title and subtitle',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('appearance-theme-card')),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.sunMedium), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(
        find.text('Choose your preferred interface theme'),
        findsOneWidget,
      );
    });

    testWidgets('renders all 3 theme options with their keys and icons',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      final lightOption =
          find.byKey(const ValueKey<String>('theme-option-light'));
      final darkOption = find.byKey(const ValueKey<String>('theme-option-dark'));
      final systemOption =
          find.byKey(const ValueKey<String>('theme-option-system'));

      expect(lightOption, findsOneWidget);
      expect(darkOption, findsOneWidget);
      expect(systemOption, findsOneWidget);

      expect(find.byIcon(LucideIcons.sun), findsOneWidget);
      expect(find.byIcon(LucideIcons.moon), findsOneWidget);
      expect(find.byIcon(LucideIcons.laptop), findsOneWidget);

      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
    });

    testWidgets('renders cleanly in compact screen layout (mobile viewport)',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('appearance-theme-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-light')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-system')),
        findsOneWidget,
      );
    });

    testWidgets('active indicator reflects initial theme mode correctly',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      // Default is ThemeMode.system
      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('theme-option-system-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsNothing,
      );
    });

    testWidgets('tapping an option calls setThemeMode and updates mode reactively',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      // Tap Dark Mode option
      await tester.tap(find.byKey(const ValueKey<String>('theme-option-dark')));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.dark);
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-system-check')),
        findsNothing,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppThemeController.storageKey), 'dark');

      // Tap Light Mode option
      await tester.tap(find.byKey(const ValueKey<String>('theme-option-light')));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.light);
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-system-check')),
        findsNothing,
      );
      expect(prefs.getString(AppThemeController.storageKey), 'light');

      // Tap System Default option
      await tester.tap(find.byKey(const ValueKey<String>('theme-option-system')));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.system);
      expect(
        find.byKey(const ValueKey<String>('theme-option-system-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsNothing,
      );
      expect(prefs.getString(AppThemeController.storageKey), 'system');
    });

    testWidgets(
        'settings card updates when AppThemeController.toggleLightDark() is called externally',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await controller.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(buildProfileHarness());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsNothing,
      );

      // External toggle: light -> dark
      await controller.toggleLightDark();
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.dark);
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsNothing,
      );

      // External toggle: dark -> light
      await controller.toggleLightDark();
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.light);
      expect(
        find.byKey(const ValueKey<String>('theme-option-light-check')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme-option-dark-check')),
        findsNothing,
      );
    });
  });
}

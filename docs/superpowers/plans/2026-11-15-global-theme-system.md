# Attendify – Global Light Mode and Dark Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a centralized Light, Dark, and System Default theme system across Attendify for Flutter Web and Android APK, complete with SharedPreferences persistence, a responsive header Sun/Moon toggle button, and a settings theme selector card.

**Architecture:** A singleton `AppThemeController` (ChangeNotifier) persists the user's preference in `SharedPreferences` under key `attendify_theme_mode` and drives both `ShadApp.custom` and `MaterialApp` reactively via `ListenableBuilder`. A dedicated `ThemeToggleIconButton` widget is added between the notification bell and profile icon across all dashboard headers (`Notification Bell → Theme Toggle → Profile Icon`), while `ProfileScreen` provides a 3-way theme selector (Light, Dark, System Default).

**Tech Stack:** Flutter / Dart, `shared_preferences: ^2.2.2`, `shadcn_ui`, `lucide_icons`.

**Spec:** User Request: *Attendify – Implement Global Light Mode and Dark Mode* (Light, Dark, System Default; persistent across sessions and logouts; header Sun/Moon icon between notification bell and profile icon; settings selector; zero breaking changes to business logic; preserves black-and-white visual identity).

## Global Constraints

- **Theme Options:** 3 options: `Light Mode` (`ThemeMode.light`), `Dark Mode` (`ThemeMode.dark`), `System Default` (`ThemeMode.system`).
- **Persistence Key:** `attendify_theme_mode` stored in `SharedPreferences`. Must survive logout (`ApiClient.clearToken()` does NOT touch this key).
- **Header Placement:** Exact layout: `Notification Bell → Theme Toggle → Profile Icon`.
- **Header Icon:** Minimalist `LucideIcons.sun` when dark mode is active, `LucideIcons.moon` when light mode is active. Immediate toggle on tap.
- **Visual Identity:** Retain Attendify's high-contrast black-and-white design system via `AppDesignTokens.light` and `AppDesignTokens.dark`.
- **No Direct DB Access:** Flutter client communicates strictly through `/api/v1/*` endpoints; theme preferences are stored locally on device/browser.
- **Approval Rule:** Do NOT commit or push without user's explicit approval.

## Review Focus

1. **System Default fallback:** When `attendify_theme_mode` is null or invalid, the app must default to `ThemeMode.system` and follow OS brightness changes.
2. **Persistence across logout:** Calling `ApiClient().clearToken()` during logout must leave `attendify_theme_mode` intact.
3. **Synchronized UI state:** Tapping the header Sun/Moon button must immediately update the Settings selector in `ProfileScreen` and vice versa.
4. **Header icon responsiveness:** The theme button in the header must match 20px icon sizing, 48px minimum touch target, and align gracefully across mobile viewports and desktop wrap layouts.
5. **Dark Mode Auth/Login styling:** In dark mode, `authSurface`, `authDark`, and `authLight` in `AppDesignTokens` must provide legible contrast for the login page without disrupting light mode aesthetics.

---

### Task 1: Centralized `AppThemeController` & Adaptive Theme Tokens

**Files:**
- Create: `mobile/lib/core/theme/theme_controller.dart`
- Modify: `mobile/lib/core/theme/app_tokens.dart:308-313`
- Test: `mobile/test/core/theme_controller_test.dart`

**Interfaces:**
- Produces:
  - `class AppThemeController extends ChangeNotifier`:
    - `static AppThemeController get instance` (or factory `AppThemeController()`)
    - `ThemeMode get themeMode`
    - `bool get isDarkMode`
    - `Future<void> initialize()`
    - `Future<void> setThemeMode(ThemeMode mode)`
    - `Future<void> toggleLightDark()`
    - `static const String storageKey = 'attendify_theme_mode'`
- Consumes:
  - `package:shared_preferences/shared_preferences.dart`
  - `package:flutter/material.dart`

- [ ] **Step 1: Write the failing test for `AppThemeController`**

```dart
// mobile/test/core/theme_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppThemeController defaults to ThemeMode.system when unconfigured', () async {
    final controller = AppThemeController();
    await controller.initialize();
    expect(controller.themeMode, ThemeMode.system);
  });

  test('AppThemeController loads saved light mode from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'attendify_theme_mode': 'light'});
    final controller = AppThemeController();
    await controller.initialize();
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.isDarkMode, false);
  });

  test('AppThemeController loads saved dark mode from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'attendify_theme_mode': 'dark'});
    final controller = AppThemeController();
    await controller.initialize();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isDarkMode, true);
  });

  test('setThemeMode updates state, notifies listeners, and persists', () async {
    final controller = AppThemeController();
    await controller.initialize();

    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);
    expect(notified, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('attendify_theme_mode'), 'dark');
  });

  test('toggleLightDark switches between light and dark modes', () async {
    final controller = AppThemeController();
    await controller.initialize();

    await controller.setThemeMode(ThemeMode.light);
    await controller.toggleLightDark();
    expect(controller.themeMode, ThemeMode.dark);

    await controller.toggleLightDark();
    expect(controller.themeMode, ThemeMode.light);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme_controller_test.dart`
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement `AppThemeController` in `mobile/lib/core/theme/theme_controller.dart` and adapt `app_tokens.dart`**

Implement singleton `AppThemeController` with `SharedPreferences` persistence for `'light'`, `'dark'`, `'system'`.
In `mobile/lib/core/theme/app_tokens.dart`, update:
```dart
  Color get authPage => isDark ? const Color(0xFF09090B) : const Color(0xFFE6E6E4);
  Color get authSurface => isDark ? const Color(0xFF121214) : const Color(0xFFF6F6F4);
  Color get authDark => isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A);
  Color get authDarkSelection => isDark ? const Color(0x24FAFAFA) : const Color(0x240A0A0A);
  Color get authLight => isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme_controller_test.dart`
Expected: PASS

---

### Task 2: Bind `AppThemeController` to `main.dart`

**Files:**
- Modify: `mobile/lib/main.dart:16-21`, `mobile/lib/main.dart:136-166`
- Test: `mobile/test/screens/theme_integration_test.dart`

**Interfaces:**
- Consumes:
  - `AppThemeController` from `mobile/lib/core/theme/theme_controller.dart`
  - `AppTheme.shadTheme`, `AppTheme.shadDarkTheme`, `AppTheme.lightTheme`, `AppTheme.darkTheme`

- [ ] **Step 1: Write test for dynamic theme binding**

```dart
// mobile/test/screens/theme_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/theme_controller.dart';
import 'package:school_event_attendance/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SchoolAttendanceApp reacts to AppThemeController changes', (tester) async {
    SharedPreferences.setMockInitialValues({'attendify_theme_mode': 'light'});
    await AppThemeController().initialize();

    await tester.pumpWidget(const SchoolAttendanceApp());
    await tester.pump();

    // Verify initial MaterialApp themeMode is light
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    // Switch to dark mode
    await AppThemeController().setThemeMode(ThemeMode.dark);
    await tester.pump();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/theme_integration_test.dart`
Expected: FAIL (themeMode is hardcoded to ThemeMode.system)

- [ ] **Step 3: Update `main.dart` to initialize and observe `AppThemeController`**

In `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppThemeController().initialize();
  await PushNotificationService().initialize();
  runApp(const SchoolAttendanceApp());
}
```
In `_SchoolAttendanceAppState.build()`:
```dart
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController(),
      builder: (context, _) {
        final currentMode = AppThemeController().themeMode;
        return ShadApp.custom(
          theme: AppTheme.shadTheme,
          darkTheme: AppTheme.shadDarkTheme,
          themeMode: currentMode,
          appBuilder: (context) => MaterialApp(
            title: 'School Event Attendance',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            localizationsDelegates: const [GlobalShadLocalizations.delegate],
            scrollBehavior: const ShadScrollBehavior(),
            builder: (context, child) => ShadAppBuilder(child: child),
            home: FutureBuilder<Widget>(
              future: _initialScreen,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }
                return snapshot.data ?? const LoginScreen();
              },
            ),
          ),
        );
      },
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/theme_integration_test.dart`
Expected: PASS

---

### Task 3: Create `ThemeToggleIconButton` & Update Dashboard Headers

**Files:**
- Create: `mobile/lib/core/widgets/theme_toggle_button.dart`
- Modify: `mobile/lib/screens/admin/admin_dashboard_screen.dart:644-646`
- Modify: `mobile/lib/screens/management/management_dashboard_screen.dart:636-638`
- Modify: `mobile/lib/screens/organizer/organizer_dashboard_screen.dart:476-478`
- Modify: `mobile/lib/screens/student/student_dashboard_screen.dart:552-554`
- Test: `mobile/test/widgets/theme_toggle_button_test.dart`

**Interfaces:**
- Produces:
  - `class ThemeToggleIconButton extends StatelessWidget`:
    - Renders an `IconButton` with key `ValueKey('header-theme-toggle-button')`
    - Icon: `LucideIcons.sun` when dark, `LucideIcons.moon` when light
    - Tooltip: `'Switch to Light Mode'` or `'Switch to Dark Mode'`
    - On pressed: `AppThemeController().toggleLightDark()`
- Header Sequence across all dashboards:
  `[NotificationBell, ThemeToggleIconButton, ProfileIcon]`

- [ ] **Step 1: Write test for `ThemeToggleIconButton`**

```dart
// mobile/test/widgets/theme_toggle_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/core/theme/theme_controller.dart';
import 'package:school_event_attendance/core/widgets/theme_toggle_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ThemeToggleIconButton displays correct icon and toggles theme', (tester) async {
    SharedPreferences.setMockInitialValues({'attendify_theme_mode': 'light'});
    await AppThemeController().initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Row(
              children: [ThemeToggleIconButton()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // In light mode, icon is Moon
    expect(find.byIcon(LucideIcons.moon), findsOneWidget);

    // Tap to toggle
    await tester.tap(find.byType(ThemeToggleIconButton));
    await tester.pump();

    expect(AppThemeController().themeMode, ThemeMode.dark);
    expect(find.byIcon(LucideIcons.sun), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/theme_toggle_button_test.dart`
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement `ThemeToggleIconButton` and add to headers**

1. Create `mobile/lib/core/widgets/theme_toggle_button.dart`.
2. Insert `const ThemeToggleIconButton()` between notification bell and profile icon in:
   - `AdminDashboardScreen`
   - `ManagementDashboardScreen`
   - `OrganizerDashboardScreen`
   - `StudentDashboardScreen`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/theme_toggle_button_test.dart`
Expected: PASS

---

### Task 4: Add "Appearance & Theme" Selector in Settings (`ProfileScreen`)

**Files:**
- Modify: `mobile/lib/screens/common/profile_screen.dart`
- Test: `mobile/test/screens/theme_settings_test.dart`

**Interfaces:**
- Section Header: `'Appearance & Theme'`
- 3 Segments / Cards:
  - **Light Mode** (`LucideIcons.sun`) -> `ThemeMode.light`
  - **Dark Mode** (`LucideIcons.moon`) -> `ThemeMode.dark`
  - **System Default** (`LucideIcons.laptop`) -> `ThemeMode.system`
- Highlights currently active `AppThemeController().themeMode`.
- Tapping any option calls `AppThemeController().setThemeMode(mode)`.

- [ ] **Step 1: Write test for Theme Selector in `ProfileScreen`**

```dart
// mobile/test/screens/theme_settings_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/core/theme/theme_controller.dart';
import 'package:school_event_attendance/screens/common/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileScreen renders Appearance & Theme section with 3 options', (tester) async {
    SharedPreferences.setMockInitialValues({'attendify_theme_mode': 'system'});
    await AppThemeController().initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(embedded: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-light')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-dark')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-option-system')), findsOneWidget);

    // Tap dark mode
    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pump();

    expect(AppThemeController().themeMode, ThemeMode.dark);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/theme_settings_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Theme Selector in `profile_screen.dart`**

Add an "Appearance & Theme" card section under the Account Identity summary card with 3 selectable options (Light Mode, Dark Mode, System Default) wrapped in `ListenableBuilder(listenable: AppThemeController(), ...)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/theme_settings_test.dart`
Expected: PASS

---

### Task 5: End-to-End Verification & Build Validation

**Files:**
- Test all suites in `mobile/test/`
- Build Flutter Web release bundle

- [ ] **Step 1: Run static analysis**
Run: `cd mobile; flutter analyze`
Expected: 0 errors, 0 warnings

- [ ] **Step 2: Run full test suite**
Run: `cd mobile; flutter test`
Expected: All tests pass

- [ ] **Step 3: Verify backend test integrity**
Run: `cd backend; php artisan test`
Expected: All tests pass

- [ ] **Step 4: Build Flutter Web release to verify production buildability**
Run: `cd mobile; flutter build web --release --base-href /`
Expected: Web build succeeds with zero errors.

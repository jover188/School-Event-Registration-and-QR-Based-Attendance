import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';
import 'package:school_event_attendance/core/widgets/app_button.dart';
import 'package:school_event_attendance/main.dart';
import 'package:school_event_attendance/screens/auth/login_screen.dart';
import '../support/app_test_host.dart';

void main() {
  test('Material and Shad themes match the exact :root and .dark Zinc/Teal/Amber/Red palette', () {
    // Light Mode (:root)
    expect(AppTheme.lightTheme.colorScheme.primary, const Color(0xFF18181B));
    expect(AppTheme.lightTheme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
    expect(AppTheme.shadTheme.colorScheme.primary, const Color(0xFF18181B));
    expect(AppTheme.shadTheme.colorScheme.primaryForeground, const Color(0xFFFAFAFA));
    expect(AppTheme.shadTheme.colorScheme.background, const Color(0xFFFAFAFA));
    expect(AppTheme.shadTheme.colorScheme.foreground, const Color(0xFF09090B));
    expect(AppTheme.shadTheme.colorScheme.card, const Color(0xFFFFFFFF));
    expect(AppTheme.shadTheme.colorScheme.cardForeground, const Color(0xFF09090B));
    expect(AppTheme.shadTheme.colorScheme.secondary, const Color(0xFFF4F4F5));
    expect(AppTheme.shadTheme.colorScheme.secondaryForeground, const Color(0xFF18181B));
    expect(AppTheme.shadTheme.colorScheme.muted, const Color(0xFFF4F4F5));
    expect(AppTheme.shadTheme.colorScheme.mutedForeground, const Color(0xFF52525B));
    expect(AppTheme.shadTheme.colorScheme.destructive, const Color(0xFFEF4444));
    expect(AppTheme.shadTheme.colorScheme.destructiveForeground, const Color(0xFF09090B));
    expect(AppTheme.shadTheme.colorScheme.border, const Color(0xFFE4E4E7));
    expect(AppTheme.shadTheme.colorScheme.input, const Color(0xFFE4E4E7));
    expect(AppTheme.shadTheme.colorScheme.ring, const Color(0xFF71717A));
    expect(AppDesignTokens.light.warning, const Color(0xFFF59E0B));
    expect(AppDesignTokens.light.warningForeground, const Color(0xFF09090B));
    expect(AppDesignTokens.light.success, const Color(0xFF14B8A6));
    expect(AppDesignTokens.light.successForeground, const Color(0xFF042F2E));
    expect(AppDesignTokens.light.sidebar, const Color(0xFFF4F4F5));
    expect(AppDesignTokens.light.sidebarForeground, const Color(0xFF09090B));
    expect(AppDesignTokens.light.sidebarPrimary, const Color(0xFF18181B));
    expect(AppDesignTokens.light.sidebarPrimaryForeground, const Color(0xFFFAFAFA));
    expect(AppDesignTokens.light.sidebarBorder, const Color(0xFFE4E4E7));

    // Dark Mode (.dark)
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, const Color(0xFF09090B));
    expect(AppTheme.shadDarkTheme.colorScheme.background, const Color(0xFF09090B));
    expect(AppTheme.shadDarkTheme.colorScheme.foreground, const Color(0xFFFFFFFF));
    expect(AppTheme.shadDarkTheme.colorScheme.card, const Color(0xFF121214));
    expect(AppTheme.shadDarkTheme.colorScheme.cardForeground, const Color(0xFFFFFFFF));
    expect(AppTheme.shadDarkTheme.colorScheme.popover, const Color(0xFF18181B));
    expect(AppTheme.shadDarkTheme.colorScheme.popoverForeground, const Color(0xFFFFFFFF));
    expect(AppTheme.shadDarkTheme.colorScheme.primary, const Color(0xFFFFFFFF));
    expect(AppTheme.shadDarkTheme.colorScheme.primaryForeground, const Color(0xFF27272A));
    expect(AppTheme.shadDarkTheme.colorScheme.secondary, const Color(0xFF27272A));
    expect(AppTheme.shadDarkTheme.colorScheme.secondaryForeground, const Color(0xFFFAFAFA));
    expect(AppTheme.shadDarkTheme.colorScheme.muted, const Color(0xFF27272A));
    expect(AppTheme.shadDarkTheme.colorScheme.mutedForeground, const Color(0xFFA1A1AA));
    expect(AppTheme.shadDarkTheme.colorScheme.border, const Color(0xFF27272A));
    expect(AppTheme.shadDarkTheme.colorScheme.input, const Color(0xFF27272A));
    expect(AppTheme.shadDarkTheme.colorScheme.ring, const Color(0xFFA1A1AA));
    expect(AppDesignTokens.dark.sidebar, const Color(0xFF0F0F12));
    expect(AppDesignTokens.dark.sidebarForeground, const Color(0xFFFFFFFF));
    expect(AppDesignTokens.dark.sidebarPrimary, const Color(0xFFFFFFFF));
    expect(AppDesignTokens.dark.sidebarPrimaryForeground, const Color(0xFF27272A));
    expect(AppDesignTokens.dark.sidebarBorder, const Color(0xFF27272A));
  });

  testWidgets('shadcn button and dialog inherit custom scheme and preserve navigator key', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      AppTestHost(
        navigatorKey: navKey,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: AppButton(
                label: 'Open Dialog',
                onPressed: () {
                  showShadDialog<void>(
                    context: context,
                    builder: (ctx) => const ShadDialog(
                      title: Text('Confirm Action'),
                      description: Text('Dialog overlay is active.'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(navKey.currentState, isNotNull);
    final element = tester.element(find.byType(AppButton));
    expect(element.design.primary, const Color(0xFF18181B));
    expect(element.design.buttonPrimary, const Color(0xFF18181B));
    expect(ShadTheme.of(element).colorScheme.primary, const Color(0xFF18181B));

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Action'), findsOneWidget);
    expect(find.text('Dialog overlay is active.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session termination clears open modals and routes back to LoginScreen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SchoolAttendanceApp());
    await tester.pumpAndSettle();

    // Push a protected route and open a modal over it
    final nav = navigatorKey.currentState!;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Protected Dashboard Content')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected Dashboard Content'), findsOneWidget);

    showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (_) => const AlertDialog(title: Text('Open Protected Modal')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open Protected Modal'), findsOneWidget);

    // Trigger global session termination
    ApiClient().onSessionTerminated?.call();
    await tester.pumpAndSettle();

    expect(find.text('Session Terminated'), findsOneWidget);
    await tester.tap(find.text('Return to Login'));
    await tester.pumpAndSettle();

    expect(find.text('Open Protected Modal'), findsNothing);
    expect(find.text('Protected Dashboard Content'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}



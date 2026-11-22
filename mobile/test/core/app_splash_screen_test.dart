import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/app_splash_screen.dart';
import '../support/app_test_host.dart';

void main() {
  group('AppSplashScreen', () {
    testWidgets('buildStaticForTesting renders logo, title, subtitle, and spinner',
        (tester) async {
      await tester.pumpWidget(
        AppTestHost(
          child: AppSplashScreen.buildStaticForTesting(),
        ),
      );

      expect(
        find.byKey(const ValueKey('attendify-splash-logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('attendify-splash-title')),
        findsOneWidget,
      );
      expect(find.text('Attendify'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('attendify-splash-subtitle')),
        findsOneWidget,
      );
      expect(find.text('School Event Attendance'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('attendify-splash-spinner')),
        findsOneWidget,
      );
    });

    testWidgets('adapts to dark mode theme tokens', (tester) async {
      await tester.pumpWidget(
        AppTestHost(
          themeMode: ThemeMode.dark,
          child: AppSplashScreen.buildStaticForTesting(),
        ),
      );

      final imageWidget = tester.widget<Image>(
        find.byKey(const ValueKey('attendify-splash-logo')),
      );
      expect(imageWidget.color, isNotNull);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('navigates to resolved target screen after duration',
        (tester) async {
      final completer = Completer<Widget>();

      await tester.pumpWidget(
        MaterialApp(
          home: AppSplashScreen(
            initialScreenFuture: completer.future,
            minimumDuration: const Duration(milliseconds: 300),
          ),
        ),
      );

      // Splash is active
      expect(find.text('Attendify'), findsOneWidget);
      expect(find.text('Resolved Dashboard'), findsNothing);

      // Resolve the future
      completer.complete(
        const Scaffold(
          body: Text('Resolved Dashboard'),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      // Minimum duration not reached yet
      expect(find.text('Attendify'), findsOneWidget);
      expect(find.text('Resolved Dashboard'), findsNothing);

      // Advance past minimum duration
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.text('Resolved Dashboard'), findsOneWidget);
    });

    testWidgets('gracefully handles prolonged initialization without freezing',
        (tester) async {
      final completer = Completer<Widget>();

      await tester.pumpWidget(
        MaterialApp(
          home: AppSplashScreen(
            initialScreenFuture: completer.future,
            minimumDuration: const Duration(milliseconds: 200),
          ),
        ),
      );

      // Advance past minimum duration but future is still pending
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Attendify'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('attendify-splash-spinner')),
        findsOneWidget,
      );

      // Complete future after long delay
      completer.complete(
        const Scaffold(
          body: Text('Late Dashboard'),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Late Dashboard'), findsOneWidget);
    });

    testWidgets('falls back to LoginScreen if future throws', (tester) async {
      final completer = Completer<Widget>();

      await tester.pumpWidget(
        MaterialApp(
          home: AppSplashScreen(
            initialScreenFuture: completer.future,
            minimumDuration: const Duration(milliseconds: 50),
          ),
        ),
      );

      completer.completeError(Exception('Failed to load'));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // LoginScreen rendered as fallback
      expect(
        find.byKey(const ValueKey('attendify-login-logo')),
        findsOneWidget,
      );
    });
  });
}

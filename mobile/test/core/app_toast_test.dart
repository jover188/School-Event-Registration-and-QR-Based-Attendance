import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/app_toast.dart';
import '../support/app_test_host.dart';

void main() {
  group('AppToast unit and widget tests', () {
    tearDown(() {
      AppToast.dismiss(immediate: true);
    });

    testWidgets('renders top-center with compact width, icon, and text', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late BuildContext testContext;

      await tester.pumpWidget(
        AppTestHost(
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(
                body: Center(child: Text('Host Page')),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppToast.success(testContext, 'Registration confirmed successfully!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final toastContainer = find.byKey(const ValueKey('app-toast-container'));
      expect(toastContainer, findsOneWidget);

      final iconFinder = find.byKey(const ValueKey('app-toast-icon-success'));
      expect(iconFinder, findsOneWidget);

      final messageFinder = find.byKey(const ValueKey('app-toast-message'));
      expect(messageFinder, findsOneWidget);
      expect(find.text('Registration confirmed successfully!'), findsOneWidget);

      // Verify top-center placement
      final toastCenter = tester.getCenter(toastContainer);
      expect(toastCenter.dx, closeTo(1280 / 2, 2.0));
      expect(toastCenter.dy, lessThan(100.0));

      // Verify compact bounds (not full width)
      final toastSize = tester.getSize(toastContainer);
      expect(toastSize.width, lessThanOrEqualTo(440.0));
      expect(toastSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('supports error, warning, and info variants with semantic styling', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        AppTestHost(
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error toast
      AppToast.error(testContext, 'Action failed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('app-toast-icon-error')), findsOneWidget);
      expect(find.text('Action failed'), findsOneWidget);

      // Warning toast (replaces previous immediately without duplicate)
      AppToast.warning(testContext, 'Warning message');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('app-toast-icon-warning')), findsOneWidget);
      expect(find.byKey(const ValueKey('app-toast-icon-error')), findsNothing);
      expect(find.text('Warning message'), findsOneWidget);

      // Info toast
      AppToast.info(testContext, 'Informational update');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('app-toast-icon-info')), findsOneWidget);
      expect(find.text('Informational update'), findsOneWidget);
    });

    testWidgets('dismisses manually when close button tapped', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        AppTestHost(
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppToast.info(testContext, 'Dismissible toast');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('app-toast-container')), findsOneWidget);

      final dismissButton = find.byKey(const ValueKey('app-toast-dismiss-button'));
      expect(dismissButton, findsOneWidget);

      await tester.tap(dismissButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('app-toast-container')), findsNothing);
    });

    testWidgets('automatically dismisses after 4 seconds', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        AppTestHost(
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppToast.success(testContext, 'Self-closing toast');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('app-toast-container')), findsOneWidget);

      // Advance clock past 4 seconds
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('app-toast-container')), findsNothing);
    });

    testWidgets('adapts to Dark mode with high contrast text and icons', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        AppTestHost(
          themeMode: ThemeMode.dark,
          child: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      AppToast.error(testContext, 'Registrations cannot be cancelled after the event has started.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textWidget = tester.widget<Text>(find.byKey(const ValueKey('app-toast-message')));
      // Dark mode foreground should be light (#FFFFFF)
      expect(textWidget.style?.color, const Color(0xFFFFFFFF));

      final containerWidget = tester.widget<Container>(find.byKey(const ValueKey('app-toast-container')));
      final decoration = containerWidget.decoration as BoxDecoration;
      // In dark mode, error background is tinted dark red
      expect(decoration.color, const Color(0xFF280C0C));
    });
  });
}

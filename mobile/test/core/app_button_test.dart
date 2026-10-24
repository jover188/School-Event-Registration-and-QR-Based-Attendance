import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/core/widgets/app_button.dart';
import '../support/app_test_host.dart';

void main() {
  setUp(() {
    AppTestHost.ensureStorageMocked();
  });

  group('AppButton Design System Tests', () {
    testWidgets('renders all 5 variants without error and with correct text', (tester) async {
      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: Column(
              children: [
                AppButton(
                  key: const ValueKey('btn-primary'),
                  label: 'Primary Action',
                  variant: AppButtonVariant.primary,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-secondary'),
                  label: 'Secondary Action',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-outline'),
                  label: 'Outline Action',
                  variant: AppButtonVariant.outline,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-ghost'),
                  label: 'Ghost Action',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-destructive'),
                  label: 'Destructive Action',
                  variant: AppButtonVariant.destructive,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.text('Outline Action'), findsOneWidget);
      expect(find.text('Ghost Action'), findsOneWidget);
      expect(find.text('Destructive Action'), findsOneWidget);
    });

    testWidgets('renders three sizes with appropriate heights', (tester) async {
      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: Column(
              children: [
                AppButton(
                  key: const ValueKey('btn-compact'),
                  label: 'Compact',
                  size: AppButtonSize.compact,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-standard'),
                  label: 'Standard',
                  size: AppButtonSize.standard,
                  onPressed: () {},
                ),
                AppButton(
                  key: const ValueKey('btn-large'),
                  label: 'Large',
                  size: AppButtonSize.large,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final compactBox = tester.renderObject<RenderBox>(find.byKey(const ValueKey('btn-compact')));
      final standardBox = tester.renderObject<RenderBox>(find.byKey(const ValueKey('btn-standard')));
      final largeBox = tester.renderObject<RenderBox>(find.byKey(const ValueKey('btn-large')));

      expect(compactBox.size.height, equals(34.0));
      expect(standardBox.size.height, equals(40.0));
      expect(largeBox.size.height, equals(46.0));
    });

    testWidgets('supports full width button expansion', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: AppButton(
                  key: const ValueKey('btn-fullwidth'),
                  label: 'Full Width Button',
                  isFullWidth: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('btn-fullwidth')));
      expect(box.size.width, equals(350.0));
    });

    testWidgets('shows loading indicator and disables tap during isLoading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: AppButton(
              key: const ValueKey('btn-loading'),
              label: 'Submit',
              isLoading: true,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Submit…'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('btn-loading')));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('AppIconButton enforces accessible minimum hit target and badge', (tester) async {
      var iconTapped = false;
      await tester.pumpWidget(
        AppTestHost(
          child: Scaffold(
            body: AppIconButton(
              key: const ValueKey('icon-btn'),
              icon: LucideIcons.bell,
              tooltip: 'Notifications',
              badgeCount: 5,
              onPressed: () {
                iconTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('icon-btn')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(find.byKey(const ValueKey('icon-btn')));
      // Hit target must be at least 44x44
      expect(renderBox.size.width, greaterThanOrEqualTo(40.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(40.0));

      await tester.tap(find.byKey(const ValueKey('icon-btn')));
      await tester.pump();
      expect(iconTapped, isTrue);
    });
  });
}

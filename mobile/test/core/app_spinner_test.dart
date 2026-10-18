import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/core/widgets/app_button.dart';
import 'package:school_event_attendance/core/widgets/app_spinner.dart';
import '../support/app_test_host.dart';

void main() {
  testWidgets('AppSpinner renders with default size and LucideIcons.loader2',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: Scaffold(
          body: Center(
            child: AppSpinner(),
          ),
        ),
      ),
    );
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(find.byIcon(LucideIcons.loader2), findsOneWidget);
    final size = tester.getSize(find.byType(AppSpinner));
    expect(size.width, 24.0);
    expect(size.height, 24.0);
  });

  testWidgets('AppSpinner presets (sm, md, lg) render expected sizes',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: Scaffold(
          body: Column(
            children: [
              AppSpinner.sm(key: ValueKey('spinner-sm')),
              AppSpinner.md(key: ValueKey('spinner-md')),
              AppSpinner.lg(key: ValueKey('spinner-lg')),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('spinner-sm'))),
        const Size(16.0, 16.0));
    expect(tester.getSize(find.byKey(const ValueKey('spinner-md'))),
        const Size(24.0, 24.0));
    expect(tester.getSize(find.byKey(const ValueKey('spinner-lg'))),
        const Size(36.0, 36.0));
  });

  testWidgets('AppSpinner applies custom color and semantics label',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: Scaffold(
          body: AppSpinner(
            color: Colors.red,
            semanticsLabel: 'Submitting form',
          ),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.loader2));
    expect(icon.color, Colors.red);
    expect(find.bySemanticsLabel('Submitting form'), findsOneWidget);
  });

  testWidgets('AppSpinner respects reduced motion (disableAnimations)',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AppSpinner(),
          ),
        ),
      ),
    );
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppSpinner.page displays centered spinner with message',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(
        child: Scaffold(
          body: AppSpinner.page(label: 'Loading event registrations...'),
        ),
      ),
    );
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(find.text('Loading event registrations...'), findsOneWidget);
  });

  testWidgets('AppButton uses AppSpinner when isLoading is true',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(
        child: Scaffold(
          body: AppButton(
            label: 'Submit',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byType(AppSpinner), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

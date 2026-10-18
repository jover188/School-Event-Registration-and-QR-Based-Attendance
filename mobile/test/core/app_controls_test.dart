import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/app_button.dart';
import 'package:school_event_attendance/core/widgets/app_pressable.dart';
import '../support/app_test_host.dart';

void main() {
  testWidgets('loading button blocks repeat submission and grows with text', (tester) async {
    var calls = 0;
    await tester.pumpWidget(AppTestHost(child: Scaffold(body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Center(child: SizedBox(width: 200, child: AppButton(label: 'Register for this event',
        isLoading: true, onPressed: () => calls++))),
    ))));
    await tester.tap(find.byType(AppButton));
    expect(calls, 0);
    expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pressable supports Enter and Space once and ignores disabled input', (tester) async {
    var calls = 0;
    Future<void> mount(bool enabled) => tester.pumpWidget(AppTestHost(child: Scaffold(body: AppPressable(
      semanticLabel: 'Open event', onPressed: enabled ? () => calls++ : null,
      child: const Text('Event'),
    ))));
    await mount(true);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(calls, 2);
    expect(find.bySemanticsLabel('Open event'), findsOneWidget);
    await mount(false);
    await tester.tap(find.byType(AppPressable));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(calls, 2);
  });

  testWidgets('reduced motion removes press scaling', (tester) async {
    await tester.pumpWidget(AppTestHost(child: Scaffold(body: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: AppPressable(semanticLabel: 'Open', onPressed: () {}, child: const Text('Open')),
    ))));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(AppPressable)));
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.duration, Duration.zero);
    expect(scale.scale, 1);
    await gesture.up();
  });
}

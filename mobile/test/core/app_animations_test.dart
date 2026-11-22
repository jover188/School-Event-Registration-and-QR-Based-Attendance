import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/animations/app_animations.dart';
import '../support/app_test_host.dart';

void main() {
  group('EntranceFader', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: EntranceFader(
            child: Text('Fading Content'),
          ),
        ),
      );

      expect(find.text('Fading Content'), findsOneWidget);
    });

    testWidgets('respects disableAnimations', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppTestHost(
            child: EntranceFader(
              child: Text('Instant Content'),
            ),
          ),
        ),
      );

      expect(find.text('Instant Content'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EntranceFader),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('animates opacity and translation over duration', (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: EntranceFader(
            duration: Duration(milliseconds: 300),
            offset: Offset(0, 20),
            child: Text('Animated Card'),
          ),
        ),
      );

      expect(find.text('Animated Card'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Animated Card'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Animated Card'), findsOneWidget);
    });
  });

  group('AnimatedCheckmark', () {
    testWidgets('renders checkmark and triggers onCompleted', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        AppTestHost(
          child: AnimatedCheckmark(
            size: 64,
            duration: const Duration(milliseconds: 200),
            onCompleted: () => completed = true,
          ),
        ),
      );

      expect(find.byType(AnimatedCheckmark), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets('respects disableAnimations', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AppTestHost(
            child: AnimatedCheckmark(
              size: 48,
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCheckmark), findsOneWidget);
      expect(completed, isTrue);
    });
  });

  group('AnimatedScannerLine', () {
    testWidgets('renders scanner reticle and line painter', (tester) async {
      await tester.pumpWidget(
        const AppTestHost(
          child: AnimatedScannerLine(
            width: 200,
            height: 200,
            duration: Duration(milliseconds: 500),
          ),
        ),
      );

      expect(find.byType(AnimatedScannerLine), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AnimatedScannerLine), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('respects disableAnimations', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppTestHost(
            child: AnimatedScannerLine(
              width: 150,
              height: 150,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedScannerLine), findsOneWidget);
    });
  });

  group('AppPageRoute', () {
    testWidgets('transitions to destination page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  AppPageRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Text('Destination Screen'),
                    ),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      expect(find.text('Go'), findsOneWidget);
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Destination Screen'), findsOneWidget);
    });
  });
}

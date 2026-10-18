import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/layout/responsive_layout.dart';

void main() {
  test('windowClassFor classifies 599/600/1023/1024 boundaries accurately', () {
    expect(windowClassFor(320), AppWindowClass.compact);
    expect(windowClassFor(599), AppWindowClass.compact);
    expect(windowClassFor(600), AppWindowClass.medium);
    expect(windowClassFor(1023), AppWindowClass.medium);
    expect(windowClassFor(1024), AppWindowClass.expanded);
    expect(windowClassFor(1440), AppWindowClass.expanded);
  });

  testWidgets('card rows reflow without losing long content', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 599.0, 600.0, 768.0, 1023.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(2),
            ),
            child: Scaffold(
              body: AppResponsivePage(
                child: CustomScrollView(
                  key: ValueKey<double>(width),
                  slivers: [
                    ResponsiveCardSliver(
                      itemCount: 8,
                      itemBuilder: (_, i) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Event $i with a long title and important registration information',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width $width');
      expect(find.textContaining('Event 0'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('form columns stack at large text and retain both fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 2,
              children: [
                TextField(decoration: InputDecoration(labelText: 'Start date')),
                TextField(decoration: InputDecoration(labelText: 'End date')),
              ],
            ),
          ),
        ),
      ),
    );
    final first = tester.getTopLeft(find.byType(TextField).first);
    final last = tester.getTopLeft(find.byType(TextField).last);
    expect(last.dy, greaterThan(first.dy));
    expect(last.dx, first.dx);
    expect(tester.takeException(), isNull);
  });
}


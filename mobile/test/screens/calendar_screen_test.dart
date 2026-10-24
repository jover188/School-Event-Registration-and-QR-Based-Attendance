import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/common/calendar_screen.dart';
import '../support/app_test_host.dart';

EventModel _makeEvent({
  int id = 1,
  String title = 'Test Event',
  String? eventDate,
  String status = 'published',
}) {
  final date = eventDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  return EventModel(
    id: id,
    title: title,
    description: 'A test description.',
    venue: 'Test Hall',
    eventDate: date,
    startTime: '09:00:00',
    endTime: '17:00:00',
    currentRegisteredCount: 0,
    lateGracePeriodMinutes: 15,
    walkInAllowed: false,
    status: status,
  );
}

void main() {
  setUp(AppTestHost.ensureStorageMocked);

  // 1. Calendar grid + header renders
  testWidgets('CalendarScreen renders calendar grid and month header',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: const [])),
    );
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
    expect(find.text('Today'), findsOneWidget);
  });

  // 2. Empty state when no day is selected on load
  testWidgets('CalendarScreen shows select-a-day hint when no day selected',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a Day'), findsOneWidget);
  });

  // 3. Event card appears for a day with injected events
  testWidgets('CalendarScreen renders event card for day with injected event',
      (tester) async {
    final today = DateTime.now();
    final event = _makeEvent(
      title: 'Campus Summit 2026',
      eventDate: DateFormat('yyyy-MM-dd').format(today),
    );

    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: [event])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus Summit 2026'), findsOneWidget);
  });

  // 4. Today button is tappable without error
  testWidgets('CalendarScreen Today button is tappable without error',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: const [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
  });

  // 5. Month ↔ Week format toggle
  testWidgets('CalendarScreen toggles between month and week format',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: const [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
  });
}

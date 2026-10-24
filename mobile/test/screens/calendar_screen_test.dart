import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/common/calendar_screen.dart';
import '../support/app_test_host.dart';

EventModel _makeEvent({
  int id = 1,
  String title = 'Test Event',
  String? eventDate,
  String status = 'published',
  String venue = 'Main Hall',
  String description = 'A test description.',
}) {
  final date = eventDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
  return EventModel(
    id: id,
    title: title,
    description: description,
    venue: venue,
    eventDate: date,
    startTime: '09:00:00',
    endTime: '17:00:00',
    currentRegisteredCount: 15,
    maxParticipants: 50,
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
      const AppTestHost(child: CalendarScreen(initialEvents: [])),
    );
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Attendify'), findsOneWidget);
  });

  // 2. Empty state when no day is selected on load
  testWidgets('CalendarScreen shows select-a-day hint when no day selected',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(child: CalendarScreen(initialEvents: [])),
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
      const AppTestHost(child: CalendarScreen(initialEvents: [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
  });

  // 5. Month ↔ Week format toggle and centered labels
  testWidgets('CalendarScreen toggles between month and week format',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(child: CalendarScreen(initialEvents: [])),
    );
    await tester.pumpAndSettle();

    final monthTabCenter = tester.getCenter(
      find.byKey(const ValueKey('calendar-format-month')),
    );
    final monthTextCenter = tester.getCenter(find.text('Month'));
    expect(monthTextCenter.dx, closeTo(monthTabCenter.dx, 1.0));
    expect(monthTextCenter.dy, closeTo(monthTabCenter.dy, 1.0));

    final weekTabCenter = tester.getCenter(
      find.byKey(const ValueKey('calendar-format-week')),
    );
    final weekTextCenter = tester.getCenter(find.text('Week'));
    expect(weekTextCenter.dx, closeTo(weekTabCenter.dx, 1.0));
    expect(weekTextCenter.dy, closeTo(weekTabCenter.dy, 1.0));

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    final monthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(monthName), findsAtLeastNWidgets(1));
  });

  // 6. Monochrome category badge, status pill, and chevron render on event card
  testWidgets('CalendarScreen renders monochrome category badge and chevron on event card',
      (tester) async {
    final today = DateTime.now();
    final event = _makeEvent(
      title: 'Hackathon Workshop',
      description: 'Tech coding workshop for students.',
      venue: 'Lab 3',
      status: 'published',
      eventDate: DateFormat('yyyy-MM-dd').format(today),
    );

    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: [event])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hackathon Workshop'), findsOneWidget);
    expect(find.text('PUBLISHED'), findsOneWidget);
    expect(find.text('WORKSHOP'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsAtLeastNWidgets(1));
    expect(find.byIcon(LucideIcons.wrench), findsOneWidget);
    expect(find.text('Capacity: 15 / 50'), findsOneWidget);
  });

  // 7. Navigation controls: Next and Previous month buttons work
  testWidgets('CalendarScreen navigation previous and next buttons advance month',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(child: CalendarScreen(initialEvents: [])),
    );
    await tester.pumpAndSettle();

    // Tap next month
    await tester.tap(find.byKey(const ValueKey('calendar-next-btn')));
    await tester.pumpAndSettle();

    final nextMonth = DateTime.now().add(const Duration(days: 35));
    final nextMonthName = DateFormat('MMMM').format(nextMonth);
    expect(find.textContaining(nextMonthName), findsAtLeastNWidgets(1));

    // Tap previous month back
    await tester.tap(find.byKey(const ValueKey('calendar-prev-btn')));
    await tester.pumpAndSettle();

    final currentMonthName = DateFormat('MMMM').format(DateTime.now());
    expect(find.textContaining(currentMonthName), findsAtLeastNWidgets(1));
  });

  // 8. Notification badge displays unread count
  testWidgets('CalendarScreen renders unread notification badge when unread count > 0',
      (tester) async {
    await tester.pumpWidget(
      const AppTestHost(
        child: CalendarScreen(
          initialEvents: [],
          initialUnreadNotifications: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-notifications-badge')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('calendar-notifications-badge')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-notifications-btn')), findsOneWidget);
  });

  // 9. Entire page scrolls vertically without nested scroll conflicts
  testWidgets('CalendarScreen entire page scrolls vertically including calendar grid and event cards',
      (tester) async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final events = List.generate(
      10,
      (i) => _makeEvent(
        id: i + 1,
        title: 'Event Number ${i + 1}',
        eventDate: todayStr,
      ),
    );

    await tester.pumpWidget(
      AppTestHost(child: CalendarScreen(initialEvents: events)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Event Number 1'), findsOneWidget);

    final scrollViewFinder = find.byKey(const PageStorageKey<String>('calendar-scroll-view'));
    expect(scrollViewFinder, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Event Number 10'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Event Number 10'), findsOneWidget);
  });

  // 10. Compact mobile viewport (320x568) renders and scrolls without overflow
  testWidgets('CalendarScreen compact mobile viewport (320x568) renders and scrolls without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final events = [
      _makeEvent(id: 1, title: 'Compact Morning Session', eventDate: todayStr),
      _makeEvent(id: 2, title: 'Compact Afternoon Session', eventDate: todayStr),
    ];

    await tester.pumpWidget(
      AppTestHost(
        child: CalendarScreen(
          embedded: true,
          initialEvents: events,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attendify'), findsNothing);
    expect(
      find.byKey(const ValueKey('calendar-notifications-btn')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    final scrollViewFinder = find.byKey(const PageStorageKey<String>('calendar-scroll-view'));
    await tester.drag(scrollViewFinder, const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

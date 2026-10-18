import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/organizer/event_form_screen.dart';
import 'package:school_event_attendance/screens/organizer/organizer_dashboard_screen.dart';
import '../support/app_test_host.dart';

EventModel _buildEvent({
  required int id,
  required String title,
  required String status,
}) {
  return EventModel(
    id: id,
    title: title,
    description: 'Detailed academic event description for $title',
    venue: 'University Main Auditorium',
    eventDate: '2026-11-20',
    startTime: '09:00:00',
    endTime: '12:00:00',
    maxParticipants: 120,
    remainingSlots: 40,
    currentRegisteredCount: 80,
    lateGracePeriodMinutes: 15,
    walkInAllowed: true,
    status: status,
  );
}

void main() {
  testWidgets('event form retains typing and bounds fields after resizing',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppTestHost(
      child: EventFormScreen(),
    ));

    final title = find.byKey(const ValueKey('event-title-field'));
    await tester.enterText(title, 'Campus research showcase');
    expect(tester.getSize(title).width, lessThanOrEqualTo(720));

    tester.view.physicalSize = const Size(320, 568);
    await tester.pump();

    expect(find.text('Campus research showcase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'event form separates save draft and submit approval actions and scales to 2x text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draftEvent = _buildEvent(
      id: 15,
      title: 'Annual Cybersecurity & Software Engineering Colloquium',
      status: 'draft',
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2.0),
        ),
        child: AppTestHost(
          child: EventFormScreen(event: draftEvent),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edit Event'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('save-event-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('submit-approval-button')),
      findsOneWidget,
    );
    expect(find.text('Save Event Changes'), findsOneWidget);
    expect(find.text('Submit for Admin Approval'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'organizer dashboard separates overview, my events, and reports and disables scanner on draft events',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixtures = [
      _buildEvent(
        id: 1,
        title: 'Published AI Ethics Forum',
        status: 'published',
      ),
      _buildEvent(
        id: 2,
        title: 'Draft Robotics Workshop',
        status: 'draft',
      ),
    ];

    await tester.pumpWidget(
      AppTestHost(
        child: OrganizerDashboardScreen(
          initialEvents: fixtures,
          initialSummary: const {
            'total_events': 2,
            'published_events': 1,
            'ongoing_events': 0,
            'pending_events': 1,
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Event Operations Summary'), findsOneWidget);
    expect(find.text('Published AI Ethics Forum'), findsOneWidget);
    expect(find.text('Draft Robotics Workshop'), findsOneWidget);
    expect(
      find.textContaining('QR scanning requires Published or Ongoing status'),
      findsOneWidget,
    );

    // Switch to My Events destination
    await tester.tap(find.byKey(const ValueKey('destination-events')));
    await tester.pump();

    expect(find.text('Manage Owned Events'), findsOneWidget);
    final searchField = find.byKey(
      const ValueKey('organizer-events-search-field'),
    );
    await tester.enterText(searchField, 'Robotics');
    await tester.pump();

    expect(find.text('Draft Robotics Workshop'), findsOneWidget);

    // Resize to compact width and verify search state is preserved
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();

    expect(find.text('Draft Robotics Workshop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

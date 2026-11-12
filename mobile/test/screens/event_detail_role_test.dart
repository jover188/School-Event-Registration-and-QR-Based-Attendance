import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';

import '../support/app_test_host.dart';

EventModel _event() => EventModel.fromJson({
      'id': 1,
      'title': 'Role Test Event',
      'description': 'desc',
      'venue': 'Hall',
      'event_date': '2026-12-01',
      'start_time': '08:00',
      'end_time': '10:00',
      'status': 'published',
      'max_participants': 50,
      'current_registered_count': 10,
      'late_grace_period_minutes': 15,
      'walk_in_allowed': false,
    });

void main() {
  setUp(AppTestHost.ensureStorageMocked);

  testWidgets('student sees Registration pane and register button',
      (tester) async {
    await tester.pumpWidget(AppTestHost(
      child: EventDetailScreen(initialEvent: _event(), viewerRole: 'student'),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-detail-action-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-event-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-detail-staff-pane')), findsNothing);
  });

  for (final role in ['administrator', 'organizer', 'management']) {
    testWidgets('$role does not see registration UI', (tester) async {
      await tester.pumpWidget(AppTestHost(
        child: EventDetailScreen(initialEvent: _event(), viewerRole: role),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-detail-action-pane')), findsNothing);
      expect(find.byKey(const ValueKey('register-event-button')), findsNothing);
      expect(find.text('Register for Event'), findsNothing);
      expect(find.byKey(const ValueKey('event-detail-staff-pane')), findsOneWidget);
    });
  }
}

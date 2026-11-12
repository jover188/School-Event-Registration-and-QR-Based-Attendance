import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/widgets/event_card.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';
import '../support/app_test_host.dart';

void main() {
  group('EventCard & EventDetailScreen Category and Audience Badges', () {
    testWidgets('EventCard renders category and audience badges',
        (tester) async {
      final event = EventModel(
        id: 101,
        title: 'Full Stack Engineering Seminar',
        description: 'Deep dive into modern web and mobile apps',
        venue: 'Main Auditorium',
        eventDate: '2026-11-20',
        startTime: '09:00:00',
        endTime: '12:00:00',
        currentRegisteredCount: 45,
        lateGracePeriodMinutes: 15,
        walkInAllowed: true,
        status: 'published',
        category: 'Seminar',
        targetAudienceType: 'course',
        targetCourses: const ['BSIT', 'BSCS'],
      );

      await tester.pumpWidget(AppTestHost(
        child: Scaffold(
          body: EventCard(event: event),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SEMINAR'), findsOneWidget);
      expect(find.text('Course: BSIT, BSCS'), findsOneWidget);
    });

    testWidgets('EventCard renders All Students badge by default',
        (tester) async {
      final event = EventModel(
        id: 102,
        title: 'University Sports Fest Opening',
        description: 'Campus-wide celebration',
        venue: 'Sports Complex',
        eventDate: '2026-11-22',
        startTime: '08:00:00',
        endTime: '17:00:00',
        currentRegisteredCount: 150,
        lateGracePeriodMinutes: 30,
        walkInAllowed: true,
        status: 'published',
        category: 'Sports',
        targetAudienceType: 'all',
      );

      await tester.pumpWidget(AppTestHost(
        child: Scaffold(
          body: EventCard(event: event),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('SPORTS'), findsOneWidget);
      expect(find.text('All Students'), findsOneWidget);
    });

    testWidgets('EventDetailScreen renders Category and Target Audience badge in header',
        (tester) async {
      final event = EventModel(
        id: 103,
        title: 'Cybersecurity Hands-on Workshop',
        description: 'Network defense simulation',
        venue: 'IT Lab 2',
        eventDate: '2026-11-25',
        startTime: '13:00:00',
        endTime: '16:00:00',
        currentRegisteredCount: 20,
        lateGracePeriodMinutes: 15,
        walkInAllowed: false,
        status: 'published',
        category: 'Workshop',
        targetAudienceType: 'custom',
        targetRules: const [
          {'course': 'BSIT', 'year_level': '3rd Year'}
        ],
      );

      await tester.pumpWidget(AppTestHost(
        child: EventDetailScreen(
          eventId: 103,
          initialEvent: event,
          viewerRole: 'student',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP'), findsOneWidget);
      expect(find.text('BSIT (3rd Year)'), findsOneWidget);
      expect(find.text('Cybersecurity Hands-on Workshop'), findsWidgets);
    });
  });
}

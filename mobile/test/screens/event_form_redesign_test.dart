import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/organizer/event_form_screen.dart';
import '../support/app_test_host.dart';

void main() {
  group('EventFormScreen Redesign & Audience Targeting', () {
    testWidgets('renders all 6 required sections on create event screen',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppTestHost(
        child: EventFormScreen(),
      ));
      await tester.pumpAndSettle();

      // Section A: Event Information
      expect(find.text('Event Information'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-title-field')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('event-description-field')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('event-category-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('event-venue-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('event-cover-image-field')),
          findsOneWidget);

      // Section B: Target Participants
      expect(find.text('Target Participants'), findsOneWidget);
      expect(find.byKey(const ValueKey('audience-type-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('audience-type-course')), findsOneWidget);
      expect(find.byKey(const ValueKey('audience-type-year-level')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('audience-type-custom')), findsOneWidget);

      // Section C: Event Schedule
      expect(find.text('Event Schedule'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-date-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('event-start-time-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('event-end-time-field')), findsOneWidget);

      // Section D: Registration Period
      expect(find.text('Registration Period'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('registration-start-field')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('registration-end-field')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('max-participants-field')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('walk-in-allowed-switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('late-grace-period-field')),
          findsOneWidget);

      // Section E: Notification Settings
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('send-announcement-switch')),
          findsOneWidget);
      expect(
          find.textContaining('Notifications will only be sent to students'),
          findsOneWidget);

      // Section F: Review and Publish
      expect(find.text('Review & Publish'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-summary-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('submit-event-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('save-draft-button')), findsOneWidget);
    });

    testWidgets('audience type selector switches between modes and updates summary',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppTestHost(
        child: EventFormScreen(),
      ));
      await tester.pumpAndSettle();

      // Default is All Students
      expect(find.text('All Students'), findsWidgets);

      // Select Specific Course
      await tester.tap(find.byKey(const ValueKey('audience-type-course')));
      await tester.pumpAndSettle();

      // Check course chip exists and tap BSIT
      final bsitChip = find.byKey(const ValueKey('course-chip-BSIT'));
      expect(bsitChip, findsOneWidget);
      await tester.tap(bsitChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('Course: BSIT'), findsWidgets);

      // Select Specific Year Level
      await tester.tap(find.byKey(const ValueKey('audience-type-year-level')));
      await tester.pumpAndSettle();

      final firstYearChip =
          find.byKey(const ValueKey('year-chip-1st Year'));
      expect(firstYearChip, findsOneWidget);
      await tester.tap(firstYearChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('Year: 1st Year'), findsWidgets);

      // Select Custom Combination
      await tester.tap(find.byKey(const ValueKey('audience-type-custom')));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('add-combination-button')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-combination-button')));
      await tester.pumpAndSettle();

      // Verify combination chip was added
      expect(find.byKey(const ValueKey('combo-rule-0')), findsOneWidget);
    });

    testWidgets('populates fields when editing an existing event with audience targeting',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existingEvent = EventModel(
        id: 25,
        title: 'Cybersecurity Workshop',
        description: 'Advanced Network Defense',
        venue: 'Computer Lab 4',
        eventDate: '2026-11-30',
        startTime: '10:00:00',
        endTime: '15:00:00',
        maxParticipants: 40,
        remainingSlots: 15,
        currentRegisteredCount: 25,
        lateGracePeriodMinutes: 20,
        walkInAllowed: true,
        status: 'draft',
        category: 'Workshop',
        coverImagePath: 'https://example.com/banner.jpg',
        targetAudienceType: 'course',
        targetCourses: const ['BSIT', 'BSCS'],
        sendAnnouncement: false,
      );

      await tester.pumpWidget(AppTestHost(
        child: EventFormScreen(event: existingEvent),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Cybersecurity Workshop'), findsWidgets);
      expect(find.text('Workshop'), findsWidgets);
      expect(find.text('https://example.com/banner.jpg'), findsOneWidget);
      expect(find.textContaining('Course: BSIT, BSCS'), findsWidgets);
      expect(find.byKey(const ValueKey('save-event-button')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('submit-approval-button')), findsOneWidget);
    });
  });
}

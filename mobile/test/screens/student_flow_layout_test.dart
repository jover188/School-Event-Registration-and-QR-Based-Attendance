import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';
import 'package:school_event_attendance/screens/student/student_dashboard_screen.dart';
import '../support/app_test_host.dart';

List<EventModel> _buildStudentEventFixtures() {
  return [
    EventModel(
      id: 1,
      title: 'Annual Cybersecurity & Cloud Computing Summit 2026',
      description: 'Confirmed registration fixture event.',
      venue: 'Main University Auditorium',
      eventDate: '2026-11-10',
      startTime: '08:00:00',
      endTime: '12:00:00',
      maxParticipants: 200,
      remainingSlots: 45,
      currentRegisteredCount: 155,
      lateGracePeriodMinutes: 15,
      walkInAllowed: true,
      status: 'published',
      userRegistrationStatus: 'registered',
    ),
    EventModel(
      id: 2,
      title: 'Data Science & Machine Learning Colloquium',
      description: 'Waiting-list student fixture event.',
      venue: 'Engineering Lecture Hall B',
      eventDate: '2026-11-12',
      startTime: '13:00:00',
      endTime: '17:00:00',
      maxParticipants: 100,
      remainingSlots: 0,
      currentRegisteredCount: 100,
      lateGracePeriodMinutes: 10,
      walkInAllowed: false,
      status: 'published',
      userRegistrationStatus: 'waiting_list',
      userWaitingPosition: 3,
    ),
    EventModel(
      id: 3,
      title: 'Campus Robotics Workshop',
      description: 'Full capacity event open for waiting list.',
      venue: 'Innovation Lab 401',
      eventDate: '2026-11-15',
      startTime: '09:00:00',
      endTime: '15:00:00',
      maxParticipants: 50,
      remainingSlots: 0,
      currentRegisteredCount: 50,
      lateGracePeriodMinutes: 15,
      walkInAllowed: false,
      status: 'published',
    ),
    EventModel(
      id: 4,
      title: 'Outdoor Cultural Night',
      description: 'Cancelled campus event fixture.',
      venue: 'University Grand Oval',
      eventDate: '2026-11-20',
      startTime: '18:00:00',
      endTime: '21:00:00',
      maxParticipants: 300,
      remainingSlots: 180,
      currentRegisteredCount: 120,
      lateGracePeriodMinutes: 20,
      walkInAllowed: true,
      status: 'cancelled',
    ),
  ];
}

void main() {
  group('StudentDashboardScreen responsive layout and states', () {
    testWidgets(
      'renders registered, waiting-list, full, and cancelled fixtures in single scroll region and retains search across resizes and tabs',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = const Size(390, 844);

        final fixtures = _buildStudentEventFixtures();
        await tester.pumpWidget(
          AppTestHost(
            child: StudentDashboardScreen(
              initialEvents: fixtures,
              initialStats: const {
                'total_registered_events': 2,
                'total_attended_events': 5,
                'waiting_list_count': 1,
              },
              initialRegistrations: const [],
              initialQrData: const {
                'qr_token':
                    'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
                'full_name': 'Juan M. Dela Cruz',
                'student_id_number': '20260001',
                'status': 'active',
              },
              initialAttendanceRecords: const [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Single CustomScrollView for the events destination.
        expect(find.byType(CustomScrollView), findsOneWidget);

        // Summary metrics visible.
        expect(find.text('Registered'), findsOneWidget);
        expect(find.text('Attended'), findsOneWidget);
        expect(find.text('Waiting List'), findsOneWidget);

        // Server-backed statuses and actions visible across fixtures.
        expect(find.text('REGISTERED'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('WAITING #3'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('WAITING #3'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Join Waiting List'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Join Waiting List'), findsOneWidget);

        // Enter search query and verify retention across compact, medium, and expanded widths.
        final searchField = find.byKey(
          const ValueKey('student-events-search-input'),
        );
        await tester.scrollUntilVisible(
          searchField,
          -120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(searchField, findsOneWidget);
        await tester.enterText(searchField, 'Cybersecurity');
        await tester.pump();

        for (final size in const [
          Size(390, 844),
          Size(768, 1024),
          Size(1440, 900),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          expect(find.text('Cybersecurity'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'size $size');
        }

        // Switch destinations and return to Events without losing search input.
        await tester.tap(find.byKey(const ValueKey('destination-qr')));
        await tester.pumpAndSettle();
        expect(find.text('Juan M. Dela Cruz'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('destination-events')));
        await tester.pumpAndSettle();
        expect(find.text('Cybersecurity'), findsOneWidget);
      },
    );

    testWidgets(
      'handles 320x568 at 2x text scale, empty state, and partial failure banner without overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixtures = _buildStudentEventFixtures();
        await tester.pumpWidget(
          AppTestHost(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
              ),
              child: StudentDashboardScreen(
                initialEvents: fixtures,
                initialStats: const {
                  'total_registered_events': 1,
                  'total_attended_events': 3,
                  'waiting_list_count': 1,
                },
                initialErrorMessage: 'Summary metrics may be outdated.',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Summary metrics may be outdated.'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify empty state fixture.
        await tester.pumpWidget(
          const AppTestHost(
            child: StudentDashboardScreen(
              initialEvents: [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No upcoming events found.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('EventDetailScreen responsive layout and states', () {
    testWidgets(
      'stacks action pane on narrow 390x844 and renders side action pane on wide 1280x800',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixtures = _buildStudentEventFixtures();
        final registeredEvent = fixtures[0];

        // Narrow 390x844 -> stacked layout
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: registeredEvent.id,
              initialEvent: registeredEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final mainPaneNarrow = tester.getTopLeft(
          find.byKey(const ValueKey('event-detail-main-pane')),
        );
        final actionPaneNarrow = tester.getTopLeft(
          find.byKey(const ValueKey('event-detail-action-pane')),
        );
        expect(actionPaneNarrow.dy, greaterThan(mainPaneNarrow.dy));
        expect(actionPaneNarrow.dx, equals(mainPaneNarrow.dx));
        expect(find.text('REGISTERED'), findsOneWidget);
        expect(find.text('Cancel My Registration'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Wide 1280x800 -> 2-column layout with 320-wide right action pane
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pumpAndSettle();

        final mainPaneWide = tester.getTopLeft(
          find.byKey(const ValueKey('event-detail-main-pane')),
        );
        final actionPaneWide = tester.getTopLeft(
          find.byKey(const ValueKey('event-detail-action-pane')),
        );
        final actionPaneSize = tester.getSize(
          find.byKey(const ValueKey('event-detail-action-pane')),
        );
        expect(actionPaneWide.dx, greaterThan(mainPaneWide.dx));
        expect(actionPaneSize.width, equals(320));
        expect(tester.takeException(), isNull);

        // Tapping Cancel My Registration opens consequence confirmation dialog
        await tester.tap(
          find.byKey(const ValueKey('cancel-registration-button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cancel Registration?'), findsOneWidget);
        expect(
          find.textContaining('waiting list'),
          findsWidgets,
        );
        await tester.tap(find.text('Keep Registration'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'distinguishes waiting-list, full, and cancelled event states accurately',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixtures = _buildStudentEventFixtures();
        final waitingListEvent = fixtures[1];
        final fullEvent = fixtures[2];
        final cancelledEvent = fixtures[3];

        // Waiting-list fixture
        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: waitingListEvent.id,
              initialEvent: waitingListEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('WAITING LIST #3'), findsOneWidget);
        expect(find.text('Cancel My Registration'), findsOneWidget);

        // Full capacity fixture (not yet registered)
        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: fullEvent.id,
              initialEvent: fullEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('0 slots left (Full)'), findsOneWidget);
        expect(find.text('Join Waiting List'), findsOneWidget);

        // Cancelled event fixture
        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: cancelledEvent.id,
              initialEvent: cancelledEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('CANCELLED'), findsOneWidget);
        expect(find.text('Event Cancelled'), findsOneWidget);
        expect(
          find.textContaining('Registration is closed'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}

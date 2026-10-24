import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/core/widgets/app_toast.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/student/event_detail_screen.dart';
import 'package:school_event_attendance/screens/student/my_attendance_history_screen.dart';
import 'package:school_event_attendance/screens/student/my_registrations_screen.dart';
import 'package:school_event_attendance/screens/student/permanent_qr_screen.dart';
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

        // Verify My Profile is at the very top of the sidebar above all pages, categorized with labels, and Logout is at bottom.
        final accountCategoryFinder = find.byKey(
          const ValueKey('destination-category-account'),
        );
        final eventsCategoryFinder = find.byKey(
          const ValueKey('destination-category-events'),
        );
        final attendanceCategoryFinder = find.byKey(
          const ValueKey('destination-category-attendance'),
        );
        final profileFinder = find.byKey(const ValueKey('destination-profile'));
        final eventsNavFinder = find.byKey(const ValueKey('destination-events'));
        final calendarNavFinder = find.byKey(
          const ValueKey('destination-calendar'),
        );
        final registrationsFinder = find.byKey(
          const ValueKey('destination-registrations'),
        );
        final historyFinder = find.byKey(const ValueKey('destination-history'));
        final logoutFinder = find.byKey(const ValueKey('destination-logout'));

        expect(accountCategoryFinder, findsOneWidget);
        expect(eventsCategoryFinder, findsOneWidget);
        expect(attendanceCategoryFinder, findsOneWidget);
        expect(profileFinder, findsOneWidget);
        expect(eventsNavFinder, findsOneWidget);
        expect(calendarNavFinder, findsOneWidget);
        expect(registrationsFinder, findsOneWidget);
        expect(logoutFinder, findsOneWidget);
        expect(
          tester.getTopLeft(accountCategoryFinder).dy,
          lessThan(tester.getTopLeft(profileFinder).dy),
        );
        expect(
          tester.getTopLeft(profileFinder).dy,
          lessThan(tester.getTopLeft(eventsCategoryFinder).dy),
        );
        expect(
          tester.getTopLeft(eventsCategoryFinder).dy,
          lessThan(tester.getTopLeft(eventsNavFinder).dy),
        );
        expect(
          tester.getTopLeft(calendarNavFinder).dy,
          lessThan(tester.getTopLeft(attendanceCategoryFinder).dy),
        );
        expect(
          tester.getTopLeft(attendanceCategoryFinder).dy,
          lessThan(tester.getTopLeft(registrationsFinder).dy),
        );
        expect(
          tester.getTopLeft(logoutFinder).dy,
          greaterThan(tester.getBottomLeft(historyFinder).dy),
        );
        expect(find.byTooltip('Refresh'), findsNothing);
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

    testWidgets(
      'mobile 390x844 shows 4 primary bottom tabs, 3-up metric strip, and unread notification badge',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixtures = _buildStudentEventFixtures();
        await tester.pumpWidget(
          AppTestHost(
            child: StudentDashboardScreen(
              initialEvents: fixtures,
              initialStats: const {
                'total_registered_events': 2,
                'total_attended_events': 5,
                'waiting_list_count': 1,
                'unread_notifications': 3,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 4 primary tabs on compact phone bottom bar (no redundant More button; History & Profile in drawer)
        expect(find.byKey(const ValueKey('destination-events')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('destination-calendar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('destination-registrations')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('destination-qr')), findsOneWidget);
        expect(find.byKey(const ValueKey('destination-more')), findsNothing);
        expect(find.byKey(const ValueKey('destination-history')), findsNothing);
        expect(find.byKey(const ValueKey('destination-profile')), findsNothing);

        // 3 summary metric cards aligned on a single horizontal row on 390px phone
        final regTop = tester.getTopLeft(find.text('Registered')).dy;
        final attTop = tester.getTopLeft(find.text('Attended')).dy;
        final waitTop = tester.getTopLeft(find.text('Waiting List')).dy;
        expect(regTop, closeTo(attTop, 2.0));
        expect(attTop, closeTo(waitTop, 2.0));

        // Unread notification badge shown on top header bell
        expect(
          find.byKey(const ValueKey('student-notifications-badge')),
          findsOneWidget,
        );
        expect(find.text('3'), findsOneWidget);
      },
    );
  });

  group('MyRegistrationsScreen and MyAttendanceHistoryScreen mobile UX', () {
    testWidgets(
      'MyRegistrationsScreen renders View Details action and navigates to EventDetailScreen',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: MyRegistrationsScreen(
              embedded: true,
              initialRegistrations: [
                {
                  'id': 10,
                  'event_id': 1,
                  'status': 'registered',
                  'event': {
                    'id': 1,
                    'title': 'Annual AI & Robotics Summit',
                    'description': 'Hands-on AI symposium.',
                    'venue': 'Main Auditorium',
                    'event_date': '2026-10-15',
                    'start_time': '09:00:00',
                    'end_time': '12:00:00',
                    'status': 'published',
                  },
                },
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final viewDetailsBtn = find.byKey(
          const ValueKey('view-registration-event-1'),
        );
        expect(viewDetailsBtn, findsOneWidget);
        expect(find.text('Cancel Registration'), findsNothing);

        await tester.tap(viewDetailsBtn);
        await tester.pumpAndSettle();
        expect(find.byType(EventDetailScreen), findsOneWidget);
        expect(find.text('Annual AI & Robotics Summit'), findsWidgets);
        expect(find.text('Cancel My Registration'), findsOneWidget);
      },
    );

    testWidgets(
      'MyAttendanceHistoryScreen filters by status chip and opens EventDetailScreen on card tap',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: MyAttendanceHistoryScreen(
              embedded: true,
              initialRecords: [
                {
                  'id': 101,
                  'status': 'present',
                  'check_in_time': '2026-10-02 08:54:00',
                  'check_out_time': '2026-10-02 12:01:00',
                  'event': {
                    'id': 11,
                    'title': 'Cybersecurity Workshop',
                    'description': 'Campus security lab.',
                    'venue': 'Lab 201',
                    'event_date': '2026-10-02',
                    'start_time': '09:00:00',
                    'end_time': '12:00:00',
                    'status': 'completed',
                  },
                },
                {
                  'id': 102,
                  'status': 'late',
                  'check_in_time': '2026-09-25 09:22:00',
                  'check_out_time': null,
                  'event': {
                    'id': 12,
                    'title': 'Cloud Computing Seminar',
                    'description': 'Cloud architecture overview.',
                    'venue': 'Room 302',
                    'event_date': '2026-09-25',
                    'start_time': '09:00:00',
                    'end_time': '11:45:00',
                    'status': 'completed',
                  },
                },
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Both records initially visible
        expect(find.text('Cybersecurity Workshop'), findsOneWidget);
        expect(find.text('Cloud Computing Seminar'), findsOneWidget);

        // Filter by Late chip
        await tester.tap(
          find.byKey(const ValueKey('attendance-filter-late')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cybersecurity Workshop'), findsNothing);
        expect(find.text('Cloud Computing Seminar'), findsOneWidget);

        // Tapping history card opens EventDetailScreen
        await tester.tap(find.text('Cloud Computing Seminar'));
        await tester.pumpAndSettle();
        expect(find.byType(EventDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'highlighted filter chips in student screens adapt between light and dark modes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            themeMode: ThemeMode.light,
            child: MyAttendanceHistoryScreen(
              embedded: true,
              initialRecords: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final lightChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('attendance-filter-all')),
        );
        expect(lightChip.selectedColor, const Color(0xFF18181B));

        await tester.pumpWidget(
          const AppTestHost(
            themeMode: ThemeMode.dark,
            child: MyAttendanceHistoryScreen(
              embedded: true,
              initialRecords: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final darkChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('attendance-filter-all')),
        );
        expect(darkChip.selectedColor, const Color(0xFFFFFFFF));
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

    testWidgets(
      'enforces consistent typography tokens and concise labels across student pages',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. MyRegistrationsScreen filter chips use 13px supporting token
        await tester.pumpWidget(
          const AppTestHost(
            child: MyRegistrationsScreen(
              embedded: true,
              initialRegistrations: [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final regChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('registration-filter-all')),
        );
        expect(regChip.labelStyle?.fontSize, 13);
        expect(find.text('Refresh'), findsNothing);

        // 2. MyAttendanceHistoryScreen filter chips use 13px supporting token and concise Check-In / Check-Out labels
        await tester.pumpWidget(
          const AppTestHost(
            child: MyAttendanceHistoryScreen(
              embedded: true,
              initialRecords: [
                {
                  'id': 1,
                  'status': 'present',
                  'check_in_time': '2026-10-02 08:54:00',
                  'check_out_time': '2026-10-02 12:01:00',
                  'event': {
                    'id': 11,
                    'title': 'Cybersecurity Workshop',
                    'venue': 'Lab 201',
                    'event_date': '2026-10-02',
                  },
                },
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final attChip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('attendance-filter-all')),
        );
        expect(attChip.labelStyle?.fontSize, 13);
        expect(find.text('Check-In'), findsOneWidget);
        expect(find.text('Check-Out'), findsOneWidget);
        expect(find.text('Check-In Time'), findsNothing);
        expect(find.text('Check-Out Time'), findsNothing);

        // 3. PermanentQrScreen uses ACTIVE badge without redundant STATUS: prefix
        await tester.pumpWidget(
          const AppTestHost(
            child: PermanentQrScreen(
              embedded: true,
              initialQrData: {
                'qr_token':
                    'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
                'full_name': 'Juan M. Dela Cruz',
                'student_id_number': '20260001',
                'status': 'active',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('STATUS: ACTIVE'), findsNothing);

        // 4. EventDetailScreen uses 14px body text for info rows and concise labels
        final fixtures = _buildStudentEventFixtures();
        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: fixtures[0].id,
              initialEvent: fixtures[0],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final venueText = tester.widget<Text>(
          find.text('Main University Auditorium'),
        );
        expect(venueText.style?.fontSize, 14);
        expect(find.text('Available Slots'), findsOneWidget);
        expect(find.text('Your Status'), findsOneWidget);
        expect(find.text('Walk-ins allowed'), findsOneWidget);

        // 5. 15px border radius on buttons & cards, primary icon colors, and top-left icon alignment
        expect(regChip.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)));

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1440, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          AppTestHost(
            child: StudentDashboardScreen(
              initialEvents: fixtures,
              initialStats: const {
                'total_registered_events': 2,
                'total_attended_events': 5,
                'waiting_list_count': 1,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify StatMetricCard icon is top-left and vertically centered with 'Registered' title
        final regTitleCenter = tester.getCenter(find.text('Registered'));
        final regCardIcon = find.byKey(const ValueKey('stat-icon-Registered'));
        expect(regCardIcon, findsOneWidget);
        final regIconWidget = tester.widget<Icon>(regCardIcon);
        expect(regIconWidget.color, const Color(0xFF18181B));
        final regIconCenter = tester.getCenter(regCardIcon);
        expect(regIconCenter.dx, lessThan(regTitleCenter.dx));
        expect(regIconCenter.dy, closeTo(regTitleCenter.dy, 2.0));

        // 6. Verify EventCard grid equal card heights, clean time format, and standardized action buttons
        expect(find.text('08:00 AM - 12:00 PM'), findsOneWidget);
        expect(find.text('01:00 PM - 05:00 PM'), findsOneWidget);
        expect(find.textContaining('2026-11-10'), findsNothing);

        final timeTextWidget = tester.widget<Text>(
          find.text('08:00 AM - 12:00 PM'),
        );
        expect(timeTextWidget.style?.fontSize, 14);
        expect(timeTextWidget.style?.fontWeight, FontWeight.w500);

        // Verify action buttons in the first 3-column grid row share identical height and baseline
        final viewRegRect = tester.getRect(find.text('View Registration'));
        final waitingListBtnRect = tester.getRect(find.text('WAITING LIST #3'));
        final joinWaitingBtnRect = tester.getRect(find.text('Join Waiting List'));
        expect(viewRegRect.center.dy, closeTo(waitingListBtnRect.center.dy, 1.0));
        expect(viewRegRect.center.dy, closeTo(joinWaitingBtnRect.center.dy, 1.0));
      },
    );

    testWidgets(
      'Keep Registration button has contrasting styles in Dark mode and closes modal without API request',
      (tester) async {
        addTearDown(() {
          ApiClient.mockHandler = null;
          AppToast.dismiss(immediate: true);
        });

        bool apiCalled = false;
        ApiClient.mockHandler = (method, endpoint, body) async {
          apiCalled = true;
          return ApiResponse(success: true, statusCode: 200);
        };

        final fixtures = _buildStudentEventFixtures();
        final registeredEvent = fixtures.firstWhere((e) => e.isRegistered);

        await tester.pumpWidget(
          AppTestHost(
            themeMode: ThemeMode.dark,
            child: EventDetailScreen(
              eventId: registeredEvent.id,
              initialEvent: registeredEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find and tap Cancel My Registration button
        final cancelBtn = find.byKey(const ValueKey('cancel-registration-button'));
        expect(cancelBtn, findsOneWidget);
        await tester.ensureVisible(cancelBtn);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Verify confirmation dialog opened
        expect(find.text('Cancel Registration?'), findsOneWidget);

        // Find Keep Registration button
        final keepBtnFinder = find.byKey(const ValueKey('cancel-dialog-keep-button'));
        expect(keepBtnFinder, findsOneWidget);

        final keepBtnWidget = tester.widget<OutlinedButton>(keepBtnFinder);
        // Verify styling: foreground color is high contrast white in dark mode, background is dark card
        final style = keepBtnWidget.style;
        final foregroundColor = style?.foregroundColor?.resolve({WidgetState.selected});
        final backgroundColor = style?.backgroundColor?.resolve({WidgetState.selected});
        expect(foregroundColor, const Color(0xFFFFFFFF));
        expect(backgroundColor, const Color(0xFF121214));

        // Tap Keep Registration button
        await tester.tap(keepBtnFinder);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Cancel Registration?'), findsNothing);

        // API should NOT have been called
        expect(apiCalled, isFalse);

        // Status and remaining slots remain intact
        expect(find.text('REGISTERED'), findsOneWidget);
        expect(find.text('45 slots left'), findsOneWidget);
      },
    );

    testWidgets(
      'Cancellation rejection displays top-center error toast and preserves registration',
      (tester) async {
        addTearDown(() {
          ApiClient.mockHandler = null;
          AppToast.dismiss(immediate: true);
        });

        const rejectionMessage =
            'Registrations cannot be cancelled after the event has started.';

        ApiClient.mockHandler = (method, endpoint, body) async {
          if (method == 'DELETE') {
            return ApiResponse(
              success: false,
              message: rejectionMessage,
              statusCode: 422,
            );
          }
          return ApiResponse(success: true, statusCode: 200);
        };

        final fixtures = _buildStudentEventFixtures();
        final registeredEvent = fixtures.firstWhere((e) => e.isRegistered);

        await tester.pumpWidget(
          AppTestHost(
            child: EventDetailScreen(
              eventId: registeredEvent.id,
              initialEvent: registeredEvent,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Cancel My Registration
        final cancelBtn = find.byKey(const ValueKey('cancel-registration-button'));
        await tester.ensureVisible(cancelBtn);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Tap Cancel Slot in confirmation modal
        final confirmBtn = find.byKey(const ValueKey('cancel-dialog-confirm-button'));
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog should be closed
        expect(find.text('Cancel Registration?'), findsNothing);

        // Top-center error toast appears with rejection message
        final toastContainer = find.byKey(const ValueKey('app-toast-container'));
        expect(toastContainer, findsOneWidget);
        expect(find.text(rejectionMessage), findsOneWidget);
        expect(find.byKey(const ValueKey('app-toast-icon-error')), findsOneWidget);

        // Toast is positioned at top center
        final toastCenter = tester.getCenter(toastContainer);
        expect(toastCenter.dy, lessThan(100.0));

        // Registration status and slots remain intact
        expect(find.text('REGISTERED'), findsOneWidget);
        expect(find.text('45 slots left'), findsOneWidget);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/common/reports_screen.dart';
import '../support/app_test_host.dart';

final List<EventModel> _fixtureEvents = [
  EventModel(
    id: 10,
    title: 'University-Wide Artificial Intelligence & Ethics Symposium 2026',
    description: 'Annual symposium',
    venue: 'Grand Amphitheater',
    eventDate: '2026-10-25',
    startTime: '08:00:00',
    endTime: '17:00:00',
    maxParticipants: 300,
    remainingSlots: 42,
    currentRegisteredCount: 258,
    lateGracePeriodMinutes: 15,
    walkInAllowed: true,
    status: 'published',
  ),
];

const Map<String, dynamic> _fixtureSummaryAndRecordsPayload = {
  'summary': {
    'total_registered_participants_across_departments': 258,
    'total_verified_present_on_time': 214,
    'late_arrivals_recorded': 29,
    'unexcused_absentees_count': 15,
  },
  'records': [
    {
      'id': 501,
      'status': 'present',
      'check_in_time': '2026-10-25T08:03:19',
      'student': {
        'student_id_number': '202600192',
        'full_name':
            'Maria Christina Concepcion Dela Cruz-Villanueva of Computer Studies',
        'course':
            'Bachelor of Science in Computer Science Specialized in Distributed Systems',
      },
      'event': {
        'title':
            'University-Wide Artificial Intelligence & Ethics Symposium 2026',
        'event_date': '2026-10-25',
      },
    },
    {
      'id': 502,
      'status': 'late',
      'check_in_time': '2026-10-25T08:27:44',
      'student': {
        'student_id_number': '202600488',
        'full_name': 'Gabriel Lorenzo Santos',
        'course': 'BS Information Technology',
      },
    },
  ],
};

void main() {
  group('ReportsScreen responsive layout & behavior tests', () {
    testWidgets(
      'lists all 7 report types and toggles conditional event/student filters and PDF export restriction',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          AppTestHost(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1280, 900)),
              child: ReportsScreen(
                initialEvents: _fixtureEvents,
                initialReportPayload: _fixtureSummaryAndRecordsPayload,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Default is event_attendance: needsEvent = true, needsStudent = false, PDF supported
        expect(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('report-student-id-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('export-pdf-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('export-csv-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('export-excel-button')),
          findsOneWidget,
        );

        // Open Report Type dropdown and verify all 7 report types exist
        await tester.tap(
          find.byKey(const ValueKey<String>('report-type-dropdown')),
        );
        await tester.pumpAndSettle();

        const expectedLabels = [
          'Event Attendance Report',
          'Student Attendance History',
          'Event Registration Summary',
          'Institutional Participation Summary',
          'Event Absentee Report',
          'Walk-In Attendees Report',
          'Organizer Activity Summary',
        ];
        for (final label in expectedLabels) {
          expect(find.text(label), findsWidgets);
        }

        // Switch to Student Attendance History (needsStudent = true, needsEvent = false, PDF hidden)
        await tester.tap(find.text('Student Attendance History').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('report-student-id-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('export-pdf-button')),
          findsNothing,
        );

        // Switch to Institutional Participation Summary (neither event nor student ID needed)
        await tester.tap(
          find.byKey(const ValueKey<String>('report-type-dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Institutional Participation Summary').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('report-student-id-field')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('export-pdf-button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders long summary metrics and record labels at 320x568 (2x text scale) and 1440x900 without overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Test 320x568 with 2x text scale
        tester.view.physicalSize = const Size(320, 568);
        await tester.pumpWidget(
          AppTestHost(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
              ),
              child: ReportsScreen(
                initialEvents: _fixtureEvents,
                initialReportPayload: _fixtureSummaryAndRecordsPayload,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Maria Christina Concepcion'), findsOneWidget);

        // 2. Test 1440x900 desktop viewport and verify record rows do not stretch full window width
        tester.view.physicalSize = const Size(1440, 900);
        await tester.pumpWidget(
          AppTestHost(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1440, 900)),
              child: ReportsScreen(
                initialEvents: _fixtureEvents,
                initialReportPayload: _fixtureSummaryAndRecordsPayload,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final recordFinder = find.textContaining('Maria Christina Concepcion');
        expect(recordFinder, findsOneWidget);
        final recordSize = tester.getSize(recordFinder);
        expect(recordSize.width, lessThan(900));
      },
    );

    testWidgets(
      'validates invalid filter inputs, renders empty state, recovers from ErrorStateView, and never claims Saved to Downloads',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1024, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Empty results state
        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(size: Size(1024, 900)),
              child: ReportsScreen(
                initialEvents: [],
                initialReportPayload: <Map<String, dynamic>>[],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No records found for this report.'), findsOneWidget);

        // 2. Invalid Event ID validation
        await tester.enterText(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          '0',
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('generate-report-button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Please enter or select a valid Event ID.'),
          findsOneWidget,
        );

        // 3. ErrorStateView recovery via Retry
        await tester.enterText(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          '1',
        );
        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(size: Size(1024, 900)),
              child: ReportsScreen(
                initialEvents: [],
                initialErrorMessage: 'Temporary report service timeout.',
                initialReportPayload: {'total_events': 9},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Temporary report service timeout.'),
          findsOneWidget,
        );
        final retryBtn = find.text('Retry');
        expect(retryBtn, findsOneWidget);

        await tester.ensureVisible(retryBtn);
        await tester.pumpAndSettle();
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();
        expect(find.text('TOTAL EVENTS'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);

        // 4. Verify "Saved to Downloads" never appears anywhere
        expect(find.textContaining('Saved to Downloads'), findsNothing);
      },
    );
  });
}

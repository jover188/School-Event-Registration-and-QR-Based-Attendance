import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/common/reports_screen.dart';
import '../support/app_test_host.dart';

final List<EventModel> _fixtureEvents = [
  EventModel(
    id: 1,
    title: 'Grand Annual Technology Summit 2026',
    description: 'Annual tech summit',
    venue: 'Grand Auditorium',
    eventDate: '2026-10-20',
    startTime: '08:00:00',
    endTime: '17:00:00',
    maxParticipants: 100,
    remainingSlots: 50,
    currentRegisteredCount: 50,
    lateGracePeriodMinutes: 15,
    walkInAllowed: true,
    status: 'completed',
  ),
];

const Map<String, dynamic> _fixtureValidPayload = {
  'summary': {
    'total_registered': 50,
    'total_present': 45,
    'total_late': 3,
    'total_absent': 2,
  },
  'records': [
    {
      'id': 1,
      'status': 'present',
      'check_in_time': '2026-10-20T08:05:00',
      'student': {
        'student_id_number': '20260001',
        'full_name': 'Juan Dela Cruz',
        'course': 'BS Computer Science',
      },
    },
  ],
};

void main() {
  group('Report Export Download Functional Tests', () {
    testWidgets(
      'Export buttons render with correct keys and labels',
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
                initialReportPayload: _fixtureValidPayload,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey<String>('export-csv-button')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('export-excel-button')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('export-pdf-button')), findsOneWidget);

        expect(find.text('Export CSV'), findsOneWidget);
        expect(find.text('Export XLSX'), findsOneWidget);
        expect(find.text('Export PDF'), findsOneWidget);
      },
    );

    testWidgets(
      'Empty report data prevents export and shows informative error toast',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(size: Size(1280, 900)),
              child: ReportsScreen(
                initialEvents: [],
                initialReportPayload: <Map<String, dynamic>>[],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Export CSV with empty data
        await tester.tap(find.byKey(const ValueKey<String>('export-csv-button')));
        await tester.pumpAndSettle();

        expect(
          find.text('No report data available to export. Please generate a report with valid records first.'),
          findsOneWidget,
        );

        // Tap Export XLSX with empty data
        await tester.tap(find.byKey(const ValueKey<String>('export-excel-button')));
        await tester.pumpAndSettle();

        expect(
          find.text('No report data available to export. Please generate a report with valid records first.'),
          findsWidgets,
        );

        // Tap Export PDF with empty data
        await tester.tap(find.byKey(const ValueKey<String>('export-pdf-button')));
        await tester.pumpAndSettle();

        expect(
          find.text('No report data available to export. Please generate a report with valid records first.'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Export buttons are disabled when Event ID is missing or invalid for required reports',
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
                initialReportPayload: _fixtureValidPayload,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Clear Event ID
        await tester.enterText(
          find.byKey(const ValueKey<String>('report-event-id-field')),
          '',
        );

        // Tap Export CSV
        await tester.tap(find.byKey(const ValueKey<String>('export-csv-button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter or select a valid Event ID.'),
          findsOneWidget,
        );
      },
    );
  });
}

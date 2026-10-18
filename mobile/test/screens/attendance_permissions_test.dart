import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/screens/organizer/event_registrations_screen.dart';
import 'package:school_event_attendance/screens/organizer/live_attendance_screen.dart';
import '../support/app_test_host.dart';

final List<Map<String, dynamic>> _attendanceFixtures = [
  {
    'id': 101,
    'status': 'late',
    'check_in_time': '2026-11-20T09:22:00',
    'check_out_time': null,
    'student': {
      'id': 1,
      'full_name': 'Juan M. Dela Cruz',
      'student_id_number': '20260001',
      'course': 'BS Computer Science',
    },
  },
];

final List<Map<String, dynamic>> _registrationFixtures = [
  {
    'id': 501,
    'status': 'registered',
    'waiting_list_position': null,
    'registered_at': '2026-11-10T10:00:00',
    'student': {
      'id': 1,
      'full_name': 'Juan M. Dela Cruz',
      'student_id_number': '20260001',
      'course': 'BS Computer Science',
      'year_level': '3rd Year',
      'section': 'CS-3A',
    },
  },
  {
    'id': 502,
    'status': 'waiting_list',
    'waiting_list_position': 1,
    'registered_at': '2026-11-11T14:30:00',
    'student': {
      'id': 2,
      'full_name': 'Maria Clara Santos',
      'student_id_number': '20260002',
      'course': 'BS Information Technology',
      'year_level': '2nd Year',
      'section': 'IT-2B',
    },
  },
];

void main() {
  testWidgets(
      'LiveAttendanceScreen permits corrections with mandatory reason when canCorrect is true',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(
        child: LiveAttendanceScreen(
          eventId: 10,
          eventTitle: 'Cybersecurity Summit',
          canCorrect: true,
          initialAttendances: _attendanceFixtures,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Attendance — Cybersecurity Summit'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mark-student-attendance-fab')),
      findsOneWidget,
    );
    final correctBtn = find.byKey(const ValueKey('correct-attendance-101'));
    expect(correctBtn, findsOneWidget);

    await tester.ensureVisible(correctBtn);
    await tester.pumpAndSettle();
    await tester.tap(correctBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('Correct Attendance: Juan M. Dela Cruz'),
      findsOneWidget,
    );

    // Attempt to submit without a valid reason
    await tester.tap(find.text('Save Correction'));
    await tester.pump();

    expect(
      find.text('Reason must be at least 5 characters.'),
      findsOneWidget,
    );

    // Enter a short 3-char reason and verify validation still blocks
    await tester.enterText(
      find.byKey(const ValueKey('correct-reason-field')),
      'abc',
    );
    await tester.tap(find.text('Save Correction'));
    await tester.pump();

    expect(
      find.text('Reason must be at least 5 characters.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'LiveAttendanceScreen hides manual mark and correction controls when canCorrect is false',
      (tester) async {
    await tester.pumpWidget(
      AppTestHost(
        child: LiveAttendanceScreen(
          eventId: 10,
          eventTitle: 'Cybersecurity Summit',
          canCorrect: false,
          initialAttendances: _attendanceFixtures,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Read-Only View: Attendance corrections are disabled'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mark-student-attendance-fab')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('correct-attendance-101')),
      findsNothing,
    );
    expect(find.text('Correct Attendance Status'), findsNothing);
    expect(find.text('Mark Attendance'), findsNothing);
  });

  testWidgets(
      'EventRegistrationsScreen enforces canCancel permission for organizer vs management',
      (tester) async {
    // Organizer view (canCancel: true)
    await tester.pumpWidget(
      AppTestHost(
        child: EventRegistrationsScreen(
          eventId: 10,
          eventTitle: 'Cybersecurity Summit',
          canCancel: true,
          initialRegistrations: _registrationFixtures,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Registrations — Cybersecurity Summit'), findsOneWidget);
    expect(find.text('WAITING #1'), findsOneWidget);
    final cancelBtn = find.byKey(const ValueKey('cancel-registration-501'));
    expect(cancelBtn, findsOneWidget);

    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(find.text('Cancel Student Registration?'), findsOneWidget);
    expect(
      find.textContaining('automatically promoted'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep Registration'));
    await tester.pumpAndSettle();

    // Management read-only view (canCancel: false)
    await tester.pumpWidget(
      AppTestHost(
        child: EventRegistrationsScreen(
          eventId: 10,
          eventTitle: 'Cybersecurity Summit',
          canCancel: false,
          initialRegistrations: _registrationFixtures,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Read-Only View: Registration mutations are disabled'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cancel-registration-501')), findsNothing);
    expect(find.byKey(const ValueKey('cancel-registration-502')), findsNothing);
    expect(find.text('Cancel Registration'), findsNothing);
  });
}

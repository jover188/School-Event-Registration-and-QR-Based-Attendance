import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/core/network/api_client.dart';
import 'package:school_event_attendance/screens/common/profile_screen.dart';

import '../support/app_test_host.dart';

void main() {
  final studentProfileData = {
    'user': {
      'id': 101,
      'name': 'Thea Queen',
      'email': 'thea@school.edu',
      'role': 'student',
      'status': 'active',
    },
    'student_profile': {
      'student_id_number': '2026-0001',
      'first_name': 'Thea',
      'last_name': 'Queen',
      'middle_name': 'DeMerteuil',
      'course': 'BS Computer Science',
      'year_level': '3rd Year',
      'section': 'CS-3A',
      'contact_number': '+639123456789',
      'department': 'College of Computer Studies',
    },
  };

  tearDown(() {
    ApiClient.mockHandler = null;
  });

  testWidgets(
    'student role renders institutional fields with read-only badges and presentation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: studentProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check official institutional banner & card keys
      expect(
        find.byKey(const ValueKey('institutional-notice-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('student-institutional-card')),
        findsOneWidget,
      );

      // Verify institutional badges
      expect(find.text('Institutional Record'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
      expect(find.byIcon(LucideIcons.idCard), findsOneWidget);

      // Verify academic identity fields
      expect(find.text('2026-0001'), findsOneWidget);
      expect(find.text('Thea DeMerteuil Queen'), findsOneWidget);
      expect(find.text('BS Computer Science'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      expect(find.text('CS-3A'), findsOneWidget);
      expect(find.text('College of Computer Studies'), findsOneWidget);

      // Verify account level summary badges
      expect(find.text('thea@school.edu'), findsOneWidget);
      expect(find.text('ROLE: STUDENT'), findsOneWidget);
      expect(find.text('STATUS: ACTIVE'), findsOneWidget);
    },
  );

  testWidgets(
    'student role does not render editable form fields or submit buttons',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: studentProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no text editing input widgets exist
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(EditableText), findsNothing);

      // Ensure no legacy mutation keys exist
      expect(find.byKey(const ValueKey('profile-first-name')), findsNothing);
      expect(find.byKey(const ValueKey('profile-last-name')), findsNothing);
      expect(find.byKey(const ValueKey('profile-contact')), findsNothing);
      expect(find.byKey(const ValueKey('profile-course')), findsNothing);
      expect(find.byKey(const ValueKey('profile-department')), findsNothing);

      // Ensure no mutation buttons exist
      expect(find.byKey(const ValueKey('save-profile-button')), findsNothing);
      expect(find.byKey(const ValueKey('request-correction-button')), findsNothing);
      expect(find.text('Save Profile Changes'), findsNothing);
      expect(find.text('Update Contact Number'), findsNothing);
    },
  );

  testWidgets(
    'displays institutional academic identity section header and sis synchronization notice',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: studentProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section header for institutional student information
      expect(find.text('Institutional Academic Identity'), findsOneWidget);
      expect(
        find.text(
          'Official student records synchronized with school information systems.',
        ),
        findsOneWidget,
      );

      // Check notice banner text explaining read-only SIS synchronization
      expect(
        find.textContaining(
          'Institutional records are synchronized with the School Student Information System (SIS) and are read-only.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          "For official record corrections, contact the registrar's office.",
        ),
        findsOneWidget,
      );

      // Verify notification preferences navigation link is accessible
      expect(find.text('Notification Preferences'), findsOneWidget);
    },
  );

  testWidgets(
    'non-student role displays their respective profile information without student institutional fields',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      final adminData = {
        'user': {
          'id': 1,
          'name': 'Admin User',
          'email': 'admin@school.edu',
          'role': 'administrator',
          'status': 'active',
        },
      };

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: adminData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Non-students show their identity summary
      expect(find.text('admin@school.edu'), findsOneWidget);
      expect(find.text('ROLE: ADMINISTRATOR'), findsOneWidget);
      expect(find.text('STATUS: ACTIVE'), findsOneWidget);

      // Shows staff Account Information section header
      expect(find.text('Account Information'), findsOneWidget);
      expect(
        find.text(
          'Staff credentials and access permissions are managed by system administrators.',
        ),
        findsOneWidget,
      );

      // Non-students must NOT have student institutional fields or cards
      expect(
        find.byKey(const ValueKey('student-institutional-card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('institutional-notice-banner')),
        findsNothing,
      );
      expect(find.text('Institutional Academic Identity'), findsNothing);
      expect(find.text('Institutional Record'), findsNothing);
      expect(find.text('BS Computer Science'), findsNothing);
      expect(find.text('2026-0001'), findsNothing);

      // No editable fields or mutation buttons
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Save Profile Changes'), findsNothing);
    },
  );
}

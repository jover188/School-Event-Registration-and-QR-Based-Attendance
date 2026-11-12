import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:school_event_attendance/core/constants/api_constants.dart';
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
      'student_profile': {
        'student_id': '2026-0001',
        'first_name': 'Thea',
        'last_name': 'Queen',
        'middle_name': 'DeMerteuil',
        'course': 'BS Computer Science',
        'year_level': '3rd Year',
        'section': 'CS-3A',
        'contact_number': '+639123456789',
        'department': 'College of Computer Studies',
      },
    },
  };

  tearDown(() {
    ApiClient.mockHandler = null;
  });

  testWidgets(
    'student role renders read-only fields with lock icons and single contact updater',
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

      // Check official institutional banner
      expect(
        find.textContaining('Your official student information is managed by the school'),
        findsOneWidget,
      );

      // Check read-only labels and values
      expect(find.text('Thea'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('DeMerteuil'), findsOneWidget);
      expect(find.text('2026-0001'), findsOneWidget);
      expect(find.text('thea@school.edu'), findsNWidgets(2));
      expect(find.text('BS Computer Science'), findsOneWidget);
      expect(find.text('3rd Year'), findsOneWidget);
      expect(find.text('CS-3A'), findsOneWidget);
      expect(find.text('College of Computer Studies'), findsOneWidget);

      // Verify lock icons exist for read-only fields
      expect(find.byIcon(LucideIcons.lock), findsWidgets);

      // Verify editable fields for academic info are NOT present as inputs
      expect(find.byKey(const ValueKey('profile-first-name')), findsNothing);
      expect(find.byKey(const ValueKey('profile-last-name')), findsNothing);
      expect(find.byKey(const ValueKey('profile-course')), findsNothing);
      expect(find.byKey(const ValueKey('profile-department')), findsNothing);

      // Contact number MUST be editable
      expect(find.byKey(const ValueKey('profile-contact')), findsOneWidget);

      // Button says "Update Contact Number"
      expect(find.text('Update Contact Number'), findsOneWidget);
      expect(find.text('Save Profile Changes'), findsNothing);

      // Request correction button exists
      expect(find.byKey(const ValueKey('request-correction-button')), findsOneWidget);
    },
  );

  testWidgets(
    'student saving contact number only sends contact_number payload',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      Map<String, dynamic>? capturedBody;
      String? capturedEndpoint;

      ApiClient.mockHandler = (method, endpoint, body) async {
        if (method == 'PUT' && endpoint == ApiConstants.profile) {
          capturedEndpoint = endpoint;
          capturedBody = body as Map<String, dynamic>;
          return ApiResponse(
            success: true,
            message: 'Contact number updated successfully.',
            statusCode: 200,
          );
        }
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: studentProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contactField = find.byKey(const ValueKey('profile-contact'));
      await tester.enterText(contactField, '+639998887777');
      await tester.pump();

      final updateBtn = find.byKey(const ValueKey('save-profile-button'));
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(capturedEndpoint, ApiConstants.profile);
      expect(capturedBody, {'contact_number': '+639998887777'});
    },
  );

  testWidgets(
    'request profile correction dialog allows selecting fields, entering reason, and submitting',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.reset);

      Map<String, dynamic>? correctionPayload;

      ApiClient.mockHandler = (method, endpoint, body) async {
        if (method == 'POST' && endpoint == ApiConstants.profileCorrectionRequest) {
          correctionPayload = body as Map<String, dynamic>;
          return ApiResponse(
            success: true,
            message: 'Your correction request has been submitted.',
            statusCode: 200,
          );
        }
        return ApiResponse(success: true, statusCode: 200);
      };

      await tester.pumpWidget(
        AppTestHost(
          child: ProfileScreen(
            initialData: studentProfileData,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final correctionBtn = find.byKey(const ValueKey('request-correction-button'));
      await tester.ensureVisible(correctionBtn);
      await tester.tap(correctionBtn);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Request Profile Correction')), findsOneWidget);

      // Try submitting without selecting any fields
      final submitBtn = find.byKey(const ValueKey('submit-correction-button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Select at least one field requiring correction.'), findsOneWidget);

      // Select 'Section' and 'Course/Program'
      final sectionChip = find.byKey(const ValueKey('correction-chip-Section'));
      await tester.tap(sectionChip);
      await tester.pumpAndSettle();

      final courseChip = find.byKey(const ValueKey('correction-chip-Course/Program'));
      await tester.tap(courseChip);
      await tester.pumpAndSettle();

      // Try submitting without reason
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Please provide details for the correction request'),
        findsOneWidget,
      );

      // Fill in reason
      final reasonField = find.byKey(const ValueKey('correction-reason-input'));
      await tester.enterText(
        reasonField,
        'I officially shifted to BS Information Technology section IT-3B.',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(correctionPayload, isNotNull);
      expect(correctionPayload!['fields'], containsAll(['Section', 'Course/Program']));
      expect(
        correctionPayload!['reason'],
        'I officially shifted to BS Information Technology section IT-3B.',
      );

      // Dialog should be dismissed
      expect(find.byKey(const ValueKey('submit-correction-button')), findsNothing);
    },
  );

  testWidgets(
    'non-student role displays full editable form and Save Profile Changes button',
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
          'student_profile': {
            'student_id': 'ADM-001',
            'first_name': 'Admin',
            'last_name': 'User',
            'middle_name': '',
            'course': 'Faculty',
            'year_level': '1st Year',
            'section': 'ADMIN',
            'contact_number': '+639111111111',
            'department': 'Administration',
          },
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

      // Non-students should NOT see the lock banner
      expect(
        find.textContaining('Your official student information is managed by the school'),
        findsNothing,
      );

      // Non-students have editable fields
      expect(find.byKey(const ValueKey('profile-first-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-last-name')), findsOneWidget);
      expect(find.text('Save Profile Changes'), findsOneWidget);
      expect(find.text('Update Contact Number'), findsNothing);
    },
  );
}

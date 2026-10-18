import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/screens/auth/login_screen.dart';
import 'package:school_event_attendance/screens/common/notification_preferences_screen.dart';
import 'package:school_event_attendance/screens/common/notifications_screen.dart';
import 'package:school_event_attendance/screens/common/profile_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../support/app_test_host.dart';

void main() {
  testWidgets(
    'login renders full-screen stretched layout on desktop and mobile',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const AppTestHost(child: LoginScreen()));

      expect(find.byType(SvgPicture), findsOneWidget);

      final surface = find.byKey(const ValueKey('login-surface'));
      expect(surface, findsOneWidget);
      final surfaceDecoration =
          tester.widget<Container>(surface).decoration! as BoxDecoration;
      expect(surfaceDecoration.color, const Color(0xFFF6F6F4));
      expect(tester.getSize(surface).width, 1440);
      expect(tester.getTopLeft(surface).dx, 0);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF6F6F4));

      final header = find.byKey(const ValueKey('login-header'));
      final headerBackground = find.descendant(
        of: header,
        matching: find.byType(CustomPaint),
      );
      final painter = tester.widget<CustomPaint>(headerBackground).painter!
          as AttendifyHeaderPainter;
      expect(
        painter.color,
        const Color(0xFF0A0A0A),
      );
      expect(tester.getSize(header).height, 270);
      expect(tester.getSize(find.byType(SvgPicture)), const Size(64, 64));

      expect(find.text('ID or email'), findsOneWidget);
      expect(find.text('you@school.edu.ph'), findsOneWidget);
      expect(find.text('Student ID or School Email'), findsNothing);
      expect(find.textContaining('pre-provisioned'), findsNothing);

      final emailLabel = find.text('ID or email');
      final emailPlaceholder = find.text('you@school.edu.ph');
      final passwordLabel = find.text('Password');
      final passwordPlaceholder = find.text('Enter your password');

      final identifier = find.byKey(const ValueKey('login-identifier-field'));
      final password = find.byKey(const ValueKey('login-password-field'));
      final submit = find.byKey(const ValueKey('login-submit-button'));

      // Labels align horizontally with field content padding (~18px inset)
      expect(tester.getTopLeft(emailLabel).dx, closeTo(tester.getTopLeft(emailPlaceholder).dx, 2));
      expect(tester.getTopLeft(passwordLabel).dx, closeTo(tester.getTopLeft(passwordPlaceholder).dx, 2));

      // Placeholders are vertically centered in 54px fields
      final identifierCenterY = tester.getCenter(identifier).dy;
      expect(tester.getCenter(emailPlaceholder).dy, closeTo(identifierCenterY, 1));
      final passwordCenterY = tester.getCenter(password).dy;
      expect(tester.getCenter(passwordPlaceholder).dy, closeTo(passwordCenterY, 1));
      final identifierControl = find.descendant(
        of: identifier,
        matching: find.byType(ShadInput),
      );
      final passwordControl = find.descendant(
        of: password,
        matching: find.byType(ShadInput),
      );
      final expectedLeft = tester.getTopLeft(identifier).dx;
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('login-title'))).dx,
        expectedLeft,
      );
      expect(tester.getTopLeft(password).dx, expectedLeft);
      expect(tester.getTopLeft(submit).dx, expectedLeft);
      expect(tester.getSize(identifierControl).height, 54);
      expect(tester.getSize(passwordControl).height, 54);
      expect(tester.getSize(submit).height, 58);
      expect(tester.getSize(submit).width, tester.getSize(identifier).width);
      final submitLabel = find.descendant(
        of: submit,
        matching: find.text('Login'),
      );
      expect(tester.widget<Text>(submitLabel).style?.fontSize, 16);

      await tester.enterText(identifier, '20260001');
      expect(find.text('Register Here'), findsNothing);
      expect(find.text('Forgot Password?'), findsNothing);
      expect(find.text('Forgot password?'), findsNothing);
      expect(find.byKey(const ValueKey('forgot-password-action')), findsNothing);

      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(find.byTooltip('Hide password'), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(surface).dx, 0);
      expect(tester.getTopLeft(surface).dy, 0);
      expect(tester.getSize(surface).width, 390);
      expect(tester.getSize(header).width, 390);
      expect(tester.getSize(header).height, 270);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();

      expect(find.text('20260001'), findsOneWidget);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('20260001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('login places the Attendify wordmark below the logo',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AppTestHost(child: LoginScreen()));

    final logo = find.byKey(const ValueKey('attendify-login-logo'));
    final brand = find.byKey(const ValueKey('attendify-brand-name'));
    final welcome = find.text('Welcome back! Log in to continue.');

    expect(brand, findsOneWidget);
    expect(find.text('Attendify'), findsOneWidget);
    expect(tester.getTopLeft(brand).dy,
        greaterThan(tester.getBottomLeft(logo).dy));
    expect(
      tester.getTopLeft(welcome).dy,
      greaterThan(tester.getBottomLeft(brand).dy),
    );
  });

  testWidgets('login fields stay white when the app uses dark mode',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const AppTestHost(
        themeMode: ThemeMode.dark,
        child: LoginScreen(),
      ),
    );

    for (final key in const [
      'login-identifier-field',
      'login-password-field',
    ]) {
      final input = find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ShadInput),
      );
      expect(tester.widget<ShadInput>(input).decoration?.color,
          const Color(0xFFFFFFFF));
    }
  });

  testWidgets('login fields keep a dark cursor when focused in dark mode',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const AppTestHost(
        themeMode: ThemeMode.dark,
        child: LoginScreen(),
      ),
    );

    for (final key in const [
      'login-identifier-field',
      'login-password-field',
    ]) {
      final field = find.byKey(ValueKey(key));
      await tester.tap(field);
      await tester.pump();

      final editable = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editable).cursorColor,
          const Color(0xFF0A0A0A));
      expect(tester.widget<EditableText>(editable).selectionColor,
          const Color(0x240A0A0A));
    }
  });

  testWidgets('login button stays black when hovered in dark mode',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const AppTestHost(
        themeMode: ThemeMode.dark,
        child: LoginScreen(),
      ),
    );

    final submit = find.byKey(const ValueKey('login-submit-button'));
    final decorator = find.descendant(
      of: submit,
      matching: find.byType(ShadDecorator),
    );
    expect(tester.widget<ShadDecorator>(decorator).decoration?.color,
        const Color(0xFF0A0A0A));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(submit));
    await tester.pumpAndSettle();

    expect(tester.widget<ShadDecorator>(decorator).decoration?.color,
        const Color(0xFF0A0A0A));
  });

  testWidgets(
    'profile caps width at 720 on desktop and stays scrollable at 320px and 2x text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const AppTestHost(
          child: ProfileScreen(
            initialData: {
              'user': {
                'email': 'thea@school.edu',
                'role': 'student',
                'status': 'active',
              },
              'student_profile': {
                'student_id_number': '20260001',
                'first_name': 'Thea',
                'middle_name': 'M',
                'last_name': 'Santos',
                'course': 'BS Computer Science',
                'year_level': '3rd Year',
                'section': 'CS-3A',
                'department': 'College of Computing Studies',
                'contact_number': '09171234567',
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('thea@school.edu'), findsOneWidget);
      expect(find.textContaining('20260001'), findsOneWidget);
      final saveBtn = find.text('Save Profile Changes');
      expect(tester.getSize(saveBtn).width, lessThanOrEqualTo(720));

      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpWidget(
        const AppTestHost(
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: ProfileScreen(
              initialData: {
                'user': {
                  'email': 'thea@school.edu',
                  'role': 'student',
                  'status': 'active',
                },
                'student_profile': {
                  'student_id_number': '20260001',
                  'first_name': 'Thea',
                  'last_name': 'Santos',
                  'course': 'BSCS',
                  'year_level': '3rd Year',
                  'section': '3A',
                  'department': 'CCS',
                },
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'notifications inbox and preferences preserve 30-day retention notice and locked mandatory alerts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const AppTestHost(
          child: NotificationsScreen(
            initialNotifications: [
              {
                'id': 1,
                'title': 'Attendance Recorded',
                'message': 'Checked in to Cybersecurity Colloquium.',
                'type': 'attendance_recorded',
                'is_read': false,
                'created_at': '2026-10-17T09:00:00Z',
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('retained for 30 days'), findsOneWidget);
      expect(find.text('Attendance Recorded'), findsOneWidget);
      expect(find.text('Mark All Read'), findsOneWidget);

      await tester.pumpWidget(
        const AppTestHost(
          child: NotificationPreferencesScreen(
            initialPreferences: {
              'new_event_published': true,
              'registration_confirmed': true,
              'event_reminders': false,
              'event_updates': true,
              'waiting_list_promoted': true,
              'admin_announcements': true,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mandatory Critical Alerts'), findsOneWidget);
      expect(find.text('Event Cancellations'), findsOneWidget);
      expect(find.text('Attendance Confirmation'), findsOneWidget);
      expect(find.text('LOCKED'), findsNWidgets(2));

      final switches = tester
          .widgetList<SwitchListTile>(
            find.byType(SwitchListTile),
          )
          .toList();
      // First two switches are mandatory critical alerts and must have null onChanged
      expect(switches[0].value, isTrue);
      expect(switches[0].onChanged, isNull);
      expect(switches[1].value, isTrue);
      expect(switches[1].onChanged, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

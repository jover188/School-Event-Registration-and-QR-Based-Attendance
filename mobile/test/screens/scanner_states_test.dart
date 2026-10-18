import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:school_event_attendance/models/event_model.dart';
import 'package:school_event_attendance/screens/organizer/qr_scanner_screen.dart';
import '../support/app_test_host.dart';

EventModel scannerEvent(String status) => EventModel(
      id: 4,
      title: 'Research showcase',
      description: 'Campus showcase',
      venue: 'Main hall',
      eventDate: '2026-12-01',
      startTime: '09:00:00',
      endTime: '12:00:00',
      currentRegisteredCount: 20,
      lateGracePeriodMinutes: 15,
      walkInAllowed: true,
      status: status,
    );

void main() {
  testWidgets('Linux provides attendance access without opening a camera',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await tester.pumpWidget(AppTestHost(
      child: QrScannerScreen(event: scannerEvent('published')),
    ));

    expect(find.byType(MobileScanner), findsNothing);
    expect(find.text('View attendance'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'non-published event blocks scanner camera and offers attendance view',
      (tester) async {
    await tester.pumpWidget(AppTestHost(
      child: QrScannerScreen(event: scannerEvent('draft')),
    ));

    expect(find.byType(MobileScanner), findsNothing);
    expect(
      find.textContaining(
        'QR attendance scanning is only available when an event is published or ongoing',
      ),
      findsOneWidget,
    );
    expect(find.text('View attendance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'scan check-in and check-out results render long student names at 320x568 and 844x390 at 2x text without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final checkOutResult = <String, dynamic>{
      'status': 'present',
      'mode': 'check_out',
      'check_in_time': '2026-12-01T08:55:10',
      'check_out_time': '2026-12-01T12:03:45',
      'student': <String, dynamic>{
        'full_name':
            'Maria Christina Gabriella Dela Cruz-Villanueva III',
        'student_id_number': '20260991',
        'course': 'BS Computer Engineering',
        'year_level': '4th Year',
        'section': 'CPE-4A',
      },
    };

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2.0),
        ),
        child: AppTestHost(
          child: QrScannerScreen(
            event: scannerEvent('ongoing'),
            initialMode: 'check_out',
            initialScanResult: checkOutResult,
            cameraSupportedOverride: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Maria Christina Gabriella Dela Cruz-Villanueva III'),
      findsOneWidget,
    );
    expect(find.textContaining('20260991'), findsOneWidget);
    expect(find.textContaining('Check-Out Time:'), findsOneWidget);
    expect(find.text('Scan Next QR Code'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Resize to short landscape 844x390 at 2x text scale
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(844, 390),
          textScaler: TextScaler.linear(2.0),
        ),
        child: AppTestHost(
          child: QrScannerScreen(
            event: scannerEvent('ongoing'),
            initialMode: 'check_out',
            initialScanResult: checkOutResult,
            cameraSupportedOverride: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Maria Christina Gabriella Dela Cruz-Villanueva III'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rejected scan error and processing lock states preserve mode across resize',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppTestHost(
        child: QrScannerScreen(
          event: scannerEvent('published'),
          initialScanError:
              'Student is not registered and walk-in attendance is disabled for this event.',
          cameraSupportedOverride: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Scan Rejected'), findsOneWidget);
    expect(find.text('NOT RECORDED'), findsOneWidget);
    expect(
      find.textContaining('walk-in attendance is disabled'),
      findsOneWidget,
    );

    // Dismiss error and switch mode to Check-Out
    await tester.tap(find.byKey(const ValueKey('scan-error-retry-button')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('scanner-mode-check-out')));
    await tester.pump();

    expect(find.text('Ready for Check-Out Scan'), findsOneWidget);

    // Test processing lock prevents mode change
    await tester.pumpWidget(
      AppTestHost(
        child: QrScannerScreen(
          event: scannerEvent('published'),
          initialMode: 'check_in',
          initialIsProcessing: true,
          cameraSupportedOverride: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Recording attendance…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

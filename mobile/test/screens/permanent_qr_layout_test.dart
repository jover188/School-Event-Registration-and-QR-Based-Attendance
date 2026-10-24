import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:school_event_attendance/screens/student/permanent_qr_screen.dart';
import '../support/app_test_host.dart';

const String _kSample64HexToken =
    'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

void main() {
  group('PermanentQrScreen responsive layout and reissue flow', () {
    testWidgets(
      'renders active 64-hex token within 180..280 bounds at 320x568 (2x text) and 1024x768 without FittedBox or overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 320x568 with 2x text scale
        tester.view.physicalSize = const Size(320, 568);
        await tester.pumpWidget(
          const AppTestHost(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
              ),
              child: PermanentQrScreen(
                initialQrData: {
                  'qr_token': _kSample64HexToken,
                  'full_name': 'Juan M. Dela Cruz',
                  'student_id_number': '20260001',
                  'status': 'active',
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(QrImageView),
            matching: find.byType(FittedBox),
          ),
          findsNothing,
        );

        final qrFinder = find.byType(QrImageView);
        expect(qrFinder, findsOneWidget);
        expect(
          find.byKey(const ValueKey('student-qr-wallet-header')),
          findsOneWidget,
        );

        final qrSize320 = tester.getSize(qrFinder);
        expect(qrSize320.width, greaterThanOrEqualTo(180));
        expect(qrSize320.width, lessThanOrEqualTo(280));
        expect(qrSize320.height, equals(qrSize320.width));

        // 1024x768 expanded viewport
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpWidget(
          const AppTestHost(
            child: PermanentQrScreen(
              initialQrData: {
                'qr_token': _kSample64HexToken,
                'full_name': 'Juan M. Dela Cruz',
                'student_id_number': '20260001',
                'status': 'active',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final qrSize1024 = tester.getSize(qrFinder);
        expect(qrSize1024.width, greaterThanOrEqualTo(180));
        expect(qrSize1024.width, lessThanOrEqualTo(280));
        expect(qrSize1024.height, equals(qrSize1024.width));

        // Scroll to and tap Reissue button -> verify revocation confirmation dialog
        final reissueButton = find.byKey(const ValueKey('reissue-qr-button'));
        await tester.ensureVisible(reissueButton);
        await tester.pumpAndSettle();
        await tester.tap(reissueButton);
        await tester.pumpAndSettle();

        expect(find.text('Reissue Permanent QR Code?'), findsOneWidget);
        expect(
          find.textContaining('immediately and permanently revoke'),
          findsOneWidget,
        );
        expect(find.text('Reissue Now'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Reissue Permanent QR Code?'), findsNothing);
      },
    );
  });
}

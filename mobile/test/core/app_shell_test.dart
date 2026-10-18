import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_event_attendance/core/navigation/app_destination.dart';
import 'package:school_event_attendance/core/widgets/app_shell.dart';
import '../support/app_test_host.dart';

void main() {
  testWidgets('navigation changes width without replacing body state', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(const AppTestHost(child: _ShellFixture()));
    await tester.enterText(find.byType(TextField), 'Retain my search');
    for (final width in [599.0, 600.0, 1023.0, 1024.0, 1440.0, 320.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpAndSettle();
      expect(find.text('Retain my search'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
    await tester.tap(find.byKey(const ValueKey('destination-qr')));
    await tester.pumpAndSettle();
    expect(find.text('My QR selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('destination-events')));
    await tester.pumpAndSettle();
    expect(find.text('Retain my search'), findsOneWidget);
  });

  testWidgets('compact More sheet keeps secondary and large-text destinations reachable', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const AppTestHost(
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: _ShellFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('destination-more')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('destination-more')));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('History selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile off-canvas slide-over drawer opens from header trigger and navigates', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppTestHost(child: _ShellFixture()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-drawer-trigger')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mobile-drawer-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('drawer-destination-history')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drawer-destination-history')));
    await tester.pumpAndSettle();

    expect(find.text('History selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ShellFixture extends StatefulWidget {
  const _ShellFixture();
  @override
  State<_ShellFixture> createState() => _ShellFixtureState();
}

class _ShellFixtureState extends State<_ShellFixture> {
  String selected = 'events';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
    title: switch (selected) {
      'qr' => 'My QR selected',
      'history' => 'History selected',
      _ => 'Campus Events',
    },
    destinations: const [
      AppDestination(
        id: 'events',
        label: 'Events',
        icon: Icons.event,
        essential: true,
      ),
      AppDestination(
        id: 'qr',
        label: 'My QR',
        icon: Icons.qr_code,
        essential: true,
      ),
      AppDestination(
        id: 'history',
        label: 'History',
        icon: Icons.history,
      ),
    ],
    selectedId: selected,
    onDestinationSelected: (id) => setState(() => selected = id),
    body: AppDestinationStack(
      selectedId: selected,
      builders: {
        'events': (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(controller: _searchController),
        ),
        'qr': (_) => const Center(child: Text('QR Body')),
        'history': (_) => const Center(child: Text('History Body')),
      },
    ),
  );
}


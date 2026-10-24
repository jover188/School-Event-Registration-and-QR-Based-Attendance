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

  testWidgets('compact More sheet keeps secondary and large-text destinations reachable when enabled', (tester) async {
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

  testWidgets('highlighted navigation button adapts between light and dark modes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Light mode: selected sidebar item uses dark primary surface (#18181B)
    await tester.pumpWidget(
      const AppTestHost(
        themeMode: ThemeMode.light,
        child: _ShellFixture(),
      ),
    );
    await tester.pumpAndSettle();

    final lightContainer = tester.widget<Container>(
      find.byKey(const ValueKey('destination-events-surface')),
    );
    final lightDecoration = lightContainer.decoration! as BoxDecoration;
    expect(lightDecoration.color, const Color(0xFF18181B));

    // Dark mode: selected sidebar item adapts to light primary surface (#FFFFFF)
    await tester.pumpWidget(
      const AppTestHost(
        themeMode: ThemeMode.dark,
        child: _ShellFixture(),
      ),
    );
    await tester.pumpAndSettle();

    final darkContainer = tester.widget<Container>(
      find.byKey(const ValueKey('destination-events-surface')),
    );
    final darkDecoration = darkContainer.decoration! as BoxDecoration;
    expect(darkDecoration.color, const Color(0xFFFFFFFF));
  });

  testWidgets('mobile off-canvas slide-over drawer opens from header trigger and navigates', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppTestHost(child: _ShellFixture()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-drawer-trigger')), findsOneWidget);
    final mobileLogoFinder = find.byKey(const ValueKey('mobile-drawer-logo'));
    expect(mobileLogoFinder, findsOneWidget);
    final mobileLogo = tester.widget<Image>(mobileLogoFinder);
    expect((mobileLogo.image as AssetImage).assetName, 'assets/images/logo_mark.png');
    expect(mobileLogo.width, 24);
    expect(mobileLogo.height, 24);
    expect(mobileLogo.fit, BoxFit.contain);
    final titleCenter = tester.getCenter(find.text('Campus Events'));
    final triggerCenter = tester.getCenter(find.byKey(const ValueKey('mobile-drawer-trigger')));
    expect(triggerCenter.dy, closeTo(titleCenter.dy, 2.0));

    await tester.tap(find.byKey(const ValueKey('mobile-drawer-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('drawer-destination-history')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drawer-destination-history')));
    await tester.pumpAndSettle();

    expect(find.text('History selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders logout button at the bottom of sidebar and mobile drawer', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var logoutCount = 0;
    await tester.pumpWidget(
      AppTestHost(
        child: _ShellFixture(
          onLogout: () => logoutCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final historyFinder = find.byKey(const ValueKey('destination-history'));
    final logoutFinder = find.byKey(const ValueKey('destination-logout'));
    expect(logoutFinder, findsOneWidget);
    expect(
      tester.getTopLeft(logoutFinder).dy,
      greaterThan(tester.getBottomLeft(historyFinder).dy),
    );

    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();
    expect(logoutCount, 1);

    // Compact mobile drawer also renders logout at the bottom
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mobile-drawer-trigger')));
    await tester.pumpAndSettle();

    final drawerLogoutFinder = find.byKey(
      const ValueKey('drawer-destination-logout'),
    );
    final drawerHistoryFinder = find.byKey(
      const ValueKey('drawer-destination-history'),
    );
    expect(drawerLogoutFinder, findsOneWidget);
    expect(
      tester.getTopLeft(drawerLogoutFinder).dy,
      greaterThan(tester.getBottomLeft(drawerHistoryFinder).dy),
    );

    await tester.tap(drawerLogoutFinder);
    await tester.pumpAndSettle();
    expect(logoutCount, 2);
  });

  testWidgets('sidebar logo uses logo_mark.png with preserved aspect ratio and 48px nav item height, and 5px button radius', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AppTestHost(child: _ShellFixture()));
    await tester.pumpAndSettle();

    final logoFinder = find.byKey(const ValueKey('sidebar-brand-logo'));
    expect(logoFinder, findsOneWidget);
    final logoImage = tester.widget<Image>(logoFinder);
    expect((logoImage.image as AssetImage).assetName, 'assets/images/logo_mark.png');
    expect(logoImage.width, isNull);
    expect(logoImage.height, 48);
    expect(logoImage.fit, BoxFit.contain);

    final navSurface = tester.widget<Container>(
      find.byKey(const ValueKey('destination-events-surface')),
    );
    final navDecoration = navSurface.decoration! as BoxDecoration;
    expect(navDecoration.borderRadius, BorderRadius.circular(15));
  });
}

class _ShellFixture extends StatefulWidget {
  const _ShellFixture({this.onLogout});
  final VoidCallback? onLogout;
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
    onLogout: widget.onLogout,
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


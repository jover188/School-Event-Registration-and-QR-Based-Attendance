# Navigation

Official: [Navigation and routing](https://docs.flutter.dev/ui/navigation), [go_router](https://pub.dev/packages/go_router) (Flutter Favorite, 17.x).

## Which API

| Situation | Use |
| --- | --- |
| New app, deep links, web URLs, tabs with state | `go_router` + `MaterialApp.router` / `CupertinoApp.router` |
| Existing app already on `Navigator.push` | Stay on `Navigator` + `MaterialPageRoute` / `CupertinoPageRoute` |
| One-off dialog or sheet | Pageless: `showAdaptiveDialog`, `showModalBottomSheet` |
| `MaterialApp.routes` / `pushNamed` | Do not add. Official docs recommend against named routes |

Do not introduce auto_route, GetX routing, or a second `GoRouter` if one already exists.

## go_router

```dart
final GoRouter router = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'item/:id',
                  builder: (context, state) =>
                      ItemScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

MaterialApp.router(routerConfig: router);
```

- `context.go('/path')` — declare the location (replaces the stack).
- `context.push('/path')` — push on the current stack.
- `context.pop()` — pop. Check `context.canPop()` before a custom back button.
- Path params: `state.pathParameters['id']`. Query: `state.uri.queryParameters`.
- Extra objects via `extra` are not deep-linkable. Prefer path/query for anything shareable.
- Auth gates belong in `GoRouter.redirect`, not in random `initState` pushes.
- `PopScope` does not block page-backed `go_router` routes. Use the package redirect / `onExit` APIs.

## Tab shell

```dart
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 840;
    if (wide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const <Widget>[
          NavigationDestination(
            key: ValueKey<String>('nav-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey<String>('nav-settings'),
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
```

iOS-first chrome: `CupertinoTabScaffold` + `CupertinoTabBar`, or a `CupertinoTabBar` in the shell instead of `NavigationBar`. Do not put both on screen.

## Transitions

Flutter already picks the platform transition from `MaterialPageRoute` / `CupertinoPageRoute` / go_router's default pages.

- Android: zoom (`ZoomPageTransitionsBuilder`).
- iOS push: end-to-start + parallax. iOS present: `fullscreenDialog: true` (bottom-up).
- Edge-swipe back is automatic on iOS. Predictive back on Android needs `PopScope`, not `WillPopScope`.

Custom transitions only when the design asks. Prefer `CustomTransitionPage` on that `GoRoute`, not a global hack.

## Sheets and dialogs

```dart
await showAdaptiveDialog<void>(
  context: context,
  builder: (context) => AlertDialog.adaptive(
    title: const Text('Discard draft?'),
    actions: <Widget>[
      TextButton(
        key: const ValueKey<String>('dialog-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        key: const ValueKey<String>('dialog-discard'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Discard'),
      ),
    ],
  ),
);

await showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, controller) {
        return ListView(controller: controller, children: const <Widget>[]);
      },
    );
  },
);
```

iOS action lists: `showCupertinoModalPopup` + `CupertinoActionSheet`. Do not restyle a Material sheet to fake that.

Deep-linkable sheet: a `GoRoute` with a modal page builder. Otherwise keep it pageless so a deep link does not leave a stranded sheet.

## Navigator-only (legacy trees)

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (context) => const DetailsScreen()),
);
Navigator.of(context).push(
  CupertinoPageRoute<void>(
    fullscreenDialog: true,
    builder: (context) => const ComposeScreen(),
  ),
);
```

Pass arguments through the widget constructor, not `ModalRoute.of(context)!.settings.arguments` unless the existing code already does.

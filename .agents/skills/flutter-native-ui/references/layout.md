# Layout

Official: [SafeArea & MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery), [Adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices), [Large screens](https://docs.flutter.dev/ui/adaptive-responsive/large-screens).

## Safe area

- Wrap the **body** of a `Scaffold`, not the `Scaffold` itself. `AppBar` / `CupertinoNavigationBar` paint into the status bar on purpose.
- `SafeArea` consumes insets for descendants. Nested `SafeArea`s will not double-pad.
- Edge-to-edge is the Android default. Bottom nav, FABs, and home-indicator overlap are `SafeArea` / `NavigationBar` problems, not `padding: 16` problems.
- Keyboard: `MediaQuery.viewInsetsOf(context).bottom` or `Scaffold(resizeToAvoidBottomInset: true)` (the default). Do not pad a scroll view with a hardcoded 300.

## MediaQuery targeted getters

```dart
final Size size = MediaQuery.sizeOf(context);
final EdgeInsets padding = MediaQuery.paddingOf(context);
final EdgeInsets insets = MediaQuery.viewInsetsOf(context);
final TextScaler scaler = MediaQuery.textScalerOf(context);
```

`MediaQuery.of(context)` rebuilds when *any* MediaQuery field changes. Use it only when you need the whole `MediaQueryData`.

## Spacing

```dart
Column(
  spacing: 12,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[...],
)

Wrap(spacing: 8, runSpacing: 8, children: <Widget>[...])
```

Prefer padding on the parent (`Padding`, `contentPadding`, sliver padding) over margin-like `SizedBox` stacks. Page gutters: 16 on compact, 24 on medium+.

## Breakpoints

Decide from **window width**, never from phone/tablet/orientation.

| Width | Class | Chrome |
| --- | --- | --- |
| `< 600` | compact | `NavigationBar` |
| `600–839` | medium | `NavigationRail` or nav bar |
| `≥ 840` | expanded | `NavigationRail` or `NavigationDrawer` + optional list/detail |

```dart
final double width = MediaQuery.sizeOf(context).width;
if (width >= 840) {
  return ListDetailView(...);
}
```

Do not lock orientation. Do not use `OrientationBuilder` at the root. Foldables and split-screen make “landscape == tablet” false.

Unconstrained width on large screens: cap forms and reading columns (`Align` + `ConstrainedBox(maxWidth: 640)`). Do not stretch a single `TextField` across 1600px.

## Lists and slivers

```dart
CustomScrollView(
  slivers: <Widget>[
    const SliverAppBar.large(title: Text('Inbox')),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => InboxTile(item: items[index]),
      ),
    ),
  ],
)
```

- Material large/medium titles: `SliverAppBar.large` / `SliverAppBar.medium`.
- iOS large titles: `CustomScrollView` + `CupertinoSliverNavigationBar`.
- Pull to refresh: `RefreshIndicator.adaptive` around the scroll view, or `CupertinoSliverRefreshControl` in a sliver list.
- Preserve scroll position across size changes with `PageStorageKey<String>('inbox-list')`.
- Always `.builder` / sliver builder for long or unbounded data.

## Flex mistakes

- `Expanded` / `Flexible` only inside a `Flex` with a bounded main axis. Not inside a vertical `ListView` unless the list is bounded.
- `mainAxisSize: MainAxisSize.min` inside scroll views.
- Intrinsic widgets (`IntrinsicHeight`, `IntrinsicWidth`) are last-resort measurement, not layout strategy.

## Input and density

Touch first (44×44 minimum). Visual density can tighten on pointer devices via `ThemeData.visualDensity` / `VisualDensity.adaptivePlatformDensity`. Add shortcuts and context menus on top; do not replace the touch target.

## System UI

`AppBar` / `NavigationBar` already set overlay styles from the theme. If you draw under the status bar yourself:

```dart
AnnotatedRegion<SystemUiOverlayStyle>(
  value: SystemUiOverlayStyle.dark,
  child: child,
)
```

Do not call `SystemChrome.setSystemUIOverlayStyle` from random widgets; it races.

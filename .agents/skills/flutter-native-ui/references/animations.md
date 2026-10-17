# Animations

Official: [Animations](https://docs.flutter.dev/ui/animations), [Hero](https://docs.flutter.dev/ui/animations/hero-animations), [M3 motion](https://m3.material.io/styles/motion/overview).

Decision tree: implicit widget → `TweenAnimationBuilder` → built-in explicit (`FadeTransition`, …) → `AnimationController` + `AnimatedBuilder`. Do not pull in `flutter_animate` or Reanimated-style packages to fade a list tile.

## Implicit (default)

| Widget | When |
| --- | --- |
| `AnimatedSwitcher` | One child replaced by another (loading → content, tab body) |
| `AnimatedOpacity` / `AnimatedScale` / `AnimatedSlide` | Visibility and affordance |
| `AnimatedPadding` / `AnimatedAlign` / `AnimatedContainer` | Layout that the framework can lerp |
| `AnimatedCrossFade` | Two known children (use `crossFadeState`) |
| `AnimatedSize` | Child size changed |

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  switchInCurve: Easing.standardDecelerate,
  switchOutCurve: Easing.standardAccelerate,
  child: loading
      ? const CircularProgressIndicator.adaptive(key: ValueKey<String>('loading'))
      : Content(key: const ValueKey<String>('content'), data: data),
)
```

Keys on `AnimatedSwitcher` children are required or the animation will not run.

Durations: 50–200 short, 200–300 medium, ≤500 long. Prefer springs (`Curves.easeOutCubic`, `Easing.emphasizedDecelerate`) over linear. Animate `transform` / opacity, not `width`/`height`, when both are possible.

## Lists

```dart
AnimatedList(
  key: listKey,
  initialItemCount: items.length,
  itemBuilder: (context, index, animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: InboxTile(item: items[index]),
    );
  },
)
```

For sliver lists, `SliverAnimatedList`. Do not rebuild a `ListView` and hope items fade.

## Shared element

```dart
Hero(
  tag: 'photo-${item.id}',
  child: Image.network(item.thumbUrl),
)
```

Tags must be unique on screen. Same tag on source and destination. Do not wrap an entire scaffold in a `Hero`.

## Explicit

```dart
class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

Always `vsync`, always `dispose`. Use `AnimationController.unbounded` + `SpringSimulation` for flings. Stagger with `Interval` on a `CurvedAnimation`.

Route transitions: see `references/navigation.md`. Do not wrap every push in `PageRouteBuilder`.

## Scroll-driven

`SliverAppBar` already collapses. For custom fade-on-scroll, listen to the `ScrollController` and drive an implicit widget, or use `NotificationListener<ScrollNotification>`. Do not run an `AnimationController` at 60 Hz from `setState` on every pixel unless you measured a need.

## Reduced motion

```dart
final bool reduce = MediaQuery.disableAnimationsOf(context);
final Duration duration = reduce ? Duration.zero : const Duration(milliseconds: 200);
```

Honor it. Decorative loops (pulses, shimmer) should become static.

## Impeller

Impeller is the default renderer on iOS, Android, and (as of 3.47) macOS, Windows, and Linux. First-frame shader jank is no longer a reason to skip transitions. Do not disable Impeller to “fix” an animation.

# House Pressable

Material ink is the tell. Replace it once, use it everywhere.

## Theme

```dart
ThemeData(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
  hoverColor: Colors.transparent,
)
```

## Widget

```dart
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.semanticLabel,
    this.pressScale = 0.975,
    this.pressSink = 0,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final String? semanticLabel;
  final double pressScale;
  final double pressSink;
  final BorderRadius? borderRadius;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onPressed != null;
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    final Duration duration =
        reduce ? Duration.zero : const Duration(milliseconds: 90);
    final bool pressed = _pressed && interactive;

    Widget child = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      transformAlignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(0, pressed ? widget.pressSink : 0, 0, 1)
        ..scaleByDouble(
          pressed ? widget.pressScale : 1,
          pressed ? widget.pressScale : 1,
          1,
          1,
        ),
      child: widget.child,
    );

    if (widget.semanticLabel != null) {
      child = Semantics(
        button: true,
        enabled: interactive,
        label: widget.semanticLabel,
        child: child,
      );
    }

    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: (_) {},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: interactive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: interactive ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: child,
      ),
    );
  }
}
```

If the project already has a pressable, **do not add this file**. Extend that widget.

## Rules

- Hit target ≥ 48×48 unless the system specifies another minimum. Pad the pressable, not the icon.
- Honor `MediaQuery.disableAnimationsOf` (duration zero).
- Disabled: ignore input and drop opacity to the system’s disabled token (do not invent 38% vs 42%).
- Focus-visible: the system’s focus ring (width, offset, color), not Material’s default overlay.
- Do not stack `InkWell` + this pressable. One interaction surface.
- Icon-only: pass `semanticLabel`.
- Prefer scale 0.97–0.99 and a 1–2 px sink. Large squash looks like a toy.

## Tests

```dart
await tester.tap(find.byKey(const ValueKey<String>('submit-order')));
```

Keys go on the pressable (or the public branded button that wraps it), never on a nested `Text`.

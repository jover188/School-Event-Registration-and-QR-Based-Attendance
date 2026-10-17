# Visual effects

Official: [BackdropFilter](https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html), [ImageFiltered](https://api.flutter.dev/flutter/widgets/ImageFiltered-class.html), [Material elevation](https://m3.material.io/styles/elevation/overview).

## Elevation (prefer this over handmade shadows)

M3 elevation is tint + shadow from the theme. Use the widget that already has it:

- `Card.filled` / `Card.outlined` / default `Card`
- `Material(elevation: 1, shadowColor: colors.shadow, surfaceTintColor: colors.surfaceTint)`
- `AppBar` scrolled-under tint (`scrolledUnderElevation`)

Do not copy CSS `boxShadow` strings onto `BoxDecoration` to fake a card. If you need a custom shadow, `BoxShadow` with `colors.shadow` and a small blur, not a stack of four grey layers.

## Gradients

```dart
DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        colors.surface,
        colors.surfaceContainer,
      ],
    ),
  ),
)
```

`SweepGradient` / `RadialGradient` for conical and spotlight fills. `ShaderMask` to fade a child (list-edge fade). Keep stops on `ColorScheme` colors so dark mode works.

## Blur

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: DecoratedBox(
      decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.7)),
      child: child,
    ),
  ),
)
```

- Clip first (`ClipRRect` / `ClipOval`). Unclipped blur is a full-screen tax.
- Do not nest blurs.
- `ImageFiltered` blurs the child itself; `BackdropFilter` blurs what is *behind*.
- There is no first-party Flutter “liquid glass” widget. Do not add Expo `expo-glass-effect` or a random pub glass package to imitate iOS 26. Use `BackdropFilter` + a translucent `surface` / `CupertinoPopupSurface`.

`withValues(alpha: …)` is the current Color API. Do not use deprecated `withOpacity`.

## Shape

- Material 3 corners come from `ShapeDefaults` / component themes. Do not invent a new radius on every widget.
- Capsules: `StadiumBorder` / `BorderRadius.circular(999)`.
- iOS continuous corners are not a Flutter primitive. `BorderRadius.circular` is the default; do not depend on a third-party squircle unless the project already has one.

## Scrims and overlays

Modal barriers are handled by `showDialog` / `showModalBottomSheet`. Custom overlays: `colors.scrim.withValues(alpha: 0.32)` — not `Colors.black54`.

# Theming

Official: [Themes cookbook](https://docs.flutter.dev/cookbook/design/themes), [Material 3 for Flutter](https://docs.flutter.dev/ui/design/material), [ColorScheme](https://api.flutter.dev/flutter/material/ColorScheme-class.html), [CupertinoThemeData](https://api.flutter.dev/flutter/cupertino/CupertinoThemeData-class.html).

## App theme

```dart
final Color seed = const Color(0xFF6750A4);

MaterialApp.router(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
  routerConfig: router,
);
```

- One seed. Let `ColorScheme.fromSeed` build the roles. Do not hand-author 20 hex values unless you are implementing a signed-off token sheet.
- `theme` + `darkTheme` + `themeMode`. Do not branch `ThemeData(...)` on `platformBrightness` inside `build`.
- Follow user preference by default (`ThemeMode.system`). Persist an override with the project's existing settings store.
- Never `ThemeData(primarySwatch: ...)`, `accentColor`, or `useMaterial3: false`.

## Read tokens in widgets

```dart
final ColorScheme colors = ColorScheme.of(context);
final TextTheme text = TextTheme.of(context);

Text('Title', style: text.titleLarge?.copyWith(color: colors.onSurface));
FilledButton(onPressed: onSave, child: const Text('Save')); // uses theme
```

Override a subtree with `Theme(data: Theme.of(context).copyWith(...), child: ...)`. Do not construct a fresh `ThemeData` that throws away the app scheme.

Custom tokens the scheme lacks: a `ThemeExtension<T>` on `ThemeData.extensions`. One extension type, not a random `AppColors` imported beside `ColorScheme`.

## Type

Use M3 roles, not ad-hoc sizes:

| Role | For |
| --- | --- |
| `displayLarge`–`displaySmall` | Hero numerals, empty-state headlines |
| `headlineLarge`–`headlineSmall` | Screen-level headlines (rare under an `AppBar`) |
| `titleLarge`–`titleSmall` | App bar, list headers, cards |
| `bodyLarge`–`bodySmall` | Body copy, supporting text |
| `labelLarge`–`labelSmall` | Buttons, chips, badges, nav |

Material picks Roboto on Android and San Francisco on iOS. Cupertino uses SF. Do not add `google_fonts` unless the brand requires a custom face, and then set it on `textTheme` once.

Respect `MediaQuery.textScalerOf(context)`. Do not clamp text scale to `1.0`.

## Cupertino theme

```dart
CupertinoApp(
  theme: const CupertinoThemeData(
    primaryColor: CupertinoColors.activeBlue,
    brightness: null, // follow system
  ),
)
```

Resolve dynamic colors:

```dart
final Color label = CupertinoDynamicColor.resolve(
  CupertinoColors.label,
  context,
);
```

If a Material app needs iOS-looking nav chrome without switching to `CupertinoApp`, restyle `AppBar` (transparent `surfaceTintColor`, 44px toolbar, SF-like title). Only do this when the rest of the surface is also being adapted. See [platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations).

## Component themes

Set component themes on `ThemeData` (`filledButtonTheme`, `navigationBarTheme`, `inputDecorationTheme`, `appBarTheme`, …) instead of wrapping every widget. That is how M3 tokens stay consistent.

```dart
ThemeData(
  colorScheme: scheme,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
)
```

## High contrast and inversion

Flutter 3.47 forwards Android high-contrast and color inversion into `MediaQueryData.highContrast` and `MediaQueryData.invertColors`. Read those with `MediaQuery.highContrastOf` / `invertColorsOf`. Do not invent a parallel accessibility flag.

## Widget previews

```dart
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Primary button', brightness: Brightness.light)
@Preview(name: 'Primary button dark', brightness: Brightness.dark)
Widget primaryButtonPreview() => const FilledButton(
      onPressed: null,
      child: Text('Save'),
    );
```

Use `PreviewThemeData` when the preview must match the app seed, not `ThemeData.light()`.

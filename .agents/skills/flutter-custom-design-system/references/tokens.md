# Tokens and ThemeExtension

Official: [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html), [ThemeData.extensions](https://api.flutter.dev/flutter/material/ThemeData/extensions.html).

## Shape

One immutable extension. One factory for the shipped theme(s). One accessor.

```dart
@immutable
class AppSemantics extends ThemeExtension<AppSemantics> {
  const AppSemantics({
    required this.surfaceCanvas,
    required this.textBody,
    required this.actionPrimaryBg,
    required this.actionPrimaryFg,
  });

  final Color surfaceCanvas;
  final Color textBody;
  final Color actionPrimaryBg;
  final Color actionPrimaryFg;

  static AppSemantics of(BuildContext context) {
    final AppSemantics? ext = Theme.of(context).extension<AppSemantics>();
    assert(ext != null, 'AppSemantics missing from ThemeData.extensions');
    return ext!;
  }

  @override
  AppSemantics copyWith({
    Color? surfaceCanvas,
    Color? textBody,
    Color? actionPrimaryBg,
    Color? actionPrimaryFg,
  }) {
    return AppSemantics(
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      textBody: textBody ?? this.textBody,
      actionPrimaryBg: actionPrimaryBg ?? this.actionPrimaryBg,
      actionPrimaryFg: actionPrimaryFg ?? this.actionPrimaryFg,
    );
  }

  @override
  AppSemantics lerp(ThemeExtension<AppSemantics>? other, double t) {
    if (other is! AppSemantics) return this;
    return AppSemantics(
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      actionPrimaryBg: Color.lerp(actionPrimaryBg, other.actionPrimaryBg, t)!,
      actionPrimaryFg: Color.lerp(actionPrimaryFg, other.actionPrimaryFg, t)!,
    );
  }
}

extension AppSemanticsX on BuildContext {
  AppSemantics get tokens => AppSemantics.of(this);
}
```

Mount once at the app root:

```dart
ThemeData(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
  extensions: const <ThemeExtension<dynamic>>[AppSemantics.light],
)
```

Widgets:

```dart
Text('Hello', style: TextStyle(color: context.tokens.textBody));
```

Do not also keep a top-level `AppColors.canvas` that widgets import. The extension is the lookup.

## 1:1 discipline

- Token identifiers match the system file (`surface/canvas` → `surfaceCanvas`).
- Values copy the system file. No rounding, no “close enough” Material role mapping.
- Changing a value is a token-file change, then a visual check of every surface that reads it.
- Generating from CSS/JSON is fine (`build_runner`, a small script). Hand-editing generated output is not.

## Type, space, motion

Put non-color tokens on the same extension or on sibling extensions (`AppSpacing`, `AppMotion`) mounted next to it. Same accessor story. Do not hide spacing in a random `AppDimens` that product widgets import while colors go through `Theme`.

If the system maps onto `TextTheme`, assign those styles on `ThemeData.textTheme` **from the tokens** so `DefaultTextStyle` is correct. Still prefer the extension when the system’s role names do not match M3 (`textKicker`, `gold500`).

## Previews

Wrap `@Preview` widgets in the same `Theme` + extension the app uses. `ThemeData.light()` will lie.

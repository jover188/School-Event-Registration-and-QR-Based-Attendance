# Accessibility recipes

Copy these. Rules live in `SKILL.md`.

## Custom control

```dart
Semantics(
  button: true,
  label: 'Submit',
  tooltip: 'Submit',
  hint: 'Sends the form',
  onTap: onSubmit,
  child: CustomPaint(painter: SubmitPainter()),
)
```

Need a distinct TalkBack/VoiceOver focus stop: `container: true`. Replace child semantics: `excludeSemantics: true`. Transient status: `liveRegion: true`.

## Merge a control and its label

```dart
MergeSemantics(
  child: Row(
    children: <Widget>[
      Checkbox(
        value: true,
        onChanged: (bool? value) {},
      ),
      const Text('Settings'),
    ],
  ),
)
```

## Exclude decorative / block what's behind

```dart
ExcludeSemantics(
  child: const Icon(Icons.star), // redundant with a visible label
)

Semantics(
  excludeSemantics: true,
  button: true,
  label: 'Close',
  onTap: onClose,
  child: customCloseGlyph,
)

BlockSemantics(
  child: modalOrDrawer,
)
```

## Icon-only and images

```dart
IconButton(
  tooltip: 'Search',
  icon: const Icon(Icons.search),
  onPressed: onSearch,
)

Image.asset('assets/hero.png', semanticLabel: 'Team celebrating');
Image.asset('assets/rule.png', excludeFromSemantics: true);
const Icon(Icons.star_border, semanticLabel: 'Not favorited');
```

## Text scale

```dart
final TextScaler scaler = MediaQuery.textScalerOf(context);
final double size = scaler.scale(16);

MediaQuery.withNoTextScaling(
  child: const Icon(Icons.chevron_right),
)

MediaQuery.withClampedTextScaling(
  maxScaleFactor: 1.3,
  child: overflowProneChip,
)
```

## MediaQuery flags and themes

```dart
final bool screenReader = MediaQuery.accessibleNavigationOf(context);
final bool highContrast = MediaQuery.highContrastOf(context);
final bool disableAnim = MediaQuery.disableAnimationsOf(context);

if (screenReader) {
  // disable timeouts or raise their minimum duration
}

MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  highContrastTheme: highContrastLight,
  highContrastDarkTheme: highContrastDark,
);
```

## Screen-reader vs keyboard order

```dart
Semantics(
  sortKey: const OrdinalSortKey(1.0),
  child: firstTalkBackStop,
)

FocusTraversalGroup(
  child: formFields, // default ReadingOrderTraversalPolicy
)

FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: columnWithFocusTraversalOrderChildren,
)
```

## Guideline test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_accessible_app/main.dart';

void main() {
  testWidgets('Follows a11y guidelines', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const AccessibleApp());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
```

## Web and debug

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  runApp(const MyApp());
  SemanticsBinding.instance.ensureSemantics();
}

MaterialApp(
  showSemanticsDebugger: true,
  home: home,
);
```

```bash
flutter run -d chrome --profile --dart-define=FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true
```

## Custom animation

```dart
final bool disableAnim = MediaQuery.disableAnimationsOf(context);
final Duration duration =
    disableAnim ? Duration.zero : const Duration(milliseconds: 200);
```

`AnimationController` already honors `SemanticsBinding.disableAnimations`. iOS Reduce Motion is `AccessibilityFeatures.reduceMotion`, not `disableAnimations`.

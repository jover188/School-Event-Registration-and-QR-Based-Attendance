# Controls

Official: [Material widgets](https://docs.flutter.dev/ui/widgets/material), [Cupertino widgets](https://docs.flutter.dev/ui/widgets/cupertino), [`.adaptive()` constructors](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations#widgets-with-adaptive-constructors).

OS-native input and feedback must use the adaptive constructor. Brand chrome (buttons, cards, nav) stays on the app's design system.

## Adaptive (always for these)

| Material | Becomes on iOS |
| --- | --- |
| `Switch.adaptive` | `CupertinoSwitch` |
| `Slider.adaptive` | `CupertinoSlider` |
| `Checkbox.adaptive` | `CupertinoCheckbox` |
| `Radio.adaptive` | `CupertinoRadio` |
| `CircularProgressIndicator.adaptive` | `CupertinoActivityIndicator` |
| `RefreshIndicator.adaptive` | iOS-style refresh |
| `AlertDialog.adaptive` + `showAdaptiveDialog` | `CupertinoAlertDialog` |

These already fire the right haptics. Do not add `HapticFeedback` on top.

## Buttons

Primary: `FilledButton`. Secondary: `FilledButton.tonal` or `OutlinedButton`. Tertiary: `TextButton`. Destructive: `FilledButton` / `TextButton` with `styleFrom(foregroundColor: colors.error, …)`.

Icon-only: `IconButton`, `IconButton.filled`, `IconButton.filledTonal`, `IconButton.outlined`.

FAB: one per screen, for the single constructive action. Prefer `FloatingActionButton.extended` when the label is not obvious.

iOS-first: `CupertinoButton` / `CupertinoButton.filled`. Do not drop a `FilledButton` into a `CupertinoPageScaffold`.

## Text fields

```dart
TextFormField(
  key: const ValueKey<String>('email-field'),
  keyboardType: TextInputType.emailAddress,
  autofillHints: const <String>[AutofillHints.email],
  textInputAction: TextInputAction.next,
  decoration: const InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
  ),
  validator: validateEmail,
)
```

- Outlined M3 fields by default (`InputDecorationTheme` on the theme).
- iOS-first: `CupertinoTextField` / `CupertinoTextFormFieldRow` inside `CupertinoFormSection`.
- Set `keyboardType`, `textInputAction`, `autofillHints`, `autocorrect`, `obscureText` correctly.
- Errors live in `InputDecoration.errorText` or `FormField.validator`, not a sibling `Text` in red.

Search: `SearchAnchor.bar` / `SearchBar` (Material) or `CupertinoSearchTextField`.

## Selection

- 2–5 exclusive options: `SegmentedButton` or `CupertinoSlidingSegmentedControl`.
- Many options: `DropdownMenu` or a picker sheet.
- Filters: `FilterChip` / `InputChip`.
- On/off setting in a list: `Switch.adaptive` as `ListTile.trailing` (Material) or `CupertinoListTile` + `CupertinoSwitch`.
- Continuous value: `Slider.adaptive`. Stepped: set `divisions`.

```dart
ListTile(
  title: const Text('Notifications'),
  trailing: Switch.adaptive(
    key: const ValueKey<String>('notifications-switch'),
    value: enabled,
    onChanged: onChanged,
  ),
  onTap: () => onChanged(!enabled),
)
```

## Pickers

Material: `showDatePicker`, `showTimePicker`, `showDateRangePicker`.

iOS: `showCupertinoModalPopup` + `CupertinoDatePicker` / `CupertinoTimerPicker` / `CupertinoPicker` (wheel, 5+ items).

Do not present a Material calendar on an iOS-first surface.

## Menus

`MenuAnchor` for overflow and context actions. `MenuBar` on desktop. `CupertinoContextMenu` for iOS long-press previews.

## Progress and feedback

- Determinate work: `LinearProgressIndicator` / `CircularProgressIndicator`.
- Indeterminate OS spinner: `CircularProgressIndicator.adaptive`.
- Transient confirmation: `SnackBar` via `ScaffoldMessenger`. iOS-first: a `CupertinoAlertDialog` only when the user must acknowledge.
- Tooltips on icon-only desktop/web actions (`Tooltip`).

## Haptics

```dart
await HapticFeedback.selectionClick();
await HapticFeedback.lightImpact();
```

Use for custom gestures you invented. Built-in pickers, switches, and sliders already knock. iOS selection buzz ≠ Android long-press vibrate — do not normalize them.

## Accessibility

- Every icon-only control: `tooltip` or `Semantics(label: ...)`.
- Contrast from `ColorScheme` roles, not pale greys on white.
- Do not `IgnorePointer` over a focusable field.
- `SelectableText` for identifiers, errors, and codes.

# Form recipes

Official: [validation](https://docs.flutter.dev/cookbook/forms/validation), [AutofillGroup](https://api.flutter.dev/flutter/widgets/AutofillGroup-class.html), [FormField](https://api.flutter.dev/flutter/widgets/FormField-class.html), [forceErrorText](https://api.flutter.dev/flutter/widgets/FormField/forceErrorText.html). Rules live in `SKILL.md`. These are pasteable shapes.

## Login vs signup

```dart
AutofillGroup(
  child: Column(
    children: <Widget>[
      TextFormField(
        key: const ValueKey<String>('email-field'),
        focusNode: emailFocus,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[AutofillHints.email, AutofillHints.username],
        decoration: const InputDecoration(labelText: 'Email', helperText: ' '),
        validator: (String? v) {
          if (v == null || v.isEmpty) return 'Required';
          return null;
        },
      ),
      TextFormField(
        key: const ValueKey<String>('password-field'),
        focusNode: passwordFocus,
        obscureText: true,
        textInputAction: TextInputAction.done,
        autofillHints: const <String>[AutofillHints.password],
        onFieldSubmitted: (_) => submit(),
        decoration: const InputDecoration(labelText: 'Password', helperText: ' '),
        validator: (String? v) {
          if (v == null || v.isEmpty) return 'Required';
          return null;
        },
      ),
    ],
  ),
)
```

Signup: `AutofillHints.newUsername` + `AutofillHints.newPassword` (never `password` on create-account). iOS/web read only the first hint — put the real type first. Do not place these fields only as unbuilt `ListView.builder` children.

After the last successful step of the screen:

```dart
TextInput.finishAutofillContext(shouldSave: true);
```

## First invalid field

`validateGranularly()` returns a `Set` — walk **your** visual order:

```dart
void submit() {
  final Set<FormFieldState<Object?>> invalid =
      formKey.currentState!.validateGranularly();
  if (invalid.isEmpty) {
    formKey.currentState!.save();
    TextInput.finishAutofillContext(shouldSave: true);
    return;
  }
  setState(() => auto = AutovalidateMode.onUserInteraction);
  if (invalid.contains(emailField.currentState)) {
    emailFocus.requestFocus();
  } else if (invalid.contains(passwordField.currentState)) {
    passwordFocus.requestFocus();
  }
}
```

`emailField` / `passwordField` are `GlobalKey<FormFieldState<String>>` on those fields. `requestFocus()` on the `FocusNode` is enough — do not call `FocusScope.of(context).requestFocus`.

## Server error

```dart
String? serverEmailError;

TextFormField(
  forceErrorText: serverEmailError,
  validator: (String? v) {
    if (v == null || v.isEmpty) return 'Required';
    return null;
  },
  onChanged: (_) {
    if (serverEmailError != null) {
      setState(() => serverEmailError = null);
    }
  },
)
```

On API failure: `setState(() => serverEmailError = message)`. While non-null, `validator` does not run and `InputDecoration.errorText` is ignored.

## Custom FormField

```dart
FormField<bool>(
  initialValue: false,
  validator: (bool? v) => (v ?? false) ? null : 'Required',
  builder: (FormFieldState<bool> state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Checkbox(
          value: state.value ?? false,
          onChanged: (bool? v) => state.didChange(v ?? false),
        ),
        if (state.hasError) Text(state.errorText!),
      ],
    );
  },
)
```

Same `didChange` pattern for sliders and chip pickers. `state.clearError()` drops a visible error without `reset()`.

## Lazy list

Own the controller on the ancestor that also owns the `ListView`. The auto-created controller is disposed when the row leaves the viewport.

```dart
class _RowsState extends State<Rows> {
  late final List<TextEditingController> rows = List<TextEditingController>.generate(
    20,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final TextEditingController c in rows) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int i) {
        return TextFormField(
          controller: rows[i],
          validator: (String? v) {
            if (v == null || v.isEmpty) return 'Required';
            return null;
          },
        );
      },
    );
  }
}
```

Credential `AutofillGroup` fields must still be built together — do not hide username/password behind lazy first-layout.

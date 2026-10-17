# Storage

Only when the screen needs persistence. Do not add a database to ship a widget.

| Need | Package | Notes |
| --- | --- | --- |
| Small key/value | `shared_preferences` | Use `SharedPreferencesAsync` (or `SharedPreferencesWithCache`), not the legacy `SharedPreferences.getInstance()` in new code |
| Secrets, tokens | `flutter_secure_storage` | Keychain / EncryptedSharedPreferences |
| Files, cache dirs | `path_provider` | Then `dart:io` `File` / `Directory` (not on web — use conditional imports) |
| Structured SQL | `drift` | Prefer over raw `sqflite` for new schemas |
| Existing Hive/Isar/sqflite | Keep it | Do not migrate as a side effect of a UI task |

```dart
final SharedPreferencesAsync prefs = SharedPreferencesAsync();
await prefs.setBool('haptics', true);
final bool enabled = await prefs.getBool('haptics') ?? true;
```

Theme mode and similar flags belong next to the project's existing settings layer, not a new `ThemePrefs` singleton in `lib/ui`.

Web and Wasm: `dart:io` and `dart:html` are the wrong layer. Prefer the packages above (they federate) or `package:web`. Flutter 3.47 is moving web toward Wasm by default; do not add `dart:html` usage.

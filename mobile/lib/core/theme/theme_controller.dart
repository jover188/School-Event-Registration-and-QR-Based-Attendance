import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central controller managing application theme mode (light, dark, system).
///
/// Persists the selected mode across app launches using [SharedPreferences]
/// with key [storageKey].
class AppThemeController extends ChangeNotifier {
  static final AppThemeController _instance = AppThemeController._internal();
  factory AppThemeController() => _instance;
  AppThemeController._internal();

  static const String storageKey = 'attendify_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(storageKey);
    switch (savedMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString(storageKey, value);
  }

  Future<void> toggleLightDark() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  @visibleForTesting
  void resetForTesting({ThemeMode mode = ThemeMode.system}) {
    _themeMode = mode;
  }
}

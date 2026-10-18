import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_event_attendance/core/theme/app_theme.dart';

class AppTestHost extends StatelessWidget {
  const AppTestHost({
    super.key,
    required this.child,
    this.navigatorKey,
    this.themeMode = ThemeMode.light,
  });
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final ThemeMode themeMode;

  static bool _storageMocked = false;

  static void ensureStorageMocked() {
    if (!_storageMocked) {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      _storageMocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    ensureStorageMocked();
    return ShadApp.custom(
      theme: AppTheme.shadTheme,
      darkTheme: AppTheme.shadDarkTheme,
      themeMode: themeMode,
      appBuilder: (context) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: const [GlobalShadLocalizations.delegate],
        scrollBehavior: const ShadScrollBehavior(),
        builder: (context, child) => ShadAppBuilder(child: child),
        home: child,
      ),
    );
  }
}

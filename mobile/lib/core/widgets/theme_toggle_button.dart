import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

/// An action bar icon button that toggles between light and dark mode.
///
/// Listens to [AppThemeController] and displays a sun icon when dark mode
/// is active, and a moon icon when light mode is active.
class ThemeToggleIconButton extends StatelessWidget {
  final double iconSize;
  final Color? color;

  const ThemeToggleIconButton({
    super.key = const ValueKey<String>('header-theme-toggle-button'),
    this.iconSize = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final controller = AppThemeController();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = controller.isDarkMode;
        return IconButton(
          icon: Icon(
            isDark ? LucideIcons.sun : LucideIcons.moon,
            size: iconSize,
            color: color ?? d.primary,
          ),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () => controller.toggleLightDark(),
        );
      },
    );
  }
}

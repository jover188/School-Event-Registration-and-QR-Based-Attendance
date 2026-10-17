import 'package:flutter/material.dart';

/// Semantic color tokens for the School Event Registration & Attendance system.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1E3A8A); // Academic Navy (#1E3A8A)
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Navy Tint (#EFF6FF)
  static const Color secondary = Color(0xFF0D9488); // Teal (#0D9488)
  static const Color secondaryLight = Color(0xFFF0FDFA); // Soft Teal Tint (#F0FDFA)
  static const Color accent = Color(0xFFF59E0B); // Amber (#F59E0B)

  static const Color surface = Color(0xFFF8FAFC); // Cool Slate Surface (#F8FAFC)
  static const Color card = Color(0xFFFFFFFF); // Pure White Card (#FFFFFF)
  static const Color border = Color(0xFFE2E8F0); // Slate 200 Border (#E2E8F0)

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (#0F172A)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (#475569)
  static const Color textMuted = Color(0xFF64748B); // Slate 500 (#64748B)

  // Semantic Attendance & Event Status Colors (WCAG AA compliant on light pills)
  static const Color present = Color(0xFF16A34A); // Green 600 (#16A34A)
  static const Color late = Color(0xFFD97706); // Amber 600 (#D97706)
  static const Color absent = Color(0xFFDC2626); // Red 600 (#DC2626)
  static const Color walkIn = Color(0xFF2563EB); // Blue 600 (#2563EB)
  static const Color waiting = Color(0xFF7C3AED); // Violet 600 (#7C3AED)
  static const Color excused = Color(0xFF0284C7); // Sky 600 (#0284C7)

  /// Returns the semantic foreground color for a given event, registration,
  /// attendance, or account status string.
  static Color statusColor(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'published' ||
      'registered' ||
      'present' ||
      'active' ||
      'approved' =>
        present,
      'ongoing' || 'walk_in' || 'walk-in' => walkIn,
      'completed' => primary,
      'late' || 'pending_approval' || 'pending' => late,
      'waiting_list' || 'waiting' => waiting,
      'excused' => excused,
      'cancelled' ||
      'absent' ||
      'rejected' ||
      'revoked' ||
      'inactive' ||
      'suspended' =>
        absent,
      'draft' => textSecondary,
      _ => textSecondary,
    };
  }

  /// Returns a high-contrast, soft tinted background color for a given status.
  static Color statusBackgroundColor(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'published' ||
      'registered' ||
      'present' ||
      'active' ||
      'approved' =>
        const Color(0xFFDCFCE7),
      'ongoing' || 'walk_in' || 'walk-in' => const Color(0xFFDBEAFE),
      'completed' => primaryLight,
      'late' || 'pending_approval' || 'pending' => const Color(0xFFFEF3C7),
      'waiting_list' || 'waiting' => const Color(0xFFF3E8FF),
      'excused' => const Color(0xFFE0F2FE),
      'cancelled' ||
      'absent' ||
      'rejected' ||
      'revoked' ||
      'inactive' ||
      'suspended' =>
        const Color(0xFFFEE2E2),
      'draft' => const Color(0xFFF1F5F9),
      _ => const Color(0xFFF1F5F9),
    };
  }
}

/// Consistent spacing scale (4pt grid).
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Consistent border radius tokens.
class AppRadius {
  const AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// Clean typography presets that respect OS TextScaler.
class AppTypography {
  const AppTypography._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    height: 1.2,
  );
}

/// Application theme configuration with backward-compatible static color getters.
class AppTheme {
  // Primary & Brand Aliases (backward-compatible)
  static const Color primary = AppColors.primary;
  static const Color primaryColor = AppColors.primary;
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color secondary = AppColors.secondary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accent = AppColors.accent;
  static const Color accentColor = AppColors.accent;
  static const Color surfaceColor = AppColors.surface;

  // Status Badge Aliases (backward-compatible)
  static const Color presentColor = AppColors.present;
  static const Color lateColor = AppColors.late;
  static const Color walkInColor = AppColors.walkIn;
  static const Color absentColor = AppColors.absent;
  static const Color waitingColor = AppColors.waiting;
  static const Color excusedColor = AppColors.excused;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.absent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.card,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primaryLight,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.absent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.absent, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: AppSpacing.md,
      ),
    );
  }
}

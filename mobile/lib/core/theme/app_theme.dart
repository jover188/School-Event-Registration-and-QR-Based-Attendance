import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app_tokens.dart';
export 'app_tokens.dart';

abstract final class AppColors {
  static const primary = AppPalette.primary;
  static const primaryLight = AppPalette.selection;
  static const secondary = AppPalette.brandCyan;
  static const secondaryLight = AppPalette.excusedBackground;
  static const accent = AppPalette.brandPink;
  static const surface = AppPalette.background;
  static const card = AppPalette.card;
  static const border = AppPalette.border;
  static const textPrimary = AppPalette.foreground;
  static const textSecondary = AppPalette.mutedForeground;
  static const textMuted = AppPalette.mutedForeground;
  static const present = AppPalette.success;
  static const late = AppPalette.warning;
  static const absent = AppPalette.destructive;
  static const walkIn = AppPalette.information;
  static const waiting = AppPalette.waiting;
  static const excused = AppPalette.excused;
  static Color statusColor(String status) => AppDesignTokens.light.statusColor(status);
  static Color statusBackgroundColor(String status) => AppDesignTokens.light.statusBackgroundColor(status);
}

abstract final class AppSpacing {
  static const xs = 4.0, sm = 8.0, gap = 12.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = 15.0, md = 15.0, lg = 15.0, xl = 15.0, full = 999.0;
}

abstract final class AppTypography {
  static const headline = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppPalette.foreground,
  );
  static const title = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppPalette.foreground,
  );
  static const subtitle = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppPalette.foreground,
  );
  static const body = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    color: AppPalette.foreground,
  );
  static const bodyMuted = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 13,
    height: 18 / 13,
    color: AppPalette.mutedForeground,
  );
  static const caption = bodyMuted;
  static const badge = TextStyle(
    fontFamily: AppPalette.fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

abstract final class AppTheme {
  static const primary = AppColors.primary;
  static const primaryColor = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const secondary = AppColors.secondary;
  static const secondaryColor = AppColors.secondary;
  static const accent = AppColors.accent;
  static const accentColor = AppColors.accent;
  static const surfaceColor = AppColors.surface;
  static const presentColor = AppColors.present;
  static const lateColor = AppColors.late;
  static const walkInColor = AppColors.walkIn;
  static const absentColor = AppColors.absent;
  static const waitingColor = AppColors.waiting;
  static const excusedColor = AppColors.excused;

  static ShadThemeData get shadTheme => _buildShadTheme(AppDesignTokens.light, Brightness.light);
  static ShadThemeData get shadDarkTheme => _buildShadTheme(AppDesignTokens.dark, Brightness.dark);

  static ShadThemeData _buildShadTheme(AppDesignTokens d, Brightness brightness) {
    return ShadThemeData(
      brightness: brightness,
      radius: BorderRadius.circular(d.radiusControl),
      colorScheme: ShadColorScheme(
        background: d.background,
        foreground: d.foreground,
        card: d.card,
        cardForeground: d.cardForeground,
        popover: d.popover,
        popoverForeground: d.popoverForeground,
        primary: d.primary,
        primaryForeground: d.primaryForeground,
        secondary: d.secondary,
        secondaryForeground: d.secondaryForeground,
        muted: d.muted,
        mutedForeground: d.mutedForeground,
        accent: d.accent,
        accentForeground: d.accentForeground,
        destructive: d.destructive,
        destructiveForeground: d.destructiveForeground,
        border: d.border,
        input: d.input,
        ring: d.ring,
        selection: d.selection,
      ),
    );
  }

  static ThemeData get lightTheme => _buildMaterialTheme(AppDesignTokens.light, Brightness.light);
  static ThemeData get darkTheme => _buildMaterialTheme(AppDesignTokens.dark, Brightness.dark);

  static ThemeData _buildMaterialTheme(AppDesignTokens d, Brightness brightness) {
    final colorScheme = brightness == Brightness.light
        ? ColorScheme.light(
            primary: d.primary,
            onPrimary: d.primaryForeground,
            primaryContainer: d.secondary,
            onPrimaryContainer: d.secondaryForeground,
            secondary: d.secondary,
            onSecondary: d.secondaryForeground,
            secondaryContainer: d.accent,
            onSecondaryContainer: d.accentForeground,
            tertiary: d.success,
            onTertiary: d.successForeground,
            surface: d.card,
            onSurface: d.cardForeground,
            error: d.destructive,
            onError: d.destructiveForeground,
            outline: d.input,
            outlineVariant: d.border,
          )
        : ColorScheme.dark(
            primary: d.primary,
            onPrimary: d.primaryForeground,
            primaryContainer: d.secondary,
            onPrimaryContainer: d.secondaryForeground,
            secondary: d.secondary,
            onSecondary: d.secondaryForeground,
            secondaryContainer: d.accent,
            onSecondaryContainer: d.accentForeground,
            tertiary: d.success,
            onTertiary: d.successForeground,
            surface: d.card,
            onSurface: d.cardForeground,
            error: d.destructive,
            onError: d.destructiveForeground,
            outline: d.input,
            outlineVariant: d.border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppPalette.fontFamily,
      extensions: [d],
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: d.background,
      iconTheme: IconThemeData(color: d.primary, size: 18, weight: 300),
      textTheme: TextTheme(
        headlineLarge: d.pageTitle,
        headlineMedium: d.compactPageTitle,
        titleLarge: d.sectionTitle,
        titleMedium: d.cardTitle,
        bodyLarge: d.body,
        bodyMedium: d.body,
        bodySmall: d.supporting,
        labelLarge: d.body.copyWith(fontWeight: FontWeight.w600),
        labelSmall: d.badge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: d.card,
        foregroundColor: d.cardForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: d.cardTitle,
        iconTheme: IconThemeData(color: d.primary, size: 20, weight: 300),
      ),
      cardTheme: CardThemeData(
        color: d.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(d.radiusCard),
          side: BorderSide(color: d.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: d.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(d.radiusOverlay),
          side: BorderSide(color: d.border, width: 1),
        ),
        titleTextStyle: d.sectionTitle.copyWith(color: d.popoverForeground),
        contentTextStyle: d.body.copyWith(color: d.popoverForeground),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: d.popover,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(d.radiusOverlay)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: d.authDark,
          foregroundColor: d.authLight,
          elevation: 0,
          minimumSize: Size(d.minimumTarget, d.minimumTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusControl)),
          textStyle: d.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: d.foreground,
          backgroundColor: d.card,
          side: BorderSide(color: d.border, width: 1),
          minimumSize: Size(d.minimumTarget, d.minimumTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusControl)),
          textStyle: d.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(d.minimumTarget, d.minimumTarget),
          foregroundColor: d.foreground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.radiusControl)),
          textStyle: d.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(d.minimumTarget, d.minimumTarget),
          foregroundColor: d.primary,
          iconSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: d.card,
        errorMaxLines: 4,
        contentPadding: EdgeInsets.symmetric(horizontal: d.md, vertical: 14),
        hintStyle: d.supporting.copyWith(color: d.authDark.withValues(alpha: 0.48)),
        labelStyle: d.supporting.copyWith(color: d.authDark.withValues(alpha: 0.62)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusCard),
          borderSide: BorderSide(color: d.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusCard),
          borderSide: BorderSide(color: d.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusCard),
          borderSide: BorderSide(color: d.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.radiusCard),
          borderSide: BorderSide(color: d.destructive, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: d.border, thickness: 1, space: d.md),
    );
  }
}


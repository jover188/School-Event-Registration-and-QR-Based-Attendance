import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_spinner.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { compact, standard, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
    this.icon,
    this.pill = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool pill;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    final effectiveHeight = height ??
        switch (size) {
          AppButtonSize.compact => d.buttonHeightCompact,
          AppButtonSize.standard => d.buttonHeightStandard,
          AppButtonSize.large => d.buttonHeightLarge,
        };

    final horizontalPadding = switch (size) {
      AppButtonSize.compact => d.buttonPaddingHorizontalCompact,
      AppButtonSize.standard => d.buttonPaddingHorizontalStandard,
      AppButtonSize.large => d.buttonPaddingHorizontalLarge,
    };

    final verticalPadding = switch (size) {
      AppButtonSize.compact => 4.0,
      AppButtonSize.standard => 6.0,
      AppButtonSize.large => 8.0,
    };

    final effectiveIconSize = switch (size) {
      AppButtonSize.compact => d.buttonIconSizeCompact,
      AppButtonSize.standard => d.buttonIconSizeStandard,
      AppButtonSize.large => d.buttonIconSizeLarge,
    };

    final defaultFontSize = switch (size) {
      AppButtonSize.compact => 12.5,
      AppButtonSize.standard => 13.5,
      AppButtonSize.large => 14.5,
    };

    final fgColor = foregroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimaryForeground,
          AppButtonVariant.secondary => d.secondaryForeground,
          AppButtonVariant.destructive => d.destructiveForeground,
          AppButtonVariant.outline => d.foreground,
          AppButtonVariant.ghost => d.foreground,
        };

    final bgColor = backgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimary,
          AppButtonVariant.secondary => d.secondary,
          AppButtonVariant.outline => d.card,
          AppButtonVariant.ghost => Colors.transparent,
          AppButtonVariant.destructive => d.destructive,
        };

    // Mobile-friendly corner radius
    final radius = BorderRadius.circular(
      size == AppButtonSize.compact ? d.buttonRadiusCompact : d.buttonRadiusStandard,
    );

    final effectiveBorderColor = borderColor ??
        switch (variant) {
          AppButtonVariant.outline => d.border,
          AppButtonVariant.secondary => d.border,
          _ => null,
        };

    final effectiveDecoration = effectiveBorderColor != null
        ? ShadDecoration(
            border: ShadBorder.all(
              color: effectiveBorderColor,
              width: 1,
              radius: radius,
            ),
          )
        : null;

    final effectiveWidth = isFullWidth ? double.infinity : width;

    final button = ShadButton.raw(
      variant: switch (variant) {
        AppButtonVariant.primary => ShadButtonVariant.primary,
        AppButtonVariant.secondary => ShadButtonVariant.secondary,
        AppButtonVariant.outline => ShadButtonVariant.outline,
        AppButtonVariant.ghost => ShadButtonVariant.ghost,
        AppButtonVariant.destructive => ShadButtonVariant.destructive,
      },
      backgroundColor: bgColor,
      hoverBackgroundColor: backgroundColor == null ? null : bgColor,
      foregroundColor: fgColor,
      hoverForegroundColor: foregroundColor == null ? null : fgColor,
      decoration: effectiveDecoration,
      height: height ?? 0,
      width: effectiveWidth,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      enabled: onPressed != null && !isLoading,
      onPressed: isLoading ? null : onPressed,
      child: Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: effectiveHeight - (2 * verticalPadding),
            minWidth: effectiveHeight - (2 * horizontalPadding),
          ),
          child: Semantics(
            liveRegion: isLoading,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  AppSpinner.sm(color: fgColor),
                  SizedBox(width: d.buttonIconSpacing),
                ] else if (icon != null) ...[
                  Icon(icon, size: effectiveIconSize, weight: 300, color: fgColor),
                  SizedBox(width: d.buttonIconSpacing),
                ],
                Flexible(
                  child: Text(
                    isLoading ? '$label…' : label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: (labelStyle ?? d.body).copyWith(
                      fontSize: labelStyle?.fontSize ?? defaultFontSize,
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ShadTheme.maybeOf(context) == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return ShadTheme(
        data: isDark ? AppTheme.shadDarkTheme : AppTheme.shadTheme,
        child: button,
      );
    }
    return button;
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.standard,
    this.badgeCount,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final int? badgeCount;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    final dimension = switch (size) {
      AppButtonSize.compact => 30.0,
      AppButtonSize.standard => 36.0,
      AppButtonSize.large => 42.0,
    };

    final iconSize = switch (size) {
      AppButtonSize.compact => d.buttonIconSizeCompact,
      AppButtonSize.standard => d.buttonIconSizeStandard,
      AppButtonSize.large => d.buttonIconSizeLarge,
    };

    final fgColor = foregroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimaryForeground,
          AppButtonVariant.secondary => d.secondaryForeground,
          AppButtonVariant.destructive => d.destructiveForeground,
          AppButtonVariant.outline => d.foreground,
          AppButtonVariant.ghost => d.foreground,
        };

    final bgColor = backgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimary,
          AppButtonVariant.secondary => d.secondary,
          AppButtonVariant.outline => d.card,
          AppButtonVariant.ghost => Colors.transparent,
          AppButtonVariant.destructive => d.destructive,
        };

    final radius = BorderRadius.circular(
      size == AppButtonSize.compact ? d.buttonRadiusCompact : d.buttonRadiusStandard,
    );

    final effectiveBorderColor = borderColor ??
        switch (variant) {
          AppButtonVariant.outline => d.border,
          AppButtonVariant.secondary => d.border,
          _ => null,
        };

    final decoration = effectiveBorderColor != null
        ? ShadDecoration(
            border: ShadBorder.all(
              color: effectiveBorderColor,
              width: 1,
              radius: radius,
            ),
          )
        : null;

    final targetMin = switch (size) {
      AppButtonSize.compact => 32.0,
      AppButtonSize.standard => 40.0,
      AppButtonSize.large => 44.0,
    };

    Widget buttonContent = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (isLoading)
          AppSpinner.sm(color: fgColor)
        else
          Icon(icon, size: iconSize, color: fgColor),
        if (badgeCount != null && badgeCount! > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: d.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: d.card, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: d.primaryForeground,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );

    Widget button = ShadButton.raw(
      variant: switch (variant) {
        AppButtonVariant.primary => ShadButtonVariant.primary,
        AppButtonVariant.secondary => ShadButtonVariant.secondary,
        AppButtonVariant.outline => ShadButtonVariant.outline,
        AppButtonVariant.ghost => ShadButtonVariant.ghost,
        AppButtonVariant.destructive => ShadButtonVariant.destructive,
      },
      backgroundColor: bgColor,
      hoverBackgroundColor: backgroundColor == null ? null : bgColor,
      foregroundColor: fgColor,
      hoverForegroundColor: foregroundColor == null ? null : fgColor,
      decoration: decoration,
      width: dimension,
      height: dimension,
      padding: EdgeInsets.zero,
      enabled: onPressed != null && !isLoading,
      onPressed: isLoading ? null : onPressed,
      child: buttonContent,
    );

    if (dimension < targetMin) {
      button = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: targetMin,
          minHeight: targetMin,
        ),
        child: Center(child: button),
      );
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null && !isLoading,
        child: button,
      );
    }

    if (ShadTheme.maybeOf(context) == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return ShadTheme(
        data: isDark ? AppTheme.shadDarkTheme : AppTheme.shadTheme,
        child: button,
      );
    }

    return button;
  }
}

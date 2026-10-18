import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_spinner.dart';

enum AppButtonVariant { primary, outline, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.pill = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool pill;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final fgColor = foregroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimaryForeground,
          AppButtonVariant.destructive => d.destructiveForeground,
          AppButtonVariant.outline => d.foreground,
          AppButtonVariant.ghost => d.foreground,
        };

    final bgColor = backgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => d.buttonPrimary,
          AppButtonVariant.outline => d.card,
          AppButtonVariant.ghost => Colors.transparent,
          AppButtonVariant.destructive => d.destructive,
        };

    final radius = BorderRadius.circular(pill ? d.radiusPill : d.radiusControl);

    final effectiveBorderColor =
        borderColor ?? (variant == AppButtonVariant.outline ? d.border : null);

    final effectiveDecoration = effectiveBorderColor != null
        ? ShadDecoration(
            border: ShadBorder.all(
              color: effectiveBorderColor,
              width: 1,
              radius: radius,
            ),
          )
        : (pill
            ? ShadDecoration(
                border: ShadBorder.all(
                  color: Colors.transparent,
                  width: 0,
                  radius: radius,
                ),
              )
            : null);

    final button = ShadButton.raw(
      variant: switch (variant) {
        AppButtonVariant.primary => ShadButtonVariant.primary,
        AppButtonVariant.outline => ShadButtonVariant.outline,
        AppButtonVariant.ghost => ShadButtonVariant.ghost,
        AppButtonVariant.destructive => ShadButtonVariant.destructive,
      },
      backgroundColor: bgColor,
      hoverBackgroundColor: backgroundColor == null ? null : bgColor,
      foregroundColor: fgColor,
      hoverForegroundColor: foregroundColor == null ? null : fgColor,
      decoration: effectiveDecoration,
      height: 0,
      padding: EdgeInsets.symmetric(
        horizontal: d.md,
        vertical: pill ? d.md : d.gap,
      ),
      enabled: onPressed != null && !isLoading,
      onPressed: isLoading ? null : onPressed,
      child: Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: d.minimumTarget - (2 * d.gap),
            minWidth: d.minimumTarget - (2 * d.md),
          ),
          child: Semantics(
            liveRegion: isLoading,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  AppSpinner.sm(color: fgColor),
                  SizedBox(width: d.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, weight: 300, color: fgColor),
                  SizedBox(width: d.sm),
                ],
                Flexible(
                  child: Text(
                    isLoading ? '$label…' : label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: (labelStyle ?? d.body).copyWith(
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

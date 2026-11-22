import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable empty state placeholder with modern AetherUI aesthetics,
/// subtle entrance animation, high-contrast borders, and accessibility semantics.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final EdgeInsetsGeometry? padding;

  const EmptyStateView({
    super.key,
    this.icon = LucideIcons.calendarX2,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return Center(
      child: SingleChildScrollView(
        padding: padding ?? EdgeInsets.all(d.lg),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - progress)),
                child: child,
              ),
            );
          },
          child: Semantics(
            liveRegion: true,
            label: message.trim().isNotEmpty
                ? '$title. $message'
                : title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon visual container with high-contrast border
                Container(
                  padding: EdgeInsets.all(d.md),
                  decoration: BoxDecoration(
                    color: d.selection,
                    borderRadius: BorderRadius.circular(d.radiusCard),
                    border: Border.all(color: d.border, width: 1),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    weight: 300,
                    color: d.foreground,
                  ),
                ),
                SizedBox(height: d.md),
                Text(
                  title,
                  style: d.sectionTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message.trim().isNotEmpty) ...[
                  SizedBox(height: d.xs + 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Text(
                      message,
                      style: d.supporting.copyWith(
                        color: d.mutedForeground,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: d.lg),
                  AppButton(
                    onPressed: onAction,
                    icon: actionIcon,
                    label: actionLabel!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

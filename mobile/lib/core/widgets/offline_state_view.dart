import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Full-height / centered placeholder for campus network disconnection.
///
/// Adheres strictly to AetherUI monochrome design tokens and provides
/// accessible semantics and a retry action.
class OfflineStateView extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String message;
  final String retryLabel;
  final bool isRetrying;
  final EdgeInsetsGeometry? padding;

  const OfflineStateView({
    super.key,
    required this.onRetry,
    this.title = 'No Internet Connection',
    this.message =
        'Unable to connect to the campus network. Please check your Wi-Fi or cellular data and try again.',
    this.retryLabel = 'Retry Connection',
    this.isRetrying = false,
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
                offset: Offset(0, 10 * (1 - progress)),
                child: child,
              ),
            );
          },
          child: Semantics(
            liveRegion: true,
            label: '$title. $message. Status: OFFLINE',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon visual container
                Container(
                  padding: EdgeInsets.all(d.md),
                  decoration: BoxDecoration(
                    color: d.selection,
                    borderRadius: BorderRadius.circular(d.radiusCard),
                    border: Border.all(color: d.border, width: 1),
                  ),
                  child: Icon(
                    LucideIcons.wifiOff,
                    size: 32,
                    weight: 300,
                    color: d.foreground,
                  ),
                ),
                SizedBox(height: d.md),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: d.sm + 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: d.muted,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: d.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: d.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: d.xs + 2),
                      Text(
                        'OFFLINE',
                        style: d.badge.copyWith(
                          color: d.mutedForeground,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: d.md),
                Text(
                  title,
                  style: d.sectionTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: d.foreground,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                SizedBox(height: d.lg),
                AppButton(
                  onPressed: onRetry,
                  isLoading: isRetrying,
                  icon: LucideIcons.refreshCw,
                  label: retryLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

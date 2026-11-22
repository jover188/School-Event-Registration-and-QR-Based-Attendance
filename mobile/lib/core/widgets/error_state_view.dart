import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable error state view with high-contrast borders, subtle entrance animation,
/// accessible live regions, and safe error presentation.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final String? title;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.title,
    this.isLoading = false,
    this.padding,
  });

  /// Sanitizes any raw message to prevent internal database queries or stack traces from appearing.
  static String _sanitize(String raw) {
    final lower = raw.toLowerCase();
    const sensitive = [
      'sql',
      'pdoexception',
      'syntax error',
      'queryexception',
      'column not found',
      'table',
      'stacktrace',
      'stack trace',
      'fatal error',
      'vendor/laravel',
      'connection refused',
    ];

    for (final word in sensitive) {
      if (lower.contains(word)) {
        return 'An unexpected error occurred while communicating with the service. Please try again.';
      }
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final sanitizedMessage = _sanitize(message);

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
            label: title != null
                ? '$title. $sanitizedMessage'
                : sanitizedMessage,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon visual container with high-contrast border
                Container(
                  padding: EdgeInsets.all(d.md),
                  decoration: BoxDecoration(
                    color: d.dangerBackground,
                    borderRadius: BorderRadius.circular(d.radiusCard),
                    border: Border.all(
                      color: d.destructive.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.circleAlert,
                    size: 32,
                    weight: 300,
                    color: d.destructive,
                  ),
                ),
                SizedBox(height: d.md),
                if (title != null) ...[
                  Text(
                    title!,
                    style: d.sectionTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: d.xs + 2),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(
                    sanitizedMessage,
                    style: d.body.copyWith(
                      color: title != null ? d.mutedForeground : d.destructive,
                      fontWeight: title != null ? FontWeight.w400 : FontWeight.w500,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: d.lg),
                AppButton(
                  onPressed: onRetry,
                  isLoading: isLoading,
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

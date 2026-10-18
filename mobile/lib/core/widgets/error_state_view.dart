import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable error state view with retry button.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(d.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(d.md),
              decoration: BoxDecoration(
                color: d.dangerBackground,
                borderRadius: BorderRadius.circular(d.radiusCard),
                border: Border.all(color: d.destructive.withValues(alpha: 0.2)),
              ),
              child: Icon(
                LucideIcons.circleAlert,
                size: 28,
                weight: 300,
                color: d.destructive,
              ),
            ),
            SizedBox(height: d.md),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: d.body.copyWith(color: d.destructive),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: d.md),
            AppButton(
              onPressed: onRetry,
              icon: LucideIcons.refreshCw,
              label: retryLabel,
            ),
          ],
        ),
      ),
    );
  }
}


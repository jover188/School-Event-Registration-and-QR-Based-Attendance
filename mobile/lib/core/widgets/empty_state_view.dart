import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable empty state placeholder with icon, title, message, and optional action.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.icon = LucideIcons.calendarX2,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
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
                color: d.selection,
                borderRadius: BorderRadius.circular(d.radiusCard),
                border: Border.all(color: d.primary.withValues(alpha: 0.16)),
              ),
              child: Icon(
                icon,
                size: 28,
                weight: 300,
                color: d.primary,
              ),
            ),
            SizedBox(height: d.md),
            Text(
              title,
              style: d.sectionTitle,
              textAlign: TextAlign.center,
            ),
            if (message.trim().isNotEmpty) ...[
              SizedBox(height: d.xs),
              Text(
                message,
                style: d.supporting,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: d.md),
              AppButton(
                onPressed: onAction,
                label: actionLabel!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


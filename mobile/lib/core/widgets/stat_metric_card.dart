import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

/// Reusable KPI / metric summary card with accessible container semantics.
class StatMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final semanticSummary = subtitle != null
        ? '$label: $value, $subtitle'
        : '$label: $value';

    final content = Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(d.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(d.sm),
            ),
            child: Icon(icon, size: 18, weight: 300, color: color),
          ),
          SizedBox(height: d.sm),
          Text(
            value,
            style: d.sectionTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: d.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: d.xs),
          Text(
            label,
            style: d.supporting.copyWith(
              color: d.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: d.badge.copyWith(
                color: d.mutedForeground,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return AppPressable(
        semanticLabel: semanticSummary,
        onPressed: onTap,
        child: content,
      );
    }

    return Semantics(
      container: true,
      label: semanticSummary,
      child: content,
    );
  }
}


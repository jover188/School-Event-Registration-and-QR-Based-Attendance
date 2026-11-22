import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

/// Reusable KPI / metric summary card with accessible container semantics
/// and desktop hover feedback.
class StatMetricCard extends StatefulWidget {
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
  State<StatMetricCard> createState() => _StatMetricCardState();
}

class _StatMetricCardState extends State<StatMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final semanticSummary = widget.subtitle != null
        ? '${widget.label}: ${widget.value}, ${widget.subtitle}'
        : '${widget.label}: ${widget.value}';
    final isInteractive = widget.onTap != null;

    final cardBorderColor = _isHovered
        ? (d.isDark
            ? d.foreground.withValues(alpha: 0.35)
            : d.foreground.withValues(alpha: 0.22))
        : d.border;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: _isHovered ? 0.08 : 0.04),
            offset: Offset(0, _isHovered ? 4 : 2),
            blurRadius: _isHovered ? 14 : 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                key: ValueKey('stat-icon-${widget.label}'),
                size: 18,
                weight: 300,
                color: d.primary,
              ),
              SizedBox(width: d.sm),
              Expanded(
                child: Text(
                  widget.label,
                  style: d.supporting.copyWith(
                    color: d.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          SizedBox(height: d.sm),
          Text(
            widget.value,
            style: d.sectionTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: d.foreground,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: d.badge.copyWith(
                color: d.mutedForeground,
                fontWeight: FontWeight.w400,
              ),
              softWrap: true,
            ),
          ],
        ],
      ),
    );

    final wrapped = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: content,
    );

    if (widget.onTap != null) {
      return AppPressable(
        semanticLabel: semanticSummary,
        onPressed: widget.onTap,
        child: wrapped,
      );
    }

    return Semantics(
      container: true,
      label: semanticSummary,
      child: wrapped,
    );
  }
}


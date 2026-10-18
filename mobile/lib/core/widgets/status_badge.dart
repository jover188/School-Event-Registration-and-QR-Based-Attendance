import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

/// Semantic status pill badge for events, registrations, attendance, and users.
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.showIcon = true,
  });

  static IconData _iconForStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    return switch (normalized) {
      'published' ||
      'registered' ||
      'present' ||
      'active' ||
      'approved' =>
        LucideIcons.circleCheck,
      'ongoing' => LucideIcons.radio,
      'completed' => LucideIcons.checkCheck,
      'walk_in' || 'walk-in' => LucideIcons.footprints,
      'late' => LucideIcons.clock,
      'pending_approval' || 'pending' => LucideIcons.hourglass,
      'waiting_list' || 'waiting' => LucideIcons.listOrdered,
      'excused' => LucideIcons.fileCheck,
      'cancelled' ||
      'absent' ||
      'rejected' ||
      'revoked' ||
      'inactive' ||
      'suspended' =>
        LucideIcons.circleX,
      'draft' => LucideIcons.filePenLine,
      _ => LucideIcons.info,
    };
  }

  String get _displayText {
    if (label != null && label!.trim().isNotEmpty) {
      return label!.trim().toUpperCase();
    }
    return status.trim().replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final fgColor = d.statusColor(status);
    final bgColor = d.statusBackgroundColor(status);
    final displayText = _displayText;

    return Semantics(
      container: true,
      label: 'Status: $displayText',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: d.sm + 2,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: fgColor.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                _iconForStatus(status),
                size: 13,
                weight: 300,
                color: fgColor,
              ),
              SizedBox(width: d.xs),
            ],
            Flexible(
              child: Text(
                displayText,
                style: d.badge.copyWith(color: fgColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


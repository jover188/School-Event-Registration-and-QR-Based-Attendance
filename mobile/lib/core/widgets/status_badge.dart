import 'package:flutter/material.dart';
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
        Icons.check_circle_outline,
      'ongoing' => Icons.sensors,
      'completed' => Icons.task_alt,
      'walk_in' || 'walk-in' => Icons.directions_walk,
      'late' => Icons.schedule,
      'pending_approval' || 'pending' => Icons.hourglass_top_rounded,
      'waiting_list' || 'waiting' => Icons.queue_rounded,
      'excused' => Icons.assignment_turned_in_outlined,
      'cancelled' ||
      'absent' ||
      'rejected' ||
      'revoked' ||
      'inactive' ||
      'suspended' =>
        Icons.cancel_outlined,
      'draft' => Icons.edit_note_rounded,
      _ => Icons.info_outline,
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
    final fgColor = AppColors.statusColor(status);
    final bgColor = AppColors.statusBackgroundColor(status);
    final displayText = _displayText;

    return Semantics(
      container: true,
      label: 'Status: $displayText',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: fgColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                _iconForStatus(status),
                size: 13,
                color: fgColor,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                displayText,
                style: AppTypography.badge.copyWith(color: fgColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Reusable card for rendering an [EventModel] across student, organizer,
/// management, and administrator lists.
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool showEventStatusBadge;
  final bool showCapacity;
  final Widget? trailingAction;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showEventStatusBadge = false,
    this.showCapacity = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final maxCap = event.maxParticipants;
    final registered = event.currentRegisteredCount;
    final progress = (maxCap != null && maxCap > 0)
        ? (registered / maxCap).clamp(0.0, 1.0)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTypography.subtitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (event.isRegistered)
                    const StatusBadge(
                      status: 'registered',
                      label: 'REGISTERED',
                    )
                  else if (event.isWaitingList)
                    StatusBadge(
                      status: 'waiting_list',
                      label: 'WAITING #${event.userWaitingPosition ?? 1}',
                    )
                  else if (showEventStatusBadge)
                    StatusBadge(status: event.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      event.venue,
                      style: AppTypography.bodyMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${event.eventDate} • ${event.startTime}',
                      style: AppTypography.bodyMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (showCapacity || trailingAction != null) ...[
                const Divider(height: AppSpacing.lg),
                if (progress != null && showCapacity) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: progress >= 1.0
                          ? AppColors.late
                          : AppColors.present,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showCapacity)
                      Expanded(
                        child: Text(
                          'Registered: $registered${maxCap != null ? ' / $maxCap' : ''}',
                          style: AppTypography.bodyMuted.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    if (trailingAction != null) trailingAction!,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

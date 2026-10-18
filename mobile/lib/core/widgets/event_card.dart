import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/event_model.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';
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

  (String month, String day) _parseDateTile(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      return (
        DateFormat('MMM').format(parsed).toUpperCase(),
        DateFormat('dd').format(parsed),
      );
    }
    return ('EVT', '--');
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final maxCap = event.maxParticipants;
    final registered = event.currentRegisteredCount;
    final progress = (maxCap != null && maxCap > 0)
        ? (registered / maxCap).clamp(0.0, 1.0)
        : null;
    final (monthLabel, dayLabel) = _parseDateTile(event.eventDate);

    final Widget? badgeWidget = event.isRegistered
        ? const StatusBadge(
            status: 'registered',
            label: 'REGISTERED',
          )
        : event.isWaitingList
            ? StatusBadge(
                status: 'waiting_list',
                label: 'WAITING #${event.userWaitingPosition ?? 1}',
              )
            : showEventStatusBadge
                ? StatusBadge(status: event.status)
                : null;

    final mainInfoContent = Padding(
      padding: EdgeInsets.all(d.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.symmetric(
                  horizontal: d.sm,
                  vertical: d.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: d.selection,
                  borderRadius: BorderRadius.circular(d.radiusControl),
                  border: Border.all(color: d.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthLabel,
                      style: d.badge.copyWith(color: d.primary),
                    ),
                    Text(
                      dayLabel,
                      style: d.cardTitle.copyWith(
                        color: d.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: d.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: d.cardTitle,
                      softWrap: true,
                    ),
                    if (badgeWidget != null) ...[
                      SizedBox(height: d.xs),
                      badgeWidget,
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: d.gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  weight: 300,
                  color: d.mutedForeground,
                ),
              ),
              SizedBox(width: d.xs + 2),
              Expanded(
                child: Text(
                  event.venue,
                  style: d.supporting,
                  softWrap: true,
                ),
              ),
            ],
          ),
          SizedBox(height: d.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  LucideIcons.clock,
                  size: 16,
                  weight: 300,
                  color: d.mutedForeground,
                ),
              ),
              SizedBox(width: d.xs + 2),
              Expanded(
                child: Text(
                  '${event.eventDate} • ${event.startTime}',
                  style: d.supporting,
                  softWrap: true,
                ),
              ),
            ],
          ),
          if (showCapacity && trailingAction == null) ...[
            Divider(height: d.lg, color: d.border),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: d.muted,
                  color: progress >= 1.0 ? d.warning : d.primary,
                ),
              ),
              SizedBox(height: d.sm),
            ],
            Text(
              'Registered: $registered${maxCap != null ? ' / $maxCap' : ''}',
              style: d.supporting.copyWith(
                fontWeight: FontWeight.w600,
                color: d.foreground,
              ),
            ),
          ],
        ],
      ),
    );

    final interactiveMainInfo = onTap != null
        ? AppPressable(
            semanticLabel: '${event.title}, ${event.venue}, ${event.eventDate}',
            onPressed: onTap,
            child: mainInfoContent,
          )
        : mainInfoContent;

    return Container(
      margin: EdgeInsets.only(bottom: d.gap),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          interactiveMainInfo,
          if (trailingAction != null) ...[
            Divider(height: 1, color: d.border),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: d.md,
                vertical: d.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress != null && showCapacity) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: d.muted,
                        color: progress >= 1.0 ? d.warning : d.primary,
                      ),
                    ),
                    SizedBox(height: d.sm),
                  ],
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: d.sm,
                    runSpacing: d.sm,
                    children: [
                      if (showCapacity)
                        Text(
                          'Registered: $registered${maxCap != null ? ' / $maxCap' : ''}',
                          style: d.supporting.copyWith(
                            fontWeight: FontWeight.w600,
                            color: d.foreground,
                          ),
                        ),
                      trailingAction!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


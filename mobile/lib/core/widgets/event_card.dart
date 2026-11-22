import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../models/event_model.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';
import 'status_badge.dart';

/// Reusable card for rendering an [EventModel] across student, organizer,
/// management, and administrator lists.
class EventCard extends StatefulWidget {
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

  static String formatSingleTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final parsedIso = DateTime.tryParse(trimmed);
    if (parsedIso != null && trimmed.contains('T')) {
      return DateFormat('hh:mm a').format(parsedIso);
    }

    final timeMatch = RegExp(
      r'(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?',
    ).firstMatch(trimmed);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1)!) ?? 0;
      final minute = int.tryParse(timeMatch.group(2)!) ?? 0;
      final meridiem = timeMatch.group(3);
      if (meridiem != null && meridiem.isNotEmpty) {
        final h = hour.toString().padLeft(2, '0');
        final m = minute.toString().padLeft(2, '0');
        return '$h:$m ${meridiem.toUpperCase()}';
      }
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }

    return trimmed.replaceFirst(RegExp(r'^\d{4}-\d{2}-\d{2}[T\s]\S*\s*'), '');
  }

  static String formatTimeRange(String startTime, String endTime) {
    final start = formatSingleTime(startTime);
    final end = formatSingleTime(endTime);
    if (start.isNotEmpty && end.isNotEmpty && start != end) {
      return '$start - $end';
    }
    if (start.isNotEmpty) return start;
    return end;
  }

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isHovered = false;

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
    final event = widget.event;
    final maxCap = event.maxParticipants;
    final registered = event.currentRegisteredCount;
    final progress = (maxCap != null && maxCap > 0)
        ? (registered / maxCap).clamp(0.0, 1.0)
        : null;
    final (monthLabel, dayLabel) = _parseDateTile(event.eventDate);
    final cleanTimeText = EventCard.formatTimeRange(event.startTime, event.endTime);
    final isScaledText = MediaQuery.textScalerOf(context).scale(1) > 1.25;

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
            : widget.showEventStatusBadge
                ? StatusBadge(status: event.status)
                : null;

    final categoryBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: d.foreground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        event.category.toUpperCase(),
        style: TextStyle(
          color: d.background,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );

    final audienceBadge = Container(
      constraints: BoxConstraints(maxWidth: isScaledText ? 120 : 180),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: d.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.users,
            size: 10,
            color: d.mutedForeground,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              event.audienceSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: d.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final mainInfoContent = Column(
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
                color: d.authSurface,
                borderRadius: BorderRadius.circular(d.radiusControl),
                border: Border.all(color: d.border, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthLabel,
                    style: d.badge.copyWith(color: d.authDark),
                  ),
                  Text(
                    dayLabel,
                    style: d.cardTitle.copyWith(
                      color: d.authDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: d.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        event.title,
                        style: d.cardTitle,
                        maxLines: isScaledText ? null : 2,
                        overflow: isScaledText ? null : TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ),
                  if (badgeWidget != null) ...[
                    SizedBox(height: d.sm),
                    badgeWidget,
                  ],
                  SizedBox(height: d.xs),
                  Wrap(
                    spacing: d.xs,
                    runSpacing: d.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      categoryBadge,
                      audienceBadge,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: d.gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 16,
              weight: 300,
              color: d.primary,
            ),
            SizedBox(width: d.sm),
            Expanded(
              child: Text(
                event.venue,
                style: d.body.copyWith(
                  fontSize: 14,
                  color: d.mutedForeground,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
        SizedBox(height: d.gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              weight: 300,
              color: d.primary,
            ),
            SizedBox(width: d.sm),
            Expanded(
              child: Text(
                cleanTimeText,
                style: d.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: d.foreground,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );

    final interactiveMainInfo = widget.onTap != null
        ? AppPressable(
            semanticLabel: '${event.title}, ${event.venue}, $cleanTimeText',
            onPressed: widget.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: mainInfoContent,
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: mainInfoContent,
          );

    final hasFooter = widget.showCapacity || widget.trailingAction != null;

    final cardBorderColor = _isHovered
        ? (d.isDark
            ? d.foreground.withValues(alpha: 0.35)
            : d.foreground.withValues(alpha: 0.22))
        : d.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(d.lg),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            interactiveMainInfo,
            if (hasFooter)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress != null && widget.showCapacity) ...[
                    SizedBox(height: d.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: d.muted,
                        color: progress >= 1.0 ? d.warning : d.primary,
                      ),
                    ),
                    SizedBox(height: d.md),
                  ] else
                    SizedBox(height: d.md),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: d.sm,
                    runSpacing: d.sm,
                    children: [
                      if (widget.showCapacity)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Registered: $registered${maxCap != null ? ' / $maxCap' : ''}',
                              style: d.supporting.copyWith(
                                fontWeight: FontWeight.w600,
                                color: d.foreground,
                              ),
                            ),
                          ),
                        ),
                      if (widget.trailingAction != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 36),
                          child: widget.trailingAction!,
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

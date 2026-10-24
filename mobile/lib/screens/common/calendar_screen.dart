import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../models/event_model.dart';
import '../student/event_detail_screen.dart';
import 'notifications_screen.dart';

/// Strict monochrome color palette for the Attendify Calendar.
abstract final class CalendarBwPalette {
  static const primaryBlack = Color(0xFF09090B);
  static const darkSurfaces = Color(0xFF121214);
  static const primaryWhite = Color(0xFFFFFFFF);
  static const lightBackground = Color(0xFFFAFAFA);
  static const secondaryGray = Color(0xFFF4F4F5);
  static const borders = Color(0xFFE4E4E7);
  static const mutedText = Color(0xFF71717A);
  static const darkModeBorders = Color(0xFF27272A);
  static const subtleDarkGray = Color(0xFFA1A1AA);
}

/// A shared black-and-white event calendar screen available to all roles.
///
/// When [initialEvents] is provided, the widget skips all API calls and
/// uses the supplied events directly. This is intended for widget-test
/// injection.
///
/// Set [embedded] to `true` when embedding this screen inside a parent
/// scaffold; the widget will then adapt its root layout cleanly.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.embedded = false,
    this.initialEvents,
    this.initialUnreadNotifications,
  });

  /// Whether the screen is embedded inside another scaffold.
  final bool embedded;

  /// Pre-loaded events for widget-test injection — skips API calls entirely.
  final List<EventModel>? initialEvents;

  /// Pre-loaded unread notifications count for widget-test injection.
  final int? initialUnreadNotifications;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final Map<DateTime, List<EventModel>> _eventsByDay = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentMonthKey = '';
  int _unreadNotifications = 0;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _unreadNotifications = widget.initialUnreadNotifications ?? 0;
    if (widget.initialEvents != null) {
      _bucketEvents(widget.initialEvents!);
      // Auto-select today when there are events on today's date.
      final todayKey = _dayKey(DateTime.now());
      if (_eventsByDay.containsKey(todayKey)) {
        _selectedDay = DateTime.now();
      }
      _isLoading = false;
    } else {
      _loadEventsForMonth(_focusedDay);
      _fetchUnreadNotifications();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers & Data loading
  // ──────────────────────────────────────────────────────────────────────────

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  void _bucketEvents(List<EventModel> events) {
    _eventsByDay.clear();
    for (final event in events) {
      final parsed = DateTime.tryParse(event.eventDate);
      if (parsed == null) continue;
      final key = _dayKey(parsed);
      _eventsByDay.putIfAbsent(key, () => []).add(event);
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final res = await ApiClient().get(ApiConstants.notifications);
      if (res.success && res.data is List && mounted) {
        final unread = (res.data as List)
            .where((n) => n is Map && (n['is_read'] != true && n['is_read'] != 1))
            .length;
        setState(() => _unreadNotifications = unread);
      }
    } catch (_) {}
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final monthKey =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // Guard: skip if already loaded for this month.
    if (_currentMonthKey == monthKey) return;

    setState(() {
      _currentMonthKey = monthKey;
      _isLoading = true;
      _errorMessage = null;
    });

    final dateFrom =
        DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month, 1));
    final dateTo = DateFormat('yyyy-MM-dd')
        .format(DateTime(month.year, month.month + 1, 0));

    final response = await ApiClient().get(
      ApiConstants.events,
      queryParams: {
        'date_from': dateFrom,
        'date_to': dateTo,
        'per_page': '100',
      },
    );

    if (!mounted) return;

    if (response.success && response.data is List) {
      final events = (response.data as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _bucketEvents(events);
    } else {
      _errorMessage = response.message ?? 'Failed to load events.';
    }

    setState(() => _isLoading = false);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Calendar callbacks
  // ──────────────────────────────────────────────────────────────────────────

  List<EventModel> _getEventsForDay(DateTime day) {
    return _eventsByDay[_dayKey(day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() => _calendarFormat = format);
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    _loadEventsForMonth(focusedDay);
  }

  void _onPrevPage() {
    setState(() {
      if (_calendarFormat == CalendarFormat.month) {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      } else {
        _focusedDay = _focusedDay.subtract(const Duration(days: 7));
      }
    });
    _loadEventsForMonth(_focusedDay);
  }

  void _onNextPage() {
    setState(() {
      if (_calendarFormat == CalendarFormat.month) {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      } else {
        _focusedDay = _focusedDay.add(const Duration(days: 7));
      }
    });
    _loadEventsForMonth(_focusedDay);
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
    _loadEventsForMonth(DateTime.now());
  }

  void _openEventDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(eventId: event.id, event: event),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted && widget.initialEvents == null) {
      _fetchUnreadNotifications();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;

    final scrollable = CustomScrollView(
      key: const PageStorageKey<String>('calendar-scroll-view'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Branded App Header ──────────────────────────────────────────
              if (!widget.embedded) _buildAppHeader(context),

              // ── Calendar Toolbar & View Selector ─────────────────────────────
              _buildCalendarToolbar(context),

              // ── 7-Column Calendar Grid ──────────────────────────────────────
              _buildCalendarGrid(context),

              // Divider
              Divider(
                height: 1,
                color: isDark
                    ? CalendarBwPalette.darkModeBorders
                    : CalendarBwPalette.borders,
              ),
            ],
          ),
        ),

        // ── Event list for selected date (or empty/loading/error state) ───────
        ..._buildEventSlivers(context),

        // ── Bottom Clearance Padding ─────────────────────────────────────────
        // Prevents bottom navigation bar from covering the last event card
        SliverPadding(
          padding: EdgeInsets.only(bottom: d.xl + 48),
        ),
      ],
    );

    final scrollConfigured = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: scrollable,
    );

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: scrollConfigured,
      ),
    );

    if (widget.embedded) {
      return Container(
        color: isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.lightBackground,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.lightBackground,
      body: SafeArea(
        child: content,
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;
    final fg = isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
      decoration: BoxDecoration(
        color: isDark ? CalendarBwPalette.darkSurfaces : CalendarBwPalette.primaryWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? CalendarBwPalette.darkModeBorders : CalendarBwPalette.borders,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attendify Logo mark badge
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/logo_mark.png',
              fit: BoxFit.contain,
              color: isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.primaryWhite,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (_, __, ___) => Icon(
                LucideIcons.calendarDays,
                color: isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.primaryWhite,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attendify',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: fg,
                  ),
                ),
                const Text(
                  'Event Calendar • Browse campus events by schedule',
                  style: TextStyle(
                    fontSize: 11,
                    color: CalendarBwPalette.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification Bell with unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: const ValueKey('calendar-notifications-btn'),
                icon: Icon(LucideIcons.bell, size: 20, color: fg),
                tooltip: 'Notifications',
                onPressed: _openNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    key: const ValueKey('calendar-notifications-badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isDark
                            ? CalendarBwPalette.darkSurfaces
                            : CalendarBwPalette.primaryWhite,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                      style: TextStyle(
                        color: isDark
                            ? CalendarBwPalette.primaryBlack
                            : CalendarBwPalette.primaryWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarToolbar(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;
    final fg = isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;

          final monthNav = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('calendar-prev-btn'),
                icon: Icon(LucideIcons.chevronLeft, size: 18, color: fg),
                tooltip: 'Previous',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                onPressed: _onPrevPage,
              ),
              Flexible(
                child: Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: d.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const ValueKey('calendar-next-btn'),
                icon: Icon(LucideIcons.chevronRight, size: 18, color: fg),
                tooltip: 'Next',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                onPressed: _onNextPage,
              ),
            ],
          );

          final viewSelector = Container(
            decoration: BoxDecoration(
              color: isDark
                  ? CalendarBwPalette.darkModeBorders
                  : CalendarBwPalette.secondaryGray,
              borderRadius: BorderRadius.circular(d.radiusControl),
              border: Border.all(
                color: isDark
                    ? CalendarBwPalette.darkModeBorders
                    : CalendarBwPalette.borders,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewTab(
                  label: 'Month',
                  isSelected: _calendarFormat == CalendarFormat.month,
                  onTap: () => setState(() => _calendarFormat = CalendarFormat.month),
                ),
                _buildViewTab(
                  label: 'Week',
                  isSelected: _calendarFormat == CalendarFormat.week,
                  onTap: () => setState(() => _calendarFormat = CalendarFormat.week),
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    monthNav,
                    AppButton(
                      variant: AppButtonVariant.outline,
                      pill: true,
                      label: 'Today',
                      onPressed: _goToToday,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: viewSelector),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              monthNav,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  viewSelector,
                  const SizedBox(width: 8),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    pill: true,
                    label: 'Today',
                    onPressed: _goToToday,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final d = context.design;
    final isDark = d.isDark;
    final bg = isSelected
        ? (isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack)
        : Colors.transparent;
    final fg = isSelected
        ? (isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.primaryWhite)
        : CalendarBwPalette.mutedText;

    return AppPressable(
      onPressed: onTap,
      semanticLabel: '$label view',
      child: Container(
        key: ValueKey('calendar-format-${label.toLowerCase()}'),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(d.radiusControl),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: d.supporting.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;
    final fg = isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack;
    final cardBg = isDark ? CalendarBwPalette.darkSurfaces : CalendarBwPalette.primaryWhite;
    final cardBorder = isDark ? CalendarBwPalette.darkModeBorders : CalendarBwPalette.borders;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: d.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: CalendarBwPalette.primaryBlack.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: TableCalendar<EventModel>(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        eventLoader: _getEventsForDay,
        onDaySelected: _onDaySelected,
        onFormatChanged: _onFormatChanged,
        onPageChanged: _onPageChanged,
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: 28,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
          weekendTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
          selectedDecoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: isDark ? CalendarBwPalette.primaryBlack : CalendarBwPalette.primaryWhite,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          todayDecoration: BoxDecoration(
            border: Border.all(color: fg, width: 1.5),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          markerDecoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1.2),
          markersMaxCount: 3,
          markersAlignment: Alignment.bottomCenter,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          dowTextFormatter: (date, locale) =>
              DateFormat.E(locale).format(date).toUpperCase(),
          weekdayStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CalendarBwPalette.mutedText,
            letterSpacing: 0.5,
          ),
          weekendStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CalendarBwPalette.mutedText,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventSlivers(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;
    final fg = isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack;

    if (_isLoading && _eventsByDay.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: AppSpinner()),
          ),
        ),
      ];
    }

    if (_errorMessage != null && _eventsByDay.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(d.md),
            child: ErrorStateView(
              message: _errorMessage!,
              onRetry: () => _loadEventsForMonth(_focusedDay),
            ),
          ),
        ),
      ];
    }

    if (_selectedDay == null) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyStateView(
              icon: LucideIcons.calendarDays,
              title: 'Select a Day',
              message: 'Tap any date to view events.',
            ),
          ),
        ),
      ];
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: EmptyStateView(
              icon: LucideIcons.calendarX2,
              title: 'No events',
              message: 'No events scheduled on this day.',
            ),
          ),
        ),
      ];
    }

    final dayHeader = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dayHeader,
                  style: d.cardTitle.copyWith(
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? CalendarBwPalette.darkModeBorders
                      : CalendarBwPalette.secondaryGray,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isDark
                        ? CalendarBwPalette.darkModeBorders
                        : CalendarBwPalette.borders,
                  ),
                ),
                child: Text(
                  '${events.length} EVENT${events.length == 1 ? '' : 'S'}',
                  style: d.badge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: d.md),
        sliver: SliverList.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return _BwEventCard(
              event: e,
              onTap: () => _openEventDetail(e),
            );
          },
        ),
      ),
    ];
  }
}

/// Strictly black-and-white event card with monochrome category icon, status pill,
/// location, time, and chevron navigation indicator.
class _BwEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _BwEventCard({
    required this.event,
    required this.onTap,
  });

  static IconData _categoryIconForEvent(EventModel event) {
    final text = '${event.title} ${event.description} ${event.venue}'.toLowerCase();
    if (text.contains('workshop') ||
        text.contains('training') ||
        text.contains('build') ||
        text.contains('lab')) {
      return LucideIcons.wrench;
    }
    if (text.contains('academic') ||
        text.contains('lecture') ||
        text.contains('exam') ||
        text.contains('class') ||
        text.contains('summit') ||
        text.contains('symposium')) {
      return LucideIcons.graduationCap;
    }
    if (text.contains('tech') ||
        text.contains('code') ||
        text.contains('hackathon') ||
        text.contains('dev') ||
        text.contains('computer')) {
      return LucideIcons.laptop;
    }
    if (text.contains('sport') ||
        text.contains('tournament') ||
        text.contains('match') ||
        text.contains('game') ||
        text.contains('championship')) {
      return LucideIcons.trophy;
    }
    if (text.contains('art') ||
        text.contains('culture') ||
        text.contains('music') ||
        text.contains('dance') ||
        text.contains('concert') ||
        text.contains('festival')) {
      return LucideIcons.palette;
    }
    if (text.contains('club') ||
        text.contains('meetup') ||
        text.contains('social') ||
        text.contains('assembly') ||
        text.contains('fair')) {
      return LucideIcons.users;
    }
    return LucideIcons.calendarDays;
  }

  static String _categoryLabelForEvent(EventModel event) {
    final text = '${event.title} ${event.description} ${event.venue}'.toLowerCase();
    if (text.contains('workshop') || text.contains('training')) {
      return 'WORKSHOP';
    }
    if (text.contains('academic') ||
        text.contains('lecture') ||
        text.contains('summit') ||
        text.contains('symposium')) {
      return 'ACADEMIC';
    }
    if (text.contains('tech') || text.contains('hackathon')) {
      return 'TECH';
    }
    if (text.contains('sport') || text.contains('tournament')) {
      return 'SPORTS';
    }
    if (text.contains('art') || text.contains('music') || text.contains('festival')) {
      return 'ARTS & CULTURE';
    }
    if (text.contains('club') || text.contains('social')) {
      return 'COMMUNITY';
    }
    return 'EVENT';
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final isDark = d.isDark;
    final cardBg = isDark ? CalendarBwPalette.darkSurfaces : CalendarBwPalette.primaryWhite;
    final cardBorder = isDark ? CalendarBwPalette.darkModeBorders : CalendarBwPalette.borders;
    final iconBg = isDark ? CalendarBwPalette.darkModeBorders : CalendarBwPalette.secondaryGray;
    final primaryColor = isDark ? CalendarBwPalette.primaryWhite : CalendarBwPalette.primaryBlack;
    final badgeBg = isDark ? CalendarBwPalette.darkModeBorders : CalendarBwPalette.secondaryGray;

    final icon = _categoryIconForEvent(event);
    final categoryLabel = _categoryLabelForEvent(event);
    final statusText = event.status.replaceAll('_', ' ').toUpperCase();

    final maxCap = event.maxParticipants;
    final registered = event.currentRegisteredCount;
    final progress = (maxCap != null && maxCap > 0)
        ? (registered / maxCap).clamp(0.0, 1.0)
        : null;

    final formattedTime = event.startTime.isNotEmpty
        ? (event.endTime.isNotEmpty
            ? '${event.startTime.length >= 5 ? event.startTime.substring(0, 5) : event.startTime} - ${event.endTime.length >= 5 ? event.endTime.substring(0, 5) : event.endTime}'
            : event.startTime)
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: d.gap),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: CalendarBwPalette.primaryBlack.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: AppPressable(
        onPressed: onTap,
        semanticLabel: '${event.title}, $categoryLabel, ${event.venue}',
        child: Padding(
          padding: EdgeInsets.all(d.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top-left icon aligned and centered with title + badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: primaryColor,
                        ),
                        SizedBox(width: d.sm),
                        Expanded(
                          child: Text(
                            event.title,
                            style: d.cardTitle.copyWith(
                              color: primaryColor,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: d.xs),
                    // Category & Status row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          categoryLabel,
                          style: d.badge.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: CalendarBwPalette.mutedText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(d.radiusControl),
                            border: Border.all(color: cardBorder, width: 1),
                          ),
                          child: Text(
                            statusText,
                            style: d.badge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Venue & Time
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (formattedTime.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: primaryColor,
                              ),
                              SizedBox(width: d.xs),
                              Flexible(
                                child: Text(
                                  formattedTime,
                                  style: d.supporting.copyWith(
                                    color: CalendarBwPalette.mutedText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: primaryColor,
                            ),
                            SizedBox(width: d.xs),
                            Flexible(
                              child: Text(
                                event.venue,
                                style: d.supporting.copyWith(
                                  color: CalendarBwPalette.mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(d.radiusControl),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: iconBg,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: $registered / $maxCap',
                        style: d.supporting.copyWith(
                          fontWeight: FontWeight.w500,
                          color: CalendarBwPalette.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: d.sm),
              // Chevron indicator matched to primary theme color
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

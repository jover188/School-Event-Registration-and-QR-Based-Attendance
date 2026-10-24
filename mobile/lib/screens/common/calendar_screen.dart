import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/event_card.dart';
import '../../models/event_model.dart';
import '../student/event_detail_screen.dart';

/// A shared event calendar screen available to all roles.
///
/// When [initialEvents] is provided, the widget skips all API calls and
/// uses the supplied events directly. This is intended for widget-test
/// injection.
///
/// Set [embedded] to `true` when embedding this screen inside a parent
/// scaffold; the widget will then render a plain [Column] instead of
/// wrapping itself in [AppResponsivePage].
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.embedded = false, this.initialEvents});

  /// Whether the screen is embedded inside another scaffold.
  final bool embedded;

  /// Pre-loaded events for widget-test injection — skips API calls entirely.
  final List<EventModel>? initialEvents;

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

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
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
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
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

  // ──────────────────────────────────────────────────────────────────────────
  // Data loading
  // ──────────────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    final content = Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: d.md,
            vertical: d.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: d.sectionTitle,
              ),
              SizedBox(height: d.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    variant: AppButtonVariant.ghost,
                    label: 'Week',
                    onPressed: () =>
                        setState(() => _calendarFormat = CalendarFormat.week),
                  ),
                  AppButton(
                    variant: AppButtonVariant.ghost,
                    label: 'Month',
                    onPressed: () =>
                        setState(() => _calendarFormat = CalendarFormat.month),
                  ),
                  const Spacer(),
                  AppButton(
                    variant: AppButtonVariant.outline,
                    pill: true,
                    label: 'Today',
                    onPressed: _goToToday,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Calendar grid ───────────────────────────────────────────────────
        Container(
          color: d.card,
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
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: d.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                border: Border.all(color: d.primary, width: 1.5),
                shape: BoxShape.circle,
              ),
              todayTextStyle: d.supporting.copyWith(
                color: d.primary,
                fontWeight: FontWeight.w700,
              ),
              selectedTextStyle: d.supporting.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markerDecoration: BoxDecoration(
                color: d.success,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: d.badge,
              weekendStyle: d.badge,
            ),
          ),
        ),

        Divider(color: d.border),

        // ── Event list for selected day ──────────────────────────────────────
        Expanded(child: _buildEventList(context)),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      body: AppResponsivePage(child: content),
    );
  }

  Widget _buildEventList(BuildContext context) {
    if (_isLoading && _eventsByDay.isEmpty) {
      return const Center(child: AppSpinner());
    }

    if (_errorMessage != null && _eventsByDay.isEmpty) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: () => _loadEventsForMonth(_focusedDay),
      );
    }

    if (_selectedDay == null) {
      return const EmptyStateView(
        icon: LucideIcons.calendarDays,
        title: 'Select a Day',
        message: 'Tap any date to view events.',
      );
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.calendarX2,
        title: 'No events',
        message: 'No events scheduled on this day.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.design.md),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        return EventCard(
          event: e,
          showEventStatusBadge: true,
          showCapacity: true,
          onTap: () => _openEventDetail(e),
        );
      },
    );
  }
}

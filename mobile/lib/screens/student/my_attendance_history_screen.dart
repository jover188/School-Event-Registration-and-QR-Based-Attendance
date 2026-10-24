import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';

class MyAttendanceHistoryScreen extends StatefulWidget {
  final bool embedded;
  final List<Map<String, dynamic>>? initialRecords;
  final String? initialErrorMessage;

  const MyAttendanceHistoryScreen({
    super.key,
    this.embedded = false,
    this.initialRecords,
    this.initialErrorMessage,
  });

  @override
  State<MyAttendanceHistoryScreen> createState() =>
      _MyAttendanceHistoryScreenState();
}

class _MyAttendanceHistoryScreenState extends State<MyAttendanceHistoryScreen> {
  static const List<({String label, String value})> _filters = [
    (label: 'All', value: 'all'),
    (label: 'Present', value: 'present'),
    (label: 'Late', value: 'late'),
    (label: 'Walk-In', value: 'walk_in'),
    (label: 'Excused', value: 'excused'),
  ];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _records = [];

  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedFilter == 'all') return _records;
    return _records
        .where((rec) => rec['status']?.toString() == _selectedFilter)
        .toList();
  }

  bool get _hasFixtureData =>
      widget.initialRecords != null || widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtureData) {
      _isLoading = false;
      _errorMessage = widget.initialErrorMessage;
      _records = (widget.initialRecords ?? const [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    if (_hasFixtureData && widget.initialRecords != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _records = widget.initialRecords!
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response =
        await ApiClient().get(ApiConstants.studentAttendanceHistory);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _records = (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (!response.success) {
        _errorMessage =
            response.message ?? 'Failed to load your attendance history.';
      }
    });
  }

  Future<void> _openAttendanceEventDetail(Map<String, dynamic> record) async {
    final eventMap = Map<String, dynamic>.from(
      (record['event'] as Map?) ?? const {},
    );
    final eventId =
        (record['event_id'] as num? ?? eventMap['id'] as num? ?? 0).toInt();
    if (eventId <= 0 && eventMap.isEmpty) return;

    eventMap['id'] ??= eventId;
    final model = EventModel.fromJson(eventMap);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          eventId: eventId > 0 ? eventId : model.id,
          event: model,
          initialEvent: _hasFixtureData ? model : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final items = _filteredRecords;

    return AppPageScaffold(
      title: 'Attendance History',
      embedded: widget.embedded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(bottom: d.gap),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter.value;
                  return Padding(
                    padding: EdgeInsets.only(right: d.sm),
                    child: ChoiceChip(
                      key: ValueKey('attendance-filter-${filter.value}'),
                      label: Text(filter.label),
                      selected: isSelected,
                      selectedColor: d.buttonPrimary,
                      backgroundColor: d.card,
                      labelStyle: d.supporting.copyWith(
                        color: isSelected
                            ? d.buttonPrimaryForeground
                            : d.foreground,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? d.buttonPrimary : d.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(d.radiusControl),
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter.value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: AppSpinner(
                      size: 28,
                      color: d.authDark,
                    ),
                  )
                : _errorMessage != null && _records.isEmpty
                    ? ErrorStateView(
                        message: _errorMessage!,
                        onRetry: _fetchHistory,
                      )
                    : items.isEmpty
                        ? EmptyStateView(
                            icon: LucideIcons.clipboardCheck,
                            title: _selectedFilter == 'all'
                                ? 'No attendance records yet'
                                : 'No matching attendance records',
                            message: _selectedFilter == 'all'
                                ? 'Show your QR code at events to record attendance.'
                                : 'No records with this status.',
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchHistory,
                            child: CustomScrollView(
                              slivers: [
                                ResponsiveCardSliver(
                                  itemCount: items.length,
                                  minItemWidth: 340,
                                  maxColumns: 2,
                                  itemBuilder: (context, index) {
                                    final record = items[index];
                                    return _AttendanceHistoryCard(
                                      record: record,
                                      onTap: () =>
                                          _openAttendanceEventDetail(record),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback? onTap;

  const _AttendanceHistoryCard({
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final status = record['status']?.toString() ?? 'present';
    final checkInTime = record['check_in_time']?.toString() ?? 'N/A';
    final checkOutTime = record['check_out_time']?.toString();
    final hasCheckOut = checkOutTime != null && checkOutTime.trim().isNotEmpty;
    final event = (record['event'] as Map<String, dynamic>?) ?? {};
    final title = event['title']?.toString() ?? 'Campus Event';
    final venue = event['venue']?.toString() ?? 'Campus Venue';
    final eventDate = event['event_date']?.toString() ?? '';

    final cardContent = Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
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
                LucideIcons.clipboardCheck,
                size: 18,
                color: d.primary,
              ),
              SizedBox(width: d.sm),
              Expanded(
                child: Text(
                  title,
                  style: d.cardTitle,
                ),
              ),
              SizedBox(width: d.sm),
              StatusBadge(status: status),
            ],
          ),
          SizedBox(height: d.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 16,
                color: d.primary,
              ),
              SizedBox(width: d.sm),
              Expanded(
                child: Text(
                  eventDate.isNotEmpty ? '$eventDate • $venue' : venue,
                  style: d.supporting,
                  softWrap: true,
                ),
              ),
            ],
          ),
          Divider(
            height: d.lg,
            color: d.border,
          ),
          ResponsiveGrid(
            minItemWidth: 160,
            maxColumns: 2,
            spacing: d.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-In', style: d.supporting),
                  const SizedBox(height: 2),
                  Text(
                    checkInTime,
                    style: d.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-Out', style: d.supporting),
                  const SizedBox(height: 2),
                  Text(
                    hasCheckOut ? checkOutTime : 'Not checked out',
                    style: d.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasCheckOut ? d.foreground : d.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return AppPressable(
        semanticLabel: '$title, $status',
        onPressed: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

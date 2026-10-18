import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _records = [];

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

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AppPageScaffold(
      title: 'Attendance History',
      embedded: widget.embedded,
      actions: [
        IconButton(
          tooltip: 'Refresh Attendance History',
          icon: Icon(LucideIcons.refreshCw, size: 18, color: d.foreground),
          onPressed: _isLoading ? null : _fetchHistory,
        ),
      ],
      body: _isLoading
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
              : _records.isEmpty
                  ? EmptyStateView(
                      icon: LucideIcons.clipboardCheck,
                      title: 'No attendance records yet',
                      message:
                          'Present your permanent student QR code at campus events to record check-ins and check-outs.',
                      actionLabel: 'Refresh',
                      onAction: _fetchHistory,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      child: CustomScrollView(
                        slivers: [
                          ResponsiveCardSliver(
                            itemCount: _records.length,
                            minItemWidth: 340,
                            maxColumns: 2,
                            itemBuilder: (context, index) {
                              return _AttendanceHistoryCard(
                                record: _records[index],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _AttendanceHistoryCard({required this.record});

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

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: d.sm,
            runSpacing: d.xs,
            children: [
              Text(
                title,
                style: d.cardTitle,
              ),
              StatusBadge(status: status),
            ],
          ),
          SizedBox(height: d.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 15,
                color: d.mutedForeground,
              ),
              SizedBox(width: d.xs),
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
            color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
          ),
          ResponsiveGrid(
            minItemWidth: 160,
            maxColumns: 2,
            spacing: d.sm,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-In Time', style: d.supporting),
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
                  Text('Check-Out Time', style: d.supporting),
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
  }
}

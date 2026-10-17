import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class MyAttendanceHistoryScreen extends StatefulWidget {
  const MyAttendanceHistoryScreen({super.key});

  @override
  State<MyAttendanceHistoryScreen> createState() =>
      _MyAttendanceHistoryScreenState();
}

class _MyAttendanceHistoryScreenState extends State<MyAttendanceHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            tooltip: 'Refresh Attendance History',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _records.isEmpty
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchHistory,
                  )
                : _records.isEmpty
                    ? EmptyStateView(
                        icon: Icons.fact_check_outlined,
                        title: 'No attendance records yet',
                        message:
                            'Present your permanent student QR code at campus events to record check-ins and check-outs.',
                        actionLabel: 'Refresh',
                        onAction: _fetchHistory,
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            return _AttendanceHistoryCard(
                              record: _records[index],
                            );
                          },
                        ),
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
    final status = record['status']?.toString() ?? 'present';
    final checkInTime = record['check_in_time']?.toString() ?? 'N/A';
    final checkOutTime = record['check_out_time']?.toString();
    final event = (record['event'] as Map<String, dynamic>?) ?? {};
    final title = event['title']?.toString() ?? 'Campus Event';
    final venue = event['venue']?.toString() ?? 'Campus Venue';
    final eventDate = event['event_date']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
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
                    title,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(status: status),
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
                    eventDate.isNotEmpty ? '$eventDate • $venue' : venue,
                    style: AppTypography.bodyMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-In Time',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        checkInTime,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-Out Time',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        checkOutTime != null && checkOutTime.isNotEmpty
                            ? checkOutTime
                            : 'Not checked out',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: checkOutTime != null && checkOutTime.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/reports_screen.dart';
import '../organizer/event_registrations_screen.dart';
import '../organizer/live_attendance_screen.dart';

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _statusBreakdown = {};
  List<dynamic> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.managementDashboard);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success && response.data is Map<String, dynamic>) {
      setState(() {
        _metrics =
            (response.data['overall_metrics'] as Map<String, dynamic>?) ?? {};
        _statusBreakdown =
            (response.data['attendance_by_status'] as Map<String, dynamic>?) ??
                {};
        _recentEvents = (response.data['recent_events'] as List?) ?? [];
      });
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Failed to load management analytics.';
      });
    }
  }

  void _openReports([int? eventId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsScreen(initialEventId: eventId),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiClient().post(ApiConstants.logout, {});
    await ApiClient().clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Management (Read-Only)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Reports & Exports',
            onPressed: () => _openReports(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: _isLoading ? null : _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _metrics.isEmpty
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchData,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                const Expanded(
                                  child: Text(
                                    'Executive Overview: Read-only institutional participation metrics.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openReports(),
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Reports'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Overall Metrics Grid
                          Row(
                            children: [
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Overall Turnout',
                                  value:
                                      '${_metrics['overall_turnout_rate'] ?? '0%'}',
                                  icon: Icons.pie_chart_outline,
                                  color: AppColors.present,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 4),
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Total Events',
                                  value: '${_metrics['total_events'] ?? 0}',
                                  icon: Icons.event_note_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          Row(
                            children: [
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Total Registered',
                                  value:
                                      '${_metrics['total_registrations'] ?? 0}',
                                  icon: Icons.how_to_reg_outlined,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 4),
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Total Attended',
                                  value:
                                      '${_metrics['total_attendances'] ?? 0}',
                                  icon: Icons.verified_user_outlined,
                                  color: AppColors.late,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Attendance Breakdown
                          const SectionHeader(
                            title: 'Attendance Status Breakdown',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  _AttendanceStatusRow(
                                    label: 'Present on Time',
                                    status: 'present',
                                    count: _statusBreakdown['present'] ?? 0,
                                  ),
                                  const Divider(height: AppSpacing.md),
                                  _AttendanceStatusRow(
                                    label: 'Late Arrival',
                                    status: 'late',
                                    count: _statusBreakdown['late'] ?? 0,
                                  ),
                                  const Divider(height: AppSpacing.md),
                                  _AttendanceStatusRow(
                                    label: 'Walk-In Attendees',
                                    status: 'walk_in',
                                    count: _statusBreakdown['walk_in'] ?? 0,
                                  ),
                                  const Divider(height: AppSpacing.md),
                                  _AttendanceStatusRow(
                                    label: 'Excused Absences',
                                    status: 'excused',
                                    count: _statusBreakdown['excused'] ?? 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Recent Events
                          SectionHeader(
                            title: 'Recent Events & Attendance',
                            actionLabel: 'View All Reports',
                            onAction: () => _openReports(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_recentEvents.isEmpty)
                            const EmptyStateView(
                              icon: Icons.analytics_outlined,
                              title: 'No recent events recorded.',
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentEvents.length,
                              itemBuilder: (ctx, i) {
                                final e =
                                    _recentEvents[i] as Map<String, dynamic>;
                                return _ManagementEventReadOnlyCard(
                                  eventMap: e,
                                  onViewRegistrations: (eventId, title) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EventRegistrationsScreen(
                                          eventId: eventId,
                                          eventTitle: title,
                                          canCancel: false,
                                        ),
                                      ),
                                    );
                                  },
                                  onViewAttendance: (eventId, title) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LiveAttendanceScreen(
                                          eventId: eventId,
                                          eventTitle: title,
                                          canCorrect: false,
                                        ),
                                      ),
                                    );
                                  },
                                  onOpenReports: (eventId) =>
                                      _openReports(eventId),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _AttendanceStatusRow extends StatelessWidget {
  final String label;
  final String status;
  final dynamic count;

  const _AttendanceStatusRow({
    required this.label,
    required this.status,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              StatusBadge(status: status),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ManagementEventReadOnlyCard extends StatelessWidget {
  final Map<String, dynamic> eventMap;
  final void Function(int eventId, String title) onViewRegistrations;
  final void Function(int eventId, String title) onViewAttendance;
  final void Function(int eventId) onOpenReports;

  const _ManagementEventReadOnlyCard({
    required this.eventMap,
    required this.onViewRegistrations,
    required this.onViewAttendance,
    required this.onOpenReports,
  });

  @override
  Widget build(BuildContext context) {
    final eventId = (eventMap['id'] as num?)?.toInt();
    final title = eventMap['title']?.toString() ?? 'Event';
    final eventDate = eventMap['event_date']?.toString().split('T').first ?? '';
    final venue = eventMap['venue']?.toString() ?? '';
    final attendedCount = eventMap['attendances_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.subtitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  status: 'present',
                  label: '$attendedCount ATTENDED',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$eventDate • $venue',
              style: AppTypography.bodyMuted,
            ),
            if (eventId != null) ...[
              const Divider(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onViewRegistrations(eventId, title),
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: const Text(
                      'Registrations (RO)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onViewAttendance(eventId, title),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text(
                      'Attendance (RO)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onOpenReports(eventId),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text(
                      'Reports',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

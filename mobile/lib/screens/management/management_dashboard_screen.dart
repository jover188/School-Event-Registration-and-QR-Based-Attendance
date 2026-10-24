import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/navigation/app_destination.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/calendar_screen.dart';
import '../common/profile_screen.dart';
import '../common/reports_screen.dart';
import '../organizer/event_registrations_screen.dart';
import '../organizer/live_attendance_screen.dart';

class ManagementDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMetrics;
  final Map<String, dynamic>? initialStatusBreakdown;
  final List<dynamic>? initialRecentEvents;
  final String? initialErrorMessage;

  const ManagementDashboardScreen({
    super.key,
    this.initialMetrics,
    this.initialStatusBreakdown,
    this.initialRecentEvents,
    this.initialErrorMessage,
  });

  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  static const List<AppDestination> _destinations = [
    AppDestination(
      id: 'overview',
      label: 'Overview',
      icon: LucideIcons.layoutDashboard,
      essential: true,
    ),
    AppDestination(
      id: 'events',
      label: 'Events',
      icon: LucideIcons.calendarRange,
    ),
    AppDestination(
      id: 'calendar',
      label: 'Calendar',
      icon: LucideIcons.calendarDays,
    ),
    AppDestination(
      id: 'reports',
      label: 'Reports',
      icon: LucideIcons.chartBar,
      essential: true,
    ),
  ];

  String _selectedDestination = 'overview';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _statusBreakdown = {};
  List<dynamic> _recentEvents = [];

  late final TextEditingController _eventSearchController =
      TextEditingController();
  String _eventSearchQuery = '';

  bool get _hasFixtures =>
      widget.initialMetrics != null ||
      widget.initialStatusBreakdown != null ||
      widget.initialRecentEvents != null ||
      widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtures) {
      _isLoading = false;
      _metrics = Map<String, dynamic>.from(widget.initialMetrics ?? const {});
      _statusBreakdown = Map<String, dynamic>.from(
        widget.initialStatusBreakdown ?? const {},
      );
      _recentEvents = List<dynamic>.from(
        widget.initialRecentEvents ?? const [],
      );
      _errorMessage = widget.initialErrorMessage;
    } else {
      _fetchData();
    }
  }

  @override
  void dispose() {
    _eventSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.managementDashboard);

    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _metrics =
            (response.data['overall_metrics'] as Map<String, dynamic>?) ?? {};
        _statusBreakdown =
            (response.data['attendance_by_status'] as Map<String, dynamic>?) ??
                {};
        _recentEvents = (response.data['recent_events'] as List?) ?? [];
      });
    } else if (_hasFixtures && widget.initialMetrics != null) {
      setState(() {
        _isLoading = false;
        _metrics = Map<String, dynamic>.from(widget.initialMetrics!);
        _statusBreakdown = Map<String, dynamic>.from(
          widget.initialStatusBreakdown ?? const {},
        );
        _recentEvents = List<dynamic>.from(
          widget.initialRecentEvents ?? const [],
        );
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            response.message ?? 'Failed to load management analytics.';
      });
    }
  }

  void _openReports([int? eventId]) {
    if (eventId == null) {
      setState(() => _selectedDestination = 'reports');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportsScreen(initialEventId: eventId),
      ),
    );
  }

  void _openEventRegistrations(int eventId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventRegistrationsScreen(
          eventId: eventId,
          eventTitle: title,
          canCancel: false,
        ),
      ),
    );
  }

  void _openEventAttendance(int eventId, String title) {
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

  String get _shellTitle => switch (_selectedDestination) {
        'calendar' => 'Event Calendar',
        'events' => 'Campus Events (Read-Only)',
        'reports' => 'Reports & Analytics',
        _ => 'School Management (Read-Only)',
      };

  List<Map<String, dynamic>> get _filteredEvents {
    final all = _recentEvents.whereType<Map<String, dynamic>>().toList();
    final query = _eventSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((e) {
      final title = (e['title'] ?? '').toString().toLowerCase();
      final venue = (e['venue'] ?? '').toString().toLowerCase();
      final date = (e['event_date'] ?? '').toString().toLowerCase();
      return title.contains(query) ||
          venue.contains(query) ||
          date.contains(query);
    }).toList();
  }

  Widget _buildReadOnlyBanner(BuildContext context, {bool showAction = true}) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.gap),
      decoration: BoxDecoration(
        color: d.selection,
        borderRadius: BorderRadius.circular(d.radiusControl),
        border: Border.all(
          color: d.isDark ? d.border : d.primary.withValues(alpha: 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 460 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          final messageRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, color: d.primary, size: 20),
              SizedBox(width: d.sm),
              Expanded(
                child: Text(
                  'Executive Overview: Read-only institutional participation metrics.',
                  style: d.supporting.copyWith(
                    color: d.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

          if (!showAction) return messageRow;

          final actionBtn = AppButton(
            key: const ValueKey<String>('overview-open-reports-button'),
            variant: AppButtonVariant.ghost,
            pill: true,
            icon: LucideIcons.barChart2,
            label: 'Open Reports',
            onPressed: () => _openReports(),
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                messageRow,
                SizedBox(height: d.sm),
                actionBtn,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: messageRow),
              SizedBox(width: d.sm),
              actionBtn,
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewDestination(BuildContext context) {
    final d = context.design;
    if (_isLoading) {
      return Center(child: AppSpinner(color: d.authDark, size: 28));
    }
    if (_errorMessage != null && _metrics.isEmpty && _recentEvents.isEmpty) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchData,
      );
    }

    final previewEvents =
        _recentEvents.whereType<Map<String, dynamic>>().take(3).toList();

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AppResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyBanner(context),
              if (_errorMessage != null) ...[
                SizedBox(height: d.md),
                Container(
                  padding: EdgeInsets.all(d.gap),
                  decoration: BoxDecoration(
                    color: d.warningBackground,
                    borderRadius: BorderRadius.circular(d.radiusControl),
                    border: Border.all(color: d.warning.withValues(alpha: 0.3)),
                  ),
                  child: Wrap(
                    spacing: d.sm,
                    runSpacing: d.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing cached metrics. ${_errorMessage!}',
                        style: d.supporting.copyWith(color: d.warning),
                      ),
                      AppButton(
                        variant: AppButtonVariant.outline,
                        pill: true,
                        label: 'Retry',
                        icon: LucideIcons.refreshCw,
                        onPressed: _fetchData,
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: d.md),
              ResponsiveGrid(
                minItemWidth: 160,
                maxColumns: 4,
                children: [
                  StatMetricCard(
                    label: 'Overall Turnout',
                    value: '${_metrics['overall_turnout_rate'] ?? '0%'}',
                    icon: LucideIcons.pieChart,
                    color: d.success,
                  ),
                  StatMetricCard(
                    label: 'Total Events',
                    value: '${_metrics['total_events'] ?? 0}',
                    icon: LucideIcons.calendar,
                    color: d.primary,
                  ),
                  StatMetricCard(
                    label: 'Total Registered',
                    value: '${_metrics['total_registrations'] ?? 0}',
                    icon: LucideIcons.users,
                    color: d.information,
                  ),
                  StatMetricCard(
                    label: 'Total Attended',
                    value: '${_metrics['total_attendances'] ?? 0}',
                    icon: LucideIcons.userCheck,
                    color: d.warning,
                  ),
                ],
              ),
              SizedBox(height: d.lg),
              const SectionHeader(
                title: 'Attendance Status Breakdown',
                subtitle: 'Verified check-in outcomes across school events',
              ),
              SizedBox(height: d.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Container(
                  padding: EdgeInsets.all(d.md),
                  decoration: BoxDecoration(
                    color: d.card,
                    borderRadius: BorderRadius.circular(d.radiusCard),
                    border: Border.all(
                      color: d.isDark
                          ? d.border
                          : d.authDark.withValues(alpha: 0.08),
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
                    children: [
                      _AttendanceStatusRow(
                        label: 'Present on Time',
                        status: 'present',
                        count: _statusBreakdown['present'] ?? 0,
                      ),
                      Divider(height: d.md, color: d.border),
                      _AttendanceStatusRow(
                        label: 'Late Arrival',
                        status: 'late',
                        count: _statusBreakdown['late'] ?? 0,
                      ),
                      Divider(height: d.md, color: d.border),
                      _AttendanceStatusRow(
                        label: 'Walk-In Attendees',
                        status: 'walk_in',
                        count: _statusBreakdown['walk_in'] ?? 0,
                      ),
                      Divider(height: d.md, color: d.border),
                      _AttendanceStatusRow(
                        label: 'Excused Absences',
                        status: 'excused',
                        count: _statusBreakdown['excused'] ?? 0,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: d.lg),
              SectionHeader(
                title: 'Recent Events & Attendance',
                subtitle: 'Inspect read-only registration and attendance lists',
                actionLabel: 'Browse All Events',
                onAction: () => setState(() => _selectedDestination = 'events'),
              ),
              SizedBox(height: d.sm),
              if (previewEvents.isEmpty)
                const EmptyStateView(
                  icon: LucideIcons.barChart3,
                  title: 'No recent events recorded.',
                )
              else
                ResponsiveGrid(
                  minItemWidth: 320,
                  maxColumns: 3,
                  spacing: d.md,
                  children: [
                    for (final e in previewEvents)
                      _ManagementEventReadOnlyCard(
                        eventMap: e,
                        onViewRegistrations: _openEventRegistrations,
                        onViewAttendance: _openEventAttendance,
                        onOpenReports: _openReports,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsDestination(BuildContext context) {
    final d = context.design;
    if (_isLoading) {
      return Center(child: AppSpinner(color: d.authDark, size: 28));
    }
    if (_errorMessage != null && _metrics.isEmpty && _recentEvents.isEmpty) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchData,
      );
    }

    final events = _filteredEvents;

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AppResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReadOnlyBanner(context, showAction: false),
              SizedBox(height: d.md),
              SectionHeader(
                title: 'Institutional Events Directory',
                subtitle:
                    'Read-only inspection of event capacity, registrations, and attendance (${events.length} shown)',
                actionLabel: 'View All Reports',
                onAction: () => _openReports(),
              ),
              SizedBox(height: d.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: TextField(
                  key: const ValueKey<String>('management-event-search-field'),
                  controller: _eventSearchController,
                  onChanged: (value) =>
                      setState(() => _eventSearchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Search events by title, venue, or date',
                    hintText: 'Filter institutional events…',
                    filled: true,
                    fillColor: d.isDark ? d.muted : d.card,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: d.md,
                      vertical: d.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(d.radiusCard),
                      borderSide: BorderSide(
                        color: d.isDark
                            ? d.border
                            : d.authDark.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(d.radiusCard),
                      borderSide: BorderSide(
                        color: d.isDark
                            ? d.border
                            : d.authDark.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(d.radiusCard),
                      borderSide: BorderSide(
                        color: d.authDark,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: _eventSearchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _eventSearchController.clear();
                              setState(() => _eventSearchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: d.md),
              if (events.isEmpty)
                EmptyStateView(
                  icon: LucideIcons.calendarX,
                  title: _eventSearchQuery.trim().isEmpty
                      ? 'No institutional events available.'
                      : 'No events match your search.',
                  message: _eventSearchQuery.trim().isEmpty
                      ? 'Published and completed school events will appear here for read-only inspection.'
                      : 'Try clearing the search filter to view all recorded events.',
                  actionLabel:
                      _eventSearchQuery.trim().isEmpty ? null : 'Clear Filter',
                  onAction: _eventSearchQuery.trim().isEmpty
                      ? null
                      : () {
                          _eventSearchController.clear();
                          setState(() => _eventSearchQuery = '');
                        },
                )
              else
                ResponsiveGrid(
                  minItemWidth: 320,
                  maxColumns: 3,
                  spacing: d.md,
                  children: [
                    for (final e in events)
                      _ManagementEventReadOnlyCard(
                        eventMap: e,
                        onViewRegistrations: _openEventRegistrations,
                        onViewAttendance: _openEventAttendance,
                        onOpenReports: _openReports,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _shellTitle,
      destinations: _destinations,
      selectedId: _selectedDestination,
      onDestinationSelected: (id) {
        setState(() => _selectedDestination = id);
      },
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell, size: 20),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.user, size: 20),
          tooltip: 'My Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 20),
          tooltip: 'Refresh Metrics',
          onPressed: _isLoading ? null : _fetchData,
        ),
        IconButton(
          icon: const Icon(LucideIcons.logOut, size: 20),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
      body: AppDestinationStack(
        selectedId: _selectedDestination,
        builders: {
          'overview': _buildOverviewDestination,
          'events': _buildEventsDestination,
          'calendar': (_) => const CalendarScreen(embedded: true),
          'reports': (_) => ReportsScreen(
                embedded: true,
                initialEvents: _hasFixtures ? const [] : null,
                initialReportPayload: _hasFixtures
                    ? (_metrics.isNotEmpty
                        ? _metrics
                        : const <String, dynamic>{'total_events': 0})
                    : null,
              ),
        },
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
    final d = context.design;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5;

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(status: status),
              SizedBox(height: d.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: d.body,
                      softWrap: true,
                    ),
                  ),
                  SizedBox(width: d.sm),
                  Text(
                    '$count',
                    style: d.cardTitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  StatusBadge(status: status),
                  SizedBox(width: d.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: d.body,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: d.sm),
            Text(
              '$count',
              style: d.cardTitle.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        );
      },
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
    final d = context.design;
    final eventId = (eventMap['id'] as num?)?.toInt();
    final title = eventMap['title']?.toString() ?? 'Event';
    final eventDate = eventMap['event_date']?.toString().split('T').first ?? '';
    final venue = eventMap['venue']?.toString() ?? '';
    final attendedCount = eventMap['attendances_count'] ?? 0;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackHeader = constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stackHeader) ...[
                Text(title, style: d.cardTitle, softWrap: true),
                SizedBox(height: d.xs),
                StatusBadge(
                  status: 'present',
                  label: '$attendedCount ATTENDED',
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: d.cardTitle, softWrap: true),
                    ),
                    SizedBox(width: d.sm),
                    StatusBadge(
                      status: 'present',
                      label: '$attendedCount ATTENDED',
                    ),
                  ],
                ),
              SizedBox(height: d.xs),
              Text(
                [
                  if (eventDate.isNotEmpty) eventDate,
                  if (venue.isNotEmpty) venue,
                ].join(' • '),
                style: d.supporting,
                softWrap: true,
              ),
              if (eventId != null) ...[
                Divider(height: d.md, color: d.border),
                Wrap(
                  spacing: d.sm,
                  runSpacing: d.sm,
                  children: [
                    AppButton(
                      variant: AppButtonVariant.outline,
                      pill: true,
                      icon: LucideIcons.users,
                      label: 'Registrations (RO)',
                      onPressed: () => onViewRegistrations(eventId, title),
                    ),
                    AppButton(
                      variant: AppButtonVariant.outline,
                      pill: true,
                      icon: LucideIcons.eye,
                      label: 'Attendance (RO)',
                      onPressed: () => onViewAttendance(eventId, title),
                    ),
                    AppButton(
                      variant: AppButtonVariant.ghost,
                      pill: true,
                      icon: LucideIcons.barChart2,
                      label: 'Reports',
                      onPressed: () => onOpenReports(eventId),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

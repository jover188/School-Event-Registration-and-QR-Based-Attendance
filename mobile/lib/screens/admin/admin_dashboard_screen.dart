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
import '../auth/account_input.dart';
import '../auth/login_screen.dart';
import '../common/notification_preferences_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/reports_screen.dart';
import '../organizer/event_form_screen.dart';
import 'activity_logs_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCounts;
  final Map<String, dynamic>? initialUsersByRole;
  final Map<String, dynamic>? initialEventsByStatus;
  final List<dynamic>? initialPendingEvents;
  final String? initialErrorMessage;
  final List<Map<String, dynamic>>? initialUsers;
  final List<dynamic>? initialLogs;
  final String initialDestinationId;

  const AdminDashboardScreen({
    super.key,
    this.initialCounts,
    this.initialUsersByRole,
    this.initialEventsByStatus,
    this.initialPendingEvents,
    this.initialErrorMessage,
    this.initialUsers,
    this.initialLogs,
    this.initialDestinationId = 'overview',
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const List<AppDestination> _destinations = [
    AppDestination(
      id: 'overview',
      label: 'Overview',
      icon: LucideIcons.layoutDashboard,
      essential: true,
    ),
    AppDestination(
      id: 'reviews',
      label: 'Reviews',
      icon: LucideIcons.folderCheck,
      essential: true,
    ),
    AppDestination(
      id: 'users',
      label: 'Users',
      icon: LucideIcons.users,
    ),
    AppDestination(
      id: 'qr-records',
      label: 'QR Records',
      icon: LucideIcons.scanLine,
      compactPrimary: false,
    ),
    AppDestination(
      id: 'reports',
      label: 'Reports',
      icon: LucideIcons.chartBar,
      compactPrimary: false,
    ),
    AppDestination(
      id: 'activity',
      label: 'Activity',
      icon: LucideIcons.scrollText,
      compactPrimary: false,
    ),
  ];

  late String _selectedDestinationId = widget.initialDestinationId;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _usersByRole = {};
  Map<String, dynamic> _eventsByStatus = {};
  List<dynamic> _pendingEvents = [];

  bool get _hasInitialFixtures =>
      widget.initialCounts != null ||
      widget.initialUsersByRole != null ||
      widget.initialEventsByStatus != null ||
      widget.initialPendingEvents != null ||
      widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasInitialFixtures) {
      _isLoading = false;
      _errorMessage = widget.initialErrorMessage;
      _stats = Map<String, dynamic>.from(widget.initialCounts ?? const {});
      _usersByRole = Map<String, dynamic>.from(
        widget.initialUsersByRole ??
            (widget.initialCounts?['users_by_role'] as Map?) ??
            const {},
      );
      _eventsByStatus = Map<String, dynamic>.from(
        widget.initialEventsByStatus ??
            (widget.initialCounts?['events_by_status'] as Map?) ??
            const {},
      );
      _pendingEvents =
          List<dynamic>.from(widget.initialPendingEvents ?? const []);
    } else {
      _fetchAdminData();
    }
  }

  int get _pendingCount {
    final fromStats = (_stats['pending_event_approvals'] as num?)?.toInt() ??
        (_stats['pending_approvals'] as num?)?.toInt();
    return fromStats ?? _pendingEvents.length;
  }

  Map<String, dynamic> get _effectiveUsersByRole {
    if (_usersByRole.isNotEmpty) return _usersByRole;
    final derived = <String, dynamic>{};
    if (_stats['total_students'] != null) {
      derived['student'] = _stats['total_students'];
    }
    if (_stats['total_organizers'] != null) {
      derived['organizer'] = _stats['total_organizers'];
    }
    if (_stats['total_admins'] != null) {
      derived['administrator'] = _stats['total_admins'];
    }
    if (_stats['total_management'] != null) {
      derived['management'] = _stats['total_management'];
    }
    return derived;
  }

  Map<String, dynamic> get _effectiveEventsByStatus {
    if (_eventsByStatus.isNotEmpty) return _eventsByStatus;
    final derived = <String, dynamic>{};
    if (_stats['pending_event_approvals'] != null ||
        _pendingEvents.isNotEmpty) {
      derived['pending_approval'] = _pendingCount;
    }
    if (_stats['published_events'] != null) {
      derived['published'] = _stats['published_events'];
    }
    if (_stats['ongoing_events'] != null) {
      derived['ongoing'] = _stats['ongoing_events'];
    }
    if (_stats['completed_events'] != null) {
      derived['completed'] = _stats['completed_events'];
    }
    return derived;
  }

  String get _shellTitle => switch (_selectedDestinationId) {
        'reviews' => 'Publishing Reviews',
        'users' => 'User Management',
        'qr-records' => 'QR Records',
        'reports' => 'Reports',
        'activity' => 'Activity',
        _ => 'Administrator Console',
      };

  void _selectDestination(String id) {
    setState(() => _selectedDestinationId = id);
  }

  Future<void> _fetchAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.adminDashboard);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _stats = (data['stats'] as Map<String, dynamic>?) ??
            (data['counts'] as Map<String, dynamic>?) ??
            {};
        _usersByRole = (data['users_by_role'] as Map<String, dynamic>?) ??
            (_stats['users_by_role'] as Map<String, dynamic>?) ??
            {};
        _eventsByStatus = (data['events_by_status'] as Map<String, dynamic>?) ??
            (_stats['events_by_status'] as Map<String, dynamic>?) ??
            {};
        _pendingEvents = (data['pending_approval_events'] as List?) ?? [];
      });
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Failed to load administrator dashboard.';
      });
    }
  }

  Future<void> _reviewEvent(Map<String, dynamic> event, String action) async {
    final eventId = (event['id'] as num?)?.toInt();
    if (eventId == null) return;
    final eventTitle = event['title']?.toString() ?? 'Event #$eventId';

    final remarks = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewEventApprovalDialog(
        action: action,
        eventTitle: eventTitle,
      ),
    );

    if (remarks == null || !mounted) return;

    if (_hasInitialFixtures) {
      setState(() {
        _pendingEvents.removeWhere(
          (item) => item is Map && (item['id'] as num?)?.toInt() == eventId,
        );
        if (_stats.containsKey('pending_event_approvals')) {
          _stats['pending_event_approvals'] = _pendingEvents.length;
        }
      });
      final d = context.design;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: action == 'approved' ? d.success : d.mutedForeground,
          content: Text(
            remarks.isEmpty
                ? 'Event publishing has been $action.'
                : 'Event publishing has been $action: $remarks',
          ),
        ),
      );
      return;
    }

    final response = await ApiClient().post(
      ApiConstants.adminReviewEvent(eventId),
      {
        'action': action,
        'remarks': remarks,
      },
    );

    if (!mounted) return;

    final d = context.design;
    if (response.success) {
      _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: action == 'approved' ? d.success : d.mutedForeground,
          content: Text('Event publishing has been $action.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.destructive,
          content: Text(response.message ?? 'Failed to review event.'),
        ),
      );
    }
  }

  Future<void> _openBroadcastAnnouncementDialog() async {
    final payload = await showDialog<
        ({String title, String message, String targetRole})>(
      context: context,
      builder: (_) => const _BroadcastAnnouncementDialog(),
    );

    if (payload == null || !mounted) return;

    if (_hasInitialFixtures) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.design.success,
          content: Text(
            'Announcement "${payload.title}" queued for ${payload.targetRole}.',
          ),
        ),
      );
      return;
    }

    final response = await ApiClient().post(
      ApiConstants.adminAnnouncements,
      {
        'title': payload.title,
        'message': payload.message,
        'target_role': payload.targetRole,
      },
    );

    if (!mounted) return;

    final d = context.design;
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.success,
          content: Text(
            response.message ?? 'System announcement broadcast successfully.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.destructive,
          content: Text(
            response.message ?? 'Failed to broadcast announcement.',
          ),
        ),
      );
    }
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (created == true && mounted && !_hasInitialFixtures) {
      _fetchAdminData();
    }
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

  Widget _buildOverviewTab(BuildContext context) {
    final d = context.design;
    final hasAnyData = _stats.isNotEmpty ||
        _usersByRole.isNotEmpty ||
        _eventsByStatus.isNotEmpty ||
        _pendingEvents.isNotEmpty;

    if (_isLoading && !hasAnyData) {
      return Center(
        child: Semantics(
          label: 'Loading administrator overview',
          child: AppSpinner(color: d.authDark, size: 28),
        ),
      );
    }

    if (_errorMessage != null && !hasAnyData) {
      return AppResponsivePage(
        child: ErrorStateView(
          message: _errorMessage!,
          onRetry: _fetchAdminData,
        ),
      );
    }

    final roleBreakdown = _effectiveUsersByRole;
    final eventBreakdown = _effectiveEventsByStatus;

    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AppResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(d.md),
                  decoration: BoxDecoration(
                    color: d.warningBackground,
                    borderRadius: BorderRadius.circular(d.radiusCard),
                    border: Border.all(
                      color: d.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Wrap(
                    spacing: d.sm,
                    runSpacing: d.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        _errorMessage!,
                        style: d.supporting.copyWith(color: d.warning),
                      ),
                      AppButton(
                        pill: true,
                        variant: AppButtonVariant.outline,
                        label: 'Retry',
                        icon: LucideIcons.refreshCw,
                        onPressed: _fetchAdminData,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: d.md),
              ],
              const SectionHeader(
                title: 'Administrative Operations',
                subtitle:
                    'Create campus events, broadcast notices, review submissions, and manage accounts',
              ),
              SizedBox(height: d.gap),
              _AdminQuickActionsGrid(
                pendingReviewsCount: _pendingCount,
                onOpenReviews: () => _selectDestination('reviews'),
                onOpenUsers: () => _selectDestination('users'),
                onOpenQrRecords: () => _selectDestination('qr-records'),
                onOpenLogs: () => _selectDestination('activity'),
                onOpenReports: () => _selectDestination('reports'),
                onCreateEvent: _openCreateEvent,
                onBroadcastAnnouncement: _openBroadcastAnnouncementDialog,
              ),
              SizedBox(height: d.lg),
              const SectionHeader(
                title: 'System Metrics',
                subtitle: 'Current platform activity and identity counts',
              ),
              SizedBox(height: d.gap),
              ResponsiveGrid(
                children: [
                  StatMetricCard(
                    label: 'Pending Approvals',
                    value: '$_pendingCount',
                    icon: LucideIcons.hourglass,
                    color: d.warning,
                    onTap: () => _selectDestination('reviews'),
                  ),
                  StatMetricCard(
                    label: 'Total Users',
                    value: '${_stats['total_users'] ?? 0}',
                    icon: LucideIcons.users,
                    color: d.primary,
                    onTap: () => _selectDestination('users'),
                  ),
                  StatMetricCard(
                    label: 'Students',
                    value:
                        '${_stats['total_students'] ?? roleBreakdown['student'] ?? 0}',
                    icon: LucideIcons.graduationCap,
                    color: d.information,
                    onTap: () => _selectDestination('qr-records'),
                  ),
                  StatMetricCard(
                    label: 'Active QR Codes',
                    value:
                        '${_stats['active_permanent_qrs'] ?? _stats['active_qrs'] ?? 0}',
                    icon: LucideIcons.qrCode,
                    color: d.success,
                    onTap: () => _selectDestination('qr-records'),
                  ),
                ],
              ),
              if (roleBreakdown.isNotEmpty) ...[
                SizedBox(height: d.lg),
                const SectionHeader(
                  title: 'Users by Role',
                  subtitle: 'Distribution across fixed RBAC roles',
                ),
                SizedBox(height: d.gap),
                _BreakdownSectionCard(
                  entries: roleBreakdown,
                  isStatusBadge: false,
                ),
              ],
              if (eventBreakdown.isNotEmpty) ...[
                SizedBox(height: d.lg),
                const SectionHeader(
                  title: 'Events by Status',
                  subtitle: 'Campus event lifecycle breakdown',
                ),
                SizedBox(height: d.gap),
                _BreakdownSectionCard(
                  entries: eventBreakdown,
                  isStatusBadge: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsTab(BuildContext context) {
    final d = context.design;

    if (_isLoading && _pendingEvents.isEmpty) {
      return Center(
        child: Semantics(
          label: 'Loading event publishing review queue',
          child: AppSpinner(color: d.authDark, size: 28),
        ),
      );
    }

    if (_errorMessage != null && _pendingEvents.isEmpty && _stats.isEmpty) {
      return AppResponsivePage(
        child: ErrorStateView(
          message: _errorMessage!,
          onRetry: _fetchAdminData,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AppResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Event Approval Queue',
                subtitle:
                    'Review organizer submissions before campus-wide publication (${_pendingEvents.length} pending)',
              ),
              SizedBox(height: d.gap),
              if (_pendingEvents.isEmpty)
                Container(
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
                  child: const EmptyStateView(
                    icon: LucideIcons.badgeCheck,
                    title: 'No events currently pending review.',
                    message:
                        'All submitted organizer events have been processed.',
                  ),
                )
              else
                ResponsiveGrid(
                  minItemWidth: 340,
                  maxColumns: 2,
                  spacing: d.md,
                  children: [
                    for (final rawEvent in _pendingEvents)
                      if (rawEvent is Map)
                        _PendingApprovalEventCard(
                          event: Map<String, dynamic>.from(rawEvent),
                          onApprove: () => _reviewEvent(
                            Map<String, dynamic>.from(rawEvent),
                            'approved',
                          ),
                          onReject: () => _reviewEvent(
                            Map<String, dynamic>.from(rawEvent),
                            'rejected',
                          ),
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
      selectedId: _selectedDestinationId,
      onDestinationSelected: _selectDestination,
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
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          tooltip: 'Refresh Console',
          onPressed: _isLoading ? null : _fetchAdminData,
        ),
        PopupMenuButton<String>(
          key: const ValueKey<String>('admin-account-menu'),
          tooltip: 'Account & Profile Menu',
          icon: const Icon(LucideIcons.user, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              case 'preferences':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationPreferencesScreen(),
                  ),
                );
              case 'logout':
                _logout();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'profile',
              child: Text('My Profile'),
            ),
            PopupMenuItem<String>(
              value: 'preferences',
              child: Text('Notification Preferences'),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
      body: AppDestinationStack(
        selectedId: _selectedDestinationId,
        builders: {
          'overview': _buildOverviewTab,
          'reviews': _buildReviewsTab,
          'users': (_) => UserManagementScreen(
                key: const ValueKey<String>('admin-embedded-users'),
                embedded: true,
                initialUsers: widget.initialUsers,
              ),
          'qr-records': (_) => UserManagementScreen(
                key: const ValueKey<String>('admin-embedded-qr-records'),
                embedded: true,
                initialRoleFilter: 'student',
                qrInspectMode: true,
                initialUsers: widget.initialUsers,
              ),
          'reports': (_) => const ReportsScreen(
                key: ValueKey<String>('admin-embedded-reports'),
                embedded: true,
              ),
          'activity': (_) => ActivityLogsScreen(
                key: const ValueKey<String>('admin-embedded-activity'),
                embedded: true,
                initialLogs: widget.initialLogs,
              ),
        },
      ),
    );
  }
}

class _AdminQuickActionsGrid extends StatelessWidget {
  final int pendingReviewsCount;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenQrRecords;
  final VoidCallback onOpenLogs;
  final VoidCallback onOpenReports;
  final VoidCallback onCreateEvent;
  final VoidCallback onBroadcastAnnouncement;

  const _AdminQuickActionsGrid({
    required this.pendingReviewsCount,
    required this.onOpenReviews,
    required this.onOpenUsers,
    required this.onOpenQrRecords,
    required this.onOpenLogs,
    required this.onOpenReports,
    required this.onCreateEvent,
    required this.onBroadcastAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Wrap(
      spacing: d.sm,
      runSpacing: d.sm,
      children: [
        AppButton(
          key: const ValueKey<String>('admin-nav-create-event'),
          pill: true,
          onPressed: onCreateEvent,
          icon: LucideIcons.calendarPlus,
          label: 'Create Event',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-broadcast'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onBroadcastAnnouncement,
          icon: LucideIcons.megaphone,
          label: 'Broadcast Announcement',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-reviews'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onOpenReviews,
          icon: LucideIcons.folderCheck,
          label: 'Publishing Reviews ($pendingReviewsCount)',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-users'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onOpenUsers,
          icon: LucideIcons.users,
          label: 'User Management',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-qr-records'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onOpenQrRecords,
          icon: LucideIcons.scanLine,
          label: 'QR Records',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-reports'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onOpenReports,
          icon: LucideIcons.chartBar,
          label: 'Reports & Exports',
        ),
        AppButton(
          key: const ValueKey<String>('admin-nav-logs'),
          pill: true,
          variant: AppButtonVariant.outline,
          onPressed: onOpenLogs,
          icon: LucideIcons.scrollText,
          label: 'Activity Logs',
        ),
      ],
    );
  }
}

class _BreakdownSectionCard extends StatelessWidget {
  final Map<String, dynamic> entries;
  final bool isStatusBadge;

  const _BreakdownSectionCard({
    required this.entries,
    required this.isStatusBadge,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Container(
      width: double.infinity,
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
      child: Wrap(
        spacing: d.md,
        runSpacing: d.sm,
        children: [
          for (final entry in entries.entries)
            Container(
              padding: EdgeInsets.symmetric(horizontal: d.gap, vertical: d.sm),
              decoration: BoxDecoration(
                color: d.isDark ? d.muted : d.authSurface,
                borderRadius: BorderRadius.circular(d.radiusControl),
                border: Border.all(
                  color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
                ),
              ),
              child: Wrap(
                spacing: d.sm,
                runSpacing: d.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(
                    status: isStatusBadge ? entry.key : 'completed',
                    label: entry.key.replaceAll('_', ' ').toUpperCase(),
                    showIcon: isStatusBadge,
                  ),
                  Text(
                    '${entry.value}',
                    style: d.cardTitle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingApprovalEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingApprovalEventCard({
    required this.event,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final eventId = (event['id'] as num?)?.toInt() ?? 0;
    final title = event['title']?.toString() ?? 'Untitled Event';
    final status = event['status']?.toString() ?? 'pending_approval';
    final venue = event['venue']?.toString() ?? 'TBA';
    final eventDate = event['event_date']?.toString() ?? 'TBA';
    final organizerMap = event['organizer'] is Map
        ? Map<String, dynamic>.from(event['organizer'] as Map)
        : null;
    final organizerEmail =
        organizerMap?['email']?.toString() ?? event['organizer_email']?.toString() ?? 'N/A';

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
            spacing: d.sm,
            runSpacing: d.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title, style: d.cardTitle),
              StatusBadge(status: status),
            ],
          ),
          SizedBox(height: d.sm),
          Text(
            'Venue: $venue • Date: $eventDate',
            style: d.supporting.copyWith(color: d.foreground),
          ),
          SizedBox(height: d.xs),
          Text(
            'Organizer: $organizerEmail',
            style: d.supporting,
          ),
          const Divider(),
          Wrap(
            spacing: d.sm,
            runSpacing: d.sm,
            alignment: WrapAlignment.end,
            children: [
              AppButton(
                key: ValueKey<String>('reject-event-$eventId'),
                pill: true,
                variant: AppButtonVariant.destructive,
                icon: LucideIcons.x,
                label: 'Reject',
                onPressed: onReject,
              ),
              AppButton(
                key: ValueKey<String>('approve-event-$eventId'),
                pill: true,
                variant: AppButtonVariant.primary,
                icon: LucideIcons.check,
                label: 'Approve & Publish',
                onPressed: onApprove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewEventApprovalDialog extends StatefulWidget {
  final String action;
  final String eventTitle;

  const _ReviewEventApprovalDialog({
    required this.action,
    required this.eventTitle,
  });

  @override
  State<_ReviewEventApprovalDialog> createState() =>
      _ReviewEventApprovalDialogState();
}

class _ReviewEventApprovalDialogState
    extends State<_ReviewEventApprovalDialog> {
  late final TextEditingController _remarksController =
      TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final isApprove = widget.action == 'approved';
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusCard),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      title: Row(
        children: [
          Icon(
            isApprove ? LucideIcons.badgeCheck : LucideIcons.alertCircle,
            size: 20,
            color: isApprove ? d.success : d.destructive,
          ),
          SizedBox(width: d.sm),
          Expanded(child: Text('${isApprove ? 'Approve' : 'Reject'} Event?')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm ${widget.action} of "${widget.eventTitle}".',
                style: d.body,
              ),
              SizedBox(height: d.gap),
              AccountInput(
                key: const ValueKey<String>('review-remarks-field'),
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remarks (Optional)',
                  hintText: 'Add review notes for the organizer',
                  prefixIcon: Icon(
                    LucideIcons.messageSquare,
                    size: 18,
                    color: d.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              key: ValueKey<String>('confirm-review-${widget.action}'),
              pill: true,
              variant: isApprove
                  ? AppButtonVariant.primary
                  : AppButtonVariant.destructive,
              onPressed: () =>
                  Navigator.pop(context, _remarksController.text.trim()),
              label: widget.action.toUpperCase(),
            ),
          ],
        ),
      ],
    );
  }
}

class _BroadcastAnnouncementDialog extends StatefulWidget {
  const _BroadcastAnnouncementDialog();

  @override
  State<_BroadcastAnnouncementDialog> createState() =>
      _BroadcastAnnouncementDialogState();
}

class _BroadcastAnnouncementDialogState
    extends State<_BroadcastAnnouncementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _messageController = TextEditingController();
  late final FocusNode _titleFocus = FocusNode();
  late final FocusNode _messageFocus = FocusNode();

  String _targetRole = 'all';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _titleFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      if (_titleController.text.trim().isEmpty) {
        _titleFocus.requestFocus();
      } else {
        _messageFocus.requestFocus();
      }
      return;
    }
    _formKey.currentState!.save();
    Navigator.pop(
      context,
      (
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        targetRole: _targetRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusCard),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      title: Row(
        children: [
          Icon(LucideIcons.megaphone, size: 20, color: d.primary),
          SizedBox(width: d.sm),
          const Expanded(child: Text('Broadcast System Announcement')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey<String>('announcement-target-role'),
                      isExpanded: true,
                      initialValue: _targetRole,
                      decoration: InputDecoration(
                        labelText: 'Target Audience Role',
                        prefixIcon: Icon(
                          LucideIcons.users,
                          size: 18,
                          color: d.mutedForeground,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'All Active Users',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'student',
                          child: Text(
                            'Students Only',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'organizer',
                          child: Text(
                            'Event Organizers Only',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'management',
                          child: Text(
                            'School Management Only',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _targetRole = val);
                        }
                      },
                    ),
                    SizedBox(height: d.gap),
                    AccountInput(
                      key: const ValueKey<String>('announcement-title-field'),
                      controller: _titleController,
                      focusNode: _titleFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: 'Announcement Title',
                        hintText: 'e.g. Campus Maintenance Schedule',
                        prefixIcon: Icon(
                          LucideIcons.heading,
                          size: 18,
                          color: d.mutedForeground,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: d.gap),
                    AccountInput(
                      key: const ValueKey<String>('announcement-message-field'),
                      controller: _messageController,
                      focusNode: _messageFocus,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.multiline,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Announcement Message',
                        hintText: 'Enter announcement body text',
                        prefixIcon: Icon(
                          LucideIcons.messageSquare,
                          size: 18,
                          color: d.mutedForeground,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Message body is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              key: const ValueKey<String>('send-broadcast-button'),
              pill: true,
              onPressed: _submit,
              label: 'Send Broadcast',
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/navigation/app_destination.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../models/event_model.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/calendar_screen.dart';
import '../common/profile_screen.dart';
import '../common/reports_screen.dart';
import 'event_form_screen.dart';
import 'event_registrations_screen.dart';
import 'live_attendance_screen.dart';
import 'qr_scanner_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  final List<EventModel>? initialEvents;
  final Map<String, dynamic>? initialSummary;
  final String? initialErrorMessage;

  const OrganizerDashboardScreen({
    super.key,
    this.initialEvents,
    this.initialSummary,
    this.initialErrorMessage,
  });

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  static const List<AppDestination> _destinations = [
    AppDestination(
      id: 'overview',
      label: 'Overview',
      icon: LucideIcons.layoutDashboard,
      essential: true,
    ),
    AppDestination(
      id: 'calendar',
      label: 'Calendar',
      icon: LucideIcons.calendarDays,
    ),
    AppDestination(
      id: 'events',
      label: 'My Events',
      icon: LucideIcons.calendarRange,
      essential: true,
    ),
    AppDestination(
      id: 'reports',
      label: 'Reports',
      icon: LucideIcons.chartBar,
    ),
  ];

  String _selectedDestinationId = 'overview';
  String _selectedStatusFilter = 'all';
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<EventModel> _myEvents = [];

  bool get _hasFixtures =>
      widget.initialEvents != null ||
      widget.initialSummary != null ||
      widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtures) {
      _isLoading = false;
      _myEvents = List<EventModel>.from(widget.initialEvents ?? const []);
      _stats = Map<String, dynamic>.from(widget.initialSummary ?? const {});
      _errorMessage = widget.initialErrorMessage;
    } else {
      _fetchDashboardData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      ApiClient().get(ApiConstants.organizerDashboard),
      ApiClient().get(ApiConstants.events),
    ]);

    final dashboardResp = results[0];
    final eventsResp = results[1];

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (dashboardResp.success && dashboardResp.data is Map<String, dynamic>) {
        _stats =
            (dashboardResp.data['stats'] as Map<String, dynamic>?) ?? {};
      }
      if (eventsResp.success && eventsResp.data is List) {
        _myEvents = (eventsResp.data as List)
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (!eventsResp.success && !dashboardResp.success) {
        _errorMessage =
            eventsResp.message ?? 'Failed to load organizer dashboard.';
      }
    });
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (created == true && mounted) {
      _fetchDashboardData();
    }
  }

  Future<void> _openEditEvent(EventModel event) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
    );
    if (updated == true && mounted) {
      _fetchDashboardData();
    }
  }

  void _openRegistrations(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventRegistrationsScreen(
          eventId: event.id,
          eventTitle: event.title,
          canCancel: true,
        ),
      ),
    );
  }

  void _openAttendance(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveAttendanceScreen(
          eventId: event.id,
          eventTitle: event.title,
          canCorrect: true,
        ),
      ),
    );
  }

  void _openScanner(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(event: event),
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

  List<EventModel> get _filteredEvents {
    final query = _searchController.text.trim().toLowerCase();
    return _myEvents.where((event) {
      final matchesStatus = _selectedStatusFilter == 'all' ||
          event.status.toLowerCase() == _selectedStatusFilter;
      final matchesQuery = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.venue.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  String get _shellTitle => switch (_selectedDestinationId) {
        'calendar' => 'Event Calendar',
        'events' => 'My Events',
        'reports' => 'Reports & Exports',
        _ => 'Organizer Portal',
      };

  Widget _buildOverviewTab(BuildContext context) {
    final d = context.design;
    if (_isLoading && _myEvents.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (_errorMessage != null && _myEvents.isEmpty) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchDashboardData,
      );
    }

    final totalCount =
        (_stats['total_events'] as num?)?.toInt() ?? _myEvents.length;
    final publishedCount = (_stats['published_events'] as num?)?.toInt() ??
        _myEvents.where((e) => e.status == 'published').length;
    final ongoingCount = (_stats['ongoing_events'] as num?)?.toInt() ??
        _myEvents.where((e) => e.status == 'ongoing').length;
    final draftOrPendingCount = (_stats['pending_events'] as num?)?.toInt() ??
        _myEvents
            .where(
              (e) => e.status == 'draft' || e.status == 'pending_approval',
            )
            .length;

    final priorityEvents = _myEvents.take(4).toList();

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: AppResponsivePage(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Event Operations Summary',
                subtitle:
                    'Create event drafts, monitor registrations, and launch QR check-in',
                trailing: AppButton(
                  key: const ValueKey<String>('organizer-create-event-fab'),
                  label: 'Create Event',
                  pill: true,
                  icon: LucideIcons.plus,
                  onPressed: _openCreateEvent,
                ),
              ),
              SizedBox(height: d.md),
              ResponsiveGrid(
                minItemWidth: 150,
                maxColumns: 4,
                children: [
                  StatMetricCard(
                    label: 'Total Events',
                    value: '$totalCount',
                    icon: LucideIcons.calendarDays,
                    color: d.primary,
                  ),
                  StatMetricCard(
                    label: 'Published',
                    value: '$publishedCount',
                    icon: LucideIcons.globe,
                    color: d.success,
                  ),
                  StatMetricCard(
                    label: 'Ongoing',
                    value: '$ongoingCount',
                    icon: LucideIcons.radio,
                    color: d.information,
                  ),
                  StatMetricCard(
                    label: 'Draft & Pending',
                    value: '$draftOrPendingCount',
                    icon: LucideIcons.hourglass,
                    color: d.warning,
                  ),
                ],
              ),
              SizedBox(height: d.lg),
              SectionHeader(
                title: 'Recent & Active Events',
                subtitle:
                    'Manage registrations, inspect attendance, or open the QR scanner',
                actionLabel: 'View All (${_myEvents.length})',
                onAction: () =>
                    setState(() => _selectedDestinationId = 'events'),
              ),
              SizedBox(height: d.md),
              if (priorityEvents.isEmpty)
                EmptyStateView(
                  icon: LucideIcons.calendarX,
                  title: 'No events found.',
                  message:
                      'Create a new event draft or refresh your dashboard.',
                  actionLabel: 'Create Event',
                  onAction: _openCreateEvent,
                )
              else
                for (final event in priorityEvents)
                  _OrganizerEventManagementCard(
                    event: event,
                    onEdit: () => _openEditEvent(event),
                    onRegistrations: () => _openRegistrations(event),
                    onAttendance: () => _openAttendance(event),
                    onScanQr: () => _openScanner(event),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyEventsTab(BuildContext context) {
    final d = context.design;
    if (_isLoading && _myEvents.isEmpty) {
      return const Center(child: AppSpinner());
    }
    if (_errorMessage != null && _myEvents.isEmpty) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchDashboardData,
      );
    }

    final events = _filteredEvents;

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: AppResponsivePage(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Manage Owned Events',
                subtitle:
                    'Filter by lifecycle state, edit details, or manage attendance',
                trailing: AppButton(
                  label: 'Create Event',
                  pill: true,
                  icon: LucideIcons.plus,
                  onPressed: _openCreateEvent,
                ),
              ),
              SizedBox(height: d.md),
              TextField(
                key: const ValueKey<String>('organizer-events-search-field'),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search owned events by title or venue',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear Search',
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              SizedBox(height: d.sm),
              _EventStatusFilterChips(
                selectedStatus: _selectedStatusFilter,
                onSelect: (status) =>
                    setState(() => _selectedStatusFilter = status),
              ),
              SizedBox(height: d.md),
              if (events.isEmpty)
                EmptyStateView(
                  icon: LucideIcons.calendarX,
                  title: 'No matching events.',
                  message: _myEvents.isEmpty
                      ? 'Create your first school event draft to get started.'
                      : 'Adjust your search query or lifecycle status filter.',
                  actionLabel:
                      _myEvents.isEmpty ? 'Create Event' : 'Reset Filters',
                  onAction: _myEvents.isEmpty
                      ? _openCreateEvent
                      : () {
                          _searchController.clear();
                          setState(() => _selectedStatusFilter = 'all');
                        },
                )
              else
                for (final event in events)
                  _OrganizerEventManagementCard(
                    event: event,
                    onEdit: () => _openEditEvent(event),
                    onRegistrations: () => _openRegistrations(event),
                    onAttendance: () => _openAttendance(event),
                    onScanQr: () => _openScanner(event),
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
      onDestinationSelected: (id) =>
          setState(() => _selectedDestinationId = id),
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
          tooltip: 'Refresh Dashboard',
          onPressed: _isLoading ? null : _fetchDashboardData,
        ),
        IconButton(
          icon: const Icon(LucideIcons.logOut, size: 20),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
      body: AppDestinationStack(
        selectedId: _selectedDestinationId,
        builders: {
          'overview': _buildOverviewTab,
          'events': _buildMyEventsTab,
          'calendar': (_) => const CalendarScreen(embedded: true),
          'reports': (_) => const ReportsScreen(embedded: true),
        },
      ),
    );
  }
}

class _EventStatusFilterChips extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onSelect;

  const _EventStatusFilterChips({
    required this.selectedStatus,
    required this.onSelect,
  });

  static const List<({String value, String label})> _filters = [
    (value: 'all', label: 'All'),
    (value: 'draft', label: 'Draft'),
    (value: 'pending_approval', label: 'Pending Approval'),
    (value: 'published', label: 'Published'),
    (value: 'ongoing', label: 'Ongoing'),
    (value: 'completed', label: 'Completed'),
    (value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Wrap(
      spacing: d.sm,
      runSpacing: d.xs,
      children: [
        for (final filter in _filters)
          AppPressable(
            key: ValueKey<String>('org-event-filter-${filter.value}'),
            semanticLabel: 'Filter ${filter.label}',
            selected: selectedStatus == filter.value,
            onPressed: () => onSelect(filter.value),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: EdgeInsets.symmetric(
                horizontal: d.gap,
                vertical: d.xs + 2,
              ),
              decoration: BoxDecoration(
                color: selectedStatus == filter.value
                    ? (d.isDark ? d.authDark : Colors.black)
                    : d.card,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selectedStatus == filter.value
                      ? (d.isDark ? d.border : Colors.black)
                      : (d.isDark
                          ? d.border
                          : d.authDark.withValues(alpha: 0.08)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.authDark.withValues(alpha: 0.03),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                filter.label,
                style: d.badge.copyWith(
                  fontWeight: selectedStatus == filter.value
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selectedStatus == filter.value
                      ? Colors.white
                      : d.foreground,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrganizerEventManagementCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onRegistrations;
  final VoidCallback onAttendance;
  final VoidCallback onScanQr;

  const _OrganizerEventManagementCard({
    required this.event,
    required this.onEdit,
    required this.onRegistrations,
    required this.onAttendance,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final canScan =
        event.status == 'published' || event.status == 'ongoing';

    return Padding(
      padding: EdgeInsets.only(bottom: d.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventCard(
            event: event,
            onTap: onEdit,
            showEventStatusBadge: true,
            showCapacity: true,
            trailingAction: AppButton(
              key: ValueKey<String>('open-scanner-${event.id}'),
              label: 'Open Scanner',
              pill: true,
              icon: LucideIcons.scanLine,
              onPressed: canScan ? onScanQr : null,
            ),
          ),
          if (!canScan)
            Padding(
              padding: EdgeInsets.only(bottom: d.xs),
              child: Text(
                'QR scanning requires Published or Ongoing status (currently ${event.status.replaceAll('_', ' ')}).',
                style: d.supporting,
              ),
            ),
          Wrap(
            spacing: d.sm,
            runSpacing: d.xs,
            children: [
              AppButton(
                key: ValueKey<String>('edit-event-${event.id}'),
                variant: AppButtonVariant.outline,
                pill: true,
                icon: LucideIcons.pencil,
                label: event.status == 'draft' ? 'Edit / Submit' : 'Edit Event',
                onPressed: onEdit,
              ),
              AppButton(
                key: ValueKey<String>('event-registrations-${event.id}'),
                variant: AppButtonVariant.outline,
                pill: true,
                icon: LucideIcons.users,
                label: 'Registrations',
                onPressed: onRegistrations,
              ),
              AppButton(
                key: ValueKey<String>('event-attendance-${event.id}'),
                variant: AppButtonVariant.outline,
                pill: true,
                icon: LucideIcons.clipboardCheck,
                label: 'Attendance',
                onPressed: onAttendance,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

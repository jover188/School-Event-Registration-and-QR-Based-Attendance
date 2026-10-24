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
import '../../core/widgets/event_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';
import '../auth/login_screen.dart';
import '../common/calendar_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import 'event_detail_screen.dart';
import 'my_attendance_history_screen.dart';
import 'my_registrations_screen.dart';
import 'permanent_qr_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final List<EventModel>? initialEvents;
  final Map<String, dynamic>? initialStats;
  final String? initialErrorMessage;
  final List<Map<String, dynamic>>? initialRegistrations;
  final Map<String, dynamic>? initialQrData;
  final List<Map<String, dynamic>>? initialAttendanceRecords;

  const StudentDashboardScreen({
    super.key,
    this.initialEvents,
    this.initialStats,
    this.initialErrorMessage,
    this.initialRegistrations,
    this.initialQrData,
    this.initialAttendanceRecords,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const List<AppDestination> _destinations = [
    AppDestination(
      id: 'events',
      label: 'Events',
      icon: LucideIcons.calendar,
      essential: true,
    ),
    AppDestination(
      id: 'calendar',
      label: 'Calendar',
      icon: LucideIcons.calendarDays,
    ),
    AppDestination(
      id: 'registrations',
      label: 'My Registrations',
      icon: LucideIcons.clipboardCheck,
    ),
    AppDestination(
      id: 'qr',
      label: 'My QR',
      icon: LucideIcons.qrCode,
      essential: true,
    ),
    AppDestination(
      id: 'history',
      label: 'History',
      icon: LucideIcons.history,
    ),
  ];

  String _selectedId = 'events';
  List<EventModel> _events = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  String? _partialWarningMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool get _hasFixtureData =>
      widget.initialEvents != null ||
      widget.initialStats != null ||
      widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtureData) {
      _applyFixtureData();
    } else {
      _fetchEvents();
    }
  }

  @override
  void didUpdateWidget(covariant StudentDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEvents != oldWidget.initialEvents ||
        widget.initialStats != oldWidget.initialStats ||
        widget.initialErrorMessage != oldWidget.initialErrorMessage) {
      if (_hasFixtureData) {
        _applyFixtureData();
      }
    }
  }

  void _applyFixtureData() {
    _isLoading = false;
    _events = List<EventModel>.from(widget.initialEvents ?? const []);
    _stats = widget.initialStats != null
        ? Map<String, dynamic>.from(widget.initialStats!)
        : null;
    if (_events.isNotEmpty && widget.initialErrorMessage != null) {
      _partialWarningMessage = widget.initialErrorMessage;
      _errorMessage = null;
    } else {
      _errorMessage = widget.initialErrorMessage;
      _partialWarningMessage = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    if (_hasFixtureData) {
      final base = widget.initialEvents ?? const <EventModel>[];
      final query = _searchQuery.trim().toLowerCase();
      setState(() {
        _isLoading = false;
        _events = query.isEmpty
            ? List<EventModel>.from(base)
            : base
                .where(
                  (e) =>
                      e.title.toLowerCase().contains(query) ||
                      e.venue.toLowerCase().contains(query),
                )
                .toList();
      });
      return;
    }

    setState(() {
      _isLoading = _events.isEmpty;
      _errorMessage = null;
      _partialWarningMessage = null;
    });

    final queryParams = <String, String>{};
    if (_searchQuery.isNotEmpty) {
      queryParams['search'] = _searchQuery;
    }

    final results = await Future.wait([
      ApiClient().get(ApiConstants.events, queryParams: queryParams),
      ApiClient().get(ApiConstants.studentDashboard),
    ]);

    final response = results[0];
    final dashResponse = results[1];

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _events = (response.data as List)
            .map(
              (e) => EventModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } else if (!response.success) {
        final msg = response.message ?? 'Unable to load campus events.';
        if (_events.isNotEmpty) {
          _partialWarningMessage = msg;
        } else {
          _errorMessage = msg;
        }
      }

      if (dashResponse.success && dashResponse.data is Map) {
        final dashData = Map<String, dynamic>.from(dashResponse.data as Map);
        if (dashData['stats'] is Map) {
          _stats = Map<String, dynamic>.from(dashData['stats'] as Map);
        }
      } else if (!dashResponse.success && response.success) {
        _partialWarningMessage =
            dashResponse.message ?? 'Summary metrics could not be refreshed.';
      }
    });
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

  Future<void> _openEventDetail(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          eventId: event.id,
          event: event,
          initialEvent: _hasFixtureData ? event : null,
        ),
      ),
    );
    if (!mounted) return;
    _fetchEvents();
  }

  String get _currentTitle => switch (_selectedId) {
        'calendar' => 'Event Calendar',
        'registrations' => 'My Registrations',
        'qr' => 'Permanent Student QR',
        'history' => 'Attendance History',
        _ => 'Campus Events',
      };

  Widget _buildEventTrailingAction(BuildContext context, EventModel event) {
    final remaining = event.remainingSlots;
    final isFull = remaining != null && remaining <= 0;
    final normalizedStatus = event.status.trim().toLowerCase();

    if (normalizedStatus == 'cancelled') {
      return const StatusBadge(
        status: 'cancelled',
        label: 'CANCELLED',
      );
    }
    if (event.isRegistered) {
      return AppButton(
        size: AppButtonSize.compact,
        variant: AppButtonVariant.outline,
        onPressed: () => _openEventDetail(event),
        label: 'Manage Registration',
      );
    }
    if (event.isWaitingList) {
      return StatusBadge(
        status: 'waiting_list',
        label: 'WAITING LIST #${event.userWaitingPosition ?? 1}',
      );
    }
    if (isFull) {
      return AppButton(
        size: AppButtonSize.compact,
        variant: AppButtonVariant.outline,
        icon: LucideIcons.listOrdered,
        onPressed: () => _openEventDetail(event),
        label: 'Join Waiting List',
      );
    }
    return AppButton(
      size: AppButtonSize.compact,
      variant: AppButtonVariant.ghost,
      onPressed: () => _openEventDetail(event),
      label: 'View Event',
    );
  }

  Widget _buildEventsDestination(BuildContext context) {
    final d = context.design;
    final warningMessage = _partialWarningMessage ??
        (_events.isNotEmpty ? _errorMessage : null);

    return AppResponsivePage(
      child: RefreshIndicator(
        onRefresh: _fetchEvents,
        child: CustomScrollView(
          key: const PageStorageKey<String>('student-events-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (warningMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(d.md),
                      decoration: BoxDecoration(
                        color: d.warningBackground,
                        borderRadius: BorderRadius.circular(d.radiusCard),
                        border: Border.all(
                          color: d.warning.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: d.sm,
                        runSpacing: d.sm,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.alertTriangle,
                                color: d.warning,
                                size: 18,
                              ),
                              SizedBox(width: d.sm),
                              Flexible(
                                child: Text(
                                  warningMessage,
                                  style: d.supporting.copyWith(
                                    color: d.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppButton(
                            size: AppButtonSize.compact,
                            variant: AppButtonVariant.outline,
                            icon: LucideIcons.refreshCw,
                            onPressed: _fetchEvents,
                            label: 'Retry',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: d.md),
                  ],
                  if (_stats != null) ...[
                    ResponsiveGrid(
                      minItemWidth: 150,
                      maxColumns: 3,
                      spacing: d.gap,
                      children: [
                        StatMetricCard(
                          label: 'Registered',
                          value:
                              '${(_stats!['total_registered_events'] ?? _stats!['registered'] ?? 0)}',
                          icon: LucideIcons.calendarCheck,
                          color: d.primary,
                          onTap: () =>
                              setState(() => _selectedId = 'registrations'),
                        ),
                        StatMetricCard(
                          label: 'Attended',
                          value:
                              '${(_stats!['total_attended_events'] ?? _stats!['attended'] ?? 0)}',
                          icon: LucideIcons.shieldCheck,
                          color: d.success,
                          onTap: () => setState(() => _selectedId = 'history'),
                        ),
                        StatMetricCard(
                          label: 'Waiting List',
                          value:
                              '${(_stats!['waiting_list_count'] ?? _stats!['total_waiting_list'] ?? _stats!['waiting_list'] ?? _stats!['unread_notifications'] ?? 0)}',
                          icon: LucideIcons.listOrdered,
                          color: d.waiting,
                          onTap: () =>
                              setState(() => _selectedId = 'registrations'),
                        ),
                      ],
                    ),
                    SizedBox(height: d.md),
                  ],
                  TextField(
                    key: const ValueKey('student-events-search-input'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Search events by title or venue',
                      hintText: 'Search events or venues...',
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: d.authDark.withValues(alpha: 0.62),
                      ),
                      suffixIcon: (_searchQuery.isNotEmpty ||
                              _searchController.text.isNotEmpty)
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: d.authDark.withValues(alpha: 0.62),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _fetchEvents();
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val.trim());
                      _fetchEvents();
                    },
                  ),
                  SizedBox(height: d.md),
                  SectionHeader(
                    title: 'Campus Events',
                    subtitle: _isLoading
                        ? null
                        : '${_events.length} event${_events.length == 1 ? '' : 's'} available',
                  ),
                  SizedBox(height: d.gap),
                ],
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: AppSpinner(
                    size: 28,
                    color: d.authDark,
                  ),
                ),
              )
            else if (_errorMessage != null && _events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchEvents,
                ),
              )
            else if (_events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: LucideIcons.calendarX2,
                  title: 'No upcoming events found.',
                  message:
                      'Check back soon or adjust your search filters.',
                  actionLabel: 'Refresh',
                  onAction: _fetchEvents,
                ),
              )
            else
              ResponsiveCardSliver(
                itemCount: _events.length,
                minItemWidth: 300,
                maxColumns: 3,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return EventCard(
                    event: event,
                    showEventStatusBadge: true,
                    showCapacity: true,
                    onTap: () => _openEventDetail(event),
                    trailingAction: _buildEventTrailingAction(context, event),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AppShell(
      title: _currentTitle,
      destinations: _destinations,
      selectedId: _selectedId,
      onDestinationSelected: (id) {
        setState(() => _selectedId = id);
      },
      actions: [
        IconButton(
          icon: Icon(LucideIcons.refreshCw, size: 18, color: d.foreground),
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _fetchEvents,
        ),
        IconButton(
          icon: Icon(LucideIcons.bell, size: 18, color: d.foreground),
          tooltip: 'Notifications',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
            if (!mounted) return;
            _fetchEvents();
          },
        ),
        IconButton(
          icon: Icon(LucideIcons.user, size: 18, color: d.foreground),
          tooltip: 'My Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        IconButton(
          icon: Icon(LucideIcons.logOut, size: 18, color: d.foreground),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
      body: AppDestinationStack(
        selectedId: _selectedId,
        builders: {
          'events': _buildEventsDestination,
          'calendar': (_) => const CalendarScreen(embedded: true),
          'registrations': (_) => MyRegistrationsScreen(
                embedded: true,
                initialRegistrations: widget.initialRegistrations,
              ),
          'qr': (_) => PermanentQrScreen(
                embedded: true,
                initialQrData: widget.initialQrData,
              ),
          'history': (_) => MyAttendanceHistoryScreen(
                embedded: true,
                initialRecords: widget.initialAttendanceRecords,
              ),
        },
      ),
    );
  }
}

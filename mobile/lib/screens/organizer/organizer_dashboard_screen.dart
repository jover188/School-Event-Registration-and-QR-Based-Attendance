import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../models/event_model.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/reports_screen.dart';
import 'event_form_screen.dart';
import 'event_registrations_screen.dart';
import 'live_attendance_screen.dart';
import 'qr_scanner_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<EventModel> _myEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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
        title: const Text('Organizer Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Reports & Exports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
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
            tooltip: 'Refresh Dashboard',
            onPressed: _isLoading ? null : _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('organizer-create-event-fab'),
        onPressed: _openCreateEvent,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _myEvents.isEmpty
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchDashboardData,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDashboardData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        88,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Total Events',
                                  value: '${_stats['total_events'] ?? 0}',
                                  icon: Icons.event_note_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Published',
                                  value: '${_stats['published_events'] ?? 0}',
                                  icon: Icons.public,
                                  color: AppColors.present,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Ongoing',
                                  value: '${_stats['ongoing_events'] ?? 0}',
                                  icon: Icons.sensors,
                                  color: AppColors.late,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionHeader(
                            title: 'Manage Events & Scan Attendance',
                            subtitle:
                                'Edit drafts, manage registrations, monitor live attendance, and scan QR codes',
                            actionLabel: 'Reports',
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          if (_myEvents.isEmpty)
                            EmptyStateView(
                              icon: Icons.event_busy_outlined,
                              title: 'No events found.',
                              message:
                                  'Create a new event draft or refresh your dashboard.',
                              actionLabel: 'Create Event',
                              onAction: _openCreateEvent,
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _myEvents.length,
                              itemBuilder: (context, index) {
                                final event = _myEvents[index];
                                return _OrganizerEventManagementCard(
                                  event: event,
                                  onEdit: () => _openEditEvent(event),
                                  onRegistrations: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EventRegistrationsScreen(
                                          eventId: event.id,
                                          eventTitle: event.title,
                                          canCancel: true,
                                        ),
                                      ),
                                    );
                                  },
                                  onLiveAttendance: () {
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
                                  },
                                  onScanQr: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            QrScannerScreen(event: event),
                                      ),
                                    );
                                  },
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

class _OrganizerEventManagementCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onRegistrations;
  final VoidCallback onLiveAttendance;
  final VoidCallback onScanQr;

  const _OrganizerEventManagementCard({
    required this.event,
    required this.onEdit,
    required this.onRegistrations,
    required this.onLiveAttendance,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventCard(
          event: event,
          onTap: onEdit,
          showEventStatusBadge: true,
          showCapacity: true,
          trailingAction: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
            ),
            onPressed: onScanQr,
            icon: const Icon(
              Icons.qr_code_scanner,
              size: 18,
            ),
            label: const Text(
              'Open Scanner',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  event.status == 'draft' ? 'Edit / Submit' : 'Edit Event',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRegistrations,
                icon: const Icon(Icons.people_alt_outlined, size: 16),
                label: const Text(
                  'Registrations',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onLiveAttendance,
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text(
                  'Live Attendance',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/event_card.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../models/event_model.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import 'event_detail_screen.dart';
import 'my_attendance_history_screen.dart';
import 'my_registrations_screen.dart';
import 'permanent_qr_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<EventModel> _events = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (!response.success) {
        _errorMessage = response.message ?? 'Unable to load campus events.';
      }
      if (dashResponse.success && dashResponse.data is Map<String, dynamic>) {
        _stats = dashResponse.data['stats'] as Map<String, dynamic>?;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'My Permanent QR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermanentQrScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
              _fetchEvents();
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
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PermanentQrScreen()),
          );
        },
        icon: const Icon(Icons.qr_code, color: Colors.white),
        label: const Text(
          'My QR Code',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Student Dashboard Summary Metrics (SRS DASH-001)
            if (_stats != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StatMetricCard(
                        label: 'Registered',
                        value:
                            '${(_stats!['total_registered_events'] as num?)?.toInt() ?? 0}',
                        icon: Icons.event_available,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyRegistrationsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatMetricCard(
                        label: 'Attended',
                        value:
                            '${(_stats!['total_attended_events'] as num?)?.toInt() ?? 0}',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.present,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyAttendanceHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatMetricCard(
                        label: 'Unread Alerts',
                        value:
                            '${(_stats!['unread_notifications'] as num?)?.toInt() ?? 0}',
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.late,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                          _fetchEvents();
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Navigation Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 4,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyRegistrationsScreen(),
                          ),
                        );
                        _fetchEvents();
                      },
                      icon: const Icon(Icons.event_note_outlined, size: 18),
                      label: const Text(
                        'My Registrations',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyAttendanceHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history_outlined, size: 18),
                      label: const Text(
                        'Attendance History',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search events by title or venue',
                  hintText: 'Search events or venues...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _fetchEvents();
                          },
                        )
                      : null,
                ),
                onSubmitted: (val) {
                  setState(() => _searchQuery = val.trim());
                  _fetchEvents();
                },
              ),
            ),

            // Events List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _events.isEmpty
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchEvents,
                        )
                      : _events.isEmpty
                          ? EmptyStateView(
                              icon: Icons.event_busy,
                              title: 'No upcoming events found.',
                              message:
                                  'Check back soon or adjust your search filters.',
                              actionLabel: 'Refresh',
                              onAction: _fetchEvents,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchEvents,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                  80,
                                ),
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  final event = _events[index];
                                  return EventCard(
                                    event: event,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EventDetailScreen(event: event),
                                        ),
                                      );
                                      _fetchEvents();
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

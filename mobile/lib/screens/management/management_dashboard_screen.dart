import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  State<ManagementDashboardScreen> createState() => _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _statusBreakdown = {};
  List<dynamic> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final response = await ApiClient().get(ApiConstants.dashboard('management'));

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      setState(() {
        _metrics = response.data['overall_metrics'] ?? {};
        _statusBreakdown = response.data['attendance_by_status'] ?? {};
        _recentEvents = response.data['recent_events'] ?? [];
      });
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

  Widget _buildMetricTile(String title, dynamic val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            '$val',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Management (Read-Only)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Executive Overview: Read-only institutional participation metrics.',
                              style: TextStyle(fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Overall Metrics Grid
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('Overall Turnout', _metrics['overall_turnout_rate'] ?? '0%', AppTheme.presentColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricTile('Total Events', _metrics['total_events'] ?? 0, AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildMetricTile('Total Registered', _metrics['total_registrations'] ?? 0, AppTheme.accent)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricTile('Total Attended', _metrics['total_attendances'] ?? 0, AppTheme.lateColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Attendance Breakdown
                    const Text('Attendance Status Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildStatusRow('Present on Time', _statusBreakdown['present'] ?? 0, AppTheme.presentColor),
                            const Divider(height: 16),
                            _buildStatusRow('Late Arrival', _statusBreakdown['late'] ?? 0, AppTheme.lateColor),
                            const Divider(height: 16),
                            _buildStatusRow('Walk-In Attendees', _statusBreakdown['walk_in'] ?? 0, AppTheme.walkInColor),
                            const Divider(height: 16),
                            _buildStatusRow('Excused Absences', _statusBreakdown['excused'] ?? 0, AppTheme.excusedColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Events
                    const Text('Recent Events & Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentEvents.length,
                      itemBuilder: (ctx, i) {
                        final e = _recentEvents[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${e['event_date']} • ${e['venue']}'),
                            trailing: Text(
                              '${e['attendances_count'] ?? 0} Attended',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.presentColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, dynamic count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

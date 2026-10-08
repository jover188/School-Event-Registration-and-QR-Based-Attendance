import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _pendingEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);

    final response = await ApiClient().get(ApiConstants.dashboard('admin'));

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      setState(() {
        _stats = response.data['stats'] ?? {};
        _pendingEvents = response.data['pending_approval_events'] ?? [];
      });
    }
  }

  Future<void> _reviewEvent(int eventId, String action) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action == 'approved' ? 'Approve' : 'Reject'} Event?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Confirm $action of event publishing.'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved' ? AppTheme.presentColor : AppTheme.absentColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await ApiClient().post('/admin/events/$eventId/review', {
        'action': action,
        'remarks': remarksController.text.trim(),
      });

      if (response.success) {
        _fetchAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: action == 'approved' ? AppTheme.presentColor : Colors.grey,
            content: Text('Event publishing has been $action.'),
          ),
        );
      }
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
        title: const Text('Administrator Console'),
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
              onRefresh: _fetchAdminData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat row
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: AppTheme.lateColor.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${_stats['pending_event_approvals'] ?? 0}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.lateColor),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Pending Approvals', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${_stats['total_users'] ?? 0}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Total Users', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pending Approvals Queue
                    const Text('Event Approval Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (_pendingEvents.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No events currently pending review.', style: TextStyle(color: Colors.black54)),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingEvents.length,
                        itemBuilder: (ctx, i) {
                          final event = _pendingEvents[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Venue: ${event['venue']} • Date: ${event['event_date']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Organizer: ${event['organizer']?['email'] ?? 'N/A'}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                  const Divider(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _reviewEvent(event['id'], 'rejected'),
                                        child: const Text('Reject', style: TextStyle(color: AppTheme.absentColor)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.presentColor),
                                        onPressed: () => _reviewEvent(event['id'], 'approved'),
                                        child: const Text('Approve & Publish'),
                                      ),
                                    ],
                                  ),
                                ],
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
}

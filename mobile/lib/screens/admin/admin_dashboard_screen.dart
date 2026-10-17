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
import '../organizer/event_form_screen.dart';
import 'activity_logs_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<dynamic> _pendingEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
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
      setState(() {
        _stats = (response.data['stats'] as Map<String, dynamic>?) ?? {};
        _pendingEvents =
            (response.data['pending_approval_events'] as List?) ?? [];
      });
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Failed to load administrator dashboard.';
      });
    }
  }

  Future<void> _reviewEvent(int eventId, String action) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewEventApprovalDialog(action: action),
    );

    if (remarks == null || !mounted) return;

    final response = await ApiClient().post(
      ApiConstants.adminReviewEvent(eventId),
      {
        'action': action,
        'remarks': remarks,
      },
    );

    if (!mounted) return;

    if (response.success) {
      _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: action == 'approved'
              ? AppColors.present
              : AppColors.textSecondary,
          content: Text('Event publishing has been $action.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
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

    final response = await ApiClient().post(
      ApiConstants.adminAnnouncements,
      {
        'title': payload.title,
        'message': payload.message,
        'target_role': payload.targetRole,
      },
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'System announcement broadcast successfully.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
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
    if (created == true && mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Broadcast Announcement',
            onPressed: _openBroadcastAnnouncementDialog,
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
            tooltip: 'Refresh Console',
            onPressed: _isLoading ? null : _fetchAdminData,
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
            : _errorMessage != null && _stats.isEmpty
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchAdminData,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAdminData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stat row
                          Row(
                            children: [
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Pending Approvals',
                                  value:
                                      '${_stats['pending_event_approvals'] ?? 0}',
                                  icon: Icons.pending_actions_outlined,
                                  color: AppColors.late,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 4),
                              Expanded(
                                child: StatMetricCard(
                                  label: 'Total Users',
                                  value: '${_stats['total_users'] ?? 0}',
                                  icon: Icons.people_outline,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const UserManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Quick Administrative Modules
                          const SectionHeader(
                            title: 'Administrative Modules',
                            subtitle:
                                'Manage accounts, inspect audit logs, export reports, and broadcast notices',
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),
                          _AdminQuickActionsGrid(
                            onOpenUsers: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserManagementScreen(),
                                ),
                              );
                            },
                            onOpenLogs: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ActivityLogsScreen(),
                                ),
                              );
                            },
                            onOpenReports: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              );
                            },
                            onCreateEvent: _openCreateEvent,
                            onBroadcastAnnouncement:
                                _openBroadcastAnnouncementDialog,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Pending Approvals Queue
                          const SectionHeader(
                            title: 'Event Approval Queue',
                            subtitle:
                                'Review organizer submissions before campus-wide publication',
                          ),
                          const SizedBox(height: AppSpacing.sm + 4),

                          if (_pendingEvents.isEmpty)
                            const Card(
                              child: EmptyStateView(
                                icon: Icons.verified_outlined,
                                title: 'No events currently pending review.',
                                message:
                                    'All submitted organizer events have been processed.',
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _pendingEvents.length,
                              itemBuilder: (ctx, i) {
                                final event =
                                    _pendingEvents[i] as Map<String, dynamic>;
                                final eventId = (event['id'] as num).toInt();
                                return _PendingApprovalEventCard(
                                  event: event,
                                  onApprove: () =>
                                      _reviewEvent(eventId, 'approved'),
                                  onReject: () =>
                                      _reviewEvent(eventId, 'rejected'),
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

class _AdminQuickActionsGrid extends StatelessWidget {
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenLogs;
  final VoidCallback onOpenReports;
  final VoidCallback onCreateEvent;
  final VoidCallback onBroadcastAnnouncement;

  const _AdminQuickActionsGrid({
    required this.onOpenUsers,
    required this.onOpenLogs,
    required this.onOpenReports,
    required this.onCreateEvent,
    required this.onBroadcastAnnouncement,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          key: const ValueKey<String>('admin-nav-users'),
          onPressed: onOpenUsers,
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('User Management'),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('admin-nav-logs'),
          onPressed: onOpenLogs,
          icon: const Icon(Icons.history_edu_outlined),
          label: const Text('Activity Logs'),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('admin-nav-reports'),
          onPressed: onOpenReports,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Reports & Exports'),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('admin-nav-create-event'),
          onPressed: onCreateEvent,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Create Event'),
        ),
        ElevatedButton.icon(
          key: const ValueKey<String>('admin-nav-broadcast'),
          onPressed: onBroadcastAnnouncement,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Broadcast Announcement'),
        ),
      ],
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
                    event['title']?.toString() ?? '',
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  status: event['status']?.toString() ?? 'pending_approval',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'Venue: ${event['venue']} • Date: ${event['event_date']}',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Organizer: ${event['organizer']?['email'] ?? 'N/A'}',
              style: AppTypography.caption,
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: AppColors.absent),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.present,
                  ),
                  onPressed: onApprove,
                  child: const Text('Approve & Publish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewEventApprovalDialog extends StatefulWidget {
  final String action;

  const _ReviewEventApprovalDialog({required this.action});

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
    final isApprove = widget.action == 'approved';
    return AlertDialog(
      title: Text('${isApprove ? 'Approve' : 'Reject'} Event?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Confirm ${widget.action} of event publishing.'),
          const SizedBox(height: AppSpacing.sm + 4),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              hintText: 'Add review notes for the organizer',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isApprove ? AppColors.present : AppColors.absent,
          ),
          onPressed: () =>
              Navigator.pop(context, _remarksController.text.trim()),
          child: Text(widget.action.toUpperCase()),
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
    return AlertDialog(
      title: const Text('Broadcast System Announcement'),
      content: FocusTraversalGroup(
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
                    initialValue: _targetRole,
                    decoration: const InputDecoration(
                      labelText: 'Target Audience Role',
                      helperText: ' ',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Active Users'),
                      ),
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Students Only'),
                      ),
                      DropdownMenuItem(
                        value: 'organizer',
                        child: Text('Event Organizers Only'),
                      ),
                      DropdownMenuItem(
                        value: 'management',
                        child: Text('School Management Only'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _targetRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    key: const ValueKey<String>('announcement-title-field'),
                    controller: _titleController,
                    focusNode: _titleFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title',
                      hintText: 'e.g. Campus Maintenance Schedule',
                      helperText: ' ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    key: const ValueKey<String>('announcement-message-field'),
                    controller: _messageController,
                    focusNode: _messageFocus,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.multiline,
                    autofillHints: const [AutofillHints.name],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Announcement Message',
                      hintText: 'Enter announcement body text',
                      helperText: ' ',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Send Broadcast'),
        ),
      ],
    );
  }
}

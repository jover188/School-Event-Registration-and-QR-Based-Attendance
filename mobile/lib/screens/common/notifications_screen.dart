import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  int get _unreadCount => _notifications
      .where((n) => n['is_read'] != true && n['is_read'] != 1)
      .length;

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.notifications);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _notifications = (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } else if (!response.success) {
        _errorMessage = response.message ?? 'Failed to load notifications.';
      }
    });
  }

  Future<void> _markSingleRead(int index) async {
    final item = _notifications[index];
    final isRead = item['is_read'] == true || item['is_read'] == 1;
    if (isRead) return;

    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;

    final response =
        await ApiClient().patch(ApiConstants.markNotificationRead(id), {});

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _notifications[index] = {
          ...item,
          'is_read': true,
        };
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;

    final response =
        await ApiClient().post(ApiConstants.markAllNotificationsRead, {});

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _notifications = _notifications
            .map((item) => {...item, 'is_read': true})
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.present,
          content: Text('All notifications marked as read.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            tooltip: 'Notification Preferences',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Unread summary bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unread > 0
                        ? '$unread unread notification${unread == 1 ? '' : 's'}'
                        : 'All caught up',
                    style: AppTypography.bodyMuted.copyWith(
                      fontWeight: FontWeight.w600,
                      color: unread > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  StatusBadge(
                    status: unread > 0 ? 'pending' : 'active',
                    label: '$unread UNREAD',
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _notifications.isEmpty
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchNotifications,
                        )
                      : _notifications.isEmpty
                          ? EmptyStateView(
                              icon: Icons.notifications_none_rounded,
                              title: 'No notifications yet',
                              message:
                                  'Attendance receipts, event updates, and reminders will appear here.',
                              actionLabel: 'Refresh',
                              onAction: _fetchNotifications,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final item = _notifications[index];
                                  final isRead = item['is_read'] == true ||
                                      item['is_read'] == 1;
                                  return _NotificationTile(
                                    notification: item,
                                    isRead: isRead,
                                    onTap: () => _markSingleRead(index),
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

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    return switch (type) {
      'attendance_recorded' => Icons.verified_user_outlined,
      'event_cancellation' => Icons.cancel_outlined,
      'waiting_list_promoted' => Icons.trending_up,
      'registration_confirmed' => Icons.event_available_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'general';
    final createdAt = notification['created_at']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      color: isRead ? AppColors.card : AppColors.primaryLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isRead
                    ? AppColors.surface
                    : AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  _iconForType(type),
                  size: 20,
                  color: isRead ? AppColors.textSecondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.subtitle.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        createdAt,
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

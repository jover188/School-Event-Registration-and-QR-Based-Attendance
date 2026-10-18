import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialNotifications;

  const NotificationsScreen({super.key, this.initialNotifications});

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
    if (widget.initialNotifications != null) {
      _isLoading = false;
      _notifications = widget.initialNotifications!
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      _fetchNotifications();
    }
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
    final d = context.design;
    final unread = _unreadCount;

    return AppPageScaffold(
      title: 'Notifications',
      maxWidth: 720,
      actions: [
        if (unread > 0)
          AppButton(
            variant: AppButtonVariant.ghost,
            pill: true,
            icon: LucideIcons.checkCheck,
            onPressed: _markAllRead,
            label: 'Mark All Read',
          ),
        IconButton(
          tooltip: 'Notification Preferences',
          icon: const Icon(LucideIcons.settings, size: 20),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: d.sm,
              runSpacing: d.xs,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unread > 0
                          ? '$unread unread notification${unread == 1 ? '' : 's'}'
                          : 'All caught up',
                      style: d.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: unread > 0 ? d.primary : d.foreground,
                      ),
                    ),
                    Text(
                      'Notification history is retained for 30 days.',
                      style: d.supporting,
                    ),
                  ],
                ),
                StatusBadge(
                  status: unread > 0 ? 'pending' : 'active',
                  label: '$unread UNREAD',
                ),
              ],
            ),
          ),
          SizedBox(height: d.md),
          Expanded(
            child: _isLoading
                ? Center(child: AppSpinner(color: d.authDark, size: 28))
                : _errorMessage != null && _notifications.isEmpty
                    ? ErrorStateView(
                        message: _errorMessage!,
                        onRetry: _fetchNotifications,
                      )
                    : _notifications.isEmpty
                        ? EmptyStateView(
                            icon: LucideIcons.bell,
                            title: 'No notifications yet',
                            message:
                                'Attendance receipts, event updates, and reminders will appear here.',
                            actionLabel: 'Refresh',
                            onAction: _fetchNotifications,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            child: ListView.builder(
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
      'attendance_recorded' => LucideIcons.shieldCheck,
      'event_cancellation' => LucideIcons.calendarX,
      'waiting_list_promoted' => LucideIcons.arrowUpRight,
      'registration_confirmed' => LucideIcons.calendarCheck,
      _ => LucideIcons.bell,
    };
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'general';
    final createdAt = notification['created_at']?.toString() ?? '';

    final tileContent = Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: isRead
            ? d.card
            : (d.isDark ? d.selection : const Color(0xFFFBFBFA)),
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: isRead
              ? (d.isDark ? d.border : d.authDark.withValues(alpha: 0.08))
              : d.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(d.sm + 2),
            decoration: BoxDecoration(
              color: isRead ? d.muted : d.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForType(type),
              size: 20,
              color: isRead ? d.mutedForeground : d.primary,
            ),
          ),
          SizedBox(width: d.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: d.cardTitle.copyWith(
                          fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: d.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: d.xs),
                Text(
                  message,
                  style: d.supporting.copyWith(color: d.foreground),
                ),
                if (createdAt.isNotEmpty) ...[
                  SizedBox(height: d.xs + 2),
                  Text(
                    createdAt,
                    style: d.supporting,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: d.gap),
      child: AppPressable(
        semanticLabel: '$title: $message',
        onPressed: onTap,
        child: tileContent,
      ),
    );
  }
}


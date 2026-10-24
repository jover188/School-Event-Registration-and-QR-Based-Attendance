import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic>? initialPreferences;

  const NotificationPreferencesScreen({super.key, this.initialPreferences});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool _newEventPublished = true;
  bool _registrationConfirmed = true;
  bool _eventReminders = true;
  bool _eventUpdates = true;
  bool _waitingListPromoted = true;
  bool _adminAnnouncements = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPreferences != null) {
      _isLoading = false;
      _applyPreferences(widget.initialPreferences!);
    } else {
      _fetchPreferences();
    }
  }

  void _applyPreferences(Map<String, dynamic> data) {
    _newEventPublished = _parseBool(data['new_event_published']);
    _registrationConfirmed = _parseBool(data['registration_confirmed']);
    _eventReminders = _parseBool(data['event_reminders']);
    _eventUpdates = _parseBool(data['event_updates']);
    _waitingListPromoted = _parseBool(data['waiting_list_promoted']);
    _adminAnnouncements = _parseBool(data['admin_announcements']);
  }

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val == '1' || val.toLowerCase() == 'true';
    return true;
  }

  Future<void> _fetchPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response =
        await ApiClient().get(ApiConstants.notificationPreferences);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is Map<String, dynamic>) {
        _applyPreferences(response.data as Map<String, dynamic>);
      } else if (!response.success) {
        _errorMessage =
            response.message ?? 'Failed to load notification preferences.';
      }
    });
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    final response = await ApiClient().put(
      ApiConstants.notificationPreferences,
      {
        'new_event_published': _newEventPublished,
        'registration_confirmed': _registrationConfirmed,
        'event_reminders': _eventReminders,
        'event_updates': _eventUpdates,
        'waiting_list_promoted': _waitingListPromoted,
        'admin_announcements': _adminAnnouncements,
      },
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            response.success ? AppColors.present : AppColors.absent,
        content: Text(
          response.message ??
              (response.success
                  ? 'Notification preferences updated.'
                  : 'Failed to save preferences.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AppPageScaffold(
      title: 'Notification Preferences',
      maxWidth: 720,
      actions: [
        AppIconButton(
          tooltip: 'Refresh Preferences',
          icon: LucideIcons.refreshCw,
          onPressed: _isLoading ? null : _fetchPreferences,
        ),
      ],
      body: _isLoading
          ? Center(child: AppSpinner(color: d.authDark, size: 28))
          : _errorMessage != null
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchPreferences,
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mandatory Critical Notifications (SRS NOTIF-004)
                      const SectionHeader(
                        title: 'Mandatory Critical Alerts',
                        subtitle:
                            'Required by school policy (SRS NOTIF-004) and cannot be disabled.',
                      ),
                      SizedBox(height: d.sm),
                      Container(
                        decoration: BoxDecoration(
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
                        child: Material(
                          color: d.card,
                          borderRadius: BorderRadius.circular(d.radiusCard),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: true,
                                onChanged: null,
                                secondary: Icon(
                                  LucideIcons.lock,
                                  size: 20,
                                  color: d.destructive,
                                ),
                                title: Wrap(
                                  spacing: d.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Event Cancellations',
                                      style: d.cardTitle,
                                    ),
                                    const StatusBadge(
                                      status: 'active',
                                      label: 'LOCKED',
                                      showIcon: false,
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Mandatory per school policy (SRS NOTIF-004) — immediate notice when a registered event is cancelled.',
                                  style: d.supporting,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: true,
                                onChanged: null,
                                secondary: Icon(
                                  LucideIcons.lock,
                                  size: 20,
                                  color: d.success,
                                ),
                                title: Wrap(
                                  spacing: d.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Attendance Confirmation',
                                      style: d.cardTitle,
                                    ),
                                    const StatusBadge(
                                      status: 'active',
                                      label: 'LOCKED',
                                      showIcon: false,
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'Mandatory per school policy (SRS NOTIF-004) — real-time receipt when your QR code is scanned.',
                                  style: d.supporting,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: d.lg),

                      // Optional Notification Preferences
                      const SectionHeader(
                        title: 'Optional Notifications',
                        subtitle:
                            'Customize non-critical event reminders and announcements.',
                      ),
                      SizedBox(height: d.sm),
                      Container(
                        decoration: BoxDecoration(
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
                        child: Material(
                          color: d.card,
                          borderRadius: BorderRadius.circular(d.radiusCard),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                          children: [
                            SwitchListTile(
                              value: _newEventPublished,
                              onChanged: (val) =>
                                   setState(() => _newEventPublished = val),
                              title: Text(
                                'New Events Published',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'Notify me when new campus events open for registration.',
                                style: d.supporting,
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _registrationConfirmed,
                              onChanged: (val) => setState(
                                () => _registrationConfirmed = val,
                              ),
                              title: Text(
                                'Registration Confirmed',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'Confirmations when you register or join a waiting list.',
                                style: d.supporting,
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _waitingListPromoted,
                              onChanged: (val) =>
                                  setState(() => _waitingListPromoted = val),
                              title: Text(
                                'Waiting List Promotions',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'Alerts when a slot opens and you are promoted to registered.',
                                style: d.supporting,
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _eventReminders,
                              onChanged: (val) =>
                                  setState(() => _eventReminders = val),
                              title: Text(
                                'Upcoming Event Reminders',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'Reminders 24 hours and 1 hour before registered events.',
                                style: d.supporting,
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _eventUpdates,
                              onChanged: (val) =>
                                  setState(() => _eventUpdates = val),
                              title: Text(
                                'Event Schedule & Venue Updates',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'Changes to event venue, date, or time.',
                                style: d.supporting,
                              ),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _adminAnnouncements,
                              onChanged: (val) =>
                                  setState(() => _adminAnnouncements = val),
                              title: Text(
                                'Campus Announcements',
                                style: d.cardTitle,
                              ),
                              subtitle: Text(
                                'General broadcasts from school administration.',
                                style: d.supporting,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      SizedBox(height: d.lg),

                      AppButton(
                        key: const ValueKey<String>(
                          'save-notification-preferences-button',
                        ),
                        pill: true,
                        onPressed: _isSaving ? null : _savePreferences,
                        isLoading: _isSaving,
                        icon: LucideIcons.save,
                        label: 'Save Preferences',
                      ),
                    ],
                  ),
                ),
    );
  }
}


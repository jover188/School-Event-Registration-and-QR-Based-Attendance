import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

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
    _fetchPreferences();
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
        final data = response.data as Map<String, dynamic>;
        _newEventPublished = _parseBool(data['new_event_published']);
        _registrationConfirmed = _parseBool(data['registration_confirmed']);
        _eventReminders = _parseBool(data['event_reminders']);
        _eventUpdates = _parseBool(data['event_updates']);
        _waitingListPromoted = _parseBool(data['waiting_list_promoted']);
        _adminAnnouncements = _parseBool(data['admin_announcements']);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          IconButton(
            tooltip: 'Refresh Preferences',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchPreferences,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchPreferences,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mandatory Critical Notifications (SRS NOTIF-004)
                        const SectionHeader(
                          title: 'Mandatory Critical Alerts',
                          subtitle:
                              'Required by school policy (SRS NOTIF-004) and cannot be disabled.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: true,
                                onChanged: null,
                                secondary: Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.absent,
                                ),
                                title: Text(
                                  'Event Cancellations',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: Text(
                                  'Mandatory per school policy (SRS NOTIF-004) — immediate notice when a registered event is cancelled.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              Divider(height: 1),
                              SwitchListTile(
                                value: true,
                                onChanged: null,
                                secondary: Icon(
                                  Icons.qr_code_scanner,
                                  color: AppColors.present,
                                ),
                                title: Text(
                                  'Attendance Confirmation',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: Text(
                                  'Mandatory per school policy (SRS NOTIF-004) — real-time receipt when your QR code is scanned.',
                                  style: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Optional Notification Preferences
                        const SectionHeader(
                          title: 'Optional Notifications',
                          subtitle:
                              'Customize non-critical event reminders and announcements.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _newEventPublished,
                                onChanged: (val) =>
                                    setState(() => _newEventPublished = val),
                                title: const Text(
                                  'New Events Published',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'Notify me when new campus events open for registration.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: _registrationConfirmed,
                                onChanged: (val) => setState(
                                  () => _registrationConfirmed = val,
                                ),
                                title: const Text(
                                  'Registration Confirmed',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'Confirmations when you register or join a waiting list.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: _waitingListPromoted,
                                onChanged: (val) =>
                                    setState(() => _waitingListPromoted = val),
                                title: const Text(
                                  'Waiting List Promotions',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'Alerts when a slot opens and you are promoted to registered.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: _eventReminders,
                                onChanged: (val) =>
                                    setState(() => _eventReminders = val),
                                title: const Text(
                                  'Upcoming Event Reminders',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'Reminders 24 hours and 1 hour before registered events.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: _eventUpdates,
                                onChanged: (val) =>
                                    setState(() => _eventUpdates = val),
                                title: const Text(
                                  'Event Schedule & Venue Updates',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'Changes to event venue, date, or time.',
                                  style: AppTypography.caption,
                                ),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                value: _adminAnnouncements,
                                onChanged: (val) =>
                                    setState(() => _adminAnnouncements = val),
                                title: const Text(
                                  'Campus Announcements',
                                  style: AppTypography.subtitle,
                                ),
                                subtitle: const Text(
                                  'General broadcasts from school administration.',
                                  style: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        ElevatedButton.icon(
                          key: const ValueKey<String>(
                            'save-notification-preferences-button',
                          ),
                          onPressed: _isSaving ? null : _savePreferences,
                          icon: const Icon(Icons.save_outlined),
                          label: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Preferences'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

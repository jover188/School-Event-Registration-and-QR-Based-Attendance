import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _event;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _refreshEventDetails();
  }

  Future<void> _refreshEventDetails() async {
    final response =
        await ApiClient().get(ApiConstants.eventDetail(_event.id));
    if (!mounted) return;
    if (response.success && response.data is Map<String, dynamic>) {
      setState(() {
        _event = EventModel.fromJson(response.data as Map<String, dynamic>);
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final response =
        await ApiClient().post(ApiConstants.registerEvent(_event.id), {});
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      await _refreshEventDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(response.message ?? 'Registration successful!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(response.message ?? 'Registration failed.'),
        ),
      );
    }
  }

  Future<void> _handleCancelRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Registration?'),
        content: const Text(
          'Are you sure you want to cancel your registration for this event? Your slot will be given to the next student on the waiting list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Registration'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final response =
          await ApiClient().delete(ApiConstants.cancelRegistration(_event.id));
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        await _refreshEventDetails();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.textSecondary,
            content: Text('Your registration has been cancelled.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.absent,
            content: Text(response.message ?? 'Cancellation failed.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _event.remainingSlots;
    final isFull = remaining != null && remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_event.title),
        actions: [
          IconButton(
            tooltip: 'Refresh Event Details',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshEventDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _event.title,
                              style: AppTypography.headline.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(status: _event.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _EventInfoRow(
                        icon: Icons.location_on_outlined,
                        text: _event.venue,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      _EventInfoRow(
                        icon: Icons.calendar_today_outlined,
                        text:
                            '${_event.eventDate} • ${_event.startTime} - ${_event.endTime}',
                      ),
                      const Divider(height: AppSpacing.lg),

                      // Capacity indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remaining Capacity',
                                style: AppTypography.caption,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                remaining == null
                                    ? 'Unlimited Slots'
                                    : '$remaining slots left',
                                style: AppTypography.subtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isFull
                                      ? AppColors.late
                                      : AppColors.present,
                                ),
                              ),
                            ],
                          ),
                          if (_event.userRegistrationStatus != null)
                            StatusBadge(
                              status: _event.userRegistrationStatus!,
                              label: _event.isRegistered
                                  ? 'REGISTERED'
                                  : 'WAITING LIST #${_event.userWaitingPosition ?? 1}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Description Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'About the Event'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _event.description,
                        style: AppTypography.body,
                      ),
                      if (_event.walkInAllowed) ...[
                        const SizedBox(height: AppSpacing.sm + 4),
                        const _EventInfoRow(
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.present,
                          text: 'Walk-in attendees permitted at venue',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              if (_event.isRegistered || _event.isWaitingList) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.absent,
                    side: const BorderSide(color: AppColors.absent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleCancelRegistration,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel My Registration'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFull ? AppColors.late : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  icon: Icon(isFull ? Icons.queue : Icons.how_to_reg),
                  label: Text(
                    isFull ? 'Join Waiting List' : 'Register for Event',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _EventInfoRow({
    required this.icon,
    this.iconColor = AppColors.textSecondary,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}

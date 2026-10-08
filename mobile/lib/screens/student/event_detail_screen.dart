import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
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
    final response = await ApiClient().get(ApiConstants.eventDetails(_event.id));
    if (response.success && response.data != null) {
      setState(() {
        _event = EventModel.fromJson(response.data);
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final response = await ApiClient().post(ApiConstants.registerEvent(_event.id), {});
    setState(() => _isLoading = false);

    if (response.success) {
      await _refreshEventDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.presentColor,
          content: Text(response.message ?? 'Registration successful!'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.absentColor,
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
        content: const Text('Are you sure you want to cancel your registration for this event? Your slot will be given to the next student on the waiting list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Registration')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.absentColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final response = await ApiClient().delete(ApiConstants.cancelRegistration(_event.id));
      setState(() => _isLoading = false);

      if (response.success) {
        await _refreshEventDetails();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.grey,
            content: Text('Your registration has been cancelled.'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.absentColor,
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
      appBar: AppBar(title: Text(_event.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(_event.venue, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text('${_event.eventDate} • ${_event.startTime} - ${_event.endTime}', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const Divider(height: 24),

                    // Capacity indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Remaining Capacity', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Text(
                              remaining == null ? 'Unlimited Slots' : '$remaining slots left',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isFull ? AppTheme.lateColor : AppTheme.presentColor,
                              ),
                            ),
                          ],
                        ),
                        if (_event.userRegistrationStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _event.isRegistered
                                  ? AppTheme.presentColor.withOpacity(0.1)
                                  : AppTheme.lateColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _event.isRegistered
                                  ? 'REGISTERED'
                                  : 'WAITING LIST #${_event.userWaitingPosition ?? 1}',
                              style: TextStyle(
                                color: _event.isRegistered ? AppTheme.presentColor : AppTheme.lateColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About the Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_event.description, style: const TextStyle(height: 1.5, color: Colors.black87)),
                    const SizedBox(height: 12),
                    if (_event.walkInAllowed)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppTheme.presentColor),
                          SizedBox(width: 6),
                          Text('Walk-in attendees permitted at venue', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (_event.isRegistered || _event.isWaitingList) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.absentColor,
                  side: const BorderSide(color: AppTheme.absentColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _handleCancelRegistration,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel My Registration'),
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFull ? AppTheme.lateColor : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _handleRegister,
                icon: Icon(isFull ? Icons.queue : Icons.how_to_reg),
                label: Text(isFull ? 'Join Waiting List' : 'Register for Event'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

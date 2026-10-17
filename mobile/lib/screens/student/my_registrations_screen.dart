import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  static const List<({String label, String value})> _filters = [
    (label: 'All', value: 'all'),
    (label: 'Registered', value: 'registered'),
    (label: 'Waiting List', value: 'waiting_list'),
    (label: 'Walk-In', value: 'walk_in'),
    (label: 'Cancelled', value: 'cancelled'),
  ];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _registrations = [];

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  List<Map<String, dynamic>> get _filteredRegistrations {
    if (_selectedFilter == 'all') return _registrations;
    return _registrations
        .where((reg) => reg['status']?.toString() == _selectedFilter)
        .toList();
  }

  Future<void> _fetchRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.studentRegistrations);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _registrations = (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (!response.success) {
        _errorMessage =
            response.message ?? 'Failed to load your event registrations.';
      }
    });
  }

  Future<void> _confirmCancelRegistration(
    int eventId,
    String eventTitle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Registration?'),
        content: Text(
          'Are you sure you want to cancel your registration for "$eventTitle"? If you hold a confirmed slot, the next student on the waiting list will be automatically promoted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Slot'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final response =
        await ApiClient().delete(ApiConstants.cancelRegistration(eventId));

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Registration cancelled successfully.',
          ),
        ),
      );
      _fetchRegistrations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Could not cancel registration.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredRegistrations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registrations'),
        actions: [
          IconButton(
            tooltip: 'Refresh Registrations',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchRegistrations,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter.value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _registrations.isEmpty
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchRegistrations,
                        )
                      : items.isEmpty
                          ? EmptyStateView(
                              icon: Icons.event_note_outlined,
                              title: 'No registrations found',
                              message: _selectedFilter == 'all'
                                  ? 'Browse campus events to register or join a waiting list.'
                                  : 'No registrations match the selected status filter.',
                              actionLabel: 'Refresh',
                              onAction: _fetchRegistrations,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchRegistrations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final reg = items[index];
                                  return _RegistrationItemCard(
                                    registration: reg,
                                    onCancel: (eventId, title) =>
                                        _confirmCancelRegistration(
                                      eventId,
                                      title,
                                    ),
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

class _RegistrationItemCard extends StatelessWidget {
  final Map<String, dynamic> registration;
  final void Function(int eventId, String eventTitle) onCancel;

  const _RegistrationItemCard({
    required this.registration,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = registration['status']?.toString() ?? 'registered';
    final waitPos = registration['waiting_list_position'];
    final event = (registration['event'] as Map<String, dynamic>?) ?? {};
    final eventId =
        (registration['event_id'] as num? ?? event['id'] as num? ?? 0).toInt();
    final title = event['title']?.toString() ?? 'Campus Event';
    final venue = event['venue']?.toString() ?? 'Campus Venue';
    final eventDate = event['event_date']?.toString() ?? '';
    final startTime = event['start_time']?.toString() ?? '';
    final canCancel = status == 'registered' || status == 'waiting_list';

    final badgeLabel = status == 'waiting_list' && waitPos != null
        ? 'WAITING LIST #$waitPos'
        : null;

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
                    title,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  status: status,
                  label: badgeLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    venue,
                    style: AppTypography.bodyMuted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (eventDate.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      startTime.isNotEmpty
                          ? '$eventDate • $startTime'
                          : eventDate,
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                ],
              ),
            ],
            if (canCancel && eventId > 0) ...[
              const Divider(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.absent,
                    side: const BorderSide(color: AppColors.absent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => onCancel(eventId, title),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Registration'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

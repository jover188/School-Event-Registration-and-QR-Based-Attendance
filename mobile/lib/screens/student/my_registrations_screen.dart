import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class MyRegistrationsScreen extends StatefulWidget {
  final bool embedded;
  final List<Map<String, dynamic>>? initialRegistrations;
  final String? initialErrorMessage;

  const MyRegistrationsScreen({
    super.key,
    this.embedded = false,
    this.initialRegistrations,
    this.initialErrorMessage,
  });

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

  bool get _hasFixtureData =>
      widget.initialRegistrations != null || widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtureData) {
      _isLoading = false;
      _errorMessage = widget.initialErrorMessage;
      _registrations = (widget.initialRegistrations ?? const [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      _fetchRegistrations();
    }
  }

  List<Map<String, dynamic>> get _filteredRegistrations {
    if (_selectedFilter == 'all') return _registrations;
    return _registrations
        .where((reg) => reg['status']?.toString() == _selectedFilter)
        .toList();
  }

  Future<void> _fetchRegistrations() async {
    if (_hasFixtureData && widget.initialRegistrations != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _registrations = widget.initialRegistrations!
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
      return;
    }

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
    final d = context.design;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: d.destructive,
              foregroundColor: d.destructiveForeground,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final response =
        await ApiClient().delete(ApiConstants.cancelRegistration(eventId));

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.success,
          content: Text(
            response.message ?? 'Registration cancelled successfully.',
          ),
        ),
      );
      _fetchRegistrations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.destructive,
          content: Text(
            response.message ?? 'Could not cancel registration.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final items = _filteredRegistrations;

    return AppPageScaffold(
      title: 'My Registrations',
      embedded: widget.embedded,
      actions: [
        IconButton(
          tooltip: 'Refresh Registrations',
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _fetchRegistrations,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(bottom: d.gap),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter.value;
                return Padding(
                  padding: EdgeInsets.only(right: d.sm),
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
                            child: CustomScrollView(
                              slivers: [
                                ResponsiveCardSliver(
                                  itemCount: items.length,
                                  minItemWidth: 340,
                                  maxColumns: 2,
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
                              ],
                            ),
                          ),
          ),
        ],
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
    final d = context.design;
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

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: d.sm,
            runSpacing: d.xs,
            children: [
              Text(
                title,
                style: d.cardTitle,
              ),
              StatusBadge(
                status: status,
                label: badgeLabel,
              ),
            ],
          ),
          SizedBox(height: d.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: d.mutedForeground,
              ),
              SizedBox(width: d.xs),
              Expanded(
                child: Text(
                  venue,
                  style: d.supporting,
                  softWrap: true,
                ),
              ),
            ],
          ),
          if (eventDate.isNotEmpty) ...[
            SizedBox(height: d.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: d.mutedForeground,
                ),
                SizedBox(width: d.xs),
                Expanded(
                  child: Text(
                    startTime.isNotEmpty
                        ? '$eventDate • $startTime'
                        : eventDate,
                    style: d.supporting,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
          if (canCancel && eventId > 0) ...[
            Divider(height: d.lg, color: d.border),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                variant: AppButtonVariant.destructive,
                icon: Icons.cancel_outlined,
                onPressed: () => onCancel(eventId, title),
                label: 'Cancel Registration',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

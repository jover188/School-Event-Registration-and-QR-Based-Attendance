import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';
import 'event_detail_screen.dart';

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

  Future<void> _openRegistrationEventDetail(
    Map<String, dynamic> registration,
  ) async {
    final eventMap = Map<String, dynamic>.from(
      (registration['event'] as Map?) ?? const {},
    );
    final eventId =
        (registration['event_id'] as num? ?? eventMap['id'] as num? ?? 0)
            .toInt();
    if (eventId <= 0 && eventMap.isEmpty) return;

    eventMap['id'] ??= eventId;
    eventMap['user_registration_status'] ??= registration['status'];
    eventMap['user_waiting_position'] ??= registration['waiting_list_position'];
    final model = EventModel.fromJson(eventMap);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          eventId: eventId > 0 ? eventId : model.id,
          event: model,
          initialEvent: _hasFixtureData ? model : null,
        ),
      ),
    );
    if (!mounted) return;
    _fetchRegistrations();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final items = _filteredRegistrations;

    return AppPageScaffold(
      title: 'My Registrations',
      embedded: widget.embedded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(bottom: d.gap),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter.value;
                  return Padding(
                    padding: EdgeInsets.only(right: d.sm),
                    child: ChoiceChip(
                      key: ValueKey('registration-filter-${filter.value}'),
                      label: Text(filter.label),
                      selected: isSelected,
                      selectedColor: d.buttonPrimary,
                      backgroundColor: d.card,
                      labelStyle: d.supporting.copyWith(
                        color: isSelected
                            ? d.buttonPrimaryForeground
                            : d.foreground,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? d.buttonPrimary : d.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(d.radiusControl),
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter.value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: AppSpinner(
                      size: 28,
                      color: d.authDark,
                    ),
                  )
                : _errorMessage != null && _registrations.isEmpty
                    ? ErrorStateView(
                        message: _errorMessage!,
                        onRetry: _fetchRegistrations,
                      )
                    : items.isEmpty
                        ? EmptyStateView(
                            icon: LucideIcons.calendarX2,
                            title: 'No registrations found',
                            message: _selectedFilter == 'all'
                                ? 'Browse events to register or join a waiting list.'
                                : 'No registrations with this status.',
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
                                      onViewDetails: () =>
                                          _openRegistrationEventDetail(reg),
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
  final VoidCallback? onViewDetails;

  const _RegistrationItemCard({
    required this.registration,
    this.onViewDetails,
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

    final badgeLabel = status == 'waiting_list' && waitPos != null
        ? 'WAITING LIST #$waitPos'
        : null;

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendarCheck,
                size: 18,
                color: d.primary,
              ),
              SizedBox(width: d.sm),
              Expanded(
                child: Text(
                  title,
                  style: d.cardTitle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: d.sm),
              StatusBadge(
                status: status,
                label: badgeLabel,
              ),
            ],
          ),
          SizedBox(height: d.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 16,
                color: d.primary,
              ),
              SizedBox(width: d.sm),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: d.primary,
                ),
                SizedBox(width: d.sm),
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
          if (eventId > 0 && onViewDetails != null) ...[
            Divider(height: d.lg, color: d.border),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                key: ValueKey('view-registration-event-$eventId'),
                variant: AppButtonVariant.outline,
                pill: true,
                icon: LucideIcons.arrowUpRight,
                onPressed: onViewDetails,
                label: 'View Details',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

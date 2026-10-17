import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class EventRegistrationsScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool canCancel;

  const EventRegistrationsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.canCancel = true,
  });

  @override
  State<EventRegistrationsScreen> createState() =>
      _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _registrations = [];

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  Future<void> _fetchRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queryParams = <String, String>{};
    if (_selectedStatus != 'all') {
      queryParams['status'] = _selectedStatus;
    }

    final response = await ApiClient().get(
      ApiConstants.eventRegistrations(widget.eventId),
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _registrations = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        _errorMessage =
            response.message ?? 'Failed to load event registrations.';
      }
    });
  }

  Future<void> _confirmAndCancelRegistration(
    Map<String, dynamic> reg,
  ) async {
    if (!widget.canCancel) return;

    final regId = (reg['id'] as num?)?.toInt();
    if (regId == null) return;

    final student = (reg['student'] as Map<String, dynamic>?) ?? {};
    final fullName = _resolveStudentName(student);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Student Registration?'),
        content: Text(
          'Cancel registration for $fullName? If this student holds an active slot, the next waiting-list student will be automatically promoted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Registration'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final response = await ApiClient().delete(
      ApiConstants.staffCancelRegistration(widget.eventId, regId),
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Student registration cancelled successfully.',
          ),
        ),
      );
      _fetchRegistrations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to cancel student registration.',
          ),
        ),
      );
    }
  }

  static String _resolveStudentName(Map<String, dynamic> student) {
    final full = student['full_name']?.toString().trim() ?? '';
    if (full.isNotEmpty) return full;
    final first = student['first_name']?.toString().trim() ?? '';
    final last = student['last_name']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'Student' : combined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrations: ${widget.eventTitle}'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.canCancel)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.primaryLight,
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Read-Only View: Registration mutations are disabled for School Management.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _RegistrationStatusFilterBar(
              selectedStatus: _selectedStatus,
              onSelectStatus: (status) {
                setState(() => _selectedStatus = status);
                _fetchRegistrations();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchRegistrations,
                        )
                      : _registrations.isEmpty
                          ? EmptyStateView(
                              icon: Icons.how_to_reg_outlined,
                              title: 'No registrations found.',
                              message:
                                  'No student registrations match the selected filter.',
                              actionLabel: 'Refresh',
                              onAction: _fetchRegistrations,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchRegistrations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: _registrations.length,
                                itemBuilder: (context, index) {
                                  final reg = _registrations[index];
                                  return _RegistrationItemCard(
                                    registration: reg,
                                    canCancel: widget.canCancel,
                                    onCancel: () =>
                                        _confirmAndCancelRegistration(reg),
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

class _RegistrationStatusFilterBar extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onSelectStatus;

  const _RegistrationStatusFilterBar({
    required this.selectedStatus,
    required this.onSelectStatus,
  });

  static const List<({String value, String label})> _filters = [
    (value: 'all', label: 'All'),
    (value: 'registered', label: 'Registered'),
    (value: 'waiting_list', label: 'Waiting List'),
    (value: 'walk_in', label: 'Walk-In'),
    (value: 'cancelled', label: 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          for (final filter in _filters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                key: ValueKey<String>('reg-filter-${filter.value}'),
                label: Text(filter.label),
                selected: selectedStatus == filter.value,
                onSelected: (_) => onSelectStatus(filter.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegistrationItemCard extends StatelessWidget {
  final Map<String, dynamic> registration;
  final bool canCancel;
  final VoidCallback onCancel;

  const _RegistrationItemCard({
    required this.registration,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final student =
        (registration['student'] as Map<String, dynamic>?) ?? {};
    final fullName =
        _EventRegistrationsScreenState._resolveStudentName(student);
    final studentIdNumber =
        student['student_id_number']?.toString() ?? 'N/A';
    final course = student['course']?.toString() ?? '';
    final yearLevel = student['year_level']?.toString() ?? '';
    final section = student['section']?.toString() ?? '';
    final status = registration['status']?.toString() ?? 'registered';
    final waitingPos = registration['waiting_list_position'];
    final registeredAt = registration['registered_at']?.toString() ?? '';

    final academicMeta = [
      if (course.isNotEmpty) course,
      if (yearLevel.isNotEmpty) yearLevel,
      if (section.isNotEmpty) 'Sec $section',
    ].join(' • ');

    final isCancellable =
        canCancel && (status == 'registered' || status == 'waiting_list');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge(
                        status: status,
                        label: status == 'waiting_list' && waitingPos != null
                            ? 'WAITING #$waitingPos'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Student ID: $studentIdNumber',
                    style: AppTypography.bodyMuted,
                  ),
                  if (academicMeta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      academicMeta,
                      style: AppTypography.caption,
                    ),
                  ],
                  if (registeredAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Registered: ${registeredAt.split('T').first}',
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
            if (isCancellable) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Cancel Student Registration',
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.absent,
                ),
                onPressed: onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

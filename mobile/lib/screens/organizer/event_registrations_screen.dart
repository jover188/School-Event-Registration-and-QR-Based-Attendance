import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';

class EventRegistrationsScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool canCancel;
  final List<Map<String, dynamic>>? initialRegistrations;
  final Map<String, int>? initialSummary;

  const EventRegistrationsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.canCancel = true,
    this.initialRegistrations,
    this.initialSummary,
  });

  @override
  State<EventRegistrationsScreen> createState() =>
      _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState extends State<EventRegistrationsScreen> {
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _registrations = [];
  Map<String, int> _summary = {
    'total': 0,
    'registered': 0,
    'waiting_list': 0,
    'walk_in': 0,
  };

  bool get _hasFixtures =>
      widget.initialRegistrations != null || widget.initialSummary != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtures) {
      _isLoading = false;
      _registrations = List<Map<String, dynamic>>.from(
        widget.initialRegistrations ?? const [],
      );
      _summary = _computeSummary(_registrations, widget.initialSummary);
    } else {
      _fetchRegistrations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static Map<String, int> _computeSummary(
    List<Map<String, dynamic>> items, [
    Map<String, int>? overrideSummary,
  ]) {
    if (overrideSummary != null) {
      return {
        'total': overrideSummary['total'] ?? items.length,
        'registered': overrideSummary['registered'] ?? 0,
        'waiting_list': overrideSummary['waiting_list'] ?? 0,
        'walk_in': overrideSummary['walk_in'] ?? 0,
      };
    }
    return {
      'total': items.length,
      'registered':
          items.where((r) => r['status']?.toString() == 'registered').length,
      'waiting_list':
          items.where((r) => r['status']?.toString() == 'waiting_list').length,
      'walk_in':
          items.where((r) => r['status']?.toString() == 'walk_in').length,
    };
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
        if (_selectedStatus == 'all') {
          _summary = _computeSummary(_registrations);
        }
      } else if (_registrations.isEmpty) {
        _errorMessage =
            response.message ?? 'Failed to load event registrations.';
      }
    });
  }

  List<Map<String, dynamic>> get _filteredRegistrations {
    final query = _searchController.text.trim().toLowerCase();
    return _registrations.where((reg) {
      final status = reg['status']?.toString().toLowerCase() ?? 'registered';
      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final student = (reg['student'] as Map<String, dynamic>?) ?? {};
      final fullName = _resolveStudentName(student).toLowerCase();
      final studentId =
          student['student_id_number']?.toString().toLowerCase() ?? '';
      final course = student['course']?.toString().toLowerCase() ?? '';
      return fullName.contains(query) ||
          studentId.contains(query) ||
          course.contains(query);
    }).toList();
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
    final d = context.design;
    final visibleRegistrations = _filteredRegistrations;

    return AppPageScaffold(
      title: 'Registrations — ${widget.eventTitle}',
      actions: [
        IconButton(
          tooltip: 'Refresh Registrations',
          icon: const Icon(LucideIcons.refreshCw, size: 20),
          onPressed: _isLoading ? null : _fetchRegistrations,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _fetchRegistrations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.canCancel) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: d.md,
                    vertical: d.sm,
                  ),
                  decoration: BoxDecoration(
                    color: d.selection,
                    borderRadius: BorderRadius.circular(d.radiusControl),
                    border: Border.all(
                      color: d.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.eye,
                        size: 18,
                        color: d.primary,
                      ),
                      SizedBox(width: d.sm),
                      Expanded(
                        child: Text(
                          'Read-Only View: Registration mutations are disabled for School Management.',
                          style: d.supporting.copyWith(
                            color: d.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: d.md),
              ],
              ResponsiveGrid(
                minItemWidth: 150,
                maxColumns: 4,
                children: [
                  StatMetricCard(
                    label: 'Total',
                    value: '${_summary['total'] ?? 0}',
                    icon: LucideIcons.users,
                    color: d.primary,
                  ),
                  StatMetricCard(
                    label: 'Registered',
                    value: '${_summary['registered'] ?? 0}',
                    icon: LucideIcons.circleCheck,
                    color: d.success,
                  ),
                  StatMetricCard(
                    label: 'Waiting List',
                    value: '${_summary['waiting_list'] ?? 0}',
                    icon: LucideIcons.hourglass,
                    color: d.waiting,
                  ),
                  StatMetricCard(
                    label: 'Walk-In',
                    value: '${_summary['walk_in'] ?? 0}',
                    icon: LucideIcons.footprints,
                    color: d.information,
                  ),
                ],
              ),
              SizedBox(height: d.md),
              TextField(
                key: const ValueKey<String>('registration-search-field'),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search student name, ID, or course',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear Search',
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              SizedBox(height: d.sm),
              _RegistrationStatusFilterBar(
                selectedStatus: _selectedStatus,
                onSelectStatus: (status) {
                  setState(() => _selectedStatus = status);
                  if (!_hasFixtures) {
                    _fetchRegistrations();
                  }
                },
              ),
              SizedBox(height: d.md),
              if (_isLoading && _registrations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: AppSpinner()),
                )
              else if (_errorMessage != null && _registrations.isEmpty)
                ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchRegistrations,
                )
              else if (visibleRegistrations.isEmpty)
                EmptyStateView(
                  icon: LucideIcons.userX,
                  title: 'No registrations found.',
                  message:
                      'No student registrations match the selected filter.',
                  actionLabel: 'Refresh',
                  onAction: _fetchRegistrations,
                )
              else
                for (final reg in visibleRegistrations)
                  _RegistrationItemCard(
                    registration: reg,
                    canCancel: widget.canCancel,
                    onCancel: () => _confirmAndCancelRegistration(reg),
                  ),
            ],
          ),
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
    final d = context.design;
    return Wrap(
      spacing: d.sm,
      runSpacing: d.xs,
      children: [
        for (final filter in _filters)
          AppPressable(
            key: ValueKey<String>('reg-filter-${filter.value}'),
            semanticLabel: filter.label,
            selected: selectedStatus == filter.value,
            onPressed: () => onSelectStatus(filter.value),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: EdgeInsets.symmetric(
                horizontal: d.gap,
                vertical: d.xs + 2,
              ),
              decoration: BoxDecoration(
                color: selectedStatus == filter.value
                    ? (d.isDark ? d.authDark : Colors.black)
                    : d.card,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selectedStatus == filter.value
                      ? (d.isDark ? d.border : Colors.black)
                      : (d.isDark
                          ? d.border
                          : d.authDark.withValues(alpha: 0.08)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.authDark.withValues(alpha: 0.03),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                filter.label,
                style: d.badge.copyWith(
                  fontWeight: selectedStatus == filter.value
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selectedStatus == filter.value
                      ? Colors.white
                      : d.foreground,
                ),
              ),
            ),
          ),
      ],
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
    final d = context.design;
    final regId = registration['id'];
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

    return Container(
      margin: EdgeInsets.only(bottom: d.gap),
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: d.sm,
            runSpacing: d.xs,
            children: [
              Text(
                fullName,
                style: d.cardTitle,
                softWrap: true,
              ),
              StatusBadge(
                status: status,
                label: status == 'waiting_list' && waitingPos != null
                    ? 'WAITING #$waitingPos'
                    : null,
              ),
            ],
          ),
          SizedBox(height: d.xs),
          Text(
            'Student ID: $studentIdNumber',
            style: d.supporting.copyWith(
              color: d.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (academicMeta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              academicMeta,
              style: d.supporting,
            ),
          ],
          if (registeredAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Registered: ${registeredAt.split('T').first}',
              style: d.supporting,
            ),
          ],
          if (isCancellable) ...[
            SizedBox(height: d.gap),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                key: ValueKey<String>('cancel-registration-$regId'),
                variant: AppButtonVariant.destructive,
                pill: true,
                icon: LucideIcons.userX,
                label: 'Cancel Registration',
                onPressed: onCancel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

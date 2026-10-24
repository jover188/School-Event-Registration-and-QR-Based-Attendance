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

class LiveAttendanceScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool canCorrect;
  final List<Map<String, dynamic>>? initialAttendances;
  final Map<String, int>? initialStats;

  const LiveAttendanceScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.canCorrect = true,
    this.initialAttendances,
    this.initialStats,
  });

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  late final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _attendances = [];
  Map<String, int> _summary = {
    'total_checked_in': 0,
    'present': 0,
    'late': 0,
    'walk_in': 0,
    'excused': 0,
  };

  bool get _hasFixtures =>
      widget.initialAttendances != null || widget.initialStats != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtures) {
      _isLoading = false;
      _attendances = List<Map<String, dynamic>>.from(
        widget.initialAttendances ?? const [],
      );
      _summary = _computeSummary(_attendances, widget.initialStats);
    } else {
      _fetchAttendance();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static Map<String, int> _computeSummary(
    List<Map<String, dynamic>> records, [
    Map<String, int>? overrideStats,
  ]) {
    if (overrideStats != null) {
      return {
        'total_checked_in': overrideStats['total_checked_in'] ?? records.length,
        'present': overrideStats['present'] ?? 0,
        'late': overrideStats['late'] ?? 0,
        'walk_in': overrideStats['walk_in'] ?? 0,
        'excused': overrideStats['excused'] ?? 0,
      };
    }
    return {
      'total_checked_in': records.length,
      'present':
          records.where((r) => r['status']?.toString() == 'present').length,
      'late': records.where((r) => r['status']?.toString() == 'late').length,
      'walk_in':
          records.where((r) => r['status']?.toString() == 'walk_in').length,
      'excused':
          records.where((r) => r['status']?.toString() == 'excused').length,
    };
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queryParams = <String, String>{};
    if (_selectedStatus != 'all') {
      queryParams['status'] = _selectedStatus;
    }
    final search = _searchController.text.trim();
    if (search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await ApiClient().get(
      ApiConstants.eventAttendance(widget.eventId),
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success) {
        List<Map<String, dynamic>> records = [];
        Map<String, dynamic>? rawSummary;

        if (response.data is List) {
          records = (response.data as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap['items'] is List) {
            records = (dataMap['items'] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          } else if (dataMap['data'] is List) {
            records = (dataMap['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          }
          if (dataMap['summary'] is Map<String, dynamic>) {
            rawSummary = dataMap['summary'] as Map<String, dynamic>;
          }
        }

        _attendances = records;

        if (rawSummary != null) {
          _summary = {
            'total_checked_in':
                (rawSummary['total_checked_in'] as num?)?.toInt() ??
                    records.length,
            'present': (rawSummary['present'] as num?)?.toInt() ?? 0,
            'late': (rawSummary['late'] as num?)?.toInt() ?? 0,
            'walk_in': (rawSummary['walk_in'] as num?)?.toInt() ?? 0,
            'excused': (rawSummary['excused'] as num?)?.toInt() ?? 0,
          };
        } else if (_selectedStatus == 'all' && search.isEmpty) {
          _summary = _computeSummary(records);
        }
      } else if (_attendances.isEmpty) {
        _errorMessage =
            response.message ?? 'Failed to load attendance records.';
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAttendances {
    final query = _searchController.text.trim().toLowerCase();
    return _attendances.where((record) {
      final status = record['status']?.toString().toLowerCase() ?? 'present';
      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final student = (record['student'] as Map<String, dynamic>?) ?? {};
      final fullName = _resolveStudentName(student).toLowerCase();
      final studentId =
          student['student_id_number']?.toString().toLowerCase() ?? '';
      final course = student['course']?.toString().toLowerCase() ?? '';
      return fullName.contains(query) ||
          studentId.contains(query) ||
          course.contains(query);
    }).toList();
  }

  Future<void> _openCorrectDialog(Map<String, dynamic> attendance) async {
    if (!widget.canCorrect) return;
    final attendanceId = (attendance['id'] as num?)?.toInt();
    if (attendanceId == null) return;

    final currentStatus = attendance['status']?.toString() ?? 'present';
    final student = (attendance['student'] as Map<String, dynamic>?) ?? {};
    final studentName = _resolveStudentName(student);

    final result = await showDialog<({String newStatus, String reason})>(
      context: context,
      builder: (_) => _CorrectAttendanceDialog(
        studentName: studentName,
        initialStatus: currentStatus,
      ),
    );

    if (result == null || !mounted) return;

    final response = await ApiClient().put(
      ApiConstants.correctAttendance(attendanceId),
      {
        'new_status': result.newStatus,
        'reason': result.reason,
      },
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Attendance status corrected successfully.',
          ),
        ),
      );
      _fetchAttendance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to correct attendance status.',
          ),
        ),
      );
    }
  }

  Future<void> _openMarkAttendanceDialog() async {
    if (!widget.canCorrect) return;

    final result =
        await showDialog<({int studentId, String status, String reason})>(
      context: context,
      builder: (_) => const _MarkAttendanceDialog(),
    );

    if (result == null || !mounted) return;

    final response = await ApiClient().post(
      ApiConstants.markAttendance(widget.eventId),
      {
        'student_id': result.studentId,
        'status': result.status,
        'reason': result.reason,
      },
    );

    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ?? 'Student attendance marked successfully.',
          ),
        ),
      );
      _fetchAttendance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to manually mark attendance.',
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
    final visibleAttendances = _filteredAttendances;

    return AppPageScaffold(
      title: 'Attendance — ${widget.eventTitle}',
      actions: [
        if (widget.canCorrect)
          AppIconButton(
            tooltip: 'Mark Student Attendance',
            icon: LucideIcons.userPlus,
            onPressed: _openMarkAttendanceDialog,
          ),
        AppIconButton(
          tooltip: 'Refresh Attendance',
          icon: LucideIcons.refreshCw,
          onPressed: _isLoading ? null : _fetchAttendance,
        ),
      ],
      floatingActionButton: widget.canCorrect
          ? FloatingActionButton.extended(
              key: const ValueKey<String>('mark-student-attendance-fab'),
              onPressed: _openMarkAttendanceDialog,
              backgroundColor: d.primary,
              foregroundColor: d.primaryForeground,
              icon: const Icon(LucideIcons.clipboardCheck, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(d.buttonRadiusStandard)),
              label: const Text('Mark Attendance'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: widget.canCorrect ? 88 : d.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.canCorrect) ...[
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
                          'Read-Only View: Attendance corrections are disabled for School Management.',
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
              _AttendanceSummaryMetricsGrid(summary: _summary),
              SizedBox(height: d.md),
              TextField(
                key: const ValueKey<String>('attendance-search-field'),
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (!_hasFixtures) {
                    _fetchAttendance();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search student name, ID, or course',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: IconButton(
                    tooltip: 'Search Attendance',
                    icon: const Icon(LucideIcons.arrowRight, size: 18),
                    onPressed: () {
                      if (_hasFixtures) {
                        setState(() {});
                      } else {
                        _fetchAttendance();
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: d.sm),
              _AttendanceStatusFilterBar(
                selectedStatus: _selectedStatus,
                onSelectStatus: (status) {
                  setState(() => _selectedStatus = status);
                  if (!_hasFixtures) {
                    _fetchAttendance();
                  }
                },
              ),
              SizedBox(height: d.md),
              if (_isLoading && _attendances.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: AppSpinner()),
                )
              else if (_errorMessage != null && _attendances.isEmpty)
                ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchAttendance,
                )
              else if (visibleAttendances.isEmpty)
                EmptyStateView(
                  icon: LucideIcons.clipboardList,
                  title: 'No attendance records found.',
                  message:
                      'Checked-in students and attendance records will appear here.',
                  actionLabel: 'Refresh',
                  onAction: _fetchAttendance,
                )
              else
                for (final record in visibleAttendances)
                  _AttendanceRecordCard(
                    record: record,
                    canCorrect: widget.canCorrect,
                    onCorrect: () => _openCorrectDialog(record),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummaryMetricsGrid extends StatelessWidget {
  final Map<String, int> summary;

  const _AttendanceSummaryMetricsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return ResponsiveGrid(
      minItemWidth: 150,
      maxColumns: 4,
      children: [
        StatMetricCard(
          label: 'Checked In',
          value: '${summary['total_checked_in'] ?? 0}',
          icon: LucideIcons.userCheck,
          color: d.primary,
        ),
        StatMetricCard(
          label: 'Present',
          value: '${summary['present'] ?? 0}',
          icon: LucideIcons.circleCheck,
          color: d.success,
        ),
        StatMetricCard(
          label: 'Late',
          value: '${summary['late'] ?? 0}',
          icon: LucideIcons.clock,
          color: d.warning,
        ),
        StatMetricCard(
          label: 'Walk-In',
          value: '${summary['walk_in'] ?? 0}',
          icon: LucideIcons.footprints,
          color: d.information,
        ),
        StatMetricCard(
          label: 'Excused',
          value: '${summary['excused'] ?? 0}',
          icon: LucideIcons.fileCheck,
          color: d.excused,
        ),
      ],
    );
  }
}

class _AttendanceStatusFilterBar extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onSelectStatus;

  const _AttendanceStatusFilterBar({
    required this.selectedStatus,
    required this.onSelectStatus,
  });

  static const List<({String value, String label})> _filters = [
    (value: 'all', label: 'All'),
    (value: 'present', label: 'Present'),
    (value: 'late', label: 'Late'),
    (value: 'walk_in', label: 'Walk-In'),
    (value: 'excused', label: 'Excused'),
    (value: 'absent', label: 'Absent'),
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
            key: ValueKey<String>('att-filter-${filter.value}'),
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

class _AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool canCorrect;
  final VoidCallback onCorrect;

  const _AttendanceRecordCard({
    required this.record,
    required this.canCorrect,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final recordId = record['id'];
    final student = (record['student'] as Map<String, dynamic>?) ?? {};
    final fullName = _LiveAttendanceScreenState._resolveStudentName(student);
    final studentIdNumber =
        student['student_id_number']?.toString() ?? 'N/A';
    final course = student['course']?.toString() ?? '';
    final status = record['status']?.toString() ?? 'present';
    final checkInTime = record['check_in_time']?.toString() ?? '';
    final checkOutTime = record['check_out_time']?.toString() ?? '';

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
              StatusBadge(status: status),
            ],
          ),
          SizedBox(height: d.xs),
          Text(
            'ID: $studentIdNumber${course.isNotEmpty ? ' • $course' : ''}',
            style: d.supporting.copyWith(
              color: d.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (checkInTime.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Check-In: ${checkInTime.replaceAll('T', ' ').split('.').first}',
              style: d.supporting,
            ),
          ],
          if (checkOutTime.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Check-Out: ${checkOutTime.replaceAll('T', ' ').split('.').first}',
              style: d.supporting,
            ),
          ],
          if (canCorrect) ...[
            SizedBox(height: d.gap),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                key: ValueKey<String>('correct-attendance-$recordId'),
                size: AppButtonSize.compact,
                variant: AppButtonVariant.outline,
                icon: LucideIcons.pencilLine,
                label: 'Correct Attendance Status',
                onPressed: onCorrect,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CorrectAttendanceDialog extends StatefulWidget {
  final String studentName;
  final String initialStatus;

  const _CorrectAttendanceDialog({
    required this.studentName,
    required this.initialStatus,
  });

  @override
  State<_CorrectAttendanceDialog> createState() =>
      _CorrectAttendanceDialogState();
}

class _CorrectAttendanceDialogState extends State<_CorrectAttendanceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController = TextEditingController();
  late final FocusNode _reasonFocus = FocusNode();
  late String _selectedStatus;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  static const List<String> _validStatuses = [
    'present',
    'late',
    'walk_in',
    'excused',
    'absent',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _validStatuses.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'present';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      _reasonFocus.requestFocus();
      return;
    }
    _formKey.currentState!.save();
    Navigator.pop(
      context,
      (newStatus: _selectedStatus, reason: _reasonController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusOverlay),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      backgroundColor: d.card,
      title: Text('Correct Attendance: ${widget.studentName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New Attendance Status',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    DropdownButtonFormField<String>(
                      key: const ValueKey<String>('correct-status-dropdown'),
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        helperText: ' ',
                      ),
                      items: _validStatuses
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s.replaceAll('_', ' ').toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                        }
                      },
                    ),
                    SizedBox(height: d.xs),
                    Text(
                      'Correction Reason (Mandatory)',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    TextFormField(
                      key: const ValueKey<String>('correct-reason-field'),
                      controller: _reasonController,
                      focusNode: _reasonFocus,
                      autofocus: true,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Minimum 5 characters explaining the change',
                        helperText:
                            'Logged in audit trail & attendance corrections',
                        helperMaxLines: 2,
                        errorMaxLines: 3,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Reason must be at least 5 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.primary,
              onPressed: _submit,
              label: 'Save Correction',
            ),
          ],
        ),
      ],
    );
  }
}

class _MarkAttendanceDialog extends StatefulWidget {
  const _MarkAttendanceDialog();

  @override
  State<_MarkAttendanceDialog> createState() => _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends State<_MarkAttendanceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdController =
      TextEditingController();
  late final TextEditingController _reasonController = TextEditingController();
  late final FocusNode _studentIdFocus = FocusNode();
  late final FocusNode _reasonFocus = FocusNode();

  String _selectedStatus = 'present';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  static const List<String> _validStatuses = [
    'present',
    'late',
    'walk_in',
    'excused',
    'absent',
  ];

  @override
  void dispose() {
    _studentIdController.dispose();
    _reasonController.dispose();
    _studentIdFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      if (int.tryParse(_studentIdController.text.trim()) == null) {
        _studentIdFocus.requestFocus();
      } else {
        _reasonFocus.requestFocus();
      }
      return;
    }
    _formKey.currentState!.save();
    final studentId = int.parse(_studentIdController.text.trim());
    Navigator.pop(
      context,
      (
        studentId: studentId,
        status: _selectedStatus,
        reason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(d.radiusOverlay),
        side: BorderSide(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
      ),
      backgroundColor: d.card,
      title: const Text('Mark Student Attendance'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: FocusTraversalGroup(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Student Record ID (Numeric)',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    TextFormField(
                      key: const ValueKey<String>('mark-student-id-field'),
                      controller: _studentIdController,
                      focusNode: _studentIdFocus,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1',
                        prefixIcon: Icon(LucideIcons.idCard, size: 18),
                        helperText: ' ',
                        errorMaxLines: 2,
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Enter a valid numeric student ID.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: d.xs),
                    Text(
                      'Attendance Status',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    DropdownButtonFormField<String>(
                      key: const ValueKey<String>('mark-status-dropdown'),
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        helperText: ' ',
                      ),
                      items: _validStatuses
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s.replaceAll('_', ' ').toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                        }
                      },
                    ),
                    SizedBox(height: d.xs),
                    Text(
                      'Reason (Mandatory)',
                      style: d.supporting.copyWith(
                        color: d.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: d.xs),
                    TextFormField(
                      key: const ValueKey<String>('mark-reason-field'),
                      controller: _reasonController,
                      focusNode: _reasonFocus,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      autofillHints: const [AutofillHints.name],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Minimum 5 characters',
                        helperText: ' ',
                        errorMaxLines: 3,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'Reason must be at least 5 characters.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Wrap(
          spacing: d.sm,
          runSpacing: d.sm,
          alignment: WrapAlignment.end,
          children: [
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
              label: 'Cancel',
            ),
            AppButton(
              size: AppButtonSize.compact,
              variant: AppButtonVariant.primary,
              onPressed: _submit,
              label: 'Mark Attendance',
            ),
          ],
        ),
      ],
    );
  }
}

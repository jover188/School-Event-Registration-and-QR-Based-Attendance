import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';

class LiveAttendanceScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool canCorrect;

  const LiveAttendanceScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.canCorrect = true,
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

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
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
          _summary = {
            'total_checked_in': records.length,
            'present': records
                .where((r) => r['status']?.toString() == 'present')
                .length,
            'late':
                records.where((r) => r['status']?.toString() == 'late').length,
            'walk_in': records
                .where((r) => r['status']?.toString() == 'walk_in')
                .length,
            'excused': records
                .where((r) => r['status']?.toString() == 'excused')
                .length,
          };
        }
      } else {
        _errorMessage =
            response.message ?? 'Failed to load live attendance records.';
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Attendance: ${widget.eventTitle}'),
        actions: [
          if (widget.canCorrect)
            IconButton(
              tooltip: 'Mark Student Attendance',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: _openMarkAttendanceDialog,
            ),
          IconButton(
            tooltip: 'Refresh Attendance',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAttendance,
          ),
        ],
      ),
      floatingActionButton: widget.canCorrect
          ? FloatingActionButton.extended(
              key: const ValueKey<String>('mark-student-attendance-fab'),
              onPressed: _openMarkAttendanceDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Mark Attendance'),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.canCorrect)
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
                        'Read-Only View: Attendance corrections are disabled for School Management.',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: _AttendanceSummaryMetricsRow(summary: _summary),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: TextField(
                key: const ValueKey<String>('attendance-search-field'),
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchAttendance(),
                decoration: InputDecoration(
                  labelText: 'Search Student Name or ID',
                  hintText: 'Type name or student ID and press search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search Attendance',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _fetchAttendance,
                  ),
                ),
              ),
            ),
            _AttendanceStatusFilterBar(
              selectedStatus: _selectedStatus,
              onSelectStatus: (status) {
                setState(() => _selectedStatus = status);
                _fetchAttendance();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchAttendance,
                        )
                      : _attendances.isEmpty
                          ? EmptyStateView(
                              icon: Icons.fact_check_outlined,
                              title: 'No attendance records found.',
                              message:
                                  'Checked-in students and attendance records will appear here.',
                              actionLabel: 'Refresh',
                              onAction: _fetchAttendance,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchAttendance,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                  88,
                                ),
                                itemCount: _attendances.length,
                                itemBuilder: (context, index) {
                                  final record = _attendances[index];
                                  return _AttendanceRecordCard(
                                    record: record,
                                    canCorrect: widget.canCorrect,
                                    onCorrect: () => _openCorrectDialog(record),
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

class _AttendanceSummaryMetricsRow extends StatelessWidget {
  final Map<String, int> summary;

  const _AttendanceSummaryMetricsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: StatMetricCard(
              label: 'Checked In',
              value: '${summary['total_checked_in'] ?? 0}',
              icon: Icons.how_to_reg_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 104,
            child: StatMetricCard(
              label: 'Present',
              value: '${summary['present'] ?? 0}',
              icon: Icons.check_circle_outline,
              color: AppColors.present,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 104,
            child: StatMetricCard(
              label: 'Late',
              value: '${summary['late'] ?? 0}',
              icon: Icons.schedule,
              color: AppColors.late,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 104,
            child: StatMetricCard(
              label: 'Walk-In',
              value: '${summary['walk_in'] ?? 0}',
              icon: Icons.directions_walk,
              color: AppColors.walkIn,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 104,
            child: StatMetricCard(
              label: 'Excused',
              value: '${summary['excused'] ?? 0}',
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.excused,
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final filter in _filters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                key: ValueKey<String>('att-filter-${filter.value}'),
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
    final student = (record['student'] as Map<String, dynamic>?) ?? {};
    final fullName = _LiveAttendanceScreenState._resolveStudentName(student);
    final studentIdNumber =
        student['student_id_number']?.toString() ?? 'N/A';
    final course = student['course']?.toString() ?? '';
    final status = record['status']?.toString() ?? 'present';
    final checkInTime = record['check_in_time']?.toString() ?? '';
    final checkOutTime = record['check_out_time']?.toString() ?? '';

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
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ID: $studentIdNumber${course.isNotEmpty ? ' • $course' : ''}',
                    style: AppTypography.bodyMuted,
                  ),
                  if (checkInTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Check-In: ${checkInTime.replaceAll('T', ' ').split('.').first}',
                      style: AppTypography.caption,
                    ),
                  ],
                  if (checkOutTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Check-Out: ${checkOutTime.replaceAll('T', ' ').split('.').first}',
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
            if (canCorrect) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Correct Attendance Status',
                icon: const Icon(
                  Icons.edit_note_outlined,
                  color: AppColors.primary,
                ),
                onPressed: onCorrect,
              ),
            ],
          ],
        ),
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
    return AlertDialog(
      title: Text('Correct Attendance: ${widget.studentName}'),
      content: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    key: const ValueKey<String>('correct-status-dropdown'),
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'New Attendance Status',
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
                  const SizedBox(height: AppSpacing.xs),
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
                      labelText: 'Correction Reason (Mandatory)',
                      hintText: 'Minimum 5 characters explaining the change',
                      helperText: 'Logged in audit trail & attendance corrections',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save Correction'),
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
    return AlertDialog(
      title: const Text('Mark Student Attendance'),
      content: FocusTraversalGroup(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey<String>('mark-student-id-field'),
                    controller: _studentIdController,
                    focusNode: _studentIdFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Student Record ID (Numeric)',
                      hintText: 'e.g. 1',
                      prefixIcon: Icon(Icons.badge_outlined),
                      helperText: ' ',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1) {
                        return 'Enter a valid numeric student ID.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    key: const ValueKey<String>('mark-status-dropdown'),
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Attendance Status',
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
                  const SizedBox(height: AppSpacing.xs),
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
                      labelText: 'Reason (Mandatory)',
                      hintText: 'Minimum 5 characters',
                      helperText: ' ',
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Mark Attendance'),
        ),
      ],
    );
  }
}

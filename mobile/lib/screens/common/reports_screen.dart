import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class ReportsScreen extends StatefulWidget {
  final int? initialEventId;

  const ReportsScreen({super.key, this.initialEventId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<({String key, String label, bool needsEvent, bool needsStudent})>
      _reportTypes = [
    (
      key: 'event_attendance',
      label: 'Event Attendance Report',
      needsEvent: true,
      needsStudent: false,
    ),
    (
      key: 'student_history',
      label: 'Student Attendance History',
      needsEvent: false,
      needsStudent: true,
    ),
    (
      key: 'registration_summary',
      label: 'Event Registration Summary',
      needsEvent: true,
      needsStudent: false,
    ),
    (
      key: 'participation_summary',
      label: 'Institutional Participation Summary',
      needsEvent: false,
      needsStudent: false,
    ),
    (
      key: 'absentee',
      label: 'Event Absentee Report',
      needsEvent: true,
      needsStudent: false,
    ),
    (
      key: 'walk_in',
      label: 'Walk-In Attendees Report',
      needsEvent: true,
      needsStudent: false,
    ),
    (
      key: 'organizer_summary',
      label: 'Organizer Activity Summary',
      needsEvent: false,
      needsStudent: false,
    ),
  ];

  late final TextEditingController _eventIdController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _departmentController;
  late final TextEditingController _yearLevelController;
  late final TextEditingController _dateFromController;
  late final TextEditingController _dateToController;

  late final FocusNode _eventIdFocus = FocusNode();
  late final FocusNode _studentIdFocus = FocusNode();
  late final FocusNode _departmentFocus = FocusNode();
  late final FocusNode _yearLevelFocus = FocusNode();
  late final FocusNode _dateFromFocus = FocusNode();
  late final FocusNode _dateToFocus = FocusNode();

  String _selectedReportType = 'event_attendance';
  List<EventModel> _availableEvents = [];
  bool _isLoadingReport = false;
  bool _isExporting = false;
  String? _errorMessage;
  dynamic _reportPayload;

  @override
  void initState() {
    super.initState();
    _eventIdController = TextEditingController(
      text: widget.initialEventId != null ? '${widget.initialEventId}' : '1',
    );
    _studentIdController = TextEditingController(text: '1');
    _departmentController = TextEditingController();
    _yearLevelController = TextEditingController();
    _dateFromController = TextEditingController();
    _dateToController = TextEditingController();

    _loadEventsAndInitialReport();
  }

  @override
  void dispose() {
    _eventIdController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _yearLevelController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();

    _eventIdFocus.dispose();
    _studentIdFocus.dispose();
    _departmentFocus.dispose();
    _yearLevelFocus.dispose();
    _dateFromFocus.dispose();
    _dateToFocus.dispose();
    super.dispose();
  }

  Future<void> _loadEventsAndInitialReport() async {
    final eventsResp = await ApiClient().get(ApiConstants.events);
    if (!mounted) return;

    if (eventsResp.success && eventsResp.data is List) {
      final loaded = (eventsResp.data as List)
          .whereType<Map<String, dynamic>>()
          .map(EventModel.fromJson)
          .toList();
      setState(() {
        _availableEvents = loaded;
        if (widget.initialEventId == null && loaded.isNotEmpty) {
          _eventIdController.text = '${loaded.first.id}';
        }
      });
    }

    await _generateReport();
  }

  ({String key, String label, bool needsEvent, bool needsStudent})
      get _currentConfig {
    return _reportTypes.firstWhere(
      (r) => r.key == _selectedReportType,
      orElse: () => _reportTypes.first,
    );
  }

  Map<String, String> _collectFilterParams() {
    final params = <String, String>{};
    if (_departmentController.text.trim().isNotEmpty) {
      params['department'] = _departmentController.text.trim();
    }
    if (_yearLevelController.text.trim().isNotEmpty) {
      params['year_level'] = _yearLevelController.text.trim();
    }
    if (_dateFromController.text.trim().isNotEmpty) {
      params['date_from'] = _dateFromController.text.trim();
    }
    if (_dateToController.text.trim().isNotEmpty) {
      params['date_to'] = _dateToController.text.trim();
    }
    return params;
  }

  Future<void> _generateReport() async {
    final config = _currentConfig;
    final eventId = int.tryParse(_eventIdController.text.trim());
    final studentId = int.tryParse(_studentIdController.text.trim());

    if (config.needsEvent && (eventId == null || eventId < 1)) {
      setState(() {
        _errorMessage = 'Please enter or select a valid Event ID.';
        _reportPayload = null;
      });
      return;
    }

    if (config.needsStudent && (studentId == null || studentId < 1)) {
      setState(() {
        _errorMessage = 'Please enter a valid numeric Student ID.';
        _reportPayload = null;
      });
      return;
    }

    setState(() {
      _isLoadingReport = true;
      _errorMessage = null;
    });

    final endpoint = switch (_selectedReportType) {
      'event_attendance' => ApiConstants.reportEventAttendance(eventId!),
      'student_history' => ApiConstants.reportStudentHistory(studentId!),
      'registration_summary' =>
        ApiConstants.reportRegistrationSummary(eventId!),
      'participation_summary' => ApiConstants.reportParticipationSummary,
      'absentee' => ApiConstants.reportAbsentee(eventId!),
      'walk_in' => ApiConstants.reportWalkIn(eventId!),
      'organizer_summary' => ApiConstants.reportOrganizerSummary,
      _ => ApiConstants.reportParticipationSummary,
    };

    final queryParams = _collectFilterParams();
    final response = await ApiClient().get(
      endpoint,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (!mounted) return;

    if (response.success) {
      dynamic payload = response.data;
      if (payload == null) {
        final rawDownload = await ApiClient().downloadBytes(
          endpoint,
          queryParams: queryParams.isEmpty ? null : queryParams,
        );
        if (!mounted) return;
        if (rawDownload.bytes.isNotEmpty) {
          try {
            final decoded = json.decode(utf8.decode(rawDownload.bytes));
            if (decoded is Map<String, dynamic>) {
              payload = decoded['summary'] ?? decoded['data'] ?? decoded;
            }
          } catch (_) {}
        }
      }
      setState(() {
        _isLoadingReport = false;
        _reportPayload = payload ?? <String, dynamic>{};
      });
    } else {
      setState(() {
        _isLoadingReport = false;
        _errorMessage = response.message ?? 'Failed to fetch report data.';
      });
    }
  }

  Future<void> _exportReportFormat(String format) async {
    final config = _currentConfig;
    final eventId = int.tryParse(_eventIdController.text.trim());
    final studentId = int.tryParse(_studentIdController.text.trim());

    final queryParams = <String, String>{
      'report_type': _selectedReportType,
      'format': format,
      ..._collectFilterParams(),
    };

    if (config.needsEvent && eventId != null) {
      queryParams['event_id'] = '$eventId';
    }
    if (config.needsStudent && studentId != null) {
      queryParams['student_id'] = '$studentId';
    }

    setState(() => _isExporting = true);

    final result = await ApiClient().downloadBytes(
      ApiConstants.exportReport,
      queryParams: queryParams,
    );

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result.statusCode >= 200 &&
        result.statusCode < 300 &&
        result.bytes.isNotEmpty) {
      final ext = format.toLowerCase();
      final filename = 'report_$_selectedReportType.$ext';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            'Exported $filename (${result.bytes.length} bytes downloaded).',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            result.errorMessage ??
                'Export not available for $_selectedReportType in ${format.toUpperCase()} format.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _currentConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Data Exports'),
        actions: [
          IconButton(
            tooltip: 'Refresh Report',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingReport ? null : _generateReport,
          ),
        ],
      ),
      body: SafeArea(
        child: FocusTraversalGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Report Configuration',
                  subtitle: 'Select report type, target event/student, and filters',
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: const ValueKey<String>('report-type-dropdown'),
                          initialValue: _selectedReportType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Report Type',
                            prefixIcon: Icon(Icons.analytics_outlined),
                          ),
                          items: _reportTypes
                              .map(
                                (r) => DropdownMenuItem<String>(
                                  value: r.key,
                                  child: Text(
                                    r.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedReportType = val);
                              _generateReport();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (config.needsEvent) ...[
                          if (_availableEvents.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              key: const ValueKey<String>('report-event-picker'),
                              initialValue: _availableEvents.any(
                                (e) =>
                                    e.id ==
                                    int.tryParse(
                                      _eventIdController.text.trim(),
                                    ),
                              )
                                  ? int.tryParse(_eventIdController.text.trim())
                                  : _availableEvents.first.id,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Event',
                                prefixIcon: Icon(Icons.event_outlined),
                              ),
                              items: _availableEvents
                                  .map(
                                    (e) => DropdownMenuItem<int>(
                                      value: e.id,
                                      child: Text(
                                        '#${e.id} • ${e.title}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _eventIdController.text = '$val';
                                  });
                                  _generateReport();
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          TextField(
                            key: const ValueKey<String>('report-event-id-field'),
                            controller: _eventIdController,
                            focusNode: _eventIdFocus,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _generateReport(),
                            decoration: const InputDecoration(
                              labelText: 'Event ID',
                              hintText: 'Enter numeric event ID',
                              prefixIcon: Icon(Icons.tag),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (config.needsStudent) ...[
                          TextField(
                            key: const ValueKey<String>(
                              'report-student-id-field',
                            ),
                            controller: _studentIdController,
                            focusNode: _studentIdFocus,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _generateReport(),
                            decoration: const InputDecoration(
                              labelText: 'Student Record ID',
                              hintText: 'Enter numeric student ID (e.g. 1)',
                              prefixIcon: Icon(Icons.person_search_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'report-department-field',
                                ),
                                controller: _departmentController,
                                focusNode: _departmentFocus,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Department (Optional)',
                                  hintText: 'e.g. CCS',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'report-year-level-field',
                                ),
                                controller: _yearLevelController,
                                focusNode: _yearLevelFocus,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Year Level (Optional)',
                                  hintText: 'e.g. 3rd Year',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'report-date-from-field',
                                ),
                                controller: _dateFromController,
                                focusNode: _dateFromFocus,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Date From (YYYY-MM-DD)',
                                  hintText: '2026-01-01',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'report-date-to-field',
                                ),
                                controller: _dateToController,
                                focusNode: _dateToFocus,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _generateReport(),
                                decoration: const InputDecoration(
                                  labelText: 'Date To (YYYY-MM-DD)',
                                  hintText: '2026-12-31',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          key: const ValueKey<String>('generate-report-button'),
                          onPressed: _isLoadingReport ? null : _generateReport,
                          icon: const Icon(Icons.play_arrow_outlined),
                          label: const Text('Generate Report'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ReportExportButtonsCard(
                  isExporting: _isExporting,
                  onExportPdf: () => _exportReportFormat('pdf'),
                  onExportCsv: () => _exportReportFormat('csv'),
                  onExportExcel: () => _exportReportFormat('xlsx'),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Report Results',
                  subtitle: config.label,
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                if (_isLoadingReport)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _generateReport,
                  )
                else
                  _ReportPayloadViewer(
                    reportType: _selectedReportType,
                    payload: _reportPayload,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportExportButtonsCard extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;

  const _ReportExportButtonsCard({
    required this.isExporting,
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Official Report File',
              style: AppTypography.subtitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Export formatted records in PDF, CSV, or Excel (.xlsx)',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey<String>('export-pdf-button'),
                  onPressed: isExporting ? null : onExportPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.absent,
                  ),
                  label: const Text('Export PDF'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('export-csv-button'),
                  onPressed: isExporting ? null : onExportCsv,
                  icon: const Icon(
                    Icons.table_rows_outlined,
                    color: AppColors.primary,
                  ),
                  label: const Text('Export CSV'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('export-excel-button'),
                  onPressed: isExporting ? null : onExportExcel,
                  icon: const Icon(
                    Icons.grid_on_outlined,
                    color: AppColors.present,
                  ),
                  label: const Text('Export Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportPayloadViewer extends StatelessWidget {
  final String reportType;
  final dynamic payload;

  const _ReportPayloadViewer({
    required this.reportType,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    if (payload == null) {
      return const EmptyStateView(
        icon: Icons.description_outlined,
        title: 'No report data loaded.',
        message: 'Choose parameters above and tap Generate Report.',
      );
    }

    if (payload is Map<String, dynamic>) {
      final map = payload as Map<String, dynamic>;
      final nestedSummary = map['summary'] is Map<String, dynamic>
          ? map['summary'] as Map<String, dynamic>
          : map;

      if ( nestedSummary.isEmpty) {
        return const EmptyStateView(
          icon: Icons.inbox_outlined,
          title: 'No summary metrics available.',
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nestedSummary.entries.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (context, index) {
          final entry = nestedSummary.entries.elementAt(index);
          final label = entry.key.replaceAll('_', ' ').toUpperCase();
          final value = entry.value?.toString() ?? 'N/A';
          return StatMetricCard(
            label: label,
            value: value,
            icon: Icons.query_stats_outlined,
            color: AppColors.primary,
          );
        },
      );
    }

    if (payload is List) {
      final list = (payload as List).whereType<Map<String, dynamic>>().toList();
      if (list.isEmpty) {
        return const EmptyStateView(
          icon: Icons.inbox_outlined,
          title: 'No records found for this report.',
          message: 'Try selecting another event or adjusting your filters.',
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _ReportRowItemCard(reportType: reportType, item: item);
        },
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(payload.toString(), style: AppTypography.body),
      ),
    );
  }
}

class _ReportRowItemCard extends StatelessWidget {
  final String reportType;
  final Map<String, dynamic> item;

  const _ReportRowItemCard({
    required this.reportType,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    if (reportType == 'organizer_summary') {
      final email = item['email']?.toString() ?? 'Organizer';
      final eventsCount = item['events_count'] ?? 0;
      final totalRegs = item['total_registrations'] ?? 0;
      final totalAtt = item['total_attendances'] ?? 0;

      return Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_outline, color: AppColors.primary),
          ),
          title: Text(email, style: AppTypography.subtitle),
          subtitle: Text(
            'Events: $eventsCount • Registered: $totalRegs • Attended: $totalAtt',
            style: AppTypography.bodyMuted,
          ),
        ),
      );
    }

    final student = (item['student'] as Map<String, dynamic>?) ?? {};
    final event = (item['event'] as Map<String, dynamic>?) ?? {};
    final status = item['status']?.toString() ?? 'present';

    final primaryTitle = student['full_name']?.toString() ??
        event['title']?.toString() ??
        item['title']?.toString() ??
        'Record #${item['id'] ?? ''}';

    final secondarySubtitle = [
      if (student['student_id_number'] != null)
        'ID: ${student['student_id_number']}',
      if (student['course'] != null) student['course'].toString(),
      if (event['event_date'] != null)
        event['event_date'].toString().split('T').first,
      if (item['check_in_time'] != null)
        'Check-In: ${item['check_in_time'].toString().replaceAll('T', ' ').split('.').first}',
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primaryTitle, style: AppTypography.subtitle),
                  if (secondarySubtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(secondarySubtitle, style: AppTypography.bodyMuted),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

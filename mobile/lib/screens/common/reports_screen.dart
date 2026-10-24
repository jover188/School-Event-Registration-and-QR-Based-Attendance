import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class ReportsScreen extends StatefulWidget {
  final int? initialEventId;
  final bool embedded;
  final List<EventModel>? initialEvents;
  final dynamic initialReportPayload;
  final String? initialErrorMessage;
  final String? initialReportType;

  const ReportsScreen({
    super.key,
    this.initialEventId,
    this.embedded = false,
    this.initialEvents,
    this.initialReportPayload,
    this.initialErrorMessage,
    this.initialReportType,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const List<
      ({
        String key,
        String label,
        bool needsEvent,
        bool needsStudent,
      })> _reportTypes = [
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

  bool get _hasFixtures =>
      widget.initialEvents != null ||
      widget.initialReportPayload != null ||
      widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialReportType != null &&
        _reportTypes.any((r) => r.key == widget.initialReportType)) {
      _selectedReportType = widget.initialReportType!;
    }

    _eventIdController = TextEditingController(
      text: widget.initialEventId != null ? '${widget.initialEventId}' : '1',
    );
    _studentIdController = TextEditingController(text: '1');
    _departmentController = TextEditingController();
    _yearLevelController = TextEditingController();
    _dateFromController = TextEditingController();
    _dateToController = TextEditingController();

    if (_hasFixtures) {
      _availableEvents = List<EventModel>.from(
        widget.initialEvents ?? const [],
      );
      if (widget.initialEventId == null && _availableEvents.isNotEmpty) {
        _eventIdController.text = '${_availableEvents.first.id}';
      }
      _reportPayload = widget.initialReportPayload;
      _errorMessage = widget.initialErrorMessage;
      _isLoadingReport = false;
    } else {
      _loadEventsAndInitialReport();
    }
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReportType != oldWidget.initialReportType &&
        widget.initialReportType != null &&
        _reportTypes.any((r) => r.key == widget.initialReportType)) {
      _selectedReportType = widget.initialReportType!;
    }
    if (widget.initialEvents != oldWidget.initialEvents) {
      _availableEvents = List<EventModel>.from(
        widget.initialEvents ?? const [],
      );
    }
    if (widget.initialReportPayload != oldWidget.initialReportPayload ||
        widget.initialErrorMessage != oldWidget.initialErrorMessage) {
      _reportPayload = widget.initialReportPayload;
      _errorMessage = widget.initialErrorMessage;
      _isLoadingReport = false;
    }
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
      _eventIdFocus.requestFocus();
      return;
    }

    if (config.needsStudent && (studentId == null || studentId < 1)) {
      setState(() {
        _errorMessage = 'Please enter a valid numeric Student ID.';
        _reportPayload = null;
      });
      _studentIdFocus.requestFocus();
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
    } else if (widget.initialReportPayload != null) {
      setState(() {
        _isLoadingReport = false;
        _reportPayload = widget.initialReportPayload;
        _errorMessage = null;
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

    if (config.needsEvent && (eventId == null || eventId < 1)) {
      setState(() {
        _errorMessage = 'Please enter or select a valid Event ID.';
      });
      _eventIdFocus.requestFocus();
      return;
    }

    if (config.needsStudent && (studentId == null || studentId < 1)) {
      setState(() {
        _errorMessage = 'Please enter a valid numeric Student ID.';
      });
      _studentIdFocus.requestFocus();
      return;
    }

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

    final upperFormat = format.toUpperCase();
    if (result.statusCode >= 200 &&
        result.statusCode < 300 &&
        result.bytes.isNotEmpty) {
      final bytes = result.bytes;
      AppToast.success(
        context,
        '$upperFormat report generated (${bytes.length} bytes received).',
      );
      await _showExportPreviewDialog(upperFormat, bytes);
    } else {
      AppToast.error(
        context,
        result.errorMessage ??
            'Export not available for $_selectedReportType in $upperFormat format.',
      );
    }
  }

  Future<void> _showExportPreviewDialog(
    String upperFormat,
    List<int> bytes,
  ) async {
    String previewText;
    try {
      final decoded = utf8.decode(bytes, allowMalformed: true);
      previewText =
          decoded.length > 600 ? '${decoded.substring(0, 600)}…' : decoded;
    } catch (_) {
      previewText = 'Binary $upperFormat payload (${bytes.length} bytes).';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final d = ctx.design;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.radiusCard),
            side: BorderSide(
              color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
            ),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.fileCheck, size: 20, color: d.primary),
              SizedBox(width: d.sm),
              Expanded(child: Text('$upperFormat Export Ready')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report payload received from server (${bytes.length} bytes)',
                    style: d.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: d.sm),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(d.sm),
                    decoration: BoxDecoration(
                      color: d.muted,
                      borderRadius: BorderRadius.circular(d.radiusControl),
                      border: Border.all(color: d.border),
                    ),
                    child: Text(
                      previewText,
                      style: d.supporting,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            AppButton(
              pill: true,
              variant: AppButtonVariant.primary,
              label: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final config = _currentConfig;
    final selectedEventValue = _availableEvents.any(
      (e) => e.id == int.tryParse(_eventIdController.text.trim()),
    )
        ? int.tryParse(_eventIdController.text.trim())
        : (_availableEvents.isNotEmpty ? _availableEvents.first.id : null);

    final filterFields = <Widget>[
      if (config.needsEvent && _availableEvents.isNotEmpty)
        DropdownButtonFormField<int>(
          key: const ValueKey<String>('report-event-picker'),
          initialValue: selectedEventValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Event',
            prefixIcon: Icon(
              LucideIcons.calendar,
              size: 18,
              color: d.mutedForeground,
            ),
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
      if (config.needsEvent)
        TextField(
          key: const ValueKey<String>('report-event-id-field'),
          controller: _eventIdController,
          focusNode: _eventIdFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _generateReport(),
          decoration: InputDecoration(
            labelText: 'Event ID',
            hintText: 'Enter numeric event ID',
            prefixIcon: Icon(
              LucideIcons.hash,
              size: 18,
              color: d.mutedForeground,
            ),
          ),
        ),
      if (config.needsStudent)
        TextField(
          key: const ValueKey<String>('report-student-id-field'),
          controller: _studentIdController,
          focusNode: _studentIdFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _generateReport(),
          decoration: InputDecoration(
            labelText: 'Student Record ID',
            hintText: 'Enter numeric student ID (e.g. 1)',
            prefixIcon: Icon(
              LucideIcons.user,
              size: 18,
              color: d.mutedForeground,
            ),
          ),
        ),
      TextField(
        key: const ValueKey<String>('report-department-field'),
        controller: _departmentController,
        focusNode: _departmentFocus,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Department (Optional)',
          hintText: 'e.g. CCS',
          prefixIcon: Icon(
            LucideIcons.building,
            size: 18,
            color: d.mutedForeground,
          ),
        ),
      ),
      TextField(
        key: const ValueKey<String>('report-year-level-field'),
        controller: _yearLevelController,
        focusNode: _yearLevelFocus,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Year Level (Optional)',
          hintText: 'e.g. 3rd Year',
          prefixIcon: Icon(
            LucideIcons.graduationCap,
            size: 18,
            color: d.mutedForeground,
          ),
        ),
      ),
      TextField(
        key: const ValueKey<String>('report-date-from-field'),
        controller: _dateFromController,
        focusNode: _dateFromFocus,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'Date From (YYYY-MM-DD)',
          hintText: '2026-01-01',
          prefixIcon: Icon(
            LucideIcons.calendarDays,
            size: 18,
            color: d.mutedForeground,
          ),
        ),
      ),
      TextField(
        key: const ValueKey<String>('report-date-to-field'),
        controller: _dateToController,
        focusNode: _dateToFocus,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _generateReport(),
        decoration: InputDecoration(
          labelText: 'Date To (YYYY-MM-DD)',
          hintText: '2026-12-31',
          prefixIcon: Icon(
            LucideIcons.calendarDays,
            size: 18,
            color: d.mutedForeground,
          ),
        ),
      ),
    ];

    return AppPageScaffold(
      title: 'Attendance & Event Reports',
      embedded: widget.embedded,
      body: FocusTraversalGroup(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Report Configuration',
                subtitle:
                    'Select report type, target event/student, and filters',
              ),
              SizedBox(height: d.gap),
              Container(
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
                    DropdownButtonFormField<String>(
                      key: const ValueKey<String>('report-type-dropdown'),
                      initialValue: _selectedReportType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Report Type',
                        prefixIcon: Icon(
                          LucideIcons.fileText,
                          size: 18,
                          color: d.mutedForeground,
                        ),
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
                    SizedBox(height: d.md),
                    ResponsiveGrid(
                      minItemWidth: 220,
                      maxColumns: 3,
                      spacing: d.gap,
                      children: filterFields,
                    ),
                    SizedBox(height: d.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        key: const ValueKey<String>('generate-report-button'),
                        pill: true,
                        onPressed: _isLoadingReport ? null : _generateReport,
                        isLoading: _isLoadingReport,
                        icon: LucideIcons.play,
                        label: 'Generate Report',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: d.md),
              _ReportExportButtonsCard(
                reportType: _selectedReportType,
                isExporting: _isExporting,
                onExportPdf: () => _exportReportFormat('pdf'),
                onExportCsv: () => _exportReportFormat('csv'),
                onExportExcel: () => _exportReportFormat('xlsx'),
              ),
              SizedBox(height: d.lg),
              SectionHeader(
                title: 'Report Results',
                subtitle: config.label,
              ),
              SizedBox(height: d.gap),
              if (_isLoadingReport)
                Padding(
                  padding: EdgeInsets.all(d.xl),
                  child: Center(
                    child: AppSpinner(color: d.authDark, size: 28),
                  ),
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
    );
  }
}

class _ReportExportButtonsCard extends StatelessWidget {
  final String reportType;
  final bool isExporting;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;

  const _ReportExportButtonsCard({
    required this.reportType,
    required this.isExporting,
    required this.onExportPdf,
    required this.onExportCsv,
    required this.onExportExcel,
  });

  bool get _supportsPdf => reportType == 'event_attendance';

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Report Payload',
              style: d.cardTitle,
            ),
            SizedBox(height: d.xs),
            Text(
              _supportsPdf
                  ? 'Generate formatted report data in CSV, XLSX, or PDF.'
                  : 'Generate formatted report data in CSV or XLSX (PDF is supported for Event Attendance Report).',
              style: d.supporting,
              softWrap: true,
            ),
            SizedBox(height: d.gap),
            Wrap(
              spacing: d.sm,
              runSpacing: d.sm,
              children: [
                AppButton(
                  key: const ValueKey<String>('export-csv-button'),
                  pill: true,
                  variant: AppButtonVariant.outline,
                  onPressed: isExporting ? null : onExportCsv,
                  icon: LucideIcons.fileSpreadsheet,
                  label: 'Export CSV',
                ),
                AppButton(
                  key: const ValueKey<String>('export-excel-button'),
                  pill: true,
                  variant: AppButtonVariant.outline,
                  onPressed: isExporting ? null : onExportExcel,
                  icon: LucideIcons.table,
                  label: 'Export XLSX',
                ),
                if (_supportsPdf)
                  AppButton(
                    key: const ValueKey<String>('export-pdf-button'),
                    pill: true,
                    variant: AppButtonVariant.outline,
                    onPressed: isExporting ? null : onExportPdf,
                    icon: LucideIcons.fileText,
                    label: 'Export PDF',
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
    final d = context.design;
    if (payload == null) {
      return const EmptyStateView(
        icon: LucideIcons.fileText,
        title: 'No report data loaded.',
        message: 'Choose parameters above and tap Generate Report.',
      );
    }

    if (payload is Map<String, dynamic>) {
      final map = payload as Map<String, dynamic>;
      final Map<String, dynamic> summaryMap;
      if (map['summary'] is Map<String, dynamic>) {
        summaryMap = map['summary'] as Map<String, dynamic>;
      } else {
        summaryMap = {
          for (final entry in map.entries)
            if (entry.value is! List && entry.value is! Map)
              entry.key: entry.value,
        };
      }

      final rawList = map['records'] ??
          map['items'] ??
          map['data'] ??
          map['attendances'];
      final recordsList = rawList is List
          ? rawList.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];

      if (summaryMap.isEmpty && recordsList.isEmpty) {
        return const EmptyStateView(
          icon: LucideIcons.inbox,
          title: 'No summary metrics available.',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summaryMap.isNotEmpty)
            ResponsiveGrid(
              minItemWidth: 160,
              maxColumns: 4,
              spacing: d.gap,
              children: [
                for (final entry in summaryMap.entries)
                  StatMetricCard(
                    label: entry.key.replaceAll('_', ' ').toUpperCase(),
                    value: entry.value?.toString() ?? 'N/A',
                    icon: LucideIcons.trendingUp,
                    color: d.primary,
                  ),
              ],
            ),
          if (summaryMap.isNotEmpty && recordsList.isNotEmpty)
            SizedBox(height: d.md),
          if (recordsList.isNotEmpty)
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in recordsList)
                      _ReportRowItemCard(reportType: reportType, item: item),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    if (payload is List) {
      final list = (payload as List).whereType<Map<String, dynamic>>().toList();
      if (list.isEmpty) {
        return const EmptyStateView(
          icon: LucideIcons.inbox,
          title: 'No records found for this report.',
          message: 'Try selecting another event or adjusting your filters.',
        );
      }

      return Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in list)
                _ReportRowItemCard(reportType: reportType, item: item),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
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
          child: Text(payload.toString(), style: d.body, softWrap: true),
        ),
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
    final d = context.design;
    if (reportType == 'organizer_summary') {
      final email = item['email']?.toString() ?? 'Organizer';
      final eventsCount = item['events_count'] ?? 0;
      final totalRegs = item['total_registrations'] ?? 0;
      final totalAtt = item['total_attendances'] ?? 0;

      return Container(
        margin: EdgeInsets.only(bottom: d.sm),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(d.sm),
              decoration: BoxDecoration(
                color: d.isDark ? d.muted : d.authSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.userCheck, color: d.primary, size: 20),
            ),
            SizedBox(width: d.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email, style: d.cardTitle, softWrap: true),
                  SizedBox(height: d.xs),
                  Text(
                    'Events: $eventsCount • Registered: $totalRegs • Attended: $totalAtt',
                    style: d.supporting,
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
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

    return Container(
      margin: EdgeInsets.only(bottom: d.sm),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 380 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primaryTitle, style: d.cardTitle, softWrap: true),
              if (secondarySubtitle.isNotEmpty) ...[
                SizedBox(height: d.xs),
                Text(secondarySubtitle, style: d.supporting, softWrap: true),
              ],
            ],
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                SizedBox(height: d.sm),
                StatusBadge(status: status),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: details),
              SizedBox(width: d.sm),
              StatusBadge(status: status),
            ],
          );
        },
      ),
    );
  }
}

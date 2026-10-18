import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/account_input.dart';

class ActivityLogsScreen extends StatefulWidget {
  final bool embedded;
  final List<dynamic>? initialLogs;

  const ActivityLogsScreen({
    super.key,
    this.embedded = false,
    this.initialLogs,
  });

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  late final TextEditingController _actionSearchController =
      TextEditingController();
  late final FocusNode _actionSearchFocus = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedModule = 'all';
  List<Map<String, dynamic>>? _fixtureLogs;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLogs != null) {
      _isLoading = false;
      _fixtureLogs = widget.initialLogs!
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _logs = _applyLocalFilters(_fixtureLogs!);
    } else {
      _fetchLogs();
    }
  }

  @override
  void dispose() {
    _actionSearchController.dispose();
    _actionSearchFocus.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyLocalFilters(
    List<Map<String, dynamic>> source,
  ) {
    final actionSearch = _actionSearchController.text.trim().toLowerCase();
    return source.where((log) {
      final module = (log['module']?.toString() ?? 'system').toLowerCase();
      if (_selectedModule != 'all' && module != _selectedModule) {
        return false;
      }
      if (actionSearch.isNotEmpty) {
        final action = (log['action']?.toString() ?? '').toLowerCase();
        if (!action.contains(actionSearch)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _fetchLogs() async {
    if (_fixtureLogs != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _logs = _applyLocalFilters(_fixtureLogs!);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queryParams = <String, String>{};
    if (_selectedModule != 'all') {
      queryParams['module'] = _selectedModule;
    }
    final actionSearch = _actionSearchController.text.trim();
    if (actionSearch.isNotEmpty) {
      queryParams['action'] = actionSearch;
    }

    final response = await ApiClient().get(
      ApiConstants.adminLogs,
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _logs = (response.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _errorMessage =
            response.message ?? 'Failed to load system activity logs.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return AppPageScaffold(
      title: 'System Activity Logs',
      embedded: widget.embedded,
      body: RefreshIndicator(
        onRefresh: _fetchLogs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'Audit Trail & Activity Logs',
                    subtitle:
                        'Inspect state-changing operations across authentication, events, QR identity, and attendance',
                    trailing: AppButton(
                      variant: AppButtonVariant.outline,
                      onPressed: _isLoading ? null : _fetchLogs,
                      icon: Icons.refresh,
                      label: 'Refresh',
                    ),
                  ),
                  SizedBox(height: d.gap),
                  AccountInput(
                    key: const ValueKey<String>(
                      'activity-action-search-field',
                    ),
                    controller: _actionSearchController,
                    focusNode: _actionSearchFocus,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _fetchLogs(),
                    decoration: InputDecoration(
                      labelText: 'Filter by Action Key',
                      hintText:
                          'e.g. login_success, event_created, attendance_recorded',
                      prefixIcon: const Icon(Icons.manage_search_outlined),
                      suffixIcon: IconButton(
                        tooltip: 'Search Action Logs',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _fetchLogs,
                      ),
                    ),
                  ),
                  SizedBox(height: d.gap),
                  _LogModuleFilterBar(
                    selectedModule: _selectedModule,
                    onSelectModule: (mod) {
                      setState(() => _selectedModule = mod);
                      _fetchLogs();
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: d.xl),
                  child: Center(
                    child: Semantics(
                      label: 'Loading system activity logs',
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null && _logs.isEmpty)
              SliverToBoxAdapter(
                child: ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchLogs,
                ),
              )
            else if (_logs.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: Icons.history_edu_outlined,
                  title: 'No audit log entries found.',
                  message:
                      'System activity logs matching the selected module will appear here.',
                  actionLabel: 'Refresh',
                  onAction: _fetchLogs,
                ),
              )
            else
              SliverList.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: d.sm),
                    child: _ActivityLogCard(log: log),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LogModuleFilterBar extends StatelessWidget {
  final String selectedModule;
  final ValueChanged<String> onSelectModule;

  const _LogModuleFilterBar({
    required this.selectedModule,
    required this.onSelectModule,
  });

  static const List<({String value, String label})> _modules = [
    (value: 'all', label: 'All Modules'),
    (value: 'auth', label: 'Auth'),
    (value: 'events', label: 'Events'),
    (value: 'registration', label: 'Registration'),
    (value: 'attendance', label: 'Attendance'),
    (value: 'qr', label: 'QR Identity'),
    (value: 'reports', label: 'Reports'),
    (value: 'admin', label: 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Wrap(
      spacing: d.sm,
      runSpacing: d.xs,
      children: [
        for (final m in _modules)
          ChoiceChip(
            key: ValueKey<String>('module-filter-${m.value}'),
            label: Text(m.label),
            selected: selectedModule == m.value,
            onSelected: (_) => onSelectModule(m.value),
          ),
      ],
    );
  }
}

class _ActivityLogCard extends StatefulWidget {
  final Map<String, dynamic> log;

  const _ActivityLogCard({required this.log});

  static String formatMetadata(dynamic metadata) {
    if (metadata == null) return '';
    if (metadata is Map) {
      return metadata.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(' • ');
    }
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = json.decode(metadata);
        if (decoded is Map) {
          return decoded.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(' • ');
        }
      } catch (_) {}
      return metadata;
    }
    return metadata.toString();
  }

  @override
  State<_ActivityLogCard> createState() => _ActivityLogCardState();
}

class _ActivityLogCardState extends State<_ActivityLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final log = widget.log;
    final action = log['action']?.toString() ?? 'system_action';
    final module = log['module']?.toString() ?? 'system';
    final userMap = log['user'] is Map
        ? Map<String, dynamic>.from(log['user'] as Map)
        : null;
    final userEmail = userMap?['email']?.toString() ??
        log['actor_email']?.toString() ??
        'System / Unauthenticated';
    final ipAddress = log['ip_address']?.toString() ?? 'N/A';
    final createdAt = log['created_at']?.toString() ?? '';
    final recordId = log['record_id'];
    final metadataText = _ActivityLogCard.formatMetadata(log['metadata']);
    final isLongMetadata = metadataText.length > 160;
    final visibleMetadata = !_expanded && isLongMetadata
        ? '${metadataText.substring(0, 160)}…'
        : metadataText;

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: d.sm,
            runSpacing: d.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                action.replaceAll('_', ' ').toUpperCase(),
                style: d.cardTitle,
              ),
              StatusBadge(
                status: 'completed',
                label: module.toUpperCase(),
                showIcon: false,
              ),
            ],
          ),
          SizedBox(height: d.xs),
          Text(
            'Actor: $userEmail • IP: $ipAddress${recordId != null ? ' • Record #$recordId' : ''}',
            style: d.supporting.copyWith(color: d.foreground),
            softWrap: true,
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Timestamp: ${createdAt.replaceAll('T', ' ').split('.').first}',
              style: d.supporting,
              softWrap: true,
            ),
          ],
          if (metadataText.isNotEmpty) ...[
            SizedBox(height: d.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(d.sm),
              decoration: BoxDecoration(
                color: d.muted,
                borderRadius: BorderRadius.circular(d.radiusControl),
                border: Border.all(color: d.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    visibleMetadata,
                    style: d.supporting.copyWith(
                      fontFamily: 'monospace',
                      color: d.foreground,
                    ),
                  ),
                  if (isLongMetadata) ...[
                    SizedBox(height: d.xs),
                    AppButton(
                      variant: AppButtonVariant.ghost,
                      label: _expanded ? 'Show Less' : 'Expand Full Metadata',
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

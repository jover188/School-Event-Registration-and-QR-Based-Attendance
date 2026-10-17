import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

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
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _actionSearchController.dispose();
    _actionSearchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
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
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        _errorMessage =
            response.message ?? 'Failed to load system activity logs.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Activity & Audit Logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh Audit Logs',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchLogs,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: TextField(
                key: const ValueKey<String>('activity-action-search-field'),
                controller: _actionSearchController,
                focusNode: _actionSearchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _fetchLogs(),
                decoration: InputDecoration(
                  labelText: 'Filter by Action Key',
                  hintText: 'e.g. login_success, event_created, attendance_recorded',
                  prefixIcon: const Icon(Icons.manage_search_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Search Action Logs',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _fetchLogs,
                  ),
                ),
              ),
            ),
            _LogModuleFilterBar(
              selectedModule: _selectedModule,
              onSelectModule: (mod) {
                setState(() => _selectedModule = mod);
                _fetchLogs();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? ErrorStateView(
                          message: _errorMessage!,
                          onRetry: _fetchLogs,
                        )
                      : _logs.isEmpty
                          ? EmptyStateView(
                              icon: Icons.history_edu_outlined,
                              title: 'No audit log entries found.',
                              message:
                                  'System activity logs matching the selected module will appear here.',
                              actionLabel: 'Refresh',
                              onAction: _fetchLogs,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLogs,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: _logs.length,
                                itemBuilder: (context, index) {
                                  final log = _logs[index];
                                  return _ActivityLogCard(log: log);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final m in _modules)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                key: ValueKey<String>('module-filter-${m.value}'),
                label: Text(m.label),
                selected: selectedModule == m.value,
                onSelected: (_) => onSelectModule(m.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _ActivityLogCard({required this.log});

  static String _formatMetadata(dynamic metadata) {
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
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? 'system_action';
    final module = log['module']?.toString() ?? 'system';
    final userMap = log['user'] is Map<String, dynamic>
        ? log['user'] as Map<String, dynamic>
        : null;
    final userEmail =
        userMap?['email']?.toString() ?? 'System / Unauthenticated';
    final ipAddress = log['ip_address']?.toString() ?? 'N/A';
    final createdAt = log['created_at']?.toString() ?? '';
    final recordId = log['record_id'];
    final metadataText = _formatMetadata(log['metadata']);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    action.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  status: 'completed',
                  label: module.toUpperCase(),
                  showIcon: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              'Actor: $userEmail • IP: $ipAddress${recordId != null ? ' • Record #$recordId' : ''}',
              style: AppTypography.bodyMuted,
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Timestamp: ${createdAt.replaceAll('T', ' ').split('.').first}',
                style: AppTypography.caption,
              ),
            ],
            if (metadataText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs + 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  metadataText,
                  style: AppTypography.caption.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

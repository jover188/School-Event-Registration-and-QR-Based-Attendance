import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';

class StudentQrInspectScreen extends StatefulWidget {
  final int studentId;
  final String? studentName;

  const StudentQrInspectScreen({
    super.key,
    required this.studentId,
    this.studentName,
  });

  @override
  State<StudentQrInspectScreen> createState() => _StudentQrInspectScreenState();
}

class _StudentQrInspectScreenState extends State<StudentQrInspectScreen> {
  bool _isLoading = true;
  bool _isReissuing = false;
  String? _errorMessage;
  Map<String, dynamic> _qrData = {};
  List<Map<String, dynamic>> _qrHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchQrDetails();
  }

  Future<void> _fetchQrDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(
      ApiConstants.adminStudentQr(widget.studentId),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _qrData = data;
        final historyList = data['qr_history'];
        if (historyList is List) {
          _qrHistory =
              historyList.whereType<Map<String, dynamic>>().toList();
        } else {
          _qrHistory = [];
        }
      } else {
        _errorMessage =
            response.message ?? 'Failed to load student QR code details.';
      }
    });
  }

  Future<void> _confirmAndForceReissue() async {
    final displayName = _qrData['full_name']?.toString() ??
        widget.studentName ??
        'Student #${widget.studentId}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Reissue Permanent QR?'),
        content: Text(
          'This will immediately revoke the current active QR token for $displayName and generate a new 64-character cryptographic token. Any printed or saved copies of the previous QR will become invalid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke & Reissue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isReissuing = true);

    final response = await ApiClient().post(
      ApiConstants.adminReissueStudentQr(widget.studentId),
      {},
    );

    if (!mounted) return;
    setState(() => _isReissuing = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.present,
          content: Text(
            response.message ??
                'Permanent QR code reissued and previous token revoked.',
          ),
        ),
      );
      _fetchQrDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            response.message ?? 'Failed to reissue student QR code.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _qrData['full_name']?.toString() ??
        widget.studentName ??
        'Student #${widget.studentId}';
    final studentIdNumber =
        _qrData['student_id_number']?.toString() ?? 'N/A';
    final activeQr = _qrData['active_qr'] is Map<String, dynamic>
        ? _qrData['active_qr'] as Map<String, dynamic>
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('QR Inspector: $fullName'),
        actions: [
          IconButton(
            tooltip: 'Refresh QR Status',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchQrDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchQrDetails,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchQrDetails,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _ActiveQrInspectorCard(
                          fullName: fullName,
                          studentIdNumber: studentIdNumber,
                          activeQr: activeQr,
                          isReissuing: _isReissuing,
                          onForceReissue: _confirmAndForceReissue,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const SectionHeader(
                          title: 'Token Issuance & Revocation History',
                          subtitle:
                              'Audit trail of active and revoked permanent QR tokens',
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                        if (_qrHistory.isEmpty)
                          const EmptyStateView(
                            icon: Icons.qr_code_2_outlined,
                            title: 'No QR token history found.',
                          )
                        else
                          for (final item in _qrHistory)
                            _QrHistoryItemCard(qrRecord: item),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ActiveQrInspectorCard extends StatelessWidget {
  final String fullName;
  final String studentIdNumber;
  final Map<String, dynamic>? activeQr;
  final bool isReissuing;
  final VoidCallback onForceReissue;

  const _ActiveQrInspectorCard({
    required this.fullName,
    required this.studentIdNumber,
    required this.activeQr,
    required this.isReissuing,
    required this.onForceReissue,
  });

  @override
  Widget build(BuildContext context) {
    final qrToken = activeQr?['qr_token']?.toString() ?? '';
    final status = activeQr?['status']?.toString() ?? 'inactive';
    final issuedAt = activeQr?['created_at']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: AppTypography.title),
                      const SizedBox(height: 2),
                      Text(
                        'Student ID: $studentIdNumber',
                        style: AppTypography.bodyMuted,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            if (qrToken.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: qrToken,
                  version: QrVersions.auto,
                  size: 168,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              SelectableText(
                qrToken,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (issuedAt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Issued: ${issuedAt.replaceAll('T', ' ').split('.').first}',
                  style: AppTypography.caption,
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No active permanent QR token currently assigned.',
                  style: AppTypography.bodyMuted,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey<String>('force-reissue-qr-button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.absent,
                ),
                onPressed: isReissuing ? null : onForceReissue,
                icon: isReissuing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.autorenew_rounded),
                label: const Text('Force Reissue QR Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrHistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> qrRecord;

  const _QrHistoryItemCard({required this.qrRecord});

  @override
  Widget build(BuildContext context) {
    final token = qrRecord['qr_token']?.toString() ?? '';
    final shortToken = token.length >= 16
        ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
        : token;
    final status = qrRecord['status']?.toString() ?? 'revoked';
    final createdAt = qrRecord['created_at']?.toString() ?? '';
    final revokedAt = qrRecord['revoked_at']?.toString() ?? '';

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
                  Text(
                    'Token: $shortToken',
                    style: AppTypography.subtitle.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Issued: ${createdAt.replaceAll('T', ' ').split('.').first}',
                      style: AppTypography.caption,
                    ),
                  ],
                  if (revokedAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Revoked: ${revokedAt.replaceAll('T', ' ').split('.').first}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.absent,
                      ),
                    ),
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

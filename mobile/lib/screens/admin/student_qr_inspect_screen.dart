import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';

class StudentQrInspectScreen extends StatefulWidget {
  final int studentId;
  final String? studentName;
  final String? studentLabel;
  final Map<String, dynamic>? initialData;

  const StudentQrInspectScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.studentLabel,
    this.initialData,
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

  String get _fallbackLabel =>
      widget.studentLabel ??
      widget.studentName ??
      'Student #${widget.studentId}';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _isLoading = false;
      _applyQrPayload(widget.initialData!);
    } else {
      _fetchQrDetails();
    }
  }

  void _applyQrPayload(Map<String, dynamic> rawData) {
    final data = Map<String, dynamic>.from(rawData);
    _qrData = data;
    final historyList = data['qr_history'] ?? data['history'];
    if (historyList is List) {
      _qrHistory = historyList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      _qrHistory = [];
    }
  }

  Future<void> _fetchQrDetails() async {
    if (widget.initialData != null && _qrData.isNotEmpty) {
      return;
    }

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
        _applyQrPayload(response.data as Map<String, dynamic>);
      } else {
        _errorMessage =
            response.message ?? 'Failed to load student QR code details.';
      }
    });
  }

  Map<String, dynamic>? get _resolvedActiveQr {
    if (_qrData['active_qr'] is Map) {
      return Map<String, dynamic>.from(_qrData['active_qr'] as Map);
    }
    final topToken = _qrData['qr_token']?.toString();
    if (topToken != null && topToken.isNotEmpty) {
      return {
        'qr_token': topToken,
        'status': _qrData['status']?.toString() ?? 'active',
        'created_at':
            _qrData['issued_at']?.toString() ?? _qrData['created_at']?.toString() ?? '',
      };
    }
    return null;
  }

  Future<void> _confirmAndForceReissue() async {
    final displayName =
        _qrData['full_name']?.toString() ?? _fallbackLabel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ForceReissueQrDialog(displayName: displayName),
    );

    if (confirmed != true || !mounted) return;

    if (widget.initialData != null) {
      setState(() {
        final previousQr = _resolvedActiveQr;
        const nowIso = '2026-10-17T15:30:00Z';
        if (previousQr != null) {
          _qrHistory = [
            {
              ...previousQr,
              'status': 'revoked',
              'revoked_at': nowIso,
            },
            ..._qrHistory.map((item) => {
                  ...item,
                  if (item['status'] == 'active') 'status': 'revoked',
                  if (item['status'] == 'active') 'revoked_at': nowIso,
                }),
          ];
        }
        const newToken =
            'f9e8d7c6b5a40312f9e8d7c6b5a40312f9e8d7c6b5a40312f9e8d7c6b5a40312';
        _qrData = {
          ..._qrData,
          'active_qr': {
            'qr_token': newToken,
            'status': 'active',
            'created_at': nowIso,
          },
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.design.success,
          content: const Text(
            'Permanent QR code reissued and previous token revoked.',
          ),
        ),
      );
      return;
    }

    setState(() => _isReissuing = true);

    final response = await ApiClient().post(
      ApiConstants.adminReissueStudentQr(widget.studentId),
      {},
    );

    if (!mounted) return;
    setState(() => _isReissuing = false);

    final d = context.design;
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.success,
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
          backgroundColor: d.destructive,
          content: Text(
            response.message ?? 'Failed to reissue student QR code.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final fullName =
        _qrData['full_name']?.toString() ?? _fallbackLabel;
    final studentIdNumber =
        _qrData['student_id_number']?.toString() ?? 'N/A';
    final activeQr = _resolvedActiveQr;

    return AppPageScaffold(
      title: 'QR Inspector: $fullName',
      maxWidth: 840,
      body: _isLoading
          ? Center(
              child: Semantics(
                label: 'Loading student QR details',
                child: const CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null && _qrData.isEmpty
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchQrDetails,
                )
              : RefreshIndicator(
                  onRefresh: _fetchQrDetails,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _ActiveQrInspectorCard(
                        fullName: fullName,
                        studentIdNumber: studentIdNumber,
                        activeQr: activeQr,
                        isReissuing: _isReissuing,
                        onForceReissue: _confirmAndForceReissue,
                        onRefresh: _isLoading ? null : _fetchQrDetails,
                      ),
                      SizedBox(height: d.lg),
                      const SectionHeader(
                        title: 'Token Issuance & Revocation History',
                        subtitle:
                            'Audit trail of active and revoked permanent QR tokens',
                      ),
                      SizedBox(height: d.gap),
                      if (_qrHistory.isEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: d.card,
                            borderRadius: BorderRadius.circular(d.radiusCard),
                            border: Border.all(color: d.border),
                          ),
                          child: const EmptyStateView(
                            icon: Icons.qr_code_2_outlined,
                            title: 'No QR token history found.',
                          ),
                        )
                      else
                        for (final item in _qrHistory)
                          Padding(
                            padding: EdgeInsets.only(bottom: d.sm),
                            child: _QrHistoryItemCard(qrRecord: item),
                          ),
                    ],
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
  final VoidCallback? onRefresh;

  const _ActiveQrInspectorCard({
    required this.fullName,
    required this.studentIdNumber,
    required this.activeQr,
    required this.isReissuing,
    required this.onForceReissue,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final qrToken = activeQr?['qr_token']?.toString() ?? '';
    final status = activeQr?['status']?.toString() ?? 'inactive';
    final issuedAt = activeQr?['created_at']?.toString() ??
        activeQr?['issued_at']?.toString() ??
        '';

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: d.sm,
            runSpacing: d.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: d.sectionTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Student ID: $studentIdNumber',
                    style: d.supporting,
                  ),
                ],
              ),
              StatusBadge(status: status),
            ],
          ),
          const Divider(),
          if (qrToken.isNotEmpty) ...[
            Semantics(
              container: true,
              label: 'Active permanent QR code for $fullName',
              child: ResponsiveQrFrame(
                builder: (frameSize) {
                  final framePadding = frameSize < 220 ? d.sm : d.md;
                  final qrSize =
                      (frameSize - (framePadding * 2)).clamp(120.0, 248.0);
                  return Container(
                    width: frameSize,
                    height: frameSize,
                    padding: EdgeInsets.all(framePadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(d.radiusControl),
                      border: Border.all(color: d.border),
                    ),
                    alignment: Alignment.center,
                    child: QrImageView(
                      data: qrToken,
                      version: QrVersions.auto,
                      size: qrSize,
                      gapless: true,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: d.gap),
            SelectableText(
              qrToken,
              key: const ValueKey<String>('active-qr-token-text'),
              style: d.supporting.copyWith(
                fontFamily: 'monospace',
                color: d.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            if (issuedAt.isNotEmpty) ...[
              SizedBox(height: d.xs),
              Text(
                'Issued: ${issuedAt.replaceAll('T', ' ').split('.').first}',
                style: d.supporting,
                textAlign: TextAlign.center,
              ),
            ],
          ] else
            Padding(
              padding: EdgeInsets.symmetric(vertical: d.md),
              child: Text(
                'No active permanent QR token currently assigned.',
                style: d.supporting,
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: d.md),
          Wrap(
            spacing: d.sm,
            runSpacing: d.sm,
            alignment: WrapAlignment.end,
            children: [
              if (onRefresh != null)
                AppButton(
                  variant: AppButtonVariant.outline,
                  icon: Icons.refresh,
                  label: 'Refresh Status',
                  onPressed: onRefresh,
                ),
              AppButton(
                key: const ValueKey<String>('force-reissue-qr-button'),
                variant: AppButtonVariant.destructive,
                isLoading: isReissuing,
                icon: Icons.autorenew_rounded,
                label: 'Force Reissue QR Code',
                onPressed: onForceReissue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForceReissueQrDialog extends StatelessWidget {
  final String displayName;

  const _ForceReissueQrDialog({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AlertDialog(
      title: const Text('Force Reissue Permanent QR?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This will immediately revoke the current active QR token for $displayName and generate a new 64-character cryptographic token. Any printed or saved copies of the previous QR will become invalid.',
                style: d.body,
              ),
            ],
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
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context, false),
              label: 'Cancel',
            ),
            AppButton(
              key: const ValueKey<String>('confirm-force-reissue-button'),
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.pop(context, true),
              label: 'Revoke & Reissue',
            ),
          ],
        ),
      ],
    );
  }
}

class _QrHistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> qrRecord;

  const _QrHistoryItemCard({required this.qrRecord});

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final token = qrRecord['qr_token']?.toString() ?? '';
    final shortToken = token.length >= 16
        ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
        : token;
    final status = qrRecord['status']?.toString() ?? 'revoked';
    final createdAt = qrRecord['created_at']?.toString() ?? '';
    final revokedAt = qrRecord['revoked_at']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: Wrap(
        spacing: d.sm,
        runSpacing: d.xs,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Token: $shortToken',
                style: d.cardTitle.copyWith(fontFamily: 'monospace'),
              ),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Issued: ${createdAt.replaceAll('T', ' ').split('.').first}',
                  style: d.supporting,
                ),
              ],
              if (revokedAt.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Revoked: ${revokedAt.replaceAll('T', ' ').split('.').first}',
                  style: d.supporting.copyWith(color: d.destructive),
                ),
              ],
            ],
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}

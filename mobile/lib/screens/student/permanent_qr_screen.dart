import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class PermanentQrScreen extends StatefulWidget {
  final bool embedded;
  final Map<String, dynamic>? initialQrData;
  final String? initialErrorMessage;

  const PermanentQrScreen({
    super.key,
    this.embedded = false,
    this.initialQrData,
    this.initialErrorMessage,
  });

  @override
  State<PermanentQrScreen> createState() => _PermanentQrScreenState();
}

class _PermanentQrScreenState extends State<PermanentQrScreen> {
  bool _isLoading = true;
  bool _isReissuing = false;
  String? _qrToken;
  String? _studentName;
  String? _studentId;
  String? _status;
  String? _errorMessage;

  bool get _hasFixtureData =>
      widget.initialQrData != null || widget.initialErrorMessage != null;

  @override
  void initState() {
    super.initState();
    if (_hasFixtureData) {
      _isLoading = false;
      _errorMessage = widget.initialErrorMessage;
      final data = widget.initialQrData;
      if (data != null) {
        _qrToken = (data['qr_token'] ?? data['new_qr_token'])?.toString();
        _studentName = data['full_name']?.toString();
        _studentId = data['student_id_number']?.toString();
        _status = data['status']?.toString();
      }
    } else {
      _fetchQrData();
    }
  }

  Future<void> _fetchQrData() async {
    if (_hasFixtureData && widget.initialQrData != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        final data = widget.initialQrData!;
        _qrToken = (data['qr_token'] ?? data['new_qr_token'])?.toString();
        _studentName = data['full_name']?.toString();
        _studentId = data['student_id_number']?.toString();
        _status = data['status']?.toString();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.studentQr);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _qrToken = data['qr_token']?.toString();
        _studentName = data['full_name']?.toString();
        _studentId = data['student_id_number']?.toString();
        _status = data['status']?.toString();
      } else {
        _errorMessage =
            response.message ?? 'Failed to load permanent QR code.';
      }
    });
  }

  Future<void> _confirmReissue() async {
    final d = context.design;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Reissue Permanent QR Code?'),
        content: const Text(
          'Reissuing will immediately and permanently revoke your current QR code. You will need to present the new QR code at all future events.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: d.destructive,
              foregroundColor: d.destructiveForeground,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reissue Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isReissuing = true;
    });

    final response = await ApiClient().post(ApiConstants.reissueQr, {});

    if (!mounted) return;

    setState(() {
      _isReissuing = false;
    });

    if (response.success && response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      setState(() {
        _qrToken = (data['new_qr_token'] ?? data['qr_token'])?.toString();
        _status = data['status']?.toString() ?? _status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.success,
          content: const Text(
            'Your permanent QR code has been successfully reissued!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: d.destructive,
          content: Text(response.message ?? 'Failed to reissue QR code.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final activeStatus = _status ?? 'active';

    return AppPageScaffold(
      title: 'Permanent Student QR',
      embedded: widget.embedded,
      maxWidth: 640,
      actions: [
        IconButton(
          tooltip: 'Refresh QR Code',
          icon: const Icon(Icons.refresh),
          onPressed: (_isLoading || _isReissuing) ? null : _fetchQrData,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _qrToken == null
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchQrData,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 340;
                    final cardPadding = isNarrow ? d.sm : d.lg;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: d.card,
                              borderRadius: BorderRadius.circular(d.radiusCard),
                              border: Border.all(color: d.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _studentName ?? 'Student',
                                  style: d.sectionTitle,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: d.xs),
                                Text(
                                  'Student ID: ${_studentId ?? 'N/A'}',
                                  style: d.supporting,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: d.md),
                                if (_qrToken != null)
                                  Semantics(
                                    container: true,
                                    label:
                                        'Permanent student QR code for ${_studentName ?? 'Student'}',
                                    child: ResponsiveQrFrame(
                                      builder: (qrSize) => DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            d.radiusControl,
                                          ),
                                          border: Border.all(color: d.border),
                                        ),
                                        child: QrImageView(
                                          data: _qrToken!,
                                          version: QrVersions.auto,
                                          size: qrSize,
                                          padding: const EdgeInsets.all(16),
                                          backgroundColor: Colors.white,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: Colors.black,
                                          ),
                                          dataModuleStyle:
                                              const QrDataModuleStyle(
                                            dataModuleShape:
                                                QrDataModuleShape.square,
                                            color: Colors.black,
                                          ),
                                          errorCorrectionLevel:
                                              QrErrorCorrectLevel.H,
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: d.md),
                                StatusBadge(
                                  status: activeStatus,
                                  label:
                                      'STATUS: ${activeStatus.toUpperCase()}',
                                ),
                                SizedBox(height: d.gap),
                                Text(
                                  'Present this QR code to the event organizer for check-in and check-out.',
                                  textAlign: TextAlign.center,
                                  style: d.supporting,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: d.lg),
                          Container(
                            padding: EdgeInsets.all(d.md),
                            decoration: BoxDecoration(
                              color: d.card,
                              borderRadius: BorderRadius.circular(d.radiusCard),
                              border: Border.all(color: d.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppButton(
                                  key: const ValueKey('reissue-qr-button'),
                                  variant: AppButtonVariant.destructive,
                                  icon: Icons.refresh,
                                  isLoading: _isReissuing,
                                  onPressed: _confirmReissue,
                                  label: 'Reissue Permanent QR Code',
                                ),
                                SizedBox(height: d.sm),
                                Text(
                                  'Lost device or compromised QR? Reissuing revokes the old code immediately.',
                                  textAlign: TextAlign.center,
                                  style: d.supporting,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

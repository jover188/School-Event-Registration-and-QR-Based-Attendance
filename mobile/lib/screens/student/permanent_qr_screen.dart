import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_state_view.dart';
import '../../core/widgets/status_badge.dart';

class PermanentQrScreen extends StatefulWidget {
  const PermanentQrScreen({super.key});

  @override
  State<PermanentQrScreen> createState() => _PermanentQrScreenState();
}

class _PermanentQrScreenState extends State<PermanentQrScreen> {
  bool _isLoading = true;
  String? _qrToken;
  String? _studentName;
  String? _studentId;
  String? _status;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchQrData();
  }

  Future<void> _fetchQrData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiClient().get(ApiConstants.studentQr);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success && response.data != null) {
      setState(() {
        _qrToken = response.data['qr_token']?.toString();
        _studentName = response.data['full_name']?.toString();
        _studentId = response.data['student_id_number']?.toString();
        _status = response.data['status']?.toString();
      });
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Failed to load permanent QR code.';
      });
    }
  }

  Future<void> _confirmReissue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reissue Permanent QR Code?'),
        content: const Text(
          'Reissuing will immediately and permanently revoke your current QR code. You will need to present the new QR code at all future events.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reissue Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiClient().post(ApiConstants.reissueQr, {});

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.success && response.data != null) {
        setState(() {
          _qrToken = response.data['new_qr_token']?.toString();
          _status = response.data['status']?.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.present,
            content: Text(
              'Your permanent QR code has been successfully reissued!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.absent,
            content: Text(response.message ?? 'Failed to reissue QR code.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = _status ?? 'active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permanent Student QR'),
        actions: [
          IconButton(
            tooltip: 'Refresh QR Code',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchQrData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ErrorStateView(
                    message: _errorMessage!,
                    onRetry: _fetchQrData,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Text(
                                  _studentName ?? 'Student',
                                  style: AppTypography.headline,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Student ID: ${_studentId ?? ''}',
                                  style: AppTypography.bodyMuted,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // QR Code Renderer
                                if (_qrToken != null)
                                  Semantics(
                                    label:
                                        'Permanent student QR code for ${_studentName ?? 'Student'}',
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sm + 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: QrImageView(
                                        data: _qrToken!,
                                        version: QrVersions.auto,
                                        size: 240,
                                        errorCorrectionLevel:
                                            QrErrorCorrectLevel.H,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.md),

                                StatusBadge(
                                  status: activeStatus,
                                  label:
                                      'STATUS: ${activeStatus.toUpperCase()}',
                                ),
                                const SizedBox(height: AppSpacing.sm + 4),
                                const Text(
                                  'Present this QR code to the event organizer for check-in and check-out.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.absent,
                            side: const BorderSide(color: AppColors.absent),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 14,
                            ),
                          ),
                          onPressed: _confirmReissue,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reissue Permanent QR Code'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Lost device or compromised QR? Reissuing revokes the old code immediately.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

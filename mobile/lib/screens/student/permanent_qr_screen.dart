import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/layout/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/app_toast.dart';
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

      AppToast.success(
        context,
        'Your permanent QR code has been successfully reissued!',
      );
    } else {
      AppToast.error(
        context,
        response.message ?? 'Failed to reissue QR code.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final activeStatus = _status ?? 'active';
    final displayName = _studentName ?? 'Student';

    return AppPageScaffold(
      title: 'My QR Code',
      embedded: widget.embedded,
      maxWidth: 640,
      body: _isLoading
          ? Center(
              child: AppSpinner(
                size: 28,
                color: d.primary,
              ),
            )
          : _errorMessage != null && _qrToken == null
              ? ErrorStateView(
                  message: _errorMessage!,
                  onRetry: _fetchQrData,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 340;
                    final cardPadding = isNarrow ? d.sm : d.md;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: d.card,
                              borderRadius: BorderRadius.circular(d.radiusCard),
                              border: Border.all(
                                color: d.border,
                                width: 1,
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
                              children: [
                                Container(
                                  key: const ValueKey(
                                    'student-qr-wallet-header',
                                  ),
                                  padding: EdgeInsets.only(bottom: d.sm),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: d.sm,
                                    runSpacing: d.xs,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/logo_mark.png',
                                            height: 36,
                                            fit: BoxFit.contain,
                                            color:
                                                d.isDark ? d.primary : null,
                                            colorBlendMode: d.isDark
                                                ? BlendMode.srcIn
                                                : null,
                                          ),
                                          SizedBox(width: d.sm),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  displayName,
                                                  style:
                                                      d.sectionTitle.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  'ID: ${_studentId ?? 'N/A'}',
                                                  style: d.supporting.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      StatusBadge(
                                        status: activeStatus,
                                        label: activeStatus.toUpperCase(),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: d.md,
                                  color: d.border,
                                ),
                                SizedBox(height: d.xs),
                                if (_qrToken != null)
                                  Semantics(
                                    container: true,
                                    label:
                                        'Permanent student QR code for $displayName',
                                    child: ResponsiveQrFrame(
                                      builder: (qrSize) => DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            d.radiusCard,
                                          ),
                                          border: Border.all(
                                            color: d.border,
                                            width: 1,
                                          ),
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
                                SizedBox(height: d.sm),
                                Text(
                                  'Show this QR code to the organizer for check-in and check-out.',
                                  textAlign: TextAlign.center,
                                  style: d.body.copyWith(
                                    color: d.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: d.md),
                          Container(
                            padding: EdgeInsets.all(d.md),
                            decoration: BoxDecoration(
                              color: d.card,
                              borderRadius: BorderRadius.circular(d.radiusCard),
                              border: Border.all(color: d.border, width: 1),
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
                                AppButton(
                                  key: const ValueKey('reissue-qr-button'),
                                  variant: AppButtonVariant.destructive,
                                  pill: true,
                                  icon: LucideIcons.refreshCw,
                                  isLoading: _isReissuing,
                                  onPressed: _confirmReissue,
                                  label: 'Reissue QR Code',
                                ),
                                SizedBox(height: d.sm),
                                Text(
                                  'Reissuing immediately deactivates your current QR code.',
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

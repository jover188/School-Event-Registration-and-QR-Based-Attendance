import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';

class QrScannerScreen extends StatefulWidget {
  final EventModel event;
  const QrScannerScreen({super.key, required this.event});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String _mode = 'check_in'; // 'check_in' or 'check_out'
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.length != 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.absent,
          content: Text(
            'Invalid QR code format. Expected 64-character token.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _scannerController.stop();

    final response = await ApiClient().post(
      ApiConstants.scanAttendance(widget.event.id),
      {
        'qr_token': rawValue,
        'mode': _mode,
      },
    );

    if (!mounted) return;

    if (response.success && response.data is Map<String, dynamic>) {
      await _showVerificationModal(response.data as Map<String, dynamic>);
    } else {
      await _showErrorDialog(response.message ?? 'Attendance scan failed.');
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  Future<void> _showVerificationModal(Map<String, dynamic> data) async {
    final student = (data['student'] as Map<String, dynamic>?) ?? {};
    final rawStatus = (data['status'] ?? 'present').toString();
    final statusUpper = rawStatus.toUpperCase();
    final isCheckOut = _mode == 'check_out';
    final displayTime = isCheckOut
        ? (data['check_out_time'] ?? data['check_in_time'] ?? 'N/A')
        : (data['check_in_time'] ?? 'N/A');
    final timeLabel = isCheckOut ? 'Check-out Time' : 'Check-in Time';
    final photoUrl = student['profile_photo_url']?.toString();

    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Student Profile Photo for Face Verification
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.border,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.textMuted,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm + 4),

            Text(
              student['full_name']?.toString() ?? 'Student',
              style: AppTypography.headline.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${student['student_id_number'] ?? ''} • ${student['course'] ?? ''}',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.sm + 4),

            // Status Badge
            StatusBadge(
              status: rawStatus,
              label: isCheckOut ? 'CHECK-OUT RECORDED' : 'CHECK-IN: $statusUpper',
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              '$timeLabel: $displayTime',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md + 4),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Confirm & Scan Next'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.absent),
            SizedBox(width: AppSpacing.sm),
            Text('Scan Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Scanning'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner: ${widget.event.title}'),
        actions: [
          IconButton(
            tooltip: 'Toggle Flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Viewfinder
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Scanning Reticle / Overlay
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),

            // Mode Selector (Check-In vs Check-Out)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _mode == 'check_in',
                        label: 'Check-In Mode',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => setState(() => _mode = 'check_in'),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _mode == 'check_in'
                                  ? AppColors.present
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Check-In Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: _mode == 'check_out',
                        label: 'Check-Out Mode',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => setState(() => _mode = 'check_out'),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _mode == 'check_out'
                                  ? AppColors.walkIn
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Check-Out Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Processing Indicator
            if (_isProcessing)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.length != 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.absentColor,
          content: Text('Invalid QR code format. Expected 64-character token.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _scannerController.stop();

    // Call attendance API
    final response = await ApiClient().post(
      ApiConstants.scanAttendance(widget.event.id),
      {
        'qr_token': rawValue,
        'mode': _mode,
      },
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      await _showVerificationModal(response.data);
    } else {
      await _showErrorDialog(response.message ?? 'Attendance scan failed.');
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      _scannerController.start();
    }
  }

  Future<void> _showVerificationModal(Map<String, dynamic> data) async {
    final student = data['student'] ?? {};
    final status = (data['status'] ?? 'present').toString().toUpperCase();
    final checkInTime = data['check_in_time'];
    final photoUrl = student['profile_photo_url'];

    Color statusColor;
    switch (status) {
      case 'LATE':
        statusColor = AppTheme.lateColor;
        break;
      case 'WALK_IN':
        statusColor = AppTheme.walkInColor;
        break;
      default:
        statusColor = AppTheme.presentColor;
    }

    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Student Profile Photo for Face Verification
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 48, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),

            Text(
              student['full_name'] ?? 'Student',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              'ID: ${student['student_id_number'] ?? ''} • ${student['course'] ?? ''}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                _mode == 'check_out' ? 'CHECK-OUT RECORDED' : 'CHECK-IN: $status',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Time: ${checkInTime ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppTheme.primary,
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
            Icon(Icons.error_outline, color: AppTheme.absentColor),
            SizedBox(width: 8),
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
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Mode Selector (Check-In vs Check-Out)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = 'check_in'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _mode == 'check_in' ? AppTheme.presentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Check-In Mode',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = 'check_out'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _mode == 'check_out' ? AppTheme.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Check-Out Mode',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }
}

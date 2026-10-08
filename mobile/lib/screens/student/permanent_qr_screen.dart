import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

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

    setState(() {
      _isLoading = false;
    });

    if (response.success && response.data != null) {
      setState(() {
        _qrToken = response.data['qr_token'];
        _studentName = response.data['full_name'];
        _studentId = response.data['student_id_number'];
        _status = response.data['status'];
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load permanent QR code.';
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.absentColor),
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

      setState(() {
        _isLoading = false;
      });

      if (response.success && response.data != null) {
        setState(() {
          _qrToken = response.data['new_qr_token'];
          _status = response.data['status'];
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.presentColor,
            content: Text('Your permanent QR code has been successfully reissued!'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.absentColor,
            content: Text(response.message ?? 'Failed to reissue QR code.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permanent Student QR')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: AppTheme.absentColor)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchQrData, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                _studentName ?? 'Student',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Student ID: ${_studentId ?? ''}',
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 16),

                              // QR Code Renderer
                              if (_qrToken != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: QrImageView(
                                    data: _qrToken!,
                                    version: QrVersions.auto,
                                    size: 240,
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.presentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Status: ${(_status ?? 'Active').toUpperCase()}',
                                  style: const TextStyle(
                                    color: AppTheme.presentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Present this QR code to the event organizer for check-in and check-out.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.absentColor,
                          side: const BorderSide(color: AppTheme.absentColor),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: _confirmReissue,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reissue Permanent QR Code'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lost device or compromised QR? Reissuing revokes the old code immediately.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

/// Camera-free presentation widget for QR attendance scan results and errors.
class ScanResultContent extends StatelessWidget {
  final Map<String, dynamic>? result;
  final String? errorMessage;
  final String mode;
  final bool isProcessing;
  final VoidCallback onScanNext;
  final VoidCallback? onOpenAttendance;

  const ScanResultContent({
    super.key,
    this.result,
    this.errorMessage,
    required this.mode,
    this.isProcessing = false,
    required this.onScanNext,
    this.onOpenAttendance,
  });

  static String _resolveInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    if (isProcessing) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Validating QR attendance token with server',
        child: Container(
          padding: EdgeInsets.all(d.lg),
          decoration: BoxDecoration(
            color: d.card,
            borderRadius: BorderRadius.circular(d.radiusCard),
            border: Border.all(color: d.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: d.primary,
                ),
              ),
              SizedBox(height: d.md),
              Text(
                'Recording attendance…',
                style: d.cardTitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: d.xs),
              Text(
                'Hold steady while the server verifies student registration and eligibility.',
                style: d.supporting,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Scan rejected: $errorMessage',
        child: Container(
          padding: EdgeInsets.all(d.lg),
          decoration: BoxDecoration(
            color: d.card,
            borderRadius: BorderRadius.circular(d.radiusCard),
            border: Border.all(color: d.destructive.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(d.sm),
                    decoration: BoxDecoration(
                      color: d.dangerBackground,
                      borderRadius: BorderRadius.circular(d.radiusControl),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: d.destructive,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: d.gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan Rejected', style: d.cardTitle),
                        SizedBox(height: d.xs),
                        const StatusBadge(
                          status: 'rejected',
                          label: 'NOT RECORDED',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: d.md),
              Text(
                errorMessage!,
                style: d.body,
              ),
              SizedBox(height: d.lg),
              AppButton(
                key: const ValueKey<String>('scan-error-retry-button'),
                label: 'Scan Next QR Code',
                icon: Icons.qr_code_scanner,
                onPressed: onScanNext,
              ),
              if (onOpenAttendance != null) ...[
                SizedBox(height: d.sm),
                AppButton(
                  label: 'View attendance',
                  variant: AppButtonVariant.outline,
                  icon: Icons.fact_check_outlined,
                  onPressed: onOpenAttendance,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (result == null) {
      return Container(
        padding: EdgeInsets.all(d.lg),
        decoration: BoxDecoration(
          color: d.card,
          borderRadius: BorderRadius.circular(d.radiusCard),
          border: Border.all(color: d.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mode == 'check_out'
                  ? 'Ready for Check-Out Scan'
                  : 'Ready for Check-In Scan',
              style: d.cardTitle,
            ),
            SizedBox(height: d.xs),
            Text(
              'Align the student’s permanent 64-character QR code inside the reticle. Verify their identity card after each scan.',
              style: d.supporting,
            ),
          ],
        ),
      );
    }

    final data = result!;
    final student = (data['student'] as Map<String, dynamic>?) ?? {};
    final fullName = student['full_name']?.toString().trim().isNotEmpty == true
        ? student['full_name'].toString().trim()
        : 'Student';
    final studentIdNumber =
        student['student_id_number']?.toString().trim().isNotEmpty == true
            ? student['student_id_number'].toString().trim()
            : 'N/A';
    final course = student['course']?.toString().trim() ?? '';
    final yearLevel = student['year_level']?.toString().trim() ?? '';
    final section = student['section']?.toString().trim() ?? '';
    final photoUrl = student['profile_photo_url']?.toString().trim();

    final academicParts = [
      if (course.isNotEmpty) course,
      if (yearLevel.isNotEmpty) yearLevel,
      if (section.isNotEmpty) 'Sec $section',
    ].join(' • ');

    final rawStatus = (data['status'] ?? 'present').toString();
    final statusUpper = rawStatus.replaceAll('_', ' ').toUpperCase();
    final isCheckOut = mode == 'check_out' ||
        (data['check_out_time'] != null &&
            data['check_out_time'].toString().isNotEmpty &&
            data['mode'] == 'check_out');
    final checkInTime = data['check_in_time']?.toString() ?? '';
    final checkOutTime = data['check_out_time']?.toString() ?? '';
    final primaryTimestamp = isCheckOut
        ? (checkOutTime.isNotEmpty
            ? checkOutTime
            : (checkInTime.isNotEmpty ? checkInTime : 'N/A'))
        : (checkInTime.isNotEmpty ? checkInTime : 'N/A');
    final timeLabel = isCheckOut ? 'Check-Out Time' : 'Check-In Time';

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'Scan verified for $fullName, ID $studentIdNumber, status $statusUpper',
      child: Container(
        padding: EdgeInsets.all(d.lg),
        decoration: BoxDecoration(
          color: d.card,
          borderRadius: BorderRadius.circular(d.radiusCard),
          border: Border.all(color: d.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: d.selection,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        _resolveInitials(fullName),
                        style: d.sectionTitle.copyWith(
                          color: d.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(height: d.md),
            Text(
              fullName,
              style: d.sectionTitle,
              textAlign: TextAlign.center,
              softWrap: true,
            ),
            SizedBox(height: d.xs),
            Text(
              'Student ID: $studentIdNumber',
              style: d.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (academicParts.isNotEmpty) ...[
              SizedBox(height: d.xs),
              Text(
                academicParts,
                style: d.supporting,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ],
            SizedBox(height: d.md),
            Center(
              child: StatusBadge(
                status: rawStatus,
                label: isCheckOut
                    ? 'CHECK-OUT RECORDED ($statusUpper)'
                    : 'CHECK-IN: $statusUpper',
              ),
            ),
            SizedBox(height: d.md),
            Container(
              padding: EdgeInsets.all(d.gap),
              decoration: BoxDecoration(
                color: d.muted,
                borderRadius: BorderRadius.circular(d.radiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$timeLabel: ${primaryTimestamp.replaceAll('T', ' ').split('.').first}',
                    style: d.supporting.copyWith(
                      color: d.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isCheckOut && checkInTime.isNotEmpty) ...[
                    SizedBox(height: d.xs),
                    Text(
                      'Check-In Time: ${checkInTime.replaceAll('T', ' ').split('.').first}',
                      style: d.supporting,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: d.lg),
            AppButton(
              key: const ValueKey<String>('scan-next-button'),
              label: 'Scan Next QR Code',
              icon: Icons.qr_code_scanner,
              onPressed: onScanNext,
            ),
          ],
        ),
      ),
    );
  }
}

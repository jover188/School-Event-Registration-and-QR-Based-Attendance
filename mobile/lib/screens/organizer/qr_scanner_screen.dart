import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_spinner.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/event_model.dart';
import 'live_attendance_screen.dart';
import 'widgets/scan_result_content.dart';

class QrScannerScreen extends StatefulWidget {
  final EventModel event;
  final Map<String, dynamic>? initialScanResult;
  final String? initialScanError;
  final bool? cameraSupportedOverride;
  final bool initialIsProcessing;
  final String initialMode;

  const QrScannerScreen({
    super.key,
    required this.event,
    this.initialScanResult,
    this.initialScanError,
    this.cameraSupportedOverride,
    this.initialIsProcessing = false,
    this.initialMode = 'check_in',
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _scannerController;
  late String _mode;
  late bool _isProcessing;
  Map<String, dynamic>? _activeScanResult;
  String? _activeScanError;

  bool get _isEventScannable =>
      widget.event.status == 'published' || widget.event.status == 'ongoing';

  bool get _isCameraSupported =>
      widget.cameraSupportedOverride ??
      (defaultTargetPlatform != TargetPlatform.linux);

  bool get _shouldMountCamera =>
      _isEventScannable &&
      _isCameraSupported &&
      widget.initialScanResult == null &&
      widget.initialScanError == null &&
      !widget.initialIsProcessing;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _isProcessing = widget.initialIsProcessing;
    _activeScanResult = widget.initialScanResult;
    _activeScanError = widget.initialScanError;

    if (_shouldMountCamera) {
      _scannerController = MobileScannerController();
    }
  }

  @override
  void didUpdateWidget(covariant QrScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMode != oldWidget.initialMode) {
      _mode = widget.initialMode;
    }
    if (widget.initialIsProcessing != oldWidget.initialIsProcessing) {
      _isProcessing = widget.initialIsProcessing;
    }
    if (widget.initialScanResult != oldWidget.initialScanResult) {
      _activeScanResult = widget.initialScanResult;
    }
    if (widget.initialScanError != oldWidget.initialScanError) {
      _activeScanError = widget.initialScanError;
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveAttendanceScreen(
          eventId: widget.event.id,
          eventTitle: widget.event.title,
          canCorrect: true,
        ),
      ),
    );
  }

  void _selectMode(String nextMode) {
    if (_isProcessing || _mode == nextMode) return;
    setState(() => _mode = nextMode);
  }

  void _clearScanFeedback() {
    if (_isProcessing) return;
    setState(() {
      _activeScanResult = null;
      _activeScanError = null;
    });
    _scannerController?.start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing ||
        _activeScanResult != null ||
        _activeScanError != null) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.length != 64) {
      setState(() {
        _activeScanError =
            'Invalid QR code format. Expected a 64-character permanent student QR token.';
      });
      _scannerController?.stop();
      return;
    }

    setState(() {
      _isProcessing = true;
      _activeScanResult = null;
      _activeScanError = null;
    });
    _scannerController?.stop();

    final response = await ApiClient().post(
      ApiConstants.scanAttendance(widget.event.id),
      {
        'qr_token': rawValue,
        'mode': _mode,
      },
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      if (response.success && response.data is Map<String, dynamic>) {
        _activeScanResult = Map<String, dynamic>.from(
          response.data as Map<String, dynamic>,
        );
      } else {
        _activeScanError = response.message ?? 'Attendance scan failed.';
      }
    });
  }

  Widget _buildModeSelector(BuildContext context) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.xs),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackModes = constraints.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          final checkInOption = _ModeToggleOption(
            key: const ValueKey<String>('scanner-mode-check-in'),
            label: 'Check-In (Arrival)',
            selected: _mode == 'check_in',
            activeColor: d.success,
            activeBg: d.successBackground,
            disabled: _isProcessing,
            onTap: () => _selectMode('check_in'),
          );
          final checkOutOption = _ModeToggleOption(
            key: const ValueKey<String>('scanner-mode-check-out'),
            label: 'Check-Out (Departure)',
            selected: _mode == 'check_out',
            activeColor: d.information,
            activeBg: d.informationBackground,
            disabled: _isProcessing,
            onTap: () => _selectMode('check_out'),
          );

          if (stackModes) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                checkInOption,
                SizedBox(height: d.xs),
                checkOutOption,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: checkInOption),
              SizedBox(width: d.xs),
              Expanded(child: checkOutOption),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventHeaderBanner(BuildContext context) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: d.authDark.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: d.sm,
        runSpacing: d.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.event.title,
                style: d.cardTitle,
              ),
              SizedBox(height: d.xs),
              Text(
                '${widget.event.venue} • ${widget.event.eventDate}',
                style: d.supporting,
              ),
            ],
          ),
          StatusBadge(status: widget.event.status),
        ],
      ),
    );
  }

  Widget _buildNonActiveEventNotice(BuildContext context) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.lg),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(d.sm),
                decoration: BoxDecoration(
                  color: d.warningBackground,
                  borderRadius: BorderRadius.circular(d.radiusControl),
                ),
                child: Icon(
                  LucideIcons.lock,
                  color: d.warning,
                  size: 22,
                ),
              ),
              SizedBox(width: d.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scanning Not Active for This Event State',
                      style: d.cardTitle,
                    ),
                    SizedBox(height: d.xs),
                    StatusBadge(status: widget.event.status),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: d.md),
          Text(
            'QR attendance scanning is only available when an event is published or ongoing. This event is currently ${widget.event.status.replaceAll('_', ' ')}.',
            style: d.body,
          ),
          SizedBox(height: d.lg),
          AppButton(
            key: const ValueKey<String>('scanner-view-attendance-button'),
            label: 'View attendance',
            pill: true,
            icon: LucideIcons.clipboardCheck,
            onPressed: _openAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUnsupportedNotice(BuildContext context) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.lg),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(
          color: d.isDark ? d.border : d.authDark.withValues(alpha: 0.08),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(d.sm),
                decoration: BoxDecoration(
                  color: d.informationBackground,
                  borderRadius: BorderRadius.circular(d.radiusControl),
                ),
                child: Icon(
                  LucideIcons.videoOff,
                  color: d.information,
                  size: 22,
                ),
              ),
              SizedBox(width: d.gap),
              Expanded(
                child: Text(
                  'Camera Scanner Unavailable on This Platform',
                  style: d.cardTitle,
                ),
              ),
            ],
          ),
          SizedBox(height: d.md),
          Text(
            'Live camera QR scanning is supported on Android, iOS, macOS, and web devices with camera access. You can still inspect and manage attendance records directly.',
            style: d.body,
          ),
          SizedBox(height: d.lg),
          AppButton(
            key: const ValueKey<String>('scanner-view-attendance-button'),
            label: 'View attendance',
            pill: true,
            icon: LucideIcons.clipboardCheck,
            onPressed: _openAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinder(BuildContext context, {required double height}) {
    final d = context.design;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(d.radiusCard),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final target =
                (math.min(constraints.maxWidth, constraints.maxHeight) * 0.62)
                    .clamp(160.0, 280.0);
            final reticleSize = math.min(
              target,
              math.max(
                80.0,
                math.min(constraints.maxWidth, constraints.maxHeight) - 24.0,
              ),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                if (_scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onDetect,
                  )
                else
                  const ColoredBox(color: Colors.black87),
                Center(
                  child: Container(
                    key: const ValueKey<String>('scanner-reticle'),
                    width: reticleSize,
                    height: reticleSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.5),
                      borderRadius: BorderRadius.circular(d.radiusCard),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const AppSpinner(color: Colors.white),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final hasScanState = _isProcessing ||
        _activeScanResult != null ||
        (_activeScanError != null && _activeScanError!.isNotEmpty);

    final scanResultWidget = ScanResultContent(
      result: _activeScanResult,
      errorMessage: _activeScanError,
      mode: _mode,
      isProcessing: _isProcessing,
      onScanNext: _clearScanFeedback,
      onOpenAttendance: _openAttendance,
    );

    return AppPageScaffold(
      title: 'QR Scanner — ${widget.event.title}',
      actions: [
        if (_shouldMountCamera && _scannerController != null) ...[
          AppIconButton(
            tooltip: 'Toggle Flash',
            icon: LucideIcons.zap,
            onPressed: () => _scannerController?.toggleTorch(),
          ),
          AppIconButton(
            tooltip: 'Switch Camera',
            icon: LucideIcons.switchCamera,
            onPressed: () => _scannerController?.switchCamera(),
          ),
        ],
        AppIconButton(
          tooltip: 'Attendance Records',
          icon: LucideIcons.clipboardCheck,
          onPressed: _openAttendance,
        ),
      ],
      body: !_isEventScannable
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEventHeaderBanner(context),
                  SizedBox(height: d.md),
                  _buildNonActiveEventNotice(context),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 900;
                final primaryStage = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEventHeaderBanner(context),
                    SizedBox(height: d.gap),
                    _buildModeSelector(context),
                    SizedBox(height: d.gap),
                    if (_shouldMountCamera)
                      _buildCameraViewfinder(
                        context,
                        height: wideLayout ? 400 : 300,
                      )
                    else
                      _buildCameraUnsupportedNotice(context),
                  ],
                );

                if (wideLayout) {
                  return SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: primaryStage),
                        SizedBox(width: d.lg),
                        SizedBox(
                          width: 360,
                          child: scanResultWidget,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primaryStage,
                      if (hasScanState || _shouldMountCamera) ...[
                        SizedBox(height: d.md),
                        scanResultWidget,
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ModeToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color activeBg;
  final bool disabled;
  final VoidCallback onTap;

  const _ModeToggleOption({
    super.key,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.activeBg,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return AppPressable(
      semanticLabel: label,
      selected: selected,
      onPressed: disabled ? null : onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: d.minimumTarget),
        padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(d.radiusControl),
          border: Border.all(
            color: selected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? LucideIcons.circleDot
                  : LucideIcons.circle,
              size: 16,
              color: selected ? activeColor : d.mutedForeground,
            ),
            SizedBox(width: d.sm),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: d.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : d.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

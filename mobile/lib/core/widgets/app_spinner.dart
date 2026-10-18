import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

/// Preset sizes for [AppSpinner] adhering to the shadcn design scale.
enum AppSpinnerSize {
  /// 16px — Designed for buttons, badges, and inline elements.
  sm(16.0),

  /// 24px — Standard size for cards, list items, and modal dialogs.
  md(24.0),

  /// 36px — Section headers and content panel loading.
  lg(36.0),

  /// 48px — Prominent and full-page loading indicators.
  xl(48.0);

  const AppSpinnerSize(this.dimension);
  final double dimension;
}

/// Visual style variant for [AppSpinner].
enum AppSpinnerVariant {
  /// The canonical shadcn spinning loader icon (`LucideIcons.loader2`).
  loader2,

  /// Clean circular track + rotating arc indicator.
  ring,
}

/// A shadcn-styled loading spinner with smooth continuous rotation,
/// accessibility semantics, and automatic light/dark design token adaptation.
class AppSpinner extends StatefulWidget {
  const AppSpinner({
    super.key,
    this.size,
    this.spinnerSize = AppSpinnerSize.md,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticsLabel = 'Loading',
    this.variant = AppSpinnerVariant.loader2,
    this.duration = const Duration(milliseconds: 900),
  });

  /// Small 16px spinner, ideal for buttons and inline actions.
  const AppSpinner.sm({
    super.key,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticsLabel = 'Loading',
    this.variant = AppSpinnerVariant.loader2,
    this.duration = const Duration(milliseconds: 900),
  })  : size = 16.0,
        spinnerSize = AppSpinnerSize.sm;

  /// Medium 24px spinner (default).
  const AppSpinner.md({
    super.key,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticsLabel = 'Loading',
    this.variant = AppSpinnerVariant.loader2,
    this.duration = const Duration(milliseconds: 900),
  })  : size = 24.0,
        spinnerSize = AppSpinnerSize.md;

  /// Large 36px spinner, ideal for section or page loading.
  const AppSpinner.lg({
    super.key,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticsLabel = 'Loading',
    this.variant = AppSpinnerVariant.loader2,
    this.duration = const Duration(milliseconds: 900),
  })  : size = 36.0,
        spinnerSize = AppSpinnerSize.lg;

  /// Extra large 48px spinner.
  const AppSpinner.xl({
    super.key,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.semanticsLabel = 'Loading',
    this.variant = AppSpinnerVariant.loader2,
    this.duration = const Duration(milliseconds: 900),
  })  : size = 48.0,
        spinnerSize = AppSpinnerSize.xl;

  /// Explicit size in logical pixels (overrides [spinnerSize] if provided).
  final double? size;

  /// Preset size tier.
  final AppSpinnerSize spinnerSize;

  /// Main spinner color. Defaults to `context.design.foreground` or icon theme.
  final Color? color;

  /// Background track color for the [AppSpinnerVariant.ring] variant.
  final Color? trackColor;

  /// Stroke width for the [AppSpinnerVariant.ring] variant.
  final double? strokeWidth;

  /// Accessibility label for screen readers.
  final String? semanticsLabel;

  /// Visual representation variant.
  final AppSpinnerVariant variant;

  /// Animation rotation period duration.
  final Duration duration;

  /// Centered container/page-level loading indicator with optional status message.
  static Widget page({
    Key? key,
    String? label,
    TextStyle? labelStyle,
    Color? color,
    double? size,
    AppSpinnerSize spinnerSize = AppSpinnerSize.lg,
    AppSpinnerVariant variant = AppSpinnerVariant.loader2,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24.0),
  }) {
    return Builder(
      key: key,
      builder: (context) {
        final d = context.design;
        return Center(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSpinner(
                  size: size,
                  spinnerSize: spinnerSize,
                  color: color,
                  variant: variant,
                ),
                if (label != null) ...[
                  SizedBox(height: d.md),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: (labelStyle ?? d.body).copyWith(
                      color: d.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AppSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 0.0;
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final effectiveDimension = widget.size ?? widget.spinnerSize.dimension;
    final effectiveColor =
        widget.color ?? IconTheme.of(context).color ?? d.foreground;

    Widget spinnerWidget;
    switch (widget.variant) {
      case AppSpinnerVariant.loader2:
        spinnerWidget = RotationTransition(
          turns: _controller,
          child: Icon(
            LucideIcons.loader2,
            size: effectiveDimension,
            color: effectiveColor,
          ),
        );
      case AppSpinnerVariant.ring:
        final effectiveTrackColor = widget.trackColor ??
            effectiveColor.withValues(alpha: 0.18);
        final effectiveStroke = widget.strokeWidth ??
            (effectiveDimension <= 18 ? 2.0 : 2.5);

        spinnerWidget = RotationTransition(
          turns: _controller,
          child: CustomPaint(
            size: Size(effectiveDimension, effectiveDimension),
            painter: _RingSpinnerPainter(
              color: effectiveColor,
              trackColor: effectiveTrackColor,
              strokeWidth: effectiveStroke,
            ),
          ),
        );
    }

    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: SizedBox(
        width: effectiveDimension,
        height: effectiveDimension,
        child: Center(child: spinnerWidget),
      ),
    );
  }
}

class _RingSpinnerPainter extends CustomPainter {
  const _RingSpinnerPainter({
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, (size.width - strokeWidth) / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw full background track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw 90-degree rotating head arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 0.75,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingSpinnerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

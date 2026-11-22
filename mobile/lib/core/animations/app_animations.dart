import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Lightweight widget that performs a smooth opacity fade-in and subtle
/// vertical translation (e.g. 12px slide-up) with customizable delay.
/// Respects [MediaQuery.disableAnimationsOf(context)].
class EntranceFader extends StatefulWidget {
  const EntranceFader({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.offset = const Offset(0.0, 12.0),
    this.curve = Curves.easeOutCubic,
  });

  /// The child widget to be animated.
  final Widget child;

  /// Optional delay before starting the fade-in / slide animation.
  final Duration delay;

  /// Duration of the entrance transition.
  final Duration duration;

  /// Initial vertical and horizontal translation offset.
  final Offset offset;

  /// Easing curve for the entrance.
  final Curve curve;

  @override
  State<EntranceFader> createState() => _EntranceFaderState();
}

class _EntranceFaderState extends State<EntranceFader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;
  Timer? _delayTimer;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _offsetAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller.value = 1.0;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) => Transform.translate(
          offset: _offsetAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// An animated circular badge that displays a smooth scale-in and drawing/reveal
/// of a checkmark icon on success, using a 400ms spring/easeOutBack curve.
class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({
    super.key,
    this.size = 48.0,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 3.0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutBack,
    this.onCompleted,
  });

  /// Diameter of the circular badge.
  final double size;

  /// Stroke color for the checkmark path. Defaults to card/white.
  final Color? color;

  /// Background circle fill color. Defaults to [AppDesignTokens.success].
  final Color? backgroundColor;

  /// Stroke width for drawing the checkmark.
  final double strokeWidth;

  /// Total duration of the scale-in and checkmark drawing.
  final Duration duration;

  /// Easing curve for the scale-in.
  final Curve curve;

  /// Optional callback invoked when the checkmark animation completes.
  final VoidCallback? onCompleted;

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _checkAnimation;
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.7, curve: widget.curve),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completedFired) {
        _completedFired = true;
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller.value = 1.0;
      if (!_completedFired) {
        _completedFired = true;
        widget.onCompleted?.call();
      }
    } else if (!_controller.isAnimating && _controller.value == 0.0) {
      _controller.forward();
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
    final effectiveBg = widget.backgroundColor ?? d.success;
    final effectiveColor = widget.color ?? (d.isDark ? d.foreground : Colors.white);
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            progress: 1.0,
            scale: 1.0,
            color: effectiveColor,
            backgroundColor: effectiveBg,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckmarkPainter(
              progress: _checkAnimation.value,
              scale: _scaleAnimation.value,
              color: effectiveColor,
              backgroundColor: effectiveBg,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({
    required this.progress,
    required this.scale,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final double scale;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (scale <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale.clamp(0.0, 1.0);

    // Draw circular background badge
    if (backgroundColor != Colors.transparent && radius > 0.0) {
      final bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);
    }

    if (progress <= 0.001) return;

    // Checkmark geometry relative to size
    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.72, size.height * 0.36);

    final len1 = (p2 - p1).distance;
    final len2 = (p3 - p2).distance;
    final totalLen = len1 + len2;
    final currentLen = progress.clamp(0.0, 1.0) * totalLen;

    final checkPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (currentLen <= len1) {
      final t = len1 > 0 ? (currentLen / len1) : 0.0;
      final currentPoint = Offset.lerp(p1, p2, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final remaining = currentLen - len1;
      final t = len2 > 0 ? (remaining / len2) : 0.0;
      final currentPoint = Offset.lerp(p2, p3, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A customizable laser/scan-line painter and widget that animates smoothly
/// up and down across a defined reticle height with a subtle glow gradient
/// in monochrome or theme accent.
class AnimatedScannerLine extends StatefulWidget {
  const AnimatedScannerLine({
    super.key,
    this.height = 240.0,
    this.width = 240.0,
    this.color,
    this.duration = const Duration(milliseconds: 2000),
    this.lineWidth = 2.0,
    this.glowHeight = 24.0,
  });

  /// Height of the scanning reticle area.
  final double height;

  /// Width of the scanning reticle area.
  final double width;

  /// Line and glow color. Defaults to [AppDesignTokens.brandCyan] or [AppDesignTokens.primary].
  final Color? color;

  /// Duration for one complete sweep (up or down).
  final Duration duration;

  /// Thickness of the crisp laser line.
  final double lineWidth;

  /// Height of the vertical glow tail gradient.
  final double glowHeight;

  @override
  State<AnimatedScannerLine> createState() => _AnimatedScannerLineState();
}

class _AnimatedScannerLineState extends State<AnimatedScannerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller.value = 0.5;
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
    final effectiveColor = widget.color ?? d.brandCyan;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ScannerLinePainter(
            progress: 0.5,
            color: effectiveColor,
            lineWidth: widget.lineWidth,
            glowHeight: widget.glowHeight,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ScannerLinePainter(
              progress: _animation.value,
              color: effectiveColor,
              lineWidth: widget.lineWidth,
              glowHeight: widget.glowHeight,
            ),
          ),
        );
      },
    );
  }
}

class _ScannerLinePainter extends CustomPainter {
  const _ScannerLinePainter({
    required this.progress,
    required this.color,
    required this.lineWidth,
    required this.glowHeight,
  });

  final double progress;
  final Color color;
  final double lineWidth;
  final double glowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress.clamp(0.0, 1.0) * size.height;

    // Save layer to clip strictly within reticle bounds
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Draw vertical glow gradient
    final glowTop = math.max(0.0, y - glowHeight);
    final glowBottom = math.min(size.height, y + glowHeight);
    final glowRect = Rect.fromLTRB(0, glowTop, size.width, glowBottom);

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(glowRect);

    canvas.drawRect(glowRect, glowPaint);

    // Draw crisp horizontal laser line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScannerLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.glowHeight != glowHeight;
  }
}

/// A [PageRouteBuilder] with subtle fade and slight slide-up transition (200-250ms).
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget Function(BuildContext) builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 220),
    super.reverseTransitionDuration = const Duration(milliseconds: 180),
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState = true,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final disableAnimations =
                MediaQuery.maybeDisableAnimationsOf(context) ?? false;
            if (disableAnimations) {
              return child;
            }

            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04), // subtle 4% slide-up
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

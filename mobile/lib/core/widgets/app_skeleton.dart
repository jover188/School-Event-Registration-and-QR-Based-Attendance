import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Scope provider that coordinates a shared shimmer sweep across nested skeletons.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  /// Retrieves the nearest ancestor shimmer animation controller, if present.
  static Animation<double>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AppShimmerScope>()
        ?.animation;
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
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
  void didUpdateWidget(covariant AppShimmer oldWidget) {
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
    return _AppShimmerScope(
      animation: _controller,
      child: widget.child,
    );
  }
}

class _AppShimmerScope extends InheritedWidget {
  final Animation<double> animation;

  const _AppShimmerScope({
    required this.animation,
    required super.child,
  });

  @override
  bool updateShouldNotify(_AppShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// Lightweight, self-contained pulse / gradient sweep skeleton placeholder.
///
/// Automatically adapts to light and dark theme design tokens without requiring
/// heavy external dependencies. Can synchronize with an ancestor [AppShimmer]
/// or drive its own standalone animation loop.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? baseColor;
  final Color? highlightColor;
  final Widget? child;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.padding,
    this.baseColor,
    this.highlightColor,
    this.child,
  });

  /// Circular skeleton helper (for avatars, icons, badges).
  const AppSkeleton.circle({
    super.key,
    required double size,
    this.margin,
    this.padding,
    this.baseColor,
    this.highlightColor,
    this.child,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  /// Text line skeleton helper.
  const AppSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius,
    this.margin,
    this.baseColor,
    this.highlightColor,
  })  : shape = BoxShape.rectangle,
        padding = null,
        child = null;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentAnimation = AppShimmer.of(context);
    if (parentAnimation == null) {
      _localController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      );
      _syncLocalAnimation();
    } else {
      _localController?.dispose();
      _localController = null;
    }
  }

  void _syncLocalAnimation() {
    final controller = _localController;
    if (controller == null) return;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      if (controller.isAnimating) {
        controller.stop();
        controller.value = 0.0;
      }
    } else {
      if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final parentAnimation = AppShimmer.of(context);
    final activeAnimation = parentAnimation ?? _localController;

    final isDark = d.isDark;
    final base = widget.baseColor ??
        (isDark ? AppPalette.darkMuted : d.muted);
    final highlight = widget.highlightColor ??
        (isDark
            ? AppPalette.darkCard.withValues(alpha: 0.9)
            : d.border.withValues(alpha: 0.7));

    final effectiveRadius = widget.shape == BoxShape.circle
        ? null
        : (widget.borderRadius ?? BorderRadius.circular(d.radiusControl));

    Widget buildContainer(double animProgress) {
      final beginX = -2.0 + (4.0 * animProgress);
      final endX = beginX + 1.4;

      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: effectiveRadius,
          gradient: LinearGradient(
            begin: Alignment(beginX, -0.2),
            end: Alignment(endX, 0.2),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: widget.child,
      );
    }

    final skeletonBox = activeAnimation == null
        ? buildContainer(0.0)
        : AnimatedBuilder(
            animation: activeAnimation,
            builder: (context, _) => buildContainer(activeAnimation.value),
          );

    return Semantics(
      label: 'Loading...',
      child: skeletonBox,
    );
  }
}

/// Skeleton loading placeholder matching [StatMetricCard] dimensions.
class AppSkeletonMetricCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const AppSkeletonMetricCard({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return Container(
      margin: margin,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSkeleton(
                width: 18,
                height: 18,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(width: d.sm),
              AppSkeleton(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          SizedBox(height: d.sm),
          AppSkeleton(
            width: 64,
            height: 24,
            borderRadius: BorderRadius.circular(6),
          ),
          SizedBox(height: d.xs),
          AppSkeleton(
            width: 110,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching [EventCard] layout
/// (date tile, title, badge, venue, time, capacity meter).
class AppSkeletonEventCard extends StatelessWidget {
  final bool showCapacity;
  final EdgeInsetsGeometry? margin;

  const AppSkeletonEventCard({
    super.key,
    this.showCapacity = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return Container(
      margin: margin,
      padding: EdgeInsets.all(d.lg),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date tile placeholder (48x48)
              Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                padding: EdgeInsets.symmetric(
                  horizontal: d.sm,
                  vertical: d.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: d.authSurface,
                  borderRadius: BorderRadius.circular(d.radiusControl),
                  border: Border.all(color: d.border, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSkeleton(
                      width: 24,
                      height: 10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 4),
                    AppSkeleton(
                      width: 20,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              SizedBox(width: d.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSkeleton(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    AppSkeleton(
                      width: 140,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: d.xs + 2),
                    Row(
                      children: [
                        AppSkeleton(
                          width: 58,
                          height: 18,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        SizedBox(width: d.xs),
                        AppSkeleton(
                          width: 76,
                          height: 18,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: d.gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSkeleton(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(width: d.sm),
              AppSkeleton(
                width: 160,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          SizedBox(height: d.gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppSkeleton(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(width: d.sm),
              AppSkeleton(
                width: 120,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          if (showCapacity) ...[
            SizedBox(height: d.md),
            AppSkeleton(
              width: double.infinity,
              height: 6,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            SizedBox(height: d.xs + 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeleton(
                  width: 72,
                  height: 11,
                  borderRadius: BorderRadius.circular(3),
                ),
                AppSkeleton(
                  width: 32,
                  height: 11,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders multiple skeleton rows or cards with a synchronized shimmer pulse.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const AppSkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemBuilder,
    this.padding,
    this.spacing = 12.0,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Named constructor specifically for rendering a list of [AppSkeletonEventCard]s.
  const AppSkeletonList.events({
    super.key,
    this.itemCount = 3,
    this.padding,
    this.spacing = 12.0,
    this.shrinkWrap = false,
    this.physics,
  }) : itemBuilder = _eventCardBuilder;

  /// Named constructor specifically for rendering a list of [AppSkeletonMetricCard]s.
  const AppSkeletonList.metrics({
    super.key,
    this.itemCount = 3,
    this.padding,
    this.spacing = 12.0,
    this.shrinkWrap = false,
    this.physics,
  }) : itemBuilder = _metricCardBuilder;

  static Widget _eventCardBuilder(BuildContext context, int index) {
    return const AppSkeletonEventCard();
  }

  static Widget _metricCardBuilder(BuildContext context, int index) {
    return const AppSkeletonMetricCard();
  }

  static Widget _defaultRowBuilder(BuildContext context, int index) {
    final d = context.design;
    return Container(
      padding: EdgeInsets.all(d.md),
      decoration: BoxDecoration(
        color: d.card,
        borderRadius: BorderRadius.circular(d.radiusCard),
        border: Border.all(color: d.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(width: d.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                AppSkeleton(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          SizedBox(width: d.sm),
          AppSkeleton(
            width: 48,
            height: 20,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final builder = itemBuilder ?? _defaultRowBuilder;

    return AppShimmer(
      child: ListView.separated(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: spacing),
        itemBuilder: builder,
      ),
    );
  }
}

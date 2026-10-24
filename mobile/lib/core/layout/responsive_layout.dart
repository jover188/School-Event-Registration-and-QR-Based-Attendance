import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppWindowClass { compact, medium, expanded }

AppWindowClass windowClassFor(double width) => width < 600
    ? AppWindowClass.compact
    : width < 1024
        ? AppWindowClass.medium
        : AppWindowClass.expanded;

double pagePadding(BuildContext context) => switch (
    windowClassFor(MediaQuery.sizeOf(context).width)) {
  AppWindowClass.compact => AppSpacing.md,
  AppWindowClass.medium => AppSpacing.lg,
  AppWindowClass.expanded => AppSpacing.xl,
};

class AppResponsivePage extends StatelessWidget {
  const AppResponsivePage({super.key, required this.child, this.maxWidth = 1200});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth + pagePadding(context) * 2),
      child: Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: child,
      ),
    ),
  );
}

int _columns(BuildContext context, double width, double minimum, int maximum,
    double gap) {
  if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) return 1;
  return ((width + gap) / (minimum + gap)).floor().clamp(1, maximum);
}

/// Content-height rows for small, finite groups such as metrics and form fields.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 150,
    this.maxColumns = 4,
    this.spacing = 12,
  });
  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final columns = _columns(context, box.maxWidth, minItemWidth, maxColumns, spacing);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var offset = 0; offset < children.length; offset += columns)
          Padding(
            padding: EdgeInsets.only(bottom: offset + columns < children.length ? spacing : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) SizedBox(width: spacing),
                  Expanded(
                    child: offset + column < children.length
                        ? children[offset + column]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  });
}

/// Lazy rows without a fixed aspect ratio, so text scaling can grow each card.
class ResponsiveCardSliver extends StatelessWidget {
  const ResponsiveCardSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 300,
    this.maxColumns = 3,
    this.equalRowHeight = false,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final bool equalRowHeight;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      const gap = AppSpacing.md;
      final columns = _columns(context, constraints.crossAxisExtent,
          minItemWidth, maxColumns, gap);
      return SliverList.builder(
        itemCount: (itemCount / columns).ceil(),
        itemBuilder: (context, row) {
          final rowWidget = Row(
            crossAxisAlignment: equalRowHeight
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) const SizedBox(width: gap),
                Expanded(
                  child: row * columns + column < itemCount
                      ? itemBuilder(context, row * columns + column)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: gap),
            child: equalRowHeight ? IntrinsicHeight(child: rowWidget) : rowWidget,
          );
        },
      );
    },
  );
}

/// Caps a QR including its quiet zone without ever overflowing its parent.
class ResponsiveQrFrame extends StatelessWidget {
  const ResponsiveQrFrame({super.key, required this.builder});
  final Widget Function(double size) builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => Center(child: builder(math.min(280, box.maxWidth))),
  );
}

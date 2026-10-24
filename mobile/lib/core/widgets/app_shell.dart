import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../layout/responsive_layout.dart';
import '../navigation/app_destination.dart';
import '../theme/app_theme.dart';
import 'app_pressable.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedId,
    required this.onDestinationSelected,
    required this.body,
    this.actions = const [],
    this.onLogout,
    this.showCompactMore = true,
  });
  final String title;
  final List<AppDestination> destinations;
  final String selectedId;
  final ValueChanged<String> onDestinationSelected;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onLogout;
  final bool showCompactMore;

  static const AppDestination _logoutDestination = AppDestination(
    id: 'logout',
    label: 'Logout',
    icon: LucideIcons.logOut,
    compactPrimary: false,
  );

  Widget _buildBrandBadge(
    AppDesignTokens d, {
    double height = 48,
    Key? key,
  }) {
    return Image.asset(
      'assets/images/logo_mark.png',
      key: key,
      height: height,
      fit: BoxFit.contain,
      color: d.isDark ? d.sidebarForeground : null,
      colorBlendMode: d.isDark ? BlendMode.srcIn : null,
    );
  }

  void _showSlideOverDrawer(
    BuildContext context,
    List<AppDestination> items, {
    String keyPrefix = 'destination',
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss navigation drawer',
      barrierColor: const Color(0x6609090B),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final d = dialogContext.design;
        return SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: d.sidebar,
                  border: Border(right: BorderSide(color: d.sidebarBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: d.md,
                        vertical: d.md,
                      ),
                      child: Row(
                        children: [
                          _buildBrandBadge(d, height: 48),
                          SizedBox(width: d.gap),
                          Expanded(
                            child: Text(
                              'Attendify',
                              style: d.cardTitle.copyWith(
                                color: d.sidebarForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close navigation drawer',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: d.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: d.sidebarBorder),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(d.sm),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildCategorizedDestinations(
                            dialogContext,
                            items,
                            horizontal: true,
                            keyPrefix: keyPrefix,
                            onItemTap: (item) {
                              Navigator.of(dialogContext).pop();
                              onDestinationSelected(item.id);
                            },
                          ),
                        ),
                      ),
                    ),
                    if (onLogout != null) ...[
                      Divider(height: 1, color: d.sidebarBorder),
                      Padding(
                        padding: EdgeInsets.all(d.sm),
                        child: _destination(
                          dialogContext,
                          _logoutDestination,
                          horizontal: true,
                          keyPrefix: keyPrefix,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            onLogout!();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * curved.value,
            sigmaY: 4 * curved.value,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  List<Widget> _buildCategorizedDestinations(
    BuildContext context,
    List<AppDestination> items, {
    required bool horizontal,
    String keyPrefix = 'destination',
    void Function(AppDestination item)? onItemTap,
  }) {
    final d = context.design;
    final widgets = <Widget>[];
    String? lastCategory;

    for (final item in items) {
      final category = item.category?.trim();
      if (category != null && category.isNotEmpty && category != lastCategory) {
        final isFirst = lastCategory == null;
        if (horizontal) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(
                left: d.gap,
                right: d.gap,
                top: isFirst ? d.xs : d.md,
                bottom: d.xs,
              ),
              child: Text(
                category.toUpperCase(),
                key: ValueKey(
                  '$keyPrefix-category-${category.toLowerCase().replaceAll(' ', '-')}',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: d.badge.copyWith(
                  color: d.mutedForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        } else if (!isFirst) {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: d.sm,
                vertical: d.xs,
              ),
              child: Divider(height: 1, color: d.sidebarBorder),
            ),
          );
        }
        lastCategory = category;
      }

      widgets.add(
        _destination(
          context,
          item,
          horizontal: horizontal,
          keyPrefix: keyPrefix,
          onTap: onItemTap != null ? () => onItemTap(item) : null,
        ),
      );
    }

    return widgets;
  }

  Widget _destination(
    BuildContext context,
    AppDestination item, {
    bool horizontal = false,
    String keyPrefix = 'destination',
    VoidCallback? onTap,
  }) {
    final d = context.design;
    final selected = item.id == selectedId;
    return Padding(
      padding: EdgeInsets.all(d.xs),
      child: AppPressable(
        key: ValueKey('$keyPrefix-${item.id}'),
        selected: selected,
        semanticLabel: item.label,
        onPressed: onTap ?? () => onDestinationSelected(item.id),
        child: Container(
          key: ValueKey('$keyPrefix-${item.id}-surface'),
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? d.gap : d.sm,
            vertical: d.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? (horizontal
                    ? d.sidebarPrimary
                    : d.primary.withValues(alpha: d.isDark ? 0.14 : 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(d.radiusControl),
            border: selected && !horizontal
                ? Border.all(
                    color: d.primary.withValues(alpha: d.isDark ? 0.24 : 0.12),
                  )
                : null,
          ),
          child: horizontal
              ? Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      weight: 300,
                      color: selected
                          ? d.sidebarPrimaryForeground
                          : d.primary,
                    ),
                    SizedBox(width: d.gap),
                    Expanded(
                      child: Text(
                        item.label,
                        style: d.body.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? d.sidebarPrimaryForeground
                              : d.sidebarForeground,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: d.sidebarPrimaryForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      weight: 300,
                      color: d.primary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.35),
                      textAlign: TextAlign.center,
                      style: d.badge.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? d.primary
                            : d.mutedForeground,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = windowClassFor(width);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final side = sizeClass != AppWindowClass.compact &&
        !(sizeClass == AppWindowClass.medium && largeText);
    final expanded = sizeClass == AppWindowClass.expanded;
    var primary = destinations.where((item) => item.compactPrimary).toList();
    if (largeText) {
      final essential = primary.where((item) => item.essential).toList();
      primary = essential.isEmpty
          ? primary.take(2).toList()
          : essential.take(2).toList();
    }
    final more = destinations.where((item) => !primary.contains(item)).toList();

    return Scaffold(
      backgroundColor: d.background,
      body: SafeArea(
        child: Row(
          children: [
            // Keep the body at the same element position across every breakpoint.
            SizedBox(
              width: side ? (expanded ? d.sidebarWidth : d.railWidth) : 0,
              child: side
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: d.sidebar,
                        border: Border(right: BorderSide(color: d.sidebarBorder)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            padding: EdgeInsets.symmetric(
                              vertical: d.md,
                              horizontal: expanded ? d.md : d.sm,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: d.sidebarBorder),
                              ),
                            ),
                            child: expanded
                                ? Row(
                                    children: [
                                      _buildBrandBadge(
                                        d,
                                        height: 48,
                                        key: const ValueKey(
                                          'sidebar-brand-logo',
                                        ),
                                      ),
                                      SizedBox(width: d.gap),
                                      Expanded(
                                        child: Text(
                                          'Attendify',
                                          style: d.cardTitle.copyWith(
                                            color: d.sidebarForeground,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: _buildBrandBadge(
                                      d,
                                      height: 48,
                                      key: const ValueKey('sidebar-brand-logo'),
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.symmetric(
                                horizontal: d.sm,
                                vertical: d.sm,
                              ),
                              children: _buildCategorizedDestinations(
                                context,
                                destinations,
                                horizontal: expanded,
                              ),
                            ),
                          ),
                          if (onLogout != null) ...[
                            Divider(height: 1, color: d.sidebarBorder),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: d.sm,
                                vertical: d.sm,
                              ),
                              child: _destination(
                                context,
                                _logoutDestination,
                                horizontal: expanded,
                                onTap: onLogout,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        decoration: BoxDecoration(
                          color: d.card.withValues(alpha: 0.92),
                          border: Border(bottom: BorderSide(color: d.border)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: d.md,
                          vertical: d.sm,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: d.sm,
                          runSpacing: d.xs,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (!side) ...[
                                  IconButton(
                                    key: const ValueKey('mobile-drawer-trigger'),
                                    tooltip: 'Open navigation drawer',
                                    onPressed: () => _showSlideOverDrawer(
                                      context,
                                      destinations,
                                      keyPrefix: 'drawer-destination',
                                    ),
                                    icon: Image.asset(
                                      'assets/images/logo_mark.png',
                                      key: const ValueKey('mobile-drawer-logo'),
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      color: d.isDark ? d.foreground : null,
                                      colorBlendMode:
                                          d.isDark ? BlendMode.srcIn : null,
                                    ),
                                  ),
                                  SizedBox(width: d.xs),
                                ],
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: (sizeClass == AppWindowClass.compact
                                            ? d.compactPageTitle
                                            : d.pageTitle)
                                        .copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: d.foreground,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (actions.isNotEmpty)
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: actions,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: side
          ? null
          : SafeArea(
              top: false,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56), // h-14
                decoration: BoxDecoration(
                  color: d.card,
                  border: Border(top: BorderSide(color: d.border)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (final item in primary)
                      Expanded(child: _destination(context, item)),
                    if (showCompactMore && more.isNotEmpty)
                      Expanded(
                        child: _destination(
                          context,
                          AppDestination(
                            id: more.any((item) => item.id == selectedId)
                                ? selectedId
                                : 'more',
                            label: 'More',
                            icon: LucideIcons.menu,
                          ),
                          onTap: () => _showSlideOverDrawer(context, more),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Lazily mounts visited destinations while preserving their local state.
class AppDestinationStack extends StatefulWidget {
  const AppDestinationStack({
    super.key,
    required this.selectedId,
    required this.builders,
  });
  final String selectedId;
  final Map<String, WidgetBuilder> builders;
  @override
  State<AppDestinationStack> createState() => _AppDestinationStackState();
}

class _AppDestinationStackState extends State<AppDestinationStack> {
  final Set<String> _visited = {};
  @override
  Widget build(BuildContext context) {
    _visited.add(widget.selectedId);
    final ids = widget.builders.keys.toList();
    return IndexedStack(
      index: ids.indexOf(widget.selectedId),
      children: [
        for (final id in ids)
          TickerMode(
            key: ValueKey(id),
            enabled: id == widget.selectedId,
            child: _visited.contains(id)
                ? widget.builders[id]!(context)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

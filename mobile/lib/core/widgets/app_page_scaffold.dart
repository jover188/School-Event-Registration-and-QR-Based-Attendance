import 'package:flutter/material.dart';
import '../layout/responsive_layout.dart';
import '../theme/app_theme.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.embedded = false,
    this.maxWidth = 1280,
    this.bottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool embedded;
  final double maxWidth;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final content = AppResponsivePage(maxWidth: maxWidth, child: body);
    if (embedded) {
      return ColoredBox(
        color: d.background,
        child: Column(
          children: [
            if (actions.isNotEmpty || floatingActionButton != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
                decoration: BoxDecoration(
                  color: d.card,
                  border: Border(bottom: BorderSide(color: d.border)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: d.sm,
                  runSpacing: d.sm,
                  children: [
                    ...actions,
                    if (floatingActionButton != null) floatingActionButton!,
                  ],
                ),
              ),
            if (bottom != null) bottom!,
            Expanded(child: content),
            if (bottomNavigationBar != null) bottomNavigationBar!,
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: d.background,
      appBar: AppBar(
        backgroundColor: d.card,
        foregroundColor: d.foreground,
        title: Text(title, style: d.cardTitle),
        bottom: bottom ??
            PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: d.border),
            ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: d.md, vertical: d.sm),
                decoration: BoxDecoration(
                  color: d.card,
                  border: Border(bottom: BorderSide(color: d.border)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: d.sm,
                    runSpacing: d.sm,
                    children: actions,
                  ),
                ),
              ),
            Expanded(child: content),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

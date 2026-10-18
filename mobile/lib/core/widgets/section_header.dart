import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable section header with title, optional subtitle, and optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final hasTrailing =
        trailing != null || (actionLabel != null && onAction != null);
    final trailingWidget = trailing ??
        (actionLabel != null && onAction != null
            ? AppButton(
                variant: AppButtonVariant.ghost,
                onPressed: onAction,
                label: actionLabel!,
              )
            : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 360 && hasTrailing;
        final headerText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: d.sectionTitle),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: d.supporting),
            ],
          ],
        );

        if (stackVertically && trailingWidget != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              headerText,
              SizedBox(height: d.sm),
              trailingWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: headerText),
            if (trailingWidget != null) ...[
              SizedBox(width: d.sm),
              trailingWidget,
            ],
          ],
        );
      },
    );
  }
}


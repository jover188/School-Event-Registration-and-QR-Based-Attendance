import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_page_scaffold.dart';

/// Standalone 404 screen for handling missing routes or unmapped destinations.
class NotFoundScreen extends StatelessWidget {
  final VoidCallback? onReturnHome;
  final String? customMessage;

  const NotFoundScreen({
    super.key,
    this.onReturnHome,
    this.customMessage,
  });

  void _handleReturnHome(BuildContext context) {
    if (onReturnHome != null) {
      onReturnHome!();
      return;
    }

    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    return AppPageScaffold(
      title: 'Page Not Found',
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(d.lg),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) {
              return Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - progress)),
                  child: child,
                ),
              );
            },
            child: Semantics(
              liveRegion: true,
              label:
                  'Page Not Found. Error 404. The requested screen does not exist or has been moved.',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon badge container
                  Container(
                    padding: EdgeInsets.all(d.md),
                    decoration: BoxDecoration(
                      color: d.selection,
                      borderRadius: BorderRadius.circular(d.radiusCard),
                      border: Border.all(color: d.border, width: 1),
                    ),
                    child: Icon(
                      LucideIcons.fileQuestion,
                      size: 32,
                      weight: 300,
                      color: d.foreground,
                    ),
                  ),
                  SizedBox(height: d.lg),
                  // Large modern display typography
                  Text(
                    '404',
                    style: TextStyle(
                      fontFamily: AppPalette.fontFamily,
                      fontSize: 84,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -3.0,
                      color: d.foreground,
                    ),
                  ),
                  SizedBox(height: d.sm),
                  Text(
                    'Page Not Found',
                    style: d.sectionTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: d.xs + 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Text(
                      customMessage ??
                          'The requested screen does not exist or has been moved.',
                      style: d.supporting.copyWith(
                        color: d.mutedForeground,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: d.xl),
                  AppButton(
                    onPressed: () => _handleReturnHome(context),
                    icon: LucideIcons.arrowLeft,
                    label: 'Return to Home',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

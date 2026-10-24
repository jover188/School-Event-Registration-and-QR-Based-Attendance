import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_theme.dart';

enum AppToastType { success, error, warning, info }

/// Top-center floating toast notification service and component.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;
  static _AppToastWidgetState? _currentState;

  /// Display a top-center floating toast notification.
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    dismiss(immediate: true);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
        ),
      );
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppToastWidget(
        message: message,
        type: type,
        onDismiss: () => dismiss(immediate: false),
        onStateCreated: (state) => _currentState = state,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _currentTimer = Timer(duration, () {
      dismiss(immediate: false);
    });
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      duration: duration,
    );
  }

  /// Dismiss the currently visible toast notification.
  static void dismiss({bool immediate = false}) {
    _currentTimer?.cancel();
    _currentTimer = null;

    final entry = _currentEntry;
    final state = _currentState;

    if (entry == null) return;

    if (immediate || state == null || !state.mounted) {
      _currentEntry = null;
      _currentState = null;
      try {
        entry.remove();
      } catch (_) {}
    } else {
      _currentEntry = null;
      _currentState = null;
      state.animateOut().then((_) {
        try {
          entry.remove();
        } catch (_) {}
      });
    }
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;
  final void Function(_AppToastWidgetState state) onStateCreated;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.onStateCreated,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
  }

  Future<void> animateOut() async {
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    AppToast._currentTimer?.cancel();
    AppToast._currentTimer = null;
    AppToast._currentEntry = null;
    AppToast._currentState = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    final (icon, iconColor, borderColor, bgColor) = switch (widget.type) {
      AppToastType.success => (
        LucideIcons.circleCheck,
        d.success,
        d.success.withValues(alpha: 0.36),
        d.isDark ? const Color(0xFF0C241B) : const Color(0xFFF0FDF4),
      ),
      AppToastType.error => (
        LucideIcons.circleX,
        d.destructive,
        d.destructive.withValues(alpha: 0.36),
        d.isDark ? const Color(0xFF280C0C) : const Color(0xFFFEF2F2),
      ),
      AppToastType.warning => (
        LucideIcons.alertTriangle,
        d.warning,
        d.warning.withValues(alpha: 0.36),
        d.isDark ? const Color(0xFF2E1906) : const Color(0xFFFFFBEB),
      ),
      AppToastType.info => (
        LucideIcons.info,
        d.primary,
        d.border,
        d.card,
      ),
    };

    return SafeArea(
      top: true,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: d.md,
            vertical: d.sm,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    key: const ValueKey('app-toast-container'),
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                      minHeight: 48,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(d.radiusControl),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: d.authDark.withValues(alpha: 0.16),
                          offset: const Offset(0, 6),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: d.md,
                      vertical: d.gap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          key: ValueKey('app-toast-icon-${widget.type.name}'),
                          size: 18,
                          weight: 300,
                          color: iconColor,
                        ),
                        SizedBox(width: d.sm),
                        Flexible(
                          child: Text(
                            widget.message,
                            key: const ValueKey('app-toast-message'),
                            style: d.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: d.foreground,
                            ),
                            softWrap: true,
                          ),
                        ),
                        SizedBox(width: d.sm),
                        InkWell(
                          key: const ValueKey('app-toast-dismiss-button'),
                          borderRadius: BorderRadius.circular(d.radiusControl),
                          onTap: widget.onDismiss,
                          child: Padding(
                            padding: EdgeInsets.all(d.xs),
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: d.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

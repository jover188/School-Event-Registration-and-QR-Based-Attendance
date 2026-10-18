import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_tokens.dart';

class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child, required this.semanticLabel,
    this.onPressed, this.selected = false});
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final enabled = widget.onPressed != null;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onPressed?.call();
          return null;
        })},
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          excludeFromSemantics: true, behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: !reduce && enabled && _pressed ? 0.98 : 1,
            duration: reduce ? Duration.zero : d.interactionDuration,
            child: Container(
              constraints: BoxConstraints(minHeight: d.minimumTarget, minWidth: d.minimumTarget),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(d.radiusControl),
                border: Border.all(color: _focused && enabled ? d.ring : Colors.transparent, width: 2),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

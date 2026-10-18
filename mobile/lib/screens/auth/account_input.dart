import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/theme/app_theme.dart';

/// An account form field with a wrapping persistent label and native Form validation.
class AccountInput extends StatelessWidget {
  const AccountInput({
    super.key,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.showLeadingDivider = false,
    this.fieldDecoration,
    this.fieldPadding,
    this.constraints,
    this.textStyle,
    this.placeholderStyle,
    this.cursorColor,
    this.selectionColor,
    required this.decoration,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;
  final bool showLeadingDivider;
  final ShadDecoration? fieldDecoration;
  final EdgeInsetsGeometry? fieldPadding;
  final BoxConstraints? constraints;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;
  final Color? cursorColor;
  final Color? selectionColor;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final Widget? leadingWidget = decoration.prefixIcon == null
        ? null
        : showLeadingDivider
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  decoration.prefixIcon!,
                  SizedBox(width: d.gap),
                  Container(
                    width: 1,
                    height: 20,
                    color: d.border,
                  ),
                  SizedBox(width: d.xs),
                ],
              )
            : decoration.prefixIcon;

    final field = ShadInputFormField(
      controller: controller,
      decoration: fieldDecoration,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator == null ? null : (v) => validator!(v),
      label: decoration.labelText == null
          ? null
          : Text(
              decoration.labelText!,
              style: d.supporting.copyWith(
                color: d.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
      placeholder: decoration.hintText == null
          ? null
          : Text(
              decoration.hintText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      leading: leadingWidget,
      trailing: decoration.suffixIcon,
      onSubmitted: onFieldSubmitted,
      padding: fieldPadding,
      placeholderStyle: placeholderStyle,
      style: textStyle ?? d.body,
      alignment: Alignment.centerLeft,
      placeholderAlignment: Alignment.centerLeft,
      cursorColor: cursorColor,
      selectionColor: selectionColor,
      constraints: constraints ?? BoxConstraints(minHeight: d.minimumTarget),
    );

    if (ShadTheme.maybeOf(context) == null) {
      return ShadTheme(data: AppTheme.shadTheme, child: field);
    }
    return field;
  }
}

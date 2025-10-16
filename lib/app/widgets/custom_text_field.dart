import 'dart:async';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class CustomTextField extends StatefulWidget {
  // Appearance Properties
  final Color? iconColor;
  final Color? labelColor;
  final Color? hintColor;
  final Color? fillColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final double height;
  final double? textSize;
  final bool isBold;

  // Input Properties
  final TextInputType? type;
  final String? hint;
  final String? anotherHint;
  final String? initialValue;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction inputAction;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? formattedType;

  // Behavior Properties
  final bool isPassword;
  final bool isRequired;
  final bool isEnabled;
  final bool readOnly;
  final bool? autoFocus;
  final bool keyboardPadding;
  final bool contentPadding;
  final bool needMargin;
  final bool needToSuffixConstraints;
  final bool isResendSuffixIcon;
  final bool isNeedToElevation;

  // Controllers and Callbacks
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onSubmit;
  final String? Function(String?)? validate;
  final void Function()? onTap;
  final void Function(bool)? onFocusChange;
  final void Function()? onEditingComplete;

  // Additional UI Elements
  final String? name;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Iterable<String>? autoFillHints;

  const CustomTextField({
    super.key,
    this.iconColor,
    this.labelColor,
    this.hintColor = Colors.grey,
    this.fillColor = Colors.white,
    this.textColor,
    this.borderColor = ColorsManager.borderColor,
    this.focusedBorderColor = ColorsManager.primary,
    this.borderRadius = 8,
    this.height = 50,
    this.textSize,
    this.isBold = true,
    this.type,
    this.hint,
    this.anotherHint,
    this.initialValue,
    this.maxLines,
    this.maxLength,
    this.inputAction = TextInputAction.next,
    this.textAlign,
    this.textDirection,
    this.formattedType,
    this.isPassword = false,
    this.isRequired = false,
    this.isEnabled = true,
    this.readOnly = false,
    this.autoFocus,
    this.keyboardPadding = true,
    this.contentPadding = false,
    this.needMargin = true,
    this.needToSuffixConstraints = false,
    this.isResendSuffixIcon = false,
    this.isNeedToElevation = false,
    this.controller,
    this.focusNode,
    this.onChange,
    this.onSubmit,
    this.validate,
    this.onTap,
    this.onFocusChange,
    this.onEditingComplete,
    this.name,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.autoFillHints,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _showPassword;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _showPassword = false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _handleTextChange(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      widget.onChange?.call(value);
    });
  }

  InputBorder _buildBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: color ?? widget.borderColor!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.name != null) ...[
          Text(
            widget.name!,
            style: StylesManager.regular(
              fontSize: 14,
              color: widget.labelColor,
            ),
          ),
          //   AppSpacer(heightRatio: .6),
        ],
        SizedBox(height: 10),
        TextFormField(
          enableSuggestions: true,
          focusNode: widget.focusNode,
          autofillHints: widget.autoFillHints,
          onTap: widget.onTap,
          textInputAction: widget.inputAction,
          readOnly: widget.readOnly,
          onEditingComplete: widget.onEditingComplete,
          initialValue: widget.initialValue,
          autofocus: widget.autoFocus ?? false,
          maxLength: widget.maxLength,
          textDirection: widget.textDirection,
          textAlign: widget.textAlign ?? TextAlign.start,
          controller: widget.controller,
          maxLines: widget.isPassword ? 1 : widget.maxLines ?? 1,
          obscureText: widget.isPassword && !_showPassword,
          validator: widget.validate,
          keyboardType: widget.type,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleTextChange,
          inputFormatters: widget.formattedType ?? [],
          style: StylesManager.regular(
            fontSize: 14,
            color: widget.textColor ?? const Color(0xFF39434F),
          ),
          scrollPadding: EdgeInsets.only(
            bottom: widget.keyboardPadding
                ? MediaQuery.of(context).size.height * 0.2
                : 0,
          ),
          cursorColor: Colors.grey,
          decoration: InputDecoration(
            hintText: widget.anotherHint ?? widget.hint ?? "",
            hintStyle: StylesManager.medium(
              fontSize: 12,
              color: widget.hintColor,
            ),
            isDense: true,
            enabled: widget.isEnabled,
            filled: true,
            fillColor: widget.fillColor,
            errorText: widget.errorText,
            errorMaxLines: 1,
            prefixIcon: widget.prefixIcon,
            suffixIcon:
                widget.isPassword ? _buildPasswordToggle() : widget.suffixIcon,
            suffixIconConstraints: widget.needToSuffixConstraints
                ? BoxConstraints(
                    minHeight: 47,
                    minWidth: widget.isResendSuffixIcon ? 30 : 1,
                    maxHeight: 48,
                    maxWidth: widget.isResendSuffixIcon ? 30 : 1,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: widget.height < 49
                  ? (widget.suffixIcon != null || widget.prefixIcon != null
                      ? 0
                      : (widget.height - 30))
                  : (widget.height / 2 - 10),
            ),
            border: _buildBorder(),
            enabledBorder: _buildBorder(),
            focusedBorder: _buildBorder(color: widget.focusedBorderColor),
            disabledBorder: _buildBorder(),
            errorBorder: _buildBorder(color: ColorsManager.error),
            focusedErrorBorder: _buildBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordToggle() {
    return SizedBox(
      width: 38,
      child: GestureDetector(
        onTap: () => setState(() => _showPassword = !_showPassword),
        child: Icon(
          _showPassword ? Iconsax.eye : Iconsax.eye_slash,
          size: 20,
          color: widget.iconColor ?? const Color(0xFF82878F),
        ),
      ),
    );
  }
}

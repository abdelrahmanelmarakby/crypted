import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/extensions/int.dart';
import '../../core/extensions/string.dart';
import '../../core/constants/theme/colors_manager.dart';
import '../../core/constants/theme/sizes_manager.dart';
import '../../core/constants/theme/styles_manager.dart';
import 'required_text_widget.dart';

class CustomTextField extends StatefulWidget {
  final Color? iconColor;
  final Color? labelColor;
  final Color? hintColor;
  final TextInputType? type;
  final String? hint;
  final Iterable<String>? autoFillHints;
  final String? anotherHint;
  final ValueChanged<String>? onChange;
  final ValueChanged<String>? onSubmit;
  final String? Function(String?)? validate;
  final int? maxLines;
  final TextEditingController? controller;
  final void Function()? onTap;
  final bool keyboardPadding;
  final bool contentPadding;
  final int? maxLength;
  final bool? autoFocus;
  final String? errorText;
  final Color? fillColor;
  final Color? textColor;
  final Widget? suffixIcon;

  final String? initialValue;
  final Widget? prefixIcon;

  final bool isEnabled;
  final bool needMargin;

  final bool readOnly;
  final double? textSize;

  final TextDirection? textDirection;

  final List<TextInputFormatter>? formattedType;
  final double height;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;

  final bool isNeedToElevation;
  final TextAlign? textAlign;
  final bool needToSuffixConstraints;
  final bool isResendSuffixIcon;
  final bool isBold;
  final TextInputAction inputAction;
  final FocusNode? focusNode;
  final String? name;
  final bool isPassword;
  final bool isRequired;
  final bool isSunTitleRequired;

  final String? sunTitle;
  final void Function(bool)? onFocusChange;
  final void Function()? onEditingComplete;
  const CustomTextField({
    super.key,
    this.focusNode,
    this.sunTitle,
    this.type,
    this.isSunTitleRequired = false,
    this.hint,
    this.isRequired = false,
    this.autoFillHints,
    this.isPassword = false,
    this.onChange,
    this.validate,
    this.onFocusChange,
    this.focusedBorderColor = ColorsManager.primary1000,
    this.inputAction = TextInputAction.next,
    this.onTap,
    this.maxLines,
    this.isEnabled = true,
    this.onEditingComplete,
    this.controller,
    this.errorText,
    this.fillColor,
    this.textColor,
    this.maxLength,
    this.formattedType,
    this.iconColor,
    this.labelColor,
    this.keyboardPadding = true,
    this.contentPadding = false,
    this.autoFocus,
    this.initialValue,
    this.onSubmit,
    this.prefixIcon,
    this.readOnly = false,
    this.needMargin = true,
    this.textDirection,
    this.anotherHint,
    this.suffixIcon,
    this.textSize,
    this.height = 50,
    this.borderRadius = 10,
    this.isNeedToElevation = false,
    this.hintColor,
    this.textAlign,
    this.borderColor = Colors.grey,
    this.needToSuffixConstraints = false,
    this.isResendSuffixIcon = false,
    this.isBold = true,
    this.name,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool showPassword = false;
  int passwordStrength = 0;
  Color strengthColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.name != null)
          RequiredTextWidget(
            text: widget.name ?? "",
            isRequired: widget.isRequired,
            anotherHint: widget.sunTitle,
            isAnotherHintRequired: widget.isSunTitleRequired,
          ),
        if (widget.name != null) SizedBox(height: 8.h),
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
          obscureText: widget.isPassword && !showPassword,
          validator: widget.validate,
          keyboardType: widget.type,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: widget.isPassword
              ? (password) {
                  if (widget.onChange != null) widget.onChange!(password);
                  setState(() {
                    passwordStrength = password.measurePasswordStrength();
                    strengthColor =
                        passwordStrength.getColorForPasswordStrength();
                  });
                }
              : (txt) {
                  if (widget.onChange != null) widget.onChange!(txt);
                },
          inputFormatters: widget.formattedType ?? [],
          style: StylesManager.medium(
            fontSize: widget.textSize ?? 14,
            color: widget.textColor ?? const Color(0xFF39434F),
          ),
          scrollPadding: EdgeInsets.only(
            bottom: widget.keyboardPadding
                ? MediaQuery.of(context).size.height * .2
                : 0.0,
          ),
          cursorColor: Colors.grey,
          decoration: InputDecoration(
            hintStyle: StylesManager.medium(
              fontSize: 14,
              color: widget.hintColor ?? Colors.grey[600],
            ),
            isDense: true,
            enabled: widget.isEnabled,
            hintText: widget.anotherHint ?? widget.hint ?? "",
            labelStyle: TextStyle(
              fontSize: 16,
              color: widget.labelColor ?? ColorsManager.white,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            alignLabelWithHint: true,
            errorStyle: const TextStyle(color: Colors.red),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide: BorderSide(color: widget.borderColor!, width: 0.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide: BorderSide(color: widget.borderColor!, width: 0.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide:
                  const BorderSide(color: ColorsManager.red, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide: const BorderSide(
                  color: ColorsManager.primary1000, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide: BorderSide(color: widget.borderColor!, width: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(widget.borderRadius),
              ),
              borderSide: BorderSide(color: widget.borderColor!, width: 0.5),
            ),

            //  alignLabelWithHint: true,
            fillColor: widget.fillColor ?? Colors.transparent,
            filled: true,
            errorText: widget.errorText,
            errorMaxLines: 1,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? SizedBox(
                    width: Sizes.size38.h,
                    child: GestureDetector(
                      onTap: () {
                        showPassword = !showPassword;
                        setState(() {});
                      },
                      child: Icon(
                        showPassword ? Iconsax.eye : Iconsax.eye_slash,
                        size: 16.h,
                        color: const Color(0xFF82878F),
                      ),
                    ),
                  )
                : widget.suffixIcon,
            suffixIconConstraints: widget.needToSuffixConstraints
                ? BoxConstraints(
                    minHeight: 47,
                    minWidth: widget.isResendSuffixIcon ? 30 : 1,
                    maxHeight: 48,
                    maxWidth: widget.isResendSuffixIcon ? 30 : 1,
                  )
                : null,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import '../../core/global/validator.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PinCodeFields extends StatelessWidget {
  const PinCodeFields({super.key, this.onCompleted, required this.onChanged});
  final void Function(String)? onCompleted;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      autoFocus: true,
      cursorColor: ColorsManager.primary,
      textStyle: StylesManager.bold(fontSize: 24),
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: false,
      ),
      length: 4,
      validator: Validator.validateOtp,
      animationType: AnimationType.scale,
      enablePinAutofill: true,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(8),
        fieldHeight: 70,
        fieldWidth: 70,
        activeColor: ColorsManager.black,
        inactiveColor: ColorsManager.borderColor,
        selectedColor: ColorsManager.primary,
      ),
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: false,
      onCompleted: onCompleted,
      onChanged: onChanged,
    );
  }
}

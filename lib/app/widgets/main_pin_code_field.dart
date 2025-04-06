import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/constants/theme/colors_manager.dart';

class PinCodeFields extends StatelessWidget {
  const PinCodeFields({
    super.key,
    this.onCompleted,
    required this.onChanged,
  });

  final void Function(String)? onCompleted;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      autoFocus: true,
      cursorColor: ColorsManager.primary1000,
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: false,
      ),
      length: 4,
      animationType: AnimationType.scale,
      enablePinAutofill: true,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(14),
        fieldHeight: 54,
        fieldWidth: 54,
        activeColor: ColorsManager.primary1000,
        inactiveColor: Colors.grey,
        selectedColor: ColorsManager.primary1000,
      ),
      animationDuration: const Duration(milliseconds: 300),
      enableActiveFill: false,
      onCompleted: onCompleted,
      onChanged: onChanged,
    );
  }
}

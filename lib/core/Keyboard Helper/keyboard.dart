import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class KeyboardUtil {
  static void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}

class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove non-numeric characters except decimal point
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // If the text has a decimal point, limit the digits to two decimals
    if (newText.contains('.')) {
      List<String> parts = newText.split('.');
      if (parts[1].length > 2) {
        newText = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    // Format the number with Arabic numerals and a thousand separator
    final format = NumberFormat('#,###.00', 'ar_SA');
    try {
      newText = format.format(double.parse(newText));
    } catch (e) {
      newText = '';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

import 'package:flutter/material.dart';

class ColorsManager {
  static const Color star = Color.fromARGB(255, 255, 178, 62);
  static const Color buttonColor = Color(0xFFD0FD3E);
  static const Color dotColor = Color(0xFFADB3BC);
  static const Color subPrimary = Color(0xFF0E82FD);
  static const Color primary100 = Color(0xFFF2F7FB);
  static const Color primary200 = Color(0xFFBFD6EA);
  static const Color primary300 = Color(0xFF8BB0DA);
  static const Color primary400 = Color(0xFF5685CB);
  static const Color primary500 = Color(0xFF2156BC);
  static const Color primary600 = Color(0xFF1B3FA6);
  static const Color primary700 = Color(0xFF152B8F);
  static const Color primary800 = Color(0xFF101B78);
  static const Color primary900 = Color(0xFF0C0D60);
  static const Color primary1000 = Color(0xFF0B0848);
  static const Color accent = Color.fromARGB(255, 2, 30, 100);
  static const Color white = Color(0xFFFFFFFF);
  static const Color selection = Color(0xFF3E6FCF);
  static const Color light = Color(0xFFEFF4F8);
  static const Color lightBlue = Color(0xFF009AE2);
  static const Color pink = Color(0xFFF72585);
  static const Color offWhite = Color(0xFFF3F3F3);
  static const Color veryLightGrey = Color(0xFFCDCDCD);
  static const Color checkBoxBorderColor = Color(0xFFD9D9D9);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color grey = Color(0xFF808B9A); //#8C8C8C
  static const Color darkGrey = Color(0xFF616161);
  static const Color veryDarkGrey = Color(0xFF505050);
  static const Color charcoal = Color(0xFF222222);
  static const Color black = Color(0xFF000000);
  static const Color error = Color(0xFFFF0000);
  static const Color red = Color(0xFFFF0000);
  static const Color success = Color(0xFF00C853);
  static WidgetStateProperty<Color?> greyMatrialColor =
      WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return white;
    }
    return white;
  });

  static Color getShade(Color color, {bool darker = false, double value = .1}) {
    assert(value >= 0 && value <= 1, 'shade values must be between 0 and 1');

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness(
      (darker ? (hsl.lightness - value) : (hsl.lightness + value))
          .clamp(0.0, 1.0),
    );

    return hslDark.toColor();
  }
}

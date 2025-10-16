import 'package:flutter/material.dart';

class ColorsManager {
  // static const Color navbarColor = Color.fromARGB(255, 252, 255, 252);
  //0xff383737
  //0xff667085
  //0xffF3F4F6
  static const Color textfieldMessage = Color(0xffF3F4F6);
  static const Color manMessage = Color(0xff667085);
  static const Color navbarColor = Color(0xffF9F9F9);
  static const Color messFriendColor = Color(0xffEBF6EE);
  static const Color voiceColor = Color(0xff383737);
  static const Color voiceProgressColor = Color(0xffC8C8C8);

  static const Color backgroundIconSetting = Color(0xffEBF6EE);
  static const Color error2 = Color(0xffF04438);
  static const Color backgroundError = Color(0xffF8EFEF);
  static const Color backgroundcallContainer = Color(0xffE92A2A);

  static const Color scaffoldBackground = Color(0xFFFCFCFC);
  static const Color star = Color(0xFFFBEC26);
  static const Color buttonColor = Color(0xFFD0FD3E);
  static const Color dotColor = Color(0xFFADB3BC);
  static const Color primary = Color(0xFF31A354);
  static const Color primaryDark = Color(0xFF24306E);
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
  static const Color grey = Color(0xFF7C7C7C); //#8C8C8C
  static const Color darkGrey = Color(0xFF616161);
  static const Color veryDarkGrey = Color(0xFF505050);
  static const Color charcoal = Color(0xFF222222);
  static const Color black = Color(0xFF000000);
  static const Color error = Color(0xFFB00020);
  static const Color red = Color(0xFFFF4343);
  static const Color success = Color(0xFF00C853);
  static const Color blue = Color(0xFF3064CF);
  static const Color borderColor = Color(0xFFF2F2F2);
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
      (darker ? (hsl.lightness - value) : (hsl.lightness + value)).clamp(
        0.0,
        1.0,
      ),
    );

    return hslDark.toColor();
  }

  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFfABDCFF), Color(0xFF0396FF)],
  );
}

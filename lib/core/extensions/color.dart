import 'package:flutter/material.dart';

import '../constants/theme/colors_manager.dart';
extension SuiizColors on Color {
  /// Returns a [MaterialColor] from a [Color] object
  MaterialColor getMaterialColorFromColor() {
    final colorShades = <int, Color>{
      50: ColorsManager.getShade(this, value: 0.5),
      100: ColorsManager.getShade(this, value: 0.4),
      200: ColorsManager.getShade(this, value: 0.3),
      300: ColorsManager.getShade(this, value: 0.2),
      400: ColorsManager.getShade(this, value: 0.1),
      500: this, //Primary value
      600: ColorsManager.getShade(this, value: 0.1, darker: true),
      700: ColorsManager.getShade(this, value: 0.15, darker: true),
      800: ColorsManager.getShade(this, value: 0.2, darker: true),
      900: ColorsManager.getShade(this, value: 0.25, darker: true),
    };
    return MaterialColor(value, colorShades);
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

import 'package:flutter/widgets.dart';

import 'font_manager.dart';

//TextStyle builder method
TextStyle _getTextStyle({
  double? fontSize,
  String? fontFamily,
  Color? color,
  FontWeight? fontWeight,
  TextOverflow? overFlow = TextOverflow.ellipsis,
  TextDecoration decoration = TextDecoration.none,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontFamily: fontFamily,
    color: color,
    decoration: decoration,
    fontWeight: fontWeight,
    overflow: overFlow,
  );
}

class StylesManager {
  ///regular TextStyle
  static TextStyle regular({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontFamily: FontFamily.fontFamily,
      color: color,
      decoration: decoration,
      fontWeight: FontWeights.regular,
    );
  }

  // Bold TextStyle
  static TextStyle bold({
    double fontSize = 14,
    Color? color,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontFamily: FontFamily.fontFamily,
      decoration: decoration,
      color: color,
      overFlow: overflow,
      fontWeight: FontWeights.bold,
    );
  }

  // Medium TextStyle
  static TextStyle medium({
    double fontSize = 14,
    Color? color,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      overFlow: overflow,
      fontFamily: FontFamily.fontFamily,
      decoration: decoration,
      color: color,
      fontWeight: FontWeights.medium,
    );
  }

  // Light TextStyle
  static TextStyle light({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontFamily: FontFamily.fontFamily,
      decoration: decoration,
      overFlow: TextOverflow.visible,
      color: color,
      fontWeight: FontWeights.light,
    );
  }

  // SemiBold TextStyle
  static TextStyle semiBold({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontFamily: FontFamily.fontFamily,
      decoration: decoration,
      color: color,
      fontWeight: FontWeights.semiBold,
    );
  }

  // ExtraBold TextStyle
  static TextStyle extraBold({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      fontFamily: FontFamily.fontFamily,
      decoration: decoration,
      color: color,
      fontWeight: FontWeights.extraBold,
    );
  }

  // Black TextStyle
  static TextStyle black({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      decoration: decoration,
      fontFamily: FontFamily.fontFamily,
      color: color,
      fontWeight: FontWeights.black,
    );
  }

  // Thin TextStyle
  static TextStyle thin({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return _getTextStyle(
      fontSize: fontSize,
      decoration: decoration,
      fontFamily: FontFamily.fontFamily,
      color: color,
      fontWeight: FontWeights.light,
    );
  }

  // ============================================
  // DM SANS STYLES - For Zen/Minimal Design
  // ============================================

  /// DM Sans Regular - Clean geometric sans-serif (local font)
  static TextStyle dmSans({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
    TextDecoration decoration = TextDecoration.none,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: FontFamily.dmSans,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// DM Sans Medium - For subheadings
  static TextStyle dmSansMedium({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
    double? letterSpacing,
  }) {
    return dmSans(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  /// DM Sans SemiBold - For section headers
  static TextStyle dmSansSemiBold({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
    double? letterSpacing,
  }) {
    return dmSans(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  /// DM Sans Bold - For primary headings
  static TextStyle dmSansBold({
    double fontSize = 14,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
    double? letterSpacing,
  }) {
    return dmSans(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
      decoration: decoration,
      letterSpacing: letterSpacing,
    );
  }

  // ============================================
  // ZEN TYPOGRAPHY PRESETS
  // ============================================

  /// Large page title - 28px DM Sans Bold
  static TextStyle zenTitle({Color? color}) {
    return dmSansBold(
      fontSize: 28,
      color: color ?? const Color(0xFF1A1A1A),
      letterSpacing: -0.5,
    );
  }

  /// Section heading - 18px DM Sans SemiBold
  static TextStyle zenHeading({Color? color}) {
    return dmSansSemiBold(
      fontSize: 18,
      color: color ?? const Color(0xFF1A1A1A),
      letterSpacing: -0.3,
    );
  }

  /// Subheading - 15px DM Sans Medium
  static TextStyle zenSubheading({Color? color}) {
    return dmSansMedium(
      fontSize: 15,
      color: color ?? const Color(0xFF1A1A1A),
      letterSpacing: -0.1,
    );
  }

  /// Body text - 14px IBM Plex (your existing font)
  static TextStyle zenBody({Color? color}) {
    return regular(
      fontSize: 14,
      color: color ?? const Color(0xFF6B7280),
    );
  }

  /// Caption/small text - 12px IBM Plex
  static TextStyle zenCaption({Color? color}) {
    return regular(
      fontSize: 12,
      color: color ?? const Color(0xFF9CA3AF),
    );
  }

  /// Large stat number - 32px DM Sans Bold
  static TextStyle zenStat({Color? color}) {
    return dmSansBold(
      fontSize: 32,
      color: color ?? const Color(0xFF1A1A1A),
      letterSpacing: -1,
    );
  }
}

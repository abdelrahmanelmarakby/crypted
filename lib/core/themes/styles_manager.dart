import 'package:flutter/material.dart';

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
  // Dark-mode aware: pass a BuildContext to auto-adapt,
  // or provide an explicit color to override.
  // ============================================

  /// Large page title - 28px DM Sans Bold
  static TextStyle zenTitle({Color? color, BuildContext? context}) {
    return dmSansBold(
      fontSize: 28,
      color: color ?? _zenPrimaryColor(context),
      letterSpacing: -0.5,
    );
  }

  /// Section heading - 18px DM Sans SemiBold
  static TextStyle zenHeading({Color? color, BuildContext? context}) {
    return dmSansSemiBold(
      fontSize: 18,
      color: color ?? _zenPrimaryColor(context),
      letterSpacing: -0.3,
    );
  }

  /// Subheading - 15px DM Sans Medium
  static TextStyle zenSubheading({Color? color, BuildContext? context}) {
    return dmSansMedium(
      fontSize: 15,
      color: color ?? _zenPrimaryColor(context),
      letterSpacing: -0.1,
    );
  }

  /// Body text - 14px IBM Plex (your existing font)
  static TextStyle zenBody({Color? color, BuildContext? context}) {
    return regular(
      fontSize: 14,
      color: color ?? _zenSecondaryColor(context),
    );
  }

  /// Caption/small text - 12px IBM Plex
  static TextStyle zenCaption({Color? color, BuildContext? context}) {
    return regular(
      fontSize: 12,
      color: color ?? _zenTertiaryColor(context),
    );
  }

  /// Large stat number - 32px DM Sans Bold
  static TextStyle zenStat({Color? color, BuildContext? context}) {
    return dmSansBold(
      fontSize: 32,
      color: color ?? _zenPrimaryColor(context),
      letterSpacing: -1,
    );
  }

  // ── Zen dark-mode helpers ──

  static Color _zenPrimaryColor(BuildContext? context) {
    if (context != null && Theme.of(context).brightness == Brightness.dark) {
      return const Color(0xFFE0E0E0); // darkZenCharcoal
    }
    return const Color(0xFF1A1A1A); // zenCharcoal
  }

  static Color _zenSecondaryColor(BuildContext? context) {
    if (context != null && Theme.of(context).brightness == Brightness.dark) {
      return const Color(0xFF9E9E9E); // darkZenGray
    }
    return const Color(0xFF6B7280); // zenGray
  }

  static Color _zenTertiaryColor(BuildContext? context) {
    if (context != null && Theme.of(context).brightness == Brightness.dark) {
      return const Color(0xFF757575); // darkZenMuted
    }
    return const Color(0xFF9CA3AF); // zenMuted
  }
}

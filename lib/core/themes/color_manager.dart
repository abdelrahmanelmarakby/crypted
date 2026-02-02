import 'package:flutter/material.dart';

/// Centralized color palette for the Crypted app
/// Follows a semantic naming convention for better maintainability
class ColorsManager {
  // ============================================
  // BRAND COLORS
  // ============================================
  static const Color primary = Color(0xFF31A354);
  static const Color primaryLight = Color(0xFF5CB97A);
  static const Color primaryDark = Color(0xFF248A42);
  static const Color primarySurface = Color(0xFFEBF6EE);

  static const Color accent = Color.fromARGB(255, 2, 30, 100);
  static const Color accentLight = Color(0xFF3E6FCF);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF00962C);

  static const Color error = Color(0xFFB00020);
  static const Color error2 = Color(0xffF04438);
  static const Color errorLight = Color(0xFFF8EFEF);
  static const Color errorDark = Color(0xFF8B0017);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFE65100);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1565C0);

  // ============================================
  // NEUTRAL COLORS
  // ============================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF3F3F3);
  static const Color light = Color(0xFFEFF4F8);
  static const Color veryLightGrey = Color(0xFFCDCDCD);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color grey = Color(0xFF7C7C7C);
  static const Color darkGrey = Color(0xFF616161);
  static const Color veryDarkGrey = Color(0xFF505050);
  static const Color charcoal = Color(0xFF222222);
  static const Color black = Color(0xFF000000);

  // ============================================
  // BACKGROUND COLORS
  // ============================================
  static const Color scaffoldBackground = Color(0xFFFCFCFC);
  static const Color background = scaffoldBackground;
  static const Color surface = white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color navbarColor = Color(0xffF9F9F9);
  static const Color backgroundIconSetting = Color(0xffEBF6EE);
  static const Color backgroundError = Color(0xffF8EFEF);
  static const Color backgroundcallContainer = Color(0xffE92A2A);

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color textPrimary = black;
  static const Color textSecondary = grey;
  static const Color textTertiary = lightGrey;
  static const Color textDisabled = veryLightGrey;
  static const Color textOnPrimary = white;
  static const Color textOnDark = white;

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================
  static const Color border = Color(0xFFF2F2F2);
  static const Color borderColor = border;
  static const Color divider = Color(0xFFE0E0E0);
  static const Color checkBoxBorderColor = Color(0xFFD9D9D9);

  // ============================================
  // CHAT SPECIFIC COLORS
  // ============================================
  static const Color textfieldMessage = Color(0xffF3F4F6);
  static const Color manMessage = Color(0xff667085);
  static const Color messFriendColor = Color(0xffEBF6EE);
  static const Color voiceColor = Color(0xff383737);
  static const Color voiceProgressColor = Color(0xffC8C8C8);

  // ============================================
  // ZEN / MINIMAL DESIGN PALETTE
  // ============================================
  /// Deep charcoal for primary text - sophisticated alternative to pure black
  static const Color zenCharcoal = Color(0xFF1A1A1A);

  /// Secondary text color - balanced gray
  static const Color zenGray = Color(0xFF6B7280);

  /// Muted text color - for tertiary information
  static const Color zenMuted = Color(0xFF9CA3AF);

  /// Ultra subtle border color
  static const Color zenBorder = Color(0xFFF3F4F6);

  /// Subtle surface for cards
  static const Color zenSurface = Color(0xFFFAFAFA);

  /// Hover/pressed state background
  static const Color zenHover = Color(0xFFF9FAFB);

  // ============================================
  // MISC COLORS
  // ============================================
  static const Color star = Color(0xFFFBEC26);
  static const Color buttonColor = Color(0xFFD0FD3E);
  static const Color dotColor = Color(0xFFADB3BC);
  static const Color selection = Color(0xFF3E6FCF);
  static const Color lightBlue = Color(0xFF009AE2);
  static const Color pink = Color(0xFFF72585);
  static const Color red = Color(0xFFFF4343);
  static const Color blue = Color(0xFF3064CF);
  static const Color shadow = Color(0xFF000000);

  // ============================================
  // ONLINE STATUS COLORS
  // ============================================
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = grey;
  static const Color away = Color(0xFFFFC107);
  static const Color busy = Color(0xFFF44336);

  // ============================================
  // DARK MODE COLORS
  // ============================================
  static const Color darkScaffoldBackground = Color(0xFF121212);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkNavbar = Color(0xFF1A1A1A);
  static const Color darkAppBar = Color(0xFF1E1E1E);
  static const Color darkBottomSheet = Color(0xFF252525);
  static const Color darkDialog = Color(0xFF2C2C2C);
  static const Color darkInput = Color(0xFF2C2C2C);
  static const Color darkInputBorder = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF333333);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkSnackBar = Color(0xFF323232);

  // Dark mode text colors
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkTextTertiary = Color(0xFF757575);
  static const Color darkTextDisabled = Color(0xFF505050);

  // Dark mode chat colors
  static const Color darkTextfieldMessage = Color(0xFF2C2C2C);
  static const Color darkManMessage = Color(0xFF9E9E9E);
  static const Color darkMessFriendColor = Color(0xFF1B3A24);
  static const Color darkVoiceColor = Color(0xFFB0B0B0);
  static const Color darkVoiceProgressColor = Color(0xFF555555);

  // Dark mode icon/setting backgrounds
  static const Color darkBackgroundIconSetting = Color(0xFF1B3A24);
  static const Color darkBackgroundError = Color(0xFF3D1F1F);

  // Dark mode semantic colors
  static const Color darkSuccess = Color(0xFF4CAF50);
  static const Color darkSuccessLight = Color(0xFF1B3A24);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkWarningLight = Color(0xFF3D3118);
  static const Color darkInfo = Color(0xFF64B5F6);
  static const Color darkInfoLight = Color(0xFF1A2E45);

  // Dark mode zen palette
  static const Color darkZenCharcoal = Color(0xFFE0E0E0);
  static const Color darkZenGray = Color(0xFF9E9E9E);
  static const Color darkZenMuted = Color(0xFF757575);
  static const Color darkZenBorder = Color(0xFF333333);
  static const Color darkZenSurface = Color(0xFF1E1E1E);
  static const Color darkZenHover = Color(0xFF252525);

  // Dark mode status colors
  static const Color darkOnline = Color(0xFF66BB6A);
  static const Color darkStar = Color(0xFFFFD54F);

  // ============================================
  // ADAPTIVE COLOR HELPERS (light/dark)
  // ============================================

  /// Returns the appropriate color based on current brightness.
  /// Usage: `ColorsManager.adaptive(context, light: white, dark: darkSurface)`
  static Color adaptive(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Scaffold / page background
  static Color scaffoldBg(BuildContext context) => adaptive(context,
      light: scaffoldBackground, dark: darkScaffoldBackground);

  /// Card / container surface
  static Color surfaceAdaptive(BuildContext context) =>
      adaptive(context, light: white, dark: darkSurface);

  /// Primary text
  static Color textPrimaryAdaptive(BuildContext context) =>
      adaptive(context, light: textPrimary, dark: darkTextPrimary);

  /// Secondary text
  static Color textSecondaryAdaptive(BuildContext context) =>
      adaptive(context, light: textSecondary, dark: darkTextSecondary);

  /// Divider / border
  static Color dividerAdaptive(BuildContext context) =>
      adaptive(context, light: border, dark: darkDivider);

  /// Input field background
  static Color inputBg(BuildContext context) =>
      adaptive(context, light: surfaceVariant, dark: darkInput);

  /// Chat bubble (own message)
  static Color chatBubbleOwn(BuildContext context) =>
      adaptive(context, light: messFriendColor, dark: darkMessFriendColor);

  /// Chat bubble (friend message)
  static Color chatBubbleFriend(BuildContext context) =>
      adaptive(context, light: textfieldMessage, dark: darkTextfieldMessage);

  /// Voice waveform color
  static Color voiceAdaptive(BuildContext context) =>
      adaptive(context, light: voiceColor, dark: darkVoiceColor);

  /// Voice progress bar color
  static Color voiceProgressAdaptive(BuildContext context) => adaptive(context,
      light: voiceProgressColor, dark: darkVoiceProgressColor);

  /// Card surface
  static Color cardAdaptive(BuildContext context) =>
      adaptive(context, light: white, dark: darkCard);

  /// App bar background
  static Color appBarAdaptive(BuildContext context) =>
      adaptive(context, light: white, dark: darkAppBar);

  /// Bottom sheet background
  static Color bottomSheetAdaptive(BuildContext context) =>
      adaptive(context, light: white, dark: darkBottomSheet);

  /// Navbar background
  static Color navbarAdaptive(BuildContext context) =>
      adaptive(context, light: navbarColor, dark: darkNavbar);

  /// Icon setting background
  static Color iconSettingBg(BuildContext context) => adaptive(context,
      light: backgroundIconSetting, dark: darkBackgroundIconSetting);

  /// Error background
  static Color errorBg(BuildContext context) =>
      adaptive(context, light: backgroundError, dark: darkBackgroundError);

  /// Tertiary text
  static Color textTertiaryAdaptive(BuildContext context) =>
      adaptive(context, light: textTertiary, dark: darkTextTertiary);

  /// Border adaptive
  static Color borderAdaptive(BuildContext context) =>
      adaptive(context, light: border, dark: darkBorder);

  /// Surface variant adaptive
  static Color surfaceVariantAdaptive(BuildContext context) =>
      adaptive(context, light: surfaceVariant, dark: darkSurfaceVariant);

  // ============================================
  // MATERIAL STATE PROPERTY
  // ============================================
  static WidgetStateProperty<Color?> greyMatrialColor =
      WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return white;
    }
    return white;
  });

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get a lighter or darker shade of a color
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

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  /// Get a MaterialColor from a Color
  static MaterialColor getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, shades);
  }
}

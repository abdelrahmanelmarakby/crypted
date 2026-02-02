import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'font_manager.dart';
import 'styles_manager.dart';

/// App theme configuration following Material 3 design guidelines
/// with custom styling for the Crypted messaging app
class ThemeManager {
  // Private constructor to prevent instantiation
  ThemeManager._();

  /// Light theme configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    fontFamily: "IBM Plex Sans Arabic",

    // Color scheme
    colorScheme: ColorScheme.light(
      primary: ColorsManager.primary,
      primaryContainer: ColorsManager.primarySurface,
      secondary: ColorsManager.accent,
      secondaryContainer: ColorsManager.accentLight.withValues(alpha: 0.2),
      surface: ColorsManager.white,
      error: ColorsManager.error,
      onPrimary: ColorsManager.white,
      onSecondary: ColorsManager.white,
      onSurface: ColorsManager.textPrimary,
      onError: ColorsManager.white,
      outline: ColorsManager.border,
    ),

    scaffoldBackgroundColor: ColorsManager.scaffoldBackground,
    primaryColor: ColorsManager.primary,
    disabledColor: ColorsManager.lightGrey,

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: ColorsManager.divider,
      thickness: 1,
      space: 1,
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: ColorsManager.white,
      shadowColor: ColorsManager.shadow.withValues(alpha: 0.1),
      elevation: Elevations.sm,
      margin: const EdgeInsets.all(Margins.xSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      enableFeedback: true,
      backgroundColor: ColorsManager.primary,
      foregroundColor: ColorsManager.white,
      elevation: Elevations.lg,
      focusElevation: Elevations.xl,
      hoverElevation: Elevations.lg,
      shape: const CircleBorder(),
    ),

    // App bar theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(
        color: ColorsManager.black,
        size: IconSizes.md,
      ),
      actionsIconTheme: const IconThemeData(
        color: ColorsManager.black,
        size: IconSizes.md,
      ),
      backgroundColor: ColorsManager.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: ColorsManager.shadow.withValues(alpha: 0.05),
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: StylesManager.semiBold(
        color: ColorsManager.black,
        fontSize: FontSize.large,
      ),
    ),

    // Button themes
    buttonTheme: ButtonThemeData(
      buttonColor: ColorsManager.primary,
      disabledColor: ColorsManager.lightGrey,
      splashColor: ColorsManager.primaryLight,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: ColorsManager.white,
        disabledBackgroundColor: ColorsManager.lightGrey,
        disabledForegroundColor: ColorsManager.white,
        elevation: Elevations.sm,
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.xLarge,
          vertical: Paddings.normal,
        ),
        textStyle: StylesManager.semiBold(fontSize: FontSize.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorsManager.primary,
        side: const BorderSide(color: ColorsManager.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.xLarge,
          vertical: Paddings.normal,
        ),
        textStyle: StylesManager.semiBold(fontSize: FontSize.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.normal,
          vertical: Paddings.xSmall,
        ),
        textStyle: StylesManager.medium(fontSize: FontSize.medium),
      ),
    ),

    // Icon button theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ColorsManager.textPrimary,
        highlightColor: ColorsManager.primary.withValues(alpha: 0.1),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorsManager.navbarColor,
      selectedItemColor: ColorsManager.primary,
      unselectedItemColor: ColorsManager.lightGrey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: Elevations.md,
      selectedLabelStyle: StylesManager.medium(
        color: ColorsManager.primary,
        fontSize: FontSize.xXSmall,
      ),
      unselectedLabelStyle: StylesManager.regular(
        color: ColorsManager.lightGrey,
        fontSize: FontSize.xXSmall,
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      // Display styles
      displayLarge: StylesManager.bold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size32,
      ),
      displayMedium: StylesManager.bold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size26,
      ),
      displaySmall: StylesManager.bold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size24,
      ),

      // Headline styles
      headlineLarge: StylesManager.semiBold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size24,
      ),
      headlineMedium: StylesManager.semiBold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size20,
      ),
      headlineSmall: StylesManager.semiBold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size18,
      ),

      // Title styles
      titleLarge: StylesManager.semiBold(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size18,
      ),
      titleMedium: StylesManager.medium(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size16,
      ),
      titleSmall: StylesManager.medium(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size14,
      ),

      // Body styles
      bodyLarge: StylesManager.regular(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size16,
      ),
      bodyMedium: StylesManager.regular(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size14,
      ),
      bodySmall: StylesManager.regular(
        color: ColorsManager.textSecondary,
        fontSize: Sizes.size12,
      ),

      // Label styles
      labelLarge: StylesManager.medium(
        color: ColorsManager.textPrimary,
        fontSize: Sizes.size14,
      ),
      labelMedium: StylesManager.medium(
        color: ColorsManager.textSecondary,
        fontSize: Sizes.size12,
      ),
      labelSmall: StylesManager.regular(
        color: ColorsManager.textSecondary,
        fontSize: Sizes.size10,
      ),
    ),

    // Badge theme
    badgeTheme: const BadgeThemeData(
      backgroundColor: ColorsManager.error,
      textColor: ColorsManager.white,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      indicatorColor: ColorsManager.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: ColorsManager.primary,
      unselectedLabelColor: ColorsManager.textSecondary,
      labelStyle: StylesManager.semiBold(fontSize: FontSize.medium),
      unselectedLabelStyle: StylesManager.regular(fontSize: FontSize.medium),
      dividerColor: Colors.transparent,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: ColorsManager.surfaceVariant,
      selectedColor: ColorsManager.primarySurface,
      disabledColor: ColorsManager.lightGrey.withValues(alpha: 0.3),
      labelStyle: StylesManager.regular(fontSize: FontSize.small),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Paddings.normal,
        vertical: Paddings.xSmall,
      ),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: ColorsManager.white,
      elevation: Elevations.xl,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: StylesManager.semiBold(
        color: ColorsManager.textPrimary,
        fontSize: FontSize.large,
      ),
      contentTextStyle: StylesManager.regular(
        color: ColorsManager.textSecondary,
        fontSize: FontSize.medium,
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ColorsManager.white,
      elevation: Elevations.lg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: ColorsManager.lightGrey,
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColorsManager.charcoal,
      contentTextStyle: StylesManager.regular(
        color: ColorsManager.white,
        fontSize: FontSize.medium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColorsManager.primary,
      circularTrackColor: ColorsManager.primarySurface,
      linearTrackColor: ColorsManager.primarySurface,
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: Paddings.large,
        horizontal: Paddings.large,
      ),
      isDense: true,

      // Borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide:
            BorderSide(color: ColorsManager.lightGrey.withValues(alpha: 0.5)),
      ),

      // Text styles
      hintStyle: StylesManager.regular(
        color: ColorsManager.textTertiary,
        fontSize: FontSize.medium,
      ),
      labelStyle: StylesManager.medium(
        color: ColorsManager.textSecondary,
        fontSize: FontSize.medium,
      ),
      floatingLabelStyle: StylesManager.medium(
        color: ColorsManager.primary,
        fontSize: FontSize.small,
      ),
      errorStyle: StylesManager.regular(
        color: ColorsManager.error,
        fontSize: FontSize.small,
      ),
      suffixStyle: StylesManager.medium(color: ColorsManager.textSecondary),
      prefixStyle: StylesManager.medium(color: ColorsManager.textSecondary),

      focusColor: ColorsManager.primary,
      hoverColor: ColorsManager.primarySurface,
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.xSmall,
      ),
      titleTextStyle: StylesManager.medium(
        color: ColorsManager.textPrimary,
        fontSize: FontSize.medium,
      ),
      subtitleTextStyle: StylesManager.regular(
        color: ColorsManager.textSecondary,
        fontSize: FontSize.small,
      ),
      iconColor: ColorsManager.textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.white;
        }
        return ColorsManager.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return ColorsManager.lightGrey;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(ColorsManager.white),
      side: const BorderSide(
          color: ColorsManager.checkBoxBorderColor, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return ColorsManager.textSecondary;
      }),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: ColorsManager.primary,
      inactiveTrackColor: ColorsManager.primarySurface,
      thumbColor: ColorsManager.primary,
      overlayColor: ColorsManager.primary.withValues(alpha: 0.2),
    ),
  );

  /// Dark theme configuration
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    brightness: Brightness.dark,
    fontFamily: "IBM Plex Sans Arabic",

    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: ColorsManager.primary,
      primaryContainer: ColorsManager.darkBackgroundIconSetting,
      secondary: ColorsManager.accentLight,
      secondaryContainer: ColorsManager.accentLight.withValues(alpha: 0.2),
      surface: ColorsManager.darkSurface,
      error: ColorsManager.error2,
      onPrimary: ColorsManager.white,
      onSecondary: ColorsManager.white,
      onSurface: ColorsManager.darkTextPrimary,
      onError: ColorsManager.white,
      outline: ColorsManager.darkBorder,
    ),

    scaffoldBackgroundColor: ColorsManager.darkScaffoldBackground,
    primaryColor: ColorsManager.primary,
    disabledColor: ColorsManager.darkGrey,

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: ColorsManager.darkDivider,
      thickness: 1,
      space: 1,
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: ColorsManager.darkCard,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      elevation: Elevations.sm,
      margin: const EdgeInsets.all(Margins.xSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      enableFeedback: true,
      backgroundColor: ColorsManager.primary,
      foregroundColor: ColorsManager.white,
      elevation: Elevations.lg,
      focusElevation: Elevations.xl,
      hoverElevation: Elevations.lg,
      shape: const CircleBorder(),
    ),

    // App bar theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(
        color: ColorsManager.darkTextPrimary,
        size: IconSizes.md,
      ),
      actionsIconTheme: const IconThemeData(
        color: ColorsManager.darkTextPrimary,
        size: IconSizes.md,
      ),
      backgroundColor: ColorsManager.darkAppBar,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: FontSize.large,
      ),
    ),

    // Button themes
    buttonTheme: ButtonThemeData(
      buttonColor: ColorsManager.primary,
      disabledColor: ColorsManager.darkGrey,
      splashColor: ColorsManager.primaryLight,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        foregroundColor: ColorsManager.white,
        disabledBackgroundColor: ColorsManager.darkGrey,
        disabledForegroundColor: ColorsManager.darkTextDisabled,
        elevation: Elevations.sm,
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.xLarge,
          vertical: Paddings.normal,
        ),
        textStyle: StylesManager.semiBold(fontSize: FontSize.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorsManager.primary,
        side: const BorderSide(color: ColorsManager.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.xLarge,
          vertical: Paddings.normal,
        ),
        textStyle: StylesManager.semiBold(fontSize: FontSize.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.normal,
          vertical: Paddings.xSmall,
        ),
        textStyle: StylesManager.medium(fontSize: FontSize.medium),
      ),
    ),

    // Icon button theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ColorsManager.darkTextPrimary,
        highlightColor: ColorsManager.primary.withValues(alpha: 0.15),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorsManager.darkNavbar,
      selectedItemColor: ColorsManager.primary,
      unselectedItemColor: ColorsManager.darkTextTertiary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: Elevations.md,
      selectedLabelStyle: StylesManager.medium(
        color: ColorsManager.primary,
        fontSize: FontSize.xXSmall,
      ),
      unselectedLabelStyle: StylesManager.regular(
        color: ColorsManager.darkTextTertiary,
        fontSize: FontSize.xXSmall,
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      // Display styles
      displayLarge: StylesManager.bold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size32,
      ),
      displayMedium: StylesManager.bold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size26,
      ),
      displaySmall: StylesManager.bold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size24,
      ),

      // Headline styles
      headlineLarge: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size24,
      ),
      headlineMedium: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size20,
      ),
      headlineSmall: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size18,
      ),

      // Title styles
      titleLarge: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size18,
      ),
      titleMedium: StylesManager.medium(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size16,
      ),
      titleSmall: StylesManager.medium(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size14,
      ),

      // Body styles
      bodyLarge: StylesManager.regular(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size16,
      ),
      bodyMedium: StylesManager.regular(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size14,
      ),
      bodySmall: StylesManager.regular(
        color: ColorsManager.darkTextSecondary,
        fontSize: Sizes.size12,
      ),

      // Label styles
      labelLarge: StylesManager.medium(
        color: ColorsManager.darkTextPrimary,
        fontSize: Sizes.size14,
      ),
      labelMedium: StylesManager.medium(
        color: ColorsManager.darkTextSecondary,
        fontSize: Sizes.size12,
      ),
      labelSmall: StylesManager.regular(
        color: ColorsManager.darkTextSecondary,
        fontSize: Sizes.size10,
      ),
    ),

    // Badge theme
    badgeTheme: const BadgeThemeData(
      backgroundColor: ColorsManager.error,
      textColor: ColorsManager.white,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      indicatorColor: ColorsManager.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: ColorsManager.primary,
      unselectedLabelColor: ColorsManager.darkTextSecondary,
      labelStyle: StylesManager.semiBold(fontSize: FontSize.medium),
      unselectedLabelStyle: StylesManager.regular(fontSize: FontSize.medium),
      dividerColor: Colors.transparent,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: ColorsManager.darkSurfaceVariant,
      selectedColor: ColorsManager.darkBackgroundIconSetting,
      disabledColor: ColorsManager.darkGrey.withValues(alpha: 0.3),
      labelStyle: StylesManager.regular(fontSize: FontSize.small),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Paddings.normal,
        vertical: Paddings.xSmall,
      ),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: ColorsManager.darkDialog,
      elevation: Elevations.xl,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: StylesManager.semiBold(
        color: ColorsManager.darkTextPrimary,
        fontSize: FontSize.large,
      ),
      contentTextStyle: StylesManager.regular(
        color: ColorsManager.darkTextSecondary,
        fontSize: FontSize.medium,
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ColorsManager.darkBottomSheet,
      elevation: Elevations.lg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: ColorsManager.darkGrey,
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColorsManager.darkSnackBar,
      contentTextStyle: StylesManager.regular(
        color: ColorsManager.darkTextPrimary,
        fontSize: FontSize.medium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColorsManager.primary,
      circularTrackColor: ColorsManager.darkBackgroundIconSetting,
      linearTrackColor: ColorsManager.darkBackgroundIconSetting,
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.darkInput,
      contentPadding: const EdgeInsets.symmetric(
        vertical: Paddings.large,
        horizontal: Paddings.large,
      ),
      isDense: true,

      // Borders
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.darkInputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.darkInputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.error2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: ColorsManager.error2, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide:
            BorderSide(color: ColorsManager.darkGrey.withValues(alpha: 0.5)),
      ),

      // Text styles
      hintStyle: StylesManager.regular(
        color: ColorsManager.darkTextTertiary,
        fontSize: FontSize.medium,
      ),
      labelStyle: StylesManager.medium(
        color: ColorsManager.darkTextSecondary,
        fontSize: FontSize.medium,
      ),
      floatingLabelStyle: StylesManager.medium(
        color: ColorsManager.primary,
        fontSize: FontSize.small,
      ),
      errorStyle: StylesManager.regular(
        color: ColorsManager.error2,
        fontSize: FontSize.small,
      ),
      suffixStyle: StylesManager.medium(color: ColorsManager.darkTextSecondary),
      prefixStyle: StylesManager.medium(color: ColorsManager.darkTextSecondary),

      focusColor: ColorsManager.primary,
      hoverColor: ColorsManager.darkBackgroundIconSetting,
    ),

    // List tile theme
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Paddings.large,
        vertical: Paddings.xSmall,
      ),
      titleTextStyle: StylesManager.medium(
        color: ColorsManager.darkTextPrimary,
        fontSize: FontSize.medium,
      ),
      subtitleTextStyle: StylesManager.regular(
        color: ColorsManager.darkTextSecondary,
        fontSize: FontSize.small,
      ),
      iconColor: ColorsManager.darkTextSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.white;
        }
        return ColorsManager.darkTextTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return ColorsManager.darkGrey;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(ColorsManager.white),
      side: const BorderSide(color: ColorsManager.darkGrey, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorsManager.primary;
        }
        return ColorsManager.darkTextSecondary;
      }),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: ColorsManager.primary,
      inactiveTrackColor: ColorsManager.darkBackgroundIconSetting,
      thumbColor: ColorsManager.primary,
      overlayColor: ColorsManager.primary.withValues(alpha: 0.2),
    ),
  );
}

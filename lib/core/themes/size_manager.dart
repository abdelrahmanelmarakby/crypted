/// Spacing scale based on 4pt grid system for consistent UI
/// Usage: Use these values for margins, paddings, and gaps
class Spacing {
  static const double zero = 0.0;
  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

/// Margins is a class that contains static constants for common margins.
class Margins {
  static const double xXSmall = 4.0;
  static const double xSmall = 8.0;
  static const double small = 10.0;
  static const double normal = 12.0;
  static const double large = 16.0;
  static const double xLarge = 20.0;
  static const double xXLarge = 24.0;
  static const double xxxLarge = 32.0;
}

/// Paddings is a class that contains static constants for common padding sizes.
class Paddings {
  static const double xXSmall = 4.0;
  static const double xSmall = 8.0;
  static const double small = 10.0;
  static const double normal = 12.0;
  static const double medium = 14.0;
  static const double large = 16.0;
  static const double xLarge = 20.0;
  static const double xXLarge = 24.0;
  static const double xxxLarge = 32.0;
  static const double xXLarge50 = 50.0;
  static const double xXLarge60 = 60.0;
  static const double xXLarge90 = 90.0;
}

/// Border radius constants following iOS/Material design guidelines
class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double round = 100.0; // For pills and circular elements
  static const double card = 12.0;
  static const double button = 10.0;
  static const double input = 12.0;
  static const double bottomSheet = 24.0;
  static const double dialog = 16.0;
  static const double avatar = 50.0;
  static const double chip = 20.0;
}

/// Legacy radius class for backward compatibility
class Radiuss {
  static const double xXSmall = 4.0;
  static const double xSmall = 8.0;
  static const double xSmall9 = 9.0;
  static const double small = 10.0;
  static const double normal = 12.0;
  static const double medium = 14.0;
  static const double large = 16.0;
  static const double xLarge18 = 18.0;
  static const double xLarge19 = 19.0;
  static const double xLarge = 20.0;
  static const double xLarge22 = 22.0;
  static const double xLarge23 = 23.0;
  static const double xXLarge = 24.0;
  static const double xXLarge25 = 25.0;
  static const double xXLarge26 = 26.0;
  static const double xXLarge29 = 29.0;
  static const double xXLarge30 = 30.0;
  static const double xXLarge33 = 33.0;
  static const double xXLarge40 = 40.0;
  static const double xXLarge50 = 50.0;
  static const double xXLarge60 = 60.0;
  static const double xXLarge90 = 90.0;
  static const double xXLarge150 = 150.0;
}

/// Icon sizes following platform guidelines
class IconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

/// Avatar sizes for user images
class AvatarSizes {
  static const double xs = 24.0;
  static const double sm = 32.0;
  static const double md = 40.0;
  static const double lg = 48.0;
  static const double xl = 56.0;
  static const double xxl = 64.0;
  static const double profile = 80.0;
  static const double hero = 120.0;
}

/// A class that contains static constants for different sizes.
/// Note: if you want size bigger than these please consider using flex widgets and media query sizes to maintain the responsive design.
class Sizes {
  static const double size2 = 2.0;
  static const double size4 = 4.0;
  static const double size8 = 8.0;
  static const double size10 = 10.0;
  static const double size12 = 12.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size24 = 24.0;
  static const double size26 = 26.0;
  static const double size30 = 30.0;
  static const double size32 = 32.0;
  static const double size34 = 34.0;
  static const double size38 = 38.0;
  static const double size42 = 42.0;
  static const double size48 = 48.0;
  static const double size50 = 50.0;
  static const double size60 = 60.0;
  static const double size70 = 70.0;
  static const double size90 = 90.0;
  static const double size100 = 100.0;
  static const double size104 = 104.0;
  static const double size111 = 111.0;
  static const double size150 = 150.0;
  static const double size155 = 155.0;
  static const double size170 = 170.0;
  static const double size200 = 200.0;
  static const double size250 = 250.0;
  static const double size280 = 280.0;
  static const double size300 = 300.0;
  static const double size350 = 350.0;
}

/// Elevation values for shadows
class Elevations {
  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
}

/// Animation durations for consistent motion design
class Durations {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);
}

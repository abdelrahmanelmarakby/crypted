import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ZEGO Cloud (UIKits app)
  static int get appID => int.tryParse(dotenv.env['ZEGO_APP_ID'] ?? '') ?? 0;
  static String get appSign => dotenv.env['ZEGO_APP_SIGN'] ?? '';

  // RevenueCat
  static String get revenueCatApiKey => dotenv.env['REVENUECAT_API_KEY'] ?? '';
  static String get entitlementId =>
      dotenv.env['REVENUECAT_ENTITLEMENT_ID'] ?? 'Crypted Pro';

  // Google Maps
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Giphy
  static String get giphyApiKey => dotenv.env['GIPHY_API_KEY'] ?? '';
}

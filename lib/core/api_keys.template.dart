/// API Keys Configuration Template
/// 📝 SETUP INSTRUCTIONS:
/// 1. Copy this file to 'api_keys.dart' in the same directory
/// 2. Replace 'YOUR_API_KEY_HERE' with your actual Google Maps API key
/// 3. The api_keys.dart file is git-ignored for security
///
/// ⚠️ IMPORTANT SECURITY NOTES:
/// - NEVER commit api_keys.dart to version control
/// - Restrict your API key in Google Cloud Console:
///   - For Android: Add your app's package name and SHA-1 fingerprint
///   - For iOS: Add your app's bundle identifier
///   - For Web: Add authorized domains
/// - Enable only the APIs you need (Maps SDK, Places API, etc.)
/// - Monitor API usage in Google Cloud Console

class ApiKeys {
  // Google Maps & Places API Key
  // Get your key from: https://console.cloud.google.com/apis/credentials
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  /// Get the API key for Google Maps
  static String get mapsKey => googleMapsApiKey;

  /// Get the API key for Google Places
  static String get placesKey => googleMapsApiKey;

  // Add other API keys here as needed
  // static const String otherApiKey = 'YOUR_OTHER_API_KEY_HERE';
}

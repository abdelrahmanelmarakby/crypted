# Google Maps & Places API Setup 🗺️

This project uses Google Maps and Places APIs for location features. Follow these steps to set up the API keys securely.

## Features

- **Google Places Autocomplete**: Search for locations with real-time suggestions
- **Interactive Map Viewer**: Full-screen Google Maps with zoom/pan controls
- **Static Map Previews**: Beautiful map previews in location messages
- **Location Sharing**: Share locations in chats and stories

## Security Implementation

The API keys are **NOT committed to version control** for security reasons. They are stored in a `.env` file which is git-ignored.

### File Structure

```
.
├── .env              # ❌ Git-ignored (contains actual keys)
└── .env.template     # ✅ Committed (template file)
```

## Setup Instructions

### 1. Get Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (if using web)
   - **Places API**
   - **Maps Static API**
4. Create credentials > API Key

### 2. Secure Your API Key

**IMPORTANT**: Restrict your API key to prevent unauthorized use!

#### For Android:
1. Add **Application restrictions** > Android apps
2. Add your package name: `com.example.crypted_app` (or your actual package)
3. Get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Add the SHA-1 fingerprint to your API key restrictions

#### For iOS:
1. Add **Application restrictions** > iOS apps
2. Add your bundle identifier (found in `ios/Runner.xcodeproj`)

#### API Restrictions:
Enable only the APIs you need:
- Maps SDK for Android
- Maps SDK for iOS
- Places API
- Maps Static API

### 3. Configure the API Key in Your Project

The `.env` file should already exist with your key. If not:

1. Copy the template file:
   ```bash
   cp .env.template .env
   ```

2. Edit `.env` and replace the placeholder:
   ```env
   GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

3. **VERIFY** the file is git-ignored:
   ```bash
   git status
   # .env should NOT appear in the list
   ```

4. Run `flutter pub get` to ensure `flutter_dotenv` package is installed

### 4. Platform-Specific Setup

#### Android (`android/app/src/main/AndroidManifest.xml`):

Add your API key inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

#### iOS (`ios/Runner/AppDelegate.swift`):

Add this import and configuration:

```swift
import GoogleMaps

override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    // ... rest of the code
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

## Usage

### Location Picker with Places Autocomplete

```dart
import 'package:crypted_app/app/modules/stories/widgets/google_places_location_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ensure .env is loaded in main.dart:
// await dotenv.load(fileName: ".env");

// Show location picker
Get.bottomSheet(
  GooglePlacesLocationPicker(
    onLocationSelected: (lat, lon, placeName) {
      print('Selected: $placeName at $lat, $lon');
    },
  ),
  isScrollControlled: true,
);
```

### Interactive Map Viewer

```dart
import 'package:crypted_app/app/widgets/interactive_map_viewer.dart';

// Show interactive map
Get.to(() => InteractiveMapViewer(
  latitude: 37.7749,
  longitude: -122.4194,
  locationName: 'San Francisco',
  address: '1 Market St, San Francisco, CA',
));
```

### Location Messages

Location messages automatically display Google Maps static images and are tappable to open the interactive viewer.

## Monitoring Usage

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to **APIs & Services** > **Dashboard**
4. Monitor API usage and set up billing alerts

## Troubleshooting

### Maps not loading?
- Verify API key is correctly set in `.env` file and platform manifests (AndroidManifest.xml, AppDelegate.swift)
- Ensure `.env` file is loaded in `main.dart`: `await dotenv.load(fileName: ".env");`
- Check API restrictions match your app's package name/bundle ID
- Ensure all required APIs are enabled in Google Cloud Console
- Check logcat (Android) or Xcode console (iOS) for error messages

### "API key not valid" error?
- Verify the key is correct (no extra spaces)
- Check API key restrictions
- Ensure billing is enabled on your Google Cloud project

### Places autocomplete not working?
- Verify Places API is enabled
- Check API key restrictions allow Places API
- Ensure internet connection is available

## Cost Estimation

Google Maps APIs have a free tier:
- **Static Maps**: $2 per 1000 requests (free up to 28,500/month)
- **Places Autocomplete**: $2.83 per 1000 requests (free up to ~17,500/month)
- **Maps SDK (Android/iOS)**: Free for mobile apps

**Tip**: Set up budget alerts in Google Cloud Console to monitor costs.

## Security Best Practices

✅ **DO:**
- Keep `.env` file git-ignored
- Use `.env` for environment variables (industry standard)
- Restrict API keys to specific apps/domains
- Enable only necessary APIs
- Monitor usage regularly
- Rotate keys if compromised

❌ **DON'T:**
- Commit `.env` file or API keys to version control
- Share keys publicly
- Use unrestricted API keys
- Hardcode keys in multiple places
- Use the same key for all environments

## Support

For issues related to:
- **Google Maps APIs**: [Google Maps Platform Support](https://developers.google.com/maps/support)
- **This Implementation**: Check the codebase documentation or contact the development team

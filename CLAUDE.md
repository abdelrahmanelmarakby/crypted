# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crypted is a Flutter-based encrypted messaging application with real-time chat, stories, voice/video calling, and social features. It uses Firebase as the backend, GetX for state management, and follows a modular architecture pattern.

## Common Commands

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with specific flavor
flutter run --flavor dev

# Hot reload (press 'r' in terminal while app is running)
# Hot restart (press 'R' in terminal)
```

### Building
```bash
# Build APK (Android)
flutter build apk --release

# Build app bundle (Android - for Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build for specific flavor
flutter build apk --flavor prod
```

### Code Generation
```bash
# Generate assets (images, icons, fonts) - run after adding new assets
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing & Analysis
```bash
# Run Flutter analyzer
flutter analyze

# Format code
flutter format lib/

# Check for outdated dependencies
flutter pub outdated
```

### Dependency Management
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build
flutter clean && flutter pub get
```

## Architecture

### Directory Structure

```
lib/
├── app/
│   ├── core/                    # App-level core utilities
│   │   ├── services/           # Chat session, FCM, presence tracking
│   │   └── widgets/            # Reusable widgets
│   ├── data/
│   │   ├── data_source/        # Firebase/API data sources
│   │   └── models/             # Data models (user, story, message, etc.)
│   ├── modules/                # Feature modules (GetX pattern)
│   │   ├── chat/
│   │   ├── stories/
│   │   ├── calls/
│   │   ├── home/
│   │   └── [other features]/
│   ├── routes/                 # Navigation routes (GetX)
│   ├── services/               # App services
│   └── widgets/                # Shared widgets
├── core/
│   ├── locale/                 # Internationalization (i18n)
│   ├── themes/                 # Theme management, colors, fonts, styles
│   ├── services/               # Global services (cache, bindings)
│   └── extensions/             # Dart extensions
└── gen/                        # Generated code (assets, fonts)
```

### Module Structure (GetX Pattern)

Each feature module follows GetX convention:
```
module_name/
├── bindings/          # Dependency injection bindings
├── controllers/       # Business logic & state management
├── views/            # UI screens
└── widgets/          # Module-specific widgets
```

### Key Architectural Patterns

1. **GetX State Management**: Uses `.obs` observables and `Obx()`/`GetBuilder` for reactive UI
2. **Firebase Integration**: Firestore for data, Storage for files, Auth for authentication
3. **Stream-based Data**: Real-time updates via Firestore streams
4. **Service Layer**: Separation of data sources (`*_data_sources.dart`) from UI logic
5. **Modular Design**: Each feature is self-contained with its own bindings, controllers, and views

## Message Types System

The chat system supports multiple message types with dedicated widgets:

**Message Types:**
- `TextMessage` - Regular text messages
- `PhotoMessage` - Image messages
- `VideoMessage` - Video messages
- `AudioMessage` - Voice messages with waveform visualization
- `FileMessage` - Document/file attachments
- `PollMessage` - Interactive polls with Firebase vote persistence
- `LocationMessage` - Location sharing with map preview
- `ContactMessage` - Contact cards
- `CallMessage` - Call history records

**Message Widget Location:** `lib/app/modules/chat/widgets/message_type_widget/`

**Adding New Message Type:**
1. Create model in `lib/app/data/models/messages/`
2. Add widget in `lib/app/modules/chat/widgets/message_type_widget/`
3. Update message factory/parser in chat controller
4. Add Firestore serialization in data source

## Stories System

Instagram/WhatsApp-style stories with full-screen viewer:

**Key Files:**
- Controller: `lib/app/modules/stories/controllers/stories_controller.dart`
- Viewer: `lib/app/modules/stories/widgets/story_viewer.dart`
- Data Source: `lib/app/data/data_source/story_data_sources.dart`
- Model: `lib/app/data/models/story_model.dart`

**Story Features:**
- Image, video, and text stories
- 24-hour expiration
- View tracking (`viewedBy` list)
- Progress bars for multi-story sequences
- Tap zones (left/right) for navigation
- Long-press to pause
- Auto-advance between users

**Story Creation Flow:**
1. User selects media (camera/gallery) or creates text story
2. Upload to Firebase Storage (for media)
3. Create Firestore document with story metadata
4. Stories auto-expire after 24 hours

## Theme System

**Location:** `lib/core/themes/`

**Key Files:**
- `color_manager.dart` - Centralized color palette (primary: `#31A354`)
- `font_manager.dart` - Font sizes and weights
- `styles_manager.dart` - Text style factory methods
- `size_manager.dart` - Padding and sizing constants
- `theme_manager.dart` - Material theme configuration

**Usage:**
```dart
// Colors
Container(color: ColorsManager.primary)

// Text Styles
Text('Hello', style: StylesManager.semiBold(fontSize: FontSize.large))

// Padding
Padding(padding: EdgeInsets.all(Paddings.large))
```

**Font:** IBM Plex Sans Arabic (supports Arabic and English)

## Firebase Structure

### Collections

- `users/` - User profiles and metadata
- `Stories/` - Story posts (24hr expiration)
- `chat_rooms/` or `conversations/` - Chat room metadata
  - `chat_rooms/{roomId}/chat/` - Messages subcollection
- `calls/` - Call history
- `notifications/` - Push notifications

### Firebase Services

**FirebaseOptimizationService** (`lib/app/core/services/firebase_optimization_service.dart`)
- Persistence & caching configuration
- Memory management

**PresenceService** (`lib/app/core/services/presence_service.dart`)
- Online/offline status tracking
- Last seen timestamps
- Lifecycle-aware (goes offline when app backgrounds)

**FCMService** (`lib/app/core/services/fcm_service.dart`)
- Push notifications
- Token management

## Localization (i18n)

**Location:** `lib/core/locale/`

**Key Files:**
- `my_locale.dart` - Translation maps (Arabic & English)
- `constant.dart` - Translation key constants
- `my_locale_controller.dart` - Language switching logic

**Usage:**
```dart
Text(Constants.kWelcome.tr) // GetX translation
```

**Supported Languages:** Arabic (ar), English (en)

## Real-time Features

### Chat Sessions
**ChatSessionManager** (`lib/app/core/services/chat_session_manager.dart`)
- Tracks active chat sessions
- Manages typing indicators
- Handles message read receipts

### Presence Tracking
Users' online status is automatically tracked:
- Green dot when active
- "Last seen" timestamp when offline
- Updates on app lifecycle changes (foreground/background)

### Live Updates
- Messages: Firestore streams update in real-time
- Stories: New stories appear instantly
- Polls: Vote counts update live via Firestore transactions

## Zego Cloud Integration

Video/voice calling powered by Zego Cloud:

**Configuration:** `lib/core/constant.dart` (AppConstants.appID, AppConstants.appSign)

**Initialization:** In `main.dart` after user authentication

**Usage:** `ZegoUIKitPrebuiltCallInvitationService()` for call invitations

## Development Workflow

### Adding a New Feature Module

1. **Create module structure:**
```bash
mkdir -p lib/app/modules/feature_name/{bindings,controllers,views,widgets}
```

2. **Add route:** Edit `lib/app/routes/app_pages.dart` and `app_routes.dart`

3. **Create binding:**
```dart
class FeatureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeatureController>(() => FeatureController());
  }
}
```

4. **Create controller:**
```dart
class FeatureController extends GetxController {
  final RxList<Item> items = <Item>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }
}
```

5. **Create view:**
```dart
class FeatureView extends GetView<FeatureController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => ListView.builder(...)),
    );
  }
}
```

### Working with Firestore

**Pattern for real-time data:**
```dart
// In data source
Stream<List<Model>> getData() {
  return collection
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) =>
      snapshot.docs.map((doc) => Model.fromQuery(doc)).toList()
    );
}

// In controller
void setupListener() {
  dataSource.getData().listen((data) {
    items.value = data;
    update();
  });
}
```

**Pattern for mutations:**
```dart
// Use transactions for atomic updates (e.g., poll votes)
await FirebaseFirestore.instance.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  // ... update logic
  transaction.update(docRef, updatedData);
});
```

### Asset Management

**Adding new assets:**

1. Place files in appropriate directory:
   - Images: `assets/images/`
   - Icons: `assets/icons/`
   - Lottie: `assets/lottie/`
   - Sounds: `assets/sounds/`

2. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Use generated assets:
```dart
Image.asset(Assets.images.logo.path)
SvgPicture.asset(Assets.icons.menu.path)
```

## Important Conventions

### Code Style
- Use Arabic comments in existing Arabic-commented files (bilingual codebase)
- Follow Dart naming conventions: `camelCase` for variables, `PascalCase` for classes
- Use `final` for immutable variables
- Prefer const constructors where possible

### GetX Patterns
- Controllers extend `GetxController`
- Views extend `GetView<ControllerType>`
- Use `.obs` for reactive variables
- Wrap reactive UI with `Obx(() => ...)` or `GetBuilder<Controller>`
- Access controller in view: `controller.property` (no `Get.find()` needed)

### Firebase Patterns
- Always handle null cases for Firestore data
- Use Timestamp for dates, convert to DateTime
- Include user metadata in documents (avoids extra lookups)
- Implement exponential backoff for retries
- Use FieldValue.arrayUnion/arrayRemove for array updates

### Error Handling
```dart
try {
  // operation
} catch (e) {
  log('Error description: $e');  // Use dart:developer log
  Get.snackbar('Error', 'User-friendly message');
}
```

### Memory Management
- Dispose controllers, animation controllers, and streams in `dispose()`
- Use `Get.lazyPut` for controllers (initialized when needed)
- Unsubscribe from Firestore listeners when not needed

## Known Patterns in Codebase

### Message Sending Pattern
1. Create message model with temp ID
2. Add to UI optimistically (local state)
3. Upload media files to Firebase Storage (if applicable)
4. Save message to Firestore with download URLs
5. Update local state with Firestore-assigned ID

### Story Viewer Pattern
- Full-screen PageView for horizontal user swiping
- AnimationController for progress bars (per story)
- GestureDetector tap zones: left (previous), right (next), center (pause)
- Long-press pauses playback
- Auto-advances after duration expires

### Poll Integration Pattern
- Votes stored as map: `{"optionIndex": ["userId1", "userId2"]}`
- Use Firestore transactions for vote updates (prevents race conditions)
- Calculate percentages client-side from vote counts
- Listen to Firestore stream for real-time vote updates

## Testing Considerations

- Test on both iOS and Android (platform-specific code exists)
- Verify Firebase rules allow operations
- Test offline scenarios (Firebase persistence enabled)
- Check RTL layout for Arabic language
- Verify notification permissions on first launch
- Test call functionality with multiple users (requires Zego setup)

## Common Issues & Solutions

**Issue:** Firebase connection fails
- Solution: Check `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present
- Verify Firebase project configuration in `firebase_options.dart`

**Issue:** GetX dependency not found
- Solution: Ensure binding is registered in `app_pages.dart`
- Check InitialBindings in `main.dart`

**Issue:** Assets not found after adding
- Solution: Run `flutter pub run build_runner build --delete-conflicting-outputs`
- Verify asset path in `pubspec.yaml`

**Issue:** Stories not showing
- Solution: Check Firestore `expiresAt` field (stories expire after 24 hours)
- Verify user data is included in story documents

**Issue:** Build fails with "pod install" error (iOS)
- Solution: `cd ios && pod install && cd ..`
- May need to run `pod repo update` first

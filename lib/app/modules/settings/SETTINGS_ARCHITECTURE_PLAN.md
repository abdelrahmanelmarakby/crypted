# Comprehensive Settings Architecture Plan

## Notification & Privacy Settings Rebuild

---

## Executive Summary

This document outlines the complete architectural plan for rebuilding the Notification Settings and Privacy Settings screens from the ground up, creating a best-in-class implementation with advanced features, perfect integration, and modern UX patterns.

---

## Part 1: Current State Analysis

### 1.1 Notification Settings - Current State

**Current Features:**
- 10 basic boolean settings
- Simple sound selection (string-based)
- Per-category toggles (Message, Group, Status)
- Reminder notifications toggle
- Preview notifications toggle

**Current Gaps:**
- No Do-Not-Disturb (DND) scheduling
- No per-chat notification customization
- No notification batching/digest options
- No vibration pattern selection
- No LED color customization (Android)
- No notification channels (Android)
- No sound preview functionality
- No quiet hours by day of week
- No auto-reply during DND
- No notification history/analytics
- Settings stored but NOT enforced on backend

### 1.2 Privacy Settings - Current State

**Current Features:**
- 15 boolean settings
- Dropdown-based privacy level selection
- Blocked users list (functional)
- Live location tracking list
- Read receipts toggle
- Camera effects toggle

**Current Gaps:**
- No per-contact privacy exceptions ("Everyone except...")
- No privacy checkup wizard
- Settings NOT enforced on backend
- No two-step verification management
- No security audit log
- No device management
- No end-to-end encryption visibility
- No privacy analytics/insights
- No fingerprint/face unlock for chats
- No screenshot blocking enforcement
- No account deletion workflow

---

## Part 2: New Architecture Design

### 2.1 Core Principles

1. **Backend Enforcement**: All settings MUST be enforced server-side, not just stored
2. **Real-time Sync**: Settings sync across devices instantly via Firestore
3. **Modular Design**: Each feature is self-contained and testable
4. **Accessibility First**: Full screen reader and accessibility support
5. **Offline Capable**: Settings work offline with sync on reconnection
6. **Performance Optimized**: Lazy loading, efficient updates

### 2.2 Data Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Firestore Structure                       │
├─────────────────────────────────────────────────────────────────┤
│  users/{userId}/                                                 │
│  ├── notificationSettings: NotificationSettingsModel            │
│  ├── privacySettings: PrivacySettingsModel                      │
│  ├── dndSchedules: Collection<DNDSchedule>                      │
│  ├── chatNotificationOverrides/{chatId}: ChatNotificationOverride│
│  ├── privacyExceptions/{userId}: PrivacyException               │
│  ├── blockedUsers/{userId}: BlockedUserEntry                    │
│  └── securityLog: Collection<SecurityLogEntry>                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Model Hierarchy

```
NotificationSettingsModel (Enhanced)
├── GlobalSettings
│   ├── masterSwitch: bool
│   ├── showPreviews: PreviewLevel (always/whenUnlocked/never)
│   └── notificationGrouping: GroupingStyle
├── MessageNotifications
│   ├── enabled: bool
│   ├── sound: SoundConfig
│   ├── vibration: VibrationPattern
│   ├── ledColor: Color?
│   └── priority: NotificationPriority
├── GroupNotifications
│   ├── enabled: bool
│   ├── sound: SoundConfig
│   ├── vibration: VibrationPattern
│   ├── mentionsOnly: bool
│   └── priority: NotificationPriority
├── StatusNotifications
│   ├── enabled: bool
│   ├── sound: SoundConfig
│   └── contactsOnly: bool
├── CallNotifications
│   ├── ringtone: SoundConfig
│   ├── vibration: VibrationPattern
│   └── silentWhenDND: bool
├── ReactionNotifications
│   ├── messages: bool
│   ├── groups: bool
│   └── stories: bool
├── DNDSettings
│   ├── enabled: bool
│   ├── schedules: List<DNDSchedule>
│   ├── allowExceptions: List<String>
│   ├── autoReply: AutoReplyConfig?
│   └── allowCalls: AllowCallsConfig
└── DigestSettings
    ├── enabled: bool
    ├── frequency: DigestFrequency
    └── deliveryTime: TimeOfDay

PrivacySettingsModel (Enhanced)
├── VisibilitySettings
│   ├── lastSeen: VisibilityLevel + exceptions
│   ├── profilePhoto: VisibilityLevel + exceptions
│   ├── about: VisibilityLevel + exceptions
│   ├── status: VisibilityLevel + exceptions
│   └── onlineStatus: VisibilityLevel + exceptions
├── CommunicationSettings
│   ├── whoCanMessage: VisibilityLevel + exceptions
│   ├── whoCanCall: VisibilityLevel + exceptions
│   ├── whoCanAddToGroups: VisibilityLevel + exceptions
│   └── whoCanSeeTyping: VisibilityLevel + exceptions
├── ContentSettings
│   ├── readReceipts: bool
│   ├── allowScreenshots: bool
│   ├── allowForwarding: bool
│   └── disappearingMessages: DisappearingConfig
├── SecuritySettings
│   ├── twoStepVerification: TwoStepConfig
│   ├── appLock: AppLockConfig
│   ├── chatLock: List<LockedChat>
│   └── biometricEnabled: bool
├── BlockedContacts
│   ├── blockedUsers: List<BlockedUser>
│   └── blockedByMe: List<String>
└── LocationSettings
    ├── liveLocationShares: List<LiveLocationShare>
    └── defaultDuration: Duration
```

---

## Part 3: Feature Specifications

### 3.1 Do-Not-Disturb (DND) System

**Features:**
- Quick toggle for immediate DND
- Multiple schedule support (weekday, weekend, custom)
- Exception list (starred contacts, repeat callers)
- Auto-reply with customizable message
- Allow calls from specific contacts
- Override for urgent messages

**Data Model:**
```dart
class DNDSchedule {
  final String id;
  final String name;
  final bool enabled;
  final List<int> daysOfWeek; // 0-6 (Sun-Sat)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DNDMode mode; // total_silence, alarms_only, priority_only
  final List<String> allowedContacts;
  final bool allowRepeatCallers;
  final String? autoReplyMessage;
}
```

### 3.2 Per-Chat Notification Overrides

**Features:**
- Custom sound per chat/group
- Mute duration options (8h, 1w, always)
- Custom vibration pattern
- Priority level override
- Light color override (Android)

**Data Model:**
```dart
class ChatNotificationOverride {
  final String chatId;
  final bool? enabled; // null = use global
  final SoundConfig? sound;
  final VibrationPattern? vibration;
  final MuteDuration? mutedUntil;
  final NotificationPriority? priority;
  final bool? showPreview;
}
```

### 3.3 Privacy Exceptions System

**Features:**
- "Everyone except..." lists
- "My contacts except..." lists
- "Nobody except..." lists
- Per-setting exception management
- Quick add from contacts

**Data Model:**
```dart
class PrivacyException {
  final String settingKey; // e.g., 'lastSeen', 'profilePhoto'
  final ExceptionType type; // include, exclude
  final List<String> userIds;
  final DateTime createdAt;
}
```

### 3.4 Privacy Checkup Wizard

**Features:**
- Step-by-step privacy review
- Risk assessment score
- Recommendations engine
- One-tap fix for issues
- Progress tracking
- Scheduled reminders

**Flow:**
1. Welcome screen with current score
2. Step 1: Profile visibility review
3. Step 2: Communication settings review
4. Step 3: Security settings review
5. Step 4: Blocked contacts review
6. Step 5: Active sessions review
7. Summary with recommendations

### 3.5 Sound & Vibration Management

**Features:**
- Sound preview before selection
- Custom sound upload
- Vibration pattern selection
- Pattern preview (haptic)
- Volume adjustment
- Test notification button

**Available Patterns:**
- Default, Short, Long, Double, Triple, SOS, Heartbeat, Custom

### 3.6 Security Dashboard

**Features:**
- Two-step verification status
- Active sessions list
- Login activity log
- Security score
- Breach detection alerts
- Device management

---

## Part 4: UI/UX Design

### 4.1 Notification Settings Screen Layout

```
┌────────────────────────────────────────┐
│ ← Notification Settings                │
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │ 🔔 Master Notifications    [====] │ │
│ └────────────────────────────────────┘ │
│                                        │
│ DO NOT DISTURB                         │
│ ┌────────────────────────────────────┐ │
│ │ 🌙 Do Not Disturb         [OFF]   │ │
│ │    Tap to configure schedules      │ │
│ ├────────────────────────────────────┤ │
│ │ 📅 Scheduled                    >  │ │
│ │ 👤 Allowed Contacts             >  │ │
│ │ 💬 Auto-Reply                   >  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ MESSAGE NOTIFICATIONS                  │
│ ┌────────────────────────────────────┐ │
│ │ 💬 Messages               [====]  │ │
│ ├────────────────────────────────────┤ │
│ │ 🔊 Sound               Default >  │ │
│ │ 📳 Vibration           Pattern >  │ │
│ │ ⚡ Priority              High   >  │ │
│ │ 😀 Reactions             [====]   │ │
│ └────────────────────────────────────┘ │
│                                        │
│ GROUP NOTIFICATIONS                    │
│ ┌────────────────────────────────────┐ │
│ │ 👥 Groups                 [====]  │ │
│ ├────────────────────────────────────┤ │
│ │ 🔊 Sound               Chime   >  │ │
│ │ 📳 Vibration           Short   >  │ │
│ │ @ Mentions only          [====]   │ │
│ │ 😀 Reactions             [====]   │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ... (more sections)                    │
└────────────────────────────────────────┘
```

### 4.2 Privacy Settings Screen Layout

```
┌────────────────────────────────────────┐
│ ← Privacy Settings                     │
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │ 🛡️ Privacy Score: 85/100          │ │
│ │ ████████████████░░░░               │ │
│ │ [Run Privacy Checkup]              │ │
│ └────────────────────────────────────┘ │
│                                        │
│ WHO CAN SEE MY PERSONAL INFO          │
│ ┌────────────────────────────────────┐ │
│ │ 👁️ Last Seen        My Contacts > │ │
│ │    Exceptions: 2 people excluded   │ │
│ ├────────────────────────────────────┤ │
│ │ 📷 Profile Photo    Everyone    >  │ │
│ ├────────────────────────────────────┤ │
│ │ ℹ️ About            My Contacts >  │ │
│ ├────────────────────────────────────┤ │
│ │ 🟢 Online Status    Everyone    >  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ WHO CAN CONTACT ME                     │
│ ┌────────────────────────────────────┐ │
│ │ 💬 Messages         Everyone    >  │ │
│ ├────────────────────────────────────┤ │
│ │ 📞 Calls            My Contacts >  │ │
│ ├────────────────────────────────────┤ │
│ │ 👥 Add to Groups    Everyone    >  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ MESSAGES                               │
│ ┌────────────────────────────────────┐ │
│ │ ✓✓ Read Receipts          [====]  │ │
│ │ 📸 Screenshots             [====]  │ │
│ │ ↪️ Allow Forwarding       [====]  │ │
│ │ ⏱️ Disappearing Messages       >  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ SECURITY                               │
│ ┌────────────────────────────────────┐ │
│ │ 🔐 Two-Step Verification   ON   >  │ │
│ │ 🔒 App Lock                OFF  >  │ │
│ │ 💬 Chat Lock                    >  │ │
│ │ 📱 Active Sessions          3   >  │ │
│ └────────────────────────────────────┘ │
│                                        │
│ BLOCKED CONTACTS                       │
│ ┌────────────────────────────────────┐ │
│ │ 🚫 Blocked Users            5   >  │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

### 4.3 Privacy Exception Selection UI

```
┌────────────────────────────────────────┐
│ ← Last Seen                            │
├────────────────────────────────────────┤
│ Who can see my last seen?              │
│                                        │
│ ┌──────────────────────────────────┐   │
│ │ ○ Everyone                       │   │
│ │ ● My Contacts                    │   │
│ │ ○ My Contacts Except...          │   │
│ │ ○ Nobody                         │   │
│ └──────────────────────────────────┘   │
│                                        │
│ ───────── EXCEPTIONS ─────────         │
│                                        │
│ ┌──────────────────────────────────┐   │
│ │ + Add contacts to always show    │   │
│ │   (These contacts will always    │   │
│ │   see your last seen)            │   │
│ └──────────────────────────────────┘   │
│                                        │
│ ┌──────────────────────────────────┐   │
│ │ + Add contacts to never show     │   │
│ │   (These contacts will never     │   │
│ │   see your last seen)            │   │
│ └──────────────────────────────────┘   │
│                                        │
│ Currently excluded: 2                  │
│ ┌──────────────────────────────────┐   │
│ │ [👤] John Doe              [×]   │   │
│ │ [👤] Jane Smith            [×]   │   │
│ └──────────────────────────────────┘   │
└────────────────────────────────────────┘
```

---

## Part 5: Implementation Plan

### Phase 1: Core Infrastructure (Week 1)
1. Create enhanced data models
2. Implement settings repository with Firestore sync
3. Create settings service with backend enforcement hooks
4. Set up notification channels (Android)
5. Create base settings widgets

### Phase 2: Notification Settings (Week 2)
1. Implement DND system with scheduling
2. Create sound/vibration management
3. Build per-chat override system
4. Implement notification preview
5. Create notification settings UI

### Phase 3: Privacy Settings (Week 3)
1. Implement privacy exception system
2. Create visibility level management
3. Build security settings
4. Implement blocked users management
5. Create privacy settings UI

### Phase 4: Advanced Features (Week 4)
1. Create Privacy Checkup wizard
2. Implement security dashboard
3. Add notification digest system
4. Create settings backup/restore
5. Add analytics and insights

### Phase 5: Polish & Integration (Week 5)
1. Backend enforcement integration
2. Cross-device sync testing
3. Accessibility audit
4. Performance optimization
5. Final UI polish

---

## Part 6: File Structure

```
lib/app/modules/settings_v2/
├── core/
│   ├── models/
│   │   ├── notification_settings_model.dart
│   │   ├── privacy_settings_model.dart
│   │   ├── dnd_schedule_model.dart
│   │   ├── chat_notification_override.dart
│   │   ├── privacy_exception_model.dart
│   │   └── security_settings_model.dart
│   ├── services/
│   │   ├── notification_settings_service.dart
│   │   ├── privacy_settings_service.dart
│   │   ├── dnd_service.dart
│   │   ├── sound_service.dart
│   │   └── settings_sync_service.dart
│   ├── repositories/
│   │   ├── notification_repository.dart
│   │   ├── privacy_repository.dart
│   │   └── settings_repository.dart
│   └── constants/
│       ├── notification_constants.dart
│       └── privacy_constants.dart
├── notifications/
│   ├── bindings/
│   │   └── notification_settings_binding.dart
│   ├── controllers/
│   │   └── notification_settings_controller.dart
│   ├── views/
│   │   ├── notification_settings_view.dart
│   │   ├── dnd_settings_view.dart
│   │   ├── sound_picker_view.dart
│   │   └── per_chat_settings_view.dart
│   └── widgets/
│       ├── notification_section.dart
│       ├── sound_preview_tile.dart
│       ├── vibration_picker.dart
│       ├── dnd_schedule_card.dart
│       └── notification_toggle.dart
├── privacy/
│   ├── bindings/
│   │   └── privacy_settings_binding.dart
│   ├── controllers/
│   │   └── privacy_settings_controller.dart
│   ├── views/
│   │   ├── privacy_settings_view.dart
│   │   ├── privacy_checkup_view.dart
│   │   ├── blocked_users_view.dart
│   │   ├── security_dashboard_view.dart
│   │   └── visibility_settings_view.dart
│   └── widgets/
│       ├── privacy_score_card.dart
│       ├── visibility_selector.dart
│       ├── exception_list.dart
│       ├── security_item.dart
│       └── blocked_user_tile.dart
└── shared/
    ├── widgets/
    │   ├── settings_section.dart
    │   ├── settings_tile.dart
    │   ├── settings_switch.dart
    │   ├── settings_dropdown.dart
    │   └── settings_header.dart
    └── utils/
        ├── settings_validators.dart
        └── settings_formatters.dart
```

---

## Part 7: Backend Enforcement Points

### 7.1 Notification Enforcement

```dart
// When sending notification
Future<void> sendNotification(String userId, NotificationPayload payload) async {
  final settings = await settingsService.getNotificationSettings(userId);

  // Check master switch
  if (!settings.masterSwitch) return;

  // Check DND
  if (await dndService.isInDND(userId)) {
    if (!payload.isFromAllowedContact) return;
  }

  // Check per-chat overrides
  final override = await settingsService.getChatOverride(userId, payload.chatId);
  if (override?.enabled == false) return;

  // Check category settings
  if (!_checkCategoryEnabled(settings, payload.type)) return;

  // Send with appropriate priority/sound
  await _sendWithSettings(userId, payload, settings, override);
}
```

### 7.2 Privacy Enforcement

```dart
// When querying user data
Future<UserVisibility> getUserVisibility(
  String requesterId,
  String targetUserId,
  VisibilityField field,
) async {
  final settings = await settingsService.getPrivacySettings(targetUserId);
  final level = settings.getVisibilityLevel(field);

  // Check exceptions first
  final exceptions = await settingsService.getExceptions(targetUserId, field);
  if (exceptions.included.contains(requesterId)) {
    return UserVisibility.visible;
  }
  if (exceptions.excluded.contains(requesterId)) {
    return UserVisibility.hidden;
  }

  // Apply level logic
  switch (level) {
    case VisibilityLevel.everyone:
      return UserVisibility.visible;
    case VisibilityLevel.contacts:
      return await _isContact(targetUserId, requesterId)
          ? UserVisibility.visible
          : UserVisibility.hidden;
    case VisibilityLevel.nobody:
      return UserVisibility.hidden;
  }
}
```

---

## Part 8: Migration Strategy

### 8.1 Data Migration

```dart
class SettingsMigrator {
  Future<void> migrateNotificationSettings(String userId) async {
    // 1. Read old settings
    final oldSettings = await _readOldNotificationSettings(userId);

    // 2. Convert to new format
    final newSettings = NotificationSettingsModel(
      globalSettings: GlobalSettings(
        masterSwitch: true,
        showPreviews: PreviewLevel.whenUnlocked,
      ),
      messageNotifications: MessageNotificationSettings(
        enabled: oldSettings.showMessageNotification,
        sound: SoundConfig(name: oldSettings.soundMessage),
        // ... map other fields
      ),
      // ... other mappings
    );

    // 3. Write new settings
    await _writeNewNotificationSettings(userId, newSettings);

    // 4. Mark as migrated
    await _markMigrated(userId, 'notification_settings', 2);
  }
}
```

### 8.2 Backward Compatibility

- Keep old API endpoints working during transition
- Dual-write to both old and new collections during migration period
- Gradual rollout with feature flags
- Fallback to old UI if issues detected

---

## Part 9: Testing Strategy

### 9.1 Unit Tests
- Model serialization/deserialization
- Settings validation logic
- DND schedule matching
- Privacy level calculations

### 9.2 Integration Tests
- Firestore sync functionality
- Backend enforcement
- Cross-device consistency

### 9.3 UI Tests
- Screen navigation
- Settings persistence
- Accessibility compliance

---

## Part 10: Success Metrics

1. **User Engagement**: 40% increase in settings customization
2. **Support Tickets**: 50% reduction in privacy-related issues
3. **Retention**: Improved user retention due to better control
4. **Performance**: Settings load in < 200ms
5. **Sync Latency**: Cross-device sync in < 2 seconds

---

## Appendix A: Sound Options

```dart
enum NotificationSound {
  none,
  default_sound,
  chime,
  ding,
  pop,
  swoosh,
  bell,
  note,
  crystal,
  bubble,
  // ... more options
}
```

## Appendix B: Vibration Patterns

```dart
enum VibrationPattern {
  none,
  short,      // [100]
  medium,     // [200]
  long_,      // [400]
  double_,    // [100, 100, 100]
  triple,     // [100, 100, 100, 100, 100]
  heartbeat,  // [100, 100, 300]
  sos,        // [100, 100, 100, 100, 100, 100, 300, 300, 300, 100, 100, 100]
  custom,     // User-defined
}
```

## Appendix C: Privacy Levels

```dart
enum VisibilityLevel {
  everyone,
  contactsExcept,  // Contacts minus exclusions
  contacts,
  contactsPlus,    // Contacts plus inclusions
  nobody,
}
```

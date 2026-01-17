# Crypted Features Analysis & Implementation Plan

> **Document Version:** 1.0
> **Analysis Date:** January 2026
> **Scope:** Notification Settings, Privacy Settings, Other User Info, Group Info

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Feature Analysis Overview](#feature-analysis-overview)
3. [Notification Settings Analysis](#1-notification-settings-analysis)
4. [Privacy Settings Analysis](#2-privacy-settings-analysis)
5. [Other User Info Analysis](#3-other-user-info-analysis)
6. [Group Info Analysis](#4-group-info-analysis)
7. [Cross-Cutting Concerns](#5-cross-cutting-concerns)
8. [Implementation Plan](#6-implementation-plan)
9. [Risk Assessment](#7-risk-assessment)
10. [Appendix](#appendix)

---

## Executive Summary

### Current State Assessment

| Feature | Completion | UX Score | Architecture | Code Quality | Priority |
|---------|------------|----------|--------------|--------------|----------|
| Notification Settings | 65% | ⚠️ Medium | ❌ Dual Systems | ⚠️ Mixed | **HIGH** |
| Privacy Settings | 70% | ✅ Good | ✅ Good | ✅ Good | **HIGH** |
| Other User Info | 75% | ✅ Good | ✅ Good | ✅ Good | **MEDIUM** |
| Group Info | 55% | ⚠️ Medium | ❌ Duplicated | ⚠️ Mixed | **HIGH** |

### Critical Issues Summary

1. **Dual System Architecture** - Both notification and group info have two competing implementations
2. **Missing Route Registrations** - Enhanced modules not exposed in app routes
3. **No Backend Enforcement** - Privacy settings not enforced server-side
4. **Platform Inconsistencies** - Android-specific code paths, iOS features incomplete
5. **Disconnected Logic** - Advanced services built but not integrated into app flow

### Estimated Effort

| Phase | Description | Effort |
|-------|-------------|--------|
| Phase 1 | Critical Fixes & Route Integration | 40 hours |
| Phase 2 | Backend Enforcement & Security | 60 hours |
| Phase 3 | Platform Parity & Polish | 35 hours |
| Phase 4 | Feature Completion | 45 hours |
| **Total** | | **180 hours** |

---

## Feature Analysis Overview

### Architecture Diagram (Current State)

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP ROUTES                               │
├─────────────────────────────────────────────────────────────────┤
│ /notifications → NotificationsView (LEGACY)                      │
│ /privacy → PrivacyView (LEGACY)                                  │
│ /contact-info → ContactInfoView (BASIC)                          │
│ /group-info → GroupInfoView (LEGACY)                             │
│                                                                   │
│ ❌ NotificationSettingsView (settings_v2) - NOT REGISTERED       │
│ ❌ PrivacySettingsView (settings_v2) - NOT REGISTERED            │
│ ❌ OtherUserInfoView (user_info) - NOT REGISTERED                │
│ ❌ GroupInfoView (user_info) - NOT REGISTERED                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DUAL IMPLEMENTATIONS                        │
├──────────────────────────┬──────────────────────────────────────┤
│     LEGACY (Active)      │         MODERN (Unused)              │
├──────────────────────────┼──────────────────────────────────────┤
│ NotificationsController  │ NotificationSettingsService          │
│ PrivacyController        │ PrivacySettingsService               │
│ ContactInfoController    │ OtherUserInfoController              │
│ GroupInfoController      │ EnhancedGroupInfoController          │
└──────────────────────────┴──────────────────────────────────────┘
```

---

## 1. Notification Settings Analysis

### 1.1 Current Implementation Status

#### Files Structure

```
Legacy System:
├── lib/app/modules/notifications/
│   ├── controllers/notifications_controller.dart
│   ├── views/notifications_view.dart
│   └── bindings/notifications_binding.dart
├── lib/app/data/models/notification_model.dart
└── lib/app/data/data_source/notification_data_source.dart

Modern System (settings_v2):
├── lib/app/modules/settings_v2/notifications/
│   ├── controllers/notification_settings_controller.dart
│   ├── views/notification_settings_view.dart
│   └── bindings/notification_settings_binding.dart
├── lib/app/modules/settings_v2/core/services/
│   └── notification_settings_service.dart
├── lib/app/modules/settings_v2/core/repositories/
│   └── notification_settings_repository.dart
└── lib/app/modules/settings_v2/core/models/
    └── notification_settings_model.dart
```

#### Feature Matrix

| Feature | Legacy | Modern | Status |
|---------|--------|--------|--------|
| Master Enable/Disable | ✅ | ✅ | Duplicated |
| Message Notifications | ✅ | ✅ | Duplicated |
| Group Notifications | ✅ | ✅ | Duplicated |
| Status Notifications | ✅ | ✅ | Duplicated |
| Call Notifications | ❌ | ✅ | Modern only |
| Reminder Notifications | ❌ | ✅ | Modern only |
| Sound Selection | Basic | 13 options | Modern better |
| Vibration Patterns | ❌ | 9 options | Modern only |
| Do Not Disturb | ❌ | ✅ Schedule | Modern only |
| Per-Chat Overrides | Basic | Advanced | Modern better |
| Notification Grouping | ❌ | ✅ | Modern only |
| Preview Level | ❌ | ✅ | Modern only |
| Badge Count | ❌ | ✅ | Modern only |
| In-App Sounds | ❌ | ✅ | Modern only |
| Priority Levels | ❌ | 4 levels | Modern only |
| **Route Registered** | ✅ | ❌ | **CRITICAL** |

### 1.2 UX Issues

#### 1.2.1 Critical UX Problems

| Issue | Description | Impact |
|-------|-------------|--------|
| **Sound Preview Not Working** | Controller has TODO on line 185 | Users can't hear sounds before selecting |
| **Vibration Preview Missing** | Controller has TODO on line 196 | Users can't feel patterns before selecting |
| **No Visual DND Indicator** | No system-wide indicator when DND active | Users confused why notifications missing |
| **Per-Chat Override Hidden** | No UI to configure per-chat settings | Advanced feature unusable |
| **No Quick Mute Access** | Must navigate deep to mute a chat | Poor discoverability |

#### 1.2.2 UX Recommendations

```
BEFORE (Current Flow):
Home → Settings → Notifications → Basic toggles

AFTER (Recommended Flow):
1. Quick Actions:
   Chat Screen → Long Press → Quick Mute (1h/8h/24h/Forever)

2. Full Settings:
   Settings → Notifications → [Category Tabs]
   ├── General (master switch, badge, grouping)
   ├── Messages (per-type settings)
   ├── Groups (per-type settings)
   ├── Calls (ringtones, vibration)
   ├── Do Not Disturb (schedule, exceptions)
   └── Per-Chat (list with search)
```

### 1.3 Architecture Issues

#### 1.3.1 Dual Storage Backend (CRITICAL)

```dart
// PROBLEM: Two different storage mechanisms

// Legacy (GetStorage - local only)
class NotificationCustomizationService {
  static const String _keyPrefix = 'notif_settings_';
  final _storage = GetStorage();
  // Data stored locally, no sync
}

// Modern (Firestore - cloud sync)
class NotificationSettingsService {
  final _repository = FirestoreNotificationSettingsRepository();
  // Data stored in cloud, syncs across devices
}
```

**Impact:**
- Settings don't sync between devices
- Migration path undefined
- Potential data conflicts

#### 1.3.2 Disconnected Decision Logic (CRITICAL)

```dart
// SERVICE HAS ADVANCED LOGIC:
class NotificationSettingsService {
  NotificationDecision shouldDeliverNotification({...}) {
    // Checks: master switch, DND, category, chat mute, etc.
    // Returns: NotificationDecision with blocking reason
  }
}

// BUT FCM SERVICE DOESN'T USE IT:
class FCMService {
  void _handleForegroundMessage(RemoteMessage message) {
    // Directly shows notification without checking settings!
    _showLocalNotification(message);
  }
}
```

### 1.4 Code Quality Issues

| Issue | Location | Severity |
|-------|----------|----------|
| Hardcoded strings | Multiple views | Medium |
| Missing error handling | Legacy controller | Medium |
| No input validation | Sound selection | Low |
| Print statements | Legacy data source | Low |
| Missing documentation | Service layer | Low |

### 1.5 Firebase Integration Issues

#### 1.5.1 Firestore Structure

```
Current:
users/{userId}/settings/notifications (modern)
  ├── globalSettings: {...}
  ├── categorySettings: {...}
  └── chatOverrides/{chatId}: {...}

Legacy uses: GetStorage (local)

ISSUE: No migration between systems
```

#### 1.5.2 Missing Backend Push Logic

```
PROBLEM: No Cloud Functions for notification sending

Current Flow:
User A sends message → Saves to Firestore → ???
(No trigger to send FCM to User B)

Required Flow:
User A sends message → Saves to Firestore
                     → Cloud Function triggered
                     → Checks User B's notification settings
                     → Sends FCM if allowed
```

### 1.6 Platform Compatibility Issues

#### Android

| Feature | Status | Issue |
|---------|--------|-------|
| Notification Channels | ✅ Working | 4 channels configured |
| Notification Sounds | ⚠️ Partial | Only 3 sounds exist (13 in model) |
| Vibration Patterns | ❌ Missing | No platform integration |
| LED Colors | ❌ Missing | Model supports, not implemented |
| Heads-up Display | ✅ Working | Via channel importance |
| Badge Count | ✅ Working | Via flutter_local_notifications |

**Missing Sound Files:**
```
Required: chime, ding, pop, swoosh, bell, note, crystal,
          bubble, droplet, bamboo, chord, ping
Existing: call.mp3, missed_call.mp3, zego_incoming.mp3
```

#### iOS

| Feature | Status | Issue |
|---------|--------|-------|
| APNs Integration | ✅ Working | Via firebase_messaging |
| Background Modes | ✅ Configured | voip, remote-notification, fetch |
| Notification Categories | ❌ Missing | No UNNotificationCategory setup |
| Critical Alerts | ❌ Missing | Not configured in Info.plist |
| Sound Files | ❌ Missing | No iOS sound resources |
| Notification Grouping | ❌ Missing | threadIdentifier not set |

### 1.7 Notification Settings Fixes Required

```
Priority 1 (Critical):
□ Register modern NotificationSettingsView route
□ Integrate NotificationDecision logic into FCM service
□ Create Cloud Function for push notification delivery
□ Migrate from GetStorage to Firestore

Priority 2 (High):
□ Add missing notification sound files (10 sounds)
□ Implement sound preview with just_audio
□ Implement vibration preview with vibration package
□ Add iOS notification categories

Priority 3 (Medium):
□ Add per-chat quick mute UI
□ Implement DND schedule enforcement
□ Add system-wide DND indicator
□ Unify storage backend

Priority 4 (Low):
□ Add notification history view
□ Implement LED color support
□ Add critical alerts for iOS
```

---

## 2. Privacy Settings Analysis

### 2.1 Current Implementation Status

#### Files Structure

```
Legacy System:
├── lib/app/modules/privacy/
│   ├── controllers/privacy_controller.dart
│   ├── views/privacy_view.dart
│   └── bindings/privacy_binding.dart
├── lib/app/data/models/privacy_model.dart
└── lib/app/data/data_source/privacy_data_source.dart

Modern System (settings_v2):
├── lib/app/modules/settings_v2/privacy/
│   ├── controllers/privacy_settings_controller.dart
│   ├── views/privacy_settings_view.dart
│   └── bindings/privacy_settings_binding.dart
├── lib/app/modules/settings_v2/core/services/
│   └── privacy_settings_service.dart (868 lines)
├── lib/app/modules/settings_v2/core/repositories/
│   └── privacy_settings_repository.dart (427 lines)
└── lib/app/modules/settings_v2/core/models/
    └── privacy_settings_model.dart (1131 lines)
```

#### Feature Matrix

| Feature | Legacy | Modern | Status |
|---------|--------|--------|--------|
| Last Seen Visibility | Basic | 5 levels + exceptions | Modern better |
| Profile Photo Visibility | Basic | 5 levels + exceptions | Modern better |
| About/Bio Visibility | ❌ | 5 levels + exceptions | Modern only |
| Online Status Visibility | ❌ | 5 levels + exceptions | Modern only |
| Status Updates Visibility | ❌ | 5 levels + exceptions | Modern only |
| Who Can Message | ❌ | 3 levels + exceptions | Modern only |
| Who Can Call | ❌ | 3 levels + exceptions | Modern only |
| Who Can Add to Groups | ❌ | 3 levels + exceptions | Modern only |
| Read Receipts | ✅ | ✅ | Both |
| Typing Indicators | ❌ | ✅ | Modern only |
| Screenshot Prevention | ❌ | ✅ | Modern only |
| Message Forwarding | ❌ | ✅ | Modern only |
| Disappearing Messages | ❌ | 5 durations | Modern only |
| Two-Factor Auth | ❌ | ✅ | Modern only |
| App Lock | ❌ | ✅ + Biometric | Modern only |
| Blocked Users List | ✅ | ✅ Enhanced | Modern better |
| Privacy Checkup | ❌ | ✅ Score + Fixes | Modern only |
| Security Audit Log | ❌ | ✅ | Modern only |
| **Route Registered** | ✅ | ❌ | **CRITICAL** |

### 2.2 UX Issues

#### 2.2.1 Critical UX Problems

| Issue | Description | Impact |
|-------|-------------|--------|
| **Exception Lists Not Editable** | UI shows levels but no way to add exceptions | Feature unusable |
| **No Privacy Checkup UI** | Service calculates score, no view to show it | Feature hidden |
| **No Security Log View** | Audit log captured but not displayed | User can't review |
| **App Lock Not Functional** | Model exists but no biometric integration | Security feature broken |
| **No Block Feedback** | User blocked but no confirmation in chat | Confusing experience |

#### 2.2.2 Privacy Exception List UI (Missing)

```
Current State:
┌─────────────────────────────────┐
│ Last Seen                       │
│ ○ Everyone                      │
│ ● My Contacts                   │  ← Selected
│ ○ My Contacts Except...         │  ← Can't add exceptions!
│ ○ Nobody                        │
│ ○ Nobody Except...              │  ← Can't add exceptions!
└─────────────────────────────────┘

Required State:
┌─────────────────────────────────┐
│ Last Seen                       │
│ ○ Everyone                      │
│ ● My Contacts                   │
│ ○ My Contacts Except...   [>]   │ → Opens contact picker
│ ○ Nobody                        │
│ ○ Nobody Except...        [>]   │ → Opens contact picker
└─────────────────────────────────┘
```

### 2.3 Architecture Issues

#### 2.3.1 No Backend Privacy Enforcement (CRITICAL SECURITY)

```dart
// CLIENT-SIDE ONLY:
class PrivacySettingsService {
  VisibilityDecision canSeeProfileField({
    required String viewerId,
    required VisibilitySettingWithExceptions setting,
    required bool isContact,
  }) {
    // Returns visibility decision
    // BUT THIS IS ONLY CHECKED CLIENT-SIDE!
  }
}

// FIRESTORE RULES DON'T CHECK PRIVACY:
match /users/{userId} {
  allow read: if isAuthenticated();  // Anyone can read any profile!
  // NO CHECK: Is viewer blocked?
  // NO CHECK: Can viewer see last seen?
  // NO CHECK: Can viewer see profile photo?
}
```

**Security Impact:**
- Blocked users can still see profiles via direct Firestore access
- Privacy settings are "honor system" only
- Malicious clients can bypass all privacy

#### 2.3.2 Read Receipt/Presence Not Privacy-Aware

```dart
// ReadReceiptService - IGNORES privacy settings:
class ReadReceiptService {
  void markAsRead(String roomId, String messageId) {
    // Records read receipt regardless of user's
    // "show read receipts" setting!
  }
}

// PresenceService - IGNORES privacy settings:
class PresenceService {
  void updatePresence() {
    // Updates lastSeen regardless of user's
    // "last seen visibility" setting!
  }
}
```

### 2.4 Code Quality Issues

| Issue | Location | Severity |
|-------|----------|----------|
| Model too large | privacy_settings_model.dart (1131 lines) | Medium |
| Service too large | privacy_settings_service.dart (868 lines) | Medium |
| No unit tests | All privacy code | High |
| Default too permissive | Everyone can see/message by default | Medium |
| Missing validation | Exception list entries | Low |

### 2.5 Firebase Security Rules Analysis

#### Current Rules (INSUFFICIENT)

```javascript
// firestore.rules - CURRENT:
match /users/{userId} {
  allow read: if isAuthenticated();  // ❌ No privacy check
  allow update: if isOwner(userId);
}

// MISSING RULES:
// - Check if viewer is blocked before returning user data
// - Validate privacy level before returning fields
// - Enforce "who can message" before allowing message send
```

#### Required Cloud Functions

```javascript
// Required: Privacy-aware user data retrieval
exports.getUserProfile = functions.https.onCall(async (data, context) => {
  const viewerId = context.auth.uid;
  const targetUserId = data.userId;

  // 1. Check if viewer is blocked
  const targetPrivacy = await getPrivacySettings(targetUserId);
  if (targetPrivacy.blockedUsers.includes(viewerId)) {
    throw new functions.https.HttpsError('permission-denied', 'User not found');
  }

  // 2. Filter fields based on privacy settings
  const profile = await getUserProfile(targetUserId);
  return filterByPrivacy(profile, targetPrivacy, viewerId);
});
```

### 2.6 Platform Compatibility Issues

#### Android

| Feature | Status | Issue |
|---------|--------|-------|
| App Lock UI | ❌ Missing | No activity for PIN/pattern |
| Biometric Auth | ❌ Missing | local_auth not integrated |
| Screenshot Prevention | ⚠️ Partial | FLAG_SECURE not set |
| Screen Recording Block | ❌ Missing | Not implemented |

#### iOS

| Feature | Status | Issue |
|---------|--------|-------|
| App Lock UI | ❌ Missing | No view controller |
| Face ID / Touch ID | ❌ Missing | local_auth not integrated |
| Screenshot Prevention | ⚠️ Partial | UITextField.isSecureTextEntry |
| Blur in App Switcher | ❌ Missing | Model supports, not implemented |

### 2.7 Privacy Settings Fixes Required

```
Priority 1 (Critical - Security):
□ Implement Cloud Functions for privacy-aware data access
□ Update Firestore rules to check blocking
□ Integrate privacy checks into ReadReceiptService
□ Integrate privacy checks into PresenceService

Priority 2 (High):
□ Add exception list editing UI
□ Implement App Lock with biometric
□ Add Privacy Checkup view with score
□ Create Security Audit Log viewer

Priority 3 (Medium):
□ Implement screenshot prevention
□ Add app switcher blur
□ Create blocked user feedback in chat
□ Implement disappearing messages countdown

Priority 4 (Low):
□ Add privacy level quick preview
□ Implement security event push notifications
□ Add two-factor auth setup flow
```

---

## 3. Other User Info Analysis

### 3.1 Current Implementation Status

#### Files Structure

```
Legacy System (Active in Routes):
├── lib/app/modules/contactInfo/
│   ├── controllers/contact_info_controller.dart (1228 lines)
│   ├── views/contact_info_view.dart
│   ├── bindings/contact_info_binding.dart
│   └── widgets/
│       ├── profile_header_contact.dart
│       ├── status_section.dart
│       ├── contact_details_section.dart
│       ├── custom_notification_theme_section.dart
│       ├── custom_privacy_section_contact.dart
│       └── contact_extras_section.dart

Modern System (Not Registered):
├── lib/app/modules/user_info/
│   ├── controllers/other_user_info_controller.dart (494 lines)
│   ├── views/other_user_info_view.dart
│   ├── bindings/other_user_info_binding.dart
│   ├── repositories/user_info_repository.dart
│   ├── models/user_info_state.dart
│   └── widgets/
│       ├── user_info_header.dart
│       ├── user_info_section.dart
│       └── user_info_action_tile.dart
```

#### Feature Matrix

| Feature | ContactInfo (Legacy) | UserInfo (Modern) | Status |
|---------|---------------------|-------------------|--------|
| View Profile | ✅ | ✅ | Both |
| Block/Unblock | ✅ Basic | ✅ Enhanced | Modern better |
| Report User | ❌ | ✅ 5 categories | Modern only |
| Mute Notifications | ✅ | ✅ | Both |
| Archive Chat | ❌ | ✅ | Modern only |
| Favorite Contact | ✅ | ✅ | Both |
| Clear Chat | ✅ | ✅ | Both |
| View Shared Media | ✅ Inline | Routes to screen | Legacy has UI |
| View Starred Messages | ✅ Inline | Routes to screen | Legacy has UI |
| Export Chat | ✅ | ❌ | Legacy only |
| Mutual Contacts | ❌ | ✅ | Modern only |
| Online Status | ⚠️ Basic | ✅ Real-time | Modern better |
| Media Counts | ❌ | ✅ | Modern only |
| Edit Own Bio | ✅ | ❌ | Legacy only |
| Voice/Video Call | ✅ | ✅ | Both |
| Repository Pattern | ❌ | ✅ | Modern better |
| Testable Architecture | ❌ | ✅ | Modern better |
| **Route Registered** | ✅ | ❌ | **CRITICAL** |

### 3.2 UX Issues

#### 3.2.1 Critical UX Problems

| Issue | Description | Impact |
|-------|-------------|--------|
| **Missing Routes** | Routes.MEDIA_GALLERY, Routes.STARRED_MESSAGES undefined | Navigation crashes |
| **No Block Confirmation** | User blocked without clear feedback | Confusing |
| **Report Categories Hidden** | Modern has 5 categories, legacy has none | Incomplete reporting |
| **Monolithic Controller** | Legacy has 1228 lines in one file | Maintenance nightmare |
| **Inline vs Routed Media** | Legacy shows inline, modern routes (route missing) | Inconsistent |

#### 3.2.2 Information Architecture

```
Current (ContactInfo - Legacy):
┌──────────────────────────────────┐
│ [Avatar] Name                    │
│ Status: Online                   │
├──────────────────────────────────┤
│ Bio Section                      │
│ "User's bio text here"           │
├──────────────────────────────────┤
│ Media, Links, Documents          │ → Inline bottom sheet
│ Starred Messages                 │ → Inline bottom sheet
├──────────────────────────────────┤
│ Mute │ Custom │ Wallpaper        │ ← Unclear purpose
├──────────────────────────────────┤
│ Block │ Report │ Clear Chat      │
└──────────────────────────────────┘

Recommended (Consolidated):
┌──────────────────────────────────┐
│ [Avatar] Name                    │
│ ● Online                         │
│ [Message] [Call] [Video]         │ ← Quick actions
├──────────────────────────────────┤
│ Bio                              │
│ "User's bio text here"           │
├──────────────────────────────────┤
│ Contact Info                     │
│ 📱 +1 234 567 8900               │
│ 📧 user@email.com                │
├──────────────────────────────────┤
│ Shared Content                   │
│ 📷 Photos (23) │ 🎬 Videos (5)   │ → Navigate to gallery
│ 📄 Files (12)  │ 🔗 Links (8)    │
├──────────────────────────────────┤
│ 👥 3 Mutual Contacts             │ → Navigate to list
├──────────────────────────────────┤
│ Chat Options                     │
│ 🔔 Mute Notifications      [Off] │
│ ⭐ Add to Favorites        [On]  │
│ 📦 Archive Chat            [Off] │
├──────────────────────────────────┤
│ ⚠️ Danger Zone                   │
│ 🚫 Block User                    │
│ 🚩 Report User                   │
│ 🗑️ Clear Chat                    │
└──────────────────────────────────┘
```

### 3.3 Architecture Issues

#### 3.3.1 Module Duplication

```
PROBLEM: Two separate modules for same functionality

contactInfo/              user_info/
├── Controller (1228 ln)  ├── Controller (494 ln)
├── View                  ├── View
├── 7 Widgets             ├── 3 Shared Widgets
└── Direct Firestore      └── Repository Pattern

RECOMMENDATION: Migrate to user_info, deprecate contactInfo
```

#### 3.3.2 Missing Routes (CRITICAL)

```dart
// Referenced in controllers but NOT defined:

// other_user_info_controller.dart:432
Get.toNamed(Routes.MEDIA_GALLERY);  // ❌ Route doesn't exist

// other_user_info_controller.dart:441
Get.toNamed(Routes.STARRED_MESSAGES);  // ❌ Route doesn't exist

// enhanced_group_info_controller.dart:501
Get.toNamed(Routes.OTHER_USER_INFO);  // ❌ Route doesn't exist
```

### 3.4 Code Quality Issues

| Issue | Location | Severity |
|-------|----------|----------|
| Monolithic controller | contact_info_controller.dart (1228 lines) | High |
| Direct Firestore in controller | contact_info_controller.dart | Medium |
| Magic strings | Multiple locations | Medium |
| Missing null safety | contact_info_controller.dart:937 | Medium |
| Print statements | Legacy controller | Low |

#### Code Example (Problem)

```dart
// contact_info_controller.dart - Line 937 (BUG):
bool get isGroupContact {
  if (members.value == null || members.value!.isEmpty) return false;
  return members.value!.first.uid == currentUser?.uid;
}
// ISSUE: Uses 'members' for group check, but property doesn't exist
// Should use 'isGroup.value' instead
```

### 3.5 Firebase Integration Issues

#### 3.5.1 Inconsistent Data Access

```dart
// Legacy - Direct Firestore:
class ContactInfoController {
  void clearChat() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(roomId)
        .collection('chat')
        .get()
        .then((snapshot) {
          // Direct access, no abstraction
        });
  }
}

// Modern - Repository Pattern:
class OtherUserInfoController {
  final UserInfoRepository repository;

  void clearChat() {
    repository.clearChat(roomId);  // Abstracted, testable
  }
}
```

### 3.6 Chat Integration Issues

| Issue | Description | Impact |
|-------|-------------|--------|
| Block not reflected | Blocked user can still see chat history | Privacy leak |
| Mute not instant | Mute status requires app restart | Poor UX |
| Clear chat incomplete | Doesn't clear media from storage | Storage waste |
| No "block from chat" | Must navigate to contact info to block | Extra steps |

### 3.7 Platform Compatibility Issues

#### File Download (Android Only Bug)

```dart
// contact_info_controller.dart - Line 1211:
Future<void> _downloadFile(String url, String fileName) async {
  final appDir = '/storage/emulated/0/Download';  // ❌ Android hardcoded!
  // iOS will crash or save to wrong location
}

// Should use:
final directory = await getApplicationDocumentsDirectory();
// Or for downloads:
final directory = await getDownloadsDirectory();  // Android only
// iOS: Use share sheet instead
```

### 3.8 Other User Info Fixes Required

```
Priority 1 (Critical):
□ Add Routes.OTHER_USER_INFO to app_routes.dart
□ Add Routes.MEDIA_GALLERY to app_routes.dart
□ Add Routes.STARRED_MESSAGES to app_routes.dart
□ Register OtherUserInfoBinding in app_pages.dart

Priority 2 (High):
□ Create MediaGalleryView with tabs
□ Create StarredMessagesView
□ Fix file download path for iOS
□ Add report user functionality to legacy (or migrate)

Priority 3 (Medium):
□ Consolidate contactInfo into user_info module
□ Add block confirmation dialog
□ Implement real-time online status
□ Add mutual contacts display

Priority 4 (Low):
□ Refactor legacy controller into smaller pieces
□ Add export chat to modern module
□ Implement edit bio in modern module
```

---

## 4. Group Info Analysis

### 4.1 Current Implementation Status

#### Files Structure

```
Legacy System (Active in Routes):
├── lib/app/modules/group_info/
│   ├── controllers/group_info_controller.dart (1285 lines)
│   ├── views/group_info_view.dart
│   ├── bindings/group_info_binding.dart
│   └── widgets/ (12 files)
│       ├── profile_header.dart
│       ├── group_member_item.dart
│       ├── item_group_member.dart  ← Duplicate!
│       ├── group_details_section.dart
│       ├── group_actions_section.dart
│       ├── group_media_item.dart
│       ├── group_media_controlls.dart
│       ├── custom_info_item.dart
│       ├── custom_icon_circle.dart
│       ├── custom_reactive_switch_item.dart
│       ├── group_danger_option.dart
│       └── group_loading_view.dart

Modern System (Not Registered):
├── lib/app/modules/user_info/
│   ├── controllers/enhanced_group_info_controller.dart (525 lines)
│   ├── views/group_info_view.dart
│   ├── bindings/group_info_binding.dart
│   ├── repositories/group_info_repository.dart
│   ├── models/group_info_state.dart
│   └── widgets/ (shared with user_info)
```

#### Feature Matrix

| Feature | Legacy | Modern | Status |
|---------|--------|--------|--------|
| View Group Info | ✅ | ✅ | Both |
| Edit Group Name | ✅ | ✅ | Both |
| Edit Group Description | ✅ | ✅ | Both |
| Edit Group Image | ⚠️ Partial | ❌ | Legacy only (partial) |
| View Members | ✅ | ✅ | Both |
| Add Members | ✅ | ✅ | Both |
| Remove Members | ✅ | ✅ | Both |
| Admin Detection | ❌ Flawed | ⚠️ Better | Modern better |
| Make Admin | ❌ | ✅ Interface | Modern only |
| Remove Admin | ❌ | ✅ Interface | Modern only |
| Leave Group | ✅ | ✅ | Both |
| Report Group | ✅ | ✅ | Both |
| Delete Group | ❌ | ✅ Interface | Modern only |
| Mute Notifications | ✅ | ✅ | Both |
| Favorite | ✅ | ✅ | Both |
| View Media | ✅ Inline | Routes | Legacy has UI |
| View Starred | ✅ Inline | Routes | Legacy has UI |
| Real-time Updates | ⚠️ Basic | ✅ Stream | Modern better |
| Repository Pattern | ❌ | ✅ | Modern better |
| **Route Registered** | ✅ | ❌ | **CRITICAL** |

### 4.2 UX Issues

#### 4.2.1 Critical UX Problems

| Issue | Description | Impact |
|-------|-------------|--------|
| **Admin Detection Bug** | Only checks if user is first member | Wrong users get admin UI |
| **No Admin Promotion UI** | Interface exists but no UI to use it | Feature unusable |
| **Duplicate Member Widgets** | 3 different member display widgets | Inconsistent UI |
| **Search TODO** | "Search in chat" shows "coming soon" | Feature incomplete |
| **No Member Limit Display** | Users don't know max group size | Confusion when adding fails |

#### 4.2.2 Admin Detection Logic Bug

```dart
// group_info_controller.dart - Lines 1265-1268:
bool get isCurrentUserAdmin {
  if (members.value == null || members.value!.isEmpty || currentUser == null)
    return false;
  return members.value!.first.uid == currentUser!.uid;  // ❌ BUG!
}

// PROBLEM: Only checks first member, not actual admin list
// If member list order changes, wrong person gets admin access
// Users added first to group != Admins

// CORRECT IMPLEMENTATION (enhanced controller):
bool get isCurrentUserAdmin {
  final userId = currentUser?.uid;
  if (userId == null) return false;
  return state.value.admins.any((admin) => admin.uid == userId);
}
```

### 4.3 Architecture Issues

#### 4.3.1 Module Duplication (Same as User Info)

```
PROBLEM: Two separate modules for same functionality

group_info/               user_info/ (group part)
├── Controller (1285 ln)  ├── Controller (525 ln)
├── View                  ├── View
├── 12 Widgets            ├── 3 Shared Widgets
└── Direct Firestore      └── Repository Pattern

RECOMMENDATION: Migrate to user_info, deprecate group_info
```

#### 4.3.2 Widget Duplication

```
THREE different member display widgets exist:

1. group_info/widgets/group_member_item.dart
   - Used in legacy UI
   - Takes Map<String, dynamic> member
   - Has remove button

2. group_info/widgets/item_group_member.dart
   - UNUSED in codebase
   - Takes String imageUser (assumes asset path - wrong!)
   - Has admin badge

3. user_info/widgets/user_info_action_tile.dart → GroupMemberTile
   - Modern implementation
   - Takes proper typed parameters
   - Has admin badge AND remove option
   - Best design

RECOMMENDATION: Delete first two, use GroupMemberTile everywhere
```

### 4.4 Code Quality Issues

| Issue | Location | Severity |
|-------|----------|----------|
| Monolithic controller | group_info_controller.dart (1285 lines) | High |
| Admin detection bug | group_info_controller.dart:1265-1268 | **Critical** |
| StreamBuilder in controller | group_info_controller.dart | Medium |
| Race condition | removeMember() - fetch then update | Medium |
| Widget UI logic in controller | Line 639+ | Medium |
| Print statements | Multiple locations | Low |

#### Race Condition Example

```dart
// group_info_controller.dart - removeMember():
Future<void> removeMember(String memberId) async {
  // Step 1: Get current data
  final doc = await FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(roomId)
      .get();

  // ⚠️ RACE CONDITION: Another user could modify between get and update

  // Step 2: Update with modified data
  final members = doc.data()?['membersIds'] ?? [];
  members.remove(memberId);
  await doc.reference.update({'membersIds': members});
}

// CORRECT: Use transaction
Future<void> removeMember(String memberId) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final doc = await transaction.get(roomRef);
    final members = List<String>.from(doc.data()?['membersIds'] ?? []);
    members.remove(memberId);
    transaction.update(roomRef, {'membersIds': members});
  });
}
```

### 4.5 Firebase Integration Issues

#### 4.5.1 Missing Admin Tracking

```
CURRENT Firestore Structure:
chat_rooms/{roomId}
├── membersIds: ["user1", "user2", "user3"]
├── members: [{...}, {...}, {...}]  // Full user objects
└── ❌ admins field often missing!

REQUIRED Structure:
chat_rooms/{roomId}
├── membersIds: ["user1", "user2", "user3"]
├── adminIds: ["user1"]  // Explicit admin tracking
├── createdBy: "user1"   // Original creator
└── members: [{...}, {...}, {...}]
```

#### 4.5.2 Firestore Rules Gap

```javascript
// Current rules (firestore.rules):
match /chats/{roomId} {
  allow update: if isAuthenticated() &&
                   request.auth.uid in resource.data.membersIds;
  // ❌ Any member can remove any other member!
  // ❌ Any member can change group name!
  // ❌ No admin check for sensitive operations
}

// Required rules:
match /chats/{roomId} {
  // Only admins can modify member list
  allow update: if isAuthenticated() &&
                   request.auth.uid in resource.data.membersIds &&
                   (
                     // Regular members can only update certain fields
                     request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['lastMessage', 'lastMessageTime']) ||
                     // Admins can update everything
                     request.auth.uid in resource.data.adminIds
                   );
}
```

### 4.6 Platform Compatibility Issues

#### Same as User Info

| Issue | Platform | Description |
|-------|----------|-------------|
| File download path | Android only | Hardcoded path breaks iOS |
| Image picker | Both | Works but no crop functionality |
| Permission handling | Both | Missing runtime permission checks |

### 4.7 Group Info Fixes Required

```
Priority 1 (Critical):
□ Fix admin detection bug (use actual admin list)
□ Add adminIds field to Firestore documents
□ Update Firestore rules for admin-only operations
□ Use transactions for member operations

Priority 2 (High):
□ Register modern GroupInfoView route
□ Add admin promotion/demotion UI
□ Consolidate member display widgets
□ Implement group image upload

Priority 3 (Medium):
□ Add group deletion with cleanup
□ Implement search in chat
□ Add member limit display
□ Create group settings section

Priority 4 (Low):
□ Add group announcement feature
□ Implement member join requests
□ Add group invite links
□ Create group analytics (message count, activity)
```

---

## 5. Cross-Cutting Concerns

### 5.1 Route Registration Issues

```dart
// app_routes.dart - MISSING ROUTES:

// Add these constants:
static const OTHER_USER_INFO = '/other-user-info';
static const MEDIA_GALLERY = '/media-gallery';
static const STARRED_MESSAGES = '/starred-messages';
static const NOTIFICATION_SETTINGS = '/notification-settings';
static const PRIVACY_SETTINGS = '/privacy-settings';
static const ENHANCED_GROUP_INFO = '/enhanced-group-info';

// Add to _Paths:
static const OTHER_USER_INFO = '/other-user-info';
static const MEDIA_GALLERY = '/media-gallery';
static const STARRED_MESSAGES = '/starred-messages';
static const NOTIFICATION_SETTINGS = '/notification-settings';
static const PRIVACY_SETTINGS = '/privacy-settings';
static const ENHANCED_GROUP_INFO = '/enhanced-group-info';
```

### 5.2 Localization Gaps

| Module | Hard-coded Strings | Missing Keys |
|--------|-------------------|--------------|
| Notification Settings | ~30 | DND options, sound names |
| Privacy Settings | ~20 | Visibility levels, checkup |
| User Info | ~15 | Report categories, actions |
| Group Info | ~25 | Admin actions, member ops |

### 5.3 Error Handling Patterns

```dart
// CURRENT (Inconsistent):
try {
  await operation();
} catch (e) {
  print(e);  // ❌ Legacy: print
  log('Error: $e');  // ⚠️ Modern: log but no recovery
  Get.snackbar('Error', 'Something went wrong');  // Generic message
}

// RECOMMENDED (Consistent):
try {
  await operation();
} on FirebaseException catch (e) {
  _handleFirebaseError(e);  // Specific handling
} on NetworkException catch (e) {
  _handleNetworkError(e);  // Retry logic
} catch (e, stackTrace) {
  log('Unexpected error', error: e, stackTrace: stackTrace);
  _reportToCrashlytics(e, stackTrace);
  Get.snackbar('Error', _getUserFriendlyMessage(e));
}
```

### 5.4 Testing Strategy Gap

```
CURRENT TEST COVERAGE: ~0%

RECOMMENDED STRUCTURE:
test/
├── unit/
│   ├── services/
│   │   ├── notification_settings_service_test.dart
│   │   └── privacy_settings_service_test.dart
│   ├── repositories/
│   │   ├── user_info_repository_test.dart
│   │   └── group_info_repository_test.dart
│   └── controllers/
│       ├── other_user_info_controller_test.dart
│       └── enhanced_group_info_controller_test.dart
├── widget/
│   ├── user_info_header_test.dart
│   └── group_member_tile_test.dart
└── integration/
    ├── notification_flow_test.dart
    └── privacy_flow_test.dart
```

### 5.5 Performance Concerns

| Issue | Module | Impact | Solution |
|-------|--------|--------|----------|
| 5 separate count queries | user_info | N+1 query problem | Batch or aggregate |
| No profile caching | All | Repeated network calls | Add local cache |
| Full member load | group_info | Slow for large groups | Paginate members |
| StreamBuilder in controller | group_info | Memory leak potential | Use proper lifecycle |
| No image compression | All | Large uploads | Compress before upload |

---

## 6. Implementation Plan

### Phase 1: Critical Fixes & Route Integration (40 hours)

#### Week 1: Route Registration & Basic Integration

| Task | Effort | Priority |
|------|--------|----------|
| Add missing routes (OTHER_USER_INFO, MEDIA_GALLERY, etc.) | 2h | P0 |
| Create MediaGalleryView scaffold | 4h | P0 |
| Create StarredMessagesView scaffold | 3h | P0 |
| Register modern NotificationSettingsView | 1h | P0 |
| Register modern PrivacySettingsView | 1h | P0 |
| Register OtherUserInfoView | 1h | P0 |
| Fix admin detection bug in GroupInfoController | 2h | P0 |
| Add adminIds field migration for existing groups | 4h | P0 |

#### Week 2: Core Functionality Fixes

| Task | Effort | Priority |
|------|--------|----------|
| Integrate NotificationDecision into FCM service | 6h | P0 |
| Fix file download paths for iOS | 3h | P0 |
| Use transactions for member operations | 4h | P0 |
| Add sound preview functionality | 4h | P1 |
| Add vibration preview functionality | 2h | P1 |
| Fix race conditions in group operations | 3h | P1 |

### Phase 2: Backend Enforcement & Security (60 hours)

#### Week 3-4: Cloud Functions & Security Rules

| Task | Effort | Priority |
|------|--------|----------|
| Create Cloud Function: getUserProfile (privacy-aware) | 8h | P0 |
| Create Cloud Function: sendNotification (settings-aware) | 10h | P0 |
| Update Firestore rules for blocking enforcement | 4h | P0 |
| Update Firestore rules for admin operations | 4h | P0 |
| Integrate privacy checks into ReadReceiptService | 4h | P1 |
| Integrate privacy checks into PresenceService | 4h | P1 |
| Create Cloud Function: validateMessage (before save) | 6h | P1 |

#### Week 5: Security Features

| Task | Effort | Priority |
|------|--------|----------|
| Implement App Lock UI | 8h | P1 |
| Integrate biometric authentication | 4h | P1 |
| Implement screenshot prevention | 4h | P1 |
| Add app switcher blur | 4h | P2 |

### Phase 3: Platform Parity & Polish (35 hours)

#### Week 6: Platform-Specific Fixes

| Task | Effort | Priority |
|------|--------|----------|
| Add missing notification sound files (10 sounds) | 3h | P1 |
| Add iOS notification categories | 4h | P1 |
| Implement iOS-specific file handling | 4h | P1 |
| Add Android notification LED support | 2h | P2 |
| Fix Android scoped storage for downloads | 4h | P1 |

#### Week 7: UX Polish

| Task | Effort | Priority |
|------|--------|----------|
| Add exception list editing UI | 6h | P1 |
| Add Privacy Checkup view | 4h | P1 |
| Add Security Audit Log viewer | 4h | P2 |
| Add admin promotion/demotion UI | 4h | P1 |

### Phase 4: Feature Completion (45 hours)

#### Week 8-9: Module Consolidation

| Task | Effort | Priority |
|------|--------|----------|
| Migrate contactInfo to user_info module | 8h | P2 |
| Migrate group_info to user_info module | 8h | P2 |
| Consolidate notification systems | 6h | P2 |
| Delete deprecated legacy modules | 2h | P2 |

#### Week 10: Additional Features

| Task | Effort | Priority |
|------|--------|----------|
| Implement DND schedule enforcement | 4h | P2 |
| Add per-chat quick mute UI | 4h | P2 |
| Implement disappearing messages countdown | 6h | P2 |
| Add group image upload | 4h | P2 |
| Create comprehensive unit tests | 8h | P2 |

### Implementation Milestones

```
┌────────────────────────────────────────────────────────────────┐
│ MILESTONE 1 (Week 2): Core Functionality                       │
│ ✓ All routes registered                                        │
│ ✓ Admin detection fixed                                        │
│ ✓ Notification settings integrated                             │
│ ✓ iOS file handling fixed                                      │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ MILESTONE 2 (Week 5): Security Complete                        │
│ ✓ Cloud Functions deployed                                     │
│ ✓ Firestore rules updated                                      │
│ ✓ App Lock functional                                          │
│ ✓ Privacy backend enforcement active                           │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ MILESTONE 3 (Week 7): Platform Parity                          │
│ ✓ Android and iOS feature parity                               │
│ ✓ All sound files present                                      │
│ ✓ Notification categories configured                           │
│ ✓ UX polish complete                                           │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│ MILESTONE 4 (Week 10): Consolidation Complete                  │
│ ✓ Single unified module per feature                            │
│ ✓ Legacy modules deprecated                                    │
│ ✓ Unit test coverage > 60%                                     │
│ ✓ All features functional                                      │
└────────────────────────────────────────────────────────────────┘
```

---

## 7. Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Data migration breaks existing users | Medium | High | Feature flags, gradual rollout |
| Cloud Functions add latency | Medium | Medium | Optimize function cold starts |
| Breaking changes in routes | High | Medium | Redirect old routes to new |
| Admin migration misses groups | Medium | High | Background migration job |

### Security Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Privacy bypass during transition | High | Critical | Deploy rules first |
| Blocked users still see data | High | High | Immediate Cloud Function |
| App Lock bypassed | Medium | Medium | Proper keychain/keystore use |

### UX Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Users confused by new UI | Medium | Medium | Onboarding tooltips |
| Settings migration confusion | Medium | Low | Clear migration dialog |
| Feature discovery issues | Low | Low | Settings search |

---

## Appendix

### A. File Reference Quick Guide

```
NOTIFICATION SETTINGS:
├── LEGACY: lib/app/modules/notifications/
├── MODERN: lib/app/modules/settings_v2/notifications/
├── SERVICE: lib/app/modules/settings_v2/core/services/notification_settings_service.dart
├── MODEL: lib/app/modules/settings_v2/core/models/notification_settings_model.dart
└── FCM: lib/app/core/services/fcm_service.dart

PRIVACY SETTINGS:
├── LEGACY: lib/app/modules/privacy/
├── MODERN: lib/app/modules/settings_v2/privacy/
├── SERVICE: lib/app/modules/settings_v2/core/services/privacy_settings_service.dart
├── MODEL: lib/app/modules/settings_v2/core/models/privacy_settings_model.dart
└── PRESENCE: lib/app/core/services/presence_service.dart

USER INFO:
├── LEGACY: lib/app/modules/contactInfo/
├── MODERN: lib/app/modules/user_info/
├── REPOSITORY: lib/app/modules/user_info/repositories/user_info_repository.dart
└── MODEL: lib/app/modules/user_info/models/user_info_state.dart

GROUP INFO:
├── LEGACY: lib/app/modules/group_info/
├── MODERN: lib/app/modules/user_info/ (group components)
├── REPOSITORY: lib/app/modules/user_info/repositories/group_info_repository.dart
└── MODEL: lib/app/modules/user_info/models/group_info_state.dart

ROUTES:
├── DEFINITION: lib/app/routes/app_routes.dart
└── PAGES: lib/app/routes/app_pages.dart

FIREBASE:
├── RULES: firestore.rules
├── ANDROID: android/app/src/main/AndroidManifest.xml
└── iOS: ios/Runner/Info.plist
```

### B. Required Dependencies

```yaml
# Add to pubspec.yaml:

# For sound preview
just_audio: ^0.9.36

# For vibration preview
vibration: ^1.8.4

# For biometric auth
local_auth: ^2.1.8

# For cross-platform paths
path_provider: ^2.1.2

# For image compression
flutter_image_compress: ^2.1.0
```

### C. Cloud Functions Template

```javascript
// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Privacy-aware user profile
exports.getUserProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated');

  const viewerId = context.auth.uid;
  const targetId = data.userId;

  // Check blocking
  const privacy = await admin.firestore()
    .collection('users').doc(targetId)
    .collection('settings').doc('privacy')
    .get();

  if (privacy.data()?.blockedUsers?.includes(viewerId)) {
    throw new functions.https.HttpsError('not-found', 'User not found');
  }

  // Return filtered profile based on privacy settings
  const profile = await admin.firestore().collection('users').doc(targetId).get();
  return filterByPrivacy(profile.data(), privacy.data(), viewerId);
});

// Notification-aware message push
exports.onMessageCreate = functions.firestore
  .document('chats/{roomId}/chat/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const roomId = context.params.roomId;

    // Get room members
    const room = await admin.firestore().collection('chats').doc(roomId).get();
    const members = room.data().membersIds.filter(id => id !== message.senderId);

    // Check each member's notification settings
    for (const memberId of members) {
      const settings = await getNotificationSettings(memberId);
      const decision = shouldDeliver(settings, message, roomId);

      if (decision.shouldDeliver) {
        await sendFCM(memberId, message, room.data());
      }
    }
});
```

### D. Testing Checklist

```
□ Notification Settings
  □ Master toggle enables/disables all notifications
  □ Category toggles work independently
  □ Sound preview plays correct sound
  □ Vibration preview triggers device
  □ DND schedule activates/deactivates at correct times
  □ Per-chat mute respects duration
  □ Settings sync across devices

□ Privacy Settings
  □ Blocked user cannot see profile
  □ Blocked user cannot send messages
  □ Last seen respects visibility setting
  □ Profile photo respects visibility setting
  □ Read receipts respect toggle
  □ Typing indicator respects toggle
  □ App Lock activates after timeout
  □ Biometric unlocks app

□ User Info
  □ Block action works immediately
  □ Report submits to Firestore
  □ Mute toggle persists
  □ Media gallery loads all types
  □ Starred messages display correctly
  □ Online status updates real-time
  □ Mutual contacts load correctly

□ Group Info
  □ Only admins can remove members
  □ Admin promotion works
  □ Group name edit saves
  □ Group image upload works
  □ Leave group removes member
  □ Report submits correctly
  □ Members list loads all members
```

---

*Document generated for Crypted messaging application. Last updated: January 2026*

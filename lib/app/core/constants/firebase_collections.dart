/// Firebase Collection Names - Centralized constants for all Firestore collections
///
/// This file provides a single source of truth for all Firebase collection names
/// used throughout the app. This prevents typos, ensures consistency, and makes
/// it easy to rename collections if needed.
///
/// Usage:
/// ```dart
/// import 'package:crypted_app/app/core/constants/firebase_collections.dart';
///
/// // Instead of: .collection('chats')
/// // Use: .collection(FirebaseCollections.chats)
/// ```
library;

class FirebaseCollections {
  // Private constructor to prevent instantiation
  FirebaseCollections._();

  // =================== MAIN COLLECTIONS ===================

  /// Main chat rooms collection - stores chat room metadata and messages
  /// Structure: chats/{roomId}/chat/{messageId}
  static const String chats = 'chats';

  /// Legacy chat rooms collection - some parts of app still use this
  /// TODO: Migrate all usages to 'chats' collection
  @Deprecated('Use FirebaseCollections.chats instead. This is for legacy compatibility only.')
  static const String chatRoomsLegacy = 'chat_rooms';

  /// Users collection - stores user profiles and settings
  /// Structure: users/{userId}
  static const String users = 'users';

  /// Legacy users collection (capital U) - for backward compatibility
  @Deprecated('Use FirebaseCollections.users instead')
  static const String usersLegacy = 'Users';

  /// Stories collection - stores user stories
  /// Structure: Stories/{storyId}
  static const String stories = 'Stories';

  /// Calls collection - stores call history
  /// Structure: Calls/{callId}
  static const String calls = 'Calls';

  /// Notifications collection - stores push notifications
  /// Structure: Notifications/{notificationId}
  static const String notifications = 'Notifications';

  /// Reports collection - stores user/content reports
  /// Structure: reports/{reportId}
  static const String reports = 'reports';

  /// Help messages collection - stores help/support messages
  /// Structure: help_messages/{messageId}
  static const String helpMessages = 'help_messages';

  /// Backups collection - stores user backup metadata
  /// Structure: backups/{userId}/...
  static const String backups = 'backups';

  /// FCM tokens collection - stores Firebase Cloud Messaging tokens
  /// Structure: fcmTokens/{token}
  static const String fcmTokens = 'fcmTokens';

  /// Group invite links collection - stores group invitation links
  /// Structure: group_invite_links/{linkId}
  static const String groupInviteLinks = 'group_invite_links';

  /// Chat rooms collection (capital C) - legacy variant
  @Deprecated('Use FirebaseCollections.chats instead')
  static const String chatsLegacyCapital = 'Chats';

  // =================== SUBCOLLECTIONS ===================

  /// Messages subcollection within chat rooms
  /// Path: chats/{roomId}/chat/{messageId}
  static const String chatMessages = 'chat';

  /// Alternative messages subcollection name
  /// Path: {parent}/messages/{messageId}
  static const String messages = 'messages';

  /// Typing indicators subcollection
  /// Path: chats/{roomId}/typing/{userId}
  static const String typing = 'typing';

  /// Activity status subcollection
  /// Path: chats/{roomId}/activity/{userId}
  static const String activity = 'activity';

  /// Presence status subcollection
  /// Path: users/{userId}/presence
  static const String presence = 'presence';

  /// Blocked users subcollection
  /// Path: users/{userId}/blocked/{blockedUserId}
  static const String blocked = 'blocked';

  /// User contacts subcollection
  /// Path: users/{userId}/contacts/{contactId}
  static const String contacts = 'contacts';

  /// Private settings subcollection
  /// Path: users/{userId}/private
  static const String private = 'private';

  /// User settings subcollection
  /// Path: users/{userId}/settings
  static const String settings = 'settings';

  /// Read receipts subcollection
  /// Path: messages/{messageId}/readReceipts/{userId}
  static const String readReceipts = 'readReceipts';

  /// Recording status subcollection
  /// Path: chats/{roomId}/recording/{userId}
  static const String recording = 'recording';

  /// Story replies subcollection
  /// Path: Stories/{storyId}/replies/{replyId}
  static const String storyReplies = 'replies';

  /// Story reactions subcollection
  /// Path: Stories/{storyId}/reactions/{reactionId}
  static const String storyReactions = 'reactions';

  /// Device info backup subcollection
  /// Path: backups/{userId}/device_info
  static const String deviceInfo = 'device_info';

  /// Location backup subcollection
  /// Path: backups/{userId}/location
  static const String location = 'location';

  /// Photos backup subcollection
  /// Path: backups/{userId}/photos
  static const String photos = 'photos';

  /// Backup summary subcollection
  /// Path: backups/{userId}/backup_summary
  static const String backupSummary = 'backup_summary';

  /// Chat notification overrides subcollection
  /// Path: users/{userId}/chatNotificationOverrides/{chatId}
  static const String chatNotificationOverrides = 'chatNotificationOverrides';

  /// User sessions subcollection
  /// Path: users/{userId}/sessions/{sessionId}
  static const String sessions = 'sessions';

  /// Security log subcollection
  /// Path: users/{userId}/securityLog/{logId}
  static const String securityLog = 'securityLog';

  /// User notifications subcollection (within users)
  /// Path: users/{userId}/notifications/{notificationId}
  static const String userNotifications = 'notifications';

  // =================== SPECIAL COLLECTIONS ===================

  /// Connection check collection (for testing connectivity)
  static const String connectionCheck = '_connection_check';

  /// Chat rooms collection (for pin manager)
  /// Note: This is different from 'chats' - used specifically for pin functionality
  static const String chatRooms = 'chatRooms';
}

/// Firebase Storage Paths - Centralized constants for Firebase Storage
class FirebaseStoragePaths {
  FirebaseStoragePaths._();

  /// Chat images storage path
  static const String chatImages = 'chat_images';

  /// Chat videos storage path
  static const String chatVideos = 'chat_videos';

  /// Chat audio storage path
  static const String chatAudio = 'chat_audio';

  /// Chat files storage path
  static const String chatFiles = 'chat_files';

  /// Profile images storage path
  static const String profileImages = 'profile_images';

  /// Story media storage path
  static const String storyMedia = 'story_media';

  /// Group images storage path
  static const String groupImages = 'group_images';

  /// Backups storage path
  static const String backups = 'backups';
}

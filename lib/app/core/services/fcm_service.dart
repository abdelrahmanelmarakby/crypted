import 'dart:async';
import 'dart:developer' as developer;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/notification_controller.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/notification_settings_service.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart' as settings_model;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Production-grade FCM Service with awesome_notifications
///
/// Handles all push notifications with advanced features:
/// - Smart replies (inline text responses)
/// - Reaction buttons (like, love, laugh)
/// - Rich media support
/// - Conversation grouping
/// - Full-screen call notifications
/// - Background action handling
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Notification settings service for decision logic
  NotificationSettingsService? _notificationSettingsService;

  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize with notification settings service
  void setNotificationSettingsService(NotificationSettingsService service) {
    _notificationSettingsService = service;
  }

  /// Initialize awesome_notifications channels
  ///
  /// This should be called in main.dart BEFORE runApp()
  static Future<void> initializeAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        'resource://drawable/ic_notification',
        [
          // Direct Messages Channel
          NotificationChannel(
            channelGroupKey: 'messages_group',
            channelKey: 'direct_messages',
            channelName: 'Direct Messages',
            channelDescription: 'Personal messages from contacts',
            importance: NotificationImportance.High,
            defaultColor: const Color(0xFF31A354),
            ledColor: Colors.white,
            soundSource: 'resource://raw/notification_sound',
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
            playSound: true,
            groupAlertBehavior: GroupAlertBehavior.Children,
            icon: 'resource://drawable/ic_notification',
          ),

          // Group Messages Channel
          NotificationChannel(
            channelGroupKey: 'messages_group',
            channelKey: 'group_messages',
            channelName: 'Group Messages',
            channelDescription: 'Messages in group chats',
            importance: NotificationImportance.High,
            defaultColor: const Color(0xFF31A354),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
            playSound: true,
          ),

          // Calls Channel
          NotificationChannel(
            channelGroupKey: 'calls_group',
            channelKey: 'incoming_calls',
            channelName: 'Incoming Calls',
            channelDescription: 'Voice and video call notifications',
            importance: NotificationImportance.Max,
            defaultColor: const Color(0xFF31A354),
            soundSource: 'resource://raw/call_ringtone',
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
            playSound: true,
            locked: true,
          ),

          // Stories Channel
          NotificationChannel(
            channelGroupKey: 'social_group',
            channelKey: 'stories',
            channelName: 'Stories',
            channelDescription: 'New story notifications',
            importance: NotificationImportance.Default,
            defaultColor: const Color(0xFF31A354),
          ),

          // Reactions Channel
          NotificationChannel(
            channelGroupKey: 'social_group',
            channelKey: 'reactions',
            channelName: 'Reactions',
            channelDescription: 'Story and message reactions',
            importance: NotificationImportance.Low,
            defaultColor: const Color(0xFF31A354),
          ),

          // General Channel
          NotificationChannel(
            channelGroupKey: 'general_group',
            channelKey: 'general',
            channelName: 'General',
            channelDescription: 'General notifications',
            importance: NotificationImportance.Default,
            defaultColor: const Color(0xFF31A354),
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'messages_group',
            channelGroupName: 'Messages',
          ),
          NotificationChannelGroup(
            channelGroupKey: 'calls_group',
            channelGroupName: 'Calls',
          ),
          NotificationChannelGroup(
            channelGroupKey: 'social_group',
            channelGroupName: 'Social',
          ),
          NotificationChannelGroup(
            channelGroupKey: 'general_group',
            channelGroupName: 'General',
          ),
        ],
        debug: kDebugMode,
      );

      if (kDebugMode) {
        developer.log('✅ Awesome Notifications initialized', name: 'FCMService');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error initializing Awesome Notifications: $e', name: 'FCMService');
      }
    }
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final isAllowed = await _requestPermissions();

      if (!isAllowed) {
        if (kDebugMode) {
          developer.log('⚠️ Notification permissions not granted', name: 'FCMService');
        }
        return;
      }

      // Initialize FCM add-on (handles FCM token automatically)
      await AwesomeNotificationsFcm().initialize(
        onFcmSilentDataHandle: NotificationController.onFcmSilentDataHandle,
        onFcmTokenHandle: NotificationController.onFcmTokenHandle,
        onNativeTokenHandle: NotificationController.onNativeTokenHandle,
        debug: kDebugMode,
      );

      _isInitialized = true;
      if (kDebugMode) {
        developer.log('✅ FCM Service initialized successfully', name: 'FCMService');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error initializing FCM Service: $e', name: 'FCMService');
      }
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      return await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error requesting permissions: $e', name: 'FCMService');
      }
      return false;
    }
  }

  /// Handle FCM data messages (called from NotificationController)
  Future<void> handleFcmDataMessage(Map<String, dynamic> data) async {
    if (kDebugMode) {
      developer.log('📨 FCM data message received: $data', name: 'FCMService');
    }

    final type = data['type'] as String?;

    switch (type) {
      case 'new_message':
        _handleNewMessageNotification(data);
        break;
      case 'incoming_call':
        _handleIncomingCallNotification(data);
        break;
      case 'new_story':
        _handleNewStoryNotification(data);
        break;
      case 'backup_completed':
        _handleBackupNotification(data);
        break;
      case 'typing_indicator':
      case 'presence_update':
      case 'read_receipt':
        // Silent messages - handled by Firestore listeners
        break;
      default:
        _showGenericNotification(data);
    }
  }

  /// Handle new message notification
  Future<void> _handleNewMessageNotification(Map<String, dynamic> data) async {
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;
    final senderName = data['senderName'] as String?;
    final messageText = data['message'] as String?;
    final senderAvatar = data['senderAvatar'] as String?;
    final isGroup = data['isGroup'] == 'true';
    final isReaction = data['isReaction'] == 'true';
    final isMention = data['isMention'] == 'true';

    if (chatId == null || senderId == null) return;

    // Check notification settings before showing
    if (_notificationSettingsService != null) {
      final isContact = await _isUserContact(senderId);
      final isStarred = await _isUserStarred(senderId, chatId);

      final decision = _notificationSettingsService!.shouldDeliverNotification(
        senderId: senderId,
        chatId: chatId,
        category: settings_model.NotificationCategory.message,
        isContact: isContact,
        isStarred: isStarred,
        isReaction: isReaction,
        isMention: isMention,
      );

      if (!decision.shouldDeliver) {
        if (kDebugMode) {
          developer.log('🔕 Notification blocked: ${decision.blockReason?.displayMessage}', name: 'FCMService');
        }
        return;
      }
    }

    // Create notification with awesome_notifications
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: chatId.hashCode,
        channelKey: isGroup ? 'group_messages' : 'direct_messages',
        groupKey: chatId,
        title: senderName ?? 'New Message',
        body: messageText ?? '',
        largeIcon: senderAvatar,
        notificationLayout: isGroup
            ? NotificationLayout.MessagingGroup
            : NotificationLayout.Messaging,
        category: NotificationCategory.Message,
        displayOnForeground: true,
        displayOnBackground: true,
        wakeUpScreen: false,
        payload: {
          'chatId': chatId,
          'senderId': senderId,
          'conversationId': chatId,
          'isGroup': isGroup.toString(),
          'type': isGroup ? 'group_message' : 'direct_message',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: isGroup ? 'REPLY_GROUP' : 'REPLY',
          label: 'Reply',
          icon: 'resource://drawable/ic_reply',
          requireInputText: true,
          actionType: ActionType.SilentAction,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'MARK_READ',
          label: 'Mark as Read',
          icon: 'resource://drawable/ic_done_all',
          actionType: ActionType.SilentBackgroundAction,
        ),
        NotificationActionButton(
          key: 'MUTE',
          label: 'Mute',
          icon: 'resource://drawable/ic_notifications_off',
          actionType: ActionType.SilentBackgroundAction,
        ),
      ],
    );
  }

  /// Handle incoming call notification
  Future<void> _handleIncomingCallNotification(Map<String, dynamic> data) async {
    final callId = data['callId'] as String?;
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String?;
    final callerAvatar = data['callerAvatar'] as String?;
    final callType = data['callType'] as String?;

    if (callId == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: callId.hashCode,
        channelKey: 'incoming_calls',
        title: callerName ?? 'Incoming Call',
        body: callType == 'video' ? '📹 Video Call' : '📞 Voice Call',
        largeIcon: callerAvatar,
        category: NotificationCategory.Call,
        fullScreenIntent: true,
        wakeUpScreen: true,
        displayOnForeground: true,
        displayOnBackground: true,
        autoDismissible: false,
        locked: true,
        payload: {
          'callId': callId,
          'callerId': callerId ?? '',
          'callerName': callerName ?? '',
          'callType': callType ?? 'voice',
          'type': 'incoming_call',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ACCEPT_CALL',
          label: 'Accept',
          icon: 'resource://drawable/ic_call_accept',
          color: Colors.green,
          actionType: ActionType.Default,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'DECLINE_CALL',
          label: 'Decline',
          icon: 'resource://drawable/ic_call_decline',
          color: Colors.red,
          isDangerousOption: true,
          actionType: ActionType.Default,
          showInCompactView: true,
        ),
      ],
    );
  }

  /// Handle new story notification
  Future<void> _handleNewStoryNotification(Map<String, dynamic> data) async {
    final storyId = data['storyId'] as String?;
    final userId = data['userId'] as String?;
    final userName = data['userName'] as String?;
    final userAvatar = data['userAvatar'] as String?;
    final storyType = data['storyType'] as String?;

    if (storyId == null || userId == null) return;

    // Check notification settings
    if (_notificationSettingsService != null) {
      final isContact = await _isUserContact(userId);
      final isStarred = await _isUserStarred(userId, null);

      final decision = _notificationSettingsService!.shouldDeliverNotification(
        senderId: userId,
        chatId: 'story_$userId',
        category: settings_model.NotificationCategory.status,
        isContact: isContact,
        isStarred: isStarred,
        isReaction: false,
        isMention: false,
      );

      if (!decision.shouldDeliver) {
        if (kDebugMode) {
          developer.log('🔕 Story notification blocked: ${decision.blockReason?.displayMessage}', name: 'FCMService');
        }
        return;
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: storyId.hashCode,
        channelKey: 'stories',
        title: '$userName posted a story',
        body: storyType == 'video' ? '🎥 Video Story' : '📷 Photo Story',
        largeIcon: userAvatar,
        category: NotificationCategory.Social,
        displayOnForeground: true,
        displayOnBackground: true,
        payload: {
          'storyId': storyId,
          'userId': userId,
          'type': 'new_story',
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REACT_LIKE',
          label: '👍',
          actionType: ActionType.SilentBackgroundAction,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'REACT_LOVE',
          label: '❤️',
          actionType: ActionType.SilentBackgroundAction,
          showInCompactView: true,
        ),
        NotificationActionButton(
          key: 'REACT_LAUGH',
          label: '😂',
          actionType: ActionType.SilentBackgroundAction,
          showInCompactView: true,
        ),
      ],
    );
  }

  /// Handle backup completion notification
  void _handleBackupNotification(Map<String, dynamic> data) {
    _showGenericNotification(data);
  }

  /// Show generic notification
  Future<void> _showGenericNotification(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Crypted';
    final body = data['body'] as String? ?? 'You have a new notification';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch,
        channelKey: 'general',
        title: title,
        body: body,
        category: NotificationCategory.Message,
        displayOnForeground: true,
        displayOnBackground: true,
        payload: data.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      ),
    );
  }

  /// Delete FCM token (on logout)
  Future<void> deleteFCMToken() async {
    try {
      if (_currentToken != null) {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.fcmTokens)
            .doc(_currentToken)
            .delete();
      }

      // Note: awesome_notifications_fcm manages tokens internally
      // Token is automatically refreshed when needed
      _currentToken = null;

      if (kDebugMode) {
        developer.log('✅ FCM token deleted', name: 'FCMService');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error deleting FCM token: $e', name: 'FCMService');
      }
    }
  }

  /// Get current token
  String? get currentToken => _currentToken;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  // ============================================================================
  // CONTACT & STARRED STATUS HELPERS
  // ============================================================================

  /// Check if a user is in the current user's contacts
  Future<bool> _isUserContact(String senderId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return false;

      final contactDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUserId)
          .collection(FirebaseCollections.contacts)
          .doc(senderId)
          .get();
      return contactDoc.exists;
    } catch (e) {
      developer.log(
        'Error checking contact status for $senderId',
        name: 'FCMService',
        error: e,
      );
      return false;
    }
  }

  /// Check if a user is "starred" (has a favorited chat room with current user)
  Future<bool> _isUserStarred(String senderId, String? chatId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return false;

      // Check if user is in global allowed contacts (DND bypass list)
      if (_notificationSettingsService != null) {
        final globalAllowed = _notificationSettingsService!
            .settings.value.dnd.globalAllowedContacts;
        if (globalAllowed.contains(senderId)) {
          return true;
        }
      }

      // Check if the chat room is favorited
      if (chatId != null) {
        final chatDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.chats)
            .doc(chatId)
            .get();

        if (chatDoc.exists) {
          final data = chatDoc.data();
          final favorites = data?['favorites'] as Map<String, dynamic>?;
          if (favorites != null && favorites[currentUserId] == true) {
            return true;
          }
          if (data?['isFavorite'] == true) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      developer.log(
        'Error checking starred status for $senderId',
        name: 'FCMService',
        error: e,
      );
      return false;
    }
  }
}

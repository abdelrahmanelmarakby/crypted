import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/fcm_service.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Notification Controller for awesome_notifications
///
/// Handles all notification callbacks and actions including:
/// - Smart replies to messages
/// - Reaction buttons (like, love, laugh)
/// - Call actions (accept, decline)
/// - Conversation actions (mute, mark as read)
///
/// All methods are static and use @pragma("vm:entry-point") to ensure
/// they work even when the app is killed (background isolate execution)
class NotificationController {
  /// Receive port for isolate communication
  static final ReceivePort _receivePort = ReceivePort();

  /// Initialize isolate communication
  ///
  /// This allows background notification actions to communicate with the
  /// main app isolate
  static Future<void> initializeIsolateReceivePort() async {
    try {
      // Check if the port is already registered
      final sendPort = IsolateNameServer.lookupPortByName('notification_send_port');
      if (sendPort != null) {
        IsolateNameServer.removePortNameMapping('notification_send_port');
      }

      // Register the port
      IsolateNameServer.registerPortWithName(
        _receivePort.sendPort,
        'notification_send_port',
      );

      // Listen for messages from background isolate
      _receivePort.listen((message) {
        _handleBackgroundMessage(message);
      });

      if (kDebugMode) {
        developer.log('✅ Isolate receive port initialized', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error initializing isolate port: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle messages from background isolate
  static void _handleBackgroundMessage(dynamic message) {
    if (message is Map) {
      if (kDebugMode) {
        developer.log(
          'Background notification action received: ${message['action']}',
          name: 'NotificationController',
        );
      }
      // Handle navigation or state updates based on the message
      // This runs in the main isolate context
    }
  }

  // ============================================================================
  // NOTIFICATION LIFECYCLE CALLBACKS
  // ============================================================================

  /// Called when a notification is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      developer.log(
        'Notification created: ${receivedNotification.id}',
        name: 'NotificationController',
      );
    }
  }

  /// Called when a notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      developer.log(
        'Notification displayed: ${receivedNotification.id}',
        name: 'NotificationController',
      );
    }
  }

  /// Called when a notification is dismissed
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (kDebugMode) {
      developer.log(
        'Notification dismissed: ${receivedAction.id}',
        name: 'NotificationController',
      );
    }
  }

  // ============================================================================
  // MAIN ACTION CALLBACK
  // ============================================================================

  /// Main action callback - handles all notification action button taps
  ///
  /// This method runs in:
  /// - Foreground: When app is visible
  /// - Background: When app is in background but not killed
  /// - Background Isolate: When app is killed (SilentBackgroundAction)
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    try {
      final payload = receivedAction.payload ?? {};
      final action = receivedAction.buttonKeyPressed;
      final messageType = payload['type'] ?? '';

      if (kDebugMode) {
        developer.log(
          'Action received: $action, Type: $messageType, Lifecycle: ${receivedAction.actionLifeCycle}',
          name: 'NotificationController',
        );
      }

      // If no button was pressed, it's a tap on the notification itself
      if (action.isEmpty) {
        await _handleNotificationTap(payload);
        return;
      }

      // Handle specific actions
      switch (action) {
        case 'REPLY':
        case 'REPLY_GROUP':
          await _handleReply(
            receivedAction.buttonKeyInput,
            payload['chatId'] ?? payload['conversationId'] ?? '',
            payload['senderId'] ?? '',
          );
          break;

        case 'MARK_READ':
          await _handleMarkAsRead(
            payload['chatId'] ?? payload['conversationId'] ?? '',
          );
          break;

        case 'MUTE':
          await _handleMuteConversation(
            payload['chatId'] ?? payload['conversationId'] ?? '',
          );
          break;

        case 'ACCEPT_CALL':
          await _handleAcceptCall(payload);
          break;

        case 'DECLINE_CALL':
          await _handleDeclineCall(payload);
          break;

        case 'REACT_LIKE':
          await _handleReaction('👍', payload);
          break;

        case 'REACT_LOVE':
          await _handleReaction('❤️', payload);
          break;

        case 'REACT_LAUGH':
          await _handleReaction('😂', payload);
          break;

        default:
          if (kDebugMode) {
            developer.log('Unknown action: $action', name: 'NotificationController');
          }
      }

      // If running in background, send to main isolate
      if (receivedAction.actionLifeCycle == NotificationLifeCycle.Background) {
        final sendPort = IsolateNameServer.lookupPortByName('notification_send_port');
        if (sendPort != null) {
          sendPort.send({
            'action': action,
            'payload': payload,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error in onActionReceivedMethod: $e', name: 'NotificationController');
      }
    }
  }

  // ============================================================================
  // FCM CALLBACKS
  // ============================================================================

  /// Handle FCM silent data messages
  @pragma("vm:entry-point")
  static Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
    if (kDebugMode) {
      developer.log(
        'FCM silent data received: ${silentData.data}',
        name: 'NotificationController',
      );
    }

    // Route to FCMService for handling
    final data = silentData.data ?? {};
    final type = data['type'];

    // Skip silent messages that don't need notifications
    if (type == 'typing_indicator' ||
        type == 'presence_update' ||
        type == 'read_receipt') {
      return;
    }

    // Import FCMService at the top if not already imported
    // For other messages, route to FCMService for notification display
    try {
      final fcmService = FCMService();
      await fcmService.handleFcmDataMessage(data);
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error handling FCM data: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle FCM token updates
  @pragma("vm:entry-point")
  static Future<void> onFcmTokenHandle(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Save FCM token to Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.fcmTokens)
          .doc(token)
          .set({
        'uid': userId,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the in-memory reference so deleteFCMToken() works on logout.
      // This may fail in a background isolate where the singleton isn't
      // available, which is fine — initialize() also fetches the token.
      try {
        FCMService().updateToken(token);
      } catch (_) {}

      if (kDebugMode) {
        developer.log(
          '✅ FCM token saved: ${token.substring(0, 20)}...',
          name: 'NotificationController',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error saving FCM token: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle native token updates
  @pragma("vm:entry-point")
  static Future<void> onNativeTokenHandle(String token) async {
    if (kDebugMode) {
      developer.log(
        'Native token received: ${token.substring(0, 20)}...',
        name: 'NotificationController',
      );
    }
  }

  // ============================================================================
  // ACTION HANDLERS
  // ============================================================================

  /// Handle notification tap (not action button)
  static Future<void> _handleNotificationTap(Map<String, String?> payload) async {
    final type = payload['type'];
    final chatId = payload['chatId'];
    final conversationId = payload['conversationId'];
    final callId = payload['callId'];
    final userId = payload['userId'];
    final isGroup = payload['isGroup'] == 'true';

    if (kDebugMode) {
      developer.log(
        'Notification tapped: type=$type, chatId=$chatId, conversationId=$conversationId',
        name: 'NotificationController',
      );
    }

    // Navigate based on notification type
    switch (type) {
      case 'new_message':
      case 'direct_message':
      case 'group_message':
        // Use roomId for chat navigation (chatId and conversationId are the same)
        final roomId = conversationId ?? chatId;
        if (roomId != null && roomId.isNotEmpty) {
          // Use legacy arguments method since we don't have full user objects
          // This requires minimal data and ChatController will load the rest
          Get.toNamed(
            Routes.CHAT,
            arguments: {
              'roomId': roomId,
              'useSessionManager': false, // Use legacy method for notifications
              'members': [], // Will be loaded by controller
              'isGroupChat': isGroup,
            },
          );
        }
        break;

      case 'incoming_call':
        if (callId != null && callId.isNotEmpty) {
          Get.toNamed(Routes.CALL, arguments: {
            'callId': callId,
            'callerId': payload['callerId'],
            'callerName': payload['callerName'],
            'callType': payload['callType'],
          });
        }
        break;

      case 'new_story':
        if (userId != null && userId.isNotEmpty) {
          Get.toNamed(Routes.STORIES, arguments: {'userId': userId});
        }
        break;

      default:
        // For unknown notification types, go to home
        Get.toNamed(Routes.HOME);
    }
  }

  /// Handle reply action
  static Future<void> _handleReply(
    String? replyText,
    String conversationId,
    String replyToSenderId,
  ) async {
    try {
      if (replyText == null || replyText.isEmpty || conversationId.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Send message to Firebase
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(conversationId)
          .collection('messages')
          .add({
        'text': replyText,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
      });

      // Update conversation lastMessage
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(conversationId)
          .update({
        'lastMessage': replyText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        developer.log('✅ Reply sent: $replyText', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error sending reply: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle mark as read action
  static Future<void> _handleMarkAsRead(String conversationId) async {
    try {
      if (conversationId.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Mark conversation as read
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(conversationId)
          .update({
        'lastReadAt.$currentUserId': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        developer.log('✅ Conversation marked as read', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error marking as read: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle mute conversation action
  static Future<void> _handleMuteConversation(String conversationId) async {
    try {
      if (conversationId.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Update user preferences to mute conversation
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUserId)
          .update({
        'mutedConversations': FieldValue.arrayUnion([conversationId]),
      });

      if (kDebugMode) {
        developer.log('✅ Conversation muted', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error muting conversation: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle accept call action
  static Future<void> _handleAcceptCall(Map<String, String?> payload) async {
    try {
      final callId = payload['callId'];
      if (callId == null || callId.isEmpty) return;

      // Update call status in Firebase
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.calls)
          .doc(callId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to call screen
      Get.toNamed(Routes.CALL, arguments: {
        'callId': callId,
        'callerId': payload['callerId'],
        'callerName': payload['callerName'],
        'callType': payload['callType'],
      });

      if (kDebugMode) {
        developer.log('✅ Call accepted: $callId', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error accepting call: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle decline call action
  static Future<void> _handleDeclineCall(Map<String, String?> payload) async {
    try {
      final callId = payload['callId'];
      if (callId == null || callId.isEmpty) return;

      // Update call status in Firebase
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.calls)
          .doc(callId)
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      // Dismiss the notification
      await AwesomeNotifications().dismiss(callId.hashCode);

      if (kDebugMode) {
        developer.log('✅ Call declined: $callId', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error declining call: $e', name: 'NotificationController');
      }
    }
  }

  /// Handle reaction action
  static Future<void> _handleReaction(
    String reaction,
    Map<String, String?> payload,
  ) async {
    try {
      final storyId = payload['storyId'];
      final userId = payload['userId'];

      if (storyId == null || userId == null) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      // Save reaction to Firebase
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.stories)
          .doc(storyId)
          .update({
        'reactions.$currentUserId': reaction,
        'reactedAt.$currentUserId': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        developer.log('✅ Reaction sent: $reaction', name: 'NotificationController');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('❌ Error sending reaction: $e', name: 'NotificationController');
      }
    }
  }
}

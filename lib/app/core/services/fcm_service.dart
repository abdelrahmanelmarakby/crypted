import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Production-grade FCM Service for 1M+ users
/// Handles all push notifications with proper routing and state management
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _isInitialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final settings = await _requestPermissions();
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('⚠️ Notification permissions not granted');
        }
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      await _getFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM Service: $e');
      }
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Messages channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'New message notifications',
        importance: Importance.high,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Calls channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'calls',
        'Calls',
        description: 'Incoming call notifications',
        importance: Importance.max,
        enableVibration: true,
        showBadge: true,
        playSound: true,
      ),
    );

    // Stories channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'stories',
        'Stories',
        description: 'New story notifications',
        importance: Importance.defaultImportance,
        enableVibration: false,
        showBadge: true,
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'general',
        'General',
        description: 'General notifications',
        importance: Importance.defaultImportance,
        enableVibration: true,
        showBadge: true,
      ),
    );
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveFCMToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('fcmTokens')
          .doc(token)
          .set({
        'uid': userId,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String token) async {
    _currentToken = token;
    await _saveFCMToken(token);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📨 Foreground message received: ${message.data}');
    }

    final type = message.data['type'] as String?;

    switch (type) {
      case 'new_message':
        _handleNewMessageNotification(message);
        break;
      case 'incoming_call':
        _handleIncomingCallNotification(message);
        break;
      case 'typing_indicator':
        _handleTypingIndicator(message);
        break;
      case 'presence_update':
        _handlePresenceUpdate(message);
        break;
      case 'read_receipt':
        _handleReadReceipt(message);
        break;
      case 'new_story':
        _handleNewStoryNotification(message);
        break;
      case 'backup_completed':
        _handleBackupNotification(message);
        break;
      default:
        _showLocalNotification(message);
    }
  }

  /// Handle new message notification
  void _handleNewMessageNotification(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    final messageId = message.data['messageId'] as String?;

    // Show local notification
    _showLocalNotification(
      message,
      channelId: 'messages',
      payload: 'chat:$chatId',
    );

    // Update chat list if visible
    // This will be handled by Firestore listeners
  }

  /// Handle incoming call notification
  void _handleIncomingCallNotification(RemoteMessage message) {
    final callId = message.data['callId'] as String?;
    final callerId = message.data['callerId'] as String?;
    final callerName = message.data['callerName'] as String?;
    final callType = message.data['callType'] as String?;

    // Navigate to call screen
    if (callId != null) {
      Get.toNamed(
        Routes.CALL,
        arguments: {
          'callId': callId,
          'callerId': callerId,
          'callerName': callerName,
          'callType': callType,
          'isIncoming': true,
        },
      );
    }
  }

  /// Handle typing indicator
  void _handleTypingIndicator(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    final userId = message.data['userId'] as String?;
    final isTyping = message.data['isTyping'] == 'true';

    if (chatId != null && userId != null) {
      // Emit event for chat screen to handle
      Get.find<dynamic>().updateTypingStatus?.call(chatId, userId, isTyping);
    }
  }

  /// Handle presence update
  void _handlePresenceUpdate(RemoteMessage message) {
    final userId = message.data['userId'] as String?;
    final status = message.data['status'] as String?;

    if (userId != null && status != null) {
      // Emit event for UI to update
      Get.find<dynamic>().updateUserPresence?.call(userId, status == 'online');
    }
  }

  /// Handle read receipt
  void _handleReadReceipt(RemoteMessage message) {
    final messageId = message.data['messageId'] as String?;
    final readBy = message.data['readBy'] as String?;

    if (messageId != null && readBy != null) {
      // Update message status in cache
      // This will be handled by Firestore listeners
    }
  }

  /// Handle new story notification
  void _handleNewStoryNotification(RemoteMessage message) {
    final storyId = message.data['storyId'] as String?;
    final userId = message.data['userId'] as String?;

    _showLocalNotification(
      message,
      channelId: 'stories',
      payload: 'story:$userId',
    );
  }

  /// Handle backup notification
  void _handleBackupNotification(RemoteMessage message) {
    _showLocalNotification(
      message,
      channelId: 'general',
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification(
    RemoteMessage message, {
    String channelId = 'general',
    String? payload,
  }) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId.capitalize ?? channelId,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: payload ?? message.data['chatId'] as String?,
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final chatId = message.data['chatId'] as String?;
    final callId = message.data['callId'] as String?;
    final storyId = message.data['storyId'] as String?;
    final userId = message.data['userId'] as String?;

    if (kDebugMode) {
      print('🔔 Notification tapped: $type');
    }

    switch (type) {
      case 'new_message':
        if (chatId != null) {
          Get.toNamed(Routes.CHAT, arguments: {'chatId': chatId});
        }
        break;
      case 'incoming_call':
        if (callId != null) {
          Get.toNamed(Routes.CALL, arguments: {'callId': callId});
        }
        break;
      case 'new_story':
        if (userId != null) {
          Get.toNamed(Routes.STORIES, arguments: {'userId': userId});
        }
        break;
      default:
        // Navigate to home
        Get.toNamed(Routes.HOME);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    if (payload.startsWith('chat:')) {
      final chatId = payload.substring(5);
      Get.toNamed(Routes.CHAT, arguments: {'chatId': chatId});
    } else if (payload.startsWith('story:')) {
      final userId = payload.substring(6);
      Get.toNamed(Routes.STORIES, arguments: {'userId': userId});
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteFCMToken() async {
    try {
      if (_currentToken != null) {
        await FirebaseFirestore.instance
            .collection('fcmTokens')
            .doc(_currentToken)
            .delete();
      }
      await _messaging.deleteToken();
      _currentToken = null;

      if (kDebugMode) {
        print('✅ FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }

  /// Get current token
  String? get currentToken => _currentToken;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📨 Background message received: ${message.messageId}');
  }
  // Handle background message
  // Note: Cannot use Get.toNamed here as app might not be running
}

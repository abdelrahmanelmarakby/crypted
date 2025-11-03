import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification settings data model
class NotificationSettings {
  // Messages
  final bool showMessageNotifications;
  final String messageSound;
  final bool messageReactions;

  // Groups
  final bool showGroupNotifications;
  final String groupSound;
  final bool groupReactions;

  // Status
  final String statusSound;
  final bool statusReactions;

  // Other
  final bool reminders;
  final bool showPreview;
  final DateTime updatedAt;

  NotificationSettings({
    this.showMessageNotifications = true,
    this.messageSound = 'Note',
    this.messageReactions = true,
    this.showGroupNotifications = true,
    this.groupSound = 'Note',
    this.groupReactions = true,
    this.statusSound = 'Note',
    this.statusReactions = true,
    this.reminders = true,
    this.showPreview = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'showMessageNotifications': showMessageNotifications,
      'messageSound': messageSound,
      'messageReactions': messageReactions,
      'showGroupNotifications': showGroupNotifications,
      'groupSound': groupSound,
      'groupReactions': groupReactions,
      'statusSound': statusSound,
      'statusReactions': statusReactions,
      'reminders': reminders,
      'showPreview': showPreview,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      showMessageNotifications: map['showMessageNotifications'] ?? true,
      messageSound: map['messageSound'] ?? 'Note',
      messageReactions: map['messageReactions'] ?? true,
      showGroupNotifications: map['showGroupNotifications'] ?? true,
      groupSound: map['groupSound'] ?? 'Note',
      groupReactions: map['groupReactions'] ?? true,
      statusSound: map['statusSound'] ?? 'Note',
      statusReactions: map['statusReactions'] ?? true,
      reminders: map['reminders'] ?? true,
      showPreview: map['showPreview'] ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationSettings copyWith({
    bool? showMessageNotifications,
    String? messageSound,
    bool? messageReactions,
    bool? showGroupNotifications,
    String? groupSound,
    bool? groupReactions,
    String? statusSound,
    bool? statusReactions,
    bool? reminders,
    bool? showPreview,
  }) {
    return NotificationSettings(
      showMessageNotifications:
          showMessageNotifications ?? this.showMessageNotifications,
      messageSound: messageSound ?? this.messageSound,
      messageReactions: messageReactions ?? this.messageReactions,
      showGroupNotifications:
          showGroupNotifications ?? this.showGroupNotifications,
      groupSound: groupSound ?? this.groupSound,
      groupReactions: groupReactions ?? this.groupReactions,
      statusSound: statusSound ?? this.statusSound,
      statusReactions: statusReactions ?? this.statusReactions,
      reminders: reminders ?? this.reminders,
      showPreview: showPreview ?? this.showPreview,
    );
  }
}

/// Clean and simple notification data source
class NotificationDataSourceNew {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get notification settings for a user
  Future<NotificationSettings?> getNotificationSettings(String userId) async {
    try {
      developer.log(
        'Loading notification settings for user: $userId',
        name: 'NotificationDataSource',
      );

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        developer.log(
          'User document not found',
          name: 'NotificationDataSource',
          level: 900,
        );
        return null;
      }

      final data = doc.data();
      if (data == null || data['notificationSettings'] == null) {
        developer.log(
          'No notification settings found, using defaults',
          name: 'NotificationDataSource',
        );
        return NotificationSettings();
      }

      final settings = NotificationSettings.fromMap(
        Map<String, dynamic>.from(data['notificationSettings']),
      );

      developer.log(
        'Notification settings loaded successfully',
        name: 'NotificationDataSource',
      );

      return settings;
    } catch (e, stackTrace) {
      developer.log(
        'Error loading notification settings',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Save notification settings for a user
  Future<bool> saveNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      developer.log(
        'Saving notification settings for user: $userId',
        name: 'NotificationDataSource',
      );

      await _firestore.collection('users').doc(userId).set({
        'notificationSettings': settings.toMap(),
      }, SetOptions(merge: true));

      developer.log(
        'Notification settings saved successfully',
        name: 'NotificationDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving notification settings',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Stream notification settings changes
  Stream<NotificationSettings?> watchNotificationSettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null || data['notificationSettings'] == null) {
        return NotificationSettings();
      }

      return NotificationSettings.fromMap(
        Map<String, dynamic>.from(data['notificationSettings']),
      );
    });
  }

  /// Reset notification settings to defaults
  Future<bool> resetNotificationSettings(String userId) async {
    try {
      developer.log(
        'Resetting notification settings for user: $userId',
        name: 'NotificationDataSource',
      );

      final defaultSettings = NotificationSettings();
      await _firestore.collection('users').doc(userId).set({
        'notificationSettings': defaultSettings.toMap(),
      }, SetOptions(merge: true));

      developer.log(
        'Notification settings reset successfully',
        name: 'NotificationDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error resetting notification settings',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Update FCM token for notifications
  Future<bool> updateFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('fcmTokens').doc(token).set({
        'uid': userId,
        'token': token,
        'platform': 'flutter',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'FCM token updated successfully',
        name: 'NotificationDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating FCM token',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Remove FCM token
  Future<bool> removeFCMToken(String token) async {
    try {
      await _firestore.collection('fcmTokens').doc(token).delete();

      developer.log(
        'FCM token removed successfully',
        name: 'NotificationDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error removing FCM token',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }
}

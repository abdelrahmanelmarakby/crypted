import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/notification_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class NotificationDataSource {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  /// Get current user's notification settings
  Future<NotificationModel?> getNotificationSettings() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        developer.log(
          'No current user found for notification settings',
          name: 'NotificationDataSource',
          level: 900, // WARNING level
        );
        return null;
      }

      developer.log(
        'Fetching notification settings for user: $currentUserId',
        name: 'NotificationDataSource',
      );

      // Get user document
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await firebaseFirestore.collection(FirebaseCollections.users).doc(currentUserId).get();

      if (!userDoc.exists) {
        developer.log(
          'User document not found for: $currentUserId',
          name: 'NotificationDataSource',
          level: 900,
        );
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        developer.log(
          'User data is null for: $currentUserId',
          name: 'NotificationDataSource',
          level: 900,
        );
        return null;
      }

      // Extract notification settings from user document
      final notificationData = userData['notificationSettings'];
      if (notificationData == null) {
        developer.log(
          'No notification settings found, returning default',
          name: 'NotificationDataSource',
        );
        return _getDefaultNotificationSettings();
      }

      developer.log(
        'Successfully loaded notification settings',
        name: 'NotificationDataSource',
      );

      return NotificationModel.fromMap(Map<String, dynamic>.from(notificationData));
    } catch (e, stackTrace) {
      developer.log(
        'Error getting notification settings',
        name: 'NotificationDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
      );
      return null;
    }
  }

  /// Save notification settings to current user's document
  Future<bool> saveNotificationSettings(NotificationModel notification) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        developer.log(
          'No current user found for saving notification settings',
          name: 'NotificationDataSource',
          level: 900,
        );
        return false;
      }

      developer.log(
        'Saving notification settings for user: $currentUserId',
        name: 'NotificationDataSource',
      );

      // Update user document with notification settings
      await firebaseFirestore.collection(FirebaseCollections.users).doc(currentUserId).update({
        'notificationSettings': notification.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

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

  /// Get default notification settings
  NotificationModel _getDefaultNotificationSettings() {
    return NotificationModel(
      showMessageNotification: true,
      soundMessage: 'Note',
      reactionMessageNotification: true,
      showGroupNotification: true,
      soundGroup: 'Note',
      reactionGroupNotification: true,
      soundStatus: 'Note',
      reactionStatusNotification: true,
      reminderNotification: true,
      showPreviewNotification: true,
    );
  }

  /// Update specific notification setting
  Future<bool> updateNotificationSetting(String field, dynamic value) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for updating notification setting');
        return false;
      }

      await firebaseFirestore.collection(FirebaseCollections.users).doc(currentUserId).update({
        'notificationSettings.$field': value,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Notification setting $field updated to $value');
      return true;
    } catch (e) {
      print('❌ Error updating notification setting: $e');
      return false;
    }
  }
}

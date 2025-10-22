import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/notification_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class NotificationDataSource {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  /// Get current user's notification settings
  Future<NotificationModel?> getNotificationSettings() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for notification settings');
        return null;
      }

      // Get user document
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await firebaseFirestore.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) {
        print('❌ User document not found');
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ User data is null');
        return null;
      }

      // Extract notification settings from user document
      final notificationData = userData['notificationSettings'];
      if (notificationData == null) {
        print('ℹ️ No notification settings found, returning default');
        return _getDefaultNotificationSettings();
      }

      return NotificationModel.fromMap(Map<String, dynamic>.from(notificationData));
    } catch (e) {
      print('❌ Error getting notification settings: $e');
      return null;
    }
  }

  /// Save notification settings to current user's document
  Future<bool> saveNotificationSettings(NotificationModel notification) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for saving notification settings');
        return false;
      }

      // Update user document with notification settings
      await firebaseFirestore.collection('users').doc(currentUserId).update({
        'notificationSettings': notification.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Notification settings saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving notification settings: $e');
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

      await firebaseFirestore.collection('users').doc(currentUserId).update({
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

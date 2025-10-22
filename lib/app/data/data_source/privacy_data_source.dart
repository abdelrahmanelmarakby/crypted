import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/privacy_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

class PrivacyDataSource {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  /// Get current user's privacy settings
  Future<Privacy?> getPrivacySettings() async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for privacy settings');
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

      // Extract privacy settings from user document
      final privacyData = userData['privacySettings'];
      if (privacyData == null) {
        print('ℹ️ No privacy settings found, returning default');
        return _getDefaultPrivacySettings();
      }

      return Privacy.fromMap(Map<String, dynamic>.from(privacyData));
    } catch (e) {
      print('❌ Error getting privacy settings: $e');
      return null;
    }
  }

  /// Save privacy settings to current user's document
  Future<bool> savePrivacySettings(Privacy privacy) async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for saving privacy settings');
        return false;
      }

      // Update user document with privacy settings
      await firebaseFirestore.collection('users').doc(currentUserId).update({
        'privacySettings': privacy.toMap(),
      });

      print('✅ Privacy settings saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving privacy settings: $e');
      return false;
    }
  }

  /// Get default privacy settings
  Privacy _getDefaultPrivacySettings() {
    return Privacy(
      lastSeen: PrivacyLevel.nobody,
      profilePicture: ProfilePictureLevel.everyone,
      about: PrivacyLevel.everyone,
      groups: PrivacyLevel.everyone,
      status: PrivacyLevel.myContacts,
      liveLocation: LiveLocationLevel.none,
      calls: '',
      blocked: BlockedLevel.contacts,
      timer: false,
      receipts: true,
      appLock: '',
      chatLock: '',
      allowCamera: true,
      advanced: '',
      checkup: '',
      defaultMessageTimer: MessageTimerLevel.off,
    );
  }

  /// Update specific privacy setting
  Future<bool> updatePrivacySetting(String field, dynamic value) async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for updating privacy setting');
        return false;
      }

      await firebaseFirestore.collection('users').doc(currentUserId).update({
        'privacySettings.$field': value,
      });

      print('✅ Privacy setting $field updated to $value');
      return true;
    } catch (e) {
      print('❌ Error updating privacy setting: $e');
      return false;
    }
  }

  /// Get list of chats where user is sharing live location
  Future<List<String>> getLiveLocationChats() async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        return [];
      }

      // Query chats where current user is sharing live location
      QuerySnapshot chatSnapshot = await firebaseFirestore
          .collection('chats')
          .where('liveLocationUsers', arrayContains: currentUserId)
          .get();

      return chatSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Error getting live location chats: $e');
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/user_model.dart';

class PrivacyDataSource {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  /// Get current user's privacy settings
  Future<PrivacySettings?> getPrivacySettings() async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
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
        return PrivacySettings.defaultSettings();
      }

      return PrivacySettings.fromMap(Map<String, dynamic>.from(privacyData));
    } catch (e) {
      print('❌ Error getting privacy settings: $e');
      return null;
    }
  }

  /// Save privacy settings to current user's document
  Future<bool> savePrivacySettings(PrivacySettings privacy) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
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

  /// Update specific privacy setting
  Future<bool> updatePrivacySetting(String field, dynamic value) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
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
      final currentUserId = UserService.currentUserValue?.uid;
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

  /// Stop sharing live location with a specific chat
  Future<bool> stopSharingLiveLocation(String chatId) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid;
      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No current user found for stopping location sharing');
        return false;
      }

      // Remove current user from liveLocationUsers array in chat document
      await firebaseFirestore.collection('chats').doc(chatId).update({
        'liveLocationUsers': FieldValue.arrayRemove([currentUserId]),
      });

      // Delete any active location messages for this user in this chat
      final locationMessages = await firebaseFirestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: currentUserId)
          .where('type', isEqualTo: 'location')
          .where('isLiveLocation', isEqualTo: true)
          .get();

      // Update messages to mark live location as stopped
      for (var doc in locationMessages.docs) {
        await doc.reference.update({
          'isLiveLocation': false,
          'locationStoppedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Location sharing stopped for chat: $chatId');
      return true;
    } catch (e) {
      print('❌ Error stopping location sharing: $e');
      return false;
    }
  }
}

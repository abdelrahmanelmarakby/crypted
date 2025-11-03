import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Privacy settings data model
class PrivacySettings {
  final bool showProfilePhotoToEveryone;
  final bool showLastSeenToEveryone;
  final bool showAboutToEveryone;
  final bool showStatusToEveryone;
  final bool allowGroupInvitesFromAnyone;
  final bool readReceiptsEnabled;
  final bool cameraEffectsEnabled;
  final String disappearingMessagesTimer; // 'Off', '24 Hours', '7 Days', '90 Days'
  final DateTime updatedAt;

  PrivacySettings({
    this.showProfilePhotoToEveryone = true,
    this.showLastSeenToEveryone = true,
    this.showAboutToEveryone = true,
    this.showStatusToEveryone = true,
    this.allowGroupInvitesFromAnyone = true,
    this.readReceiptsEnabled = true,
    this.cameraEffectsEnabled = true,
    this.disappearingMessagesTimer = 'Off',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'showProfilePhotoToEveryone': showProfilePhotoToEveryone,
      'showLastSeenToEveryone': showLastSeenToEveryone,
      'showAboutToEveryone': showAboutToEveryone,
      'showStatusToEveryone': showStatusToEveryone,
      'allowGroupInvitesFromAnyone': allowGroupInvitesFromAnyone,
      'readReceiptsEnabled': readReceiptsEnabled,
      'cameraEffectsEnabled': cameraEffectsEnabled,
      'disappearingMessagesTimer': disappearingMessagesTimer,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      showProfilePhotoToEveryone: map['showProfilePhotoToEveryone'] ?? true,
      showLastSeenToEveryone: map['showLastSeenToEveryone'] ?? true,
      showAboutToEveryone: map['showAboutToEveryone'] ?? true,
      showStatusToEveryone: map['showStatusToEveryone'] ?? true,
      allowGroupInvitesFromAnyone: map['allowGroupInvitesFromAnyone'] ?? true,
      readReceiptsEnabled: map['readReceiptsEnabled'] ?? true,
      cameraEffectsEnabled: map['cameraEffectsEnabled'] ?? true,
      disappearingMessagesTimer: map['disappearingMessagesTimer'] ?? 'Off',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PrivacySettings copyWith({
    bool? showProfilePhotoToEveryone,
    bool? showLastSeenToEveryone,
    bool? showAboutToEveryone,
    bool? showStatusToEveryone,
    bool? allowGroupInvitesFromAnyone,
    bool? readReceiptsEnabled,
    bool? cameraEffectsEnabled,
    String? disappearingMessagesTimer,
  }) {
    return PrivacySettings(
      showProfilePhotoToEveryone:
          showProfilePhotoToEveryone ?? this.showProfilePhotoToEveryone,
      showLastSeenToEveryone:
          showLastSeenToEveryone ?? this.showLastSeenToEveryone,
      showAboutToEveryone: showAboutToEveryone ?? this.showAboutToEveryone,
      showStatusToEveryone: showStatusToEveryone ?? this.showStatusToEveryone,
      allowGroupInvitesFromAnyone:
          allowGroupInvitesFromAnyone ?? this.allowGroupInvitesFromAnyone,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      cameraEffectsEnabled: cameraEffectsEnabled ?? this.cameraEffectsEnabled,
      disappearingMessagesTimer:
          disappearingMessagesTimer ?? this.disappearingMessagesTimer,
    );
  }
}

/// Clean and simple privacy data source
class PrivacyDataSourceNew {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get privacy settings for a user
  Future<PrivacySettings?> getPrivacySettings(String userId) async {
    try {
      developer.log(
        'Loading privacy settings for user: $userId',
        name: 'PrivacyDataSource',
      );

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        developer.log(
          'User document not found',
          name: 'PrivacyDataSource',
          level: 900,
        );
        return null;
      }

      final data = doc.data();
      if (data == null || data['privacySettings'] == null) {
        developer.log(
          'No privacy settings found, using defaults',
          name: 'PrivacyDataSource',
        );
        return PrivacySettings();
      }

      final settings = PrivacySettings.fromMap(
        Map<String, dynamic>.from(data['privacySettings']),
      );

      developer.log(
        'Privacy settings loaded successfully',
        name: 'PrivacyDataSource',
      );

      return settings;
    } catch (e, stackTrace) {
      developer.log(
        'Error loading privacy settings',
        name: 'PrivacyDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  /// Save privacy settings for a user
  Future<bool> savePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      developer.log(
        'Saving privacy settings for user: $userId',
        name: 'PrivacyDataSource',
      );

      await _firestore.collection('users').doc(userId).set({
        'privacySettings': settings.toMap(),
      }, SetOptions(merge: true));

      developer.log(
        'Privacy settings saved successfully',
        name: 'PrivacyDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving privacy settings',
        name: 'PrivacyDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Stream privacy settings changes
  Stream<PrivacySettings?> watchPrivacySettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null || data['privacySettings'] == null) {
        return PrivacySettings();
      }

      return PrivacySettings.fromMap(
        Map<String, dynamic>.from(data['privacySettings']),
      );
    });
  }

  /// Get blocked users list
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null || data['blockedUsers'] == null) return [];

      return List<String>.from(data['blockedUsers']);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting blocked users',
        name: 'PrivacyDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return [];
    }
  }

  /// Block a user
  Future<bool> blockUser(String userId, String userToBlock) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayUnion([userToBlock]),
      });

      developer.log(
        'User $userToBlock blocked successfully',
        name: 'PrivacyDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error blocking user',
        name: 'PrivacyDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId, String userToUnblock) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([userToUnblock]),
      });

      developer.log(
        'User $userToUnblock unblocked successfully',
        name: 'PrivacyDataSource',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error unblocking user',
        name: 'PrivacyDataSource',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return false;
    }
  }
}

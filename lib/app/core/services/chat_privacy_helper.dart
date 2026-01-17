import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Chat Privacy Helper Service
/// Provides centralized privacy checks for chat functionality including:
/// - Blocking checks
/// - Message forwarding permissions
/// - Screenshot protection
/// - Content copying restrictions
class ChatPrivacyHelper {
  static final ChatPrivacyHelper _instance = ChatPrivacyHelper._internal();
  factory ChatPrivacyHelper() => _instance;
  ChatPrivacyHelper._internal();

  // Privacy settings service reference (lazy loaded)
  PrivacySettingsService? _privacyService;

  PrivacySettingsService? get _privacy {
    if (_privacyService == null) {
      try {
        _privacyService = Get.find<PrivacySettingsService>();
      } catch (_) {
        // Service not registered yet
      }
    }
    return _privacyService;
  }

  // ============================================================================
  // BLOCKING CHECKS
  // ============================================================================

  /// Check if current user has blocked a user
  bool isUserBlocked(String userId) {
    return _privacy?.isUserBlocked(userId) ?? false;
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedBy(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final blockedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('blocked')
          .doc(currentUserId)
          .get();
      return blockedDoc.exists;
    } catch (e) {
      developer.log('Error checking if blocked by: $e', name: 'ChatPrivacyHelper');
      return false;
    }
  }

  /// Check if there's a mutual block between users
  Future<bool> hasMutualBlock(String userId) async {
    if (isUserBlocked(userId)) return true;
    return await isBlockedBy(userId);
  }

  /// Check if user can send message to another user
  Future<ChatPermissionResult> canSendMessageTo(String recipientId) async {
    // Check if blocked
    if (isUserBlocked(recipientId)) {
      return ChatPermissionResult(
        allowed: false,
        reason: 'You have blocked this user',
        errorCode: 'BLOCKED_BY_ME',
      );
    }

    // Check if blocked by recipient
    final blockedByRecipient = await isBlockedBy(recipientId);
    if (blockedByRecipient) {
      return ChatPermissionResult(
        allowed: false,
        reason: 'You cannot send messages to this user',
        errorCode: 'BLOCKED_BY_THEM',
      );
    }

    // Check recipient's privacy settings
    try {
      final recipientPrivacy = await _getPrivacySettings(recipientId);
      if (recipientPrivacy == null) {
        return ChatPermissionResult(allowed: true);
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'Not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      final isContact = await _isContact(recipientId);
      final canMessage = recipientPrivacy.communication.whoCanMessage.isVisibleTo(
        currentUserId,
        isContact: isContact,
      );

      if (!canMessage) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'This user does not accept messages from you',
          errorCode: 'PRIVACY_RESTRICTED',
        );
      }

      return ChatPermissionResult(allowed: true);
    } catch (e) {
      developer.log('Error checking message permission: $e', name: 'ChatPrivacyHelper');
      // Default to allowed on error to not break existing functionality
      return ChatPermissionResult(allowed: true);
    }
  }

  /// Check if user can call another user
  Future<ChatPermissionResult> canCallUser(String recipientId) async {
    // Check if blocked
    if (isUserBlocked(recipientId)) {
      return ChatPermissionResult(
        allowed: false,
        reason: 'You have blocked this user',
        errorCode: 'BLOCKED_BY_ME',
      );
    }

    final blockedByRecipient = await isBlockedBy(recipientId);
    if (blockedByRecipient) {
      return ChatPermissionResult(
        allowed: false,
        reason: 'You cannot call this user',
        errorCode: 'BLOCKED_BY_THEM',
      );
    }

    // Check recipient's privacy settings
    try {
      final recipientPrivacy = await _getPrivacySettings(recipientId);
      if (recipientPrivacy == null) {
        return ChatPermissionResult(allowed: true);
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'Not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      final isContact = await _isContact(recipientId);
      final canCall = recipientPrivacy.communication.whoCanCall.isVisibleTo(
        currentUserId,
        isContact: isContact,
      );

      if (!canCall) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'This user does not accept calls from you',
          errorCode: 'PRIVACY_RESTRICTED',
        );
      }

      return ChatPermissionResult(allowed: true);
    } catch (e) {
      developer.log('Error checking call permission: $e', name: 'ChatPrivacyHelper');
      return ChatPermissionResult(allowed: true);
    }
  }

  // ============================================================================
  // CONTENT PROTECTION
  // ============================================================================

  /// Check if message forwarding is allowed
  bool get isForwardingAllowed {
    final settings = _privacy?.settings.value.contentProtection;
    return settings?.allowForwarding ?? true;
  }

  /// Check if copying text is allowed
  bool get isCopyingAllowed {
    final settings = _privacy?.settings.value.contentProtection;
    return settings?.allowCopyingText ?? true;
  }

  /// Check if screenshots are allowed
  bool get areScreenshotsAllowed {
    final settings = _privacy?.settings.value.contentProtection;
    return settings?.allowScreenshots ?? true;
  }

  /// Check if chat/message can be forwarded
  /// Takes into account both sender's and current user's settings
  Future<bool> canForwardMessage({
    required String senderId,
    required String chatId,
  }) async {
    // First check current user's settings
    if (!isForwardingAllowed) {
      return false;
    }

    // Check if the original sender has disabled forwarding
    try {
      final senderPrivacy = await _getPrivacySettings(senderId);
      if (senderPrivacy != null && !senderPrivacy.contentProtection.allowForwarding) {
        return false;
      }
    } catch (e) {
      developer.log('Error checking sender forwarding settings: $e', name: 'ChatPrivacyHelper');
    }

    return true;
  }

  /// Get disappearing message duration for a chat
  DisappearingDuration getDisappearingDuration() {
    final settings = _privacy?.settings.value.contentProtection;
    return settings?.defaultDisappearingDuration ?? DisappearingDuration.off;
  }

  // ============================================================================
  // GROUP PERMISSIONS
  // ============================================================================

  /// Check if user can be added to a group
  Future<ChatPermissionResult> canAddToGroup(String userId) async {
    try {
      final userPrivacy = await _getPrivacySettings(userId);
      if (userPrivacy == null) {
        return ChatPermissionResult(allowed: true);
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'Not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      final isContact = await _isContactOfUser(userId, currentUserId);
      final canAdd = userPrivacy.communication.whoCanAddToGroups.isVisibleTo(
        currentUserId,
        isContact: isContact,
      );

      if (!canAdd) {
        return ChatPermissionResult(
          allowed: false,
          reason: 'This user does not allow being added to groups by you',
          errorCode: 'PRIVACY_RESTRICTED',
        );
      }

      return ChatPermissionResult(allowed: true);
    } catch (e) {
      developer.log('Error checking group add permission: $e', name: 'ChatPrivacyHelper');
      return ChatPermissionResult(allowed: true);
    }
  }

  // ============================================================================
  // CHAT UI HELPERS
  // ============================================================================

  /// Get blocked user message for display
  String getBlockedUserMessage(bool blockedByMe, bool blockedByThem) {
    if (blockedByMe && blockedByThem) {
      return 'You cannot communicate with this user';
    } else if (blockedByMe) {
      return 'You blocked this user. Unblock to send messages.';
    } else if (blockedByThem) {
      return 'You cannot send messages to this user';
    }
    return '';
  }

  /// Check if should show "message cannot be sent" banner
  Future<BlockedChatInfo> getBlockedChatInfo(String otherUserId) async {
    final blockedByMe = isUserBlocked(otherUserId);
    final blockedByThem = await isBlockedBy(otherUserId);

    return BlockedChatInfo(
      isBlocked: blockedByMe || blockedByThem,
      blockedByMe: blockedByMe,
      blockedByThem: blockedByThem,
      message: getBlockedUserMessage(blockedByMe, blockedByThem),
    );
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<EnhancedPrivacySettingsModel?> _getPrivacySettings(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('privacy')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return EnhancedPrivacySettingsModel.fromMap(doc.data());
    } catch (e) {
      developer.log('Error getting privacy settings: $e', name: 'ChatPrivacyHelper');
      return null;
    }
  }

  Future<bool> _isContact(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(targetUserId)
          .get();
      return contactDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isContactOfUser(String userId, String contactId) async {
    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .get();
      return contactDoc.exists;
    } catch (e) {
      return false;
    }
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Result of a chat permission check
class ChatPermissionResult {
  final bool allowed;
  final String? reason;
  final String? errorCode;

  const ChatPermissionResult({
    required this.allowed,
    this.reason,
    this.errorCode,
  });
}

/// Information about blocked chat status
class BlockedChatInfo {
  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedByThem;
  final String message;

  const BlockedChatInfo({
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedByThem,
    required this.message,
  });
}

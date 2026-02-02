import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Production-grade Presence Service for 1M+ users
/// Manages user online/offline status using Firebase Realtime Database
/// Migrated from Firestore for 100x cost reduction and better performance
/// Includes privacy-aware presence visibility
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  // Firebase Realtime Database reference
  final DatabaseReference _presenceRef =
      FirebaseDatabase.instance.ref('presence');
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Presence cache for faster lookups
  final RxMap<String, Map<String, dynamic>> _presenceCache =
      <String, Map<String, dynamic>>{}.obs;

  String? _sessionId;
  bool _isOnline = false;
  bool _isInitialized = false;
  String? _deviceId;
  Timer? _heartbeatTimer;

  /// Initialize presence service
  Future<void> initialize() async {
    try {
      _deviceId = await _getDeviceId();
      _isInitialized = true;

      // Set user online automatically
      final user = _auth.currentUser;
      if (user != null) {
        await goOnline();
      }

      if (kDebugMode) {
        print('✅ Presence Service initialized with Realtime Database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Presence Service: $e');
      }
    }
  }

  /// Set user online using Realtime Database
  Future<void> goOnline() async {
    if (_isOnline) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Generate unique session ID
      _sessionId = const Uuid().v4();

      // Call Cloud Function to validate and set presence
      try {
        await _functions.httpsCallable('updatePresence').call({
          'userId': userId,
          'online': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (fnError) {
        if (kDebugMode) {
          print(
              '⚠️ Cloud Function updatePresence failed: $fnError (using fallback)');
        }
      }

      // Direct update to Realtime Database for faster response
      await _presenceRef.child(userId).set({
        'online': true,
        'lastSeen': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'deviceId': _deviceId ?? 'unknown',
        'platform': defaultTargetPlatform.name,
        'sessionId': _sessionId,
      });

      // Set up auto-offline on disconnect (native RTDB feature)
      await _presenceRef.child(userId).onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'deviceId': _deviceId ?? 'unknown',
        'platform': defaultTargetPlatform.name,
      });

      _isOnline = true;

      // Start heartbeat to prevent server cleanup from marking us offline.
      // The Cloud Function cleanupStalePresence marks users offline if
      // updatedAt is >5 min old, so we refresh every 2 minutes.
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(minutes: 2),
        (_) => refreshPresence(),
      );

      if (kDebugMode) {
        print('✅ User set online (RTDB): $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user online: $e');
      }
    }
  }

  /// Set user offline using Realtime Database
  Future<void> goOffline() async {
    if (!_isOnline) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update Realtime Database
      await _presenceRef.child(userId).set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
        'deviceId': _deviceId ?? 'unknown',
        'platform': defaultTargetPlatform.name,
      });

      // Cancel disconnect handler
      await _presenceRef.child(userId).onDisconnect().cancel();

      _isOnline = false;
      _sessionId = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      if (kDebugMode) {
        print('✅ User set offline (RTDB): $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user offline: $e');
      }
    }
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Listen to user online status from Realtime Database (privacy-aware)
  /// Returns false if:
  /// - User is blocked
  /// - User's privacy settings don't allow viewing online status
  Stream<bool> listenToUserOnlineStatus(String userId) {
    return _presenceRef.child(userId).onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return false;

      // Check privacy settings
      final visibilityResult = await _checkOnlineStatusVisibility(userId);
      if (!visibilityResult.canView) {
        return false;
      }

      return data['online'] == true;
    });
  }

  /// Get user last seen from Realtime Database (privacy-aware)
  /// Returns null if:
  /// - User is blocked
  /// - User's privacy settings don't allow viewing last seen
  Stream<DateTime?> listenToUserLastSeen(String userId) {
    return _presenceRef.child(userId).onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;

      // Check privacy settings
      final visibilityResult = await _checkLastSeenVisibility(userId);
      if (!visibilityResult.canView) {
        return null;
      }

      final lastSeenTimestamp = data['lastSeen'] as int?;
      return lastSeenTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp)
          : null;
    });
  }

  /// Privacy-aware presence stream from Realtime Database with visibility info
  Stream<PresenceInfo> listenToUserPresence(String userId) {
    return _presenceRef.child(userId).onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        return PresenceInfo(
          isOnline: false,
          lastSeen: null,
          isHiddenByPrivacy: false,
          isBlocked: false,
        );
      }

      // Check blocking first
      final isBlocked = await _checkIfBlocked(userId);
      if (isBlocked) {
        return PresenceInfo(
          isOnline: false,
          lastSeen: null,
          isHiddenByPrivacy: true,
          isBlocked: true,
        );
      }

      // Check online status visibility
      final onlineVisibility = await _checkOnlineStatusVisibility(userId);
      final lastSeenVisibility = await _checkLastSeenVisibility(userId);

      final isOnline =
          onlineVisibility.canView ? (data['online'] == true) : false;

      DateTime? lastSeen;
      if (lastSeenVisibility.canView) {
        final lastSeenTimestamp = data['lastSeen'] as int?;
        lastSeen = lastSeenTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp)
            : null;
      }

      // Update cache
      _presenceCache[userId] = {
        'online': data['online'] == true,
        'lastSeen': data['lastSeen'] ?? 0,
        'updatedAt': data['updatedAt'] ?? 0,
      };

      return PresenceInfo(
        isOnline: isOnline,
        lastSeen: lastSeen,
        isHiddenByPrivacy: !onlineVisibility.canView,
        isBlocked: false,
        hiddenReason: onlineVisibility.canView ? null : onlineVisibility.reason,
      );
    });
  }

  /// Get presence for a single user (one-time read)
  Future<Map<String, dynamic>> getPresence(String userId) async {
    try {
      // Check cache first
      if (_presenceCache.containsKey(userId)) {
        return _presenceCache[userId]!;
      }

      // Read from Realtime Database
      final snapshot = await _presenceRef.child(userId).get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final presence = {
          'online': data['online'] == true,
          'lastSeen': data['lastSeen'] ?? 0,
          'updatedAt': data['updatedAt'] ?? 0,
        };

        // Update cache
        _presenceCache[userId] = presence;

        return presence;
      }

      // Return offline if no presence data
      return {
        'online': false,
        'lastSeen': 0,
        'updatedAt': 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting presence for $userId: $e');
      }
      return {
        'online': false,
        'lastSeen': 0,
        'updatedAt': 0,
      };
    }
  }

  /// Get presence for multiple users in a single batch request via Cloud Function
  Future<Map<String, Map<String, dynamic>>> batchGetPresence(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    try {
      // Call Cloud Function for batch query
      final result = await _functions.httpsCallable('getPresence').call({
        'userIds': userIds,
      });

      final presenceData =
          Map<String, Map<String, dynamic>>.from(result.data['presence']);

      // Update cache
      _presenceCache.addAll(presenceData);

      return presenceData;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting batch presence (using fallback): $e');
      }

      // Fallback: read individually from RTDB
      final Map<String, Map<String, dynamic>> presenceMap = {};
      for (final uid in userIds) {
        presenceMap[uid] = await getPresence(uid);
      }
      return presenceMap;
    }
  }

  /// Get cached presence data (no network call)
  Map<String, dynamic>? getCachedPresence(String uid) {
    return _presenceCache[uid];
  }

  /// Check if a user is online (from cache)
  bool isUserOnline(String uid) {
    final presence = _presenceCache[uid];
    return presence?['online'] == true;
  }

  /// Get last seen timestamp for a user (from cache)
  int? getLastSeen(String uid) {
    final presence = _presenceCache[uid];
    return presence?['lastSeen'] as int?;
  }

  /// Check if user allows viewing their online status
  Future<VisibilityCheckResult> _checkOnlineStatusVisibility(
      String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return VisibilityCheckResult(canView: false, reason: 'Not authenticated');
    }

    // Always allow viewing own presence
    if (currentUserId == targetUserId) {
      return VisibilityCheckResult(canView: true);
    }

    // Check if blocked
    final isBlocked = await _checkIfBlocked(targetUserId);
    if (isBlocked) {
      return VisibilityCheckResult(canView: false, reason: 'User is blocked');
    }

    // Check target user's privacy settings
    try {
      final targetPrivacy = await _getTargetUserPrivacySettings(targetUserId);
      if (targetPrivacy == null) {
        // Default: allow if no privacy settings
        return VisibilityCheckResult(canView: true);
      }

      final isContact = await _checkIfContact(targetUserId);
      final onlineStatusSetting = targetPrivacy.profileVisibility.onlineStatus;

      final canView = onlineStatusSetting.isVisibleTo(
        currentUserId,
        isContact: isContact,
      );

      return VisibilityCheckResult(
        canView: canView,
        reason: canView ? null : 'Hidden by user\'s privacy settings',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking online status visibility: $e');
      }
      // Default: allow on error to prevent breaking existing functionality
      return VisibilityCheckResult(canView: true);
    }
  }

  /// Check if user allows viewing their last seen
  Future<VisibilityCheckResult> _checkLastSeenVisibility(
      String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return VisibilityCheckResult(canView: false, reason: 'Not authenticated');
    }

    // Always allow viewing own last seen
    if (currentUserId == targetUserId) {
      return VisibilityCheckResult(canView: true);
    }

    // Check if blocked
    final isBlocked = await _checkIfBlocked(targetUserId);
    if (isBlocked) {
      return VisibilityCheckResult(canView: false, reason: 'User is blocked');
    }

    // Check target user's privacy settings
    try {
      final targetPrivacy = await _getTargetUserPrivacySettings(targetUserId);
      if (targetPrivacy == null) {
        // Default: allow if no privacy settings
        return VisibilityCheckResult(canView: true);
      }

      final isContact = await _checkIfContact(targetUserId);
      final lastSeenSetting = targetPrivacy.profileVisibility.lastSeen;

      final canView = lastSeenSetting.isVisibleTo(
        currentUserId,
        isContact: isContact,
      );

      return VisibilityCheckResult(
        canView: canView,
        reason: canView ? null : 'Hidden by user\'s privacy settings',
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking last seen visibility: $e');
      }
      // Default: allow on error
      return VisibilityCheckResult(canView: true);
    }
  }

  /// Check if current user has blocked or is blocked by target user
  Future<bool> _checkIfBlocked(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    // Use local privacy service if available (faster)
    if (_privacy != null) {
      if (_privacy!.isUserBlocked(targetUserId)) {
        return true;
      }
    }

    // Check if current user blocked target
    try {
      final blockedDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUserId)
          .collection(FirebaseCollections.blocked)
          .doc(targetUserId)
          .get();
      if (blockedDoc.exists) return true;

      // Check if target user blocked current user
      final blockedByDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(targetUserId)
          .collection(FirebaseCollections.blocked)
          .doc(currentUserId)
          .get();
      if (blockedByDoc.exists) return true;

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking blocked status: $e');
      }
      return false;
    }
  }

  /// Check if target user is a contact
  Future<bool> _checkIfContact(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUserId)
          .collection(FirebaseCollections.contacts)
          .doc(targetUserId)
          .get();
      return contactDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get target user's privacy settings from Firestore
  Future<EnhancedPrivacySettingsModel?> _getTargetUserPrivacySettings(
      String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(userId)
          .collection(FirebaseCollections.private)
          .doc('privacy')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return EnhancedPrivacySettingsModel.fromMap(doc.data());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting target user privacy settings: $e');
      }
      return null;
    }
  }

  /// Format last seen text
  String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Last seen recently';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday at ${_formatTime(lastSeen)}';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} days ago';
    } else {
      return 'Last seen on ${_formatDate(lastSeen)}';
    }
  }

  /// Format time (HH:mm)
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format date (MMM dd)
  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  /// Clean up presence data for user (on logout)
  Future<void> cleanupPresence() async {
    try {
      await goOffline();

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Remove from Realtime Database
      await _presenceRef.child(userId).remove();

      // Clear cache
      _presenceCache.clear();

      if (kDebugMode) {
        print('✅ Presence cleaned up for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up presence: $e');
      }
    }
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Dispose resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isInitialized = false;
    _presenceCache.clear();

    if (kDebugMode) {
      print('🧹 PresenceService disposed');
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isOnline': _isOnline,
      'isInitialized': _isInitialized,
      'deviceId': _deviceId ?? 'unknown',
      'cachedPresenceCount': _presenceCache.length,
    };
  }

  /// Force refresh presence status
  /// Includes auth check — stops heartbeat if user logged out
  Future<void> refreshPresence() async {
    if (!_isOnline) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      // User logged out while heartbeat was running — clean up
      _isOnline = false;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _sessionId = null;
      if (kDebugMode) {
        print('⚠️ Heartbeat stopped: user no longer authenticated');
      }
      return;
    }

    try {
      await _presenceRef.child(userId).update({
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Heartbeat refresh failed: $e');
      }
    }
  }

  /// Format presence for display (privacy-aware version)
  String formatPresenceInfo(PresenceInfo presence) {
    if (presence.isBlocked) {
      return ''; // Don't show any presence info for blocked users
    }

    if (presence.isHiddenByPrivacy) {
      return ''; // Don't show any presence info if hidden
    }

    return formatLastSeen(presence.lastSeen, presence.isOnline);
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Result of a visibility check
class VisibilityCheckResult {
  final bool canView;
  final String? reason;

  const VisibilityCheckResult({
    required this.canView,
    this.reason,
  });
}

/// Complete presence information with privacy status
class PresenceInfo {
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isHiddenByPrivacy;
  final bool isBlocked;
  final String? hiddenReason;

  const PresenceInfo({
    required this.isOnline,
    this.lastSeen,
    required this.isHiddenByPrivacy,
    required this.isBlocked,
    this.hiddenReason,
  });

  /// Whether to show presence info at all
  bool get shouldShow => !isHiddenByPrivacy && !isBlocked;

  /// Get display text for presence
  String get displayText {
    if (isBlocked || isHiddenByPrivacy) return '';
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Last seen recently';
    return _formatLastSeen(lastSeen!);
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} days ago';
    } else {
      return 'Last seen on ${lastSeen.month}/${lastSeen.day}';
    }
  }

  @override
  String toString() {
    return 'PresenceInfo(isOnline: $isOnline, lastSeen: $lastSeen, isHiddenByPrivacy: $isHiddenByPrivacy, isBlocked: $isBlocked)';
  }
}

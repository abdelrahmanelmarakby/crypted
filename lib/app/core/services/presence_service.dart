import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Production-grade Presence Service for 1M+ users
/// Manages user online/offline status with heartbeat mechanism
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  String? _sessionId;
  Timer? _heartbeatTimer;
  Timer? _connectionCheckTimer;
  bool _isOnline = false;
  bool _isInitialized = false;
  String? _deviceId;

  /// Initialize presence service
  Future<void> initialize() async {
    try {
      _deviceId = await _getDeviceId();
      _isInitialized = true;

      // Start connection monitoring
      _startConnectionMonitoring();

      if (kDebugMode) {
        print('✅ Presence Service initialized with connection monitoring');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Presence Service: $e');
      }
    }
  }

  /// Start monitoring network connection state
  void _startConnectionMonitoring() {
    // Check connection every 30 seconds
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  /// Check if we're still connected and update presence accordingly
  Future<void> _checkConnection() async {
    if (!_isOnline) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        await goOffline();
        return;
      }

      // Try to read our presence document to verify connection
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ User document not found, going offline');
        }
        await goOffline();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Connection check failed: $e');
      }
      // Connection lost, mark as offline
      _isOnline = false;
      _heartbeatTimer?.cancel();
    }
  }

  /// Set user online
  Future<void> goOnline() async {
    if (_isOnline) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Generate unique session ID
      _sessionId = const Uuid().v4();

      // Create presence document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc(_sessionId)
          .set({
        'status': 'online',
        'lastUpdate': FieldValue.serverTimestamp(),
        'deviceId': _deviceId ?? 'unknown',
        'platform': defaultTargetPlatform.name,
      });

      // Update user's main document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _isOnline = true;

      // Start heartbeat timer (every 2 minutes)
      _startHeartbeat(userId);

      if (kDebugMode) {
        print('✅ User set online: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user online: $e');
      }
    }
  }

  /// Set user offline
  Future<void> goOffline() async {
    if (!_isOnline) return;

    try {
      // Stop heartbeat
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || _sessionId == null) return;

      // Update presence document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc(_sessionId)
          .update({
        'status': 'offline',
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      // Update user's main document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      _isOnline = false;
      _sessionId = null;

      if (kDebugMode) {
        print('✅ User set offline: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting user offline: $e');
      }
    }
  }

  /// Start heartbeat timer
  /// IMPROVED: Reduced from 2 minutes to 30 seconds for faster offline detection
  void _startHeartbeat(String userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30), // IMPROVED: was 2 minutes, now 30 seconds
      (_) => _updateHeartbeat(userId),
    );
  }

  /// Update heartbeat timestamp
  Future<void> _updateHeartbeat(String userId) async {
    if (_sessionId == null || !_isOnline) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('presence')
          .doc(_sessionId)
          .update({
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('💓 Heartbeat updated for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating heartbeat: $e');
      }
      // If heartbeat fails, try to go online again
      if (e.toString().contains('not-found')) {
        _isOnline = false;
        await goOnline();
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

  /// Listen to user online status
  Stream<bool> listenToUserOnlineStatus(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      return doc.data()?['isOnline'] ?? false;
    });
  }

  /// Get user last seen
  Stream<DateTime?> listenToUserLastSeen(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final lastSeen = doc.data()?['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    });
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  /// Clean up all presence documents for user (on logout)
  Future<void> cleanupPresence() async {
    try {
      await goOffline();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Delete all presence documents
      final presenceSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('presence')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in presenceSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

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
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    _isInitialized = false;

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
      'hasHeartbeat': _heartbeatTimer != null && _heartbeatTimer!.isActive,
      'hasConnectionCheck': _connectionCheckTimer != null && _connectionCheckTimer!.isActive,
    };
  }

  /// Force refresh presence status
  Future<void> refreshPresence() async {
    if (_isOnline) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateHeartbeat(userId);
      }
    }
  }
}

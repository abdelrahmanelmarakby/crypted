import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';

/// Activity types
enum ActivityType {
  viewing,      // User is viewing the chat (screen is visible)
  idle,         // User is in chat but inactive
  away,         // User left the chat
}

/// Production-grade Activity Status Service
/// Tracks user activity in chats (viewing, reading, idle states)
///
/// Features:
/// - Real-time activity status tracking
/// - Automatic idle detection
/// - Last active tracking per chat
/// - Activity duration analytics
/// - Battery-optimized updates
///
/// Usage:
/// ```dart
/// // Mark chat as being viewed
/// ActivityStatusService().setViewing(chatId);
///
/// // Mark as idle (no interaction)
/// ActivityStatusService().setIdle(chatId);
///
/// // Leave chat
/// ActivityStatusService().setAway(chatId);
///
/// // Listen to viewers
/// ActivityStatusService().listenToViewers(chatId).listen((viewers) {
///   // Update UI
/// });
/// ```
class ActivityStatusService {
  static final ActivityStatusService _instance = ActivityStatusService._internal();
  factory ActivityStatusService() => _instance;
  ActivityStatusService._internal();

  // Timers for idle detection
  final Map<String, Timer> _idleTimers = {};
  final Map<String, Timer> _updateTimers = {};

  // Current activity per chat
  final Map<String, ActivityType> _currentActivity = {};

  // Idle detection duration (no interaction for 30 seconds = idle)
  final Duration _idleDuration = const Duration(seconds: 30);

  // Update interval (send heartbeat every 10 seconds while viewing)
  final Duration _updateInterval = const Duration(seconds: 10);

  // Last activity timestamps
  final Map<String, DateTime> _lastActivityTime = {};

  /// Set user as viewing a chat
  Future<void> setViewing(String chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Update current activity
      _currentActivity[chatId] = ActivityType.viewing;
      _lastActivityTime[chatId] = DateTime.now();

      // Set activity in Firestore
      await _setActivityStatus(chatId, userId, ActivityType.viewing);

      // Start heartbeat updates
      _startHeartbeat(chatId, userId);

      // Start idle timer
      _restartIdleTimer(chatId);

      if (kDebugMode) {
        print('👁️ User viewing chat: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting viewing status: $e');
      }
    }
  }

  /// User interaction detected - reset idle timer
  Future<void> recordInteraction(String chatId) async {
    if (_currentActivity[chatId] == ActivityType.viewing) {
      _lastActivityTime[chatId] = DateTime.now();
      _restartIdleTimer(chatId);

      if (kDebugMode) {
        print('💬 Interaction recorded in chat: $chatId');
      }
    }
  }

  /// Set user as idle (in chat but no interaction)
  Future<void> setIdle(String chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      _currentActivity[chatId] = ActivityType.idle;

      // Stop heartbeat but keep presence
      _stopHeartbeat(chatId);

      await _setActivityStatus(chatId, userId, ActivityType.idle);

      if (kDebugMode) {
        print('💤 User idle in chat: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting idle status: $e');
      }
    }
  }

  /// Set user as away (left the chat)
  Future<void> setAway(String chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Clear timers
      _idleTimers[chatId]?.cancel();
      _idleTimers.remove(chatId);
      _stopHeartbeat(chatId);

      // Clear activity
      _currentActivity.remove(chatId);

      // Delete activity document
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.activity)
          .doc(userId)
          .delete();

      if (kDebugMode) {
        print('🚪 User left chat: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting away status: $e');
      }
    }
  }

  /// Set activity status in Firestore
  Future<void> _setActivityStatus(
    String chatId,
    String userId,
    ActivityType activityType,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(chatId)
          .collection(FirebaseCollections.activity)
          .doc(userId)
          .set({
        'userId': userId,
        'activityType': activityType.name,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating activity status: $e');
      }
    }
  }

  /// Start heartbeat updates while viewing
  void _startHeartbeat(String chatId, String userId) {
    _stopHeartbeat(chatId); // Stop existing timer

    _updateTimers[chatId] = Timer.periodic(_updateInterval, (_) async {
      if (_currentActivity[chatId] == ActivityType.viewing) {
        try {
          await FirebaseFirestore.instance
              .collection(FirebaseCollections.chats)
              .doc(chatId)
              .collection(FirebaseCollections.activity)
              .doc(userId)
              .update({
            'lastUpdate': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            print('💓 Activity heartbeat for chat: $chatId');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Heartbeat error: $e');
          }
        }
      } else {
        _stopHeartbeat(chatId);
      }
    });
  }

  /// Stop heartbeat updates
  void _stopHeartbeat(String chatId) {
    _updateTimers[chatId]?.cancel();
    _updateTimers.remove(chatId);
  }

  /// Restart idle timer
  void _restartIdleTimer(String chatId) {
    _idleTimers[chatId]?.cancel();

    _idleTimers[chatId] = Timer(_idleDuration, () {
      if (kDebugMode) {
        print('⏱️ User became idle in chat: $chatId');
      }
      setIdle(chatId);
    });
  }

  /// Listen to active viewers in a chat
  Stream<List<ActivityViewer>> listenToViewers(String chatId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection(FirebaseCollections.chats)
        .doc(chatId)
        .collection(FirebaseCollections.activity)
        .where('activityType', isEqualTo: 'viewing')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != userId) // Exclude current user
          .map((doc) {
        final data = doc.data();
        return ActivityViewer(
          userId: doc.id,
          activityType: _parseActivityType(data['activityType']),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
          lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
        );
      })
          .where((viewer) => !viewer.isStale) // Filter stale viewers
          .toList();
    });
  }

  /// Listen to all activity (viewing + idle) in a chat
  Stream<List<ActivityViewer>> listenToAllActivity(String chatId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection(FirebaseCollections.chats)
        .doc(chatId)
        .collection(FirebaseCollections.activity)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != userId)
          .map((doc) {
        final data = doc.data();
        return ActivityViewer(
          userId: doc.id,
          activityType: _parseActivityType(data['activityType']),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
          lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
        );
      })
          .where((viewer) => !viewer.isStale)
          .toList();
    });
  }

  /// Get viewer names
  Future<List<String>> getViewerNames(List<String> viewerIds) async {
    if (viewerIds.isEmpty) return [];

    try {
      final userDocs = await Future.wait(
        viewerIds.map((userId) =>
            FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(userId).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data()?['fullName'] as String? ?? doc.data()?['name'] as String? ?? 'Someone')
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting viewer names: $e');
      }
      return [];
    }
  }

  /// Format viewing indicator text
  String formatViewingText(List<String> names) {
    if (names.isEmpty) return '';

    if (names.length == 1) {
      return '👁️ ${names[0]} is viewing';
    } else if (names.length == 2) {
      return '👁️ ${names[0]} and ${names[1]} are viewing';
    } else {
      return '👁️ ${names[0]}, ${names[1]} and ${names.length - 2} others are viewing';
    }
  }

  /// Get current activity type for a chat
  ActivityType? getCurrentActivity(String chatId) {
    return _currentActivity[chatId];
  }

  /// Get last activity time for a chat
  DateTime? getLastActivityTime(String chatId) {
    return _lastActivityTime[chatId];
  }

  /// Get time spent in chat
  Duration? getTimeSpentInChat(String chatId) {
    final lastActivity = _lastActivityTime[chatId];
    if (lastActivity == null) return null;
    return DateTime.now().difference(lastActivity);
  }

  /// Clean up all activity indicators for user
  Future<void> cleanupActivity(String? chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (chatId != null) {
        // Clean up specific chat
        await setAway(chatId);
      } else {
        // Clean up all chats
        _idleTimers.forEach((chatId, timer) => timer.cancel());
        _idleTimers.clear();

        _updateTimers.forEach((chatId, timer) => timer.cancel());
        _updateTimers.clear();

        _currentActivity.clear();
        _lastActivityTime.clear();

        // Batch delete all activity documents
        final chatsSnapshot =
            await FirebaseFirestore.instance.collection(FirebaseCollections.chats).get();

        final batch = FirebaseFirestore.instance.batch();
        for (final chatDoc in chatsSnapshot.docs) {
          final activityDoc = chatDoc.reference.collection(FirebaseCollections.activity).doc(userId);
          batch.delete(activityDoc);
        }
        await batch.commit();
      }

      if (kDebugMode) {
        print('✅ Activity indicators cleaned up${chatId != null ? ' for chat: $chatId' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up activity: $e');
      }
    }
  }

  /// Parse activity type from string
  ActivityType _parseActivityType(String? type) {
    switch (type) {
      case 'viewing':
        return ActivityType.viewing;
      case 'idle':
        return ActivityType.idle;
      case 'away':
        return ActivityType.away;
      default:
        return ActivityType.away;
    }
  }

  /// Dispose resources
  void dispose() {
    _idleTimers.forEach((_, timer) => timer.cancel());
    _idleTimers.clear();

    _updateTimers.forEach((_, timer) => timer.cancel());
    _updateTimers.clear();

    _currentActivity.clear();
    _lastActivityTime.clear();

    if (kDebugMode) {
      print('🧹 ActivityStatusService disposed');
    }
  }
}

/// Activity viewer model
class ActivityViewer {
  final String userId;
  final ActivityType activityType;
  final DateTime? timestamp;
  final DateTime? lastUpdate;

  ActivityViewer({
    required this.userId,
    required this.activityType,
    this.timestamp,
    this.lastUpdate,
  });

  /// Check if activity is stale (no update in last 45 seconds)
  bool get isStale {
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate!) > const Duration(seconds: 45);
  }

  /// Get time since last update
  Duration? get timeSinceLastUpdate {
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate!);
  }

  /// Check if actively viewing (updated recently)
  bool get isActivelyViewing {
    return activityType == ActivityType.viewing && !isStale;
  }
}

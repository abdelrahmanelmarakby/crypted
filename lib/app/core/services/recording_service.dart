import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';

/// Production-grade Recording Service for voice message indicators
/// Manages recording status indicators with auto-stop and debouncing
///
/// Features:
/// - Real-time recording status broadcast
/// - Automatic cleanup after recording stops
/// - Debouncing to prevent flicker
/// - Integration with typing service (mutual exclusion)
/// - Stale indicator detection
///
/// Usage:
/// ```dart
/// // Start recording
/// RecordingService().startRecording(chatId);
///
/// // Stop recording
/// RecordingService().stopRecording(chatId);
///
/// // Listen to recording users
/// RecordingService().listenToRecordingUsers(chatId).listen((users) {
///   // Update UI
/// });
/// ```
class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  // Timers for auto-stop
  final Map<String, Timer> _recordingTimers = {};
  final Map<String, Timer> _debounceTimers = {};

  // Auto-stop duration (recording timeout)
  final Duration _autoStopDuration = const Duration(minutes: 10); // Max recording time
  final Duration _debounceDuration = const Duration(milliseconds: 200);

  // Track current recording state per chat
  final Map<String, bool> _isRecordingMap = {};

  /// Start recording in a chat
  Future<void> startRecording(String chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ Cannot start recording: No user logged in');
        }
        return;
      }

      // Check if already recording
      if (_isRecordingMap[chatId] == true) {
        if (kDebugMode) {
          print('ℹ️ Already recording in chat: $chatId');
        }
        return;
      }

      // Debounce recording events to prevent rapid state changes
      _debounceTimers[chatId]?.cancel();
      _debounceTimers[chatId] = Timer(_debounceDuration, () async {
        await _setRecordingStatus(chatId, userId, true);
        _isRecordingMap[chatId] = true;
      });

      // Auto-stop after max recording time
      _recordingTimers[chatId]?.cancel();
      _recordingTimers[chatId] = Timer(_autoStopDuration, () {
        if (kDebugMode) {
          print('⏱️ Recording auto-stopped (timeout): $chatId');
        }
        stopRecording(chatId);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting recording: $e');
      }
    }
  }

  /// Stop recording in a chat
  Future<void> stopRecording(String chatId) async {
    try {
      // Cancel timers
      _recordingTimers[chatId]?.cancel();
      _recordingTimers.remove(chatId);
      _debounceTimers[chatId]?.cancel();
      _debounceTimers.remove(chatId);

      // Update state
      _isRecordingMap[chatId] = false;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _setRecordingStatus(chatId, userId, false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping recording: $e');
      }
    }
  }

  /// Set recording status in Firestore
  Future<void> _setRecordingStatus(
    String chatId,
    String userId,
    bool isRecording,
  ) async {
    try {
      if (isRecording) {
        // Create/update recording document
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chats)
            .doc(chatId)
            .collection(FirebaseCollections.recording)
            .doc(userId)
            .set({
          'isRecording': true,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
        });

        if (kDebugMode) {
          print('🎙️ User started recording in chat: $chatId');
        }
      } else {
        // Delete recording document
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chats)
            .doc(chatId)
            .collection(FirebaseCollections.recording)
            .doc(userId)
            .delete();

        if (kDebugMode) {
          print('🎙️ User stopped recording in chat: $chatId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting recording status: $e');
      }
    }
  }

  /// Listen to recording users in a chat
  Stream<List<RecordingUser>> listenToRecordingUsers(String chatId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection(FirebaseCollections.chats)
        .doc(chatId)
        .collection(FirebaseCollections.recording)
        .where('isRecording', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      // Filter out current user and stale recordings
      return snapshot.docs
          .where((doc) => doc.id != userId) // Exclude current user
          .map((doc) {
        final data = doc.data();
        return RecordingUser(
          userId: doc.id,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      })
          .where((user) => !user.isStale) // Filter stale recordings
          .toList();
    });
  }

  /// Check if user is currently recording in a specific chat
  bool isRecording(String chatId) {
    return _isRecordingMap[chatId] ?? false;
  }

  /// Get recording users names from Firestore
  Future<List<String>> getRecordingUsersNames(
    String chatId,
    List<String> recordingUserIds,
  ) async {
    if (recordingUserIds.isEmpty) return [];

    try {
      final userDocs = await Future.wait(
        recordingUserIds.map((userId) =>
            FirebaseFirestore.instance.collection(FirebaseCollections.users).doc(userId).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data()?['fullName'] as String? ?? doc.data()?['name'] as String? ?? 'Someone')
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recording users names: $e');
      }
      return [];
    }
  }

  /// Format recording indicator text
  String formatRecordingText(List<String> names) {
    if (names.isEmpty) return '';

    if (names.length == 1) {
      return '🎙️ ${names[0]} is recording audio...';
    } else if (names.length == 2) {
      return '🎙️ ${names[0]} and ${names[1]} are recording audio...';
    } else {
      return '🎙️ ${names[0]}, ${names[1]} and ${names.length - 2} ${names.length - 2 == 1 ? 'other is' : 'others are'} recording audio...';
    }
  }

  /// Clean up all recording indicators for user (on logout or chat exit)
  Future<void> cleanupRecording(String? chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (chatId != null) {
        // Clean up specific chat
        await stopRecording(chatId);
      } else {
        // Clean up all chats
        _recordingTimers.forEach((chatId, timer) {
          timer.cancel();
        });
        _recordingTimers.clear();

        _debounceTimers.forEach((chatId, timer) {
          timer.cancel();
        });
        _debounceTimers.clear();

        _isRecordingMap.clear();

        // Query and delete all recording documents for this user
        final chatsSnapshot =
            await FirebaseFirestore.instance.collection(FirebaseCollections.chats).get();

        final batch = FirebaseFirestore.instance.batch();
        for (final chatDoc in chatsSnapshot.docs) {
          final recordingDoc = chatDoc.reference.collection(FirebaseCollections.recording).doc(userId);
          batch.delete(recordingDoc);
        }
        await batch.commit();
      }

      if (kDebugMode) {
        print('✅ Recording indicators cleaned up${chatId != null ? ' for chat: $chatId' : ' for all chats'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up recording: $e');
      }
    }
  }

  /// Pause recording (without stopping) - for when user minimizes app
  Future<void> pauseRecording(String chatId) async {
    // Cancel auto-stop timer but keep state
    _recordingTimers[chatId]?.cancel();
    _recordingTimers.remove(chatId);

    if (kDebugMode) {
      print('⏸️ Recording paused in chat: $chatId');
    }
  }

  /// Resume recording (restart auto-stop timer)
  Future<void> resumeRecording(String chatId) async {
    if (_isRecordingMap[chatId] == true) {
      // Restart auto-stop timer
      _recordingTimers[chatId] = Timer(_autoStopDuration, () {
        if (kDebugMode) {
          print('⏱️ Recording auto-stopped (timeout after resume): $chatId');
        }
        stopRecording(chatId);
      });

      if (kDebugMode) {
        print('▶️ Recording resumed in chat: $chatId');
      }
    }
  }

  /// Get all active recording chats for current user
  List<String> getActiveRecordingChats() {
    return _isRecordingMap.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Dispose resources
  void dispose() {
    _recordingTimers.forEach((_, timer) => timer.cancel());
    _recordingTimers.clear();
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();
    _isRecordingMap.clear();

    if (kDebugMode) {
      print('🧹 RecordingService disposed');
    }
  }
}

/// Recording user model
class RecordingUser {
  final String userId;
  final DateTime? timestamp;

  RecordingUser({
    required this.userId,
    this.timestamp,
  });

  /// Check if recording indicator is stale (older than 11 minutes)
  /// This handles cases where recording wasn't properly cleaned up
  bool get isStale {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!) > const Duration(minutes: 11);
  }

  /// Get recording duration (how long they've been recording)
  Duration? get recordingDuration {
    if (timestamp == null) return null;
    return DateTime.now().difference(timestamp!);
  }

  /// Format recording duration as string
  String get formattedDuration {
    final duration = recordingDuration;
    if (duration == null) return '0:00';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

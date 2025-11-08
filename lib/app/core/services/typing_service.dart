import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Production-grade Typing Service for 1M+ users
/// Manages typing indicators with auto-stop and debouncing
class TypingService {
  static final TypingService _instance = TypingService._internal();
  factory TypingService() => _instance;
  TypingService._internal();

  final Map<String, Timer> _typingTimers = {};
  final Map<String, Timer> _debounceTimers = {};
  final Duration _autoStopDuration = const Duration(seconds: 5);
  final Duration _debounceDuration = const Duration(milliseconds: 300);

  /// Start typing in a chat
  Future<void> startTyping(String chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // FIXED: Cancel both timers to prevent race condition
      // If user stops and starts typing quickly, old timers are properly cancelled
      _typingTimers[chatId]?.cancel();
      _debounceTimers[chatId]?.cancel();

      // Debounce typing events
      _debounceTimers[chatId] = Timer(_debounceDuration, () async {
        await _setTypingStatus(chatId, userId, true);

        // Start auto-stop timer AFTER debounce completes
        // This prevents the race condition where auto-stop fires before debounce
        _typingTimers[chatId]?.cancel();
        _typingTimers[chatId] = Timer(_autoStopDuration, () {
          stopTyping(chatId);
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting typing: $e');
      }
    }
  }

  /// Stop typing in a chat
  Future<void> stopTyping(String chatId) async {
    try {
      // Cancel timers
      _typingTimers[chatId]?.cancel();
      _typingTimers.remove(chatId);
      _debounceTimers[chatId]?.cancel();
      _debounceTimers.remove(chatId);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _setTypingStatus(chatId, userId, false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping typing: $e');
      }
    }
  }

  /// Set typing status in Firestore
  Future<void> _setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      if (isTyping) {
        // Create/update typing document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('typing')
            .doc(userId)
            .set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
        });

        if (kDebugMode) {
          print('⌨️ User started typing in chat: $chatId');
        }
      } else {
        // Delete typing document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('typing')
            .doc(userId)
            .delete();

        if (kDebugMode) {
          print('⌨️ User stopped typing in chat: $chatId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting typing status: $e');
      }
    }
  }

  /// Listen to typing users in a chat
  Stream<List<TypingUser>> listenToTypingUsers(String chatId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != userId) // Exclude current user
          .map((doc) {
        final data = doc.data();
        return TypingUser(
          userId: doc.id,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  /// Get typing users names
  Future<List<String>> getTypingUsersNames(
    String chatId,
    List<String> typingUserIds,
  ) async {
    if (typingUserIds.isEmpty) return [];

    try {
      final userDocs = await Future.wait(
        typingUserIds.map((userId) =>
            FirebaseFirestore.instance.collection('users').doc(userId).get()),
      );

      return userDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data()?['fullName'] as String? ?? 'Someone')
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting typing users names: $e');
      }
      return [];
    }
  }

  /// Format typing indicator text
  String formatTypingText(List<String> names) {
    if (names.isEmpty) return '';

    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]}, ${names[1]} and ${names.length - 2} ${names.length - 2 == 1 ? 'other is' : 'others are'} typing...';
    }
  }

  /// Clean up all typing indicators for user (on logout or chat exit)
  Future<void> cleanupTyping(String? chatId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (chatId != null) {
        // Clean up specific chat
        await stopTyping(chatId);
      } else {
        // Clean up all chats
        _typingTimers.forEach((chatId, timer) {
          timer.cancel();
        });
        _typingTimers.clear();

        _debounceTimers.forEach((chatId, timer) {
          timer.cancel();
        });
        _debounceTimers.clear();

        // Query and delete all typing documents for this user
        final chatsSnapshot =
            await FirebaseFirestore.instance.collection('chats').get();

        final batch = FirebaseFirestore.instance.batch();
        for (final chatDoc in chatsSnapshot.docs) {
          final typingDoc = chatDoc.reference.collection('typing').doc(userId);
          batch.delete(typingDoc);
        }
        await batch.commit();
      }

      if (kDebugMode) {
        print('✅ Typing indicators cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up typing: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _typingTimers.forEach((_, timer) => timer.cancel());
    _typingTimers.clear();
    _debounceTimers.forEach((_, timer) => timer.cancel());
    _debounceTimers.clear();
  }
}

/// Typing user model
class TypingUser {
  final String userId;
  final DateTime? timestamp;

  TypingUser({
    required this.userId,
    this.timestamp,
  });

  /// Check if typing is stale (older than 30 seconds)
  bool get isStale {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!) > const Duration(seconds: 30);
  }
}

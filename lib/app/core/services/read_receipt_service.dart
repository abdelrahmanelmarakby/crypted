import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Production-grade Read Receipt Service for 1M+ users
/// Manages message read receipts with batch operations
class ReadReceiptService {
  static final ReadReceiptService _instance = ReadReceiptService._internal();
  factory ReadReceiptService() => _instance;
  ReadReceiptService._internal();

  final Set<String> _markedAsRead = {};

  /// Mark a single message as read
  Future<void> markMessageAsRead(String messageId) async {
    // Prevent duplicate marking
    if (_markedAsRead.contains(messageId)) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Check if message is from current user (don't mark own messages as read)
      final messageDoc = await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) return;

      final senderId = messageDoc.data()?['senderId'] as String?;
      if (senderId == userId) return; // Don't mark own messages

      // Create read receipt
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .collection('readReceipts')
          .doc(userId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      _markedAsRead.add(messageId);

      if (kDebugMode) {
        print('✅ Message marked as read: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking message as read: $e');
      }
    }
  }

  /// Mark multiple messages as read (batch operation)
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Filter out already marked messages
      final unreadMessages = messageIds
          .where((id) => !_markedAsRead.contains(id))
          .toList();

      if (unreadMessages.isEmpty) return;

      // Get message documents to check senders
      final messageDocs = await Future.wait(
        unreadMessages.map((id) =>
            FirebaseFirestore.instance.collection('messages').doc(id).get()),
      );

      // Filter out own messages
      final messagesToMark = <String>[];
      for (var i = 0; i < messageDocs.length; i++) {
        final doc = messageDocs[i];
        if (!doc.exists) continue;

        final senderId = doc.data()?['senderId'] as String?;
        if (senderId != userId) {
          messagesToMark.add(unreadMessages[i]);
        }
      }

      if (messagesToMark.isEmpty) return;

      // Batch write read receipts
      final batch = FirebaseFirestore.instance.batch();
      for (final messageId in messagesToMark) {
        final readReceiptRef = FirebaseFirestore.instance
            .collection('messages')
            .doc(messageId)
            .collection('readReceipts')
            .doc(userId);

        batch.set(readReceiptRef, {
          'readAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });

        _markedAsRead.add(messageId);
      }

      await batch.commit();

      if (kDebugMode) {
        print('✅ ${messagesToMark.length} messages marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking messages as read: $e');
      }
    }
  }

  /// Listen to read receipts for a message
  Stream<Map<String, DateTime>> listenToReadReceipts(String messageId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .collection('readReceipts')
        .snapshots()
        .map((snapshot) {
      final receipts = <String, DateTime>{};
      for (final doc in snapshot.docs) {
        final readAt = doc.data()['readAt'] as Timestamp?;
        if (readAt != null) {
          receipts[doc.id] = readAt.toDate();
        }
      }
      return receipts;
    });
  }

  /// Get read receipt status for a message
  Future<ReadReceiptStatus> getReadReceiptStatus(String messageId) async {
    try {
      final messageDoc = await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        return ReadReceiptStatus.unknown;
      }

      final data = messageDoc.data();
      final status = data?['status'] as String?;

      switch (status) {
        case 'sending':
          return ReadReceiptStatus.sending;
        case 'sent':
          return ReadReceiptStatus.sent;
        case 'delivered':
          return ReadReceiptStatus.delivered;
        case 'read':
          return ReadReceiptStatus.read;
        default:
          return ReadReceiptStatus.unknown;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting read receipt status: $e');
      }
      return ReadReceiptStatus.unknown;
    }
  }

  /// Listen to message status changes
  Stream<ReadReceiptStatus> listenToMessageStatus(String messageId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(messageId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return ReadReceiptStatus.unknown;

      final status = doc.data()?['status'] as String?;
      switch (status) {
        case 'sending':
          return ReadReceiptStatus.sending;
        case 'sent':
          return ReadReceiptStatus.sent;
        case 'delivered':
          return ReadReceiptStatus.delivered;
        case 'read':
          return ReadReceiptStatus.read;
        default:
          return ReadReceiptStatus.unknown;
      }
    });
  }

  /// Get read by users for group chat
  Future<List<ReadByUser>> getReadByUsers(String messageId) async {
    try {
      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageId)
          .collection('readReceipts')
          .get();

      final readByUsers = <ReadByUser>[];

      for (final doc in receiptsSnapshot.docs) {
        final userId = doc.id;
        final readAt = (doc.data()['readAt'] as Timestamp?)?.toDate();

        // Get user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          readByUsers.add(ReadByUser(
            userId: userId,
            userName: userDoc.data()?['fullName'] as String? ?? 'Unknown',
            userImage: userDoc.data()?['imageUrl'] as String?,
            readAt: readAt,
          ));
        }
      }

      // Sort by read time (most recent first)
      readByUsers.sort((a, b) {
        if (a.readAt == null) return 1;
        if (b.readAt == null) return -1;
        return b.readAt!.compareTo(a.readAt!);
      });

      return readByUsers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting read by users: $e');
      }
      return [];
    }
  }

  /// Format read receipt text for group chat
  String formatReadReceiptText(List<ReadByUser> readByUsers) {
    if (readByUsers.isEmpty) return '';

    if (readByUsers.length == 1) {
      return 'Read by ${readByUsers[0].userName}';
    } else if (readByUsers.length == 2) {
      return 'Read by ${readByUsers[0].userName} and ${readByUsers[1].userName}';
    } else {
      return 'Read by ${readByUsers[0].userName}, ${readByUsers[1].userName} and ${readByUsers.length - 2} ${readByUsers.length - 2 == 1 ? 'other' : 'others'}';
    }
  }

  /// Clear marked as read cache (on logout)
  void clearCache() {
    _markedAsRead.clear();
  }
}

/// Read receipt status enum
enum ReadReceiptStatus {
  unknown,
  sending,
  sent,
  delivered,
  read,
}

/// Read by user model
class ReadByUser {
  final String userId;
  final String userName;
  final String? userImage;
  final DateTime? readAt;

  ReadByUser({
    required this.userId,
    required this.userName,
    this.userImage,
    this.readAt,
  });
}

/// Extension for read receipt status
extension ReadReceiptStatusExtension on ReadReceiptStatus {
  /// Get icon for status
  String get icon {
    switch (this) {
      case ReadReceiptStatus.sending:
        return '🕐'; // Clock
      case ReadReceiptStatus.sent:
        return '✓'; // Single check
      case ReadReceiptStatus.delivered:
        return '✓✓'; // Double check
      case ReadReceiptStatus.read:
        return '✓✓'; // Double check (blue in UI)
      default:
        return '';
    }
  }

  /// Get color for status
  String get colorName {
    switch (this) {
      case ReadReceiptStatus.sending:
        return 'grey';
      case ReadReceiptStatus.sent:
        return 'grey';
      case ReadReceiptStatus.delivered:
        return 'grey';
      case ReadReceiptStatus.read:
        return 'blue'; // Blue checkmarks
      default:
        return 'grey';
    }
  }
}

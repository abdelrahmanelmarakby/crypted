import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// Interface for Firebase message operations
/// Extracted from ChatDataSources for single responsibility
abstract class IFirebaseMessageDataSource {
  /// Send a message to a room
  /// Returns the Firestore document ID
  Future<String> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
  });

  /// Watch messages with real-time updates
  Stream<List<Message>> watchMessages(
    String roomId, {
    int limit = 30,
    String? startAfterId,
  });

  /// Watch a single message
  Stream<Message?> watchMessage(String roomId, String messageId);

  /// Edit a text message
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String userId,
  });

  /// Soft delete a message
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  });

  /// Restore a deleted message
  Future<void> restoreMessage({
    required String roomId,
    required String messageId,
  });

  /// Toggle pin status
  Future<void> togglePin({
    required String roomId,
    required String messageId,
  });

  /// Toggle favorite status
  Future<void> toggleFavorite({
    required String roomId,
    required String messageId,
  });

  /// Search messages by text
  Future<List<Message>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  });

  /// Get messages by type
  Future<List<Message>> getMessagesByType({
    required String roomId,
    required String type,
    int limit = 50,
  });

  /// Get a single message
  Future<Message?> getMessageById(String roomId, String messageId);

  /// Update message with arbitrary fields
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  });
}

/// Firebase implementation of message data source
/// Approximately 200 lines - focused on message operations only
class FirebaseMessageDataSource implements IFirebaseMessageDataSource {
  final FirebaseFirestore _firestore;
  final CollectionReference _chatCollection;

  FirebaseMessageDataSource({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatCollection = (firestore ?? FirebaseFirestore.instance)
            .collection(FirebaseCollections.chats);

  /// Get message collection reference for a room
  CollectionReference _messagesRef(String roomId) {
    return _chatCollection.doc(roomId).collection(FirebaseCollections.chatMessages);
  }

  @override
  Future<String> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
  }) async {
    // Create message document
    final messageRef = _messagesRef(roomId).doc();
    final messageWithId = message.copyWith(id: messageRef.id);

    await messageRef.set(messageWithId.toMap());

    // Update room's last message info
    await _updateRoomLastMessage(roomId, message);

    if (kDebugMode) {
      print('✅ Message sent: ${messageRef.id}');
    }

    return messageRef.id;
  }

  /// Update room with latest message info
  Future<void> _updateRoomLastMessage(String roomId, Message message) async {
    await _chatCollection.doc(roomId).update({
      'lastMsg': _getMessagePreview(message),
      'lastSender': message.senderId,
      'lastChat': FieldValue.serverTimestamp(),
    });
  }

  /// Get message preview text
  String _getMessagePreview(Message message) {
    final map = message.toMap();
    final type = map['type'] as String?;

    switch (type) {
      case 'text':
        final text = map['text'] as String? ?? '';
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
      case 'photo':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Voice message';
      case 'file':
        return '📎 File';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'poll':
        return '📊 Poll';
      case 'event':
        return '📅 Event';
      case 'call':
        return '📞 Call';
      default:
        return 'Message';
    }
  }

  @override
  Stream<List<Message>> watchMessages(
    String roomId, {
    int limit = 30,
    String? startAfterId,
  }) {
    Query query = _messagesRef(roomId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfterId != null) {
      // For pagination, we need to get the document first
      // This is handled by the repository layer for proper pagination
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Message.fromMap(data);
      }).toList();
    });
  }

  @override
  Stream<Message?> watchMessage(String roomId, String messageId) {
    return _messagesRef(roomId).doc(messageId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>;
      data['id'] = snapshot.id;
      return Message.fromMap(data);
    });
  }

  @override
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String userId,
  }) async {
    final messageRef = _messagesRef(roomId).doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);

      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;

      // Validate sender
      if (data['senderId'] != userId) {
        throw Exception('Cannot edit message: not the sender');
      }

      // Validate edit time (15 minutes)
      final timestamp = Message.parseTimestamp(data['timestamp']);
      if (DateTime.now().difference(timestamp).inMinutes > 15) {
        throw Exception('Cannot edit message: time limit exceeded');
      }

      transaction.update(messageRef, {
        'text': newText,
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
        'originalText': data['text'], // Preserve original
      });
    });

    if (kDebugMode) {
      print('✅ Message edited: $messageId');
    }
  }

  @override
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    await updateMessage(
      roomId: roomId,
      messageId: messageId,
      updates: {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
      },
    );

    if (kDebugMode) {
      print('✅ Message deleted: $messageId');
    }
  }

  @override
  Future<void> restoreMessage({
    required String roomId,
    required String messageId,
  }) async {
    await updateMessage(
      roomId: roomId,
      messageId: messageId,
      updates: {
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
      },
    );
  }

  @override
  Future<void> togglePin({
    required String roomId,
    required String messageId,
  }) async {
    final messageRef = _messagesRef(roomId).doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentlyPinned = data['isPinned'] ?? false;

      // If pinning, unpin other messages first
      if (!currentlyPinned) {
        final pinnedMessages = await _messagesRef(roomId)
            .where('isPinned', isEqualTo: true)
            .get();

        for (final doc in pinnedMessages.docs) {
          if (doc.id != messageId) {
            transaction.update(doc.reference, {'isPinned': false});
          }
        }
      }

      transaction.update(messageRef, {'isPinned': !currentlyPinned});
    });
  }

  @override
  Future<void> toggleFavorite({
    required String roomId,
    required String messageId,
  }) async {
    final messageRef = _messagesRef(roomId).doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentlyFavorite = data['isFavorite'] ?? false;

      transaction.update(messageRef, {'isFavorite': !currentlyFavorite});
    });
  }

  @override
  Future<List<Message>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  }) async {
    // Firestore doesn't support full-text search
    // Fetch messages and filter client-side
    final snapshot = await _messagesRef(roomId)
        .where('type', isEqualTo: 'text')
        .orderBy('timestamp', descending: true)
        .limit(limit * 3) // Fetch more to account for filtering
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Message.fromMap(data);
        })
        .where((message) {
          final text = message.toMap()['text'] as String? ?? '';
          return text.toLowerCase().contains(lowerQuery);
        })
        .take(limit)
        .toList();
  }

  @override
  Future<List<Message>> getMessagesByType({
    required String roomId,
    required String type,
    int limit = 50,
  }) async {
    final snapshot = await _messagesRef(roomId)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Message.fromMap(data);
    }).toList();
  }

  @override
  Future<Message?> getMessageById(String roomId, String messageId) async {
    final doc = await _messagesRef(roomId).doc(messageId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Message.fromMap(data);
  }

  @override
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  }) async {
    await _messagesRef(roomId).doc(messageId).update(updates);
  }
}

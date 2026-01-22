// ARCH-002 FIX: Dedicated Message Repository
// Separates message operations from ChatRepository for better SRP

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/factories/message_factory.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:flutter/foundation.dart';

/// Abstract interface for message operations
abstract class IMessageRepository {
  /// Get paginated messages for a chat room
  Stream<List<Message>> getMessages(
    String roomId, {
    int limit = 30,
    DocumentSnapshot? startAfter,
  });

  /// Get a single message by ID
  Future<Message?> getMessageById(String roomId, String messageId);

  /// Send a new message
  Future<void> sendMessage({
    required String roomId,
    required Message message,
  });

  /// Update message properties
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  });

  /// Soft delete a message
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  });

  /// Hard delete a message (admin only)
  Future<void> permanentlyDeleteMessage({
    required String roomId,
    required String messageId,
  });

  /// Toggle reaction on a message
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Mark messages as read
  Future<void> markAsRead({
    required String roomId,
    required List<String> messageIds,
    required String userId,
  });

  /// Search messages in a chat room
  Future<List<Message>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  });

  /// Get media messages (images, videos, files)
  Future<List<Message>> getMediaMessages({
    required String roomId,
    String? mediaType,
    int limit = 50,
  });

  /// Get pinned messages
  Future<List<Message>> getPinnedMessages(String roomId);

  /// Get favorite messages for a user
  Future<List<Message>> getFavoriteMessages(String roomId);
}

/// Firebase implementation of IMessageRepository
class FirebaseMessageRepository implements IMessageRepository {
  final FirebaseFirestore _firestore;
  final MessageFactory _messageFactory;

  FirebaseMessageRepository({
    FirebaseFirestore? firestore,
    MessageFactory? messageFactory,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messageFactory = messageFactory ?? MessageFactory();

  CollectionReference<Map<String, dynamic>> _messagesCollection(String roomId) {
    return _firestore.collection(FirebaseCollections.chats).doc(roomId).collection(FirebaseCollections.chatMessages);
  }

  @override
  Stream<List<Message>> getMessages(
    String roomId, {
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _messagesCollection(roomId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return _messageFactory.tryFromMap(data);
            } catch (e) {
              _logError('getMessages', e);
              return null;
            }
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
    });
  }

  @override
  Future<Message?> getMessageById(String roomId, String messageId) async {
    try {
      final doc = await _messagesCollection(roomId).doc(messageId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return _messageFactory.tryFromMap(data);
    } catch (e) {
      _logError('getMessageById', e);
      return null;
    }
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required Message message,
  }) async {
    await _messagesCollection(roomId).doc(message.id).set(message.toMap());
  }

  @override
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  }) async {
    await _messagesCollection(roomId).doc(messageId).update(updates);
  }

  @override
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await updateMessage(
      roomId: roomId,
      messageId: messageId,
      updates: {'isDeleted': true},
    );
  }

  @override
  Future<void> permanentlyDeleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await _messagesCollection(roomId).doc(messageId).delete();
  }

  @override
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _messagesCollection(roomId).doc(messageId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data()!;
      Map<String, List<String>> reactions =
          Map<String, List<String>>.from((data['reactions'] ?? {}).map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ));

      final emojiReactions = reactions[emoji] ?? [];

      if (emojiReactions.contains(userId)) {
        emojiReactions.remove(userId);
        if (emojiReactions.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = emojiReactions;
        }
      } else {
        emojiReactions.add(userId);
        reactions[emoji] = emojiReactions;
      }

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  @override
  Future<void> markAsRead({
    required String roomId,
    required List<String> messageIds,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      final docRef = _messagesCollection(roomId).doc(messageId);
      batch.update(docRef, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  @override
  Future<List<Message>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  }) async {
    try {
      // Note: Firebase doesn't support full-text search natively
      // This is a simple prefix search - consider using Algolia or ElasticSearch for better search
      final snapshot = await _messagesCollection(roomId)
          .where('type', isEqualTo: 'text')
          .orderBy('timestamp', descending: true)
          .limit(limit * 3) // Fetch more to filter client-side
          .get();

      final lowercaseQuery = query.toLowerCase();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _messageFactory.tryFromMap(data);
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .where((msg) {
            final text = (msg.toMap()['text'] as String?)?.toLowerCase() ?? '';
            return text.contains(lowercaseQuery);
          })
          .take(limit)
          .toList();
    } catch (e) {
      _logError('searchMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> getMediaMessages({
    required String roomId,
    String? mediaType,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _messagesCollection(roomId)
          .orderBy('timestamp', descending: true);

      if (mediaType != null) {
        query = query.where('type', isEqualTo: mediaType);
      } else {
        query = query.where('type', whereIn: ['photo', 'video', 'audio', 'file']);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _messageFactory.tryFromMap(data);
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
    } catch (e) {
      _logError('getMediaMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> getPinnedMessages(String roomId) async {
    try {
      final snapshot = await _messagesCollection(roomId)
          .where('isPinned', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _messageFactory.tryFromMap(data);
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
    } catch (e) {
      _logError('getPinnedMessages', e);
      return [];
    }
  }

  @override
  Future<List<Message>> getFavoriteMessages(String roomId) async {
    try {
      final snapshot = await _messagesCollection(roomId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _messageFactory.tryFromMap(data);
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
    } catch (e) {
      _logError('getFavoriteMessages', e);
      return [];
    }
  }

  void _logError(String operation, dynamic error) {
    if (kDebugMode) {
      print('FirebaseMessageRepository.$operation error: $error');
    }
  }
}

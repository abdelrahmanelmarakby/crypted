import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:flutter/foundation.dart';

/// Interface for Firebase reaction operations
abstract class IFirebaseReactionDataSource {
  /// Toggle a reaction (add if not present, remove if present)
  Future<ReactionResult> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Remove all reactions by a user
  Future<void> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  });

  /// Get all reactions for a message
  Future<List<Reaction>> getReactions(String roomId, String messageId);
}

/// Firebase implementation of reaction data source
/// Approximately 100 lines - focused on reaction operations only
class FirebaseReactionDataSource implements IFirebaseReactionDataSource {
  final FirebaseFirestore _firestore;
  final CollectionReference _chatCollection;

  FirebaseReactionDataSource({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatCollection = (firestore ?? FirebaseFirestore.instance)
            .collection(FirebaseCollections.chats);

  /// Get message reference
  DocumentReference _messageRef(String roomId, String messageId) {
    return _chatCollection
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .doc(messageId);
  }

  @override
  Future<ReactionResult> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final messageRef = _messageRef(roomId, messageId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);

      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = List<Map<String, dynamic>>.from(
        (data['reactions'] as List<dynamic>?)?.map((r) => Map<String, dynamic>.from(r)).toList() ?? [],
      );

      // Check if user already reacted with this emoji
      final existingIndex = reactions.indexWhere(
        (r) => r['emoji'] == emoji && r['userId'] == userId,
      );

      bool wasAdded;
      if (existingIndex != -1) {
        // Remove reaction
        reactions.removeAt(existingIndex);
        wasAdded = false;
        if (kDebugMode) {
          print('🔄 Removed reaction $emoji from message $messageId');
        }
      } else {
        // Add reaction
        reactions.add({
          'emoji': emoji,
          'userId': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        wasAdded = true;
        if (kDebugMode) {
          print('✅ Added reaction $emoji to message $messageId');
        }
      }

      transaction.update(messageRef, {'reactions': reactions});

      // Calculate new count for this emoji
      final newCount = reactions.where((r) => r['emoji'] == emoji).length;

      return ReactionResult(
        wasAdded: wasAdded,
        emoji: emoji,
        newCount: newCount,
        allReactions: reactions.map((r) => Reaction.fromMap(r)).toList(),
      );
    });
  }

  @override
  Future<void> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _messageRef(roomId, messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);

      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = List<Map<String, dynamic>>.from(
        (data['reactions'] as List<dynamic>?)?.map((r) => Map<String, dynamic>.from(r)).toList() ?? [],
      );

      // Remove all reactions from this user
      reactions.removeWhere((r) => r['userId'] == userId);

      transaction.update(messageRef, {'reactions': reactions});
    });

    if (kDebugMode) {
      print('✅ Removed all reactions from user $userId on message $messageId');
    }
  }

  @override
  Future<List<Reaction>> getReactions(String roomId, String messageId) async {
    final doc = await _messageRef(roomId, messageId).get();

    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>;
    final reactionsData = data['reactions'] as List<dynamic>? ?? [];

    return reactionsData
        .map((r) => Reaction.fromMap(Map<String, dynamic>.from(r)))
        .toList();
  }
}

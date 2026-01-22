// PERF-001 FIX: Message Pagination Support
// Provides paginated message loading with cursor-based pagination

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:flutter/foundation.dart';

/// Pagination state for tracking loaded messages
class PaginationState {
  final int pageSize;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;
  final int totalLoaded;

  const PaginationState({
    this.pageSize = 30,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.lastDocument,
    this.totalLoaded = 0,
  });

  PaginationState copyWith({
    int? pageSize,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
    int? totalLoaded,
  }) {
    return PaginationState(
      pageSize: pageSize ?? this.pageSize,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
      totalLoaded: totalLoaded ?? this.totalLoaded,
    );
  }

  /// Reset pagination state
  PaginationState reset() {
    return PaginationState(pageSize: pageSize);
  }
}

/// Paginated message result
class PaginatedMessages {
  final List<Message> messages;
  final PaginationState state;

  PaginatedMessages({
    required this.messages,
    required this.state,
  });
}

/// Service for handling paginated message loading
class MessagePaginationService {
  final FirebaseFirestore _firestore;
  final String _collectionName;

  MessagePaginationService({
    FirebaseFirestore? firestore,
    // Uses FirebaseCollections.chats to match ChatDataSources
    String? collectionName,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionName = collectionName ?? FirebaseCollections.chats;

  /// Get initial page of messages with live updates
  Stream<PaginatedMessages> getInitialMessages({
    required String roomId,
    int pageSize = 30,
  }) {
    final query = _firestore
        .collection(_collectionName)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    return query.snapshots().map((snapshot) {
      final messages = _processMessages(snapshot.docs);
      final hasMore = snapshot.docs.length >= pageSize;

      return PaginatedMessages(
        messages: messages,
        state: PaginationState(
          pageSize: pageSize,
          hasMoreMessages: hasMore,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          totalLoaded: messages.length,
        ),
      );
    });
  }

  /// Load more messages (older messages)
  Future<PaginatedMessages> loadMoreMessages({
    required String roomId,
    required PaginationState currentState,
  }) async {
    if (!currentState.hasMoreMessages ||
        currentState.isLoadingMore ||
        currentState.lastDocument == null) {
      return PaginatedMessages(
        messages: [],
        state: currentState,
      );
    }

    try {
      final query = _firestore
          .collection(_collectionName)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(currentState.lastDocument!)
          .limit(currentState.pageSize);

      final snapshot = await query.get();
      final messages = _processMessages(snapshot.docs);
      final hasMore = snapshot.docs.length >= currentState.pageSize;

      return PaginatedMessages(
        messages: messages,
        state: currentState.copyWith(
          hasMoreMessages: hasMore,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          totalLoaded: currentState.totalLoaded + messages.length,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Pagination] Error loading more messages: $e');
      }
      return PaginatedMessages(
        messages: [],
        state: currentState,
      );
    }
  }

  /// Load messages around a specific timestamp (for jumping to messages)
  Future<PaginatedMessages> loadMessagesAround({
    required String roomId,
    required DateTime timestamp,
    int pageSize = 30,
  }) async {
    try {
      // Load messages before the timestamp
      final beforeQuery = _firestore
          .collection(_collectionName)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(timestamp))
          .limit(pageSize ~/ 2);

      // Load messages after the timestamp
      final afterQuery = _firestore
          .collection(_collectionName)
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: false)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(timestamp))
          .limit(pageSize ~/ 2);

      final results = await Future.wait([
        beforeQuery.get(),
        afterQuery.get(),
      ]);

      final beforeDocs = results[0].docs;
      final afterDocs = results[1].docs.reversed.toList();

      final allDocs = [...afterDocs, ...beforeDocs];
      final messages = _processMessages(allDocs);

      return PaginatedMessages(
        messages: messages,
        state: PaginationState(
          pageSize: pageSize,
          hasMoreMessages: beforeDocs.length >= pageSize ~/ 2,
          lastDocument: beforeDocs.isNotEmpty ? beforeDocs.last : null,
          totalLoaded: messages.length,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Pagination] Error loading messages around timestamp: $e');
      }
      return PaginatedMessages(
        messages: [],
        state: PaginationState(pageSize: pageSize),
      );
    }
  }

  /// Process and filter messages
  List<Message> _processMessages(List<QueryDocumentSnapshot> docs) {
    final currentUserId = UserService.currentUser.value?.uid ?? '';

    return docs
        .map((doc) {
          try {
            return Message.fromMap(doc.data() as Map<String, dynamic>);
          } catch (e) {
            if (kDebugMode) {
              print('[Pagination] Error parsing message ${doc.id}: $e');
            }
            return null;
          }
        })
        .whereType<Message>()
        .where((message) {
          // Filter deleted messages (only show to sender)
          if (!message.isDeleted) return true;
          return message.senderId == currentUserId;
        })
        .toList();
  }
}

/// Extension to add pagination to existing chat data sources
extension PaginatedChatDataSource on FirebaseFirestore {
  /// Get paginated messages stream
  Stream<List<Message>> getPaginatedMessages({
    required String roomId,
    required String collection,
    int limit = 30,
  }) {
    return this
        .collection(collection)
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final currentUserId = UserService.currentUser.value?.uid ?? '';
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .where((message) {
        if (!message.isDeleted) return true;
        return message.senderId == currentUserId;
      }).toList();
    });
  }
}

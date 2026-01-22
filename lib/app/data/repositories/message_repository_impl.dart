import 'dart:async';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/caching/query_cache.dart';
import 'package:crypted_app/app/data/datasources/firebase/firebase_message_datasource.dart';
import 'package:crypted_app/app/data/datasources/local/hive_message_datasource.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:flutter/foundation.dart';

/// Implementation of IMessageRepository
/// This is the SINGLE SOURCE OF TRUTH for all message operations
///
/// Key responsibilities:
/// 1. Coordinate between remote (Firebase) and local (Hive) data sources
/// 2. Emit events for ALL mutations (event-driven architecture)
/// 3. Manage caching and cache invalidation
/// 4. Handle offline-first pattern
class MessageRepositoryImpl implements IMessageRepository {
  final IFirebaseMessageDataSource _remoteDataSource;
  final ILocalMessageDataSource _localDataSource;
  final EventBus _eventBus;
  final QueryCache _cache;
  final ConnectivityService _connectivity;

  MessageRepositoryImpl({
    required IFirebaseMessageDataSource remoteDataSource,
    required ILocalMessageDataSource localDataSource,
    required EventBus eventBus,
    required QueryCache cache,
    required ConnectivityService connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _eventBus = eventBus,
        _cache = cache,
        _connectivity = connectivity;

  // =================== Real-time Streams ===================

  @override
  Stream<Result<List<Message>, RepositoryError>> watchMessages(
    String roomId, {
    int limit = 30,
    String? startAfterId,
  }) {
    return _remoteDataSource
        .watchMessages(roomId, limit: limit, startAfterId: startAfterId)
        .map((messages) {
      // Cache messages locally for offline access
      _localDataSource.saveMessages(roomId, messages);

      // Update cache
      final cacheKey = _messagesCacheKey(roomId, limit, startAfterId);
      _cache.set(cacheKey, messages,
          ttl: QueryCache.messageTtl, tags: ['room:$roomId:messages']);

      return Result<List<Message>, RepositoryError>.success(messages);
    }).handleError((error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error watching messages: $error');
      }
      return Result<List<Message>, RepositoryError>.failure(
        RepositoryError.fromException(error, stackTrace),
      );
    });
  }

  @override
  Stream<Result<Message, RepositoryError>> watchMessage(
    String roomId,
    String messageId,
  ) {
    return _remoteDataSource.watchMessage(roomId, messageId).map((message) {
      if (message == null) {
        return Result<Message, RepositoryError>.failure(
          RepositoryError.notFound('Message'),
        );
      }
      return Result<Message, RepositoryError>.success(message);
    }).handleError((error, stackTrace) {
      return Result<Message, RepositoryError>.failure(
        RepositoryError.fromException(error, stackTrace),
      );
    });
  }

  // =================== Message Operations ===================

  @override
  Future<Result<String, RepositoryError>> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
  }) async {
    try {
      // 1. Save to local storage first (offline-first)
      await _localDataSource.saveMessage(roomId, message);

      // 2. Check connectivity
      if (!_connectivity.isOnline) {
        // Queue for sync when online
        await _localDataSource.queueForSync(roomId, message);

        // EMIT: Message queued event
        _eventBus.emit(MessageSentEvent(
          roomId: roomId,
          messageId: message.id,
          localId: message.id,
        ));

        if (kDebugMode) {
          print('📤 Message queued for offline sync: ${message.id}');
        }

        return Result.success(message.id);
      }

      // 3. Send to Firebase
      final actualId = await _remoteDataSource.sendMessage(
        roomId: roomId,
        message: message,
        memberIds: memberIds,
      );

      // 4. Update local with actual ID
      await _localDataSource.updateMessageId(roomId, message.id, actualId);
      await _localDataSource.markAsSynced(roomId, actualId);

      // 5. EMIT: Message sent event (CRITICAL!)
      _eventBus.emit(MessageSentEvent(
        roomId: roomId,
        messageId: actualId,
        localId: message.id,
      ));

      // 6. Invalidate cache
      _cache.invalidateByTag('room:$roomId:messages');

      if (kDebugMode) {
        print('✅ Message sent: ${message.id} -> $actualId');
      }

      return Result.success(actualId);
    } catch (e, st) {
      // EMIT: Send failed event
      _eventBus.emit(MessageSendFailedEvent(
        roomId: roomId,
        localId: message.id,
        error: e.toString(),
      ));

      if (kDebugMode) {
        print('❌ Failed to send message: $e');
      }

      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.editMessage(
        roomId: roomId,
        messageId: messageId,
        newText: newText,
        userId: userId,
      );

      // EMIT: Message updated event
      _eventBus.emit(MessageUpdatedEvent(
        roomId: roomId,
        messageId: messageId,
        updates: {'text': newText, 'isEdited': true},
      ));

      // Invalidate cache
      _cache.invalidateByTag('room:$roomId:messages');

      if (kDebugMode) {
        print('✅ Message edited: $messageId');
      }

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.deleteMessage(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
      );

      // EMIT: Message deleted event
      _eventBus.emit(MessageDeletedEvent(
        roomId: roomId,
        messageId: messageId,
        forEveryone: false,
      ));

      // Invalidate cache
      _cache.invalidateByTag('room:$roomId:messages');

      if (kDebugMode) {
        print('✅ Message deleted: $messageId');
      }

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> restoreMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.restoreMessage(
        roomId: roomId,
        messageId: messageId,
      );

      // EMIT: Message updated event
      _eventBus.emit(MessageUpdatedEvent(
        roomId: roomId,
        messageId: messageId,
        updates: {'isDeleted': false},
      ));

      _cache.invalidateByTag('room:$roomId:messages');

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> permanentlyDeleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    // TODO: Implement permanent deletion with file cleanup
    // For now, delegate to soft delete
    return deleteMessage(
      roomId: roomId,
      messageId: messageId,
      userId: userId,
    );
  }

  // =================== Message Properties ===================

  @override
  Future<Result<void, RepositoryError>> togglePin({
    required String roomId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.togglePin(
        roomId: roomId,
        messageId: messageId,
      );

      // EMIT: Message updated event
      _eventBus.emit(MessageUpdatedEvent(
        roomId: roomId,
        messageId: messageId,
        updates: {'isPinned': true}, // Actual value comes from stream
      ));

      _cache.invalidateByTag('room:$roomId:messages');

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> toggleFavorite({
    required String roomId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.toggleFavorite(
        roomId: roomId,
        messageId: messageId,
      );

      // EMIT: Message updated event
      _eventBus.emit(MessageUpdatedEvent(
        roomId: roomId,
        messageId: messageId,
        updates: {'isFavorite': true}, // Actual value comes from stream
      ));

      _cache.invalidateByTag('room:$roomId:messages');

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Queries ===================

  @override
  Future<Result<List<Message>, RepositoryError>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  }) async {
    try {
      // Try remote first if online
      if (_connectivity.isOnline) {
        final results = await _remoteDataSource.searchMessages(
          roomId: roomId,
          query: query,
          limit: limit,
        );
        return Result.success(results);
      }

      // Fallback to local search
      final localResults = await _localDataSource.searchMessages(
        query,
        roomId: roomId,
      );
      return Result.success(localResults.take(limit).toList());
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getMessagesByType({
    required String roomId,
    required MessageType type,
    int limit = 50,
  }) async {
    try {
      final typeString = type.name;
      final messages = await _remoteDataSource.getMessagesByType(
        roomId: roomId,
        type: typeString,
        limit: limit,
      );
      return Result.success(messages);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getPinnedMessages(
    String roomId,
  ) async {
    try {
      final messages = await _remoteDataSource.getMessagesByType(
        roomId: roomId,
        type: 'pinned', // Special query
        limit: 10,
      );
      // Filter for pinned
      final pinned = messages.where((m) => m.isPinned).toList();
      return Result.success(pinned);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getFavoriteMessages(
    String roomId,
  ) async {
    try {
      final messages = await _remoteDataSource.getMessagesByType(
        roomId: roomId,
        type: 'favorite', // Special query
        limit: 50,
      );
      // Filter for favorites
      final favorites = messages.where((m) => m.isFavorite).toList();
      return Result.success(favorites);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<Message?, RepositoryError>> getMessageById(
    String roomId,
    String messageId,
  ) async {
    try {
      // Try local first for speed
      final localMessage = await _localDataSource.getMessage(roomId, messageId);
      if (localMessage != null) {
        return Result.success(localMessage);
      }

      // Fallback to remote
      final message = await _remoteDataSource.getMessageById(roomId, messageId);
      return Result.success(message);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Sync Operations ===================

  @override
  Future<Result<int, RepositoryError>> syncPendingMessages(String roomId) async {
    try {
      if (!_connectivity.isOnline) {
        return Result.failure(RepositoryError.network('Cannot sync while offline'));
      }

      final pendingMessages = await _localDataSource.getPendingMessages(roomId);
      int syncedCount = 0;

      for (final message in pendingMessages) {
        try {
          final actualId = await _remoteDataSource.sendMessage(
            roomId: roomId,
            message: message,
            memberIds: [], // Members should already exist in room
          );

          await _localDataSource.updateMessageId(roomId, message.id, actualId);
          await _localDataSource.markAsSynced(roomId, actualId);
          syncedCount++;

          // EMIT: Message sent event for each synced message
          _eventBus.emit(MessageSentEvent(
            roomId: roomId,
            messageId: actualId,
            localId: message.id,
          ));
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to sync message ${message.id}: $e');
          }
        }
      }

      _cache.invalidateByTag('room:$roomId:messages');

      return Result.success(syncedCount);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<int> getPendingMessageCount(String roomId) async {
    final pending = await _localDataSource.getPendingMessages(roomId);
    return pending.length;
  }

  // =================== Batch Operations ===================

  @override
  Future<Result<void, RepositoryError>> markMessagesAsRead({
    required String roomId,
    required List<String> messageIds,
    required String userId,
  }) async {
    try {
      // EMIT: Message read events
      for (final messageId in messageIds) {
        _eventBus.emit(MessageReadEvent(
          roomId: roomId,
          messageId: messageId,
          readByUserId: userId,
        ));
      }

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Helpers ===================

  String _messagesCacheKey(String roomId, int limit, String? startAfterId) {
    return 'messages:$roomId:$limit:${startAfterId ?? 'initial'}';
  }
}

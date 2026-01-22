import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';

/// Message types for filtering
enum MessageType {
  text,
  photo,
  video,
  audio,
  file,
  location,
  contact,
  poll,
  event,
  call,
}

/// Pagination state for message loading
class MessagePaginationState {
  final String? lastMessageId;
  final bool hasMore;
  final int loadedCount;

  const MessagePaginationState({
    this.lastMessageId,
    this.hasMore = true,
    this.loadedCount = 0,
  });

  MessagePaginationState copyWith({
    String? lastMessageId,
    bool? hasMore,
    int? loadedCount,
  }) {
    return MessagePaginationState(
      lastMessageId: lastMessageId ?? this.lastMessageId,
      hasMore: hasMore ?? this.hasMore,
      loadedCount: loadedCount ?? this.loadedCount,
    );
  }
}

/// Abstract interface for message repository
/// Implementations: MessageRepositoryImpl (Firebase + Hive)
///
/// This interface defines ALL message operations. Controllers should ONLY
/// use this interface, never access data sources directly.
abstract class IMessageRepository {
  // =================== Real-time Streams ===================

  /// Watch messages with pagination (real-time stream)
  /// Returns a stream of Result to handle errors in the stream
  ///
  /// [roomId] - The chat room ID
  /// [limit] - Number of messages per page (default 30)
  /// [startAfterId] - Message ID to start after (for pagination)
  Stream<Result<List<Message>, RepositoryError>> watchMessages(
    String roomId, {
    int limit = 30,
    String? startAfterId,
  });

  /// Watch a single message for real-time updates (reactions, edits, etc.)
  Stream<Result<Message, RepositoryError>> watchMessage(
    String roomId,
    String messageId,
  );

  // =================== Message Operations ===================

  /// Send a new message
  /// Returns the actual Firestore message ID on success
  ///
  /// This method should:
  /// 1. Save to local storage first (offline-first)
  /// 2. Queue for sync if offline
  /// 3. Send to Firebase when online
  /// 4. Emit MessageSentEvent through EventBus
  /// 5. Invalidate relevant caches
  Future<Result<String, RepositoryError>> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
  });

  /// Edit an existing text message
  ///
  /// Validates:
  /// - Message exists and is text type
  /// - User is the sender
  /// - Within edit time limit (15 minutes)
  Future<Result<void, RepositoryError>> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String userId,
  });

  /// Soft delete a message (marks as deleted, doesn't remove)
  ///
  /// Validates:
  /// - Message exists
  /// - User is the sender
  Future<Result<void, RepositoryError>> deleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  });

  /// Restore a soft-deleted message
  Future<Result<void, RepositoryError>> restoreMessage({
    required String roomId,
    required String messageId,
    required String userId,
  });

  /// Permanently delete a message and associated files
  /// Admin-only operation
  Future<Result<void, RepositoryError>> permanentlyDeleteMessage({
    required String roomId,
    required String messageId,
    required String userId,
  });

  // =================== Message Properties ===================

  /// Pin/unpin a message (only one pinned message per room)
  Future<Result<void, RepositoryError>> togglePin({
    required String roomId,
    required String messageId,
  });

  /// Add/remove message from favorites
  Future<Result<void, RepositoryError>> toggleFavorite({
    required String roomId,
    required String messageId,
  });

  // =================== Queries ===================

  /// Search messages by text content
  /// Uses client-side filtering (Firestore doesn't support full-text search)
  Future<Result<List<Message>, RepositoryError>> searchMessages({
    required String roomId,
    required String query,
    int limit = 50,
  });

  /// Get messages by type (for media gallery)
  Future<Result<List<Message>, RepositoryError>> getMessagesByType({
    required String roomId,
    required MessageType type,
    int limit = 50,
  });

  /// Get all pinned messages in a room
  Future<Result<List<Message>, RepositoryError>> getPinnedMessages(
    String roomId,
  );

  /// Get favorite messages for current user
  Future<Result<List<Message>, RepositoryError>> getFavoriteMessages(
    String roomId,
  );

  /// Get message by ID
  Future<Result<Message?, RepositoryError>> getMessageById(
    String roomId,
    String messageId,
  );

  // =================== Sync Operations ===================

  /// Force sync pending messages (when coming online)
  Future<Result<int, RepositoryError>> syncPendingMessages(String roomId);

  /// Get count of pending (unsent) messages
  Future<int> getPendingMessageCount(String roomId);

  // =================== Batch Operations ===================

  /// Mark multiple messages as read
  Future<Result<void, RepositoryError>> markMessagesAsRead({
    required String roomId,
    required List<String> messageIds,
    required String userId,
  });
}

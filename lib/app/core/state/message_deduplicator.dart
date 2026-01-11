import 'dart:collection';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:get/get.dart';

/// STATE-003: Message Deduplication
/// Prevents duplicate messages from appearing in the UI
/// Uses a combination of message ID and content hash for deduplication

class MessageDeduplicator {
  static final MessageDeduplicator instance = MessageDeduplicator._();
  MessageDeduplicator._();

  final _logger = LoggerService.instance;

  // Track seen message IDs per room
  final Map<String, LinkedHashSet<String>> _seenIds = {};

  // Track pending message hashes (for optimistic updates)
  final Map<String, Set<int>> _pendingHashes = {};

  // Maximum messages to track per room (memory optimization)
  static const int _maxTrackedMessages = 1000;

  /// Deduplicate a list of messages
  List<Message> deduplicate(String roomId, List<Message> messages) {
    _ensureRoomExists(roomId);

    final result = <Message>[];
    final seenInBatch = <String>{};

    for (final message in messages) {
      // Skip if we've seen this ID in this batch
      if (seenInBatch.contains(message.id)) {
        continue;
      }

      // Skip if we've seen this ID before (with valid ID)
      if (message.id.isNotEmpty && _seenIds[roomId]!.contains(message.id)) {
        // Check if this is an update to existing message
        final existingIndex = result.indexWhere((m) => m.id == message.id);
        if (existingIndex >= 0) {
          // Replace with newer version
          result[existingIndex] = message;
        }
        continue;
      }

      // Check for pending optimistic messages by hash
      final hash = _computeMessageHash(message);
      if (_pendingHashes[roomId]?.contains(hash) ?? false) {
        // This is likely a server-confirmed version of an optimistic message
        // Remove from pending and allow it
        _pendingHashes[roomId]!.remove(hash);
      }

      // Add to results
      result.add(message);
      seenInBatch.add(message.id);

      // Track this ID
      if (message.id.isNotEmpty) {
        _addSeenId(roomId, message.id);
      }
    }

    _logger.debug('Deduplicated messages', context: 'MessageDeduplicator', data: {
      'roomId': roomId,
      'input': messages.length,
      'output': result.length,
      'removed': messages.length - result.length,
    });

    return result;
  }

  /// Add a pending optimistic message
  void addPendingMessage(String roomId, Message message) {
    _ensureRoomExists(roomId);
    final hash = _computeMessageHash(message);
    _pendingHashes[roomId]!.add(hash);

    _logger.debug('Added pending message', context: 'MessageDeduplicator', data: {
      'roomId': roomId,
      'hash': hash,
    });
  }

  /// Remove a pending message (e.g., after server confirmation)
  void removePendingMessage(String roomId, Message message) {
    final hash = _computeMessageHash(message);
    _pendingHashes[roomId]?.remove(hash);
  }

  /// Mark a message ID as seen
  void markSeen(String roomId, String messageId) {
    if (messageId.isEmpty) return;
    _ensureRoomExists(roomId);
    _addSeenId(roomId, messageId);
  }

  /// Check if a message ID has been seen
  bool hasSeen(String roomId, String messageId) {
    return _seenIds[roomId]?.contains(messageId) ?? false;
  }

  /// Clear tracking for a room
  void clearRoom(String roomId) {
    _seenIds.remove(roomId);
    _pendingHashes.remove(roomId);
  }

  /// Clear all tracking
  void clearAll() {
    _seenIds.clear();
    _pendingHashes.clear();
  }

  /// Ensure room tracking structures exist
  void _ensureRoomExists(String roomId) {
    _seenIds[roomId] ??= LinkedHashSet<String>();
    _pendingHashes[roomId] ??= <int>{};
  }

  /// Add seen ID with memory management
  void _addSeenId(String roomId, String messageId) {
    final seen = _seenIds[roomId]!;

    // Remove oldest entries if over limit
    while (seen.length >= _maxTrackedMessages) {
      seen.remove(seen.first);
    }

    seen.add(messageId);
  }

  /// Compute hash for message content
  int _computeMessageHash(Message message) {
    // Create hash from message properties that should be unique
    return Object.hash(
      message.senderId,
      message.roomId,
      message.timestamp.millisecondsSinceEpoch ~/ 1000, // Second precision
      message.runtimeType,
      _getMessageContentHash(message),
    );
  }

  /// Get content-specific hash
  int _getMessageContentHash(Message message) {
    // Use message-specific content for hash
    return message.hashCode;
  }
}

/// Reactive message list with automatic deduplication
class RxDeduplicatedMessages extends GetxController {
  final String roomId;
  final _deduplicator = MessageDeduplicator.instance;

  final RxList<Message> _messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  RxDeduplicatedMessages({required this.roomId});

  /// Get deduplicated messages
  List<Message> get messages => _messages;

  /// Get messages as observable
  RxList<Message> get messagesRx => _messages;

  /// Add messages with deduplication
  void addMessages(List<Message> newMessages) {
    final deduplicated = _deduplicator.deduplicate(roomId, newMessages);
    _mergeMessages(deduplicated);
  }

  /// Add a single message
  void addMessage(Message message) {
    addMessages([message]);
  }

  /// Add optimistic message (pending server confirmation)
  void addOptimisticMessage(Message message) {
    _deduplicator.addPendingMessage(roomId, message);
    _messages.insert(0, message); // Add at start (newest first)
  }

  /// Confirm optimistic message with server response
  void confirmOptimisticMessage(Message optimistic, Message confirmed) {
    _deduplicator.removePendingMessage(roomId, optimistic);
    _deduplicator.markSeen(roomId, confirmed.id);

    // Replace optimistic with confirmed
    final index = _messages.indexWhere((m) =>
        m.senderId == optimistic.senderId &&
        m.timestamp.difference(optimistic.timestamp).inSeconds.abs() < 5);

    if (index >= 0) {
      _messages[index] = confirmed;
    } else {
      _messages.insert(0, confirmed);
    }
  }

  /// Update a message in the list
  void updateMessage(String messageId, Message updated) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      _messages[index] = updated;
    }
  }

  /// Remove a message from the list
  void removeMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
  }

  /// Replace all messages
  void setMessages(List<Message> messages) {
    _deduplicator.clearRoom(roomId);
    final deduplicated = _deduplicator.deduplicate(roomId, messages);
    _messages.value = deduplicated;
  }

  /// Clear all messages
  void clear() {
    _messages.clear();
    _deduplicator.clearRoom(roomId);
  }

  /// Merge new messages with existing, maintaining order
  void _mergeMessages(List<Message> newMessages) {
    if (newMessages.isEmpty) return;

    // Create map of existing messages by ID
    final existingById = {for (var m in _messages) m.id: m};

    // Process new messages
    for (final message in newMessages) {
      if (existingById.containsKey(message.id)) {
        // Update existing message
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          _messages[index] = message;
        }
      } else {
        // Insert new message in correct position (by timestamp)
        final insertIndex = _findInsertIndex(message);
        _messages.insert(insertIndex, message);
      }
      existingById[message.id] = message;
    }
  }

  /// Find correct insert position for a message
  int _findInsertIndex(Message message) {
    // Messages are ordered newest first (descending by timestamp)
    for (int i = 0; i < _messages.length; i++) {
      if (message.timestamp.isAfter(_messages[i].timestamp)) {
        return i;
      }
    }
    return _messages.length;
  }

  @override
  void onClose() {
    _deduplicator.clearRoom(roomId);
    super.onClose();
  }
}

/// Extension for easy deduplication
extension MessageListDeduplication on List<Message> {
  /// Deduplicate this list of messages
  List<Message> deduplicated(String roomId) {
    return MessageDeduplicator.instance.deduplicate(roomId, this);
  }

  /// Remove duplicate messages by ID
  List<Message> deduplicatedById() {
    final seen = <String>{};
    return where((message) {
      if (seen.contains(message.id)) return false;
      seen.add(message.id);
      return true;
    }).toList();
  }
}

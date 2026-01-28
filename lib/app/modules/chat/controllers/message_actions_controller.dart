// ARCH-001 FIX: Message Actions Controller
// Extracted message action handling from ChatController to reduce responsibilities

import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Controller responsible for message actions (pin, favorite, delete, etc.)
/// Extracted from ChatController to follow Single Responsibility Principle
class MessageActionsController extends GetxController {
  final IChatRepository _repository;
  final ErrorHandler _errorHandler;

  /// Currently selected messages for batch operations
  final RxList<Message> selectedMessages = <Message>[].obs;

  /// Whether selection mode is active
  final RxBool isSelectionMode = false.obs;

  MessageActionsController({
    required IChatRepository repository,
    ErrorHandler? errorHandler,
  })  : _repository = repository,
        _errorHandler = errorHandler ?? ErrorHandler();

  /// Current room ID (set by parent controller)
  String roomId = '';

  /// Local messages list reference (shared with parent controller)
  RxList<Message> messages = <Message>[].obs;

  /// Initialize with room ID and messages reference
  void initialize({
    required String roomId,
    required RxList<Message> messagesRef,
  }) {
    this.roomId = roomId;
    messages = messagesRef;
  }

  // =================== SELECTION MODE ===================

  /// Toggle selection mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedMessages.clear();
    }
  }

  /// Toggle message selection
  void toggleMessageSelection(Message message) {
    if (selectedMessages.any((m) => m.id == message.id)) {
      selectedMessages.removeWhere((m) => m.id == message.id);
    } else {
      selectedMessages.add(message);
    }

    // Exit selection mode if no messages selected
    if (selectedMessages.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  /// Clear selection
  void clearSelection() {
    selectedMessages.clear();
    isSelectionMode.value = false;
  }

  // =================== PIN OPERATIONS ===================

  /// Toggle pin status for a message
  Future<void> togglePinMessage(Message message) async {
    try {
      _showLoading();

      final isCurrentlyPinned = message.isPinned;

      // If pinning, unpin any existing pinned messages first
      if (!isCurrentlyPinned) {
        await _unpinAllMessages();
      }

      // Toggle pin on Firestore
      await _repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isPinned': !isCurrentlyPinned},
      );

      // Update local state
      _updateLocalMessage(message.id, {'isPinned': !isCurrentlyPinned});

      _showToast(isCurrentlyPinned ? 'Message unpinned' : 'Message pinned');
    } catch (e) {
      _errorHandler.handle(e, context: 'togglePinMessage');
    } finally {
      _hideLoading();
    }
  }

  /// Unpin all messages in the room
  Future<void> _unpinAllMessages() async {
    final pinnedMessages = messages.where((m) => m.isPinned).toList();

    for (final message in pinnedMessages) {
      await _repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isPinned': false},
      );
      _updateLocalMessage(message.id, {'isPinned': false});
    }
  }

  // =================== FAVORITE OPERATIONS ===================

  /// Toggle favorite status for a message
  Future<void> toggleFavoriteMessage(Message message) async {
    try {
      _showLoading();

      final isCurrentlyFavorite = message.isFavorite;

      await _repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isFavorite': !isCurrentlyFavorite},
      );

      _updateLocalMessage(message.id, {'isFavorite': !isCurrentlyFavorite});

      _showToast(isCurrentlyFavorite ? 'Removed from favorites' : 'Added to favorites');
    } catch (e) {
      _errorHandler.handle(e, context: 'toggleFavoriteMessage');
    } finally {
      _hideLoading();
    }
  }

  // =================== DELETE OPERATIONS ===================

  /// Soft delete a message
  Future<void> deleteMessage(Message message) async {
    try {
      _showLoading();

      await _repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': true},
      );

      _updateLocalMessage(message.id, {'isDeleted': true});

      _showToast('Message deleted');
    } catch (e) {
      _errorHandler.handle(e, context: 'deleteMessage');
    } finally {
      _hideLoading();
    }
  }

  /// Restore a deleted message
  Future<void> restoreMessage(Message message) async {
    try {
      _showLoading();

      await _repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': false},
      );

      _updateLocalMessage(message.id, {'isDeleted': false});

      _showToast('Message restored');
    } catch (e) {
      _errorHandler.handle(e, context: 'restoreMessage');
    } finally {
      _hideLoading();
    }
  }

  /// Delete selected messages
  Future<void> deleteSelectedMessages() async {
    if (selectedMessages.isEmpty) return;

    try {
      _showLoading();

      for (final message in selectedMessages) {
        await _repository.updateMessage(
          roomId: roomId,
          messageId: message.id,
          updates: {'isDeleted': true},
        );
        _updateLocalMessage(message.id, {'isDeleted': true});
      }

      _showToast('${selectedMessages.length} messages deleted');
      clearSelection();
    } catch (e) {
      _errorHandler.handle(e, context: 'deleteSelectedMessages');
    } finally {
      _hideLoading();
    }
  }

  // =================== COPY OPERATIONS ===================

  /// Copy message text to clipboard
  void copyMessageText(Message message) {
    String textToCopy = '';

    if (message is TextMessage) {
      textToCopy = message.text;
    } else {
      // For other message types, use a preview
      textToCopy = _getMessagePreview(message);
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      _showToast('Message copied');
    }
  }

  /// Copy selected messages to clipboard
  void copySelectedMessages() {
    if (selectedMessages.isEmpty) return;

    final textBuilder = StringBuffer();
    for (final message in selectedMessages) {
      if (message is TextMessage) {
        textBuilder.writeln(message.text);
      } else {
        textBuilder.writeln(_getMessagePreview(message));
      }
    }

    Clipboard.setData(ClipboardData(text: textBuilder.toString()));
    _showToast('${selectedMessages.length} messages copied');
    clearSelection();
  }

  // =================== REACTION OPERATIONS ===================

  /// Toggle reaction on a message
  Future<void> toggleReaction(Message message, String emoji, String userId) async {
    try {
      await _repository.toggleReaction(
        roomId: roomId,
        messageId: message.id,
        emoji: emoji,
        userId: userId,
      );

      // Local update will come from Firestore stream
    } catch (e) {
      _errorHandler.handle(e, context: 'toggleReaction');
    }
  }

  // =================== HELPERS ===================

  /// Update local message state
  void _updateLocalMessage(String messageId, Map<String, dynamic> updates) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final message = messages[index];

    // Try to create updated message using copyWith
    try {
      final updated = message.copyWith(
        id: message.id,
        isPinned: updates['isPinned'] ?? message.isPinned,
        isFavorite: updates['isFavorite'] ?? message.isFavorite,
        isDeleted: updates['isDeleted'] ?? message.isDeleted,
      );

      if (updated is Message) {
        messages[index] = updated;
      }
    } catch (e) {
      // copyWith not implemented, Firestore stream will update
    }
  }

  /// Get a preview of message content
  String _getMessagePreview(Message message) {
    if (message is TextMessage) {
      return message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text;
    }
    return message.runtimeType.toString().replaceAll('Message', '');
  }

  void _showLoading() => BotToast.showLoading();
  void _hideLoading() => BotToast.closeAllLoading();

  void _showToast(String message) {
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
    );
  }
}

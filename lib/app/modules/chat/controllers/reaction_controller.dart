import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

/// ARCH-001: Extracted Reaction Controller
/// Handles all message reaction operations
///
/// Responsibilities:
/// - Add/remove reactions to messages
/// - Toggle reactions
/// - Remove all user reactions
/// - Track reaction state
class ReactionController extends GetxController {
  final ChatDataSources _chatDataSource;
  final String _roomId;

  ReactionController({
    required ChatDataSources chatDataSource,
    required String roomId,
  })  : _chatDataSource = chatDataSource,
        _roomId = roomId;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Common reaction emojis
  static const List<String> commonReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '🔥',
    '👏',
  ];

  String? get _currentUserId => UserService.currentUser.value?.uid;

  /// Toggle a reaction on a message
  Future<bool> toggleReaction(Message message, String emoji) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    _logger.debug('Toggling reaction', context: 'ReactionController', data: {
      'messageId': message.id,
      'emoji': emoji,
    });

    try {
      await _chatDataSource.toggleReaction(
        roomId: _roomId,
        messageId: message.id,
        emoji: emoji,
        userId: _currentUserId!,
      );

      _logger.info('Reaction toggled successfully', context: 'ReactionController');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'ReactionController.toggleReaction',
        showToUser: true,
      );
      return false;
    }
  }

  /// Add a reaction to a message
  Future<bool> addReaction(Message message, String emoji) async {
    return toggleReaction(message, emoji);
  }

  /// Remove a specific reaction from a message
  Future<bool> removeReaction(Message message, String emoji) async {
    return toggleReaction(message, emoji);
  }

  /// Remove all reactions from current user on a message
  Future<bool> removeAllMyReactions(Message message) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    _logger.debug('Removing all reactions', context: 'ReactionController', data: {
      'messageId': message.id,
    });

    try {
      await _chatDataSource.removeUserReactions(
        roomId: _roomId,
        messageId: message.id,
        userId: _currentUserId!,
      );

      _logger.info('All reactions removed', context: 'ReactionController');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'ReactionController.removeAllMyReactions',
        showToUser: true,
      );
      return false;
    }
  }

  /// Check if current user has reacted with specific emoji
  bool hasUserReacted(Message message, String emoji) {
    if (_currentUserId == null) return false;

    final reactions = message.reactions;
    if (reactions == null || reactions.isEmpty) return false;

    return reactions.any(
      (r) => r['emoji'] == emoji && r['userId'] == _currentUserId,
    );
  }

  /// Get reaction count for a specific emoji on a message
  int getReactionCount(Message message, String emoji) {
    final reactions = message.reactions;
    if (reactions == null || reactions.isEmpty) return 0;

    return reactions.where((r) => r['emoji'] == emoji).length;
  }

  /// Get all unique emojis used on a message with their counts
  Map<String, int> getReactionSummary(Message message) {
    final reactions = message.reactions;
    if (reactions == null || reactions.isEmpty) return {};

    final summary = <String, int>{};
    for (final reaction in reactions) {
      final emoji = reaction['emoji'] as String?;
      if (emoji != null) {
        summary[emoji] = (summary[emoji] ?? 0) + 1;
      }
    }
    return summary;
  }

  /// Get total reaction count on a message
  int getTotalReactionCount(Message message) {
    return message.reactions?.length ?? 0;
  }
}

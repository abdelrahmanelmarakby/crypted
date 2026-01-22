import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';

/// Result of toggling a reaction
class ReactionResult {
  /// Whether the reaction was added (true) or removed (false)
  final bool wasAdded;

  /// The emoji that was toggled
  final String emoji;

  /// New count of this emoji on the message
  final int newCount;

  /// All reactions on the message after the toggle
  final List<Reaction> allReactions;

  const ReactionResult({
    required this.wasAdded,
    required this.emoji,
    required this.newCount,
    required this.allReactions,
  });
}

/// Reaction with user profile information
/// Used for displaying reaction details with user names/avatars
class ReactionWithUser {
  final String emoji;
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime? reactedAt;

  const ReactionWithUser({
    required this.emoji,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.reactedAt,
  });
}

/// Grouped reactions by emoji for efficient display
class GroupedReaction {
  final String emoji;
  final int count;
  final List<ReactionWithUser> users;
  final bool currentUserReacted;

  const GroupedReaction({
    required this.emoji,
    required this.count,
    required this.users,
    required this.currentUserReacted,
  });
}

/// Abstract interface for reaction repository
/// Handles all message reaction operations with optimized user loading
///
/// Key design decisions:
/// 1. Batch user profile loading to avoid N+1 queries
/// 2. Toggle-based API (simpler than separate add/remove)
/// 3. Grouped reactions for efficient UI rendering
abstract class IReactionRepository {
  // =================== Core Operations ===================

  /// Toggle a reaction on a message
  /// If user already reacted with this emoji, removes it
  /// If user hasn't reacted with this emoji, adds it
  ///
  /// Validates:
  /// - Message exists and is not pending
  /// - Emoji is valid
  ///
  /// Emits ReactionEvent through EventBus on success
  Future<Result<ReactionResult, RepositoryError>> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Remove all reactions by a user from a message
  Future<Result<void, RepositoryError>> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  });

  // =================== Query Operations ===================

  /// Get all reactions with user profiles (batch loaded)
  /// This is the PRIMARY method for displaying reaction details
  ///
  /// Performance: Uses batch user loading (1 query for N users)
  /// instead of N individual queries
  Future<Result<List<ReactionWithUser>, RepositoryError>> getReactionsWithUsers({
    required String roomId,
    required String messageId,
  });

  /// Get reactions grouped by emoji with user info
  /// Optimized for reaction chips display (e.g., "👍 3  ❤️ 2")
  Future<Result<List<GroupedReaction>, RepositoryError>> getGroupedReactions({
    required String roomId,
    required String messageId,
    required String currentUserId,
  });

  /// Get users who reacted with a specific emoji
  Future<Result<List<ReactionWithUser>, RepositoryError>> getUsersForEmoji({
    required String roomId,
    required String messageId,
    required String emoji,
  });

  // =================== Validation ===================

  /// Check if a user has reacted with a specific emoji
  Future<Result<bool, RepositoryError>> hasUserReacted({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Validate that an emoji is allowed
  /// Can be extended to support custom emoji sets
  bool isValidEmoji(String emoji);
}

/// Default allowed emojis for quick picker
const List<String> kDefaultReactionEmojis = [
  '👍', // Thumbs up
  '❤️', // Heart
  '😂', // Laughing
  '😮', // Surprised
  '😢', // Sad
  '🙏', // Praying
  '🔥', // Fire
  '👏', // Clapping
];

/// Extended emoji categories for full picker
const Map<String, List<String>> kEmojiCategories = {
  'Smileys': [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
    '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '☺️', '😚',
    '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
    '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
  ],
  'Gestures': [
    '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘',
    '👌', '🤏', '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️',
    '🖖', '👋', '🤙', '💪', '🦾', '🙏', '👏', '🙌', '👐',
  ],
  'Hearts': [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '♥️',
  ],
  'Symbols': [
    '⭐', '🌟', '✨', '💫', '🔥', '💥', '💢', '💦', '💨', '🎉',
    '🎊', '🎈', '🎁', '🏆', '🥇', '🥈', '🥉', '⚡', '💯', '✅',
  ],
};

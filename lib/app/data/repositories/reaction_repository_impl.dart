import 'package:crypted_app/app/core/caching/user_profile_cache.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/datasources/firebase/firebase_reaction_datasource.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:flutter/foundation.dart';

/// Implementation of IReactionRepository
/// Uses batch user loading for performance optimization
class ReactionRepositoryImpl implements IReactionRepository {
  final IFirebaseReactionDataSource _remoteDataSource;
  final UserProfileCache _userCache;
  final EventBus _eventBus;

  ReactionRepositoryImpl({
    required IFirebaseReactionDataSource remoteDataSource,
    required UserProfileCache userCache,
    required EventBus eventBus,
  })  : _remoteDataSource = remoteDataSource,
        _userCache = userCache,
        _eventBus = eventBus;

  // =================== Core Operations ===================

  @override
  Future<Result<ReactionResult, RepositoryError>> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      // Validate emoji
      if (!isValidEmoji(emoji)) {
        return Result.failure(RepositoryError.validation('Invalid emoji'));
      }

      // Validate message ID (prevent reacting to pending messages)
      if (messageId.isEmpty || messageId.startsWith('pending_')) {
        return Result.failure(
          RepositoryError.validation('Cannot react to pending message'),
        );
      }

      // Toggle reaction in Firebase
      final result = await _remoteDataSource.toggleReaction(
        roomId: roomId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
      );

      // EMIT: Reaction event
      _eventBus.emit(ReactionEvent(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        added: result.wasAdded,
      ));

      if (kDebugMode) {
        print(result.wasAdded
            ? '✅ Added reaction $emoji'
            : '🔄 Removed reaction $emoji');
      }

      return Result.success(result);
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Error toggling reaction: $e');
      }
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.removeUserReactions(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
      );

      // EMIT: Multiple reaction events for removal
      _eventBus.emit(ReactionEvent(
        roomId: roomId,
        messageId: messageId,
        userId: userId,
        emoji: '', // All emojis
        added: false,
      ));

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Query Operations ===================

  @override
  Future<Result<List<ReactionWithUser>, RepositoryError>> getReactionsWithUsers({
    required String roomId,
    required String messageId,
  }) async {
    try {
      // 1. Get raw reactions from message
      final reactions = await _remoteDataSource.getReactions(roomId, messageId);

      if (reactions.isEmpty) {
        return Result.success([]);
      }

      // 2. Extract unique user IDs
      final userIds = reactions.map((r) => r.userId).toSet().toList();

      // 3. BATCH load user profiles (KEY PERFORMANCE FIX!)
      // This makes 1 query instead of N queries
      final userProfiles = await _userCache.batchGetProfiles(userIds);

      // 4. Combine reactions with user data
      final reactionsWithUsers = reactions.map((r) {
        final user = userProfiles[r.userId];
        return ReactionWithUser(
          emoji: r.emoji,
          userId: r.userId,
          userName: user?.fullName ?? 'Unknown User',
          userAvatar: user?.imageUrl,
          reactedAt: null, // Could parse from reaction timestamp if stored
        );
      }).toList();

      if (kDebugMode) {
        print('📦 Loaded ${reactionsWithUsers.length} reactions with ${userProfiles.length} unique users');
      }

      return Result.success(reactionsWithUsers);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<GroupedReaction>, RepositoryError>> getGroupedReactions({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    try {
      // Get reactions with user info
      final result = await getReactionsWithUsers(
        roomId: roomId,
        messageId: messageId,
      );

      return result.fold(
        onSuccess: (reactionsWithUsers) {
          // Group by emoji
          final grouped = <String, List<ReactionWithUser>>{};
          for (final reaction in reactionsWithUsers) {
            grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
          }

          // Convert to GroupedReaction list
          final groupedReactions = grouped.entries.map((entry) {
            final emoji = entry.key;
            final users = entry.value;
            final currentUserReacted =
                users.any((u) => u.userId == currentUserId);

            return GroupedReaction(
              emoji: emoji,
              count: users.length,
              users: users,
              currentUserReacted: currentUserReacted,
            );
          }).toList();

          // Sort by count descending
          groupedReactions.sort((a, b) => b.count.compareTo(a.count));

          return Result<List<GroupedReaction>, RepositoryError>.success(
            groupedReactions,
          );
        },
        onFailure: (error) => Result.failure(error),
      );
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<ReactionWithUser>, RepositoryError>> getUsersForEmoji({
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      // Get all reactions with users
      final result = await getReactionsWithUsers(
        roomId: roomId,
        messageId: messageId,
      );

      return result.fold(
        onSuccess: (reactionsWithUsers) {
          // Filter by emoji
          final filtered =
              reactionsWithUsers.where((r) => r.emoji == emoji).toList();
          return Result<List<ReactionWithUser>, RepositoryError>.success(
            filtered,
          );
        },
        onFailure: (error) => Result.failure(error),
      );
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Validation ===================

  @override
  Future<Result<bool, RepositoryError>> hasUserReacted({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final reactions = await _remoteDataSource.getReactions(roomId, messageId);
      final hasReacted = reactions.any(
        (r) => r.emoji == emoji && r.userId == userId,
      );
      return Result.success(hasReacted);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  bool isValidEmoji(String emoji) {
    if (emoji.isEmpty) return false;

    // Check if it's in our default set
    if (kDefaultReactionEmojis.contains(emoji)) return true;

    // Check if it's in any category
    for (final category in kEmojiCategories.values) {
      if (category.contains(emoji)) return true;
    }

    // Basic emoji validation (emoji characters are typically > 0x1000)
    final codeUnits = emoji.codeUnits;
    if (codeUnits.isEmpty) return false;

    // Allow most unicode emojis
    return codeUnits.first > 0x1000 || emoji.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true));
  }
}

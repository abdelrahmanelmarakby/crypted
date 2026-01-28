import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/domain/usecases/reaction/toggle_reaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple Mock Implementation
class MockReactionRepository implements IReactionRepository {
  Result<ReactionResult, RepositoryError>? toggleReactionResult;
  int toggleReactionCallCount = 0;
  Map<String, dynamic>? lastToggleReactionParams;

  @override
  Future<Result<ReactionResult, RepositoryError>> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    toggleReactionCallCount++;
    lastToggleReactionParams = {
      'roomId': roomId,
      'messageId': messageId,
      'emoji': emoji,
      'userId': userId,
    };
    return toggleReactionResult ??
        Result.success(
          const ReactionResult(
            wasAdded: true,
            emoji: '👍',
            newCount: 1,
            allReactions: [],
          ),
        );
  }

  @override
  Future<Result<void, RepositoryError>> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<ReactionWithUser>, RepositoryError>> getReactionsWithUsers({
    required String roomId,
    required String messageId,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<GroupedReaction>, RepositoryError>> getGroupedReactions({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<ReactionWithUser>, RepositoryError>> getUsersForEmoji({
    required String roomId,
    required String messageId,
    required String emoji,
  }) async {
    return Result.success([]);
  }

  @override
  Future<Result<bool, RepositoryError>> hasUserReacted({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    return Result.success(false);
  }

  @override
  bool isValidEmoji(String emoji) {
    return emoji.isNotEmpty;
  }
}

void main() {
  late ToggleReactionUseCase useCase;
  late MockReactionRepository mockRepository;

  setUp(() {
    mockRepository = MockReactionRepository();
    useCase = ToggleReactionUseCase(repository: mockRepository);
  });

  group('ToggleReactionUseCase', () {
    final validParams = ToggleReactionParams(
      roomId: 'room123',
      messageId: 'msg123',
      emoji: '👍',
      userId: 'user123',
    );

    test('should return success when reaction is added', () async {
      // Arrange
      mockRepository.toggleReactionResult = Result.success(
        const ReactionResult(
          wasAdded: true,
          emoji: '👍',
          newCount: 1,
          allReactions: [],
        ),
      );

      // Act
      final result = await useCase.call(validParams);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (reactionResult) {
          expect(reactionResult.wasAdded, isTrue);
          expect(reactionResult.emoji, '👍');
          expect(reactionResult.newCount, 1);
        },
        onFailure: (_) => fail('Should not fail'),
      );
      expect(mockRepository.toggleReactionCallCount, 1);
    });

    test('should return success when reaction is removed', () async {
      // Arrange
      mockRepository.toggleReactionResult = Result.success(
        const ReactionResult(
          wasAdded: false,
          emoji: '👍',
          newCount: 0,
          allReactions: [],
        ),
      );

      // Act
      final result = await useCase.call(validParams);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (reactionResult) {
          expect(reactionResult.wasAdded, isFalse);
          expect(reactionResult.newCount, 0);
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('should return failure when room ID is empty', () async {
      // Arrange
      final invalidParams = ToggleReactionParams(
        roomId: '',
        messageId: 'msg123',
        emoji: '👍',
        userId: 'user123',
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Room ID is required');
        },
      );
      expect(mockRepository.toggleReactionCallCount, 0);
    });

    test('should return failure when message ID is empty', () async {
      // Arrange
      final invalidParams = ToggleReactionParams(
        roomId: 'room123',
        messageId: '',
        emoji: '👍',
        userId: 'user123',
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Message ID is required');
        },
      );
    });

    test('should return failure when emoji is empty', () async {
      // Arrange
      final invalidParams = ToggleReactionParams(
        roomId: 'room123',
        messageId: 'msg123',
        emoji: '',
        userId: 'user123',
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Emoji is required');
        },
      );
    });

    test('should return failure when user ID is empty', () async {
      // Arrange
      final invalidParams = ToggleReactionParams(
        roomId: 'room123',
        messageId: 'msg123',
        emoji: '👍',
        userId: '',
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'User ID is required');
        },
      );
    });

    test('should return failure when reacting to pending message', () async {
      // Arrange
      final pendingParams = ToggleReactionParams(
        roomId: 'room123',
        messageId: 'pending_123',
        emoji: '👍',
        userId: 'user123',
      );

      // Act
      final result = await useCase.call(pendingParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, contains('pending'));
        },
      );
    });

    test('should propagate repository error', () async {
      // Arrange
      mockRepository.toggleReactionResult = Result.failure(
        RepositoryError.network('Connection failed'),
      );

      // Act
      final result = await useCase.call(validParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'NETWORK');
        },
      );
    });

    test('should pass correct parameters to repository', () async {
      // Act
      await useCase.call(validParams);

      // Assert
      expect(mockRepository.lastToggleReactionParams?['roomId'], 'room123');
      expect(mockRepository.lastToggleReactionParams?['messageId'], 'msg123');
      expect(mockRepository.lastToggleReactionParams?['emoji'], '👍');
      expect(mockRepository.lastToggleReactionParams?['userId'], 'user123');
    });
  });
}

import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:crypted_app/app/domain/usecases/forward/forward_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: unused_element

// Simple Mock Implementations
class MockForwardRepository implements IForwardRepository {
  Result<ForwardResult, RepositoryError>? forwardMessageResult;
  Result<BatchForwardResult, RepositoryError>? forwardMessagesResult;
  Result<BatchForwardResult, RepositoryError>? forwardToMultipleResult;
  Result<bool, RepositoryError>? canForwardMessageResult;
  Result<bool, RepositoryError>? canForwardToTargetResult;
  Result<String, RepositoryError>? getOrCreatePrivateRoomResult;

  int forwardMessageCallCount = 0;
  int forwardMessagesCallCount = 0;
  int forwardToMultipleCallCount = 0;
  int canForwardMessageCallCount = 0;
  int canForwardToTargetCallCount = 0;

  Map<String, dynamic>? lastForwardMessageParams;
  Map<String, dynamic>? lastForwardMessagesParams;
  Map<String, dynamic>? lastForwardToMultipleParams;

  @override
  Future<Result<ForwardResult, RepositoryError>> forwardMessage({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) async {
    forwardMessageCallCount++;
    lastForwardMessageParams = {
      'sourceRoomId': sourceRoomId,
      'message': message,
      'currentUserId': currentUserId,
      'targetRoomId': targetRoomId,
      'targetUserId': targetUserId,
      'options': options,
    };
    return forwardMessageResult ??
        Result.success(ForwardResult(
          messageId: 'fwd_msg_123',
          targetRoomId: targetRoomId ?? 'room_123',
        ));
  }

  @override
  Future<Result<BatchForwardResult, RepositoryError>> forwardMessages({
    required String sourceRoomId,
    required List<Message> messages,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) async {
    forwardMessagesCallCount++;
    lastForwardMessagesParams = {
      'sourceRoomId': sourceRoomId,
      'messages': messages,
      'currentUserId': currentUserId,
      'targetRoomId': targetRoomId,
      'targetUserId': targetUserId,
      'options': options,
    };
    return forwardMessagesResult ??
        Result.success(BatchForwardResult(
          successful: messages
              .map((m) => ForwardResult(
                    messageId: 'fwd_${m.id}',
                    targetRoomId: targetRoomId ?? 'room_123',
                  ))
              .toList(),
          failed: {},
        ));
  }

  @override
  Future<Result<BatchForwardResult, RepositoryError>> forwardToMultiple({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    required List<String> targetRoomIds,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) async {
    forwardToMultipleCallCount++;
    lastForwardToMultipleParams = {
      'sourceRoomId': sourceRoomId,
      'message': message,
      'currentUserId': currentUserId,
      'targetRoomIds': targetRoomIds,
      'options': options,
    };
    return forwardToMultipleResult ??
        Result.success(BatchForwardResult(
          successful: targetRoomIds
              .map((roomId) => ForwardResult(
                    messageId: 'fwd_${message.id}_$roomId',
                    targetRoomId: roomId,
                  ))
              .toList(),
          failed: {},
        ));
  }

  @override
  Future<Result<bool, RepositoryError>> canForwardMessage({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    canForwardMessageCallCount++;
    return canForwardMessageResult ?? Result.success(true);
  }

  @override
  Future<Result<bool, RepositoryError>> canForwardToTarget({
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
  }) async {
    canForwardToTargetCallCount++;
    return canForwardToTargetResult ?? Result.success(true);
  }

  @override
  Future<Result<String, RepositoryError>> getOrCreatePrivateRoom({
    required String currentUserId,
    required String targetUserId,
  }) async {
    return getOrCreatePrivateRoomResult ??
        Result.success('private_room_$targetUserId');
  }

  @override
  Message createForwardedMessage({
    required Message original,
    required String forwarderId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) {
    return TextMessage(
      id: 'fwd_${original.id}',
      roomId: original.roomId,
      senderId: forwarderId,
      timestamp: DateTime.now(),
      text: (original as TextMessage).text,
      isForwarded: true,
      forwardedFrom: original.senderId,
    );
  }
}

class MockRateLimiter extends RateLimiter {
  RateLimitResult? checkAndRecordResult;
  int checkAndRecordCallCount = 0;

  MockRateLimiter() : super(RateLimitConfig.messages);

  @override
  RateLimitResult checkAndRecord() {
    checkAndRecordCallCount++;
    return checkAndRecordResult ?? RateLimitResult.allowed(9, 10000);
  }
}

void main() {
  late ForwardMessageUseCase forwardUseCase;
  late BatchForwardUseCase batchForwardUseCase;
  late ForwardToMultipleUseCase forwardToMultipleUseCase;
  late MockForwardRepository mockRepository;
  late MockRateLimiter mockRateLimiter;

  final testMessage = TextMessage(
    id: 'msg123',
    roomId: 'room123',
    senderId: 'sender123',
    timestamp: DateTime.now(),
    text: 'Hello, world!',
  );

  setUp(() {
    mockRepository = MockForwardRepository();
    mockRateLimiter = MockRateLimiter();
    forwardUseCase = ForwardMessageUseCase(
      repository: mockRepository,
      rateLimiter: mockRateLimiter,
    );
    batchForwardUseCase = BatchForwardUseCase(
      repository: mockRepository,
      rateLimiter: mockRateLimiter,
    );
    forwardToMultipleUseCase = ForwardToMultipleUseCase(
      repository: mockRepository,
      rateLimiter: mockRateLimiter,
    );
  });

  group('ForwardMessageUseCase', () {
    final testParams = ForwardMessageParams(
      sourceRoomId: 'source_room_123',
      message: testMessage,
      currentUserId: 'user123',
      targetRoomId: 'target_room_123',
    );

    test('should return success when message is forwarded', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.canForwardMessageResult = Result.success(true);
      mockRepository.canForwardToTargetResult = Result.success(true);
      mockRepository.forwardMessageResult = Result.success(ForwardResult(
        messageId: 'fwd_msg_123',
        targetRoomId: 'target_room_123',
      ));

      // Act
      final result = await forwardUseCase.call(testParams);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (forwardResult) {
          expect(forwardResult.messageId, 'fwd_msg_123');
          expect(forwardResult.targetRoomId, 'target_room_123');
        },
        onFailure: (_) => fail('Should not fail'),
      );
      expect(mockRepository.forwardMessageCallCount, 1);
      expect(mockRepository.canForwardMessageCallCount, 1);
      expect(mockRepository.canForwardToTargetCallCount, 1);
    });

    test('should return failure when source room ID is empty', () async {
      // Arrange
      final invalidParams = ForwardMessageParams(
        sourceRoomId: '',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await forwardUseCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Source room ID is required');
        },
      );
      expect(mockRepository.forwardMessageCallCount, 0);
    });

    test('should return failure when message ID is empty', () async {
      // Arrange
      final messageWithNoId = TextMessage(
        id: '',
        roomId: 'room123',
        senderId: 'sender123',
        timestamp: DateTime.now(),
        text: 'Hello',
      );
      final invalidParams = ForwardMessageParams(
        sourceRoomId: 'room123',
        message: messageWithNoId,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await forwardUseCase.call(invalidParams);

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

    test('should return failure when message is pending', () async {
      // Arrange
      final pendingMessage = TextMessage(
        id: 'pending_msg123',
        roomId: 'room123',
        senderId: 'sender123',
        timestamp: DateTime.now(),
        text: 'Hello',
      );
      final invalidParams = ForwardMessageParams(
        sourceRoomId: 'room123',
        message: pendingMessage,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await forwardUseCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Cannot forward pending message');
        },
      );
    });

    test('should return failure when no target is specified', () async {
      // Arrange
      final invalidParams = ForwardMessageParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        // No targetRoomId or targetUserId
      );

      // Act
      final result = await forwardUseCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Either target room or target user is required');
        },
      );
    });

    test('should return failure when both targets are specified', () async {
      // Arrange
      final invalidParams = ForwardMessageParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
        targetUserId: 'target_user_123',
      );

      // Act
      final result = await forwardUseCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Cannot specify both target room and target user');
        },
      );
    });

    test('should return failure when rate limited', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult =
          RateLimitResult.denied(5000, 'Rate limit exceeded');

      // Act
      final result = await forwardUseCase.call(testParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'RATE_LIMIT');
        },
      );
      expect(mockRepository.forwardMessageCallCount, 0);
    });

    test('should return failure when canForwardMessage returns false', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.canForwardMessageResult = Result.success(false);

      // Act
      final result = await forwardUseCase.call(testParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'UNAUTHORIZED');
        },
      );
      expect(mockRepository.forwardMessageCallCount, 0);
    });

    test('should return failure when canForwardToTarget returns false', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.canForwardMessageResult = Result.success(true);
      mockRepository.canForwardToTargetResult = Result.success(false);

      // Act
      final result = await forwardUseCase.call(testParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'UNAUTHORIZED');
        },
      );
      expect(mockRepository.forwardMessageCallCount, 0);
    });

    test('should work without rate limiter', () async {
      // Arrange
      final useCaseWithoutRateLimiter = ForwardMessageUseCase(
        repository: mockRepository,
      );
      mockRepository.canForwardMessageResult = Result.success(true);
      mockRepository.canForwardToTargetResult = Result.success(true);

      // Act
      final result = await useCaseWithoutRateLimiter.call(testParams);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should propagate repository failure', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.canForwardMessageResult = Result.success(true);
      mockRepository.canForwardToTargetResult = Result.success(true);
      mockRepository.forwardMessageResult = Result.failure(
        RepositoryError.network('Connection failed'),
      );

      // Act
      final result = await forwardUseCase.call(testParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'NETWORK');
          expect(error.message, 'Connection failed');
        },
      );
    });
  });

  group('BatchForwardUseCase', () {
    late List<TextMessage> testMessages;

    setUp(() {
      testMessages = List.generate(
        3,
        (i) => TextMessage(
          id: 'msg_$i',
          roomId: 'room123',
          senderId: 'sender123',
          timestamp: DateTime.now(),
          text: 'Message $i',
        ),
      );
    });

    test('should return success when messages are forwarded', () async {
      // Arrange
      final params = BatchForwardParams(
        sourceRoomId: 'room123',
        messages: testMessages,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await batchForwardUseCase.call(params);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (batchResult) {
          expect(batchResult.successful.length, 3);
          expect(batchResult.failed.isEmpty, isTrue);
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('should return failure when messages list is empty', () async {
      // Arrange
      final params = BatchForwardParams(
        sourceRoomId: 'room123',
        messages: [],
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await batchForwardUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'At least one message is required');
        },
      );
    });

    test('should return failure when messages exceed limit', () async {
      // Arrange
      final tooManyMessages = List.generate(
        11,
        (i) => TextMessage(
          id: 'msg_$i',
          roomId: 'room123',
          senderId: 'sender123',
          timestamp: DateTime.now(),
          text: 'Message $i',
        ),
      );
      final params = BatchForwardParams(
        sourceRoomId: 'room123',
        messages: tooManyMessages,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await batchForwardUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Cannot forward more than 10 messages at once');
        },
      );
    });

    test('should return failure when any message is pending', () async {
      // Arrange
      final messagesWithPending = [
        testMessages[0],
        TextMessage(
          id: 'pending_msg1',
          roomId: 'room123',
          senderId: 'sender123',
          timestamp: DateTime.now(),
          text: 'Pending message',
        ),
      ];
      final params = BatchForwardParams(
        sourceRoomId: 'room123',
        messages: messagesWithPending,
        currentUserId: 'user123',
        targetRoomId: 'target_room_123',
      );

      // Act
      final result = await batchForwardUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Cannot forward pending messages');
        },
      );
    });
  });

  group('ForwardToMultipleUseCase', () {
    test('should return success when message is forwarded to multiple', () async {
      // Arrange
      final params = ForwardToMultipleParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomIds: ['room_a', 'room_b', 'room_c'],
      );

      // Act
      final result = await forwardToMultipleUseCase.call(params);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (batchResult) {
          expect(batchResult.successful.length, 3);
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('should return failure when target room list is empty', () async {
      // Arrange
      final params = ForwardToMultipleParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomIds: [],
      );

      // Act
      final result = await forwardToMultipleUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'At least one target room is required');
        },
      );
    });

    test('should return failure when target rooms exceed limit', () async {
      // Arrange
      final params = ForwardToMultipleParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomIds: ['room_1', 'room_2', 'room_3', 'room_4', 'room_5', 'room_6'],
      );

      // Act
      final result = await forwardToMultipleUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Cannot forward to more than 5 chats at once');
        },
      );
    });

    test('should check canForwardMessage before forwarding', () async {
      // Arrange
      mockRepository.canForwardMessageResult = Result.success(false);
      final params = ForwardToMultipleParams(
        sourceRoomId: 'room123',
        message: testMessage,
        currentUserId: 'user123',
        targetRoomIds: ['room_a', 'room_b'],
      );

      // Act
      final result = await forwardToMultipleUseCase.call(params);

      // Assert
      expect(result.isFailure, isTrue);
      expect(mockRepository.canForwardMessageCallCount, 1);
      expect(mockRepository.forwardToMultipleCallCount, 0);
    });
  });

  group('ForwardOptions', () {
    test('should have correct default values', () {
      // Arrange & Act
      const options = ForwardOptions.defaultOptions;

      // Assert
      expect(options.includeAttribution, isTrue);
      expect(options.stripMedia, isFalse);
      expect(options.customPrefix, isNull);
    });

    test('should allow custom configuration', () {
      // Arrange & Act
      const options = ForwardOptions(
        includeAttribution: false,
        stripMedia: true,
        customPrefix: 'Forwarded:',
      );

      // Assert
      expect(options.includeAttribution, isFalse);
      expect(options.stripMedia, isTrue);
      expect(options.customPrefix, 'Forwarded:');
    });
  });

  group('BatchForwardResult', () {
    test('should calculate success rate correctly', () {
      // Arrange
      final result = BatchForwardResult(
        successful: [
          ForwardResult(messageId: 'msg1', targetRoomId: 'room1'),
          ForwardResult(messageId: 'msg2', targetRoomId: 'room1'),
        ],
        failed: {'msg3': 'Error'},
      );

      // Assert
      expect(result.totalAttempted, 3);
      expect(result.successRate, closeTo(66.67, 0.1));
      expect(result.allSucceeded, isFalse);
      expect(result.anySucceeded, isTrue);
    });

    test('should report allSucceeded when no failures', () {
      // Arrange
      final result = BatchForwardResult(
        successful: [
          ForwardResult(messageId: 'msg1', targetRoomId: 'room1'),
        ],
        failed: {},
      );

      // Assert
      expect(result.allSucceeded, isTrue);
      expect(result.successRate, 100);
    });
  });
}

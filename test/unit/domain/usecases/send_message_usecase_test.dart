import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_message_repository.dart';
import 'package:crypted_app/app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: unused_element

// Simple Mock Implementations
class MockMessageRepository implements IMessageRepository {
  Result<String, RepositoryError>? sendMessageResult;
  int sendMessageCallCount = 0;
  Map<String, dynamic>? lastSendMessageParams;

  @override
  Future<Result<String, RepositoryError>> sendMessage({
    required String roomId,
    required Message message,
    required List<String> memberIds,
  }) async {
    sendMessageCallCount++;
    lastSendMessageParams = {
      'roomId': roomId,
      'message': message,
      'memberIds': memberIds,
    };
    return sendMessageResult ?? Result.success('msg123');
  }

  // Mock implementations for other methods
  @override
  Stream<Result<List<Message>, RepositoryError>> watchMessages(String roomId, {int limit = 30, String? startAfterId}) {
    return Stream.value(Result.success([]));
  }

  @override
  Stream<Result<Message, RepositoryError>> watchMessage(String roomId, String messageId) {
    return Stream.value(Result.failure(RepositoryError.notFound('Message')));
  }

  @override
  Future<Result<void, RepositoryError>> editMessage({required String roomId, required String messageId, required String newText, required String userId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<void, RepositoryError>> deleteMessage({required String roomId, required String messageId, required String userId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<void, RepositoryError>> restoreMessage({required String roomId, required String messageId, required String userId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<void, RepositoryError>> permanentlyDeleteMessage({required String roomId, required String messageId, required String userId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<void, RepositoryError>> togglePin({required String roomId, required String messageId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<void, RepositoryError>> toggleFavorite({required String roomId, required String messageId}) async {
    return Result.success(null);
  }

  @override
  Future<Result<List<Message>, RepositoryError>> searchMessages({required String roomId, required String query, int limit = 50}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getMessagesByType({required String roomId, required MessageType type, int limit = 50}) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getPinnedMessages(String roomId) async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Message>, RepositoryError>> getFavoriteMessages(String roomId) async {
    return Result.success([]);
  }

  @override
  Future<Result<Message?, RepositoryError>> getMessageById(String roomId, String messageId) async {
    return Result.success(null);
  }

  @override
  Future<Result<int, RepositoryError>> syncPendingMessages(String roomId) async {
    return Result.success(0);
  }

  @override
  Future<int> getPendingMessageCount(String roomId) async {
    return 0;
  }

  @override
  Future<Result<void, RepositoryError>> markMessagesAsRead({required String roomId, required List<String> messageIds, required String userId}) async {
    return Result.success(null);
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
  late SendMessageUseCase useCase;
  late MockMessageRepository mockRepository;
  late MockRateLimiter mockRateLimiter;

  setUp(() {
    mockRepository = MockMessageRepository();
    mockRateLimiter = MockRateLimiter();
    useCase = SendMessageUseCase(
      repository: mockRepository,
      rateLimiter: mockRateLimiter,
    );
  });

  group('SendMessageUseCase', () {
    final testMessage = TextMessage(
      id: '',
      roomId: 'room123',
      senderId: 'user123',
      timestamp: DateTime.now(),
      text: 'Hello, world!',
    );

    final testParams = SendMessageParams(
      roomId: 'room123',
      message: testMessage,
      memberIds: ['user123', 'user456'],
    );

    test('should return success when message is sent', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.sendMessageResult = Result.success('msg123');

      // Act
      final result = await useCase.call(testParams);

      // Assert
      expect(result.isSuccess, isTrue);
      result.fold(
        onSuccess: (messageId) => expect(messageId, 'msg123'),
        onFailure: (_) => fail('Should not fail'),
      );
      expect(mockRepository.sendMessageCallCount, 1);
      expect(mockRepository.lastSendMessageParams?['roomId'], 'room123');
    });

    test('should return failure when rate limited', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.denied(5000, 'Rate limit exceeded');

      // Act
      final result = await useCase.call(testParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'RATE_LIMIT');
        },
      );
      expect(mockRepository.sendMessageCallCount, 0); // Should not reach repository
    });

    test('should return failure when room ID is empty', () async {
      // Arrange
      final invalidParams = SendMessageParams(
        roomId: '',
        message: testMessage,
        memberIds: ['user123'],
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
    });

    test('should return failure when sender ID is empty', () async {
      // Arrange
      final messageWithNoSender = TextMessage(
        id: '',
        roomId: 'room123',
        senderId: '',
        timestamp: DateTime.now(),
        text: 'Hello',
      );
      final invalidParams = SendMessageParams(
        roomId: 'room123',
        message: messageWithNoSender,
        memberIds: ['user123'],
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Sender ID is required');
        },
      );
    });

    test('should return failure when members list is empty', () async {
      // Arrange
      final invalidParams = SendMessageParams(
        roomId: 'room123',
        message: testMessage,
        memberIds: [],
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'At least one member is required');
        },
      );
    });

    test('should return failure when text message is empty', () async {
      // Arrange
      final emptyTextMessage = TextMessage(
        id: '',
        roomId: 'room123',
        senderId: 'user123',
        timestamp: DateTime.now(),
        text: '',
      );
      final invalidParams = SendMessageParams(
        roomId: 'room123',
        message: emptyTextMessage,
        memberIds: ['user123'],
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, 'Message text cannot be empty');
        },
      );
    });

    test('should return failure when text message is too long', () async {
      // Arrange
      final longText = 'a' * 10001; // Exceeds 10000 char limit
      final longTextMessage = TextMessage(
        id: '',
        roomId: 'room123',
        senderId: 'user123',
        timestamp: DateTime.now(),
        text: longText,
      );
      final invalidParams = SendMessageParams(
        roomId: 'room123',
        message: longTextMessage,
        memberIds: ['user123'],
      );

      // Act
      final result = await useCase.call(invalidParams);

      // Assert
      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error.code, 'VALIDATION');
          expect(error.message, contains('too long'));
        },
      );
    });

    test('should work without rate limiter', () async {
      // Arrange
      final useCaseWithoutRateLimiter = SendMessageUseCase(
        repository: mockRepository,
      );
      mockRepository.sendMessageResult = Result.success('msg123');

      // Act
      final result = await useCaseWithoutRateLimiter.call(testParams);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should propagate repository failure', () async {
      // Arrange
      mockRateLimiter.checkAndRecordResult = RateLimitResult.allowed(9, 10000);
      mockRepository.sendMessageResult = Result.failure(
        RepositoryError.network('Connection failed'),
      );

      // Act
      final result = await useCase.call(testParams);

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
}

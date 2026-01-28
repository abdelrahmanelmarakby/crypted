import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/services/chat_privacy_helper.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_forward_repository.dart';
import 'package:flutter/foundation.dart';

/// Implementation of IForwardRepository
///
/// Handles message forwarding with:
/// - Privacy validation
/// - Message copying with forward metadata
/// - Event emission for real-time updates
/// - Support for all message types
class ForwardRepositoryImpl implements IForwardRepository {
  final FirebaseFirestore _firestore;
  final EventBus _eventBus;
  final ChatPrivacyHelper? _privacyHelper;

  ForwardRepositoryImpl({
    FirebaseFirestore? firestore,
    required EventBus eventBus,
    ChatPrivacyHelper? privacyHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _eventBus = eventBus,
        _privacyHelper = privacyHelper;

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // =================== Core Operations ===================

  @override
  Future<Result<ForwardResult, RepositoryError>> forwardMessage({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) async {
    try {
      // 1. Determine target room
      String actualTargetRoomId;
      bool newRoomCreated = false;

      if (targetRoomId != null) {
        actualTargetRoomId = targetRoomId;
      } else if (targetUserId != null) {
        final roomResult = await getOrCreatePrivateRoom(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        );

        if (roomResult.isFailure) {
          return Result.failure(roomResult.errorOrNull!);
        }

        actualTargetRoomId = roomResult.dataOrNull!;
        // Check if this was a new room
        newRoomCreated = true; // We could track this in getOrCreatePrivateRoom
      } else {
        return Result.failure(
          RepositoryError.validation('Target room or user is required'),
        );
      }

      // 2. Create forwarded message
      final forwardedMessage = createForwardedMessage(
        original: message,
        forwarderId: currentUserId,
        options: options,
      );

      // 3. Get target room members for notification
      final targetRoomDoc = await _chatsCollection.doc(actualTargetRoomId).get();
      if (!targetRoomDoc.exists) {
        return Result.failure(RepositoryError.notFound('Target chat room'));
      }

      final targetRoomData = targetRoomDoc.data() as Map<String, dynamic>?;
      final memberIds = List<String>.from(targetRoomData?['membersIds'] ?? []);

      // 4. Save to Firestore
      final messageRef = await _chatsCollection
          .doc(actualTargetRoomId)
          .collection('chat')
          .add(forwardedMessage.toMap());

      // 5. Update room's last message
      await _chatsCollection.doc(actualTargetRoomId).update({
        'lastMsg': _getMessagePreview(forwardedMessage),
        'lastSender': currentUserId,
        'lastChat': FieldValue.serverTimestamp(),
      });

      // 6. Emit event
      _eventBus.emit(MessageForwardedEvent(
        roomId: sourceRoomId,
        originalMessageId: message.id,
        forwardedMessageId: messageRef.id,
        targetRoomId: actualTargetRoomId,
        forwardedByUserId: currentUserId,
      ));

      if (kDebugMode) {
        print('✅ Message forwarded: ${message.id} -> ${messageRef.id}');
      }

      return Result.success(ForwardResult(
        messageId: messageRef.id,
        targetRoomId: actualTargetRoomId,
        newRoomCreated: newRoomCreated,
      ));
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Error forwarding message: $e');
      }
      return Result.failure(RepositoryError.fromException(e, st));
    }
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
    try {
      final successful = <ForwardResult>[];
      final failed = <String, String>{};

      // Sort by timestamp (oldest first for proper order)
      final sortedMessages = List<Message>.from(messages)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final message in sortedMessages) {
        final result = await forwardMessage(
          sourceRoomId: sourceRoomId,
          message: message,
          currentUserId: currentUserId,
          targetRoomId: targetRoomId,
          targetUserId: targetUserId,
          options: options,
        );

        result.fold(
          onSuccess: (forwardResult) => successful.add(forwardResult),
          onFailure: (error) => failed[message.id] = error.message,
        );
      }

      // Emit batch completion event
      _eventBus.emit(BatchForwardCompletedEvent(
        sourceRoomId: sourceRoomId,
        successCount: successful.length,
        failedCount: failed.length,
        targetRoomIds: successful.map((r) => r.targetRoomId).toSet().toList(),
      ));

      return Result.success(BatchForwardResult(
        successful: successful,
        failed: failed,
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<BatchForwardResult, RepositoryError>> forwardToMultiple({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    required List<String> targetRoomIds,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) async {
    try {
      final successful = <ForwardResult>[];
      final failed = <String, String>{};

      for (final targetRoomId in targetRoomIds) {
        final result = await forwardMessage(
          sourceRoomId: sourceRoomId,
          message: message,
          currentUserId: currentUserId,
          targetRoomId: targetRoomId,
          options: options,
        );

        result.fold(
          onSuccess: (forwardResult) => successful.add(forwardResult),
          onFailure: (error) => failed[targetRoomId] = error.message,
        );
      }

      // Emit batch completion event
      _eventBus.emit(BatchForwardCompletedEvent(
        sourceRoomId: sourceRoomId,
        successCount: successful.length,
        failedCount: failed.length,
        targetRoomIds: targetRoomIds,
      ));

      return Result.success(BatchForwardResult(
        successful: successful,
        failed: failed,
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Validation ===================

  @override
  Future<Result<bool, RepositoryError>> canForwardMessage({
    required String roomId,
    required String messageId,
    required String currentUserId,
  }) async {
    try {
      // Check pending message
      if (messageId.startsWith('pending_')) {
        return Result.success(false);
      }

      // Get message to check sender's privacy settings
      final messageDoc = await _chatsCollection
          .doc(roomId)
          .collection('chat')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        return Result.failure(RepositoryError.notFound('Message'));
      }

      final messageData = messageDoc.data();
      if (messageData == null) {
        return Result.failure(RepositoryError.notFound('Message data'));
      }

      // Check message type is forwardable
      final messageType = messageData['type'] as String? ?? 'unknown';
      if (kNonForwardableMessageTypes.contains(messageType)) {
        return Result.success(false);
      }

      // Check privacy settings using ChatPrivacyHelper
      if (_privacyHelper != null) {
        final senderId = messageData['senderId'] as String?;
        if (senderId != null && senderId != currentUserId) {
          final canForward = await _privacyHelper!.canForwardMessage(
            senderId: senderId,
            chatId: roomId,
          );
          return Result.success(canForward);
        }
      }

      return Result.success(true);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<bool, RepositoryError>> canForwardToTarget({
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
  }) async {
    try {
      if (targetRoomId != null) {
        // Check if user is member of target room
        final roomDoc = await _chatsCollection.doc(targetRoomId).get();
        if (!roomDoc.exists) {
          return Result.failure(RepositoryError.notFound('Chat room'));
        }

        final roomData = roomDoc.data() as Map<String, dynamic>?;
        final memberIds = List<String>.from(roomData?['membersIds'] ?? []);

        if (!memberIds.contains(currentUserId)) {
          return Result.success(false);
        }

        // Check if user is blocked in this room
        final blockedUsers = List<String>.from(roomData?['blockedUsers'] ?? []);
        if (blockedUsers.contains(currentUserId)) {
          return Result.success(false);
        }

        return Result.success(true);
      }

      if (targetUserId != null) {
        // Check if users have blocked each other
        final currentUserDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        final targetUserDoc =
            await _firestore.collection('users').doc(targetUserId).get();

        if (!targetUserDoc.exists) {
          return Result.failure(RepositoryError.notFound('User'));
        }

        final currentUserData = currentUserDoc.data();
        final targetUserData = targetUserDoc.data();

        final currentBlocked =
            List<String>.from(currentUserData?['blockedUsers'] ?? []);
        final targetBlocked =
            List<String>.from(targetUserData?['blockedUsers'] ?? []);

        // Bidirectional block check
        if (currentBlocked.contains(targetUserId) ||
            targetBlocked.contains(currentUserId)) {
          return Result.success(false);
        }

        return Result.success(true);
      }

      return Result.failure(
        RepositoryError.validation('Target room or user is required'),
      );
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Helper Operations ===================

  @override
  Future<Result<String, RepositoryError>> getOrCreatePrivateRoom({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Look for existing room between these two users
      final existingRoom = await _chatsCollection
          .where('membersIds', arrayContains: currentUserId)
          .where('isGroupChat', isEqualTo: false)
          .get();

      for (final doc in existingRoom.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['membersIds'] ?? []);

        if (memberIds.contains(targetUserId) && memberIds.length == 2) {
          // Found existing private chat
          return Result.success(doc.id);
        }
      }

      // Create new private chat room
      final newRoomRef = await _chatsCollection.add({
        'membersIds': [currentUserId, targetUserId],
        'isGroupChat': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastChat': FieldValue.serverTimestamp(),
        'lastMsg': '',
        'lastSender': '',
      });

      // Emit room created event
      _eventBus.emit(ChatRoomCreatedEvent(
        roomId: newRoomRef.id,
        isGroupChat: false,
        memberIds: [currentUserId, targetUserId],
      ));

      return Result.success(newRoomRef.id);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Message createForwardedMessage({
    required Message original,
    required String forwarderId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  }) {
    final now = DateTime.now();
    final originalSenderId = original.senderId;
    final forwardedFrom = options.includeAttribution ? originalSenderId : null;

    // Get the original message as map and modify it
    final map = original.toMap();
    final type = map['type'] as String? ?? 'text';

    // Create new message based on type
    switch (type) {
      case 'text':
        return TextMessage(
          id: '', // Will be assigned by Firestore
          roomId: '', // Will be set when forwarding
          senderId: forwarderId,
          timestamp: now,
          text: (original as TextMessage).text,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'photo':
        final photoMsg = original as PhotoMessage;
        return PhotoMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          imageUrl: photoMsg.imageUrl,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'video':
        final videoMsg = original as VideoMessage;
        return VideoMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          video: videoMsg.video,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'audio':
        final audioMsg = original as AudioMessage;
        return AudioMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          audioUrl: audioMsg.audioUrl,
          duration: audioMsg.duration,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'file':
        final fileMsg = original as FileMessage;
        return FileMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          file: fileMsg.file,
          fileName: fileMsg.fileName,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'location':
        final locMsg = original as LocationMessage;
        return LocationMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          latitude: locMsg.latitude,
          longitude: locMsg.longitude,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'contact':
        final contactMsg = original as ContactMessage;
        return ContactMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          name: contactMsg.name,
          phoneNumber: contactMsg.phoneNumber,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'poll':
        final pollMsg = original as PollMessage;
        return PollMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          question: pollMsg.question,
          options: pollMsg.options,
          votes: {}, // Reset votes for forwarded poll
          allowMultipleVotes: pollMsg.allowMultipleVotes,
          isAnonymous: pollMsg.isAnonymous,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      case 'event':
        final eventMsg = original as EventMessage;
        return EventMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          title: eventMsg.title,
          description: eventMsg.description,
          eventDate: eventMsg.eventDate,
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );

      default:
        // Fallback to text message with description
        return TextMessage(
          id: '',
          roomId: '',
          senderId: forwarderId,
          timestamp: now,
          text: '[Forwarded message]',
          isForwarded: true,
          forwardedFrom: forwardedFrom,
        );
    }
  }

  // =================== Private Helpers ===================

  /// Get message preview text for room's lastMsg field
  String _getMessagePreview(Message message) {
    final map = message.toMap();
    final type = map['type'] as String? ?? 'text';

    switch (type) {
      case 'text':
        final text = map['text'] as String? ?? '';
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
      case 'photo':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'audio':
        return '🎵 Voice message';
      case 'file':
        return '📎 File';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'poll':
        return '📊 Poll';
      case 'event':
        return '📅 Event';
      default:
        return 'Message';
    }
  }
}

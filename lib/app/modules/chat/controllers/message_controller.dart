import 'dart:async';
import 'package:crypted_app/app/core/exceptions/app_exceptions.dart';
import 'package:crypted_app/app/core/pagination/message_pagination_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

/// Message Controller - Handles all message CRUD operations
///
/// Responsibilities:
/// - Send messages (text, image, video, audio, file, location, contact, poll)
/// - Delete messages
/// - Pin/unpin messages
/// - Favorite messages
/// - Reply to messages
/// - Report messages
/// - Message search
///
/// Features:
/// - Comprehensive error handling
/// - Professional logging
/// - Proper validation
/// - User feedback
class MessageController extends GetxController {
  final ChatDataSources chatDataSource;
  final String roomId;
  final List<SocialMediaUser> members;

  MessageController({
    required this.chatDataSource,
    required this.roomId,
    required this.members,
  });

  // State
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;

  // Reply state
  final Rx<Message?> replyToMessage = Rx<Message?>(null);
  final RxString replyToText = ''.obs;

  // Search state
  final RxList<Message> searchResults = <Message>[].obs;
  final RxBool isSearching = false.obs;

  // Pending uploads - tracks uploads waiting for Firestore sync
  // Maps uploadId (temp ID) -> actualMessageId (Firestore ID)
  final Map<String, String> _pendingUploads = {};

  // Pending sent messages - tracks regular messages waiting for Firestore sync
  // Maps tempId -> actualMessageId (Firestore ID)
  final Map<String, String> _pendingSentMessages = {};

  // Pagination state
  final Rx<PaginationState> paginationState = PaginationState().obs;
  final RxBool isLoadingMore = false.obs;
  late final MessagePaginationService _paginationService;
  StreamSubscription<PaginatedMessages>? _messagesSubscription;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Getters
  SocialMediaUser? get currentUser => UserService.currentUser.value;
  bool get isReplying => replyToMessage.value != null;
  Message? get replyingTo => replyToMessage.value;
  bool get hasMoreMessages => paginationState.value.hasMoreMessages;
  bool get canLoadMore => hasMoreMessages && !isLoadingMore.value;

  /// Register a pending upload that's waiting for Firestore sync
  /// Called when upload completes but before Firestore stream delivers the message
  void registerPendingUpload(String uploadId, String actualMessageId) {
    _pendingUploads[uploadId] = actualMessageId;
    _logger.debug('Registered pending upload', context: 'MessageController', data: {
      'uploadId': uploadId,
      'actualMessageId': actualMessageId,
      'pendingCount': _pendingUploads.length,
    });
  }

  /// Clear a pending upload (called when Firestore delivers the message)
  void _clearPendingUpload(String uploadId) {
    _pendingUploads.remove(uploadId);
  }

  /// Register a pending sent message waiting for Firestore sync
  /// Called after message is added locally but before Firestore confirms
  void registerPendingSentMessage(String tempId, String actualMessageId) {
    _pendingSentMessages[tempId] = actualMessageId;
    _logger.debug('Registered pending sent message', context: 'MessageController', data: {
      'tempId': tempId,
      'actualMessageId': actualMessageId,
      'pendingCount': _pendingSentMessages.length,
    });
  }

  /// Clear a pending sent message (called when Firestore delivers the message)
  void _clearPendingSentMessage(String tempId) {
    _pendingSentMessages.remove(tempId);
  }

  /// Remove a local message by temp ID (for send failure rollback)
  void removeLocalMessage(String tempId) {
    final index = messages.indexWhere((m) => m.id == tempId);
    if (index != -1) {
      messages.removeAt(index);
      messages.refresh();
      _logger.debug('Removed local message', context: 'MessageController', data: {
        'tempId': tempId,
      });
    }
    // Also clear from pending if registered
    _pendingSentMessages.remove(tempId);
  }

  @override
  void onInit() {
    super.onInit();
    _paginationService = MessagePaginationService();
    _initializePaginatedMessages();
    _logger.info('MessageController initialized', context: 'MessageController', data: {
      'roomId': roomId,
      'memberCount': members.length,
    });
  }

  /// Initialize paginated message stream
  void _initializePaginatedMessages() {
    isLoadingMessages.value = true;

    _messagesSubscription = _paginationService
        .getInitialMessages(roomId: roomId, pageSize: 30)
        .listen(
      (paginatedResult) {
        // Get all local UploadingMessages
        final localUploadingMessages = messages
            .whereType<UploadingMessage>()
            .toList();

        // Get all local pending sent messages (messages with temp IDs starting with 'pending_')
        final localPendingSentMessages = messages
            .where((m) => m.id.startsWith('pending_') && m is! UploadingMessage)
            .toList();

        final hasPendingItems = localUploadingMessages.isNotEmpty ||
            _pendingUploads.isNotEmpty ||
            localPendingSentMessages.isNotEmpty ||
            _pendingSentMessages.isNotEmpty;

        if (!hasPendingItems) {
          // No local uploads or pending messages - use Firestore messages directly
          messages.value = paginatedResult.messages;
        } else {
          // SMART MERGE: Handle upload/sent -> Firestore transition
          //
          // _pendingUploads maps: uploadId (temp) -> actualMessageId (Firestore)
          // _pendingSentMessages maps: tempId -> actualMessageId (Firestore)
          // When Firestore delivers a message with ID matching actualMessageId,
          // we should remove the local message and use the Firestore message

          // Build reverse lookup: actualMessageId -> tempId (for both uploads and sent messages)
          final actualIdToTempId = <String, String>{};
          for (final entry in _pendingUploads.entries) {
            actualIdToTempId[entry.value] = entry.key;
          }
          for (final entry in _pendingSentMessages.entries) {
            actualIdToTempId[entry.value] = entry.key;
          }

          // Find which local messages should be replaced by Firestore messages
          final tempIdsToRemove = <String>{};
          for (final firestoreMsg in paginatedResult.messages) {
            final tempId = actualIdToTempId[firestoreMsg.id];
            if (tempId != null) {
              // This Firestore message replaces a local message
              tempIdsToRemove.add(tempId);
              _clearPendingUpload(tempId);
              _clearPendingSentMessage(tempId);
              _logger.debug('Firestore message arrived, replacing local', context: 'MessageController', data: {
                'tempId': tempId,
                'actualMessageId': firestoreMsg.id,
                'messageType': firestoreMsg.runtimeType.toString(),
              });
            }
          }

          // Keep UploadingMessages that are STILL uploading (not yet synced)
          final uploadsToKeep = localUploadingMessages
              .where((upload) => !tempIdsToRemove.contains(upload.id))
              .toList();

          // Keep pending sent messages that haven't synced yet
          final pendingSentToKeep = localPendingSentMessages
              .where((msg) => !tempIdsToRemove.contains(msg.id))
              .toList();

          // Get IDs of local messages to keep (for filtering Firestore duplicates)
          final localIdsToKeep = <String>{
            ...uploadsToKeep.map((m) => m.id),
            ...pendingSentToKeep.map((m) => m.id),
          };

          // Build merged list: active uploads + pending sent + Firestore messages
          // Filter out Firestore messages that have the same ID as active local messages
          final firestoreMessages = paginatedResult.messages
              .where((m) => !localIdsToKeep.contains(m.id))
              .toList();

          final mergedMessages = <Message>[
            ...uploadsToKeep,
            ...pendingSentToKeep,
            ...firestoreMessages,
          ];

          // Sort by timestamp descending (newest first)
          mergedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          messages.value = mergedMessages;
          _logger.debug('Messages merged with smart handling', context: 'MessageController', data: {
            'firestoreCount': paginatedResult.messages.length,
            'uploadsKept': uploadsToKeep.length,
            'pendingSentKept': pendingSentToKeep.length,
            'localReplaced': tempIdsToRemove.length,
            'totalCount': mergedMessages.length,
          });
        }

        paginationState.value = paginatedResult.state;
        isLoadingMessages.value = false;
        _logger.debug('Initial messages loaded', context: 'MessageController', data: {
          'count': paginatedResult.messages.length,
          'hasMore': paginatedResult.state.hasMoreMessages,
        });
      },
      onError: (error) {
        _logger.error('Failed to load messages', context: 'MessageController', data: {
          'error': error.toString(),
        });
        isLoadingMessages.value = false;
        _errorHandler.handleError(
          error,
          context: 'MessageController._initializePaginatedMessages',
          showToUser: true,
        );
      },
    );
  }

  /// Load more older messages (pagination)
  Future<void> loadMoreMessages() async {
    if (!canLoadMore) {
      return;
    }

    isLoadingMore.value = true;
    _logger.debug('Loading more messages', context: 'MessageController', data: {
      'currentCount': messages.length,
    });

    try {
      final result = await _paginationService.loadMoreMessages(
        roomId: roomId,
        currentState: paginationState.value,
      );

      if (result.messages.isNotEmpty) {
        // Append older messages to the end
        messages.addAll(result.messages);
        paginationState.value = result.state;
        _logger.debug('More messages loaded', context: 'MessageController', data: {
          'loaded': result.messages.length,
          'totalCount': messages.length,
          'hasMore': result.state.hasMoreMessages,
        });
      }
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.loadMoreMessages',
        showToUser: false,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Jump to a specific message by loading messages around its timestamp
  Future<void> jumpToMessage(Message targetMessage) async {
    isLoadingMessages.value = true;
    _logger.debug('Jumping to message', context: 'MessageController', data: {
      'messageId': targetMessage.id,
    });

    try {
      final result = await _paginationService.loadMessagesAround(
        roomId: roomId,
        timestamp: targetMessage.timestamp,
        pageSize: 50,
      );

      messages.value = result.messages;
      paginationState.value = result.state;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.jumpToMessage',
        showToUser: true,
      );
    } finally {
      isLoadingMessages.value = false;
    }
  }

  // ========== LOCAL MESSAGE HANDLING ==========

  /// Add a message to the local UI optimistically (for offline support)
  /// This message will be synced to Firestore when connectivity is restored
  void addLocalMessage(Message message) {
    _logger.debug('Adding local message', context: 'MessageController', data: {
      'messageId': message.id,
      'type': message.runtimeType.toString(),
    });

    // Add to the beginning of the list (newest first) or end depending on sort order
    // Messages are typically sorted newest-first, so insert at index 0
    messages.insert(0, message);

    // Refresh the observable list
    messages.refresh();
  }

  // ========== MESSAGE SENDING ==========

  /// Send text message
  Future<bool> sendTextMessage(String text) async {
    if (text.trim().isEmpty) {
      _errorHandler.handleValidationError('text', 'Message cannot be empty');
      return false;
    }

    if (currentUser?.uid == null) {
      _errorHandler.handleError(
        AuthException('user-not-found', 'User not logged in'),
        context: 'MessageController.sendTextMessage',
        showToUser: true,
      );
      return false;
    }

    _logger.debug('Sending text message', context: 'MessageController', data: {
      'text': text.substring(0, text.length > 50 ? 50 : text.length),
      'length': text.length,
    });

    try {
      isSendingMessage.value = true;

      // FIX: Build reply context if replying to a message
      ReplyToMessage? replyContext;
      if (isReplying && replyingTo != null) {
        replyContext = ReplyToMessage(
          id: replyingTo!.id,
          senderId: replyingTo!.senderId,
          previewText: replyToText.value,
        );
        _logger.debug('Reply context attached', context: 'MessageController', data: {
          'replyToMessageId': replyingTo!.id,
          'previewText': replyToText.value,
        });
      }

      final textMessage = TextMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        text: text.trim(),
        replyTo: replyContext,
      );

      await _sendMessage(textMessage);

      _logger.info('Text message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendTextMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send image message
  Future<bool> sendImageMessage({
    required String imageUrl,
    String? caption,
    int? width,
    int? height,
  }) async {
    if (imageUrl.isEmpty) {
      _errorHandler.handleValidationError('imageUrl', 'Image URL cannot be empty');
      return false;
    }

    _logger.debug('Sending image message', context: 'MessageController', data: {
      'url': imageUrl,
      'hasCaption': caption != null,
    });

    try {
      isSendingMessage.value = true;

      final imageMessage = PhotoMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _sendMessage(imageMessage);

      _logger.info('Image message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendImageMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send video message
  Future<bool> sendVideoMessage({
    required String videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? duration,
  }) async {
    if (videoUrl.isEmpty) {
      _errorHandler.handleValidationError('videoUrl', 'Video URL cannot be empty');
      return false;
    }

    _logger.debug('Sending video message', context: 'MessageController', data: {
      'url': videoUrl,
      'duration': duration,
    });

    try {
      isSendingMessage.value = true;

      final videoMessage = VideoMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        video: videoUrl,
       
      );

      await _sendMessage(videoMessage);

      _logger.info('Video message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendVideoMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send audio message
  Future<bool> sendAudioMessage({
    required String audioUrl,
    required int duration,
  }) async {
    if (audioUrl.isEmpty) {
      _errorHandler.handleValidationError('audioUrl', 'Audio URL cannot be empty');
      return false;
    }

    if (duration <= 0) {
      _errorHandler.handleValidationError('duration', 'Invalid audio duration');
      return false;
    }

    _logger.debug('Sending audio message', context: 'MessageController', data: {
      'url': audioUrl,
      'duration': duration,
    });

    try {
      isSendingMessage.value = true;

      final audioMessage = AudioMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        audioUrl: audioUrl,
        duration: duration.toString(),
      );

      await _sendMessage(audioMessage);

      _logger.info('Audio message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendAudioMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send file message
  Future<bool> sendFileMessage({
    required String fileUrl,
    required String fileName,
  }) async {
    if (fileUrl.isEmpty) {
      _errorHandler.handleValidationError('fileUrl', 'File URL cannot be empty');
      return false;
    }

    _logger.debug('Sending file message', context: 'MessageController', data: {
      'fileName': fileName,
    });

    try {
      isSendingMessage.value = true;

      final fileMessage = FileMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        file: fileUrl,
        fileName: fileName,
      );

      await _sendMessage(fileMessage);

      _logger.info('File message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendFileMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send location message
  Future<bool> sendLocationMessage({
    required double latitude,
    required double longitude,
  }) async {
    _logger.debug('Sending location message', context: 'MessageController', data: {
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      isSendingMessage.value = true;

      final locationMessage = LocationMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      );

      await _sendMessage(locationMessage);

      _logger.info('Location message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendLocationMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send contact message
  Future<bool> sendContactMessage({
    required String contactName,
    required String contactPhone,
  }) async {
    if (contactName.isEmpty || contactPhone.isEmpty) {
      _errorHandler.handleValidationError('contact', 'Contact information incomplete');
      return false;
    }

    _logger.debug('Sending contact message', context: 'MessageController', data: {
      'contactName': contactName,
    });

    try {
      isSendingMessage.value = true;

      final contactMessage = ContactMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        name: contactName,
        phoneNumber: contactPhone,
      );

      await _sendMessage(contactMessage);

      _logger.info('Contact message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendContactMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Send poll message
  Future<bool> sendPollMessage({
    required String question,
    required List<String> options,
  }) async {
    if (question.trim().isEmpty) {
      _errorHandler.handleValidationError('question', 'Poll question cannot be empty');
      return false;
    }

    if (options.length < 2) {
      _errorHandler.handleValidationError('options', 'Poll must have at least 2 options');
      return false;
    }

    _logger.debug('Sending poll message', context: 'MessageController', data: {
      'question': question,
      'optionsCount': options.length,
    });

    try {
      isSendingMessage.value = true;

      final pollMessage = PollMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser!.uid!,
        timestamp: DateTime.now(),
        question: question,
        options: options,
        votes: {}, // Empty votes initially
      );

      await _sendMessage(pollMessage);

      _logger.info('Poll message sent successfully', context: 'MessageController');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.sendPollMessage',
        showToUser: true,
      );
      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Internal method to send message via data source
  /// FIX: Added optimistic update - message appears immediately before Firestore confirms
  Future<void> _sendMessage(Message message) async {
    // Verify sender is current user
    if (message.senderId != currentUser?.uid) {
      throw AuthException(
        'invalid-sender',
        'Message sender does not match current user',
      );
    }

    // Generate temp ID for optimistic update
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final localMessage = message.copyWith(id: tempId) as Message;

    // OPTIMISTIC UPDATE: Add message to local UI immediately
    addLocalMessage(localMessage);

    try {
      // Send to Firestore and get the actual message ID
      final actualMessageId = await chatDataSource.sendMessage(
        privateMessage: message,
        roomId: roomId,
        members: members,
      );

      // Register mapping for deduplication when Firestore stream delivers
      registerPendingSentMessage(tempId, actualMessageId);

      _logger.debug('Message sent with optimistic update', context: 'MessageController', data: {
        'tempId': tempId,
        'actualId': actualMessageId,
      });
    } catch (e) {
      // ROLLBACK: Remove the optimistic message on failure
      removeLocalMessage(tempId);
      _logger.logError('Message send failed, rolled back optimistic update', error: e);
      rethrow;
    }

    // Clear reply state after sending
    clearReply();
  }

  // ========== MESSAGE MANAGEMENT ==========

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    _logger.debug('Deleting message', context: 'MessageController', data: {
      'messageId': messageId,
    });

    try {
      await chatDataSource.deletePrivateMessage(messageId, roomId);

      _logger.info('Message deleted successfully', context: 'MessageController');
      _errorHandler.showSuccess('رسالة محذوفة / Message deleted');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.deleteMessage',
        showToUser: true,
      );
      return false;
    }
  }

  /// Pin message
  Future<bool> pinMessage(String messageId) async {
    _logger.debug('Pinning message', context: 'MessageController', data: {
      'messageId': messageId,
    });

    try {
      await chatDataSource.togglePinMessage(roomId, messageId);
      _logger.info('Message pinned successfully', context: 'MessageController');
      _errorHandler.showSuccess('رسالة مثبتة / Message pinned');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.pinMessage',
        showToUser: true,
      );
      return false;
    }
  }

  /// Favorite message
  Future<bool> favoriteMessage(String messageId) async {
    _logger.debug('Favoriting message', context: 'MessageController', data: {
      'messageId': messageId,
    });

    try {
      await chatDataSource.toggleFavoriteMessage(roomId, messageId);
      _logger.info('Message favorited successfully', context: 'MessageController');
      _errorHandler.showSuccess('رسالة مفضلة / Message favorited');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.favoriteMessage',
        showToUser: true,
      );
      return false;
    }
  }

  /// Report message
  Future<bool> reportMessage(String messageId, String reason) async {
    if (reason.trim().isEmpty) {
      _errorHandler.handleValidationError('reason', 'Please provide a reason for reporting');
      return false;
    }

    _logger.warning('Reporting message', context: 'MessageController', data: {
      'messageId': messageId,
      'reason': reason,
    });

    try {
      // Use existing reportContent method
      await chatDataSource.reportContent(
        reporterId: currentUser!.uid!,
        contentType: 'message',
        contentId: messageId,
        reason: reason,
      );

      _logger.info('Message reported successfully', context: 'MessageController');
      _errorHandler.showSuccess('تم الإبلاغ عن الرسالة / Message reported');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.reportMessage',
        showToUser: true,
      );
      return false;
    }
  }

  // ========== REPLY FUNCTIONALITY ==========

  /// Set message to reply to
  void setReplyTo(Message message) {
    replyToMessage.value = message;
    replyToText.value = _getMessagePreview(message);

    _logger.debug('Reply set', context: 'MessageController', data: {
      'messageId': message.id,
      'messageType': message.runtimeType.toString(),
    });
  }

  /// Clear reply
  void clearReply() {
    replyToMessage.value = null;
    replyToText.value = '';
  }

  /// Get message preview for reply
  String _getMessagePreview(Message message) {
    if (message is TextMessage) {
      return message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text;
    } else if (message is PhotoMessage) {
      return '📷 Photo';
    } else if (message is VideoMessage) {
      return '🎥 Video';
    } else if (message is AudioMessage) {
      return '🎙️ Voice message';
    } else if (message is FileMessage) {
      return '📄 ${message.fileName}';
    } else if (message is LocationMessage) {
      return '📍 Location';
    } else if (message is ContactMessage) {
      return '👤 ${message.name}';
    } else if (message is PollMessage) {
      return '📊 ${message.question}';
    }
    return 'Message';
  }

  // ========== SEARCH ==========

  /// Search messages in local message list
  Future<void> searchMessages(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    _logger.debug('Searching messages', context: 'MessageController', data: {
      'query': query,
    });

    try {
      isSearching.value = true;

      // Search locally in messages list
      final results = messages.where((message) {
        if (message is TextMessage) {
          return message.text.toLowerCase().contains(query.toLowerCase());
        }
        return false;
      }).toList();

      searchResults.value = results;

      _logger.info('Search completed', context: 'MessageController', data: {
        'resultsCount': results.length,
      });
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageController.searchMessages',
        showToUser: true,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Clear search results
  void clearSearch() {
    searchResults.clear();
    isSearching.value = false;
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _logger.info('MessageController disposed', context: 'MessageController');
    super.onClose();
  }
}

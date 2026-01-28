import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
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
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';

/// ARCH-001: Extracted Message Action Controller
/// Handles all message action operations
///
/// Responsibilities:
/// - Delete/restore messages
/// - Pin/unpin messages
/// - Favorite messages
/// - Copy message content
/// - Forward messages
/// - Report messages
/// - Edit messages
class MessageActionController extends GetxController {
  final ChatDataSources _chatDataSource;
  final String _roomId;
  final List<SocialMediaUser> _members;

  MessageActionController({
    required ChatDataSources chatDataSource,
    required String roomId,
    required List<SocialMediaUser> members,
  })  : _chatDataSource = chatDataSource,
        _roomId = roomId,
        _members = members;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Edit time limit in minutes
  static const int _editTimeLimitMinutes = 15;

  SocialMediaUser? get _currentUser => UserService.currentUser.value;
  String? get _currentUserId => _currentUser?.uid;

  /// Delete a message (soft delete)
  Future<bool> deleteMessage(Message message) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    // Only allow deleting own messages
    if (message.senderId != _currentUserId) {
      _errorHandler.showError('You can only delete your own messages');
      return false;
    }

    _logger.debug('Deleting message', context: 'MessageActionController', data: {
      'messageId': message.id,
    });

    try {
      BotToast.showLoading();

      await _chatDataSource.updateMessage(
        roomId: _roomId,
        messageId: message.id,
        updates: {'isDeleted': true, 'deletedAt': DateTime.now().toIso8601String()},
      );

      _logger.info('Message deleted successfully', context: 'MessageActionController');
      BotToast.showText(text: 'Message deleted');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.deleteMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Restore a deleted message
  Future<bool> restoreMessage(Message message) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    // Only allow restoring own messages
    if (message.senderId != _currentUserId) {
      _errorHandler.showError('You can only restore your own messages');
      return false;
    }

    _logger.debug('Restoring message', context: 'MessageActionController', data: {
      'messageId': message.id,
    });

    try {
      BotToast.showLoading();

      await _chatDataSource.updateMessage(
        roomId: _roomId,
        messageId: message.id,
        updates: {'isDeleted': false},
      );

      _logger.info('Message restored successfully', context: 'MessageActionController');
      BotToast.showText(text: 'Message restored');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.restoreMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Toggle pin status of a message
  Future<bool> togglePinMessage(Message message) async {
    _logger.debug('Toggling pin message', context: 'MessageActionController', data: {
      'messageId': message.id,
      'isPinned': message.isPinned,
    });

    try {
      BotToast.showLoading();

      // If pinning, first unpin any existing pinned messages
      if (!message.isPinned) {
        // Query for currently pinned messages and unpin them
        final pinnedMessages = await _chatDataSource.getPinnedMessages(_roomId);
        for (final pinnedMsg in pinnedMessages) {
          if (pinnedMsg.id != message.id) {
            await _chatDataSource.updateMessage(
              roomId: _roomId,
              messageId: pinnedMsg.id,
              updates: {'isPinned': false},
            );
          }
        }
      }

      await _chatDataSource.updateMessage(
        roomId: _roomId,
        messageId: message.id,
        updates: {'isPinned': !message.isPinned},
      );

      _logger.info('Message pin toggled', context: 'MessageActionController');
      BotToast.showText(text: message.isPinned ? 'Message unpinned' : 'Message pinned');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.togglePinMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Toggle favorite status of a message
  Future<bool> toggleFavoriteMessage(Message message) async {
    _logger.debug('Toggling favorite message', context: 'MessageActionController', data: {
      'messageId': message.id,
      'isFavorite': message.isFavorite,
    });

    try {
      BotToast.showLoading();

      await _chatDataSource.updateMessage(
        roomId: _roomId,
        messageId: message.id,
        updates: {'isFavorite': !message.isFavorite},
      );

      _logger.info('Message favorite toggled', context: 'MessageActionController');
      BotToast.showText(text: message.isFavorite ? 'Removed from favorites' : 'Added to favorites');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.toggleFavoriteMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Copy message content to clipboard
  void copyMessage(Message message) {
    try {
      final textToCopy = _getMessageText(message);

      Clipboard.setData(ClipboardData(text: textToCopy));

      _logger.debug('Message copied', context: 'MessageActionController');
      BotToast.showText(text: 'Message copied to clipboard');
    } catch (e) {
      _errorHandler.showError('Failed to copy message');
    }
  }

  /// Forward a message to another chat
  Future<bool> forwardMessage(Message message, String targetUserId) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    _logger.debug('Forwarding message', context: 'MessageActionController', data: {
      'messageId': message.id,
      'targetUserId': targetUserId,
    });

    try {
      BotToast.showLoading();

      // Get target user
      final targetUser = await _getUserById(targetUserId);
      if (targetUser == null) {
        throw Exception('Target user not found');
      }

      // Get or create chat room with target
      final targetRoomId = await _getOrCreateChatRoomWithUser(targetUser);

      // Create forwarded message
      final forwardedMessage = _createForwardedMessage(message, targetRoomId);

      // Send to target room
      await _chatDataSource.sendMessage(
        privateMessage: forwardedMessage,
        roomId: targetRoomId,
        members: [_currentUser!, targetUser],
      );

      _logger.info('Message forwarded successfully', context: 'MessageActionController');
      BotToast.showText(text: 'Message forwarded to ${targetUser.fullName}');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.forwardMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Report a message
  Future<bool> reportMessage(Message message, {String? reason}) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    _logger.warning('Reporting message', context: 'MessageActionController', data: {
      'messageId': message.id,
      'reason': reason,
    });

    try {
      BotToast.showLoading();

      await FirebaseFirestore.instance.collection('reports').add({
        'messageId': message.id,
        'roomId': _roomId,
        'reporterId': _currentUserId,
        'reportedUserId': message.senderId,
        'messageType': message.runtimeType.toString(),
        'messageContent': _getMessageText(message),
        'reason': reason ?? 'Community guidelines violation',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'platform': 'mobile',
      });

      // Mark message as reported
      await _chatDataSource.updateMessage(
        roomId: _roomId,
        messageId: message.id,
        updates: {
          'isReported': true,
          'reportedAt': DateTime.now().toIso8601String(),
          'reportedBy': _currentUserId,
        },
      );

      _logger.info('Message reported successfully', context: 'MessageActionController');
      BotToast.showText(text: 'Message reported. Thank you for helping keep our community safe.');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.reportMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Edit a text message
  Future<bool> editMessage(TextMessage message, String newText) async {
    if (_currentUserId == null) {
      _errorHandler.showError('User not logged in');
      return false;
    }

    if (message.senderId != _currentUserId) {
      _errorHandler.showError('You can only edit your own messages');
      return false;
    }

    // Check edit time limit
    final difference = DateTime.now().difference(message.timestamp);
    if (difference.inMinutes > _editTimeLimitMinutes) {
      _errorHandler.showError('Messages can only be edited within $_editTimeLimitMinutes minutes');
      return false;
    }

    if (newText.trim().isEmpty) {
      _errorHandler.showError('Message cannot be empty');
      return false;
    }

    _logger.debug('Editing message', context: 'MessageActionController', data: {
      'messageId': message.id,
    });

    try {
      BotToast.showLoading();

      await _chatDataSource.editMessage(
        roomId: _roomId,
        messageId: message.id,
        newText: newText.trim(),
        senderId: _currentUserId!,
      );

      _logger.info('Message edited successfully', context: 'MessageActionController');
      BotToast.showText(text: 'Message edited');
      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'MessageActionController.editMessage',
        showToUser: true,
      );
      return false;
    } finally {
      BotToast.closeAllLoading();
    }
  }

  /// Check if a message can be edited
  bool canEditMessage(Message message) {
    if (message is! TextMessage) return false;
    if (message.senderId != _currentUserId) return false;
    if (message.isDeleted) return false;

    final difference = DateTime.now().difference(message.timestamp);
    return difference.inMinutes <= _editTimeLimitMinutes;
  }

  /// Check if a message can be deleted
  bool canDeleteMessage(Message message) {
    return message.senderId == _currentUserId && !message.isDeleted;
  }

  /// Check if a message can be restored
  bool canRestoreMessage(Message message) {
    return message.senderId == _currentUserId && message.isDeleted;
  }

  /// Check if current user can interact with the message
  bool canInteractWithMessage(Message message) {
    if (!message.isDeleted) return true;
    return message.senderId == _currentUserId;
  }

  /// Get text representation of a message
  String _getMessageText(Message message) {
    switch (message) {
      case TextMessage():
        return message.text;
      case PhotoMessage():
        return '[Photo]';
      case VideoMessage():
        return '[Video]';
      case AudioMessage():
        return '[Audio ${message.duration}]';
      case FileMessage():
        return '[File: ${message.fileName}]';
      case LocationMessage():
        return '[Location ${message.latitude}, ${message.longitude}]';
      case ContactMessage():
        return '[Contact ${message.name}]';
      case PollMessage():
        return '[Poll ${message.question}]';
      case EventMessage():
        return '[Event ${message.title}]';
      case CallMessage():
        return '[Call]';
      default:
        return '[Message]';
    }
  }

  /// Create a forwarded copy of a message
  Message _createForwardedMessage(Message original, String targetRoomId) {
    if (original is TextMessage) {
      return TextMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        text: original.text,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is PhotoMessage) {
      return PhotoMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        imageUrl: original.imageUrl,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is VideoMessage) {
      return VideoMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        video: original.video,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is AudioMessage) {
      return AudioMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        audioUrl: original.audioUrl,
        duration: original.duration,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is FileMessage) {
      return FileMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        file: original.file,
        fileName: original.fileName,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is LocationMessage) {
      return LocationMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        latitude: original.latitude,
        longitude: original.longitude,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    } else if (original is ContactMessage) {
      return ContactMessage(
        id: '',
        roomId: targetRoomId,
        senderId: _currentUserId ?? '',
        timestamp: DateTime.now(),
        name: original.name,
        phoneNumber: original.phoneNumber,
        isForwarded: true,
        forwardedFrom: original.senderId,
      );
    }

    // Default: forward as text with description
    return TextMessage(
      id: '',
      roomId: targetRoomId,
      senderId: _currentUserId ?? '',
      timestamp: DateTime.now(),
      text: '[Forwarded: ${_getMessageText(original)}]',
      isForwarded: true,
      forwardedFrom: original.senderId,
    );
  }

  /// Get user by ID
  Future<SocialMediaUser?> _getUserById(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return SocialMediaUser.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      _logger.logError('Error getting user by ID', error: e, context: 'MessageActionController');
      return null;
    }
  }

  /// Get or create chat room with user
  Future<String> _getOrCreateChatRoomWithUser(SocialMediaUser targetUser) async {
    final memberIds = [_currentUserId!, targetUser.uid!]..sort();

    // Check for existing room
    final existingRooms = await FirebaseFirestore.instance
        .collection('chats')
        .where('membersIds', isEqualTo: memberIds)
        .where('isGroupChat', isEqualTo: false)
        .limit(1)
        .get();

    if (existingRooms.docs.isNotEmpty) {
      return existingRooms.docs.first.id;
    }

    // Create new room
    final newRoomRef = FirebaseFirestore.instance.collection('chats').doc();
    await newRoomRef.set({
      'membersIds': memberIds,
      'members': [_currentUser!.toMap(), targetUser.toMap()],
      'isGroupChat': false,
      'lastChat': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newRoomRef.id;
  }
}

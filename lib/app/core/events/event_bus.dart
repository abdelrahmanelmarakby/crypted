// ARCH-014 FIX: Event Bus Implementation
// Decoupled event-driven communication between components

import 'dart:async';

/// Base class for all events
abstract class AppEvent {
  final DateTime timestamp;

  AppEvent() : timestamp = DateTime.now();
}

/// Event bus for decoupled communication
/// Singleton pattern for global access
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<AppEvent>.broadcast();
  final Map<Type, List<StreamSubscription>> _subscriptions = {};

  /// Get the event stream
  Stream<AppEvent> get stream => _controller.stream;

  /// Emit an event
  void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Subscribe to events of a specific type
  StreamSubscription<T> on<T extends AppEvent>(void Function(T event) handler) {
    final subscription = stream
        .where((event) => event is T)
        .cast<T>()
        .listen(handler);

    _subscriptions[T] ??= [];
    _subscriptions[T]!.add(subscription);

    return subscription;
  }

  /// Subscribe to all events
  StreamSubscription<AppEvent> onAll(void Function(AppEvent event) handler) {
    return stream.listen(handler);
  }

  /// Unsubscribe all listeners for a specific event type
  void offAll<T extends AppEvent>() {
    final subs = _subscriptions[T];
    if (subs != null) {
      for (final sub in subs) {
        sub.cancel();
      }
      _subscriptions.remove(T);
    }
  }

  /// Dispose the event bus (call on app termination)
  void dispose() {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _subscriptions.clear();
    _controller.close();
  }
}

// =================== CHAT EVENTS ===================

/// Base class for chat-related events
abstract class ChatEvent extends AppEvent {
  final String roomId;

  ChatEvent({required this.roomId});
}

/// New message received
class MessageReceivedEvent extends ChatEvent {
  final String messageId;
  final String senderId;
  final String? preview;

  MessageReceivedEvent({
    required super.roomId,
    required this.messageId,
    required this.senderId,
    this.preview,
  });
}

/// Message sent successfully
class MessageSentEvent extends ChatEvent {
  final String messageId;
  final String? localId;

  MessageSentEvent({
    required super.roomId,
    required this.messageId,
    this.localId,
  });
}

/// Message send failed
class MessageSendFailedEvent extends ChatEvent {
  final String localId;
  final String error;

  MessageSendFailedEvent({
    required super.roomId,
    required this.localId,
    required this.error,
  });
}

/// Message deleted
class MessageDeletedEvent extends ChatEvent {
  final String messageId;
  final bool forEveryone;

  MessageDeletedEvent({
    required super.roomId,
    required this.messageId,
    this.forEveryone = false,
  });
}

/// Message updated (edited, pinned, etc.)
class MessageUpdatedEvent extends ChatEvent {
  final String messageId;
  final Map<String, dynamic> updates;

  MessageUpdatedEvent({
    required super.roomId,
    required this.messageId,
    required this.updates,
  });
}

/// Typing indicator event
class TypingEvent extends ChatEvent {
  final String userId;
  final bool isTyping;

  TypingEvent({
    required super.roomId,
    required this.userId,
    required this.isTyping,
  });
}

/// Message read event
class MessageReadEvent extends ChatEvent {
  final String messageId;
  final String readByUserId;

  MessageReadEvent({
    required super.roomId,
    required this.messageId,
    required this.readByUserId,
  });
}

/// Reaction added/removed
class ReactionEvent extends ChatEvent {
  final String messageId;
  final String userId;
  final String emoji;
  final bool added;

  ReactionEvent({
    required super.roomId,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.added,
  });
}

// =================== CHAT ROOM EVENTS ===================

/// Chat room created
class ChatRoomCreatedEvent extends ChatEvent {
  final bool isGroupChat;
  final List<String> memberIds;

  ChatRoomCreatedEvent({
    required super.roomId,
    required this.isGroupChat,
    required this.memberIds,
  });
}

/// Chat room updated
class ChatRoomUpdatedEvent extends ChatEvent {
  final Map<String, dynamic> updates;

  ChatRoomUpdatedEvent({
    required super.roomId,
    required this.updates,
  });
}

/// Member added to chat
class MemberAddedEvent extends ChatEvent {
  final String memberId;
  final String? addedBy;

  MemberAddedEvent({
    required super.roomId,
    required this.memberId,
    this.addedBy,
  });
}

/// Member removed from chat
class MemberRemovedEvent extends ChatEvent {
  final String memberId;
  final String? removedBy;
  final bool isLeave;

  MemberRemovedEvent({
    required super.roomId,
    required this.memberId,
    this.removedBy,
    this.isLeave = false,
  });
}

/// Chat archived/unarchived
class ChatArchivedEvent extends ChatEvent {
  final bool isArchived;

  ChatArchivedEvent({
    required super.roomId,
    required this.isArchived,
  });
}

/// Chat muted/unmuted
class ChatMutedEvent extends ChatEvent {
  final bool isMuted;
  final Duration? muteDuration;

  ChatMutedEvent({
    required super.roomId,
    required this.isMuted,
    this.muteDuration,
  });
}

// =================== USER EVENTS ===================

/// Base class for user-related events
abstract class UserEvent extends AppEvent {
  final String userId;

  UserEvent({required this.userId});
}

/// User came online
class UserOnlineEvent extends UserEvent {
  UserOnlineEvent({required super.userId});
}

/// User went offline
class UserOfflineEvent extends UserEvent {
  final DateTime lastSeen;

  UserOfflineEvent({
    required super.userId,
    required this.lastSeen,
  });
}

/// User blocked/unblocked
class UserBlockedEvent extends UserEvent {
  final bool isBlocked;

  UserBlockedEvent({
    required super.userId,
    required this.isBlocked,
  });
}

// =================== UPLOAD EVENTS ===================

/// Upload progress event
class UploadProgressEvent extends AppEvent {
  final String uploadId;
  final String roomId;
  final double progress;

  UploadProgressEvent({
    required this.uploadId,
    required this.roomId,
    required this.progress,
  });
}

/// Upload completed
class UploadCompletedEvent extends AppEvent {
  final String uploadId;
  final String roomId;
  final String downloadUrl;

  UploadCompletedEvent({
    required this.uploadId,
    required this.roomId,
    required this.downloadUrl,
  });
}

/// Upload failed
class UploadFailedEvent extends AppEvent {
  final String uploadId;
  final String roomId;
  final String error;

  UploadFailedEvent({
    required this.uploadId,
    required this.roomId,
    required this.error,
  });
}

// =================== CALL EVENTS ===================

/// Incoming call event
class IncomingCallEvent extends AppEvent {
  final String callId;
  final String callerId;
  final String callerName;
  final bool isVideoCall;

  IncomingCallEvent({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.isVideoCall,
  });
}

/// Call ended event
class CallEndedEvent extends AppEvent {
  final String callId;
  final Duration duration;
  final String endReason;

  CallEndedEvent({
    required this.callId,
    required this.duration,
    required this.endReason,
  });
}

// =================== NETWORK EVENTS ===================

/// Network connectivity changed
class ConnectivityChangedEvent extends AppEvent {
  final bool isOnline;

  ConnectivityChangedEvent({required this.isOnline});
}

/// Sync status changed
class SyncStatusEvent extends AppEvent {
  final bool isSyncing;
  final int pendingCount;

  SyncStatusEvent({
    required this.isSyncing,
    required this.pendingCount,
  });
}

/// Room-specific sync status (for SyncService)
class RoomSyncStatusEvent extends AppEvent {
  final String roomId;
  final bool isSyncing;
  final double? progress;
  final String? message;

  RoomSyncStatusEvent({
    required this.roomId,
    required this.isSyncing,
    this.progress,
    this.message,
  });
}

// =================== FORWARD EVENTS ===================

/// Message forwarded successfully
class MessageForwardedEvent extends ChatEvent {
  /// Original message ID
  final String originalMessageId;

  /// New forwarded message ID
  final String forwardedMessageId;

  /// Target room where message was forwarded to
  final String targetRoomId;

  /// User who forwarded the message
  final String forwardedByUserId;

  MessageForwardedEvent({
    required super.roomId,
    required this.originalMessageId,
    required this.forwardedMessageId,
    required this.targetRoomId,
    required this.forwardedByUserId,
  });
}

/// Batch forward completed
class BatchForwardCompletedEvent extends AppEvent {
  /// Source room ID
  final String sourceRoomId;

  /// Number of successful forwards
  final int successCount;

  /// Number of failed forwards
  final int failedCount;

  /// Target room IDs
  final List<String> targetRoomIds;

  BatchForwardCompletedEvent({
    required this.sourceRoomId,
    required this.successCount,
    required this.failedCount,
    required this.targetRoomIds,
  });
}

// =================== GROUP EVENTS ===================

/// Group member added
class GroupMemberAddedEvent extends ChatEvent {
  final String memberId;
  final String memberName;
  final String addedByUserId;
  final String? systemMessageId;

  GroupMemberAddedEvent({
    required super.roomId,
    required this.memberId,
    required this.memberName,
    required this.addedByUserId,
    this.systemMessageId,
  });
}

/// Group member removed
class GroupMemberRemovedEvent extends ChatEvent {
  final String memberId;
  final String memberName;
  final String removedByUserId;
  final String? systemMessageId;

  GroupMemberRemovedEvent({
    required super.roomId,
    required this.memberId,
    required this.memberName,
    required this.removedByUserId,
    this.systemMessageId,
  });
}

/// Member left group
class GroupMemberLeftEvent extends ChatEvent {
  final String memberId;
  final String memberName;
  final String? systemMessageId;

  GroupMemberLeftEvent({
    required super.roomId,
    required this.memberId,
    required this.memberName,
    this.systemMessageId,
  });
}

/// Admin role changed
class GroupAdminChangedEvent extends ChatEvent {
  final String memberId;
  final String memberName;
  final bool isNowAdmin;
  final String changedByUserId;
  final String? systemMessageId;

  GroupAdminChangedEvent({
    required super.roomId,
    required this.memberId,
    required this.memberName,
    required this.isNowAdmin,
    required this.changedByUserId,
    this.systemMessageId,
  });
}

/// Group info updated (name, description, image)
class GroupInfoUpdatedEvent extends ChatEvent {
  final Map<String, dynamic> updatedFields;
  final String updatedByUserId;
  final String? systemMessageId;

  GroupInfoUpdatedEvent({
    required super.roomId,
    required this.updatedFields,
    required this.updatedByUserId,
    this.systemMessageId,
  });
}

/// Group permissions updated
class GroupPermissionsUpdatedEvent extends ChatEvent {
  final Map<String, dynamic> newPermissions;
  final String updatedByUserId;

  GroupPermissionsUpdatedEvent({
    required super.roomId,
    required this.newPermissions,
    required this.updatedByUserId,
  });
}

/// Group ownership transferred
class GroupOwnershipTransferredEvent extends ChatEvent {
  final String previousOwnerId;
  final String newOwnerId;
  final String newOwnerName;
  final String? systemMessageId;

  GroupOwnershipTransferredEvent({
    required super.roomId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.newOwnerName,
    this.systemMessageId,
  });
}

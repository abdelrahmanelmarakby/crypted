// ARCH-004 FIX: Unified Chat State Manager
// Consolidates chat state that was spread across multiple locations

import 'dart:async';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:get/get.dart';

/// Unified state manager for chat module
/// Replaces scattered state across ChatController, ChatSessionManager, StreamProvider
class ChatStateManager extends GetxController {
  // =================== CHAT ROOM STATE ===================

  /// Current room ID
  final RxString roomId = ''.obs;

  /// Current chat room data
  final Rx<ChatRoom?> chatRoom = Rx<ChatRoom?>(null);

  /// Whether this is a group chat
  final RxBool isGroupChat = false.obs;

  /// Chat name (group name or other user's name)
  final RxString chatName = ''.obs;

  /// Chat description (for groups)
  final RxString chatDescription = ''.obs;

  /// Group image URL
  final RxString groupImageUrl = ''.obs;

  // =================== MEMBERS STATE ===================

  /// List of chat members
  final RxList<SocialMediaUser> members = <SocialMediaUser>[].obs;

  /// Member count
  final RxInt memberCount = 0.obs;

  /// Admin user IDs
  final RxList<String> adminIds = <String>[].obs;

  /// Blocking user ID (if blocked)
  final Rx<String?> blockingUserId = Rx<String?>(null);

  // =================== MESSAGES STATE ===================

  /// List of messages
  final RxList<Message> messages = <Message>[].obs;

  /// Currently uploading message IDs with progress
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;

  /// Pinned message
  final Rx<Message?> pinnedMessage = Rx<Message?>(null);

  // =================== INPUT STATE ===================

  /// Current message input text
  final RxString inputText = ''.obs;

  /// Whether user is currently typing
  final RxBool isTyping = false.obs;

  /// Reply state
  final RxBool isReplying = false.obs;
  final Rx<Message?> replyingTo = Rx<Message?>(null);

  /// Edit state
  final RxBool isEditing = false.obs;
  final Rx<Message?> editingMessage = Rx<Message?>(null);

  // =================== TYPING INDICATORS ===================

  /// List of users currently typing
  final RxList<SocialMediaUser> typingUsers = <SocialMediaUser>[].obs;

  // =================== UI STATE ===================

  /// Whether loading
  final RxBool isLoading = false.obs;

  /// Whether sending message
  final RxBool isSending = false.obs;

  /// Whether in selection mode
  final RxBool isSelectionMode = false.obs;

  /// Selected messages for batch operations
  final RxList<Message> selectedMessages = <Message>[].obs;

  /// Whether showing attachment picker
  final RxBool isShowingAttachments = false.obs;

  /// Whether recording audio
  final RxBool isRecordingAudio = false.obs;

  // =================== LIFECYCLE ===================

  /// Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }

  // =================== INITIALIZATION ===================

  /// Initialize state with chat room data
  void initializeFromChatRoom(ChatRoom room) {
    roomId.value = room.id ?? '';
    chatRoom.value = room;
    isGroupChat.value = room.isGroupChat ?? false;
    chatName.value = room.name ?? '';
    chatDescription.value = room.description ?? '';
    groupImageUrl.value = room.groupImageUrl ?? '';
    members.value = room.members ?? [];
    memberCount.value = members.length;
    blockingUserId.value = room.blockingUserId;
  }

  /// Initialize from arguments
  void initializeFromArguments(Map<String, dynamic>? arguments) {
    if (arguments == null) return;

    roomId.value = arguments['roomId'] ?? '';
    isGroupChat.value = arguments['isGroupChat'] ?? false;
    chatName.value = arguments['chatName'] ?? '';
    chatDescription.value = arguments['chatDescription'] ?? '';
    groupImageUrl.value = arguments['groupImageUrl'] ?? '';

    if (arguments['members'] != null) {
      members.value = List<SocialMediaUser>.from(arguments['members']);
      memberCount.value = members.length;
    }

    if (arguments['blockedBy'] != null) {
      blockingUserId.value = arguments['blockedBy'];
    }
  }

  // =================== MEMBER OPERATIONS ===================

  /// Get member by ID
  SocialMediaUser? getMemberById(String id) {
    return members.firstWhereOrNull((m) => m.uid == id);
  }

  /// Update members list
  void updateMembers(List<SocialMediaUser> newMembers) {
    members.value = newMembers;
    memberCount.value = newMembers.length;
  }

  /// Add a member
  void addMember(SocialMediaUser member) {
    if (!members.any((m) => m.uid == member.uid)) {
      members.add(member);
      memberCount.value = members.length;
    }
  }

  /// Remove a member
  void removeMember(String memberId) {
    members.removeWhere((m) => m.uid == memberId);
    memberCount.value = members.length;
  }

  // =================== MESSAGE OPERATIONS ===================

  /// Update messages list from stream
  void updateMessages(List<Message> newMessages) {
    messages.value = newMessages;

    // Update pinned message
    final pinned = newMessages.firstWhereOrNull((m) => m.isPinned);
    pinnedMessage.value = pinned;
  }

  /// Add a message locally (optimistic update)
  void addMessageOptimistically(Message message) {
    messages.insert(0, message);
  }

  /// Update a message locally
  void updateMessageLocally(String messageId, Map<String, dynamic> updates) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    // Try to update using copyWith
    try {
      final message = messages[index];
      final updated = message.copyWith(
        id: message.id,
        isPinned: updates['isPinned'] ?? message.isPinned,
        isFavorite: updates['isFavorite'] ?? message.isFavorite,
        isDeleted: updates['isDeleted'] ?? message.isDeleted,
      );

      if (updated is Message) {
        messages[index] = updated;
      }
    } catch (e) {
      // copyWith not available, wait for stream update
    }
  }

  // =================== REPLY STATE ===================

  /// Start replying to a message
  void startReply(Message message) {
    isReplying.value = true;
    replyingTo.value = message;
    isEditing.value = false;
    editingMessage.value = null;
  }

  /// Clear reply state
  void clearReply() {
    isReplying.value = false;
    replyingTo.value = null;
  }

  // =================== EDIT STATE ===================

  /// Start editing a message
  void startEdit(Message message) {
    isEditing.value = true;
    editingMessage.value = message;
    isReplying.value = false;
    replyingTo.value = null;
  }

  /// Clear edit state
  void clearEdit() {
    isEditing.value = false;
    editingMessage.value = null;
  }

  // =================== SELECTION STATE ===================

  /// Toggle message selection
  void toggleMessageSelection(Message message) {
    if (selectedMessages.any((m) => m.id == message.id)) {
      selectedMessages.removeWhere((m) => m.id == message.id);
    } else {
      selectedMessages.add(message);
    }

    isSelectionMode.value = selectedMessages.isNotEmpty;
  }

  /// Clear selection
  void clearSelection() {
    selectedMessages.clear();
    isSelectionMode.value = false;
  }

  // =================== UPLOAD PROGRESS ===================

  /// Update upload progress for a message
  void updateUploadProgress(String messageId, double progress) {
    uploadProgress[messageId] = progress;
  }

  /// Clear upload progress
  void clearUploadProgress(String messageId) {
    uploadProgress.remove(messageId);
  }

  // =================== TYPING INDICATORS ===================

  /// Update typing users
  void updateTypingUsers(List<SocialMediaUser> users) {
    typingUsers.value = users;
  }

  /// Add subscription
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  // =================== RESET ===================

  /// Reset all state
  void reset() {
    roomId.value = '';
    chatRoom.value = null;
    isGroupChat.value = false;
    chatName.value = '';
    chatDescription.value = '';
    groupImageUrl.value = '';
    members.clear();
    memberCount.value = 0;
    adminIds.clear();
    blockingUserId.value = null;
    messages.clear();
    uploadProgress.clear();
    pinnedMessage.value = null;
    inputText.value = '';
    isTyping.value = false;
    clearReply();
    clearEdit();
    clearSelection();
    typingUsers.clear();
    isLoading.value = false;
    isSending.value = false;
    isShowingAttachments.value = false;
    isRecordingAudio.value = false;
  }
}

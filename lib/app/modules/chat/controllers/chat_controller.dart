import 'dart:async';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_actions_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart' as image;
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/extensions/string.dart';
import 'package:crypted_app/app/routes/app_pages.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final RxList<Message> messages = <Message>[].obs;
  late final String roomId;
  final RxBool isLoading = true.obs;
  final RxBool isRecording = false.obs;
  List<SocialMediaUser> members = [];
  
  // Group chat specific properties
  final RxBool isGroupChat = false.obs;
  final RxString chatName = ''.obs;
  final RxString chatDescription = ''.obs;
  final RxInt memberCount = 0.obs;

  String? blockingUserId;

  late final ChatDataSources chatDataSource;

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _streamSubscriptions = [];

  final RxInt yesVotes = 3.obs;
  final RxInt noVotes = 5.obs;
  final RxString selectedOption = ''.obs;

  static ChatController? currentlyPlayingController;

  double get totalVotes => (yesVotes.value + noVotes.value).toDouble();

  // Computed properties for easy access
  bool get isGroup => isGroupChat.value;
  SocialMediaUser? get currentUser => UserService.currentUser.value;
  SocialMediaUser? get sender => members.isNotEmpty ? members.first : null;
  SocialMediaUser? get receiver => members.length > 1 ? members[1] : null;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
    _setupSessionListeners();
  }

  /// Setup listeners for Chat Session Manager changes
  void _setupSessionListeners() {
    // Use stream subscriptions for external streams and store them for cleanup
    _streamSubscriptions.add(
      ChatSessionManager.instance.membersStream.listen((List<SocialMediaUser> newMembers) {
        members = newMembers;
        memberCount.value = newMembers.length;
        _updateChatInfo();
        update(); // Trigger UI update
      })
    );

    _streamSubscriptions.add(
      ChatSessionManager.instance.isGroupChatStream.listen((bool isGroup) {
        isGroupChat.value = isGroup;
        update();
      })
    );

    _streamSubscriptions.add(
      ChatSessionManager.instance.chatNameStream.listen((String name) {
        chatName.value = name;
        update();
      })
    );
  }

  Future<void> _initializeApp() async {
    await _initializeFromArguments();
    _initializeChatDataSource();
    await _checkPermissions();
    _loadMessages();
  }

  Future<void> _initializeFromArguments() async {
    final arguments = Get.arguments;
    print("🔍 Chat arguments received: $arguments");
    roomId = arguments?['roomId'] ?? '';
    
    // Check if we should use the session manager
    final useSessionManager = arguments?['useSessionManager'] ?? true; // Default to true for new implementation

    if (useSessionManager && ChatSessionManager.instance.hasActiveSession) {
      // Use Chat Session Manager (preferred method)
      print("🎯 Using Chat Session Manager");
      _initializeFromSessionManager();
    } else {
      // Legacy method for backward compatibility
      print("🔄 Using legacy argument method");
      await _initializeFromLegacyArguments(arguments);
    }

    _updateChatInfo();
    _logChatInfo();
  }

  /// Initialize from Chat Session Manager
  void _initializeFromSessionManager() {
    final ChatSessionManager sessionManager = ChatSessionManager.instance;
    members = sessionManager.members;
    isGroupChat.value = sessionManager.isGroupChat;
    chatName.value = sessionManager.chatName;
    chatDescription.value = sessionManager.chatDescription;
    memberCount.value = sessionManager.memberCount;
    blockingUserId = Get.arguments?['blockingUserId'];

    sessionManager.printSessionInfo();
  }
  /// Initialize from legacy arguments (backward compatibility)
  @Deprecated('Use _initializeFromSessionManager instead')
  Future<void> _initializeFromLegacyArguments(Map<String, dynamic>? arguments) async {
    if (arguments != null) {
      members = arguments['members'] ?? [];
      blockingUserId = arguments['blockingUserId'];
      
      // Detect if it's a group chat based on member count
      isGroupChat.value = members.length > 2;
      memberCount.value = members.length;
      
      // Set chat name
      if (isGroupChat.value) {
        chatName.value = arguments['groupName'] ?? 'Group Chat';
        chatDescription.value = arguments['groupDescription'] ?? '';
      } else if (members.length > 1) {
        // For 1-on-1 chats, use the other person's name
        final otherUser = members.firstWhere(
          (user) => user.uid != currentUser?.uid,
          orElse: () => members.last,
        );
        chatName.value = otherUser.fullName ?? 'Chat';
      }
    }

    // Ensure current user is in members
    if (members.isEmpty || !members.any((user) => user.uid == currentUser?.uid)) {
      if (currentUser == null) {
        print("⚠️ Current user is null, trying to get from service");
        await _tryToGetCurrentUser();
      }
      
      if (currentUser != null && !members.any((user) => user.uid == currentUser!.uid)) {
        members.insert(0, currentUser!);
        memberCount.value = members.length;
      }
    }

    // Ensure current user is first in the list
    final currentUserIndex = members.indexWhere((user) => user.uid == currentUser?.uid);
    if (currentUserIndex > 0) {
      final userToMove = members.removeAt(currentUserIndex);
      members.insert(0, userToMove);
    }
  }

  Future<void> _tryToGetCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final cachedUserId = CacheHelper.getUserId;
      final userId = currentUser?.uid ?? cachedUserId;

      if (userId != null) {
        print("🔄 Loading user profile for: $userId");
        final userProfile = await UserService().getProfile(userId);
        if (userProfile != null) {
          print("✅ Successfully loaded current user");
          // UserService should update currentUser automatically
        } else {
          print("❌ Failed to load user profile for: $userId");
        }
      } else {
        print("❌ No user ID available from Firebase Auth or Cache");
      }
    } catch (e) {
      print("❌ Failed to get current user: $e");
    }
  }

  void _initializeChatDataSource() {
    print("🔧 Initializing ChatDataSource...");
    print("👤 Current User UID: ${currentUser?.uid}");
    print("👥 All Member UIDs: ${members.map((e) => e.uid).toList()}");

    chatDataSource = ChatDataSources(
      chatConfiguration: ChatConfiguration(
        members: members,
      ),
    );

    print("✅ ChatDataSource initialized successfully");
  }

  void _updateChatInfo() {
    memberCount.value = members.length;
    
    if (!isGroupChat.value && members.length == 2) {
      // Update 1-on-1 chat name with the other person's name
      final otherUser = members.firstWhere(
        (user) => user.uid != currentUser?.uid,
        orElse: () => members.last,
      );
      if (chatName.value.isEmpty || chatName.value == 'Chat') {
        chatName.value = otherUser.fullName ?? 'Chat';
      }
    }
  }

  void _logChatInfo() {
    print("👤 Current User: ${currentUser?.fullName} (${currentUser?.uid})");
    print("👥 Members: ${members.map((e) => '${e.fullName} (${e.uid})').join(', ')}");
    print("💬 Chat Name: ${chatName.value}");
    print("🔢 Member Count: ${memberCount.value}");
    print("👥 Is Group Chat: ${isGroupChat.value}");
    print("🚫 Blocked User ID: $blockingUserId");
  }

  Future<void> _checkPermissions() async {
    // Skip automatic permission requests to avoid unwanted dialogs
    // Permissions will be requested by Zego UIKit when actually needed for calls

    // Initialize Zego if not already initialized
    if (currentUser?.uid != null && currentUser?.fullName != null) {
      await CallDataSources().onUserLogin(currentUser!.uid!, currentUser!.fullName!);
    }
  }

  void _loadMessages() {
    isLoading.value = false;
  }

  void onMessageTextChanged(String value) {
    messageController.value = messageController.value.copyWith(
      text: value,
      selection: TextSelection.fromPosition(
        TextPosition(offset: value.length),
      ),
    );
    update();
  }

  void onChangeRec(bool status) {
    isRecording.value = status;
    update();
  }

  void toggleRecording() {
    onChangeRec(!isRecording.value);
  }

  /// Send a message with proper validation
  Future<void> sendMessage(Message message) async {
    try {
      // Verify that message sender is current user
      if (message.senderId != currentUser?.uid) {
        print("❌ ERROR: Message sender is not current user!");
        print("   Expected: ${currentUser?.uid}");
        print("   Actual: ${message.senderId}");
        throw Exception('Message sender is not current user');
      }

      await chatDataSource.sendMessage(
        privateMessage: message, 
        roomId: roomId, 
        members: members
      );

      _clearMessageInput();
      print("✅ Message sent successfully");
    } catch (e) {
      print("❌ Failed to send message: $e");
      _showErrorToast('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  /// Send a quick text message
  Future<void> sendQuickTextMessage(String text, String roomId) async {
    if (text.trim().isEmpty) {
      print("⚠️ Empty text message, skipping");
      return;
    }

    if (currentUser?.uid == null) {
      print("❌ Current user not available");
      _showErrorToast('Unable to send message: User not logged in');
      return;
    }

    print("📝 Preparing to send text message: '$text'");
    print("👤 Current user: ${currentUser!.uid} - ${currentUser!.fullName}");
    
    if (isGroupChat.value) {
      print("👥 Group members: ${members.map((user) => "${user.uid} - ${user.fullName}").join(", ")}");
    } else {
      print("👥 Receiver: ${receiver?.uid} - ${receiver?.fullName}");
    }

    final textMessage = TextMessage(
      id: '',
      roomId: roomId,
      senderId: currentUser!.uid??"",
      timestamp: DateTime.now(),
      text: text.trim(),
    );

    print("📤 Sending message with senderId: ${textMessage.senderId}");
    await sendMessage(textMessage);
  }

  Future<void> sendCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final locationMessage = LocationMessage(
        id: '${position.latitude},${position.longitude}',
        roomId: roomId,
        senderId: currentUser?.uid ?? '',
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await chatDataSource.postMessageToChat(locationMessage, roomId);
    } catch (e) {
      _showErrorToast('Failed to send location');
    }
  }

  /// Make audio call - enhanced for group chats
  Future<void> makeAudioCall(CallModel call) async {
    _showLoading();
    try {
      // For group chats, ensure all members are included
      if (isGroupChat.value && members.length > 2) {
        print("📞 Initiating group audio call with ${members.length} members");
        // You might need to modify CallModel to support multiple participants
      }
      
      final success = await CallDataSources().storeCall(call);
      if (success) {
        log('Audio call initiated');
      }
    } catch (e) {
      _showErrorToast('Failed to initiate audio call');
    } finally {
      _hideLoading();
    }
  }

  /// Make video call - enhanced for group chats
  Future<bool> makeVideoCall(CallModel call) async {
    _showLoading();
    try {
      // For group chats, ensure all members are included
      if (isGroupChat.value && members.length > 2) {
        print("📹 Initiating group video call with ${members.length} members");
        // You might need to modify CallModel to support multiple participants
      }
      
      final success = await CallDataSources().storeCall(call);
      if (success) {
        log('Video call initiated');
        return true;
      }
      return false;
    } catch (e) {
      _showErrorToast('Failed to initiate video call');
      return false;
    } finally {
      _hideLoading();
    }
  }

  /// Group management methods
  Future<void> addMemberToGroup(SocialMediaUser newMember) async {
    if (!isGroupChat.value) {
      _showErrorToast('Cannot add members to non-group chat');
      return;
    }

    try {
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        final success = sessionManager.addMember(newMember);
        if (success) {
          // Update local members list
          members = sessionManager.members;
          memberCount.value = members.length;
          _showToast('${newMember.fullName} added to group');
          
          // Reinitialize chat data source with new members
          _initializeChatDataSource();
        }
      } else {
        // Fallback for legacy mode
        if (!members.any((member) => member.uid == newMember.uid)) {
          members.add(newMember);
          memberCount.value = members.length;
          _showToast('${newMember.fullName} added to group');
          _initializeChatDataSource();
        }
      }
    } catch (e) {
      _showErrorToast('Failed to add member to group');
    }
  }

  Future<void> removeMemberFromGroup(String userId) async {
    if (!isGroupChat.value) {
      _showErrorToast('Cannot remove members from non-group chat');
      return;
    }

    try {
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        final success = sessionManager.removeMember(userId);
        if (success) {
          // Update local members list
          members = sessionManager.members;
          memberCount.value = members.length;
          _showToast('Member removed from group');
          
          // Check if we still have enough members
          if (members.length < 2) {
            _showToast('Not enough members, ending chat');
            Get.back();
            return;
          }
          
          // Reinitialize chat data source with updated members
          _initializeChatDataSource();
        }
      } else {
        // Fallback for legacy mode
        final memberIndex = members.indexWhere((member) => member.uid == userId);
        if (memberIndex != -1 && memberIndex != 0) { // Don't remove current user
          final removedMember = members.removeAt(memberIndex);
          memberCount.value = members.length;
          _showToast('${removedMember.fullName} removed from group');
          _initializeChatDataSource();
        }
      }
    } catch (e) {
      _showErrorToast('Failed to remove member from group');
    }
  }

  Future<void> updateGroupInfo({String? name, String? description}) async {
    if (!isGroupChat.value) {
      _showErrorToast('Cannot update info for non-group chat');
      return;
    }

    try {
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        sessionManager.updateGroupInfo(name: name, description: description);
        chatName.value = sessionManager.chatName;
        chatDescription.value = sessionManager.chatDescription;
      } else {
        // Fallback for legacy mode
        if (name != null && name.isNotEmpty) {
          chatName.value = name;
        }
        if (description != null) {
          chatDescription.value = description;
        }
      }
      
      _showToast('Group info updated');
    } catch (e) {
      _showErrorToast('Failed to update group info');
    }
  }

  /// Utility methods for member management
  bool isMember(String userId) {
    return members.any((member) => member.uid == userId);
  }

  bool isCurrentUserAdmin() {
    // In this implementation, the first member (current user) is considered admin
    return members.isNotEmpty && members.first.uid == currentUser?.uid;
  }

  List<SocialMediaUser> getOtherMembers() {
    return members.where((member) => member.uid != currentUser?.uid).toList();
  }

  SocialMediaUser? getMemberById(String userId) {
    try {
      return members.firstWhere((member) => member.uid == userId);
    } catch (e) {
      return null;
    }
  }

  void handleVote(String option) {
    if (selectedOption.value == option) return;

    if (selectedOption.value == 'Yes') yesVotes.value--;
    if (selectedOption.value == 'No') noVotes.value--;

    selectedOption.value = option;
    if (option == 'Yes') yesVotes.value++;
    if (option == 'No') noVotes.value++;
  }

  double getYesPercentage() =>
      totalVotes == 0 ? 0 : yesVotes.value / totalVotes;
  double getNoPercentage() => totalVotes == 0 ? 0 : noVotes.value / totalVotes;

  void addMessage(Message message) => messages.add(message);
  
  void removeMessage(int index) {
    if (index >= 0 && index < messages.length) {
      messages.removeAt(index);
    }
  }

  void _showToast(String message) => BotToast.showText(text: message);

  void _showErrorToast(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showLoading() => BotToast.showLoading();
  void _hideLoading() => BotToast.closeAllLoading();

  /// Delete a message
  Future<void> deleteMessage(Message message) async {
    try {
      _showLoading();

      // Update message to mark as deleted
      final updatedMessage = message.copyWith(id: message.id, isDeleted: true) as Message;

      // Update in Firestore
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': true},
      );

      // Update local messages list
      final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        update();
      }

      _showToast('Message deleted');
    } catch (e) {
      _showErrorToast('Failed to delete message: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Restore a deleted message
  Future<void> restoreMessage(Message message) async {
    try {
      _showLoading();

      // Update message to mark as not deleted
      final updatedMessage = message.copyWith(id: message.id, isDeleted: false) as Message;

      // Update in Firestore
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': false},
      );

      // Update local messages list
      final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        update();
      }

      _showToast('Message restored');
    } catch (e) {
      _showErrorToast('Failed to restore message: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Pin/Unpin a message
  Future<void> togglePinMessage(Message message) async {
    try {
      _showLoading();

      final isCurrentlyPinned = message.isPinned;
      final updatedMessage = message.copyWith(
        id: message.id,
        isPinned: !isCurrentlyPinned,
      ) as Message;

      // Update in Firestore
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isPinned': !isCurrentlyPinned},
      );

      // Update local messages list
      final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        update();
      }

      _showToast(isCurrentlyPinned ? 'Message unpinned' : 'Message pinned');
    } catch (e) {
      _showErrorToast('Failed to ${message.isPinned ? 'unpin' : 'pin'} message: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Favorite/Unfavorite a message
  Future<void> toggleFavoriteMessage(Message message) async {
    try {
      _showLoading();

      final isCurrentlyFavorite = message.isFavorite;
      final updatedMessage = message.copyWith(
        id: message.id,
        isFavorite: !isCurrentlyFavorite,
      ) as Message;

      // Update in Firestore
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isFavorite': !isCurrentlyFavorite},
      );

      // Update local messages list
      final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        update();
      }

      _showToast(isCurrentlyFavorite ? 'Removed from favorites' : 'Added to favorites');
    } catch (e) {
      _showErrorToast('Failed to ${message.isFavorite ? 'remove from' : 'add to'} favorites: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Reply to a message
  Future<void> replyToMessage(Message message) async {
    try {
      // Navigate to reply view or show reply input
      Get.toNamed(
        Routes.CHAT,
        arguments: {
          'roomId': roomId,
          'replyTo': message,
          'replyToText': _getMessagePreview(message),
        },
      );
    } catch (e) {
      _showErrorToast('Failed to reply to message: ${e.toString()}');
    }
  }

  /// Forward a message
  Future<void> forwardMessage(Message message) async {
    try {
      // Show contact selection or forward dialog
      Get.toNamed(
        Routes.CHAT,
        arguments: {
          'message': message,
          'roomId': roomId,
        },
      );
    } catch (e) {
      _showErrorToast('Failed to forward message: ${e.toString()}');
    }
  }

  /// Copy message content
  void clearMessages() => messages.clear();

  void _clearMessageInput() {
    messageController.clear();
    update();
  }

  void copyMessage(Message message) {
    try {
      String textToCopy = '';

      if (message is TextMessage) {
        textToCopy = message.text;
      } else {
        textToCopy = _getMessagePreview(message);
      }

      Clipboard.setData(ClipboardData(text: textToCopy));

      _showToast('Message copied to clipboard');
    } catch (e) {
      _showErrorToast('Failed to copy message: ${e.toString()}');
    }
  }

  /// Report a message
  Future<void> reportMessage(Message message) async {
    try {
      // Show report dialog or navigate to report screen
      Get.toNamed(
        Routes.HELP,
        arguments: {
          'message': message,
          'roomId': roomId,
        },
      );
    } catch (e) {
      _showErrorToast('Failed to report message: ${e.toString()}');
    }
  }

  /// Get message preview for copying/forwarding
  String _getMessagePreview(Message message) {
    switch (message) {
      case TextMessage():
        return message.text;
      case image.PhotoMessage():
        return '[Photo]';
      case VideoMessage():
        return '[Video]';
      case AudioMessage():
        return '[Audio]';
      case FileMessage():
        return '[File: ${message.fileName}]';
      case LocationMessage():
        return '[Location]';
      case ContactMessage():
        return '[Contact]';
      case PollMessage():
        return '[Poll]';
      case EventMessage():
        return '[Event]';
      case CallMessage():
        return '[${message.callModel.callType == CallType.audio ? 'Audio' : 'Video'} Call]';
      default:
        return '[Message]';
    }
  }

  /// Get pinned messages
  List<Message> getPinnedMessages() {
    return messages.where((message) => message.isPinned).toList();
  }

  /// Get favorite messages
  List<Message> getFavoriteMessages() {
    return messages.where((message) => message.isFavorite).toList();
  }

  /// Check if message can be acted upon (not deleted, etc.)
  bool canInteractWithMessage(Message message) {
    return !message.isDeleted && message.senderId != currentUser?.uid;
  }

  /// Handle message long press - show bottom sheet
  void handleMessageLongPress(Message message) {
    if (!canInteractWithMessage(message)) {
      _showToast('Cannot perform actions on this message');
      return;
    }

    MessageActionsBottomSheet.show(
      Get.context!,
      message: message,
      onReply: () => replyToMessage(message),
      onCopy: () => copyMessage(message),
      onForward: () => forwardMessage(message),
      onPin: () => togglePinMessage(message),
      onFavorite: () => toggleFavoriteMessage(message),
      onReport: () => reportMessage(message),
      onDelete: () => deleteMessage(message),
      onRestore: message.isDeleted ? () => restoreMessage(message) : null,
      isPinned: message.isPinned,
      isFavorite: message.isFavorite,
      canPin: true,
      canFavorite: true,
      canDelete: message.senderId == currentUser?.uid && !message.isDeleted, // Only allow delete for own non-deleted messages
      canRestore: message.isDeleted && message.senderId == currentUser?.uid, // Only allow restore for own deleted messages
      canReply: true,
      canForward: true,
      canCopy: message is TextMessage,
      canReport: true,
    );
  }

  /// Test method for sending a test message
  Future<void> sendTestMessage() async {
    try {
      print("🧪 Sending test message...");

      final testMessage = TextMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser?.uid ?? "",
        timestamp: DateTime.now(),
        text: 'Test message - ${DateTime.now().toIso8601String()}',
      );

      await sendMessage(testMessage);
    } catch (e) {
      print("❌ Test message failed: $e");
    }
  }

  /// Print current chat information for debugging
  void printChatInfo() {
    print("📋 Current Chat Controller Info:");
    print("   Room ID: $roomId");
    print("   Chat Name: ${chatName.value}");
    print("   Is Group Chat: ${isGroupChat.value}");
    print("   Member Count: ${memberCount.value}");
    print("   Current User: ${currentUser?.fullName} (${currentUser?.uid})");
    print("   Members:");
    for (int i = 0; i < members.length; i++) {
      String role = i == 0 ? " (Current User)" : isGroupChat.value ? " (Member)" : " (Receiver)";
      print("   ${i + 1}. ${members[i].fullName} (${members[i].uid})$role");
    }
    print("   Blocked User: $blockingUserId");
    print("   Has Active Session: ${ChatSessionManager.instance.hasActiveSession}");
  }

  @override
  void onClose() {
    messageController.dispose();
    
    // Cancel all stream subscriptions to prevent memory leaks
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    // End chat session when screen is closed if using session manager
    if (ChatSessionManager.instance.hasActiveSession) {
      print("🔚 Chat screen closed, ending session");
      ChatSessionManager.instance.endChatSession();
    }

    super.onClose();
  }
}
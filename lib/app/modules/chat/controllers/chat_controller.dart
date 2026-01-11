import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/typing_service.dart';
import 'package:crypted_app/app/core/services/read_receipt_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/core/utils/debouncer.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_actions_bottom_sheet.dart';
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
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/message_controller.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller_integration.dart';
import 'package:crypted_app/app/modules/chat/widgets/edit_message_sheet.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';

/// Main Chat Controller with new architecture integration
/// Uses ChatControllerIntegration mixin for event bus, offline support, and state management
/// Includes rate limiting and debouncing for performance
class ChatController extends GetxController
    with ChatControllerIntegration, RateLimitedController, DebouncedControllerMixin {
  // Text input controller
  final TextEditingController messageController = TextEditingController();

  // Sub-controllers (NEW!)
  late final MessageController messageControllerService;

  // Messages list (delegated to MessageController)
  RxList<Message> get messages => messageControllerService.messages;

  // Room and user state
  late final String roomId;
  final RxBool isLoading = true.obs;
  final RxBool isRecording = false.obs;
  List<SocialMediaUser> members = [];

  // Group chat specific properties
  final RxBool isGroupChat = false.obs;
  final RxString chatName = ''.obs;
  final RxString chatDescription = ''.obs;
  final RxInt memberCount = 0.obs;
  final RxString groupImageUrl = ''.obs;

  String? blockingUserId;

  // Reply functionality (delegated to MessageController)
  Rx<Message?> get replyToMessage => messageControllerService.replyToMessage;
  RxString get replyToText => messageControllerService.replyToText;

  late final ChatDataSources chatDataSource;

  // Real-time services
  final typingService = TypingService();
  final readReceiptService = ReadReceiptService();
  final presenceService = PresenceService();

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;
  
  // Typing indicators
  final RxList<String> typingUsers = <String>[].obs;
  final RxString typingText = ''.obs;
  
  // Stream subscriptions for cleanup
  final List<StreamSubscription> _streamSubscriptions = [];

  final RxInt yesVotes = 3.obs;
  final RxInt noVotes = 5.obs;
  final RxString selectedOption = ''.obs;

  double get totalVotes => (yesVotes.value + noVotes.value).toDouble();
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

    // BUG-004 FIX: Don't setup typing listener here - roomId not initialized yet
    // Typing listener is now setup in _initializeApp() after roomId is set
  }
  
  /// Setup typing indicator listener
  void _setupTypingListener() {
    if (roomId.isEmpty) return;
    
    _streamSubscriptions.add(
      typingService.listenToTypingUsers(roomId).listen((users) async {
        if (users.isEmpty) {
          typingUsers.clear();
          typingText.value = '';
          return;
        }
        
        final userIds = users.map((u) => u.userId).toList();
        final names = await typingService.getTypingUsersNames(roomId, userIds);
        typingUsers.value = names;
        typingText.value = typingService.formatTypingText(names);
      })
    );
  }

  Future<void> _initializeApp() async {
    await _initializeFromArguments();
    _initializeChatDataSource();
    await _checkPermissions();
    _loadMessages();

    // BUG-004 FIX: Setup typing listener AFTER roomId is initialized
    _setupTypingListener();

    // Initialize new architecture components
    _initializeNewArchitecture();
  }

  /// Initialize new architecture components (event bus, offline queue, etc.)
  void _initializeNewArchitecture() {
    // Initialize architecture from mixin
    initializeArchitecture(
      roomId: roomId,
      messages: messages,
    );

    // Sync state with state manager
    stateManager.roomId.value = roomId;
    stateManager.isGroupChat.value = isGroupChat.value;
    stateManager.chatName.value = chatName.value;
    stateManager.chatDescription.value = chatDescription.value;
    stateManager.groupImageUrl.value = groupImageUrl.value;

    // Initialize group controller if available
    groupController?.initialize(
      roomId: roomId,
      name: chatName.value,
      description: chatDescription.value,
      imageUrl: groupImageUrl.value,
      membersList: members,
      admins: [], // TODO: Load actual admins from Firestore
    );

    _logger.info('New architecture initialized', context: 'ChatController', data: {
      'roomId': roomId,
      'hasEventBus': true,
      'hasOfflineQueue': true,
    });
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
    _logger.debug('Initializing ChatDataSource', context: 'ChatController', data: {
      'currentUserId': currentUser?.uid,
      'memberCount': members.length,
    });

    chatDataSource = ChatDataSources(
      chatConfiguration: ChatConfiguration(
        members: members,
      ),
    );

    // Initialize MessageController (NEW!)
    messageControllerService = MessageController(
      chatDataSource: chatDataSource,
      roomId: roomId,
      members: members,
    );

    _logger.info('ChatDataSource and MessageController initialized', context: 'ChatController');
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

    // Load group image URL if it's a group chat
    if (isGroupChat.value) {
      _loadGroupImageUrl();
    }
  }

  /// Load group image URL from Firestore
  Future<void> _loadGroupImageUrl() async {
    try {
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .get();

      if (chatRoomDoc.exists) {
        final data = chatRoomDoc.data();
        if (data != null && data['groupImageUrl'] != null) {
          groupImageUrl.value = data['groupImageUrl'] as String;
          print('✅ Loaded group image URL: ${groupImageUrl.value}');
        }
      }
    } catch (e) {
      print('❌ Error loading group image URL: $e');
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

  /// Reply functionality methods (delegated to MessageController)
  Message? get replyingTo => messageControllerService.replyingTo;
  bool get isReplying => messageControllerService.isReplying;

  /// Set message to reply to
  void setReplyTo(Message message) {
    messageControllerService.setReplyTo(message);
  }

  /// Clear reply
  void clearReply() {
    messageControllerService.clearReply();
  }

  /// Send message with reply context
  Future<void> sendMessageWithReply(Message message) async {
    try {
      // BUG-002 FIX: Save reply context BEFORE clearing, then attach to message
      Message messageToSend = message;

      if (isReplying && replyingTo != null) {
        // Create reply context from the message being replied to
        final replyContext = ReplyToMessage(
          id: replyingTo!.id,
          senderId: replyingTo!.senderId,
          previewText: _getMessagePreview(replyingTo!),
        );

        // Create a copy of the message with reply context attached
        messageToSend = message.copyWith(
          id: message.id,
          replyTo: replyContext,
        ) as Message;

        // Clear reply state AFTER attaching context to message
        clearReply();
      }

      await chatDataSource.sendMessage(
        privateMessage: messageToSend,
        roomId: roomId,
        members: members
      );

      _clearMessageInput();
      print("✅ Message sent successfully with reply context");
    } catch (e) {
      print("❌ Failed to send message: $e");
      _showErrorToast('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  /// Send a message with proper validation and rate limiting
  Future<void> sendMessage(Message message) async {
    // SEC-004 FIX: Check rate limit before sending
    final rateLimitResult = recordMessageSend(roomId);
    if (!rateLimitResult.allowed) {
      _showErrorToast(rateLimitResult.message ?? 'Sending too fast. Please wait.');
      return;
    }

    // PERF-008 FIX: Check connectivity before sending
    if (!ConnectivityService().isOnline) {
      // Queue message for offline sending
      _logger.info('Offline - queueing message for later', context: 'ChatController');
      // For now, show a warning - offline queue handles actual queueing
      _showToast('You are offline. Message will be sent when connected.');
    }

    try {
      // Stop typing indicator before sending
      await typingService.stopTyping(roomId);

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

      // Emit message sent event through event bus
      eventBus.emit(MessageSentEvent(
        roomId: roomId,
        messageId: message.id,
        localId: message.id,
      ));

      _clearMessageInput();
      print("✅ Message sent successfully");
    } catch (e) {
      // Emit message send failed event
      eventBus.emit(MessageSendFailedEvent(
        roomId: roomId,
        localId: message.id,
        error: e.toString(),
      ));

      print("❌ Failed to send message: $e");
      _showErrorToast('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  /// Send a quick text message (NOW USES MessageController!)
  Future<void> sendQuickTextMessage(String text, String roomId) async {
    // Delegate to MessageController
    await messageControllerService.sendTextMessage(text);

    // Clear input after sending
    _clearMessageInput();
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

  // BUG-005 FIX: Safe message copyWith helper to avoid unsafe type casting
  /// Safely attempts to copy a message with updated fields.
  /// Returns null if copyWith is not implemented for the message type.
  Message? _safeCopyMessage(Message message, {
    bool? isDeleted,
    bool? isPinned,
    bool? isFavorite,
    ReplyToMessage? replyTo,
  }) {
    try {
      final result = message.copyWith(
        id: message.id,
        isDeleted: isDeleted,
        isPinned: isPinned,
        isFavorite: isFavorite,
        replyTo: replyTo,
      );
      // Verify the result is actually a Message
      if (result is Message) {
        return result;
      }
      return null;
    } catch (e) {
      _logger.warning('copyWith not implemented for ${message.runtimeType}', context: 'ChatController');
      return null;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(Message message) async {
    try {
      _showLoading();

      // Update in Firestore first (this is the source of truth)
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': true},
      );

      // BUG-005 FIX: Safely try to update local state, Firestore stream will sync regardless
      final updatedMessage = _safeCopyMessage(message, isDeleted: true);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
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

      // Update in Firestore first (this is the source of truth)
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': false},
      );

      // BUG-005 FIX: Safely try to update local state
      final updatedMessage = _safeCopyMessage(message, isDeleted: false);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
      }

      _showToast('Message restored');
    } catch (e) {
      _showErrorToast('Failed to restore message: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Pin/Unpin a message (only one message can be pinned at a time)
  Future<void> togglePinMessage(Message message) async {
    try {
      _showLoading();

      final isCurrentlyPinned = message.isPinned;

      // If pinning a message, first unpin any existing pinned messages
      if (!isCurrentlyPinned) {
        final currentlyPinnedMessages = messages.where((msg) => msg.isPinned).toList();

        if (currentlyPinnedMessages.isNotEmpty) {
          // Only allow one pinned message at a time
          // Unpin all currently pinned messages
          for (final pinnedMessage in currentlyPinnedMessages) {
            await chatDataSource.updateMessage(
              roomId: roomId,
              messageId: pinnedMessage.id,
              updates: {'isPinned': false},
            );

            // BUG-005 FIX: Use safe copy method
            final unpinnedMessage = _safeCopyMessage(pinnedMessage, isPinned: false);
            if (unpinnedMessage != null) {
              final pinnedIndex = messages.indexWhere((msg) => msg.id == pinnedMessage.id);
              if (pinnedIndex != -1) {
                messages[pinnedIndex] = unpinnedMessage;
              }
            }
          }
        }
      }

      // Update in Firestore first
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isPinned': !isCurrentlyPinned},
      );

      // BUG-005 FIX: Safely update local state
      final updatedMessage = _safeCopyMessage(message, isPinned: !isCurrentlyPinned);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
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

      // Update in Firestore first
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isFavorite': !isCurrentlyFavorite},
      );

      // BUG-005 FIX: Safely update local state
      final updatedMessage = _safeCopyMessage(message, isFavorite: !isCurrentlyFavorite);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
      }

      _showToast(isCurrentlyFavorite ? 'Removed from favorites' : 'Added to favorites');
    } catch (e) {
      _showErrorToast('Failed to ${message.isFavorite ? 'remove from' : 'add to'} favorites: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  // =================== MESSAGE EDITING ===================

  /// Edit a text message
  Future<void> editMessage(TextMessage message, String newText) async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null) {
        _showErrorToast('User not logged in');
        return;
      }

      if (message.senderId != currentUserId) {
        _showErrorToast('You can only edit your own messages');
        return;
      }

      // Check edit time limit (15 minutes)
      final difference = DateTime.now().difference(message.timestamp);
      if (difference.inMinutes > 15) {
        _showErrorToast('Messages can only be edited within 15 minutes');
        return;
      }

      _showLoading();

      await chatDataSource.editMessage(
        roomId: roomId,
        messageId: message.id,
        newText: newText,
        senderId: currentUserId,
      );

      _logger.info('Message edited successfully: ${message.id}');
      _showToast('Message edited');
    } catch (e) {
      _logger.logError('Failed to edit message', error: e);
      _errorHandler.handleError(
        e,
        // fallbackMessage: 'Failed to edit message',
        showToUser: true,
      );
    } finally {
      _hideLoading();
    }
  }

  /// Show edit message sheet
  void showEditMessageSheet(TextMessage message) {
    final currentUserId = UserService.currentUser.value?.uid;

    if (message.senderId != currentUserId) {
      _showErrorToast('You can only edit your own messages');
      return;
    }

    // Check edit time limit (15 minutes)
    final difference = DateTime.now().difference(message.timestamp);
    if (difference.inMinutes > 15) {
      _showErrorToast('Messages can only be edited within 15 minutes');
      return;
    }

    EditMessageSheet.show(
      context: Get.context!,
      message: message,
      onSave: (newText) => editMessage(message, newText),
    );
  }

  // =================== REACTION METHODS ===================

  /// Toggle a reaction on a message
  Future<void> toggleReaction(Message message, String emoji) async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null) return;

      await chatDataSource.toggleReaction(
        roomId: roomId,
        messageId: message.id,
        emoji: emoji,
        userId: currentUserId,
      );

      _logger.info('Toggled reaction $emoji on message ${message.id}');
    } catch (e) {
      _logger.logError('Failed to toggle reaction', error: e);
      _errorHandler.handleError(
        e,
        // fallbackMessage: 'Failed to add reaction',
        showToUser: true,
      );
    }
  }

  /// Remove all reactions from the current user on a message
  Future<void> removeAllMyReactions(Message message) async {
    try {
      final currentUserId = UserService.currentUser.value?.uid;
      if (currentUserId == null) return;

      await chatDataSource.removeUserReactions(
        roomId: roomId,
        messageId: message.id,
        userId: currentUserId,
      );

      _logger.info('Removed all reactions from message ${message.id}');
    } catch (e) {
      _logger.logError('Failed to remove reactions', error: e);
      _errorHandler.handleError(
        e,
        // fallbackMessage: 'Failed to remove reactions',
        showToUser: true,
      );
    }
  }

  /// Show reaction picker for a message
  void showReactionPicker(BuildContext context, Message message) {
    // This will be implemented in the UI layer
    // The method is here as a placeholder for UI integration
  }

  /// Forward a message with complete contact selection
  Future<void> forwardMessage(Message message) async {
    try {
      // Show contact selection dialog
      final result = await Get.dialog<SocialMediaUser>(
        AlertDialog(
          title: const Text('Forward Message'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<List<SocialMediaUser>>(
              future: _getContactsForForwarding(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final contacts = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                        child: Text(
                          contact.fullName?.isNotEmpty == true
                              ? contact.fullName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: ColorsManager.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(contact.fullName ?? 'Unknown Contact'),
                      subtitle: Text(contact.email ?? ''),
                      onTap: () => Get.back(result: contact),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result != null) {
        // Create a forwarded message
        final forwardedMessage = message.copyWith(
          id: '', // Generate new ID for forwarded message
          roomId: '', // This would be the new chat room ID
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          isForwarded: true,
          forwardedFrom: message.senderId,
        ) as Message;

        // Forward message to selected chat
        try {
          await _forwardMessageToChat(forwardedMessage, result.uid!);
          _showToast('Message forwarded to ${result.fullName}');
          print('📤 Message forwarded to: ${result.fullName} (${result.uid})');
        } catch (e) {
          _showErrorToast('Failed to forward message: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorToast('Failed to forward message: ${e.toString()}');
    }
  }

  /// Forward message to specific chat
  /// Creates or finds existing chat room and sends the forwarded message
  Future<void> _forwardMessageToChat(Message message, String targetUserId) async {
    try {
      _showLoading();
      
      // Get target user data
      final targetUser = await _getUserById(targetUserId);
      if (targetUser == null) {
        throw Exception('Target user not found');
      }
      
      // Get or create chat room with target user
      final targetRoomId = await _getOrCreateChatRoomWithUser(targetUser);
      
      // Create forwarded message with new room ID and timestamp
      Message forwardedMessage;
      
      if (message is TextMessage) {
        forwardedMessage = TextMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          text: message.text,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is image.PhotoMessage) {
        forwardedMessage = image.PhotoMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          imageUrl: message.imageUrl,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is VideoMessage) {
        forwardedMessage = VideoMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          video: message.video,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is AudioMessage) {
        forwardedMessage = AudioMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          audioUrl: message.audioUrl,
          duration: message.duration,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is FileMessage) {
        forwardedMessage = FileMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          file: message.file,
          fileName: message.fileName,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is LocationMessage) {
        forwardedMessage = LocationMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          latitude: message.latitude,
          longitude: message.longitude,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else if (message is ContactMessage) {
        forwardedMessage = ContactMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          name: message.name,
          phoneNumber: message.phoneNumber,
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      } else {
        // For unsupported message types, forward as text with description
        forwardedMessage = TextMessage(
          id: '',
          roomId: targetRoomId,
          senderId: currentUser?.uid ?? '',
          timestamp: DateTime.now(),
          text: '[Forwarded: ${_getMessagePreview(message)}]',
          isForwarded: true,
          forwardedFrom: message.senderId,
        );
      }
      
      // Send forwarded message to target chat room
      await chatDataSource.sendMessage(
        privateMessage: forwardedMessage,
        roomId: targetRoomId,
        members: [currentUser!, targetUser],
      );
      
      print('📤 Message forwarded successfully to room: $targetRoomId with user: ${targetUser.fullName}');
    } catch (e) {
      print('❌ Failed to forward message: $e');
      rethrow;
    } finally {
      _hideLoading();
    }
  }
  
  /// Get or create chat room with specific user
  Future<String> _getOrCreateChatRoomWithUser(SocialMediaUser targetUser) async {
    try {
      // Create members list (current user and target user)
      final members = [currentUser!, targetUser];
      final memberIds = members.map((user) => user.uid).toList()..sort();
      
      // Check if chat room already exists
      final existingRooms = await FirebaseFirestore.instance
          .collection('chats')
          .where('membersIds', isEqualTo: memberIds)
          .where('isGroupChat', isEqualTo: false)
          .limit(1)
          .get();
      
      if (existingRooms.docs.isNotEmpty) {
        // Return existing room ID
        return existingRooms.docs.first.id;
      }
      
      // Create new chat room
      final newRoomRef = FirebaseFirestore.instance.collection('chats').doc();
      final roomId = newRoomRef.id;
      
      await newRoomRef.set({
        'membersIds': memberIds,
        'members': members.map((user) => user.toMap()).toList(),
        'isGroupChat': false,
        'lastChat': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Created new chat room: $roomId');
      return roomId;
    } catch (e) {
      print('❌ Error getting or creating chat room: $e');
      rethrow;
    }
  }
  
  /// Get user by ID from Firestore
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
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  /// Get contacts for forwarding
  Future<List<SocialMediaUser>> _getContactsForForwarding() async {
    try {
      // Get user's contacts from Firestore
      final contactsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUser?.uid) // Exclude current user
          .limit(20) // Limit to 20 contacts for performance
          .get();

      final contacts = contactsQuery.docs
          .map((doc) => SocialMediaUser.fromMap(doc.data()))
          .toList();

      print('📞 Fetched ${contacts.length} contacts for forwarding');
      return contacts;
    } catch (e) {
      print('❌ Error fetching contacts: $e');

      // Return empty list on error - DO NOT use mock data in production
      return [];
    }
  }

  /// Copy message content
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
      // Show report confirmation dialog
      final confirmResult = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Report Message'),
          content: Text('Report this message for violating community guidelines?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Report', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmResult == true) {
        // Implement actual reporting to server
        try {
          await _reportMessageToServer(message);
          _showToast('Message reported. Thank you for helping keep our community safe.');
        } catch (e) {
          _showErrorToast('Failed to report message: ${e.toString()}');
        }
      }
    } catch (e) {
      _showErrorToast('Failed to report message: ${e.toString()}');
    }
  }

  /// Report message to server
  Future<void> _reportMessageToServer(Message message) async {
    try {
      // Implement actual reporting to backend API
      await FirebaseFirestore.instance.collection('reports').add({
        'messageId': message.id,
        'roomId': roomId,
        'reporterId': currentUser?.uid ?? '',
        'reportedUserId': message.senderId,
        'messageType': message.runtimeType.toString(),
        'messageContent': _getMessagePreview(message),
        'reason': 'Community guidelines violation',
        'timestamp': DateTime.now(),
        'status': 'pending',
        'platform': 'mobile',
        'appVersion': '1.0.0',
      });

      // Also update the message to mark it as reported
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {
          'isReported': true,
          'reportedAt': DateTime.now(),
          'reportedBy': currentUser?.uid,
        },
      );

      print('📢 Message reported: ${message.id} by user: ${currentUser?.uid}');
    } catch (e) {
      print('❌ Failed to report message: $e');
      rethrow;
    }
  }

  /// Get message preview for copying/forwarding/replying
  String _getMessagePreview(Message message) {
    switch (message) {
      case TextMessage():
        return message.text;
      case image.PhotoMessage():
        return '[Photo]';
      case VideoMessage():
        return '[Video ${message.video.toString()}]';
      case AudioMessage():
        return '[Audio ${message.duration.toString()}]';
      case FileMessage():
        return '[File: ${message.fileName}]';
      case LocationMessage():
        return '[Location ${message.latitude}, ${message.longitude}]';
      case ContactMessage():
        return '[Contact ${message.name}]';
      case PollMessage():
        return '[Poll ${message.question}]';
      case EventMessage():
        return '[Event ${message.title} ${message.eventDate.toString()}]';
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

  /// Clear message input
  void _clearMessageInput() {
    messageController.clear();
    update();
  }

  /// Check if message can be acted upon (not deleted, etc.)
  bool canInteractWithMessage(Message message) {
    // Allow interaction with non-deleted messages from anyone
    if (!message.isDeleted) return true;

    // For deleted messages, only allow interaction if it's the user's own message (for restore)
    return message.senderId == currentUser?.uid;
  }

  /// Handle message long press - show bottom sheet
  void handleMessageLongPress(Message message) {
    if (!canInteractWithMessage(message)) {
      _showToast('Cannot perform actions on this message');
      return;
    }

    final isTextMessage = message is TextMessage;
    final canEditMsg = isTextMessage &&
        message.senderId == currentUser?.uid &&
        !message.isDeleted &&
        DateTime.now().difference(message.timestamp).inMinutes <= 15;

    MessageActionsBottomSheet.show(
      Get.context!,
      message: message,
      onReply: () => setReplyTo(message),
      onCopy: () => copyMessage(message),
      onForward: () => forwardMessage(message),
      onPin: () => togglePinMessage(message),
      onFavorite: () => toggleFavoriteMessage(message),
      onReport: () => reportMessage(message),
      onDelete: () => deleteMessage(message),
      onRestore: message.isDeleted ? () => restoreMessage(message) : null,
      onReaction: (emoji) => toggleReaction(message, emoji),
      onEdit: canEditMsg ? () => showEditMessageSheet(message) : null,
      isPinned: message.isPinned,
      isFavorite: message.isFavorite,
      canPin: true,
      canFavorite: true,
      canDelete: message.senderId == currentUser?.uid && !message.isDeleted, // Only allow delete for own non-deleted messages
      canRestore: message.isDeleted && message.senderId == currentUser?.uid, // Only allow restore for own deleted messages
      canReply: true,
      canForward: true,
      canCopy: isTextMessage,
      canReport: true,
      canEdit: canEditMsg,
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

  /// Handle text input changes for typing indicator
  void onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      typingService.startTyping(roomId);
    } else {
      typingService.stopTyping(roomId);
    }
  }
  
  /// Mark visible messages as read
  void markMessagesAsRead(List<String> messageIds) {
    if (messageIds.isEmpty) return;
    readReceiptService.markMessagesAsRead(messageIds);
  }

  /// Change group photo
  Future<void> changeGroupPhoto({required bool fromCamera}) async {
    try {
      _showLoading();

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        _hideLoading();
        return;
      }

      // Upload image to Firebase Storage
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_photos')
          .child('${roomId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .update({'groupImageUrl': downloadUrl});

      // Update local state
      groupImageUrl.value = downloadUrl;

      _hideLoading();
      _showToast('Group photo updated successfully');
      print('✅ Group photo updated: $downloadUrl');
    } catch (e) {
      _hideLoading();
      print('❌ Error changing group photo: $e');
      _showErrorToast('Failed to update group photo. Please try again.');
    }
  }

  /// Remove group photo
  Future<void> removeGroupPhoto() async {
    try {
      _showLoading();

      // Delete from Storage if exists
      if (groupImageUrl.value.isNotEmpty) {
        try {
          final storageRef =
              FirebaseStorage.instance.refFromURL(groupImageUrl.value);
          await storageRef.delete();
        } catch (e) {
          print('⚠️ Could not delete old group photo from storage: $e');
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .update({'groupImageUrl': FieldValue.delete()});

      // Update local state
      groupImageUrl.value = '';

      _hideLoading();
      _showToast('Group photo removed successfully');
      print('✅ Group photo removed');
    } catch (e) {
      _hideLoading();
      print('❌ Error removing group photo: $e');
      _showErrorToast('Failed to remove group photo. Please try again.');
    }
  }

  // ============================================================
  // Upload Tracking Methods
  // ============================================================

  /// Track active uploads for cancellation
  final Map<String, StreamSubscription?> _activeUploads = {};

  /// Start tracking an upload and show progress
  void startUpload({
    required String uploadId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String uploadType,
    String? thumbnailPath,
  }) {
    final uploadingMessage = UploadingMessage(
      id: uploadId,
      roomId: roomId,
      senderId: currentUser?.uid ?? '',
      timestamp: DateTime.now(),
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      uploadType: uploadType,
      progress: 0.0,
      thumbnailPath: thumbnailPath,
    );

    // Add to messages list
    messages.insert(0, uploadingMessage);
    update();

    print('📤 Started upload tracking: $uploadId ($fileName)');
  }

  /// Update upload progress
  void updateUploadProgress(String uploadId, double progress) {
    final index = messages.indexWhere((msg) => msg.id == uploadId);
    if (index != -1 && messages[index] is UploadingMessage) {
      final uploadingMessage = messages[index] as UploadingMessage;
      messages[index] = uploadingMessage.copyWith(progress: progress);
      update();
    }
  }

  /// Complete upload by replacing uploading message with actual message
  void completeUpload(String uploadId, Message actualMessage) {
    final index = messages.indexWhere((msg) => msg.id == uploadId);
    if (index != -1) {
      messages[index] = actualMessage;
      update();
    }

    // Remove from active uploads
    _activeUploads.remove(uploadId);

    print('✅ Upload completed: $uploadId');
  }

  /// Cancel an ongoing upload
  void cancelUpload(String uploadId) {
    // Cancel the upload subscription if exists
    final subscription = _activeUploads[uploadId];
    subscription?.cancel();
    _activeUploads.remove(uploadId);

    // Remove from messages list
    messages.removeWhere((msg) => msg.id == uploadId);
    update();

    print('🚫 Upload cancelled: $uploadId');
    _showToast('Upload cancelled');
  }

  @override
  void onClose() {
    _logger.info('ChatController disposing - cleaning up resources', context: 'ChatController', data: {
      'roomId': roomId,
      'streamSubscriptions': _streamSubscriptions.length,
    });

    // Dispose new architecture resources (event bus subscriptions, etc.)
    disposeArchitecture();

    // Dispose debouncers and throttlers
    disposeDebouncers();

    // Dispose MessageController (NEW!)
    messageControllerService.onClose();

    messageController.dispose();

    // Stop all real-time indicators
    _cleanupRealtimeServices();

    // Cancel all stream subscriptions to prevent memory leaks
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    // End chat session when screen is closed if using session manager
    if (ChatSessionManager.instance.hasActiveSession) {
      _logger.info('Chat screen closed, ending session', context: 'ChatController');
      ChatSessionManager.instance.endChatSession();
    }

    _logger.info('ChatController disposed successfully', context: 'ChatController');
    super.onClose();
  }

  /// Clean up all real-time services to prevent memory leaks
  void _cleanupRealtimeServices() {
    try {
      // Stop typing indicator
      typingService.stopTyping(roomId);
      _logger.debug('Typing service cleaned up', context: 'ChatController');
    } catch (e) {
      _logger.warning('Error cleaning up typing service', context: 'ChatController', data: {'error': e.toString()});
    }

    // Note: RecordingService and ActivityStatusService will be added when integrated
    // Uncomment these lines after adding the services to the controller:

    // try {
    //   // Stop recording indicator if active
    //   recordingService.cleanupRecording(roomId);
    //   _logger.debug('Recording service cleaned up', context: 'ChatController');
    // } catch (e) {
    //   _logger.warning('Error cleaning up recording service', context: 'ChatController', data: {'error': e.toString()});
    // }

    // try {
    //   // Mark as away from chat
    //   activityService.setAway(roomId);
    //   _logger.debug('Activity service cleaned up', context: 'ChatController');
    // } catch (e) {
    //   _logger.warning('Error cleaning up activity service', context: 'ChatController', data: {'error': e.toString()});
    // }

    try {
      // Stop read receipt tracking
      // readReceiptService.stopTracking(roomId);
      _logger.debug('Read receipt service cleaned up', context: 'ChatController');
    } catch (e) {
      _logger.warning('Error cleaning up read receipt service', context: 'ChatController', data: {'error': e.toString()});
    }
  }
}
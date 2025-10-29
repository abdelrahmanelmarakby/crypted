import 'dart:async';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/typing_service.dart';
import 'package:crypted_app/app/core/services/read_receipt_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
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
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';

class ChatController extends GetxController {
  // Text input controller
  final TextEditingController messageController = TextEditingController();

  // Messages list
  final RxList<Message> messages = <Message>[].obs;

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

  String? blockingUserId;
  
  // Reply functionality
  final Rx<Message?> replyToMessage = Rx<Message?>(null);
  final RxString replyToText = ''.obs;
  late final ChatDataSources chatDataSource;
  
  // Real-time services
  final typingService = TypingService();
  final readReceiptService = ReadReceiptService();
  final presenceService = PresenceService();
  
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
    
    // Setup typing indicator listener
    _setupTypingListener();
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

  /// Reply functionality methods
  Message? get replyingTo => replyToMessage.value;
  bool get isReplying => replyToMessage.value != null;

  /// Set message to reply to
  void setReplyTo(Message message) {
    replyToMessage.value = message;
    replyToText.value = _getMessagePreview(message);
  }

  /// Clear reply
  void clearReply() {
    replyToMessage.value = null;
    replyToText.value = '';
  }

  /// Send message with reply context
  Future<void> sendMessageWithReply(Message message) async {
    try {
      // Add reply context to message if replying
      Message messageToSend = message;
      if (isReplying && replyingTo != null) {
        // Create a copy of the message with reply context
        // Note: This assumes the Message model supports reply context
        // For now, we'll just clear the reply state
        clearReply();
      }

      await chatDataSource.sendMessage(
        privateMessage: messageToSend,
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

  /// Send a message with proper validation
  Future<void> sendMessage(Message message) async {
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
                  return const Center(child: CircularProgressIndicator());
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
                        backgroundColor: ColorsManager.primary.withOpacity(0.1),
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

        // TODO: Implement actual forwarding to selected chat
        // For now, simulate the forwarding process
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

      // Fallback to mock data if Firestore fails
      return [
        SocialMediaUser(
          uid: 'fallback1',
          fullName: 'John Doe',
          email: 'john@example.com',
        ),
        SocialMediaUser(
          uid: 'fallback2',
          fullName: 'Jane Smith',
          email: 'jane@example.com',
        ),
        SocialMediaUser(
          uid: 'fallback3',
          fullName: 'Alice Johnson',
          email: 'alice@example.com',
        ),
      ];
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

  @override
  void onClose() {
    messageController.dispose();
    
    // Stop typing indicator
    typingService.stopTyping(roomId);

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
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/typing_service.dart';
import 'package:crypted_app/app/core/services/read_receipt_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/chat_privacy_helper.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/rate_limiting/rate_limiter.dart';
import 'package:crypted_app/app/core/utils/debouncer.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/services/offline_queue_service.dart';
import 'package:crypted_app/app/core/state/upload_state_manager.dart';
import 'package:crypted_app/app/core/call/chat_call_handler.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/domain/entities/chat_entity.dart';
import 'package:crypted_app/app/domain/mappers/chat_mapper.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/chat/widgets/message_actions_bottom_sheet.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart'
    as image;
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/nudge_message_model.dart';
import 'package:crypted_app/app/data/models/messages/uploading_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/chat/controllers/message_controller.dart';
import 'package:crypted_app/app/modules/chat/controllers/chat_controller_integration.dart';
import 'package:crypted_app/app/modules/chat/controllers/new_architecture_mixin.dart';
import 'package:crypted_app/app/modules/chat/controllers/forward_architecture_mixin.dart';
import 'package:crypted_app/app/modules/chat/controllers/group_architecture_mixin.dart';
import 'package:crypted_app/app/modules/chat/widgets/chat_wallpaper_picker.dart';
import 'package:crypted_app/app/modules/chat/widgets/confirmation_bottom_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/edit_message_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/forward_bottom_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/group_management_bottom_sheet.dart';
import 'package:crypted_app/app/modules/chat/widgets/member_actions_bottom_sheet.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/search_history_service.dart';

/// Main Chat Controller with new architecture integration
/// Uses ChatControllerIntegration mixin for event bus, offline support, and state management
/// Includes rate limiting and debouncing for performance
/// ARCH-008: Uses CallHandlerMixin to move call logic from view to controller
/// ARCH-009: Uses NewArchitectureMixin for clean architecture message operations
class ChatController extends GetxController
    with
        ChatControllerIntegration,
        RateLimitedController,
        DebouncedControllerMixin,
        CallHandlerMixin,
        NewArchitectureMixin,
        ForwardArchitectureMixin,
        GroupArchitectureMixin {
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
  final RxList<String> adminIds = <String>[].obs;
  final Rx<ChatWallpaper> chatWallpaper = ChatWallpaper.none.obs;

  String? blockingUserId;

  // Translation: in-memory cache { messageId: { text, sourceLang, targetLang } }
  final RxMap<String, Map<String, String>> translatedMessages =
      <String, Map<String, String>>{}.obs;
  // Track which messages are currently being translated
  final RxSet<String> translatingMessageIds = <String>{}.obs;

  // Blocked chat state
  final Rx<BlockedChatInfo> blockedChatInfo = const BlockedChatInfo(
    isBlocked: false,
    blockedByMe: false,
    blockedByThem: false,
    message: '',
  ).obs;

  // INTEGRATION: Domain layer entity for chat room
  // Provides a clean, Firebase-independent representation of chat state
  final Rx<ChatEntity?> chatEntity = Rx<ChatEntity?>(null);

  /// Build ChatEntity from current controller state
  /// Useful for passing chat state to other components without Firebase dependencies
  ChatEntity buildChatEntity() {
    return ChatEntity(
      id: roomId,
      name: chatName.value,
      description: chatDescription.value.isEmpty ? null : chatDescription.value,
      imageUrl: groupImageUrl.value.isEmpty ? null : groupImageUrl.value,
      isGroupChat: isGroupChat.value,
      members:
          members.map((m) => MemberMapper.toEntity(m, adminIds, null)).toList(),
      memberIds:
          members.map((m) => m.uid ?? '').where((id) => id.isNotEmpty).toList(),
      isRead: true,
      isMuted: false,
      isPinned: false,
      isArchived: false,
      isFavorite: false,
      blockedUserIds:
          blockedChatInfo.value.blockedByThem ? [blockingUserId ?? ''] : [],
      adminIds: adminIds.toList(),
      blockingUserId: blockingUserId,
      createdBy: null,
    );
  }

  /// Update chatEntity from current state
  void _updateChatEntity() {
    chatEntity.value = buildChatEntity();
  }

  // Reply functionality (delegated to MessageController)
  Rx<Message?> get replyToMessage => messageControllerService.replyToMessage;
  RxString get replyToText => messageControllerService.replyToText;

  late final ChatDataSources chatDataSource;

  /// Flag to indicate if chatDataSource has been initialized
  final RxBool isChatDataSourceReady = false.obs;

  /// UX-007: Unread message tracking for "New Messages" divider
  /// Stores the timestamp when user entered/opened this chat
  final Rx<DateTime?> chatEntryTime = Rx<DateTime?>(null);

  /// Flag to show the unread divider (dismisses after scrolling)
  final RxBool showUnreadDivider = true.obs;

  /// Count of messages newer than entry time
  final RxInt newMessageCount = 0.obs;

  // ARCH-003: Repository for abstracted data access
  // This provides a clean interface that hides Firebase implementation details
  IChatRepository? _repository;
  IChatRepository get repository {
    _repository ??= Get.isRegistered<IChatRepository>()
        ? Get.find<IChatRepository>()
        : null;
    return _repository!;
  }

  bool get hasRepository => Get.isRegistered<IChatRepository>();

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
  RxBool get isTyping => RxBool(typingUsers.isNotEmpty);
  SocialMediaUser? get currentUser => UserService.currentUser.value;
  SocialMediaUser? get sender => members.isNotEmpty ? members.first : null;
  SocialMediaUser? get receiver => members.length > 1 ? members[1] : null;

  @override
  void onInit() {
    super.onInit();
    // Initialize scroll controller for search navigation
    messageScrollController = ScrollController();

    // UX-007: Record entry time for unread message divider
    chatEntryTime.value = DateTime.now();
    showUnreadDivider.value = true;

    _initializeApp();
    _setupSessionListeners();
  }

  /// UX-007: Dismiss the unread divider (called when user scrolls past it)
  void dismissUnreadDivider() {
    showUnreadDivider.value = false;
  }

  /// UX-007: Check if a message is "new" (received after chat entry)
  bool isNewMessage(DateTime messageTime) {
    final entryTime = chatEntryTime.value;
    if (entryTime == null) return false;
    return messageTime.isAfter(entryTime);
  }

  /// Setup listeners for Chat Session Manager changes
  void _setupSessionListeners() {
    // Use stream subscriptions for external streams and store them for cleanup
    _streamSubscriptions.add(ChatSessionManager.instance.membersStream
        .listen((List<SocialMediaUser> newMembers) {
      members = newMembers;
      memberCount.value = newMembers.length;
      _updateChatInfo();
      update(); // Trigger UI update
    }));

    _streamSubscriptions.add(
        ChatSessionManager.instance.isGroupChatStream.listen((bool isGroup) {
      isGroupChat.value = isGroup;
      update();
    }));

    _streamSubscriptions
        .add(ChatSessionManager.instance.chatNameStream.listen((String name) {
      chatName.value = name;
      update();
    }));

    // BUG-004 FIX: Don't setup typing listener here - roomId not initialized yet
    // Typing listener is now setup in _initializeApp() after roomId is set
  }

  /// Setup typing indicator listener
  void _setupTypingListener() {
    if (roomId.isEmpty) return;

    _streamSubscriptions
        .add(typingService.listenToTypingUsers(roomId).listen((users) async {
      if (users.isEmpty) {
        typingUsers.clear();
        typingText.value = '';
        return;
      }

      final userIds = users.map((u) => u.userId).toList();
      final names = await typingService.getTypingUsersNames(roomId, userIds);
      typingUsers.value = names;
      typingText.value = typingService.formatTypingText(names);
    }));
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

    // Reset unread count for this room when the user opens it
    _resetUnreadCount();

    // Load blocked chat info for private chats
    await _loadBlockedChatInfo();
  }

  /// Get the other user's ID in a private chat
  String? get otherUserId {
    if (isGroupChat.value) return null;
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return null;

    for (final member in members) {
      if (member.uid != currentUserId) {
        return member.uid;
      }
    }
    return null;
  }

  /// Get the other user in a private chat
  SocialMediaUser? get otherUser {
    if (isGroupChat.value) return null;
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return null;

    for (final member in members) {
      if (member.uid != currentUserId) {
        return member;
      }
    }
    return null;
  }

  /// Load blocked chat info for private chats
  Future<void> _loadBlockedChatInfo() async {
    // Only check for private chats
    if (isGroupChat.value) return;

    final userId = otherUserId;
    if (userId == null) return;

    try {
      final chatPrivacyHelper = ChatPrivacyHelper();
      final info = await chatPrivacyHelper.getBlockedChatInfo(userId);
      blockedChatInfo.value = info;

      if (info.isBlocked) {
        _logger.info('Chat blocked', context: 'ChatController', data: {
          'blockedByMe': info.blockedByMe,
          'blockedByThem': info.blockedByThem,
        });
      }
    } catch (e) {
      _logger.error('Error loading blocked chat info: $e',
          context: 'ChatController');
    }
  }

  /// Reset unread count for the current user when they open this chat
  void _resetUnreadCount() {
    final uid = currentUser?.uid;
    if (uid == null || roomId.isEmpty) return;
    // Fire-and-forget: write 0 to the per-user unread counter
    FirebaseFirestore.instance
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .update({'unreadCounts.$uid': 0}).catchError((e) {
      // Silently fail — field may not exist yet on legacy rooms
      log('Reset unread count failed (non-critical): $e');
    });
  }

  /// Unblock the other user in the chat
  Future<void> unblockUser() async {
    final userId = otherUserId;
    if (userId == null) return;

    try {
      // Get the privacy settings service
      final privacyService = Get.find<PrivacySettingsService>();
      await privacyService.unblockUser(userId);

      // Reload blocked chat info
      await _loadBlockedChatInfo();

      Get.snackbar(
        'Success',
        'User has been unblocked',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      _logger.error('Error unblocking user: $e', context: 'ChatController');
      Get.snackbar(
        'Error',
        'Failed to unblock user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Initialize new architecture components (event bus, offline queue, etc.)
  void _initializeNewArchitecture() {
    // Initialize architecture from mixin
    initializeArchitecture(
      roomId: roomId,
      messages: messages,
    );

    // ARCH-009: Initialize new clean architecture mixin
    // This provides the orchestration service, use cases, and optimistic updates
    initializeNewArchitectureMixin(roomId, messages);

    // ARCH-010: Initialize forward architecture mixin
    // Provides forward operations via ForwardOrchestrationService
    if (currentUser?.uid != null) {
      initializeForwardMixin(roomId, currentUser!.uid!);
    }

    // ARCH-011: Initialize group architecture mixin (only for group chats)
    // Provides member management, admin operations, and group info updates
    if (isGroupChat.value && currentUser?.uid != null) {
      initializeGroupMixin(roomId, currentUser!.uid!);
    }

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
      admins: adminIds.toList(),
    );

    // ARCH-008: Initialize call handler
    initializeCallHandler(
      roomId: roomId,
      sendMessage: sendMessage,
    );

    _logger
        .info('New architecture initialized', context: 'ChatController', data: {
      'roomId': roomId,
      'hasEventBus': true,
      'hasOfflineQueue': true,
      'hasCallHandler': true,
      'hasNewArchMixin': isNewArchitectureEnabled,
      'hasForwardArchMixin': isForwardArchitectureEnabled,
      'hasGroupArchMixin': isGroupArchitectureEnabled,
    });
  }

  Future<void> _initializeFromArguments() async {
    final arguments = Get.arguments;
    print("🔍 Chat arguments received: $arguments");
    roomId = arguments?['roomId'] ?? '';

    // Check if we should use the session manager
    final useSessionManager = arguments?['useSessionManager'] ??
        true; // Default to true for new implementation

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
  Future<void> _initializeFromLegacyArguments(
      Map<String, dynamic>? arguments) async {
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
    if (members.isEmpty ||
        !members.any((user) => user.uid == currentUser?.uid)) {
      if (currentUser == null) {
        print("⚠️ Current user is null, trying to get from service");
        await _tryToGetCurrentUser();
      }

      if (currentUser != null &&
          !members.any((user) => user.uid == currentUser!.uid)) {
        members.insert(0, currentUser!);
        memberCount.value = members.length;
      }
    }

    // Ensure current user is first in the list
    final currentUserIndex =
        members.indexWhere((user) => user.uid == currentUser?.uid);
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
    _logger
        .debug('Initializing ChatDataSource', context: 'ChatController', data: {
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
    // BUGFIX: Manually call onInit() since MessageController is not registered via Get.put()
    // GetxController lifecycle methods are only auto-called when registered with GetX
    messageControllerService.onInit();

    // Mark chatDataSource as ready
    isChatDataSourceReady.value = true;
    update(); // Trigger UI rebuild

    _logger.info('ChatDataSource and MessageController initialized',
        context: 'ChatController');
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

    // Load wallpaper for all chat types
    _loadChatWallpaper();

    // INTEGRATION: Update domain entity when chat info changes
    _updateChatEntity();
  }

  /// Load group image URL from Firestore
  Future<void> _loadGroupImageUrl() async {
    try {
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .get();

      if (chatRoomDoc.exists) {
        final data = chatRoomDoc.data();
        if (data != null) {
          // Load group image URL
          if (data['groupImageUrl'] != null) {
            groupImageUrl.value = data['groupImageUrl'] as String;
            print('✅ Loaded group image URL: ${groupImageUrl.value}');
          }

          // Load admin IDs
          if (data['adminIds'] != null) {
            adminIds.value = (data['adminIds'] as List<dynamic>)
                .map((e) => e.toString())
                .toList();
            print('✅ Loaded ${adminIds.length} admin(s)');
          } else if (data['createdBy'] != null) {
            // Fallback: use creator as admin
            adminIds.value = [data['createdBy'] as String];
            print('✅ Using creator as admin: ${adminIds.first}');
          } else if (data['membersIds'] != null &&
              (data['membersIds'] as List).isNotEmpty) {
            // Fallback: first member is admin
            adminIds.value = [(data['membersIds'] as List).first.toString()];
            print('✅ Using first member as admin: ${adminIds.first}');
          }

          // Load chat wallpaper
          if (data['wallpaper'] != null && data['wallpaper'] is Map) {
            chatWallpaper.value = ChatWallpaper.fromMap(
              Map<String, dynamic>.from(data['wallpaper'] as Map),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error loading group data: $e');
    }
  }

  /// Listen for chat wallpaper changes from Firestore (works for all chat types)
  void _loadChatWallpaper() {
    if (roomId.isEmpty) return;

    _streamSubscriptions.add(
      FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc(roomId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null &&
              data['wallpaper'] != null &&
              data['wallpaper'] is Map) {
            chatWallpaper.value = ChatWallpaper.fromMap(
              Map<String, dynamic>.from(data['wallpaper'] as Map),
            );
          } else {
            chatWallpaper.value = ChatWallpaper.none;
          }
        }
      }, onError: (e) {
        print('❌ Error listening to chat wallpaper: $e');
      }),
    );
  }

  void _logChatInfo() {
    print("👤 Current User: ${currentUser?.fullName} (${currentUser?.uid})");
    print(
        "👥 Members: ${members.map((e) => '${e.fullName} (${e.uid})').join(', ')}");
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
      await CallDataSources()
          .onUserLogin(currentUser!.uid!, currentUser!.fullName!);
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

  // ===========================================================================
  // SEARCH IN CONVERSATION
  // ===========================================================================

  /// Whether search mode is active
  final RxBool isSearchMode = false.obs;

  /// Current search query
  final RxString searchQuery = ''.obs;

  /// Search results - filtered messages matching the query
  final RxList<Message> searchResults = <Message>[].obs;

  /// Current search result index (for navigation)
  final RxInt currentSearchIndex = 0.obs;

  /// Scroll controller for navigating to search results
  /// Created and managed by the controller for proper lifecycle management
  late final ScrollController messageScrollController;

  /// GlobalKeys for message items - used for precise scrolling
  /// Keys are registered when messages are built in the view
  final Map<String, GlobalKey> messageKeys = {};

  /// Register a GlobalKey for a message (called by the view)
  void registerMessageKey(String messageId, GlobalKey key) {
    messageKeys[messageId] = key;
  }

  /// Unregister a GlobalKey when message is disposed
  void unregisterMessageKey(String messageId) {
    messageKeys.remove(messageId);
  }

  /// Search history service for recent queries
  final SearchHistoryService _searchHistoryService = SearchHistoryService();

  /// Get recent search history
  Future<List<String>> getSearchHistory() => _searchHistoryService.getHistory();

  /// Remove item from search history
  Future<void> removeFromSearchHistory(String query) =>
      _searchHistoryService.removeFromHistory(query);

  /// Clear all search history
  Future<void> clearSearchHistory() => _searchHistoryService.clearHistory();

  /// Set scroll controller from the view (kept for backwards compatibility)
  @Deprecated(
      'Use messageScrollController getter instead - controller now owns the ScrollController')
  void setScrollController(ScrollController controller) {
    // No-op - controller now manages its own ScrollController
  }

  /// Toggle search mode
  void toggleSearchMode() {
    isSearchMode.value = !isSearchMode.value;
    if (!isSearchMode.value) {
      clearSearch();
    }
  }

  /// Open search mode
  void openSearch() {
    isSearchMode.value = true;
  }

  /// Close search mode
  void closeSearch() {
    isSearchMode.value = false;
    clearSearch();
  }

  /// Search messages with the given query (debounced to prevent excessive filtering)
  void searchMessages(String query) {
    searchQuery.value = query;

    if (query.trim().isEmpty) {
      searchResults.clear();
      currentSearchIndex.value = 0;
      return;
    }

    // FIX: Debounce search to prevent excessive filtering on every keystroke
    getDebouncer('message_search', const Duration(milliseconds: 300))
        .run(() => _performSearch(query));
  }

  /// Internal search implementation (called after debounce)
  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase();

    // Filter messages that match the query
    searchResults.value = messages.where((message) {
      // Search in text messages
      if (message is TextMessage) {
        return message.text.toLowerCase().contains(lowerQuery);
      }
      // Search in file names
      if (message is FileMessage) {
        return message.fileName.toLowerCase().contains(lowerQuery);
      }
      // Search in contact names
      if (message is ContactMessage) {
        return message.name.toLowerCase().contains(lowerQuery);
      }
      // Search in poll questions
      if (message is PollMessage) {
        return message.question.toLowerCase().contains(lowerQuery) ||
            message.options
                .any((opt) => opt.toLowerCase().contains(lowerQuery));
      }
      // Search in event titles
      if (message is EventMessage) {
        return (message.title?.toLowerCase().contains(lowerQuery) ?? false) ||
            (message.description?.toLowerCase().contains(lowerQuery) ?? false);
      }
      return false;
    }).toList();

    // Reset to first result
    currentSearchIndex.value = searchResults.isNotEmpty ? 0 : -1;

    // Save to search history if we found results
    if (searchResults.isNotEmpty) {
      _searchHistoryService.addToHistory(query);
    }

    _logger.debug('Search found ${searchResults.length} results for "$query"',
        context: 'ChatController');
  }

  /// Clear search query and results
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    currentSearchIndex.value = 0;
  }

  /// Navigate to next search result
  void nextSearchResult() {
    if (searchResults.isEmpty) return;

    currentSearchIndex.value =
        (currentSearchIndex.value + 1) % searchResults.length;
    scrollToCurrentSearchResult();
  }

  /// Navigate to previous search result
  void previousSearchResult() {
    if (searchResults.isEmpty) return;

    currentSearchIndex.value = currentSearchIndex.value - 1;
    if (currentSearchIndex.value < 0) {
      currentSearchIndex.value = searchResults.length - 1;
    }
    scrollToCurrentSearchResult();
  }

  /// Scroll to a specific message using GlobalKey for precision
  void scrollToMessage(Message message) {
    final messageId = message.id;

    // Try to use GlobalKey for precise scrolling
    final key = messageKeys[messageId];
    if (key?.currentContext != null) {
      _scrollToWidgetWithKey(key!);
      return;
    }

    // Fallback to estimated scroll, then refine with ensureVisible
    final index = messages.indexOf(message);
    if (index != -1) {
      _scrollToIndexWithRefinement(index, messageId);
    }
  }

  /// Scroll to widget using its GlobalKey (precise)
  void _scrollToWidgetWithKey(GlobalKey key) {
    if (key.currentContext == null) return;

    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3, // Position message 30% from top for visibility
    );
  }

  /// Scroll to index with post-frame refinement using GlobalKey
  void _scrollToIndexWithRefinement(int index, String messageId) {
    // First, estimate scroll position to bring message into view
    const estimatedMessageHeight = 80.0;
    final targetOffset = index * estimatedMessageHeight;

    messageScrollController
        .animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    )
        .then((_) {
      // After scroll completes, try to refine with GlobalKey
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = messageKeys[messageId];
        if (key?.currentContext != null) {
          _scrollToWidgetWithKey(key!);
        }
      });
    });
  }

  /// Scroll to message at specific index (legacy method)
  void scrollToMessageIndex(int index) {
    if (index < 0 || index >= messages.length) return;
    final message = messages[index];
    scrollToMessage(message);
  }

  /// Scroll to message by ID (for reply context tapping)
  void scrollToMessageById(String messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      scrollToMessage(messages[index]);
    }
  }

  /// Scroll to current search result
  void scrollToCurrentSearchResult() {
    if (searchResults.isEmpty || currentSearchIndex.value < 0) return;

    final targetMessage = searchResults[currentSearchIndex.value];
    scrollToMessage(targetMessage);
  }

  /// Get current search result message
  Message? get currentSearchResult {
    if (searchResults.isEmpty || currentSearchIndex.value < 0) return null;
    return searchResults[currentSearchIndex.value];
  }

  /// Check if a message is the current search result (for highlighting)
  bool isCurrentSearchResult(Message message) {
    final current = currentSearchResult;
    return current != null && current.id == message.id;
  }

  /// Check if a message matches the search query (for highlighting)
  bool isSearchResult(Message message) {
    return searchResults.any((m) => m.id == message.id);
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
          privateMessage: messageToSend, roomId: roomId, members: members);

      _clearMessageInput();
      print("✅ Message sent successfully with reply context");
    } catch (e) {
      print("❌ Failed to send message: $e");
      _showErrorToast('Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  /// Send a message with proper validation and rate limiting
  /// ARCH-003: Uses IChatRepository when available for better abstraction
  /// ARCH-009: Uses new architecture MessageOrchestrationService when enabled
  Future<void> sendMessage(Message message) async {
    // SEC-004 FIX: Check rate limit before sending
    final rateLimitResult = recordMessageSend(roomId);
    if (!rateLimitResult.allowed) {
      _showErrorToast(
          rateLimitResult.message ?? 'Sending too fast. Please wait.');
      return;
    }

    // Verify that message sender is current user
    if (message.senderId != currentUser?.uid) {
      print("❌ ERROR: Message sender is not current user!");
      print("   Expected: ${currentUser?.uid}");
      print("   Actual: ${message.senderId}");
      _showErrorToast('Message sender is not current user');
      return;
    }

    // Stop typing indicator before sending
    await typingService.stopTyping(roomId);

    // ARCH-009: Use new architecture with fallback to legacy
    await sendMessageWithNewArchitecture(
      message: message,
      members: members,
      onOptimisticUpdate: () {
        _clearMessageInput();
      },
      onSuccess: (messageId) {
        print("✅ Message sent successfully: $messageId");
        // Emit message sent event through event bus
        eventBus.emit(MessageSentEvent(
          roomId: roomId,
          messageId: messageId,
          localId: null, // New architecture handles ID mapping internally
        ));
      },
      onError: (error) {
        _showErrorToast('Failed to send message: $error');
      },
      legacyPath: () => _sendMessageLegacy(message),
    );
  }

  /// Legacy message sending path (used when new architecture is disabled)
  Future<String> _sendMessageLegacy(Message message) async {
    // PERF-008 FIX: Check connectivity before sending
    if (!ConnectivityService().isOnline) {
      // FIX: Queue message for offline sending
      _logger.info('Offline - queueing message for later',
          context: 'ChatController');

      // Queue the message to offline queue for later delivery
      final messageData = message.toMap();
      messageData['isLocal'] = true;
      messageData['localId'] = message.id;

      await OfflineQueueService().queue.enqueue(
        OperationType.sendMessage,
        {
          'roomId': roomId,
          'message': messageData,
        },
      );

      // Add message to local UI optimistically
      messageControllerService.addLocalMessage(message);

      _showToast('You are offline. Message will be sent when connected.');
      _clearMessageInput();
      return message.id; // Return local ID for offline messages
    }

    // Generate temp ID for optimistic update
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final localMessage = message.copyWith(id: tempId);

    try {
      // OPTIMISTIC UPDATE: Add message to local UI immediately
      messageControllerService.addLocalMessage(localMessage);
      _clearMessageInput();

      // ARCH-003: Use repository when available, fallback to data source
      String actualMessageId;
      if (hasRepository) {
        actualMessageId = await repository.sendMessage(
          message: message,
          roomId: roomId,
          members: members,
        );
      } else {
        actualMessageId = await chatDataSource.sendMessage(
            privateMessage: message, roomId: roomId, members: members);
      }

      // Register mapping for deduplication when Firestore stream delivers
      messageControllerService.registerPendingSentMessage(
          tempId, actualMessageId);

      // Emit message sent event through event bus
      eventBus.emit(MessageSentEvent(
        roomId: roomId,
        messageId: actualMessageId,
        localId: tempId,
      ));

      print(
          "✅ Message sent via legacy path (tempId: $tempId -> actualId: $actualMessageId)");
      return actualMessageId;
    } catch (e) {
      // ROLLBACK: Remove the optimistic message on failure
      messageControllerService.removeLocalMessage(tempId);

      // Emit message send failed event
      eventBus.emit(MessageSendFailedEvent(
        roomId: roomId,
        localId: tempId,
        error: e.toString(),
      ));

      print("❌ Failed to send message (legacy): $e");
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

  /// Make audio call - FIX: Use CallHandlerMixin for proper Zego integration
  Future<void> makeAudioCall(CallModel call) async {
    _showLoading();
    try {
      // For group chats, ensure all members are included
      if (isGroupChat.value && members.length > 2) {
        print("📞 Initiating group audio call with ${members.length} members");
        // Group calls: store call and let Zego handle it
        final callId = await CallDataSources().storeCall(call);
        if (callId != null) {
          log('Group audio call initiated');
        }
      } else {
        // Private call: Use CallHandlerMixin for proper Zego invitation
        final otherUser = _getOtherUser();
        if (otherUser != null) {
          final result = await startAudioCall(otherUser);
          if (!result.success) {
            _showErrorToast(result.error ?? 'Failed to initiate audio call');
          } else {
            log('Audio call initiated via CallHandler');
          }
        } else {
          // Fallback to direct storage if no other user found
          final callId = await CallDataSources().storeCall(call);
          if (callId != null) {
            log('Audio call initiated (fallback)');
          }
        }
      }
    } catch (e) {
      _showErrorToast('Failed to initiate audio call');
    } finally {
      _hideLoading();
    }
  }

  /// Make video call - FIX: Use CallHandlerMixin for proper Zego integration
  Future<bool> makeVideoCall(CallModel call) async {
    _showLoading();
    try {
      // For group chats, ensure all members are included
      if (isGroupChat.value && members.length > 2) {
        print("📹 Initiating group video call with ${members.length} members");
        // Group calls: store call and let Zego handle it
        final callId = await CallDataSources().storeCall(call);
        if (callId != null) {
          log('Group video call initiated');
          return true;
        }
        return false;
      } else {
        // Private call: Use CallHandlerMixin for proper Zego invitation
        final otherUser = _getOtherUser();
        if (otherUser != null) {
          final result = await startVideoCall(otherUser);
          if (!result.success) {
            _showErrorToast(result.error ?? 'Failed to initiate video call');
            return false;
          }
          log('Video call initiated via CallHandler');
          return true;
        } else {
          // Fallback to direct storage if no other user found
          final callId = await CallDataSources().storeCall(call);
          if (callId != null) {
            log('Video call initiated (fallback)');
            return true;
          }
          return false;
        }
      }
    } catch (e) {
      _showErrorToast('Failed to initiate video call');
      return false;
    } finally {
      _hideLoading();
    }
  }

  /// Helper to get the other user in a private chat
  SocialMediaUser? _getOtherUser() {
    final currentUserId = UserService.currentUser.value?.uid;
    if (currentUserId == null || members.length < 2) return null;

    for (final member in members) {
      if (member.uid != currentUserId) {
        return member;
      }
    }
    return null;
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
        final memberIndex =
            members.indexWhere((member) => member.uid == userId);
        if (memberIndex != -1 && memberIndex != 0) {
          // Don't remove current user
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
  Message? _safeCopyMessage(
    Message message, {
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
      _logger.warning('copyWith not implemented for ${message.runtimeType}',
          context: 'ChatController');
      return null;
    }
  }

  /// Delete a message
  /// ARCH-003: Uses IChatRepository when available
  /// ARCH-009: Uses new architecture when enabled
  Future<void> deleteMessage(Message message) async {
    final currentUserId = UserService.currentUser.value?.uid;
    if (currentUserId == null) {
      _showErrorToast('User not logged in');
      return;
    }

    _showLoading();

    try {
      // ARCH-009: Use new architecture with fallback
      await deleteMessageWithNewArchitecture(
        messageId: message.id,
        userId: currentUserId,
        permanent: false, // Soft delete by default
        onSuccess: () {
          // BUG-005 FIX: Safely try to update local state, Firestore stream will sync regardless
          final updatedMessage = _safeCopyMessage(message, isDeleted: true);
          if (updatedMessage != null) {
            final messageIndex =
                messages.indexWhere((msg) => msg.id == message.id);
            if (messageIndex != -1) {
              messages[messageIndex] = updatedMessage;
              update();
            }
          }
          _showToast('Message deleted');
        },
        onError: (error) {
          _showErrorToast('Failed to delete message: $error');
        },
        legacyPath: () => _deleteMessageLegacy(message),
      );
    } catch (e) {
      _showErrorToast('Failed to delete message: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  /// Legacy delete message path (used when new architecture is disabled)
  Future<void> _deleteMessageLegacy(Message message) async {
    // ARCH-003: Use repository when available, fallback to data source
    if (hasRepository) {
      await repository.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': true},
      );
    } else {
      await chatDataSource.updateMessage(
        roomId: roomId,
        messageId: message.id,
        updates: {'isDeleted': true},
      );
    }

    // BUG-005 FIX: Safely try to update local state
    final updatedMessage = _safeCopyMessage(message, isDeleted: true);
    if (updatedMessage != null) {
      final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
      if (messageIndex != -1) {
        messages[messageIndex] = updatedMessage;
        update();
      }
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
        final currentlyPinnedMessages =
            messages.where((msg) => msg.isPinned).toList();

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
            final unpinnedMessage =
                _safeCopyMessage(pinnedMessage, isPinned: false);
            if (unpinnedMessage != null) {
              final pinnedIndex =
                  messages.indexWhere((msg) => msg.id == pinnedMessage.id);
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
      final updatedMessage =
          _safeCopyMessage(message, isPinned: !isCurrentlyPinned);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
      }

      _showToast(isCurrentlyPinned ? 'Message unpinned' : 'Message pinned');
    } catch (e) {
      _showErrorToast(
          'Failed to ${message.isPinned ? 'unpin' : 'pin'} message: ${e.toString()}');
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
      final updatedMessage =
          _safeCopyMessage(message, isFavorite: !isCurrentlyFavorite);
      if (updatedMessage != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == message.id);
        if (messageIndex != -1) {
          messages[messageIndex] = updatedMessage;
          update();
        }
      }

      _showToast(isCurrentlyFavorite
          ? 'Removed from favorites'
          : 'Added to favorites');
    } catch (e) {
      _showErrorToast(
          'Failed to ${message.isFavorite ? 'remove from' : 'add to'} favorites: ${e.toString()}');
    } finally {
      _hideLoading();
    }
  }

  // =================== MESSAGE EDITING ===================

  /// Edit a text message
  /// ARCH-009: Uses new architecture when enabled
  Future<void> editMessage(TextMessage message, String newText) async {
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

    try {
      // ARCH-009: Use new architecture with fallback
      await editMessageWithNewArchitecture(
        messageId: message.id,
        newText: newText,
        userId: currentUserId,
        originalTimestamp: message.timestamp,
        onSuccess: () {
          _logger.info('Message edited successfully: ${message.id}');
          _showToast('Message edited');
        },
        onError: (error) {
          _errorHandler.handleError(
            Exception(error),
            showToUser: true,
          );
        },
        legacyPath: () => chatDataSource.editMessage(
          roomId: roomId,
          messageId: message.id,
          newText: newText,
          senderId: currentUserId,
        ),
      );
    } catch (e) {
      _logger.logError('Failed to edit message', error: e);
      _errorHandler.handleError(
        e,
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
  /// ARCH-003: Uses IChatRepository when available
  /// ARCH-009: Uses new architecture when enabled
  /// FIX: Throttled to prevent rapid fire Firestore writes
  Future<void> toggleReaction(Message message, String emoji) async {
    final currentUserId = UserService.currentUser.value?.uid;
    if (currentUserId == null) return;

    // FIX: Throttle reactions to prevent multiple rapid Firestore writes
    // Uses a unique key per message+emoji combination
    final throttleKey = 'reaction_${message.id}_$emoji';
    getThrottler(throttleKey, const Duration(milliseconds: 500))
        .run(() => _performReactionToggle(message, emoji, currentUserId));
  }

  /// Internal reaction toggle implementation (called after throttle)
  /// ARCH-009: Uses new architecture with fallback to legacy
  Future<void> _performReactionToggle(
      Message message, String emoji, String userId) async {
    // FIX: Prevent reacting to local/pending messages that don't exist in Firestore yet
    if (message.id.isEmpty || message.id.startsWith('pending_')) {
      _logger.warning('Cannot react to pending message: ${message.id}');
      _showToast('Message is still sending. Please wait.');
      return;
    }

    // ARCH-009: Use new architecture with fallback
    await toggleReactionWithNewArchitecture(
      messageId: message.id,
      emoji: emoji,
      userId: userId,
      onSuccess: (result) {
        _logger.info(
            'Toggled reaction $emoji on message ${message.id} (added: ${result.wasAdded})');
      },
      onError: (error) {
        _errorHandler.handleError(
          Exception(error),
          showToUser: true,
        );
      },
      legacyPath: () => _toggleReactionLegacy(message.id, emoji, userId),
    );
  }

  /// Legacy reaction toggle path (used when new architecture is disabled)
  Future<void> _toggleReactionLegacy(
      String messageId, String emoji, String userId) async {
    try {
      // ARCH-003: Use repository when available, fallback to data source
      if (hasRepository) {
        await repository.toggleReaction(
          roomId: roomId,
          messageId: messageId,
          emoji: emoji,
          userId: userId,
        );
      } else {
        await chatDataSource.toggleReaction(
          roomId: roomId,
          messageId: messageId,
          emoji: emoji,
          userId: userId,
        );
      }

      _logger.info('Toggled reaction $emoji on message $messageId (legacy)');
    } catch (e) {
      _logger.logError('Failed to toggle reaction (legacy)', error: e);
      rethrow;
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

  // =================== FORWARD METHODS ===================

  /// Show forward bottom sheet for a message
  /// ARCH-010: Uses ForwardArchitectureMixin with clean UX bottom sheet
  void showForwardSheet(BuildContext context, Message message) {
    // Build forward targets from available data
    final recentChats = _buildRecentChatTargets();
    final allContacts = _buildContactTargets();

    ForwardBottomSheet.show(
      context,
      message: message,
      recentChats: recentChats,
      allContacts: allContacts,
      onForward: (target) async {
        await _performForward(message, target);
      },
      onForwardMultiple: (targets) async {
        await _performForwardMultiple(message, targets);
      },
    );
  }

  /// Build recent chat targets from conversation list
  List<ForwardTarget> _buildRecentChatTargets() {
    // TODO: Implement fetching from conversations data source
    // For now, return members as targets
    return members
        .map((m) => ForwardTarget(
              id: m.uid ?? '',
              name: m.fullName ?? 'Unknown',
              imageUrl: m.imageUrl,
              type: ForwardTargetType.user,
              isGroup: false,
            ))
        .toList();
  }

  /// Build contact targets from user's contacts
  List<ForwardTarget> _buildContactTargets() {
    // TODO: Implement fetching from contacts
    return [];
  }

  /// Perform single forward operation
  Future<void> _performForward(Message message, ForwardTarget target) async {
    if (!isForwardArchitectureEnabled) {
      _showToast('Forward feature not available');
      return;
    }

    final result = await forwardMessageWithNewArchitecture(
      message: message,
      targetRoomId: target.id,
      onSuccess: (forwardResult) {
        _showToast('Message forwarded');
        _logger.info(
            'Message forwarded to ${target.name}: ${forwardResult.messageId}');
      },
      onError: (error) {
        _showToast('Failed to forward: $error');
      },
    );

    if (result == null) {
      _logger.warning('Forward returned null result');
    }
  }

  /// Perform multiple forward operation
  Future<void> _performForwardMultiple(
      Message message, List<ForwardTarget> targets) async {
    if (!isForwardArchitectureEnabled) {
      _showToast('Forward feature not available');
      return;
    }

    final results = await forwardToMultipleWithNewArchitecture(
      message: message,
      targetRoomIds: targets.map((t) => t.id).toList(),
      onComplete: (batchResult) {
        final successCount = batchResult.successful.length;
        final failedCount = batchResult.failed.length;
        if (failedCount > 0) {
          _showToast('Forwarded to $successCount chats, $failedCount failed');
        } else {
          _showToast('Forwarded to $successCount chats');
        }
      },
    );

    if (results != null) {
      _logger.info('Message forwarded to ${results.successful.length} targets');
    }
  }

  // =================== GROUP MANAGEMENT METHODS ===================

  /// Show group management bottom sheet
  /// ARCH-011: Uses GroupArchitectureMixin with clean UX bottom sheet
  void showGroupManagementSheet(BuildContext context) {
    if (!isGroupChat.value) return;

    final groupInfo = currentGroupInfo.value;
    if (groupInfo == null) {
      // Build from controller state if not loaded from service
      _showGroupManagementFromState(context);
      return;
    }

    final isAdmin = adminIds.contains(currentUser?.uid);
    final isCreator = groupInfo.isUserCreator(currentUser?.uid ?? '');

    GroupManagementBottomSheet.show(
      context,
      groupInfo: groupInfo,
      isAdmin: isAdmin,
      isCreator: isCreator,
      onEditName: (newName) => _updateGroupName(newName),
      onEditDescription: (newDescription) =>
          _updateGroupDescription(newDescription),
      onEditImage: () => _pickAndUpdateGroupImage(context),
      onLeaveGroup: () => _confirmAndLeaveGroup(context),
      onEditPermissions: () => _showPermissionsSheet(context),
      onTransferOwnership: () => _showTransferOwnershipSheet(context),
      onViewMembers: () => _showMembersSheet(context),
      onAddMembers: () => _showAddMembersSheet(context),
    );
  }

  /// Build group info from controller state
  void _showGroupManagementFromState(BuildContext context) {
    // Build GroupMember list from SocialMediaUser members
    final groupMembers = members.map((m) {
      final userId = m.uid ?? '';
      final isAdmin = adminIds.contains(userId);
      return GroupMember(
        id: userId,
        name: m.fullName ?? 'Unknown',
        avatarUrl: m.imageUrl,
        role: isAdmin ? GroupRole.admin : GroupRole.member,
        joinedAt: null,
      );
    }).toList();

    final groupInfo = GroupInfo(
      id: roomId,
      name: chatName.value,
      description: chatDescription.value.isEmpty ? null : chatDescription.value,
      imageUrl: groupImageUrl.value.isEmpty ? null : groupImageUrl.value,
      members: groupMembers,
      createdBy: currentUser?.uid ?? '', // Assume current user if unknown
      createdAt: DateTime.now(),
      permissions: GroupPermissions.defaultPermissions,
    );

    final isAdmin = adminIds.contains(currentUser?.uid);

    GroupManagementBottomSheet.show(
      context,
      groupInfo: groupInfo,
      isAdmin: isAdmin,
      isCreator: false,
      onEditName: (newName) => _updateGroupName(newName),
      onEditDescription: (newDescription) =>
          _updateGroupDescription(newDescription),
      onEditImage: () => _pickAndUpdateGroupImage(context),
      onLeaveGroup: () => _confirmAndLeaveGroup(context),
      onEditPermissions: () => _showPermissionsSheet(context),
      onTransferOwnership: () {}, // No-op for non-creator
      onViewMembers: () => _showMembersSheet(context),
      onAddMembers: () => _showAddMembersSheet(context),
    );
  }

  /// Show transfer ownership sheet
  void _showTransferOwnershipSheet(BuildContext context) {
    // TODO: Implement transfer ownership UI
    _showToast('Transfer ownership coming soon');
  }

  /// Show members list sheet
  void _showMembersSheet(BuildContext context) {
    // TODO: Implement members list UI
    _showToast('Members list coming soon');
  }

  /// Update group name using new architecture
  Future<void> _updateGroupName(String newName) async {
    if (isGroupArchitectureEnabled) {
      await updateGroupNameWithNewArchitecture(
        newName: newName,
        onSuccess: () {
          chatName.value = newName;
          _showToast('Group name updated');
        },
        onError: (error) => _showToast('Failed to update name: $error'),
      );
    } else {
      // Legacy path - direct Firestore update
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chatRooms)
            .doc(roomId)
            .update({'name': newName});
        chatName.value = newName;
        _showToast('Group name updated');
      } catch (e) {
        _showToast('Failed to update name');
      }
    }
  }

  /// Update group description using new architecture
  Future<void> _updateGroupDescription(String newDescription) async {
    if (isGroupArchitectureEnabled) {
      await updateGroupDescriptionWithNewArchitecture(
        newDescription: newDescription,
        onSuccess: () {
          chatDescription.value = newDescription;
          _showToast('Group description updated');
        },
        onError: (error) => _showToast('Failed to update description: $error'),
      );
    } else {
      // Legacy path - direct Firestore update
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chatRooms)
            .doc(roomId)
            .update({'description': newDescription});
        chatDescription.value = newDescription;
        _showToast('Group description updated');
      } catch (e) {
        _showToast('Failed to update description');
      }
    }
  }

  /// Pick and update group image
  Future<void> _pickAndUpdateGroupImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (isGroupArchitectureEnabled) {
      await updateGroupImageWithNewArchitecture(
        imagePath: image.path,
        onSuccess: (newUrl) {
          groupImageUrl.value = newUrl;
          _showToast('Group image updated');
        },
        onError: (error) => _showToast('Failed to update image: $error'),
      );
    } else {
      // Legacy path - upload to Firebase Storage and update Firestore
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child('$roomId.jpg');
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chatRooms)
            .doc(roomId)
            .update({'imageUrl': url});
        groupImageUrl.value = url;
        _showToast('Group image updated');
      } catch (e) {
        _showToast('Failed to update image');
      }
    }
  }

  /// Confirm and leave group
  Future<void> _confirmAndLeaveGroup(BuildContext context) async {
    final confirmed = await ConfirmationBottomSheet.show(
      context,
      title: 'Leave Group',
      description:
          'Are you sure you want to leave this group? You will no longer receive messages from this conversation.',
      confirmLabel: 'Leave',
      icon: Icons.exit_to_app_rounded,
      isDestructive: true,
    );

    if (confirmed != true) return;

    if (isGroupArchitectureEnabled) {
      await leaveGroupWithNewArchitecture(
        onSuccess: () {
          _showToast('Left group');
          Get.back(); // Navigate away from chat
        },
        onError: (error) => _showToast('Failed to leave group: $error'),
      );
    } else {
      // Legacy path - direct Firestore update
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.chatRooms)
            .doc(roomId)
            .update({
          'members': FieldValue.arrayRemove([currentUser!.uid!]),
          'admins': FieldValue.arrayRemove([currentUser!.uid!]),
        });
        _showToast('Left group');
        Get.back();
      } catch (e) {
        _showToast('Failed to leave group');
      }
    }
  }

  /// Show permissions editing sheet
  void _showPermissionsSheet(BuildContext context) {
    // TODO: Implement permissions editing sheet
    _showToast('Permissions editing coming soon');
  }

  /// Show add members sheet
  void _showAddMembersSheet(BuildContext context) {
    // TODO: Implement add members sheet with contact selection
    _showToast('Add members coming soon');
  }

  /// Show member actions bottom sheet
  /// ARCH-011: Uses GroupArchitectureMixin for member operations
  void showMemberActionsSheet(BuildContext context, SocialMediaUser member) {
    if (!isGroupChat.value) return;

    final isSelf = member.uid == currentUser?.uid;
    final creatorId = currentGroupInfo.value?.createdBy;
    final isCreator = member.uid == creatorId;
    final isMemberAdmin = adminIds.contains(member.uid);
    final memberRole = isCreator
        ? GroupRole.creator
        : (isMemberAdmin ? GroupRole.admin : GroupRole.member);

    final groupMember = GroupMember(
      id: member.uid ?? '',
      name: member.fullName ?? 'Unknown',
      avatarUrl: member.imageUrl,
      role: memberRole,
      joinedAt: null,
    );

    final isCurrentUserAnAdmin = adminIds.contains(currentUser?.uid);
    final isCurrentUserTheCreator = currentUser?.uid == creatorId;

    MemberActionsBottomSheet.show(
      context,
      member: groupMember,
      isCurrentUserAdmin: isCurrentUserAnAdmin,
      isCurrentUserCreator: isCurrentUserTheCreator,
      isSelf: isSelf,
      onViewProfile: () => _viewMemberProfile(member),
      onSendMessage: () => _startPrivateChat(member),
      onMakeAdmin: memberRole == GroupRole.member && isCurrentUserAnAdmin
          ? () => _makeAdmin(member)
          : null,
      onRemoveAdmin: memberRole == GroupRole.admin && isCurrentUserTheCreator
          ? () => _removeAdmin(member)
          : null,
      onRemoveMember:
          !isSelf && isCurrentUserAnAdmin && memberRole != GroupRole.creator
              ? () => _removeMember(member)
              : null,
      onTransferOwnership: isCurrentUserTheCreator && !isSelf
          ? () => _transferOwnership(context, member)
          : null,
    );
  }

  /// View member profile
  void _viewMemberProfile(SocialMediaUser member) {
    Get.toNamed('/profile', arguments: {'userId': member.uid});
  }

  /// Start private chat with member
  void _startPrivateChat(SocialMediaUser member) {
    Get.toNamed('/chat', arguments: {'userId': member.uid});
  }

  /// Make member an admin
  Future<void> _makeAdmin(SocialMediaUser member) async {
    final memberName = member.fullName ?? 'User';
    if (isGroupArchitectureEnabled) {
      await makeAdminWithNewArchitecture(
        memberId: member.uid!,
        onSuccess: () {
          adminIds.add(member.uid!);
          _showToast('$memberName is now an admin');
        },
        onError: (error) => _showToast('Failed: $error'),
      );
    } else {
      // Legacy path - no method available, show message
      _showToast('Admin management requires new architecture');
    }
  }

  /// Remove admin privileges
  Future<void> _removeAdmin(SocialMediaUser member) async {
    final memberName = member.fullName ?? 'User';
    if (isGroupArchitectureEnabled) {
      await removeAdminWithNewArchitecture(
        memberId: member.uid!,
        onSuccess: () {
          adminIds.remove(member.uid!);
          _showToast('$memberName is no longer an admin');
        },
        onError: (error) => _showToast('Failed: $error'),
      );
    } else {
      // Legacy path - no method available, show message
      _showToast('Admin management requires new architecture');
    }
  }

  /// Remove member from group
  Future<void> _removeMember(SocialMediaUser member) async {
    final memberName = member.fullName ?? 'User';
    if (isGroupArchitectureEnabled) {
      await removeMemberWithNewArchitecture(
        memberId: member.uid!,
        onSuccess: () {
          members.removeWhere((m) => m.uid == member.uid);
          memberCount.value--;
          _showToast('$memberName removed from group');
        },
        onError: (error) => _showToast('Failed: $error'),
      );
    } else {
      // Legacy path - no method available, show message
      _showToast('Member removal requires new architecture');
    }
  }

  /// Transfer group ownership
  Future<void> _transferOwnership(
      BuildContext context, SocialMediaUser member) async {
    final memberName = member.fullName ?? 'User';
    final confirmed = await ConfirmationBottomSheet.show(
      context,
      title: 'Transfer Ownership',
      description:
          'Transfer group ownership to $memberName? You will become a regular admin.',
      confirmLabel: 'Transfer',
      icon: Icons.swap_horiz_rounded,
      iconColor: ColorsManager.primary,
    );

    if (confirmed != true) return;

    if (isGroupArchitectureEnabled) {
      await transferOwnershipWithNewArchitecture(
        newOwnerId: member.uid!,
        onSuccess: () {
          _showToast('Ownership transferred to $memberName');
        },
        onError: (error) => _showToast('Failed: $error'),
      );
    } else {
      _showToast('Ownership transfer requires new architecture');
    }
  }

  /// Show reaction picker for a message
  void showReactionPicker(BuildContext context, Message message) {
    // This will be implemented in the UI layer
    // The method is here as a placeholder for UI integration
  }

  /// Forward a message with contact selection bottom sheet
  Future<void> forwardMessage(Message message) async {
    try {
      final context = Get.context;
      if (context == null) return;

      // Show contact selection bottom sheet
      final result = await showModalBottomSheet<SocialMediaUser>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _ForwardContactSheet(
          getContacts: _getContactsForForwarding,
        ),
      );

      if (result != null) {
        // Forward message to selected contact
        try {
          final forwardedMessage = message.copyWith(
            id: '',
            roomId: '',
            senderId: currentUser?.uid ?? '',
            timestamp: DateTime.now(),
            isForwarded: true,
            forwardedFrom: message.senderId,
          ) as Message;

          await _forwardMessageToChat(forwardedMessage, result.uid!);
          _showToast('Message forwarded to ${result.fullName}');
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
  Future<void> _forwardMessageToChat(
      Message message, String targetUserId) async {
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

      print(
          '📤 Message forwarded successfully to room: $targetRoomId with user: ${targetUser.fullName}');
    } catch (e) {
      print('❌ Failed to forward message: $e');
      rethrow;
    } finally {
      _hideLoading();
    }
  }

  /// Get or create chat room with specific user
  Future<String> _getOrCreateChatRoomWithUser(
      SocialMediaUser targetUser) async {
    try {
      // Create members list (current user and target user)
      final members = [currentUser!, targetUser];
      final memberIds = members.map((user) => user.uid).toList()..sort();

      // Check if chat room already exists
      final existingRooms = await FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .where('membersIds', isEqualTo: memberIds)
          .where('isGroupChat', isEqualTo: false)
          .limit(1)
          .get();

      if (existingRooms.docs.isNotEmpty) {
        // Return existing room ID
        return existingRooms.docs.first.id;
      }

      // Create new chat room
      final newRoomRef = FirebaseFirestore.instance
          .collection(FirebaseCollections.chats)
          .doc();
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
          .collection(FirebaseCollections.users)
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
      // Get current user's blocked list
      final currentUserDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUser?.uid)
          .get();

      final blockedByMe = List<String>.from(
        currentUserDoc.data()?['blockedUser'] ?? [],
      );

      // Get user's contacts from Firestore
      final contactsQuery = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('uid', isNotEqualTo: currentUser?.uid) // Exclude current user
          .limit(50) // Fetch more to account for filtering
          .get();

      // Filter out blocked users (bidirectional)
      final contacts = <SocialMediaUser>[];
      for (final doc in contactsQuery.docs) {
        final user = SocialMediaUser.fromMap(doc.data());
        final userId = user.uid ?? '';

        // Skip if I blocked them
        if (blockedByMe.contains(userId)) continue;

        // Skip if they blocked me
        final theirBlockedList =
            List<String>.from(doc.data()['blockedUser'] ?? []);
        if (theirBlockedList.contains(currentUser?.uid)) continue;

        contacts.add(user);

        // Limit to 20 after filtering
        if (contacts.length >= 20) break;
      }

      print(
          '📞 Fetched ${contacts.length} contacts for forwarding (after block filtering)');
      return contacts;
    } catch (e) {
      print('❌ Error fetching contacts: $e');

      // Return empty list on error - DO NOT use mock data in production
      return [];
    }
  }

  /// Copy message content
  @override
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
      final context = Get.context;
      if (context == null) return;

      // Show report confirmation bottom sheet
      final confirmResult = await ConfirmationBottomSheet.show(
        context,
        title: 'Report Message',
        description:
            'Report this message for violating community guidelines? Our team will review it.',
        confirmLabel: 'Report',
        icon: Icons.flag_rounded,
        isDestructive: true,
      );

      if (confirmResult == true) {
        // Implement actual reporting to server
        try {
          await _reportMessageToServer(message);
          _showToast(
              'Message reported. Thank you for helping keep our community safe.');
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
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.reports)
          .add({
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
      onTranslate: isTextMessage ? () => translateMessage(message) : null,
      isPinned: message.isPinned,
      isFavorite: message.isFavorite,
      canPin: true,
      canFavorite: true,
      canDelete: message.senderId == currentUser?.uid &&
          !message.isDeleted, // Only allow delete for own non-deleted messages
      canRestore: message.isDeleted &&
          message.senderId ==
              currentUser?.uid, // Only allow restore for own deleted messages
      canReply: true,
      canForward: true,
      canCopy: isTextMessage,
      canReport: true,
      canEdit: canEditMsg,
      canTranslate: isTextMessage,
      isTranslated: translatedMessages.containsKey(message.id),
    );
  }

  /// Translate a message to the user's device locale.
  /// Uses the Cloud Function `translateMessage` which calls Google Cloud Translation API.
  /// Results are cached in [translatedMessages] for the session lifetime.
  Future<void> translateMessage(Message message) async {
    if (message is! TextMessage) {
      _showToast('Only text messages can be translated');
      return;
    }

    final msgId = message.id;
    if (msgId.isEmpty) return;

    // If already translated, toggle it off (remove translation)
    if (translatedMessages.containsKey(msgId)) {
      translatedMessages.remove(msgId);
      update();
      return;
    }

    // Determine target language from device locale
    final deviceLocale = Get.locale?.languageCode ?? 'en';
    // If the message is in the user's language already, translate to the "other" language
    // Default: translate to device locale
    final targetLang = deviceLocale;

    // Mark as translating
    translatingMessageIds.add(msgId);
    update();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('translateMessage');

      final result = await callable.call<Map<String, dynamic>>({
        'text': message.text,
        'targetLanguage': targetLang,
      });

      final data = result.data;
      final translatedText = data?['translatedText'] as String? ?? '';
      final detectedSource = data?['detectedSourceLanguage'] as String? ?? '';

      if (translatedText.isNotEmpty && translatedText != message.text) {
        translatedMessages[msgId] = {
          'text': translatedText,
          'sourceLang': detectedSource,
          'targetLang': targetLang,
        };
      } else {
        // Same language — let the user know
        _showToast('Message is already in your language');
      }
    } catch (e) {
      log('[Translation] Error: $e');
      Get.snackbar(
        'Translation Failed',
        'Could not translate this message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      translatingMessageIds.remove(msgId);
      update();
    }
  }

  /// Send a nudge / "Thinking of you" message.
  ///
  /// Quick action to ping someone with a special animated card.
  /// [nudgeText] and [nudgeEmoji] customize the nudge content.
  Future<void> sendNudge({
    String nudgeText = 'Thinking of you',
    String nudgeEmoji = '💭',
  }) async {
    try {
      final nudge = NudgeMessage(
        id: '',
        roomId: roomId,
        senderId: currentUser?.uid ?? '',
        timestamp: DateTime.now(),
        nudgeText: nudgeText,
        nudgeEmoji: nudgeEmoji,
      );
      await sendMessage(nudge);
      HapticFeedback.mediumImpact();
    } catch (e) {
      log('[Nudge] Error sending nudge: $e');
      Get.snackbar('Error', 'Failed to send nudge');
    }
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
      String role = i == 0
          ? " (Current User)"
          : isGroupChat.value
              ? " (Member)"
              : " (Receiver)";
      print("   ${i + 1}. ${members[i].fullName} (${members[i].uid})$role");
    }
    print("   Blocked User: $blockingUserId");
    print(
        "   Has Active Session: ${ChatSessionManager.instance.hasActiveSession}");
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
          .collection(FirebaseCollections.chats)
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
          .collection(FirebaseCollections.chats)
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

    // Track in UploadStateManager for speed/ETA calculation
    try {
      final manager = Get.find<UploadStateManager>();
      final type = _getUploadType(uploadType);
      manager.startUpload(
        id: uploadId,
        fileName: fileName,
        totalBytes: fileSize,
        roomId: roomId,
        type: type,
      );
    } catch (e) {
      // UploadStateManager might not be registered
      print('⚠️ UploadStateManager not available: $e');
    }

    print('📤 Started upload tracking: $uploadId ($fileName)');
  }

  /// Map upload type string to UploadType enum
  UploadType _getUploadType(String type) {
    switch (type) {
      case 'image':
      case 'video':
        return UploadType.media;
      case 'audio':
        return UploadType.audio;
      case 'file':
        return UploadType.document;
      default:
        return UploadType.other;
    }
  }

  /// Update upload progress
  void updateUploadProgress(String uploadId, double progress) {
    final index = messages.indexWhere((msg) => msg.id == uploadId);
    if (index != -1 && messages[index] is UploadingMessage) {
      final uploadingMessage = messages[index] as UploadingMessage;
      final fileSize = uploadingMessage.fileSize;
      final bytesTransferred = (progress * fileSize).toInt();

      messages[index] = uploadingMessage.copyWith(progress: progress);
      update();

      // Update UploadStateManager with bytes transferred for speed/ETA
      try {
        final manager = Get.find<UploadStateManager>();
        manager.updateProgress(uploadId, bytesTransferred);
      } catch (e) {
        // UploadStateManager might not be available
      }
    }
  }

  /// Complete upload - register with MessageController for smart merge
  /// The actual message will arrive via Firestore stream after sync
  void completeUpload(String uploadId, Message actualMessage) {
    // Register the pending upload with MessageController
    // This allows the smart merge to know when to swap UploadingMessage for actual message
    messageControllerService.registerPendingUpload(uploadId, actualMessage.id);

    // Mark the UploadingMessage as complete (100% progress) but keep it visible
    // until the Firestore stream delivers the actual message
    final uploadIndex = messages.indexWhere((msg) => msg.id == uploadId);
    if (uploadIndex != -1 && messages[uploadIndex] is UploadingMessage) {
      final uploadingMsg = messages[uploadIndex] as UploadingMessage;
      // Mark as completed with 100% progress - will be replaced when Firestore syncs
      messages[uploadIndex] = uploadingMsg.copyWith(progress: 1.0);
      update();
      print('✅ Marked upload as complete, waiting for Firestore sync');
    }

    // Remove from active uploads
    _activeUploads.remove(uploadId);

    // Mark as completed in UploadStateManager
    try {
      final manager = Get.find<UploadStateManager>();
      manager.completeUpload(uploadId, downloadUrl: '');
    } catch (e) {
      // UploadStateManager might not be available
    }

    print('✅ Upload completed: $uploadId → ${actualMessage.id}');
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

    // Mark as cancelled in UploadStateManager
    try {
      final manager = Get.find<UploadStateManager>();
      manager.cancelUpload(uploadId);
    } catch (e) {
      // UploadStateManager might not be available
    }

    print('🚫 Upload cancelled: $uploadId');
    _showToast('Upload cancelled');
  }

  /// Retry a failed upload
  void retryUpload(String uploadId) {
    // Find the uploading message
    UploadingMessage? uploadingMessage;
    for (final msg in messages) {
      if (msg is UploadingMessage && msg.id == uploadId) {
        uploadingMessage = msg;
        break;
      }
    }

    if (uploadingMessage == null) {
      _showToast('Cannot retry - upload not found');
      return;
    }

    // Reset the upload state in UploadStateManager
    try {
      final manager = Get.find<UploadStateManager>();
      manager.retryUpload(uploadId);
    } catch (e) {
      // Manager might not be available
    }

    // Check if file still exists
    final file = File(uploadingMessage.filePath);
    if (!file.existsSync()) {
      _showToast('Cannot retry - file no longer exists');
      messages.removeWhere((msg) => msg.id == uploadId);
      update();
      return;
    }

    // Remove old upload message and show toast
    // User needs to re-select the file to retry (the original file path is no longer accessible)
    messages.removeWhere((msg) => msg.id == uploadId);
    update();

    print('🔄 Retry requested for: $uploadId');
    _showToast('Please re-select the file to send again');
  }

  @override
  void onClose() {
    _logger.info('ChatController disposing - cleaning up resources',
        context: 'ChatController',
        data: {
          'roomId': roomId,
          'streamSubscriptions': _streamSubscriptions.length,
        });

    // Dispose new architecture resources (event bus subscriptions, etc.)
    disposeArchitecture();

    // ARCH-009: Dispose new architecture mixin
    disposeNewArchitectureMixin();

    // ARCH-010: Dispose forward architecture mixin
    disposeForwardMixin();

    // ARCH-011: Dispose group architecture mixin
    disposeGroupMixin();

    // ARCH-008: Dispose call handler
    disposeCallHandler();

    // Dispose debouncers and throttlers
    disposeDebouncers();

    // Dispose MessageController (NEW!)
    messageControllerService.onClose();

    messageController.dispose();

    // Stop all real-time indicators
    _cleanupRealtimeServices();

    // Dispose scroll controller for search
    messageScrollController.dispose();

    // Cancel all stream subscriptions to prevent memory leaks
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    // End chat session when screen is closed if using session manager
    if (ChatSessionManager.instance.hasActiveSession) {
      _logger.info('Chat screen closed, ending session',
          context: 'ChatController');
      ChatSessionManager.instance.endChatSession();
    }

    _logger.info('ChatController disposed successfully',
        context: 'ChatController');
    super.onClose();
  }

  /// Clean up all real-time services to prevent memory leaks
  void _cleanupRealtimeServices() {
    try {
      // Stop typing indicator
      typingService.stopTyping(roomId);
      _logger.debug('Typing service cleaned up', context: 'ChatController');
    } catch (e) {
      _logger.warning('Error cleaning up typing service',
          context: 'ChatController', data: {'error': e.toString()});
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
      _logger.debug('Read receipt service cleaned up',
          context: 'ChatController');
    } catch (e) {
      _logger.warning('Error cleaning up read receipt service',
          context: 'ChatController', data: {'error': e.toString()});
    }
  }
}

/// iOS-style contact selection bottom sheet for forwarding messages
class _ForwardContactSheet extends StatelessWidget {
  final Future<List<SocialMediaUser>> Function() getContacts;

  const _ForwardContactSheet({required this.getContacts});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.forward_to_inbox_rounded,
                    color: ColorsManager.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Forward To',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Contact list
          Flexible(
            child: FutureBuilder<List<SocialMediaUser>>(
              future: getContacts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.grey[400], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load contacts',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final contacts = snapshot.data ?? [];
                if (contacts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              color: Colors.grey[400], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No contacts available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.grey[100],
                  ),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            ColorsManager.primary.withValues(alpha: 0.1),
                        backgroundImage: contact.imageUrl?.isNotEmpty == true
                            ? NetworkImage(contact.imageUrl!)
                            : null,
                        child: contact.imageUrl?.isNotEmpty != true
                            ? Text(
                                contact.fullName?.isNotEmpty == true
                                    ? contact.fullName![0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: ColorsManager.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        contact.fullName ?? 'Unknown Contact',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: contact.email?.isNotEmpty == true
                          ? Text(
                              contact.email!,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(contact);
                      },
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

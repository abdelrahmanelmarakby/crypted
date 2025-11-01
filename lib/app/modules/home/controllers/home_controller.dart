import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/chat_service.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/services/firebase_utils.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/auth_data_sources.dart';

/// Production-grade Home Controller for chat application
/// Handles user management, chat creation, and navigation
class HomeController extends GetxController {
  // =================== GETTERS ===================

  /// Get current user
  SocialMediaUser? get currentUser => myUser.value;

  /// Check if currently creating a chat
  bool get isBusy => isLoadingUsers.value || isCreatingChat.value;

  /// Get users for display (filtered)
  List<SocialMediaUser> get displayUsers => filteredUsers;

  // =================== STATE MANAGEMENT ===================
  final RxList<SocialMediaUser> users = <SocialMediaUser>[].obs;
  final RxList<SocialMediaUser> filteredUsers = <SocialMediaUser>[].obs;
  final RxList<SocialMediaUser> selectedUsers = <SocialMediaUser>[].obs;

  // Loading states
  final RxBool isLoadingUsers = false.obs;
  final RxBool isCreatingChat = false.obs;

  // Current user
  Rxn<SocialMediaUser> myUser = Rxn<SocialMediaUser>();

  // Search functionality
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Group chat creation properties
  final RxString groupName = ''.obs;
  final TextEditingController groupNameController = TextEditingController();
  final RxString groupPhotoUrl = ''.obs;
  final RxBool isLoadingGroupPhoto = false.obs;

  // Services
  final CallDataSources callDataSources = CallDataSources();
  final ImagePicker imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupReactiveListeners();
  }

  @override
  void onReady() async {
    await _initializeCurrentUser();
    await _initializeCallServices();
    super.onReady();
  }

  /// Initialize basic data and reactive listeners
  void _initializeData() {
    // Load users asynchronously
    _loadUsers();

    // Listen to search query changes
    ever(searchQuery, (_) => _filterUsers());
  }

  /// Setup reactive listeners for state management
  void _setupReactiveListeners() {
    // Listen to current user changes
    ever(UserService.currentUser, (user) {
      if (user != null) {
        myUser.value = user;
      }
    });

    // Listen to user selection changes
    ever(selectedUsers, (_) => _updateSelectionState());
  }

  /// Initialize current user data
  Future<void> _initializeCurrentUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? CacheHelper.getUserId ?? "";
      if (userId.isNotEmpty) {
        final user = await UserService().getProfile(userId);
        myUser.value = user;
      }
    } catch (e) {
      _showErrorToast('Failed to load user profile: $e');
    }
  }

  /// Initialize call services for the current user
  Future<void> _initializeCallServices() async {
    final user = myUser.value;
    if (user != null && user.uid != null && user.fullName != null) {
      try {
        await callDataSources.onUserLogin(user.uid!, user.fullName!);
      } catch (e) {
        print('Warning: Failed to initialize call services: $e');
      }
    }
  }

  /// Load all users from the data source
  Future<void> _loadUsers() async {
    isLoadingUsers.value = true;
    try {
      final userList = await AuthenticationService.getAllUsers();
      users.assignAll(userList);

      // Filter out current user and blocked users
      _filterUsers();
    } catch (e) {
      _showErrorToast('Failed to load users: $e');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  /// Filter users based on search query and exclude current user
  void _filterUsers() {
    final query = searchQuery.value.toLowerCase().trim();
    final currentUserId = myUser.value?.uid;

    if (query.isEmpty) {
      filteredUsers.assignAll(
        users.where((user) => user.uid != currentUserId).toList(),
      );
    } else {
      filteredUsers.assignAll(
        users.where((user) {
          return user.uid != currentUserId &&
                 (user.fullName?.toLowerCase().contains(query) == true ||
                  user.bio?.toLowerCase().contains(query) == true);
        }).toList(),
      );
    }
  }

  /// Update selection state based on selected users
  void _updateSelectionState() {
    // Clear group creation properties if no users are selected
    if (selectedUsers.isEmpty) {
      _clearGroupCreationProperties();
    }
    // Update UI state based on selection
    update();
  }

  // =================== CHAT CREATION METHODS ===================

  /// Create a new private chat with a single user
  Future<void> createNewPrivateChatRoom(SocialMediaUser otherUser) async {
    if (myUser.value == null) {
      _showErrorToast('Current user not loaded. Please try again.');
      return;
    }

    isCreatingChat.value = true;

    try {
      // Validate input
      if (!_validatePrivateChatInput(otherUser)) {
        return;
      }

      final currentUser = myUser.value!;
      final members = [currentUser, otherUser];

      print('🎯 Creating private chat:');
      print('👤 Current User: ${currentUser.fullName} (${currentUser.uid})');
      print('👥 Other User: ${otherUser.fullName} (${otherUser.uid})');

      // Step 1: Start chat session using ChatSessionManager
      final sessionStarted = ChatSessionManager.instance.startChatSession(
        sender: currentUser,
        receiver: otherUser,
      );

      if (!sessionStarted) {
        throw Exception('Failed to start chat session');
      }

      // Step 2: Initialize ChatService with members
      ChatService.instance.initializeChatDataSource(members);

      // Step 3: Create chat room using ChatService
      final chatRoom = await ChatService.instance.createChatRoom(
        members: members,
        isGroupChat: false,
        customRoomId: ChatSessionManager.instance.roomId,
      );

      if (chatRoom == null) {
        throw Exception('Failed to create chat room');
      }

      print('✅ Chat room created: ${chatRoom.id}');

      // Step 3: Navigate to chat screen
      await _navigateToChat(
        roomId: chatRoom.id!,
        members: members,
        isGroupChat: false,
      );

    } catch (e) {
      print('❌ Error creating private chat: $e');
      _showErrorToast('Failed to create private chat. Please try again.');
    } finally {
      isCreatingChat.value = false;
    }
  }

  /// Create a new group chat with selected users
  Future<void> createNewGroupChatRoom(List<SocialMediaUser> selectedUsersList) async {
    if (myUser.value == null) {
      _showErrorToast('Current user not loaded. Please try again.');
      return;
    }

    if (selectedUsersList.length < 2) {
      _showErrorToast('Please select at least 2 users for group chat.');
      return;
    }

    isCreatingChat.value = true;

    try {
      final currentUser = myUser.value!;
      final allMembers = [currentUser, ...selectedUsersList];

      print('🎯 Creating group chat:');
      print('👤 Current User: ${currentUser.fullName} (${currentUser.uid})');
      print('👥 Group Members: ${selectedUsersList.length}');

      // Step 1: Upload group photo to Firebase Storage if provided
      String? uploadedPhotoUrl;
      if (groupPhotoUrl.value.isNotEmpty && !groupPhotoUrl.value.startsWith('http')) {
        print('📸 Uploading group photo...');
        isLoadingGroupPhoto.value = true;

        uploadedPhotoUrl = await FirebaseUtils.uploadGroupPhoto(groupPhotoUrl.value);

        if (uploadedPhotoUrl != null) {
          print('✅ Group photo uploaded: $uploadedPhotoUrl');
          groupPhotoUrl.value = uploadedPhotoUrl; // Update to use the uploaded URL
        } else {
          print('⚠️ Failed to upload group photo, continuing without it');
        }

        isLoadingGroupPhoto.value = false;
      } else if (groupPhotoUrl.value.startsWith('http')) {
        uploadedPhotoUrl = groupPhotoUrl.value; // Already uploaded
      }

      // Step 2: Start group chat session using ChatSessionManager
      final sessionStarted = ChatSessionManager.instance.startGroupChatSession(
        participants: allMembers,
        groupName: groupName.value.isNotEmpty ? groupName.value : _generateGroupName(selectedUsersList),
        groupDescription: 'Group chat with ${selectedUsersList.length + 1} members',
      );

      if (!sessionStarted) {
        throw Exception('Failed to start group chat session');
      }

      // Step 3: Initialize ChatService with members
      ChatService.instance.initializeChatDataSource(allMembers);

      // Step 4: Create chat room using ChatService
      final chatRoom = await ChatService.instance.createChatRoom(
        members: allMembers,
        isGroupChat: true,
        groupName: groupName.value.isNotEmpty ? groupName.value : _generateGroupName(selectedUsersList),
        groupDescription: ChatSessionManager.instance.chatDescription,
        customRoomId: ChatSessionManager.instance.roomId,
      );

      if (chatRoom == null) {
        throw Exception('Failed to create group chat room');
      }

      // Step 5: Update chat room with group photo if uploaded
      if (uploadedPhotoUrl != null && uploadedPhotoUrl.isNotEmpty) {
        print('🖼️ Updating chat room with group photo...');
        await ChatService.instance.updateChatRoomInfo(
          roomId: chatRoom.id!,
          groupImageUrl: uploadedPhotoUrl,
        );
        print('✅ Chat room updated with group photo');
      }

      // Step 6: Clear group creation properties
      _clearGroupCreationProperties();

      // Step 7: Navigate to chat screen
      await _navigateToChat(
        roomId: chatRoom.id!,
        members: allMembers,
        isGroupChat: true,
      );

    } catch (e) {
      print('❌ Error creating group chat: $e');
      _showErrorToast('Failed to create group chat. Please try again.');
    } finally {
      isCreatingChat.value = false;
      isLoadingGroupPhoto.value = false;
    }
  }

  /// Navigate to chat screen with proper arguments
  Future<void> _navigateToChat({
    required String roomId,
    required List<SocialMediaUser> members,
    required bool isGroupChat,
  }) async {
    await Get.toNamed(
      Routes.CHAT,
      arguments: {
        'useSessionManager': true,
        'roomId': roomId,
        'members': members,
        'isGroupChat': isGroupChat,
      },
    );
  }

  // =================== USER SELECTION METHODS ===================

  /// Toggle user selection for group chat
  void toggleUserSelection(SocialMediaUser user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  /// Check if user is selected
  bool isUserSelected(SocialMediaUser user) {
    return selectedUsers.contains(user);
  }

  /// Clear all selected users
  void clearUserSelection() {
    selectedUsers.clear();
    _clearGroupCreationProperties();
  }

  /// Get count of selected users
  int get selectedUserCount => selectedUsers.length;

  // =================== SEARCH METHODS ===================

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search query
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
  }

  // =================== VALIDATION METHODS ===================

  /// Validate private chat input
  bool _validatePrivateChatInput(SocialMediaUser otherUser) {
    if (myUser.value?.uid == otherUser.uid) {
      _showErrorToast('Cannot create chat with yourself');
      return false;
    }

    if (otherUser.uid == null || otherUser.uid!.isEmpty) {
      _showErrorToast('Invalid user selected');
      return false;
    }

    return true;
  }

  // =================== UTILITY METHODS ===================

  /// Generate group name from selected users
  String _generateGroupName(List<SocialMediaUser> users) {
    if (users.length <= 3) {
      return users.map((user) => user.fullName?.split(' ').first ?? 'User').join(', ');
    } else {
      return '${users.take(2).map((user) => user.fullName?.split(' ').first ?? 'User').join(', ')} and ${users.length - 2} others';
    }
  }

  /// Clear group creation properties
  void _clearGroupCreationProperties() {
    groupName.value = '';
    groupNameController.clear();
    groupPhotoUrl.value = '';
  }

  /// Show error toast message
  void _showErrorToast(String message) {
    BotToast.showText(
      text: message,
      contentColor: Colors.red,
    );
  }

  // =================== CLEANUP ===================

  @override
  void onClose() {
    searchController.dispose();
    groupNameController.dispose();
    super.onClose();
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    await _loadUsers();
  }

  /// Pick group photo from gallery or camera
  Future<void> pickGroupPhoto() async {
    try {
      // Show loading indicator
      isLoadingGroupPhoto.value = true;

      // Show options for gallery or camera
      final source = await _showImageSourceDialog();

      if (source == null) {
        isLoadingGroupPhoto.value = false;
        return;
      }

      // Pick image based on source
      final XFile? image = await imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        isLoadingGroupPhoto.value = false;
        return;
      }

      // For now, we'll store the file path. In production, you'd upload to Firebase Storage
      // and get a URL back
      groupPhotoUrl.value = image.path;

      isLoadingGroupPhoto.value = false;
      BotToast.showText(text: 'Group photo selected successfully');

    } catch (e) {
      isLoadingGroupPhoto.value = false;
      _showErrorToast('Failed to select group photo: $e');
    }
  }

  /// Show dialog to choose between gallery and camera
  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        title: Text(
          'Select Group Photo',
          style: StylesManager.bold(fontSize: FontSize.large, color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorsManager.primary.withOpacity(0.1),
                child: Icon(Icons.photo_library, color: ColorsManager.primary),
              ),
              title: Text('Gallery', style: StylesManager.medium(fontSize: FontSize.medium)),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorsManager.primary.withOpacity(0.1),
                child: Icon(Icons.camera_alt, color: ColorsManager.primary),
              ),
              title: Text('Camera', style: StylesManager.medium(fontSize: FontSize.medium)),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: StylesManager.medium(fontSize: FontSize.medium, color: ColorsManager.grey),
            ),
          ),
        ],
      ),
    );
  }
}

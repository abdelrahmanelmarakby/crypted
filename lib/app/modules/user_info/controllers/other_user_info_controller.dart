import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/user_info/repositories/user_info_repository.dart';
import 'package:crypted_app/app/modules/user_info/models/user_info_state.dart';
import 'package:crypted_app/app/widgets/custom_bottom_sheets.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/modules/settings_v2/notifications/controllers/notification_settings_controller.dart';
import 'package:crypted_app/app/modules/settings_v2/notifications/widgets/muted_chats_manager.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';

/// Enhanced controller for viewing other user's information
class OtherUserInfoController extends GetxController {
  // Repository for data access (injected for testability)
  late final UserInfoRepository _repository;

  // Reactive state
  final Rx<UserInfoState> state = const UserInfoState(isLoading: true).obs;

  // Stream subscriptions
  StreamSubscription? _userSubscription;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _onlineSubscription;

  // Current user reference
  SocialMediaUser? get currentUser => UserService.currentUserValue;

  /// Create controller with optional repository injection
  OtherUserInfoController({UserInfoRepository? repository}) {
    _repository = repository ?? FirestoreUserInfoRepository();
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _roomSubscription?.cancel();
    _onlineSubscription?.cancel();
    super.onClose();
  }

  /// Load initial data from arguments
  Future<void> _loadInitialData() async {
    try {
      final args = UserInfoArguments.fromMap(Get.arguments);

      // If we have a user object, use it directly
      if (args.user != null) {
        state.value = state.value.copyWith(
          user: args.user,
          roomId: args.roomId,
          isLoading: true,
        );
      }

      // Get user ID from either user object or direct ID
      final userId = args.user?.uid ?? args.userId;
      final roomId = args.roomId;

      if (userId == null) {
        state.value = state.value.copyWith(
          isLoading: false,
          errorMessage: 'No user ID provided',
        );
        return;
      }

      // Load user data if not provided
      if (args.user == null) {
        final user = await _repository.getUserById(userId);
        if (user == null) {
          state.value = state.value.copyWith(
            isLoading: false,
            errorMessage: 'User not found',
          );
          return;
        }
        state.value = state.value.copyWith(user: user);
      }

      // Set up real-time listeners
      _setupUserListener(userId);
      _setupOnlineStatusListener(userId);

      if (roomId != null) {
        state.value = state.value.copyWith(roomId: roomId);
        _setupRoomListener(roomId);
        await _loadRoomData(roomId);
        await _loadMediaCounts(roomId);
      }

      // Load mutual contacts
      if (currentUser != null) {
        await _loadMutualContacts(currentUser!.uid!, userId);
      }

      // Load last seen
      final lastSeen = await _repository.getLastSeen(userId);
      state.value = state.value.copyWith(
        lastSeen: lastSeen,
        isLoading: false,
      );

      developer.log(
        'User info loaded: ${state.value.displayName}',
        name: 'OtherUserInfoController',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error loading user info',
        name: 'OtherUserInfoController',
        error: e,
        stackTrace: stackTrace,
      );
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user information',
      );
    }
  }

  void _setupUserListener(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _repository.watchUser(userId).listen(
      (user) {
        if (user != null) {
          state.value = state.value.copyWith(user: user);
        }
      },
      onError: (error) {
        developer.log(
          'User listener error',
          name: 'OtherUserInfoController',
          error: error,
        );
      },
    );
  }

  void _setupRoomListener(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _repository.watchChatRoom(roomId).listen(
      (room) {
        if (room != null) {
          final blockedUsers = room.blockedUsers ?? [];
          final userId = state.value.user?.uid;
          state.value = state.value.copyWith(
            isBlocked: userId != null && blockedUsers.contains(userId),
            isFavorite: room.isFavorite ?? false,
            isArchived: room.isArchived ?? false,
            isMuted: room.isMuted ?? false,
          );
        }
      },
      onError: (error) {
        developer.log(
          'Room listener error',
          name: 'OtherUserInfoController',
          error: error,
        );
      },
    );
  }

  void _setupOnlineStatusListener(String userId) {
    _onlineSubscription?.cancel();
    _onlineSubscription = _repository.watchOnlineStatus(userId).listen(
      (isOnline) {
        state.value = state.value.copyWith(isOnline: isOnline);
      },
      onError: (error) {
        developer.log(
          'Online status listener error',
          name: 'OtherUserInfoController',
          error: error,
        );
      },
    );
  }

  Future<void> _loadRoomData(String roomId) async {
    final room = await _repository.getChatRoomById(roomId);
    if (room != null) {
      final blockedUsers = room.blockedUsers ?? [];
      final userId = state.value.user?.uid;
      state.value = state.value.copyWith(
        isBlocked: userId != null && blockedUsers.contains(userId),
        isFavorite: room.isFavorite ?? false,
        isArchived: room.isArchived ?? false,
        isMuted: room.isMuted ?? false,
      );
    }
  }

  Future<void> _loadMediaCounts(String roomId) async {
    final counts = await _repository.getSharedMediaCounts(roomId);
    state.value = state.value.copyWith(mediaCounts: counts);
  }

  Future<void> _loadMutualContacts(String userId1, String userId2) async {
    final mutualContacts = await _repository.getMutualContacts(userId1, userId2);
    state.value = state.value.copyWith(mutualContacts: mutualContacts);
  }

  /// Refresh all data
  Future<void> refresh() async {
    state.value = state.value.copyWith(isLoading: true);
    await _loadInitialData();
  }

  /// Toggle block status
  Future<void> toggleBlock() async {
    final roomId = state.value.roomId;
    final userId = state.value.user?.uid;

    if (roomId == null || userId == null) {
      _showError('Cannot block user: Missing data');
      return;
    }

    try {
      if (state.value.isBlocked) {
        // Unblock
        state.value = state.value.copyWith(pendingAction: UserInfoAction.unblocking);
        await _repository.unblockUser(roomId, userId);
        state.value = state.value.copyWith(isBlocked: false, pendingAction: null);
        _showSuccess('User unblocked');
      } else {
        // Show confirmation
        final confirmed = await CustomBottomSheets.showConfirmation(
          title: 'Block User',
          message: 'Are you sure you want to block ${state.value.displayName}?',
          subtitle: 'You won\'t receive messages from this user',
          confirmText: 'Block',
          cancelText: 'Cancel',
          icon: Icons.block,
          isDanger: true,
        );

        if (confirmed == true) {
          state.value = state.value.copyWith(pendingAction: UserInfoAction.blocking);
          await _repository.blockUser(roomId, userId);
          state.value = state.value.copyWith(isBlocked: true, pendingAction: null);
          _showSuccess('User blocked');
        }
      }
    } catch (e) {
      developer.log('Error toggling block', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update block status');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update favorite: Missing room data');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: UserInfoAction.togglingFavorite);
      await _repository.toggleFavorite(roomId);
      state.value = state.value.copyWith(
        isFavorite: !state.value.isFavorite,
        pendingAction: null,
      );
    } catch (e) {
      developer.log('Error toggling favorite', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update favorite status');
    }
  }

  /// Toggle archive status
  Future<void> toggleArchive() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update archive: Missing room data');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: UserInfoAction.togglingArchive);
      await _repository.toggleArchive(roomId);
      state.value = state.value.copyWith(
        isArchived: !state.value.isArchived,
        pendingAction: null,
      );
    } catch (e) {
      developer.log('Error toggling archive', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update archive status');
    }
  }

  /// Toggle mute status
  Future<void> toggleMute() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update mute: Missing room data');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: UserInfoAction.togglingMute);
      await _repository.toggleMute(roomId);
      state.value = state.value.copyWith(
        isMuted: !state.value.isMuted,
        pendingAction: null,
      );
    } catch (e) {
      developer.log('Error toggling mute', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update mute status');
    }
  }

  /// Clear chat with confirmation
  Future<void> clearChat() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot clear chat: Missing room data');
      return;
    }

    final confirmed = await CustomBottomSheets.showConfirmation(
      title: 'Clear Chat',
      message: 'Are you sure you want to clear all messages?',
      subtitle: 'This action cannot be undone',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      icon: Icons.delete_sweep,
      isDanger: true,
    );

    if (confirmed != true) return;

    try {
      state.value = state.value.copyWith(pendingAction: UserInfoAction.clearingChat);
      await _repository.clearChat(roomId);
      state.value = state.value.copyWith(pendingAction: null);
      _showSuccess('Chat cleared');
      Get.back();
    } catch (e) {
      developer.log('Error clearing chat', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to clear chat');
    }
  }

  /// Report user
  Future<void> reportUser() async {
    final userId = state.value.user?.uid;
    if (userId == null || currentUser?.uid == null) {
      _showError('Cannot report user: Missing data');
      return;
    }

    final reason = await CustomBottomSheets.showSelection<String>(
      title: 'Report User',
      subtitle: 'Select a reason for reporting',
      options: [
        SelectionOption(
          title: 'Inappropriate Content',
          subtitle: 'Offensive or inappropriate material',
          icon: Icons.warning,
          iconColor: Colors.orange,
          value: 'inappropriate_content',
        ),
        SelectionOption(
          title: 'Spam',
          subtitle: 'Unwanted or repetitive content',
          icon: Icons.report,
          iconColor: Colors.red,
          value: 'spam',
        ),
        SelectionOption(
          title: 'Harassment',
          subtitle: 'Bullying or harassment',
          icon: Icons.block,
          iconColor: Colors.red,
          value: 'harassment',
        ),
        SelectionOption(
          title: 'Fake Account',
          subtitle: 'Impersonation or fake identity',
          icon: Icons.person_off,
          iconColor: Colors.purple,
          value: 'fake_account',
        ),
        SelectionOption(
          title: 'Other',
          subtitle: 'Other reason',
          icon: Icons.more_horiz,
          iconColor: Colors.grey,
          value: 'other',
        ),
      ],
    );

    if (reason == null) return;

    try {
      state.value = state.value.copyWith(pendingAction: UserInfoAction.reporting);
      await _repository.reportUser(
        reportedUserId: userId,
        reporterId: currentUser!.uid!,
        reason: reason,
      );
      state.value = state.value.copyWith(pendingAction: null);
      _showSuccess('Report submitted');
    } catch (e) {
      developer.log('Error reporting user', name: 'OtherUserInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to submit report');
    }
  }

  /// Navigate to media gallery
  void viewMedia() {
    if (state.value.roomId == null) {
      _showError('Cannot view media: Missing room data');
      return;
    }
    Get.toNamed(Routes.MEDIA_GALLERY, arguments: {'roomId': state.value.roomId});
  }

  /// Navigate to starred messages
  void viewStarredMessages() {
    if (state.value.roomId == null) {
      _showError('Cannot view starred messages: Missing room data');
      return;
    }
    Get.toNamed(Routes.STARRED_MESSAGES, arguments: {'roomId': state.value.roomId});
  }

  /// Start a call with the user
  void startCall({bool isVideo = false}) {
    if (state.value.user == null) {
      _showError('Cannot start call: Missing user data');
      return;
    }
    Get.toNamed(
      Routes.CALL,
      arguments: {
        'user': state.value.user,
        'isVideo': isVideo,
      },
    );
  }

  /// Open chat with user
  void openChat() {
    if (state.value.roomId == null || state.value.user == null) {
      _showError('Cannot open chat: Missing data');
      return;
    }
    Get.offNamed(
      Routes.CHAT,
      arguments: {
        'roomId': state.value.roomId,
        'user': state.value.user,
      },
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  /// Open custom notification settings for this contact
  Future<void> openCustomNotificationSettings(BuildContext context) async {
    final roomId = state.value.roomId;
    final user = state.value.user;

    if (roomId == null || user == null) {
      _showError('Cannot open notification settings: Missing data');
      return;
    }

    // Get current notification override if exists
    ChatNotificationOverride? currentOverride;
    try {
      final notificationController = Get.find<NotificationSettingsController>();
      currentOverride = notificationController.getChatOverride(roomId);
    } catch (e) {
      // Controller not registered, proceed without override
      developer.log(
        'NotificationSettingsController not found',
        name: 'OtherUserInfoController',
      );
    }

    // Show contact notification override sheet
    await ContactNotificationOverride.show(
      context: context,
      contactId: roomId,
      contactName: user.fullName ?? 'User',
      contactImageUrl: user.imageUrl,
      currentOverride: currentOverride,
      onSave: (newOverride) async {
        try {
          final notificationController = Get.find<NotificationSettingsController>();
          if (newOverride != null) {
            await notificationController.setChatOverride(newOverride);
            state.value = state.value.copyWith(hasCustomNotifications: true);
            _showSuccess('Custom notifications saved');
          } else {
            await notificationController.removeChatOverride(roomId);
            state.value = state.value.copyWith(hasCustomNotifications: false);
            _showSuccess('Using default notifications');
          }
        } catch (e) {
          developer.log(
            'Error saving notification override',
            name: 'OtherUserInfoController',
            error: e,
          );
          _showError('Failed to save notification settings');
        }
      },
    );
  }
}

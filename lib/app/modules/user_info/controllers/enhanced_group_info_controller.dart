import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/user_info/repositories/group_info_repository.dart';
import 'package:crypted_app/app/modules/user_info/models/group_info_state.dart';
import 'package:crypted_app/app/widgets/custom_bottom_sheets.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Enhanced controller for group information screen
class EnhancedGroupInfoController extends GetxController {
  // Repository for data access
  late final GroupInfoRepository _repository;

  // Reactive state
  final Rx<GroupInfoState> state = const GroupInfoState(isLoading: true).obs;

  // Stream subscriptions
  StreamSubscription? _groupSubscription;

  // Current user reference
  SocialMediaUser? get currentUser => UserService.currentUserValue;

  /// Check if current user is admin
  bool get isCurrentUserAdmin => state.value.isUserAdmin(currentUser?.uid);

  /// Create controller with optional repository injection
  EnhancedGroupInfoController({GroupInfoRepository? repository}) {
    _repository = repository ?? FirestoreGroupInfoRepository();
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    _groupSubscription?.cancel();
    super.onClose();
  }

  /// Load initial data from arguments
  Future<void> _loadInitialData() async {
    try {
      final args = GroupInfoArguments.fromMap(Get.arguments);

      String? roomId = args.roomId ?? args.group?.id;

      if (roomId == null) {
        state.value = state.value.copyWith(
          isLoading: false,
          errorMessage: 'No group ID provided',
        );
        return;
      }

      // Use passed members if available
      if (args.members != null) {
        state.value = state.value.copyWith(members: args.members);
      }

      // Set up real-time listener
      _setupGroupListener(roomId);

      // Load group data
      final group = await _repository.getGroupById(roomId);
      if (group == null) {
        state.value = state.value.copyWith(
          isLoading: false,
          errorMessage: 'Group not found',
        );
        return;
      }

      state.value = state.value.copyWith(
        group: group,
        isFavorite: group.isFavorite ?? false,
        isMuted: group.isMuted ?? false,
      );

      // Load members if not provided
      if (args.members == null && group.membersIds != null) {
        final members = await _repository.getGroupMembers(group.membersIds!);
        state.value = state.value.copyWith(members: members);
      }

      // Load admins
      final admins = await _repository.getGroupAdmins(roomId);
      state.value = state.value.copyWith(admins: admins);

      // Load media counts
      final mediaCounts = await _repository.getSharedMediaCounts(roomId);
      state.value = state.value.copyWith(
        mediaCounts: mediaCounts,
        isLoading: false,
      );

      developer.log(
        'Group info loaded: ${state.value.name}',
        name: 'EnhancedGroupInfoController',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error loading group info',
        name: 'EnhancedGroupInfoController',
        error: e,
        stackTrace: stackTrace,
      );
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load group information',
      );
    }
  }

  void _setupGroupListener(String roomId) {
    _groupSubscription?.cancel();
    _groupSubscription = _repository.watchGroup(roomId).listen(
      (group) {
        if (group != null) {
          state.value = state.value.copyWith(
            group: group,
            isFavorite: group.isFavorite ?? false,
            isMuted: group.isMuted ?? false,
          );
        }
      },
      onError: (error) {
        developer.log(
          'Group listener error',
          name: 'EnhancedGroupInfoController',
          error: error,
        );
      },
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    state.value = state.value.copyWith(isLoading: true);
    await _loadInitialData();
  }

  /// Update group info
  Future<void> updateGroupInfo({String? name, String? description, String? imageUrl}) async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update: Missing group data');
      return;
    }

    if (!isCurrentUserAdmin) {
      _showError('Only admins can update group info');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.updatingInfo);
      await _repository.updateGroupInfo(
        roomId: roomId,
        name: name,
        description: description,
        imageUrl: imageUrl,
      );
      state.value = state.value.copyWith(pendingAction: null);
      _showSuccess('Group info updated');
    } catch (e) {
      developer.log('Error updating group info', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update group info');
    }
  }

  /// Show edit group dialog
  void showEditGroupDialog() {
    if (!isCurrentUserAdmin) {
      _showError('Only admins can edit group info');
      return;
    }

    final nameController = TextEditingController(text: state.value.name);
    final descController = TextEditingController(text: state.value.description);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter group description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              updateGroupInfo(
                name: nameController.text.trim(),
                description: descController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Add member to group
  Future<void> addMember(SocialMediaUser member) async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot add member: Missing group data');
      return;
    }

    if (!isCurrentUserAdmin) {
      _showError('Only admins can add members');
      return;
    }

    // Check if already a member
    if (state.value.members.any((m) => m.uid == member.uid)) {
      _showError('${member.fullName} is already a member');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.addingMember);
      await _repository.addMember(roomId, member);

      // Update local state
      final updatedMembers = [...state.value.members, member];
      state.value = state.value.copyWith(
        members: updatedMembers,
        pendingAction: null,
      );
      _showSuccess('${member.fullName} added to group');
    } catch (e) {
      developer.log('Error adding member', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to add member');
    }
  }

  /// Remove member from group
  Future<void> removeMember(String memberId) async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot remove member: Missing group data');
      return;
    }

    if (!isCurrentUserAdmin) {
      _showError('Only admins can remove members');
      return;
    }

    // Can't remove yourself
    if (memberId == currentUser?.uid) {
      _showError('You cannot remove yourself. Use "Leave Group" instead.');
      return;
    }

    final member = state.value.members.firstWhereOrNull((m) => m.uid == memberId);
    if (member == null) return;

    final confirmed = await CustomBottomSheets.showConfirmation(
      title: 'Remove Member',
      message: 'Are you sure you want to remove ${member.fullName}?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      icon: Icons.person_remove,
      isDanger: true,
    );

    if (confirmed != true) return;

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.removingMember);
      await _repository.removeMember(roomId, memberId);

      // Update local state
      final updatedMembers = state.value.members.where((m) => m.uid != memberId).toList();
      state.value = state.value.copyWith(
        members: updatedMembers,
        pendingAction: null,
      );
      _showSuccess('${member.fullName} removed from group');
    } catch (e) {
      developer.log('Error removing member', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to remove member');
    }
  }

  /// Leave group
  Future<void> leaveGroup() async {
    final roomId = state.value.roomId;
    final userId = currentUser?.uid;

    if (roomId == null || userId == null) {
      _showError('Cannot leave group: Missing data');
      return;
    }

    final confirmed = await CustomBottomSheets.showConfirmation(
      title: 'Leave Group',
      message: 'Are you sure you want to leave ${state.value.name}?',
      subtitle: 'You will no longer receive messages from this group',
      confirmText: 'Leave',
      cancelText: 'Cancel',
      icon: Icons.exit_to_app,
      isDanger: true,
    );

    if (confirmed != true) return;

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.leaving);
      await _repository.leaveGroup(roomId, userId);
      state.value = state.value.copyWith(pendingAction: null);

      // Navigate back to chat list
      Get.until((route) => route.settings.name == Routes.HOME);
    } catch (e) {
      developer.log('Error leaving group', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to leave group');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update favorite: Missing group data');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.togglingFavorite);
      await _repository.toggleFavorite(roomId);
      state.value = state.value.copyWith(
        isFavorite: !state.value.isFavorite,
        pendingAction: null,
      );
    } catch (e) {
      developer.log('Error toggling favorite', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update favorite status');
    }
  }

  /// Toggle mute status
  Future<void> toggleMute() async {
    final roomId = state.value.roomId;
    if (roomId == null) {
      _showError('Cannot update mute: Missing group data');
      return;
    }

    try {
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.togglingMute);
      await _repository.toggleMute(roomId);
      state.value = state.value.copyWith(
        isMuted: !state.value.isMuted,
        pendingAction: null,
      );
    } catch (e) {
      developer.log('Error toggling mute', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to update mute status');
    }
  }

  /// Report group
  Future<void> reportGroup() async {
    final roomId = state.value.roomId;
    if (roomId == null || currentUser?.uid == null) {
      _showError('Cannot report group: Missing data');
      return;
    }

    final reason = await CustomBottomSheets.showSelection<String>(
      title: 'Report Group',
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
      state.value = state.value.copyWith(pendingAction: GroupInfoAction.reporting);
      await _repository.reportGroup(
        groupId: roomId,
        reporterId: currentUser!.uid!,
        reason: reason,
      );
      state.value = state.value.copyWith(pendingAction: null);
      _showSuccess('Report submitted');
    } catch (e) {
      developer.log('Error reporting group', name: 'EnhancedGroupInfoController', error: e);
      state.value = state.value.copyWith(pendingAction: null);
      _showError('Failed to submit report');
    }
  }

  /// Navigate to media gallery
  void viewMedia() {
    if (state.value.roomId == null) {
      _showError('Cannot view media: Missing group data');
      return;
    }
    Get.toNamed(Routes.MEDIA_GALLERY, arguments: {'roomId': state.value.roomId});
  }

  /// Navigate to starred messages
  void viewStarredMessages() {
    if (state.value.roomId == null) {
      _showError('Cannot view starred messages: Missing group data');
      return;
    }
    Get.toNamed(Routes.STARRED_MESSAGES, arguments: {'roomId': state.value.roomId});
  }

  /// Navigate to add members screen
  void navigateToAddMembers() {
    if (!isCurrentUserAdmin) {
      _showError('Only admins can add members');
      return;
    }
    // Navigate to contacts picker
    Get.toNamed(Routes.ADD_GROUP_MEMBERS, arguments: {
      'existingMembers': state.value.members.map((m) => m.uid).toList(),
      'onMembersSelected': (List<SocialMediaUser> selected) async {
        for (final member in selected) {
          await addMember(member);
        }
      },
    });
  }

  /// View member profile
  void viewMemberProfile(SocialMediaUser member) {
    if (member.uid == currentUser?.uid) return;

    Get.toNamed(Routes.OTHER_USER_INFO, arguments: {
      'user': member,
    });
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
}

import 'package:crypted_app/app/core/di/chat_architecture_bindings.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/app/domain/usecases/group/group_member_usecases.dart';
import 'package:crypted_app/app/domain/usecases/group/group_info_usecases.dart';
import 'package:crypted_app/app/modules/chat/services/group_orchestration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Mixin to add group architecture support to ChatController
///
/// This mixin provides:
/// 1. GroupOrchestrationService integration
/// 2. Methods for member management (add, remove, promote, demote)
/// 3. Methods for group info updates (name, description, image)
/// 4. Reactive group state for UI binding
///
/// Usage:
/// ```dart
/// class ChatController extends GetxController with GroupArchitectureMixin {
///   @override
///   void onInit() {
///     super.onInit();
///     initializeGroupMixin(groupId, currentUserId);
///   }
/// }
/// ```
mixin GroupArchitectureMixin on GetxController {
  /// The group orchestration service
  GroupOrchestrationService? _groupService;

  /// Current user ID for permission checks
  String? _groupUserId;

  /// Whether group architecture is enabled and ready
  bool get isGroupArchitectureEnabled =>
      ChatArchitectureConfig.shouldUseNewArchitecture && _groupService != null;

  /// Reactive group info for UI binding
  Rx<GroupInfo?> get currentGroupInfo =>
      _groupService?.currentGroupInfo ?? Rx<GroupInfo?>(null);

  /// Loading state for group operations
  RxBool get isGroupLoading => _groupService?.isLoading ?? false.obs;

  /// Last group operation error
  final RxnString lastGroupError = RxnString(null);

  // =================== Initialization ===================

  /// Initialize the group architecture mixin
  ///
  /// Call this from onInit() for group chats only.
  void initializeGroupMixin(String groupId, String currentUserId) {
    _groupUserId = currentUserId;

    // Ensure bindings are registered
    NewArchitectureBindings().dependencies();

    // Create orchestration service with all use cases
    _groupService = GroupOrchestrationService(
      addMemberUseCase: Get.find<AddMemberUseCase>(),
      addMembersUseCase: Get.find<AddMembersUseCase>(),
      removeMemberUseCase: Get.find<RemoveMemberUseCase>(),
      leaveGroupUseCase: Get.find<LeaveGroupUseCase>(),
      makeAdminUseCase: Get.find<MakeAdminUseCase>(),
      removeAdminUseCase: Get.find<RemoveAdminUseCase>(),
      updateGroupNameUseCase: Get.find<UpdateGroupNameUseCase>(),
      updateGroupDescriptionUseCase: Get.find<UpdateGroupDescriptionUseCase>(),
      updateGroupImageUseCase: Get.find<UpdateGroupImageUseCase>(),
      updateGroupPermissionsUseCase: Get.find<UpdateGroupPermissionsUseCase>(),
      getGroupInfoUseCase: Get.find<GetGroupInfoUseCase>(),
      transferOwnershipUseCase: Get.find<TransferOwnershipUseCase>(),
      eventBus: Get.find<EventBus>(),
    );

    // Initialize for this group
    _groupService!.initialize(groupId);

    if (kDebugMode) {
      print('🔧 GroupArchitectureMixin initialized');
      print('   - Group ID: $groupId');
      print('   - Feature enabled: ${ChatArchitectureConfig.shouldUseNewArchitecture}');
    }
  }

  // =================== Member Operations ===================

  /// Add a single member to the group
  Future<MemberOperationResult?> addMemberWithNewArchitecture({
    required SocialMediaUser member,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.addMember(
      member: member,
      addedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (opResult) {
        if (kDebugMode) {
          print('✅ Member added: ${opResult.memberName}');
        }
        return opResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Add member failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Add multiple members to the group
  Future<List<MemberOperationResult>?> addMembersWithNewArchitecture({
    required List<SocialMediaUser> members,
    void Function(int successCount, int failedCount)? onComplete,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.addMembers(
      members: members,
      addedByUserId: _groupUserId!,
      onComplete: onComplete,
    );

    return result.fold(
      onSuccess: (results) {
        if (kDebugMode) {
          final successCount = results.where((r) => r.success).length;
          print('✅ Members added: $successCount/${results.length}');
        }
        return results;
      },
      onFailure: (error) {
        lastGroupError.value = error.message;
        if (kDebugMode) {
          print('❌ Add members failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Remove a member from the group
  Future<MemberOperationResult?> removeMemberWithNewArchitecture({
    required String memberId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.removeMember(
      memberId: memberId,
      removedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (opResult) {
        if (kDebugMode) {
          print('✅ Member removed: ${opResult.memberName}');
        }
        return opResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Remove member failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Leave the group
  Future<bool> leaveGroupWithNewArchitecture({
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return false;
    }

    lastGroupError.value = null;

    final result = await _groupService!.leaveGroup(
      userId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Left group');
        }
        return true;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Leave group failed: ${error.message}');
        }
        return false;
      },
    );
  }

  // =================== Admin Operations ===================

  /// Promote a member to admin
  Future<bool> makeAdminWithNewArchitecture({
    required String memberId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return false;
    }

    lastGroupError.value = null;

    final result = await _groupService!.makeAdmin(
      memberId: memberId,
      promotedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Made admin: $memberId');
        }
        return true;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Make admin failed: ${error.message}');
        }
        return false;
      },
    );
  }

  /// Demote an admin to regular member
  Future<bool> removeAdminWithNewArchitecture({
    required String memberId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return false;
    }

    lastGroupError.value = null;

    final result = await _groupService!.removeAdmin(
      memberId: memberId,
      demotedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Removed admin: $memberId');
        }
        return true;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Remove admin failed: ${error.message}');
        }
        return false;
      },
    );
  }

  /// Transfer group ownership
  Future<bool> transferOwnershipWithNewArchitecture({
    required String newOwnerId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return false;
    }

    lastGroupError.value = null;

    final result = await _groupService!.transferOwnership(
      newOwnerId: newOwnerId,
      currentOwnerId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Ownership transferred to: $newOwnerId');
        }
        return true;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Transfer ownership failed: ${error.message}');
        }
        return false;
      },
    );
  }

  // =================== Group Info Operations ===================

  /// Update group name
  Future<GroupUpdateResult?> updateGroupNameWithNewArchitecture({
    required String newName,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.updateGroupName(
      newName: newName,
      updatedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (updateResult) {
        if (kDebugMode) {
          print('✅ Group name updated: $newName');
        }
        return updateResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Update name failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Update group description
  Future<GroupUpdateResult?> updateGroupDescriptionWithNewArchitecture({
    required String newDescription,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.updateGroupDescription(
      newDescription: newDescription,
      updatedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (updateResult) {
        if (kDebugMode) {
          print('✅ Group description updated');
        }
        return updateResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Update description failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Update group image
  Future<GroupUpdateResult?> updateGroupImageWithNewArchitecture({
    required String imagePath,
    void Function(String newImageUrl)? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return null;
    }

    lastGroupError.value = null;

    final result = await _groupService!.updateGroupImage(
      imagePath: imagePath,
      updatedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (updateResult) {
        if (kDebugMode) {
          print('✅ Group image updated: ${updateResult.newImageUrl}');
        }
        return updateResult;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Update image failed: ${error.message}');
        }
        return null;
      },
    );
  }

  /// Update group permissions
  Future<bool> updatePermissionsWithNewArchitecture({
    required GroupPermissions permissions,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (!isGroupArchitectureEnabled || _groupUserId == null) {
      onError?.call('Group architecture not initialized');
      return false;
    }

    lastGroupError.value = null;

    final result = await _groupService!.updatePermissions(
      permissions: permissions,
      updatedByUserId: _groupUserId!,
      onSuccess: onSuccess,
      onError: (error) {
        lastGroupError.value = error;
        onError?.call(error);
      },
    );

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Permissions updated');
        }
        return true;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Update permissions failed: ${error.message}');
        }
        return false;
      },
    );
  }

  // =================== Helper Methods ===================

  /// Check if current user is an admin (via new architecture)
  bool get isCurrentUserAdminViaNewArch =>
      _groupUserId != null && _groupService?.isUserAdmin(_groupUserId!) == true;

  /// Check if current user is the creator (via new architecture)
  bool get isCurrentUserCreatorViaNewArch =>
      _groupUserId != null && _groupService?.isUserCreator(_groupUserId!) == true;

  /// Check if a user is an admin
  bool isUserAdminViaNewArch(String userId) => _groupService?.isUserAdmin(userId) ?? false;

  /// Check if a user is the creator
  bool isUserCreatorViaNewArch(String userId) => _groupService?.isUserCreator(userId) ?? false;

  /// Get member count from service
  int get groupServiceMemberCount => _groupService?.memberCount ?? 0;

  /// Get admin count from service
  int get groupServiceAdminCount => _groupService?.adminCount ?? 0;

  /// Refresh group info
  Future<void> refreshGroupInfo() async {
    await _groupService?.loadGroupInfo();
  }

  // =================== Cleanup ===================

  /// Dispose the group architecture resources
  void disposeGroupMixin() {
    _groupService?.dispose();
    _groupService = null;
    _groupUserId = null;

    if (kDebugMode) {
      print('🧹 GroupArchitectureMixin disposed');
    }
  }
}

import 'dart:async';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/app/domain/usecases/group/group_member_usecases.dart';
import 'package:crypted_app/app/domain/usecases/group/group_info_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Orchestration service for group management operations
///
/// This service provides:
/// 1. Unified interface for all group operations
/// 2. Optimistic UI updates with rollback
/// 3. Event subscription for real-time updates
/// 4. State management coordination
class GroupOrchestrationService {
  // Use Cases
  final AddMemberUseCase _addMemberUseCase;
  final AddMembersUseCase _addMembersUseCase;
  final RemoveMemberUseCase _removeMemberUseCase;
  final LeaveGroupUseCase _leaveGroupUseCase;
  final MakeAdminUseCase _makeAdminUseCase;
  final RemoveAdminUseCase _removeAdminUseCase;
  final UpdateGroupNameUseCase _updateGroupNameUseCase;
  final UpdateGroupDescriptionUseCase _updateGroupDescriptionUseCase;
  final UpdateGroupImageUseCase _updateGroupImageUseCase;
  final UpdateGroupPermissionsUseCase _updateGroupPermissionsUseCase;
  final GetGroupInfoUseCase _getGroupInfoUseCase;
  final TransferOwnershipUseCase _transferOwnershipUseCase;

  final EventBus _eventBus;

  /// Subscriptions to event bus
  final List<StreamSubscription> _subscriptions = [];

  /// Reactive group info for UI binding
  final Rx<GroupInfo?> currentGroupInfo = Rx<GroupInfo?>(null);

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Current group ID
  String? _groupId;

  GroupOrchestrationService({
    required AddMemberUseCase addMemberUseCase,
    required AddMembersUseCase addMembersUseCase,
    required RemoveMemberUseCase removeMemberUseCase,
    required LeaveGroupUseCase leaveGroupUseCase,
    required MakeAdminUseCase makeAdminUseCase,
    required RemoveAdminUseCase removeAdminUseCase,
    required UpdateGroupNameUseCase updateGroupNameUseCase,
    required UpdateGroupDescriptionUseCase updateGroupDescriptionUseCase,
    required UpdateGroupImageUseCase updateGroupImageUseCase,
    required UpdateGroupPermissionsUseCase updateGroupPermissionsUseCase,
    required GetGroupInfoUseCase getGroupInfoUseCase,
    required TransferOwnershipUseCase transferOwnershipUseCase,
    required EventBus eventBus,
  })  : _addMemberUseCase = addMemberUseCase,
        _addMembersUseCase = addMembersUseCase,
        _removeMemberUseCase = removeMemberUseCase,
        _leaveGroupUseCase = leaveGroupUseCase,
        _makeAdminUseCase = makeAdminUseCase,
        _removeAdminUseCase = removeAdminUseCase,
        _updateGroupNameUseCase = updateGroupNameUseCase,
        _updateGroupDescriptionUseCase = updateGroupDescriptionUseCase,
        _updateGroupImageUseCase = updateGroupImageUseCase,
        _updateGroupPermissionsUseCase = updateGroupPermissionsUseCase,
        _getGroupInfoUseCase = getGroupInfoUseCase,
        _transferOwnershipUseCase = transferOwnershipUseCase,
        _eventBus = eventBus {
    _setupEventListeners();
  }

  /// Initialize for a specific group
  void initialize(String groupId) {
    _groupId = groupId;
    loadGroupInfo();
  }

  /// Setup event listeners to keep state in sync
  void _setupEventListeners() {
    // Listen for member changes
    _subscriptions.add(
      _eventBus.on<GroupMemberAddedEvent>((event) {
        if (event.roomId == _groupId) {
          loadGroupInfo(); // Refresh state
        }
      }),
    );

    _subscriptions.add(
      _eventBus.on<GroupMemberRemovedEvent>((event) {
        if (event.roomId == _groupId) {
          loadGroupInfo();
        }
      }),
    );

    _subscriptions.add(
      _eventBus.on<GroupMemberLeftEvent>((event) {
        if (event.roomId == _groupId) {
          loadGroupInfo();
        }
      }),
    );

    // Listen for admin changes
    _subscriptions.add(
      _eventBus.on<GroupAdminChangedEvent>((event) {
        if (event.roomId == _groupId) {
          loadGroupInfo();
        }
      }),
    );

    // Listen for info updates
    _subscriptions.add(
      _eventBus.on<GroupInfoUpdatedEvent>((event) {
        if (event.roomId == _groupId) {
          loadGroupInfo();
        }
      }),
    );
  }

  // =================== Group Info ===================

  /// Load current group info
  Future<void> loadGroupInfo() async {
    if (_groupId == null) return;

    isLoading.value = true;

    final result = await _getGroupInfoUseCase.call(
      GetGroupInfoParams(groupId: _groupId!),
    );

    result.fold(
      onSuccess: (info) {
        currentGroupInfo.value = info;
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Error loading group info: ${error.message}');
        }
      },
    );

    isLoading.value = false;
  }

  // =================== Member Operations ===================

  /// Add a single member to the group
  Future<Result<MemberOperationResult, RepositoryError>> addMember({
    required SocialMediaUser member,
    required String addedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    isLoading.value = true;

    final result = await _addMemberUseCase.call(AddMemberParams(
      groupId: _groupId!,
      member: member,
      addedByUserId: addedByUserId,
    ));

    isLoading.value = false;

    return result.fold(
      onSuccess: (opResult) {
        if (kDebugMode) {
          print('✅ Member added: ${opResult.memberName}');
        }
        onSuccess?.call();
        return Result<MemberOperationResult, RepositoryError>.success(opResult);
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Error adding member: ${error.message}');
        }
        onError?.call(error.message);
        return Result<MemberOperationResult, RepositoryError>.failure(error);
      },
    );
  }

  /// Add multiple members to the group
  Future<Result<List<MemberOperationResult>, RepositoryError>> addMembers({
    required List<SocialMediaUser> members,
    required String addedByUserId,
    void Function(int successCount, int failedCount)? onComplete,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    isLoading.value = true;

    final result = await _addMembersUseCase.call(AddMembersParams(
      groupId: _groupId!,
      members: members,
      addedByUserId: addedByUserId,
    ));

    isLoading.value = false;

    return result.fold(
      onSuccess: (results) {
        final successCount = results.where((r) => r.success).length;
        final failedCount = results.length - successCount;
        onComplete?.call(successCount, failedCount);
        return Result<List<MemberOperationResult>, RepositoryError>.success(results);
      },
      onFailure: (error) {
        return Result<List<MemberOperationResult>, RepositoryError>.failure(error);
      },
    );
  }

  /// Remove a member from the group
  Future<Result<MemberOperationResult, RepositoryError>> removeMember({
    required String memberId,
    required String removedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    isLoading.value = true;

    final result = await _removeMemberUseCase.call(RemoveMemberParams(
      groupId: _groupId!,
      memberId: memberId,
      removedByUserId: removedByUserId,
    ));

    isLoading.value = false;

    return result.fold(
      onSuccess: (opResult) {
        if (kDebugMode) {
          print('✅ Member removed: ${opResult.memberName}');
        }
        onSuccess?.call();
        return Result<MemberOperationResult, RepositoryError>.success(opResult);
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Error removing member: ${error.message}');
        }
        onError?.call(error.message);
        return Result<MemberOperationResult, RepositoryError>.failure(error);
      },
    );
  }

  /// Leave the group
  Future<Result<void, RepositoryError>> leaveGroup({
    required String userId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    isLoading.value = true;

    final result = await _leaveGroupUseCase.call(LeaveGroupParams(
      groupId: _groupId!,
      userId: userId,
    ));

    isLoading.value = false;

    return result.fold(
      onSuccess: (_) {
        if (kDebugMode) {
          print('✅ Left group');
        }
        onSuccess?.call();
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        if (kDebugMode) {
          print('❌ Error leaving group: ${error.message}');
        }
        onError?.call(error.message);
        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Admin Operations ===================

  /// Promote a member to admin
  Future<Result<void, RepositoryError>> makeAdmin({
    required String memberId,
    required String promotedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _makeAdminUseCase.call(MakeAdminParams(
      groupId: _groupId!,
      memberId: memberId,
      promotedByUserId: promotedByUserId,
    ));

    return result.fold(
      onSuccess: (_) {
        onSuccess?.call();
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  /// Demote an admin to regular member
  Future<Result<void, RepositoryError>> removeAdmin({
    required String memberId,
    required String demotedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _removeAdminUseCase.call(RemoveAdminParams(
      groupId: _groupId!,
      memberId: memberId,
      demotedByUserId: demotedByUserId,
    ));

    return result.fold(
      onSuccess: (_) {
        onSuccess?.call();
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  /// Transfer group ownership
  Future<Result<void, RepositoryError>> transferOwnership({
    required String newOwnerId,
    required String currentOwnerId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _transferOwnershipUseCase.call(TransferOwnershipParams(
      groupId: _groupId!,
      newOwnerId: newOwnerId,
      currentOwnerId: currentOwnerId,
    ));

    return result.fold(
      onSuccess: (_) {
        onSuccess?.call();
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Group Info Updates ===================

  /// Update group name
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupName({
    required String newName,
    required String updatedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _updateGroupNameUseCase.call(UpdateGroupNameParams(
      groupId: _groupId!,
      newName: newName,
      updatedByUserId: updatedByUserId,
    ));

    return result.fold(
      onSuccess: (updateResult) {
        onSuccess?.call();
        return Result<GroupUpdateResult, RepositoryError>.success(updateResult);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<GroupUpdateResult, RepositoryError>.failure(error);
      },
    );
  }

  /// Update group description
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupDescription({
    required String newDescription,
    required String updatedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _updateGroupDescriptionUseCase.call(
      UpdateGroupDescriptionParams(
        groupId: _groupId!,
        newDescription: newDescription,
        updatedByUserId: updatedByUserId,
      ),
    );

    return result.fold(
      onSuccess: (updateResult) {
        onSuccess?.call();
        return Result<GroupUpdateResult, RepositoryError>.success(updateResult);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<GroupUpdateResult, RepositoryError>.failure(error);
      },
    );
  }

  /// Update group image
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupImage({
    required String imagePath,
    required String updatedByUserId,
    void Function(String newImageUrl)? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    isLoading.value = true;

    final result = await _updateGroupImageUseCase.call(UpdateGroupImageParams(
      groupId: _groupId!,
      imagePath: imagePath,
      updatedByUserId: updatedByUserId,
    ));

    isLoading.value = false;

    return result.fold(
      onSuccess: (updateResult) {
        onSuccess?.call(updateResult.newImageUrl ?? '');
        return Result<GroupUpdateResult, RepositoryError>.success(updateResult);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<GroupUpdateResult, RepositoryError>.failure(error);
      },
    );
  }

  /// Update group permissions
  Future<Result<void, RepositoryError>> updatePermissions({
    required GroupPermissions permissions,
    required String updatedByUserId,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (_groupId == null) {
      return Result.failure(RepositoryError.validation('Group not initialized'));
    }

    final result = await _updateGroupPermissionsUseCase.call(
      UpdateGroupPermissionsParams(
        groupId: _groupId!,
        permissions: permissions,
        updatedByUserId: updatedByUserId,
      ),
    );

    return result.fold(
      onSuccess: (_) {
        onSuccess?.call();
        return Result<void, RepositoryError>.success(null);
      },
      onFailure: (error) {
        onError?.call(error.message);
        return Result<void, RepositoryError>.failure(error);
      },
    );
  }

  // =================== Helpers ===================

  /// Check if a user is an admin of the current group
  bool isUserAdmin(String userId) {
    return currentGroupInfo.value?.isUserAdmin(userId) ?? false;
  }

  /// Check if a user is the creator of the current group
  bool isUserCreator(String userId) {
    return currentGroupInfo.value?.isUserCreator(userId) ?? false;
  }

  /// Get member count
  int get memberCount => currentGroupInfo.value?.memberCount ?? 0;

  /// Get admin count
  int get adminCount => currentGroupInfo.value?.adminIds.length ?? 0;

  // =================== Cleanup ===================

  /// Dispose resources
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    currentGroupInfo.value = null;
    _groupId = null;

    if (kDebugMode) {
      print('🧹 GroupOrchestrationService disposed');
    }
  }
}

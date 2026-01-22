import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

// =================== Add Member Use Case ===================

/// Parameters for AddMemberUseCase
class AddMemberParams extends UseCaseParams {
  final String groupId;
  final SocialMediaUser member;
  final String addedByUserId;

  AddMemberParams({
    required this.groupId,
    required this.member,
    required this.addedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (member.uid == null || member.uid!.isEmpty) {
      return 'Member ID is required';
    }

    if (addedByUserId.isEmpty) {
      return 'Added by user ID is required';
    }

    // Cannot add yourself
    if (member.uid == addedByUserId) {
      return 'Cannot add yourself to the group';
    }

    return null;
  }
}

/// Use case for adding a member to a group
///
/// Responsibilities:
/// - Validate member data
/// - Check permissions
/// - Verify member limits
/// - Delegate to repository
class AddMemberUseCase
    implements UseCase<MemberOperationResult, AddMemberParams> {
  final IGroupRepository _repository;

  AddMemberUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<MemberOperationResult, RepositoryError>> call(
    AddMemberParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.addedByUserId,
      action: GroupAction.addMember,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('add members to this group'),
      );
    }

    // 3. Check member limit
    final members = await _repository.getMembers(params.groupId);
    if (members.isSuccess) {
      if (members.dataOrNull!.length >= kMaxGroupMembers) {
        return Result.failure(
          RepositoryError.validation(
            'Group has reached maximum member limit ($kMaxGroupMembers)',
          ),
        );
      }

      // Check if already a member
      final alreadyMember =
          members.dataOrNull!.any((m) => m.id == params.member.uid);
      if (alreadyMember) {
        return Result.failure(
          RepositoryError.conflict('Member'),
        );
      }
    }

    // 4. Delegate to repository
    return _repository.addMember(
      groupId: params.groupId,
      member: params.member,
      addedByUserId: params.addedByUserId,
    );
  }
}

// =================== Add Multiple Members Use Case ===================

/// Parameters for AddMembersUseCase
class AddMembersParams extends UseCaseParams {
  final String groupId;
  final List<SocialMediaUser> members;
  final String addedByUserId;

  AddMembersParams({
    required this.groupId,
    required this.members,
    required this.addedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (members.isEmpty) {
      return 'At least one member is required';
    }

    if (members.length > 20) {
      return 'Cannot add more than 20 members at once';
    }

    if (addedByUserId.isEmpty) {
      return 'Added by user ID is required';
    }

    // Validate each member
    for (final member in members) {
      if (member.uid == null || member.uid!.isEmpty) {
        return 'All members must have valid IDs';
      }
      if (member.uid == addedByUserId) {
        return 'Cannot add yourself to the group';
      }
    }

    return null;
  }
}

/// Use case for adding multiple members to a group
class AddMembersUseCase
    implements UseCase<List<MemberOperationResult>, AddMembersParams> {
  final IGroupRepository _repository;

  AddMembersUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<List<MemberOperationResult>, RepositoryError>> call(
    AddMembersParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.addedByUserId,
      action: GroupAction.addMember,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('add members to this group'),
      );
    }

    // 3. Check member limit
    final currentMembers = await _repository.getMembers(params.groupId);
    if (currentMembers.isSuccess) {
      final totalAfterAdd =
          currentMembers.dataOrNull!.length + params.members.length;
      if (totalAfterAdd > kMaxGroupMembers) {
        return Result.failure(
          RepositoryError.validation(
            'Adding ${params.members.length} members would exceed limit ($kMaxGroupMembers)',
          ),
        );
      }
    }

    // 4. Delegate to repository
    return _repository.addMembers(
      groupId: params.groupId,
      members: params.members,
      addedByUserId: params.addedByUserId,
    );
  }
}

// =================== Remove Member Use Case ===================

/// Parameters for RemoveMemberUseCase
class RemoveMemberParams extends UseCaseParams {
  final String groupId;
  final String memberId;
  final String removedByUserId;

  RemoveMemberParams({
    required this.groupId,
    required this.memberId,
    required this.removedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (memberId.isEmpty) {
      return 'Member ID is required';
    }

    if (removedByUserId.isEmpty) {
      return 'Removed by user ID is required';
    }

    return null;
  }
}

/// Use case for removing a member from a group
class RemoveMemberUseCase
    implements UseCase<MemberOperationResult, RemoveMemberParams> {
  final IGroupRepository _repository;

  RemoveMemberUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<MemberOperationResult, RepositoryError>> call(
    RemoveMemberParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.removedByUserId,
      action: GroupAction.removeMember,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('remove members from this group'),
      );
    }

    // 3. Check if trying to remove the creator
    final groupInfo = await _repository.getGroupInfo(params.groupId);
    if (groupInfo.isSuccess) {
      if (groupInfo.dataOrNull!.createdBy == params.memberId) {
        return Result.failure(
          RepositoryError.validation('Cannot remove the group creator'),
        );
      }

      // Check minimum members
      if (groupInfo.dataOrNull!.memberCount <= kMinGroupMembers) {
        return Result.failure(
          RepositoryError.validation('Group must have at least one member'),
        );
      }
    }

    // 4. Delegate to repository
    return _repository.removeMember(
      groupId: params.groupId,
      memberId: params.memberId,
      removedByUserId: params.removedByUserId,
    );
  }
}

// =================== Leave Group Use Case ===================

/// Parameters for LeaveGroupUseCase
class LeaveGroupParams extends UseCaseParams {
  final String groupId;
  final String userId;

  LeaveGroupParams({
    required this.groupId,
    required this.userId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (userId.isEmpty) {
      return 'User ID is required';
    }

    return null;
  }
}

/// Use case for leaving a group
class LeaveGroupUseCase implements UseCase<void, LeaveGroupParams> {
  final IGroupRepository _repository;

  LeaveGroupUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(LeaveGroupParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user is a member
    final isMember = await _repository.isMember(
      groupId: params.groupId,
      userId: params.userId,
    );

    if (isMember.isFailure) {
      return Result.failure(isMember.errorOrNull!);
    }

    if (isMember.dataOrNull != true) {
      return Result.failure(
        RepositoryError.validation('You are not a member of this group'),
      );
    }

    // 3. Check if user is the only admin
    final groupInfo = await _repository.getGroupInfo(params.groupId);
    if (groupInfo.isSuccess) {
      final info = groupInfo.dataOrNull!;
      final isOnlyAdmin =
          info.adminIds.length == 1 && info.adminIds.contains(params.userId);
      final hasOtherMembers = info.memberCount > 1;

      if (isOnlyAdmin && hasOtherMembers) {
        return Result.failure(
          RepositoryError.validation(
            'You must transfer admin role before leaving',
          ),
        );
      }
    }

    // 4. Delegate to repository
    return _repository.leaveGroup(
      groupId: params.groupId,
      userId: params.userId,
    );
  }
}

// =================== Make Admin Use Case ===================

/// Parameters for MakeAdminUseCase
class MakeAdminParams extends UseCaseParams {
  final String groupId;
  final String memberId;
  final String promotedByUserId;

  MakeAdminParams({
    required this.groupId,
    required this.memberId,
    required this.promotedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (memberId.isEmpty) {
      return 'Member ID is required';
    }

    if (promotedByUserId.isEmpty) {
      return 'Promoted by user ID is required';
    }

    if (memberId == promotedByUserId) {
      return 'Cannot promote yourself';
    }

    return null;
  }
}

/// Use case for promoting a member to admin
class MakeAdminUseCase implements UseCase<void, MakeAdminParams> {
  final IGroupRepository _repository;

  MakeAdminUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(MakeAdminParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.promotedByUserId,
      action: GroupAction.makeAdmin,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('make admins in this group'),
      );
    }

    // 3. Check if member exists and is not already admin
    final isAlreadyAdmin = await _repository.isAdmin(
      groupId: params.groupId,
      userId: params.memberId,
    );

    if (isAlreadyAdmin.isSuccess && isAlreadyAdmin.dataOrNull == true) {
      return Result.failure(
        RepositoryError.conflict('Admin'),
      );
    }

    // 4. Delegate to repository
    return _repository.makeAdmin(
      groupId: params.groupId,
      memberId: params.memberId,
      promotedByUserId: params.promotedByUserId,
    );
  }
}

// =================== Remove Admin Use Case ===================

/// Parameters for RemoveAdminUseCase
class RemoveAdminParams extends UseCaseParams {
  final String groupId;
  final String memberId;
  final String demotedByUserId;

  RemoveAdminParams({
    required this.groupId,
    required this.memberId,
    required this.demotedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (memberId.isEmpty) {
      return 'Member ID is required';
    }

    if (demotedByUserId.isEmpty) {
      return 'Demoted by user ID is required';
    }

    return null;
  }
}

/// Use case for demoting an admin
class RemoveAdminUseCase implements UseCase<void, RemoveAdminParams> {
  final IGroupRepository _repository;

  RemoveAdminUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(RemoveAdminParams params) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.demotedByUserId,
      action: GroupAction.removeAdmin,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('remove admins in this group'),
      );
    }

    // 3. Check if trying to demote the creator
    final groupInfo = await _repository.getGroupInfo(params.groupId);
    if (groupInfo.isSuccess) {
      if (groupInfo.dataOrNull!.createdBy == params.memberId) {
        return Result.failure(
          RepositoryError.validation('Cannot demote the group creator'),
        );
      }

      // Check at least one admin remains
      if (groupInfo.dataOrNull!.adminIds.length <= 1) {
        return Result.failure(
          RepositoryError.validation('Group must have at least one admin'),
        );
      }
    }

    // 4. Delegate to repository
    return _repository.removeAdmin(
      groupId: params.groupId,
      memberId: params.memberId,
      demotedByUserId: params.demotedByUserId,
    );
  }
}

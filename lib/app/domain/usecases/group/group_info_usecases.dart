import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/app/domain/usecases/usecase.dart';

// =================== Update Group Name Use Case ===================

/// Parameters for UpdateGroupNameUseCase
class UpdateGroupNameParams extends UseCaseParams {
  final String groupId;
  final String newName;
  final String updatedByUserId;

  UpdateGroupNameParams({
    required this.groupId,
    required this.newName,
    required this.updatedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (newName.trim().isEmpty) {
      return 'Group name cannot be empty';
    }

    if (newName.length > kMaxGroupNameLength) {
      return 'Group name cannot exceed $kMaxGroupNameLength characters';
    }

    if (updatedByUserId.isEmpty) {
      return 'Updated by user ID is required';
    }

    // Check for invalid characters (angle brackets and quotes)
    if (newName.contains(RegExp('[<>"\u0027]'))) {
      return 'Group name contains invalid characters';
    }

    return null;
  }
}

/// Use case for updating group name
class UpdateGroupNameUseCase
    implements UseCase<GroupUpdateResult, UpdateGroupNameParams> {
  final IGroupRepository _repository;

  UpdateGroupNameUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> call(
    UpdateGroupNameParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.updatedByUserId,
      action: GroupAction.editInfo,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('edit this group'),
      );
    }

    // 3. Delegate to repository
    return _repository.updateGroupName(
      groupId: params.groupId,
      newName: params.newName.trim(),
      updatedByUserId: params.updatedByUserId,
    );
  }
}

// =================== Update Group Description Use Case ===================

/// Parameters for UpdateGroupDescriptionUseCase
class UpdateGroupDescriptionParams extends UseCaseParams {
  final String groupId;
  final String newDescription;
  final String updatedByUserId;

  UpdateGroupDescriptionParams({
    required this.groupId,
    required this.newDescription,
    required this.updatedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    // Description can be empty (to clear it)
    if (newDescription.length > kMaxGroupDescriptionLength) {
      return 'Description cannot exceed $kMaxGroupDescriptionLength characters';
    }

    if (updatedByUserId.isEmpty) {
      return 'Updated by user ID is required';
    }

    return null;
  }
}

/// Use case for updating group description
class UpdateGroupDescriptionUseCase
    implements UseCase<GroupUpdateResult, UpdateGroupDescriptionParams> {
  final IGroupRepository _repository;

  UpdateGroupDescriptionUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> call(
    UpdateGroupDescriptionParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.updatedByUserId,
      action: GroupAction.editInfo,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('edit this group'),
      );
    }

    // 3. Delegate to repository
    return _repository.updateGroupDescription(
      groupId: params.groupId,
      newDescription: params.newDescription.trim(),
      updatedByUserId: params.updatedByUserId,
    );
  }
}

// =================== Update Group Image Use Case ===================

/// Parameters for UpdateGroupImageUseCase
class UpdateGroupImageParams extends UseCaseParams {
  final String groupId;
  final String imagePath;
  final String updatedByUserId;

  UpdateGroupImageParams({
    required this.groupId,
    required this.imagePath,
    required this.updatedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (imagePath.isEmpty) {
      return 'Image path is required';
    }

    if (updatedByUserId.isEmpty) {
      return 'Updated by user ID is required';
    }

    // Validate file extension
    final lowerPath = imagePath.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => lowerPath.endsWith(ext));
    if (!hasValidExtension) {
      return 'Invalid image format. Supported: JPG, PNG, GIF, WebP';
    }

    return null;
  }
}

/// Use case for updating group image
class UpdateGroupImageUseCase
    implements UseCase<GroupUpdateResult, UpdateGroupImageParams> {
  final IGroupRepository _repository;

  UpdateGroupImageUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> call(
    UpdateGroupImageParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.updatedByUserId,
      action: GroupAction.editInfo,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('edit this group'),
      );
    }

    // 3. Delegate to repository (handles upload)
    return _repository.updateGroupImage(
      groupId: params.groupId,
      imagePath: params.imagePath,
      updatedByUserId: params.updatedByUserId,
    );
  }
}

// =================== Update Group Permissions Use Case ===================

/// Parameters for UpdateGroupPermissionsUseCase
class UpdateGroupPermissionsParams extends UseCaseParams {
  final String groupId;
  final GroupPermissions permissions;
  final String updatedByUserId;

  UpdateGroupPermissionsParams({
    required this.groupId,
    required this.permissions,
    required this.updatedByUserId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (updatedByUserId.isEmpty) {
      return 'Updated by user ID is required';
    }

    return null;
  }
}

/// Use case for updating group permissions
class UpdateGroupPermissionsUseCase
    implements UseCase<void, UpdateGroupPermissionsParams> {
  final IGroupRepository _repository;

  UpdateGroupPermissionsUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(
    UpdateGroupPermissionsParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Check if user can perform action
    final canPerform = await _repository.canPerformAction(
      groupId: params.groupId,
      userId: params.updatedByUserId,
      action: GroupAction.updatePermissions,
    );

    if (canPerform.isFailure) {
      return Result.failure(canPerform.errorOrNull!);
    }

    if (canPerform.dataOrNull != true) {
      return Result.failure(
        RepositoryError.unauthorized('update permissions for this group'),
      );
    }

    // 3. Delegate to repository
    return _repository.updatePermissions(
      groupId: params.groupId,
      permissions: params.permissions,
      updatedByUserId: params.updatedByUserId,
    );
  }
}

// =================== Get Group Info Use Case ===================

/// Parameters for GetGroupInfoUseCase
class GetGroupInfoParams extends UseCaseParams {
  final String groupId;

  GetGroupInfoParams({required this.groupId});

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }
    return null;
  }
}

/// Use case for getting group information
class GetGroupInfoUseCase implements UseCase<GroupInfo, GetGroupInfoParams> {
  final IGroupRepository _repository;

  GetGroupInfoUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<GroupInfo, RepositoryError>> call(
    GetGroupInfoParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Delegate to repository
    return _repository.getGroupInfo(params.groupId);
  }
}

// =================== Transfer Ownership Use Case ===================

/// Parameters for TransferOwnershipUseCase
class TransferOwnershipParams extends UseCaseParams {
  final String groupId;
  final String newOwnerId;
  final String currentOwnerId;

  TransferOwnershipParams({
    required this.groupId,
    required this.newOwnerId,
    required this.currentOwnerId,
  });

  @override
  String? validate() {
    if (groupId.isEmpty) {
      return 'Group ID is required';
    }

    if (newOwnerId.isEmpty) {
      return 'New owner ID is required';
    }

    if (currentOwnerId.isEmpty) {
      return 'Current owner ID is required';
    }

    if (newOwnerId == currentOwnerId) {
      return 'New owner must be different from current owner';
    }

    return null;
  }
}

/// Use case for transferring group ownership
class TransferOwnershipUseCase
    implements UseCase<void, TransferOwnershipParams> {
  final IGroupRepository _repository;

  TransferOwnershipUseCase({required IGroupRepository repository})
      : _repository = repository;

  @override
  Future<Result<void, RepositoryError>> call(
    TransferOwnershipParams params,
  ) async {
    // 1. Validate parameters
    final validationError = params.validate();
    if (validationError != null) {
      return Result.failure(RepositoryError.validation(validationError));
    }

    // 2. Verify current user is the creator
    final groupInfo = await _repository.getGroupInfo(params.groupId);
    if (groupInfo.isFailure) {
      return Result.failure(groupInfo.errorOrNull!);
    }

    if (groupInfo.dataOrNull!.createdBy != params.currentOwnerId) {
      return Result.failure(
        RepositoryError.unauthorized('transfer ownership of this group'),
      );
    }

    // 3. Verify new owner is a member
    final isMember = await _repository.isMember(
      groupId: params.groupId,
      userId: params.newOwnerId,
    );

    if (isMember.isFailure) {
      return Result.failure(isMember.errorOrNull!);
    }

    if (isMember.dataOrNull != true) {
      return Result.failure(
        RepositoryError.validation('New owner must be a member of the group'),
      );
    }

    // 4. Delegate to repository
    return _repository.transferOwnership(
      groupId: params.groupId,
      newOwnerId: params.newOwnerId,
      currentOwnerId: params.currentOwnerId,
    );
  }
}

import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';

/// Group member with role information
class GroupMember {
  final String id;
  final String name;
  final String? avatarUrl;
  final GroupRole role;
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.joinedAt,
  });

  bool get isAdmin => role == GroupRole.admin || role == GroupRole.creator;
  bool get isCreator => role == GroupRole.creator;
}

/// Role in a group
enum GroupRole {
  member,
  admin,
  creator,
}

/// Group information
class GroupInfo {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<GroupMember> members;
  final String createdBy;
  final DateTime createdAt;
  final GroupPermissions permissions;

  const GroupInfo({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    required this.permissions,
  });

  /// Get all admin IDs
  List<String> get adminIds =>
      members.where((m) => m.isAdmin).map((m) => m.id).toList();

  /// Get all member IDs
  List<String> get memberIds => members.map((m) => m.id).toList();

  /// Check if a user is admin
  bool isUserAdmin(String userId) =>
      members.any((m) => m.id == userId && m.isAdmin);

  /// Check if a user is the creator
  bool isUserCreator(String userId) =>
      members.any((m) => m.id == userId && m.isCreator);

  /// Get member count
  int get memberCount => members.length;
}

/// Group permissions configuration
class GroupPermissions {
  /// Who can add members
  final PermissionLevel addMembers;

  /// Who can remove members
  final PermissionLevel removeMembers;

  /// Who can edit group info (name, description, image)
  final PermissionLevel editGroupInfo;

  /// Who can send messages
  final PermissionLevel sendMessages;

  /// Who can pin messages
  final PermissionLevel pinMessages;

  const GroupPermissions({
    this.addMembers = PermissionLevel.adminsOnly,
    this.removeMembers = PermissionLevel.adminsOnly,
    this.editGroupInfo = PermissionLevel.adminsOnly,
    this.sendMessages = PermissionLevel.everyone,
    this.pinMessages = PermissionLevel.adminsOnly,
  });

  static const GroupPermissions defaultPermissions = GroupPermissions();

  Map<String, dynamic> toMap() => {
        'addMembers': addMembers.name,
        'removeMembers': removeMembers.name,
        'editGroupInfo': editGroupInfo.name,
        'sendMessages': sendMessages.name,
        'pinMessages': pinMessages.name,
      };

  factory GroupPermissions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaultPermissions;
    return GroupPermissions(
      addMembers: PermissionLevel.values.firstWhere(
        (e) => e.name == map['addMembers'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      removeMembers: PermissionLevel.values.firstWhere(
        (e) => e.name == map['removeMembers'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      editGroupInfo: PermissionLevel.values.firstWhere(
        (e) => e.name == map['editGroupInfo'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
      sendMessages: PermissionLevel.values.firstWhere(
        (e) => e.name == map['sendMessages'],
        orElse: () => PermissionLevel.everyone,
      ),
      pinMessages: PermissionLevel.values.firstWhere(
        (e) => e.name == map['pinMessages'],
        orElse: () => PermissionLevel.adminsOnly,
      ),
    );
  }
}

/// Permission level for group actions
enum PermissionLevel {
  everyone,
  adminsOnly,
  creatorOnly,
}

/// Result of a member operation
class MemberOperationResult {
  final String memberId;
  final String memberName;
  final bool success;
  final String? systemMessageId;

  const MemberOperationResult({
    required this.memberId,
    required this.memberName,
    required this.success,
    this.systemMessageId,
  });
}

/// Result of updating group info
class GroupUpdateResult {
  final String groupId;
  final Map<String, dynamic> updatedFields;
  final String? newImageUrl;

  const GroupUpdateResult({
    required this.groupId,
    required this.updatedFields,
    this.newImageUrl,
  });
}

/// Abstract interface for group management repository
///
/// Handles all group chat operations with:
/// - Atomic member operations using transactions
/// - Role-based permission validation
/// - System message generation
/// - Event emission for real-time updates
abstract class IGroupRepository {
  // =================== Member Operations ===================

  /// Add a single member to a group
  ///
  /// Validates:
  /// - Current user has permission to add members
  /// - Target user is not already a member
  /// - Target user is not blocked by/blocking any group member
  /// - Group has not reached max member limit
  ///
  /// Creates system message: "{Name} was added to the group"
  /// Emits GroupMemberAddedEvent on success
  Future<Result<MemberOperationResult, RepositoryError>> addMember({
    required String groupId,
    required SocialMediaUser member,
    required String addedByUserId,
  });

  /// Add multiple members to a group
  ///
  /// Uses batch operations for efficiency.
  /// Continues on individual failures.
  Future<Result<List<MemberOperationResult>, RepositoryError>> addMembers({
    required String groupId,
    required List<SocialMediaUser> members,
    required String addedByUserId,
  });

  /// Remove a member from a group
  ///
  /// Validates:
  /// - Current user has permission to remove members
  /// - Target user is a member of the group
  /// - Cannot remove the group creator
  /// - At least one member remains
  ///
  /// Creates system message: "{Name} was removed from the group"
  /// Emits GroupMemberRemovedEvent on success
  Future<Result<MemberOperationResult, RepositoryError>> removeMember({
    required String groupId,
    required String memberId,
    required String removedByUserId,
  });

  /// Current user leaves the group
  ///
  /// Validates:
  /// - User is a member of the group
  /// - If user is the only admin, must transfer admin role first
  /// - If user is creator and only member, group is deleted
  ///
  /// Creates system message: "{Name} left the group"
  /// Emits GroupMemberLeftEvent on success
  Future<Result<void, RepositoryError>> leaveGroup({
    required String groupId,
    required String userId,
  });

  // =================== Admin Operations ===================

  /// Promote a member to admin
  ///
  /// Validates:
  /// - Current user is admin
  /// - Target user is a member
  /// - Target user is not already admin
  ///
  /// Creates system message: "{Name} is now an admin"
  /// Emits GroupAdminChangedEvent on success
  Future<Result<void, RepositoryError>> makeAdmin({
    required String groupId,
    required String memberId,
    required String promotedByUserId,
  });

  /// Demote an admin to regular member
  ///
  /// Validates:
  /// - Current user is admin (or creator for other admins)
  /// - Target user is admin
  /// - At least one admin remains
  /// - Cannot demote the creator
  ///
  /// Creates system message: "{Name} is no longer an admin"
  /// Emits GroupAdminChangedEvent on success
  Future<Result<void, RepositoryError>> removeAdmin({
    required String groupId,
    required String memberId,
    required String demotedByUserId,
  });

  /// Transfer group ownership to another member
  ///
  /// Only the creator can do this.
  /// New owner becomes creator, old creator becomes admin.
  Future<Result<void, RepositoryError>> transferOwnership({
    required String groupId,
    required String newOwnerId,
    required String currentOwnerId,
  });

  // =================== Group Info Operations ===================

  /// Update group name
  ///
  /// Validates:
  /// - Current user has permission to edit group info
  /// - Name is not empty (max 100 chars)
  ///
  /// Creates system message: "Group name changed to {name}"
  /// Emits GroupInfoUpdatedEvent on success
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupName({
    required String groupId,
    required String newName,
    required String updatedByUserId,
  });

  /// Update group description
  ///
  /// Validates:
  /// - Current user has permission to edit group info
  /// - Description max 500 chars
  ///
  /// Emits GroupInfoUpdatedEvent on success
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupDescription({
    required String groupId,
    required String newDescription,
    required String updatedByUserId,
  });

  /// Update group image
  ///
  /// Validates:
  /// - Current user has permission to edit group info
  /// - Image file exists and is valid format
  ///
  /// Uploads image to storage, updates URL.
  /// Emits GroupInfoUpdatedEvent on success
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupImage({
    required String groupId,
    required String imagePath,
    required String updatedByUserId,
  });

  /// Update group permissions
  ///
  /// Only creator or admins can update permissions.
  /// Emits GroupPermissionsUpdatedEvent on success
  Future<Result<void, RepositoryError>> updatePermissions({
    required String groupId,
    required GroupPermissions permissions,
    required String updatedByUserId,
  });

  // =================== Query Operations ===================

  /// Get full group information
  Future<Result<GroupInfo, RepositoryError>> getGroupInfo(String groupId);

  /// Get group members with their roles
  Future<Result<List<GroupMember>, RepositoryError>> getMembers(String groupId);

  /// Get group admins only
  Future<Result<List<GroupMember>, RepositoryError>> getAdmins(String groupId);

  /// Check if user is a member of the group
  Future<Result<bool, RepositoryError>> isMember({
    required String groupId,
    required String userId,
  });

  /// Check if user is an admin of the group
  Future<Result<bool, RepositoryError>> isAdmin({
    required String groupId,
    required String userId,
  });

  // =================== Permission Validation ===================

  /// Check if user can perform an action on the group
  Future<Result<bool, RepositoryError>> canPerformAction({
    required String groupId,
    required String userId,
    required GroupAction action,
  });
}

/// Group actions for permission checking
enum GroupAction {
  addMember,
  removeMember,
  editInfo,
  sendMessage,
  pinMessage,
  makeAdmin,
  removeAdmin,
  updatePermissions,
  deleteGroup,
}

/// Maximum members in a group
const int kMaxGroupMembers = 256;

/// Minimum members in a group (creator)
const int kMinGroupMembers = 1;

/// Maximum group name length
const int kMaxGroupNameLength = 100;

/// Maximum group description length
const int kMaxGroupDescriptionLength = 500;

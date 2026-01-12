import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/modules/user_info/repositories/user_info_repository.dart';

/// Comprehensive state model for group info screen
class GroupInfoState {
  final ChatRoom? group;
  final List<SocialMediaUser> members;
  final List<String> admins;
  final bool isLoading;
  final bool isFavorite;
  final bool isMuted;
  final MediaCounts mediaCounts;
  final String? errorMessage;
  final GroupInfoAction? pendingAction;

  const GroupInfoState({
    this.group,
    this.members = const [],
    this.admins = const [],
    this.isLoading = false,
    this.isFavorite = false,
    this.isMuted = false,
    this.mediaCounts = const MediaCounts(),
    this.errorMessage,
    this.pendingAction,
  });

  GroupInfoState copyWith({
    ChatRoom? group,
    List<SocialMediaUser>? members,
    List<String>? admins,
    bool? isLoading,
    bool? isFavorite,
    bool? isMuted,
    MediaCounts? mediaCounts,
    String? errorMessage,
    GroupInfoAction? pendingAction,
  }) {
    return GroupInfoState(
      group: group ?? this.group,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      isLoading: isLoading ?? this.isLoading,
      isFavorite: isFavorite ?? this.isFavorite,
      isMuted: isMuted ?? this.isMuted,
      mediaCounts: mediaCounts ?? this.mediaCounts,
      errorMessage: errorMessage,
      pendingAction: pendingAction,
    );
  }

  /// Room ID
  String? get roomId => group?.id;

  /// Group name
  String get name => group?.name ?? 'Group Chat';

  /// Group description
  String get description => group?.description ?? '';

  /// Group image URL
  String? get imageUrl => group?.groupImageUrl;

  /// Member count
  int get memberCount => members.length;

  /// Has description
  bool get hasDescription => description.isNotEmpty;

  /// Check if user is admin
  bool isUserAdmin(String? userId) {
    if (userId == null) return false;
    // First member is usually admin, or check admins list
    if (members.isNotEmpty && members.first.uid == userId) return true;
    return admins.contains(userId);
  }

  /// Get non-admin members
  List<SocialMediaUser> getNonAdminMembers(String? currentUserId) {
    return members.where((m) => m.uid != currentUserId && !isUserAdmin(m.uid)).toList();
  }

  /// Get removable members (for admin)
  List<SocialMediaUser> getRemovableMembers(String? currentUserId) {
    if (!isUserAdmin(currentUserId)) return [];
    return members.where((m) => m.uid != currentUserId).toList();
  }
}

/// Actions that can be performed on a group
enum GroupInfoAction {
  updatingInfo,
  addingMember,
  removingMember,
  leaving,
  togglingFavorite,
  togglingMute,
  reporting,
  deleting,
}

/// Extension for action display names
extension GroupInfoActionExtension on GroupInfoAction {
  String get displayName {
    switch (this) {
      case GroupInfoAction.updatingInfo:
        return 'Updating group info...';
      case GroupInfoAction.addingMember:
        return 'Adding member...';
      case GroupInfoAction.removingMember:
        return 'Removing member...';
      case GroupInfoAction.leaving:
        return 'Leaving group...';
      case GroupInfoAction.togglingFavorite:
        return 'Updating favorite...';
      case GroupInfoAction.togglingMute:
        return 'Updating mute...';
      case GroupInfoAction.reporting:
        return 'Reporting group...';
      case GroupInfoAction.deleting:
        return 'Deleting group...';
    }
  }
}

/// Arguments for navigating to group info screen
class GroupInfoArguments {
  final ChatRoom? group;
  final String? roomId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<SocialMediaUser>? members;
  final int? memberCount;

  const GroupInfoArguments({
    this.group,
    this.roomId,
    this.name,
    this.description,
    this.imageUrl,
    this.members,
    this.memberCount,
  });

  /// Create from route arguments map
  factory GroupInfoArguments.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GroupInfoArguments();
    return GroupInfoArguments(
      group: map['group'] as ChatRoom?,
      roomId: map['roomId'] as String?,
      name: map['chatName'] as String?,
      description: map['chatDescription'] as String?,
      imageUrl: map['groupImageUrl'] as String?,
      members: map['members'] as List<SocialMediaUser>?,
      memberCount: map['memberCount'] as int?,
    );
  }
}

/// Model for group chat permissions
class GroupPermissions {
  final bool canSendMessages;
  final bool canEditGroupInfo;
  final bool canAddMembers;
  final bool canRemoveMembers;
  final bool canPinMessages;
  final bool canDeleteMessages;
  final String? restrictedUntil; // ISO 8601 timestamp for temporary restrictions

  GroupPermissions({
    this.canSendMessages = true,
    this.canEditGroupInfo = false,
    this.canAddMembers = false,
    this.canRemoveMembers = false,
    this.canPinMessages = false,
    this.canDeleteMessages = false,
    this.restrictedUntil,
  });

  /// Default permissions for regular members
  factory GroupPermissions.member() => GroupPermissions(
        canSendMessages: true,
        canEditGroupInfo: false,
        canAddMembers: false,
        canRemoveMembers: false,
        canPinMessages: false,
        canDeleteMessages: false,
      );

  /// Default permissions for admins
  factory GroupPermissions.admin() => GroupPermissions(
        canSendMessages: true,
        canEditGroupInfo: true,
        canAddMembers: true,
        canRemoveMembers: true,
        canPinMessages: true,
        canDeleteMessages: true,
      );

  /// Restricted permissions (muted member)
  factory GroupPermissions.restricted({String? until}) => GroupPermissions(
        canSendMessages: false,
        canEditGroupInfo: false,
        canAddMembers: false,
        canRemoveMembers: false,
        canPinMessages: false,
        canDeleteMessages: false,
        restrictedUntil: until,
      );

  Map<String, dynamic> toMap() => {
        'canSendMessages': canSendMessages,
        'canEditGroupInfo': canEditGroupInfo,
        'canAddMembers': canAddMembers,
        'canRemoveMembers': canRemoveMembers,
        'canPinMessages': canPinMessages,
        'canDeleteMessages': canDeleteMessages,
        'restrictedUntil': restrictedUntil,
      };

  factory GroupPermissions.fromMap(Map<String, dynamic> map) =>
      GroupPermissions(
        canSendMessages: map['canSendMessages'] ?? true,
        canEditGroupInfo: map['canEditGroupInfo'] ?? false,
        canAddMembers: map['canAddMembers'] ?? false,
        canRemoveMembers: map['canRemoveMembers'] ?? false,
        canPinMessages: map['canPinMessages'] ?? false,
        canDeleteMessages: map['canDeleteMessages'] ?? false,
        restrictedUntil: map['restrictedUntil'],
      );

  GroupPermissions copyWith({
    bool? canSendMessages,
    bool? canEditGroupInfo,
    bool? canAddMembers,
    bool? canRemoveMembers,
    bool? canPinMessages,
    bool? canDeleteMessages,
    String? restrictedUntil,
  }) {
    return GroupPermissions(
      canSendMessages: canSendMessages ?? this.canSendMessages,
      canEditGroupInfo: canEditGroupInfo ?? this.canEditGroupInfo,
      canAddMembers: canAddMembers ?? this.canAddMembers,
      canRemoveMembers: canRemoveMembers ?? this.canRemoveMembers,
      canPinMessages: canPinMessages ?? this.canPinMessages,
      canDeleteMessages: canDeleteMessages ?? this.canDeleteMessages,
      restrictedUntil: restrictedUntil ?? this.restrictedUntil,
    );
  }

  bool get isRestricted {
    if (restrictedUntil == null) return false;
    final until = DateTime.parse(restrictedUntil!);
    return DateTime.now().isBefore(until);
  }
}

/// Model for group member with permissions
class GroupMember {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'admin', 'member', 'moderator'
  final GroupPermissions permissions;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.permissions,
    required this.joinedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role,
        'permissions': permissions.toMap(),
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
        userId: map['userId'],
        displayName: map['displayName'],
        photoUrl: map['photoUrl'],
        role: map['role'] ?? 'member',
        permissions: GroupPermissions.fromMap(map['permissions'] ?? {}),
        joinedAt: DateTime.parse(map['joinedAt']),
      );

  GroupMember copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    String? role,
    GroupPermissions? permissions,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

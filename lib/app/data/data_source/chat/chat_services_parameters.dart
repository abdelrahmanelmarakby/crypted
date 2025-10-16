// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:crypted_app/app/data/models/user_model.dart';

/// Configuration class for chat room creation and management
/// Contains all necessary parameters for setting up and managing chat rooms
class ChatConfiguration {
  /// Whether this is a group chat or private chat
  final bool isGroupChat;
  
  /// List of users who are members of this chat
  final List<SocialMediaUser> members;
  
  /// List of user IDs who have admin privileges
  final List<String> adminIds;
  
  /// Name of the chat room (required for group chats)
  final String? name;
  
  /// Description of the chat room
  final String? description;
  
  /// URL of the chat room's profile image
  final String? imageUrl;
  
  /// Custom settings for the chat room
  final ChatSettings? settings;
  
  /// Maximum number of members allowed (null means unlimited)
  final int? maxMembers;
  
  /// Whether the chat is archived
  final bool isArchived;
  
  /// Whether the chat is pinned
  final bool isPinned;
  
  /// Chat room category/type for organization
  final ChatCategory category;
  
  /// Custom metadata for the chat room
  final Map<String, dynamic>? metadata;
  
  /// Date when the chat was created
  final DateTime? createdAt;
  
  /// ID of the user who created the chat
  final String? createdBy;

  const ChatConfiguration({
    this.isGroupChat = false,
    this.members = const [],
    this.adminIds = const [],
    this.name,
    this.description,
    this.imageUrl,
    this.settings,
    this.maxMembers,
    this.isArchived = false,
    this.isPinned = false,
    this.category = ChatCategory.general,
    this.metadata,
    this.createdAt,
    this.createdBy,
  });

  /// Create a copy of this configuration with updated values
  ChatConfiguration copyWith({
    bool? isGroupChat,
    List<SocialMediaUser>? members,
    List<String>? adminIds,
    String? name,
    String? description,
    String? imageUrl,
    ChatSettings? settings,
    int? maxMembers,
    bool? isArchived,
    bool? isPinned,
    ChatCategory? category,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ChatConfiguration(
      isGroupChat: isGroupChat ?? this.isGroupChat,
      members: members ?? this.members,
      adminIds: adminIds ?? this.adminIds,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      settings: settings ?? this.settings,
      maxMembers: maxMembers ?? this.maxMembers,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Create configuration from a map (useful for Firebase/API responses)
  factory ChatConfiguration.fromMap(Map<String, dynamic> map) {
    return ChatConfiguration(
      isGroupChat: map['isGroupChat'] as bool? ?? false,
      members: (map['members'] as List<dynamic>?)
          ?.map((member) => SocialMediaUser.fromMap(member as Map<String, dynamic>))
          .toList() ?? const [],
      adminIds: List<String>.from(map['adminIds'] as List<dynamic>? ?? []),
      name: map['name'] as String?,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      settings: map['settings'] != null 
          ? ChatSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : null,
      maxMembers: map['maxMembers'] as int?,
      isArchived: map['isArchived'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      category: ChatCategory.fromString(map['category'] as String? ?? 'general'),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      createdBy: map['createdBy'] as String?,
    );
  }

  /// Convert configuration to map (useful for Firebase/API requests)
  Map<String, dynamic> toMap() {
    return {
      'isGroupChat': isGroupChat,
      'members': members.map((member) => member.toMap()).toList(),
      'adminIds': adminIds,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'settings': settings?.toMap(),
      'maxMembers': maxMembers,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'category': category.name,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Get list of member IDs
  List<String> get memberIds => members
      .map((member) => member.uid ?? '')
      .where((id) => id.isNotEmpty)
      .toList();

  /// Get list of non-admin member IDs
  List<String> get nonAdminMemberIds => memberIds
      .where((id) => !adminIds.contains(id))
      .toList();

  /// Check if a user is an admin
  bool isUserAdmin(String userId) => adminIds.contains(userId);

  /// Check if a user is a member
  bool isUserMember(String userId) => memberIds.contains(userId);

  /// Get member count
  int get memberCount => members.length;

  /// Check if chat has reached max members limit
  bool get isAtMaxCapacity => maxMembers != null && memberCount >= maxMembers!;

  /// Validate the configuration
  ChatConfigurationValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // Required validations
    if (members.isEmpty) {
      errors.add('At least one member is required');
    }

    if (isGroupChat && (name == null || name!.trim().isEmpty)) {
      errors.add('Group chat must have a name');
    }

    if (isGroupChat && members.length < 2) {
      errors.add('Group chat must have at least 2 members');
    }

    if (!isGroupChat && members.length > 2) {
      errors.add('Private chat cannot have more than 2 members');
    }

    if (maxMembers != null && maxMembers! < members.length) {
      errors.add('Current member count exceeds maximum allowed members');
    }

    // Admin validations
    for (final adminId in adminIds) {
      if (!memberIds.contains(adminId)) {
        errors.add('Admin with ID $adminId is not a member of the chat');
      }
    }

    // Warnings
    if (isGroupChat && adminIds.isEmpty) {
      warnings.add('Group chat has no admins assigned');
    }

    if (name != null && name!.length > 50) {
      warnings.add('Chat name is longer than 50 characters');
    }

    if (description != null && description!.length > 200) {
      warnings.add('Chat description is longer than 200 characters');
    }

    return ChatConfigurationValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Create a private chat configuration between two users
  factory ChatConfiguration.privateChat({
    required SocialMediaUser user1,
    required SocialMediaUser user2,
    Map<String, dynamic>? metadata,
  }) {
    return ChatConfiguration(
      isGroupChat: false,
      members: [user1, user2],
      adminIds: const [],
      category: ChatCategory.private,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
  }

  /// Create a group chat configuration
  factory ChatConfiguration.groupChat({
    required String name,
    required List<SocialMediaUser> members,
    required List<String> adminIds,
    String? description,
    String? imageUrl,
    ChatSettings? settings,
    int? maxMembers,
    ChatCategory category = ChatCategory.general,
    Map<String, dynamic>? metadata,
    String? createdBy,
  }) {
    return ChatConfiguration(
      isGroupChat: true,
      name: name,
      members: members,
      adminIds: adminIds,
      description: description,
      imageUrl: imageUrl,
      settings: settings,
      maxMembers: maxMembers,
      category: category,
      metadata: metadata,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatConfiguration &&
        other.isGroupChat == isGroupChat &&
        _listEquals(other.members, members) &&
        _listEquals(other.adminIds, adminIds) &&
        other.name == name &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.settings == settings &&
        other.maxMembers == maxMembers &&
        other.isArchived == isArchived &&
        other.isPinned == isPinned &&
        other.category == category &&
        _mapEquals(other.metadata, metadata) &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      isGroupChat,
      members,
      adminIds,
      name,
      description,
      imageUrl,
      settings,
      maxMembers,
      isArchived,
      isPinned,
      category,
      metadata,
      createdAt,
      createdBy,
    ]);
  }

  @override
  String toString() {
    return 'ChatConfiguration('
        'isGroupChat: $isGroupChat, '
        'members: ${members.length}, '
        'adminIds: ${adminIds.length}, '
        'name: $name, '
        'category: $category'
        ')';
  }

  // Helper methods for equality comparison
  bool _listEquals<T>(List<T>? list1, List<T>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V>? map1, Map<K, V>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
}

/// Chat settings for advanced configuration
class ChatSettings {
  /// Whether messages can be edited after sending
  final bool allowMessageEditing;
  
  /// Whether members can add new members
  final bool allowMembersToAddOthers;
  
  /// Whether to show read receipts
  final bool showReadReceipts;
  
  /// Whether to allow message forwarding
  final bool allowMessageForwarding;
  
  /// Message retention period in days (null means forever)
  final int? messageRetentionDays;
  
  /// Whether to enable message encryption
  final bool enableEncryption;
  
  /// Custom notification settings
  final NotificationSettings? notificationSettings;

  const ChatSettings({
    this.allowMessageEditing = true,
    this.allowMembersToAddOthers = false,
    this.showReadReceipts = true,
    this.allowMessageForwarding = true,
    this.messageRetentionDays,
    this.enableEncryption = false,
    this.notificationSettings,
  });

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      allowMessageEditing: map['allowMessageEditing'] as bool? ?? true,
      allowMembersToAddOthers: map['allowMembersToAddOthers'] as bool? ?? false,
      showReadReceipts: map['showReadReceipts'] as bool? ?? true,
      allowMessageForwarding: map['allowMessageForwarding'] as bool? ?? true,
      messageRetentionDays: map['messageRetentionDays'] as int?,
      enableEncryption: map['enableEncryption'] as bool? ?? false,
      notificationSettings: map['notificationSettings'] != null
          ? NotificationSettings.fromMap(map['notificationSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowMessageEditing': allowMessageEditing,
      'allowMembersToAddOthers': allowMembersToAddOthers,
      'showReadReceipts': showReadReceipts,
      'allowMessageForwarding': allowMessageForwarding,
      'messageRetentionDays': messageRetentionDays,
      'enableEncryption': enableEncryption,
      'notificationSettings': notificationSettings?.toMap(),
    };
  }

  ChatSettings copyWith({
    bool? allowMessageEditing,
    bool? allowMembersToAddOthers,
    bool? showReadReceipts,
    bool? allowMessageForwarding,
    int? messageRetentionDays,
    bool? enableEncryption,
    NotificationSettings? notificationSettings,
  }) {
    return ChatSettings(
      allowMessageEditing: allowMessageEditing ?? this.allowMessageEditing,
      allowMembersToAddOthers: allowMembersToAddOthers ?? this.allowMembersToAddOthers,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      allowMessageForwarding: allowMessageForwarding ?? this.allowMessageForwarding,
      messageRetentionDays: messageRetentionDays ?? this.messageRetentionDays,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSettings &&
        other.allowMessageEditing == allowMessageEditing &&
        other.allowMembersToAddOthers == allowMembersToAddOthers &&
        other.showReadReceipts == showReadReceipts &&
        other.allowMessageForwarding == allowMessageForwarding &&
        other.messageRetentionDays == messageRetentionDays &&
        other.enableEncryption == enableEncryption &&
        other.notificationSettings == notificationSettings;
  }

  @override
  int get hashCode {
    return Object.hash(
      allowMessageEditing,
      allowMembersToAddOthers,
      showReadReceipts,
      allowMessageForwarding,
      messageRetentionDays,
      enableEncryption,
      notificationSettings,
    );
  }
}

/// Notification settings for chat rooms
class NotificationSettings {
  /// Whether notifications are enabled
  final bool enabled;
  
  /// Whether to show message previews in notifications
  final bool showPreviews;
  
  /// Custom notification sound
  final String? soundName;
  
  /// Whether to vibrate on new messages
  final bool vibrate;
  
  /// Quiet hours start time (24-hour format)
  final String? quietHoursStart;
  
  /// Quiet hours end time (24-hour format)
  final String? quietHoursEnd;

  const NotificationSettings({
    this.enabled = true,
    this.showPreviews = true,
    this.soundName,
    this.vibrate = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] as bool? ?? true,
      showPreviews: map['showPreviews'] as bool? ?? true,
      soundName: map['soundName'] as String?,
      vibrate: map['vibrate'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] as String?,
      quietHoursEnd: map['quietHoursEnd'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'showPreviews': showPreviews,
      'soundName': soundName,
      'vibrate': vibrate,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
        other.enabled == enabled &&
        other.showPreviews == showPreviews &&
        other.soundName == soundName &&
        other.vibrate == vibrate &&
        other.quietHoursStart == quietHoursStart &&
        other.quietHoursEnd == quietHoursEnd;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      showPreviews,
      soundName,
      vibrate,
      quietHoursStart,
      quietHoursEnd,
    );
  }
}

/// Chat categories for organization
enum ChatCategory {
  general,
  private,
  work,
  family,
  friends,
  projects,
  announcements,
  support,
  custom;

  static ChatCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return ChatCategory.general;
      case 'private':
        return ChatCategory.private;
      case 'work':
        return ChatCategory.work;
      case 'family':
        return ChatCategory.family;
      case 'friends':
        return ChatCategory.friends;
      case 'projects':
        return ChatCategory.projects;
      case 'announcements':
        return ChatCategory.announcements;
      case 'support':
        return ChatCategory.support;
      case 'custom':
        return ChatCategory.custom;
      default:
        return ChatCategory.general;
    }
  }
}

/// Validation result for chat configuration
class ChatConfigurationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ChatConfigurationValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Validation Result: ${isValid ? 'Valid' : 'Invalid'}');
    
    if (hasErrors) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (hasWarnings) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    return buffer.toString();
  }
}
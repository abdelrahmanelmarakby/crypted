import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/user_info/repositories/user_info_repository.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';

/// Comprehensive state model for user info screen
class UserInfoState {
  final SocialMediaUser? user;
  final String? roomId;
  final bool isLoading;
  final bool isBlocked;
  final bool isFavorite;
  final bool isArchived;
  final bool isMuted;
  final bool isOnline;
  final bool hasCustomNotifications;
  final DateTime? lastSeen;
  final MediaCounts mediaCounts;
  final List<SocialMediaUser> mutualContacts;
  final String? errorMessage;
  final UserInfoAction? pendingAction;
  final DisappearingDuration disappearingDuration;

  const UserInfoState({
    this.user,
    this.roomId,
    this.isLoading = false,
    this.isBlocked = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isMuted = false,
    this.isOnline = false,
    this.hasCustomNotifications = false,
    this.lastSeen,
    this.mediaCounts = const MediaCounts(),
    this.mutualContacts = const [],
    this.errorMessage,
    this.pendingAction,
    this.disappearingDuration = DisappearingDuration.off,
  });

  UserInfoState copyWith({
    SocialMediaUser? user,
    String? roomId,
    bool? isLoading,
    bool? isBlocked,
    bool? isFavorite,
    bool? isArchived,
    bool? isMuted,
    bool? isOnline,
    bool? hasCustomNotifications,
    DateTime? lastSeen,
    MediaCounts? mediaCounts,
    List<SocialMediaUser>? mutualContacts,
    String? errorMessage,
    UserInfoAction? pendingAction,
    DisappearingDuration? disappearingDuration,
  }) {
    return UserInfoState(
      user: user ?? this.user,
      roomId: roomId ?? this.roomId,
      isLoading: isLoading ?? this.isLoading,
      isBlocked: isBlocked ?? this.isBlocked,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isOnline: isOnline ?? this.isOnline,
      hasCustomNotifications: hasCustomNotifications ?? this.hasCustomNotifications,
      lastSeen: lastSeen ?? this.lastSeen,
      mediaCounts: mediaCounts ?? this.mediaCounts,
      mutualContacts: mutualContacts ?? this.mutualContacts,
      errorMessage: errorMessage,
      pendingAction: pendingAction,
      disappearingDuration: disappearingDuration ?? this.disappearingDuration,
    );
  }

  /// Chat ID for navigation
  String? get chatId => roomId;

  /// User display name
  String get displayName => user?.fullName ?? 'Unknown User';

  /// User bio/status
  String get bio => user?.bio ?? 'No bio available';

  /// User email
  String get email => user?.email ?? '';

  /// User phone
  String get phone => user?.phoneNumber ?? '';

  /// User profile image URL
  String? get imageUrl => user?.imageUrl;

  /// Whether the user has contact info
  bool get hasContactInfo => email.isNotEmpty || phone.isNotEmpty;

  /// Status text based on online status
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      return _formatLastSeen(lastSeen!);
    }
    return 'Offline';
  }

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} days ago';
    } else {
      return 'Last seen on ${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Actions that can be performed on a user
enum UserInfoAction {
  blocking,
  unblocking,
  togglingFavorite,
  togglingArchive,
  togglingMute,
  clearingChat,
  reporting,
}

/// Extension for action display names
extension UserInfoActionExtension on UserInfoAction {
  String get displayName {
    switch (this) {
      case UserInfoAction.blocking:
        return 'Blocking user...';
      case UserInfoAction.unblocking:
        return 'Unblocking user...';
      case UserInfoAction.togglingFavorite:
        return 'Updating favorite...';
      case UserInfoAction.togglingArchive:
        return 'Updating archive...';
      case UserInfoAction.togglingMute:
        return 'Updating mute...';
      case UserInfoAction.clearingChat:
        return 'Clearing chat...';
      case UserInfoAction.reporting:
        return 'Reporting user...';
    }
  }
}

/// Arguments for navigating to user info screen
class UserInfoArguments {
  final SocialMediaUser? user;
  final String? userId;
  final String? roomId;

  const UserInfoArguments({
    this.user,
    this.userId,
    this.roomId,
  });

  /// Create from route arguments map
  factory UserInfoArguments.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserInfoArguments();
    return UserInfoArguments(
      user: map['user'] as SocialMediaUser?,
      userId: map['userId'] as String?,
      roomId: map['roomId'] as String?,
    );
  }

  /// Convert to map for navigation
  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'userId': userId,
      'roomId': roomId,
    };
  }
}

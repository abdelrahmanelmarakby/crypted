import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Privacy Settings Model
/// Provides comprehensive privacy control with per-contact exceptions,
/// security features, and privacy checkup capabilities.

// ============================================================================
// ENUMS
// ============================================================================

/// Visibility level for privacy settings
enum VisibilityLevel {
  everyone('Everyone', 'Visible to all users'),
  contacts('My Contacts', 'Only visible to your contacts'),
  contactsExcept('My Contacts Except...', 'Contacts minus specific exclusions'),
  nobody('Nobody', 'Not visible to anyone'),
  nobodyExcept('Nobody Except...', 'Hidden except for specific people');

  const VisibilityLevel(this.displayName, this.description);
  final String displayName;
  final String description;

  static VisibilityLevel fromString(String? value) {
    if (value == null) return VisibilityLevel.contacts;
    return VisibilityLevel.values.firstWhere(
      (l) => l.name == value,
      orElse: () => VisibilityLevel.contacts,
    );
  }

  /// Whether this level supports exception lists
  bool get supportsExceptions =>
      this == contactsExcept || this == nobodyExcept;
}

/// Privacy setting field types
enum PrivacyField {
  lastSeen('lastSeen', 'Last Seen'),
  profilePhoto('profilePhoto', 'Profile Photo'),
  about('about', 'About'),
  onlineStatus('onlineStatus', 'Online Status'),
  status('status', 'Status Updates'),
  messages('messages', 'Who can message me'),
  calls('calls', 'Who can call me'),
  groups('groups', 'Who can add me to groups'),
  typingIndicator('typingIndicator', 'Typing indicator');

  const PrivacyField(this.key, this.displayName);
  final String key;
  final String displayName;

  static PrivacyField? fromKey(String key) {
    try {
      return PrivacyField.values.firstWhere((f) => f.key == key);
    } catch (e) {
      return null;
    }
  }
}

/// Disappearing message duration options
enum DisappearingDuration {
  off('Off', null),
  hours24('24 Hours', Duration(hours: 24)),
  days7('7 Days', Duration(days: 7)),
  days30('30 Days', Duration(days: 30)),
  days90('90 Days', Duration(days: 90));

  const DisappearingDuration(this.displayName, this.duration);
  final String displayName;
  final Duration? duration;

  static DisappearingDuration fromString(String? value) {
    if (value == null) return DisappearingDuration.off;
    return DisappearingDuration.values.firstWhere(
      (d) => d.name == value,
      orElse: () => DisappearingDuration.off,
    );
  }
}

/// App lock timeout options
enum AppLockTimeout {
  immediately('Immediately', Duration.zero),
  seconds30('After 30 seconds', Duration(seconds: 30)),
  minutes1('After 1 minute', Duration(minutes: 1)),
  minutes5('After 5 minutes', Duration(minutes: 5)),
  minutes15('After 15 minutes', Duration(minutes: 15)),
  hours1('After 1 hour', Duration(hours: 1));

  const AppLockTimeout(this.displayName, this.duration);
  final String displayName;
  final Duration duration;

  static AppLockTimeout fromString(String? value) {
    if (value == null) return AppLockTimeout.immediately;
    return AppLockTimeout.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AppLockTimeout.immediately,
    );
  }
}

/// Security event type for audit log
enum SecurityEventType {
  login('login', 'Login'),
  logout('logout', 'Logout'),
  passwordChange('passwordChange', 'Password Changed'),
  twoStepEnabled('twoStepEnabled', 'Two-Step Enabled'),
  twoStepDisabled('twoStepDisabled', 'Two-Step Disabled'),
  deviceAdded('deviceAdded', 'New Device Added'),
  deviceRemoved('deviceRemoved', 'Device Removed'),
  blockedUser('blockedUser', 'User Blocked'),
  unblockedUser('unblockedUser', 'User Unblocked'),
  privacyChanged('privacyChanged', 'Privacy Settings Changed'),
  appLockChanged('appLockChanged', 'App Lock Changed');

  const SecurityEventType(this.key, this.displayName);
  final String key;
  final String displayName;

  static SecurityEventType fromString(String? value) {
    if (value == null) return SecurityEventType.login;
    return SecurityEventType.values.firstWhere(
      (e) => e.key == value || e.name == value,
      orElse: () => SecurityEventType.login,
    );
  }
}

// ============================================================================
// SUB-MODELS
// ============================================================================

/// Privacy exception entry
class PrivacyException {
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final DateTime addedAt;

  const PrivacyException({
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory PrivacyException.fromMap(Map<String, dynamic> map) {
    return PrivacyException(
      userId: map['userId'] ?? '',
      userName: map['userName'],
      userPhotoUrl: map['userPhotoUrl'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(
          map['addedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

/// Visibility setting with exceptions
class VisibilitySettingWithExceptions {
  final VisibilityLevel level;
  final List<PrivacyException> includedUsers; // "Nobody except these"
  final List<PrivacyException> excludedUsers; // "Contacts except these"

  const VisibilitySettingWithExceptions({
    this.level = VisibilityLevel.contacts,
    this.includedUsers = const [],
    this.excludedUsers = const [],
  });

  VisibilitySettingWithExceptions copyWith({
    VisibilityLevel? level,
    List<PrivacyException>? includedUsers,
    List<PrivacyException>? excludedUsers,
  }) {
    return VisibilitySettingWithExceptions(
      level: level ?? this.level,
      includedUsers: includedUsers ?? this.includedUsers,
      excludedUsers: excludedUsers ?? this.excludedUsers,
    );
  }

  /// Check if a user can see this setting
  bool isVisibleTo(String userId, {required bool isContact}) {
    // Check exclusions first
    if (excludedUsers.any((e) => e.userId == userId)) {
      return false;
    }

    // Check inclusions
    if (includedUsers.any((e) => e.userId == userId)) {
      return true;
    }

    // Apply base level
    switch (level) {
      case VisibilityLevel.everyone:
        return true;
      case VisibilityLevel.contacts:
      case VisibilityLevel.contactsExcept:
        return isContact;
      case VisibilityLevel.nobody:
      case VisibilityLevel.nobodyExcept:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'includedUsers': includedUsers.map((e) => e.toMap()).toList(),
      'excludedUsers': excludedUsers.map((e) => e.toMap()).toList(),
    };
  }

  factory VisibilitySettingWithExceptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const VisibilitySettingWithExceptions();
    return VisibilitySettingWithExceptions(
      level: VisibilityLevel.fromString(map['level']),
      includedUsers: (map['includedUsers'] as List<dynamic>?)
              ?.map((e) => PrivacyException.fromMap(e))
              .toList() ??
          [],
      excludedUsers: (map['excludedUsers'] as List<dynamic>?)
              ?.map((e) => PrivacyException.fromMap(e))
              .toList() ??
          [],
    );
  }
}

/// Profile visibility settings
class ProfileVisibilitySettings {
  final VisibilitySettingWithExceptions lastSeen;
  final VisibilitySettingWithExceptions profilePhoto;
  final VisibilitySettingWithExceptions about;
  final VisibilitySettingWithExceptions onlineStatus;
  final VisibilitySettingWithExceptions status;

  const ProfileVisibilitySettings({
    this.lastSeen = const VisibilitySettingWithExceptions(),
    this.profilePhoto = const VisibilitySettingWithExceptions(
        level: VisibilityLevel.everyone),
    this.about = const VisibilitySettingWithExceptions(),
    this.onlineStatus = const VisibilitySettingWithExceptions(
        level: VisibilityLevel.everyone),
    this.status = const VisibilitySettingWithExceptions(),
  });

  ProfileVisibilitySettings copyWith({
    VisibilitySettingWithExceptions? lastSeen,
    VisibilitySettingWithExceptions? profilePhoto,
    VisibilitySettingWithExceptions? about,
    VisibilitySettingWithExceptions? onlineStatus,
    VisibilitySettingWithExceptions? status,
  }) {
    return ProfileVisibilitySettings(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      about: about ?? this.about,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      status: status ?? this.status,
    );
  }

  /// Get setting by field
  VisibilitySettingWithExceptions getByField(PrivacyField field) {
    switch (field) {
      case PrivacyField.lastSeen:
        return lastSeen;
      case PrivacyField.profilePhoto:
        return profilePhoto;
      case PrivacyField.about:
        return about;
      case PrivacyField.onlineStatus:
        return onlineStatus;
      case PrivacyField.status:
        return status;
      default:
        return const VisibilitySettingWithExceptions();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'lastSeen': lastSeen.toMap(),
      'profilePhoto': profilePhoto.toMap(),
      'about': about.toMap(),
      'onlineStatus': onlineStatus.toMap(),
      'status': status.toMap(),
    };
  }

  factory ProfileVisibilitySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ProfileVisibilitySettings();
    return ProfileVisibilitySettings(
      lastSeen: VisibilitySettingWithExceptions.fromMap(map['lastSeen']),
      profilePhoto:
          VisibilitySettingWithExceptions.fromMap(map['profilePhoto']),
      about: VisibilitySettingWithExceptions.fromMap(map['about']),
      onlineStatus:
          VisibilitySettingWithExceptions.fromMap(map['onlineStatus']),
      status: VisibilitySettingWithExceptions.fromMap(map['status']),
    );
  }
}

/// Communication privacy settings
class CommunicationSettings {
  final VisibilitySettingWithExceptions whoCanMessage;
  final VisibilitySettingWithExceptions whoCanCall;
  final VisibilitySettingWithExceptions whoCanAddToGroups;
  final bool showTypingIndicator;
  final bool showReadReceipts;

  const CommunicationSettings({
    this.whoCanMessage = const VisibilitySettingWithExceptions(
        level: VisibilityLevel.everyone),
    this.whoCanCall = const VisibilitySettingWithExceptions(),
    this.whoCanAddToGroups = const VisibilitySettingWithExceptions(
        level: VisibilityLevel.everyone),
    this.showTypingIndicator = true,
    this.showReadReceipts = true,
  });

  CommunicationSettings copyWith({
    VisibilitySettingWithExceptions? whoCanMessage,
    VisibilitySettingWithExceptions? whoCanCall,
    VisibilitySettingWithExceptions? whoCanAddToGroups,
    bool? showTypingIndicator,
    bool? showReadReceipts,
  }) {
    return CommunicationSettings(
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      whoCanCall: whoCanCall ?? this.whoCanCall,
      whoCanAddToGroups: whoCanAddToGroups ?? this.whoCanAddToGroups,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whoCanMessage': whoCanMessage.toMap(),
      'whoCanCall': whoCanCall.toMap(),
      'whoCanAddToGroups': whoCanAddToGroups.toMap(),
      'showTypingIndicator': showTypingIndicator,
      'showReadReceipts': showReadReceipts,
    };
  }

  factory CommunicationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CommunicationSettings();
    return CommunicationSettings(
      whoCanMessage:
          VisibilitySettingWithExceptions.fromMap(map['whoCanMessage']),
      whoCanCall: VisibilitySettingWithExceptions.fromMap(map['whoCanCall']),
      whoCanAddToGroups:
          VisibilitySettingWithExceptions.fromMap(map['whoCanAddToGroups']),
      showTypingIndicator: map['showTypingIndicator'] ?? true,
      showReadReceipts: map['showReadReceipts'] ?? true,
    );
  }
}

/// Content protection settings
class ContentProtectionSettings {
  final bool allowScreenshots;
  final bool allowForwarding;
  final bool allowCopyingText;
  final DisappearingDuration defaultDisappearingDuration;
  final bool hideMediaInGallery;
  final bool blurPreviewsInTaskSwitcher;

  const ContentProtectionSettings({
    this.allowScreenshots = true,
    this.allowForwarding = true,
    this.allowCopyingText = true,
    this.defaultDisappearingDuration = DisappearingDuration.off,
    this.hideMediaInGallery = false,
    this.blurPreviewsInTaskSwitcher = true,
  });

  ContentProtectionSettings copyWith({
    bool? allowScreenshots,
    bool? allowForwarding,
    bool? allowCopyingText,
    DisappearingDuration? defaultDisappearingDuration,
    bool? hideMediaInGallery,
    bool? blurPreviewsInTaskSwitcher,
  }) {
    return ContentProtectionSettings(
      allowScreenshots: allowScreenshots ?? this.allowScreenshots,
      allowForwarding: allowForwarding ?? this.allowForwarding,
      allowCopyingText: allowCopyingText ?? this.allowCopyingText,
      defaultDisappearingDuration:
          defaultDisappearingDuration ?? this.defaultDisappearingDuration,
      hideMediaInGallery: hideMediaInGallery ?? this.hideMediaInGallery,
      blurPreviewsInTaskSwitcher:
          blurPreviewsInTaskSwitcher ?? this.blurPreviewsInTaskSwitcher,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowScreenshots': allowScreenshots,
      'allowForwarding': allowForwarding,
      'allowCopyingText': allowCopyingText,
      'defaultDisappearingDuration': defaultDisappearingDuration.name,
      'hideMediaInGallery': hideMediaInGallery,
      'blurPreviewsInTaskSwitcher': blurPreviewsInTaskSwitcher,
    };
  }

  factory ContentProtectionSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ContentProtectionSettings();
    return ContentProtectionSettings(
      allowScreenshots: map['allowScreenshots'] ?? true,
      allowForwarding: map['allowForwarding'] ?? true,
      allowCopyingText: map['allowCopyingText'] ?? true,
      defaultDisappearingDuration:
          DisappearingDuration.fromString(map['defaultDisappearingDuration']),
      hideMediaInGallery: map['hideMediaInGallery'] ?? false,
      blurPreviewsInTaskSwitcher: map['blurPreviewsInTaskSwitcher'] ?? true,
    );
  }
}

/// Two-step verification settings
class TwoStepVerificationSettings {
  final bool enabled;
  final String? recoveryEmail;
  final bool emailVerified;
  final DateTime? lastPasswordChange;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const TwoStepVerificationSettings({
    this.enabled = false,
    this.recoveryEmail,
    this.emailVerified = false,
    this.lastPasswordChange,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  bool get isLocked =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  TwoStepVerificationSettings copyWith({
    bool? enabled,
    String? recoveryEmail,
    bool? emailVerified,
    DateTime? lastPasswordChange,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return TwoStepVerificationSettings(
      enabled: enabled ?? this.enabled,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      emailVerified: emailVerified ?? this.emailVerified,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'recoveryEmail': recoveryEmail,
      'emailVerified': emailVerified,
      'lastPasswordChange': lastPasswordChange?.millisecondsSinceEpoch,
      'failedAttempts': failedAttempts,
      'lockedUntil': lockedUntil?.millisecondsSinceEpoch,
    };
  }

  factory TwoStepVerificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TwoStepVerificationSettings();
    return TwoStepVerificationSettings(
      enabled: map['enabled'] ?? false,
      recoveryEmail: map['recoveryEmail'],
      emailVerified: map['emailVerified'] ?? false,
      lastPasswordChange: map['lastPasswordChange'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPasswordChange'])
          : null,
      failedAttempts: map['failedAttempts'] ?? 0,
      lockedUntil: map['lockedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lockedUntil'])
          : null,
    );
  }
}

/// App lock settings
class AppLockSettings {
  final bool enabled;
  final bool biometricEnabled;
  final AppLockTimeout timeout;
  final bool showContentInNotifications;
  final DateTime? lastUnlocked;

  const AppLockSettings({
    this.enabled = false,
    this.biometricEnabled = true,
    this.timeout = AppLockTimeout.immediately,
    this.showContentInNotifications = false,
    this.lastUnlocked,
  });

  AppLockSettings copyWith({
    bool? enabled,
    bool? biometricEnabled,
    AppLockTimeout? timeout,
    bool? showContentInNotifications,
    DateTime? lastUnlocked,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      timeout: timeout ?? this.timeout,
      showContentInNotifications:
          showContentInNotifications ?? this.showContentInNotifications,
      lastUnlocked: lastUnlocked ?? this.lastUnlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'biometricEnabled': biometricEnabled,
      'timeout': timeout.name,
      'showContentInNotifications': showContentInNotifications,
      'lastUnlocked': lastUnlocked?.millisecondsSinceEpoch,
    };
  }

  factory AppLockSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppLockSettings();
    return AppLockSettings(
      enabled: map['enabled'] ?? false,
      biometricEnabled: map['biometricEnabled'] ?? true,
      timeout: AppLockTimeout.fromString(map['timeout']),
      showContentInNotifications: map['showContentInNotifications'] ?? false,
      lastUnlocked: map['lastUnlocked'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUnlocked'])
          : null,
    );
  }
}

/// Locked chat entry
class LockedChat {
  final String chatId;
  final String? chatName;
  final String? chatPhotoUrl;
  final DateTime lockedAt;
  final bool requireBiometric;

  const LockedChat({
    required this.chatId,
    this.chatName,
    this.chatPhotoUrl,
    required this.lockedAt,
    this.requireBiometric = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'chatName': chatName,
      'chatPhotoUrl': chatPhotoUrl,
      'lockedAt': lockedAt.millisecondsSinceEpoch,
      'requireBiometric': requireBiometric,
    };
  }

  factory LockedChat.fromMap(Map<String, dynamic> map) {
    return LockedChat(
      chatId: map['chatId'] ?? '',
      chatName: map['chatName'],
      chatPhotoUrl: map['chatPhotoUrl'],
      lockedAt: DateTime.fromMillisecondsSinceEpoch(
          map['lockedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      requireBiometric: map['requireBiometric'] ?? true,
    );
  }
}

/// Security settings container
class SecuritySettings {
  final TwoStepVerificationSettings twoStepVerification;
  final AppLockSettings appLock;
  final List<LockedChat> lockedChats;
  final bool hideSecurityNotifications;
  final bool showSecurityAlerts;

  const SecuritySettings({
    this.twoStepVerification = const TwoStepVerificationSettings(),
    this.appLock = const AppLockSettings(),
    this.lockedChats = const [],
    this.hideSecurityNotifications = false,
    this.showSecurityAlerts = true,
  });

  SecuritySettings copyWith({
    TwoStepVerificationSettings? twoStepVerification,
    AppLockSettings? appLock,
    List<LockedChat>? lockedChats,
    bool? hideSecurityNotifications,
    bool? showSecurityAlerts,
  }) {
    return SecuritySettings(
      twoStepVerification: twoStepVerification ?? this.twoStepVerification,
      appLock: appLock ?? this.appLock,
      lockedChats: lockedChats ?? this.lockedChats,
      hideSecurityNotifications:
          hideSecurityNotifications ?? this.hideSecurityNotifications,
      showSecurityAlerts: showSecurityAlerts ?? this.showSecurityAlerts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'twoStepVerification': twoStepVerification.toMap(),
      'appLock': appLock.toMap(),
      'lockedChats': lockedChats.map((c) => c.toMap()).toList(),
      'hideSecurityNotifications': hideSecurityNotifications,
      'showSecurityAlerts': showSecurityAlerts,
    };
  }

  factory SecuritySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SecuritySettings();
    return SecuritySettings(
      twoStepVerification:
          TwoStepVerificationSettings.fromMap(map['twoStepVerification']),
      appLock: AppLockSettings.fromMap(map['appLock']),
      lockedChats: (map['lockedChats'] as List<dynamic>?)
              ?.map((c) => LockedChat.fromMap(c))
              .toList() ??
          [],
      hideSecurityNotifications: map['hideSecurityNotifications'] ?? false,
      showSecurityAlerts: map['showSecurityAlerts'] ?? true,
    );
  }
}

/// Blocked user entry
class BlockedUser {
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final DateTime blockedAt;
  final String? reason;

  const BlockedUser({
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.blockedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'blockedAt': blockedAt.millisecondsSinceEpoch,
      'reason': reason,
    };
  }

  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    return BlockedUser(
      userId: map['userId'] ?? '',
      userName: map['userName'],
      userPhotoUrl: map['userPhotoUrl'],
      blockedAt: DateTime.fromMillisecondsSinceEpoch(
          map['blockedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      reason: map['reason'],
    );
  }
}

/// Live location share entry
class LiveLocationShare {
  final String chatId;
  final String? chatName;
  final DateTime startedAt;
  final DateTime expiresAt;
  final Duration duration;

  const LiveLocationShare({
    required this.chatId,
    this.chatName,
    required this.startedAt,
    required this.expiresAt,
    required this.duration,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'chatName': chatName,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'durationMinutes': duration.inMinutes,
    };
  }

  factory LiveLocationShare.fromMap(Map<String, dynamic> map) {
    return LiveLocationShare(
      chatId: map['chatId'] ?? '',
      chatName: map['chatName'],
      startedAt: DateTime.fromMillisecondsSinceEpoch(
          map['startedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
          map['expiresAt'] ?? DateTime.now().millisecondsSinceEpoch),
      duration: Duration(minutes: map['durationMinutes'] ?? 60),
    );
  }
}

/// Active session info
class ActiveSession {
  final String sessionId;
  final String deviceName;
  final String deviceType; // 'mobile', 'tablet', 'desktop', 'web'
  final String? location;
  final String? ipAddress;
  final DateTime lastActive;
  final DateTime createdAt;
  final bool isCurrentSession;

  const ActiveSession({
    required this.sessionId,
    required this.deviceName,
    required this.deviceType,
    this.location,
    this.ipAddress,
    required this.lastActive,
    required this.createdAt,
    this.isCurrentSession = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'location': location,
      'ipAddress': ipAddress,
      'lastActive': lastActive.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCurrentSession': isCurrentSession,
    };
  }

  factory ActiveSession.fromMap(Map<String, dynamic> map) {
    return ActiveSession(
      sessionId: map['sessionId'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      deviceType: map['deviceType'] ?? 'mobile',
      location: map['location'],
      ipAddress: map['ipAddress'],
      lastActive: DateTime.fromMillisecondsSinceEpoch(
          map['lastActive'] ?? DateTime.now().millisecondsSinceEpoch),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      isCurrentSession: map['isCurrentSession'] ?? false,
    );
  }
}

/// Security log entry
class SecurityLogEntry {
  final String id;
  final SecurityEventType eventType;
  final DateTime timestamp;
  final String? deviceName;
  final String? location;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;

  const SecurityLogEntry({
    required this.id,
    required this.eventType,
    required this.timestamp,
    this.deviceName,
    this.location,
    this.ipAddress,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType.key,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceName': deviceName,
      'location': location,
      'ipAddress': ipAddress,
      'metadata': metadata,
    };
  }

  factory SecurityLogEntry.fromMap(Map<String, dynamic> map) {
    return SecurityLogEntry(
      id: map['id'] ?? '',
      eventType: SecurityEventType.fromString(map['eventType']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      deviceName: map['deviceName'],
      location: map['location'],
      ipAddress: map['ipAddress'],
      metadata: map['metadata'],
    );
  }
}

// ============================================================================
// PRIVACY CHECKUP
// ============================================================================

/// Privacy checkup result
class PrivacyCheckupResult {
  final int score; // 0-100
  final List<PrivacyIssue> issues;
  final List<PrivacyRecommendation> recommendations;
  final DateTime checkedAt;

  const PrivacyCheckupResult({
    required this.score,
    required this.issues,
    required this.recommendations,
    required this.checkedAt,
  });

  String get scoreLabel {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'issues': issues.map((i) => i.toMap()).toList(),
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'checkedAt': checkedAt.millisecondsSinceEpoch,
    };
  }

  factory PrivacyCheckupResult.fromMap(Map<String, dynamic> map) {
    return PrivacyCheckupResult(
      score: map['score'] ?? 0,
      issues: (map['issues'] as List<dynamic>?)
              ?.map((i) => PrivacyIssue.fromMap(i))
              .toList() ??
          [],
      recommendations: (map['recommendations'] as List<dynamic>?)
              ?.map((r) => PrivacyRecommendation.fromMap(r))
              .toList() ??
          [],
      checkedAt: DateTime.fromMillisecondsSinceEpoch(
          map['checkedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

/// Privacy issue found during checkup
class PrivacyIssue {
  final String id;
  final String title;
  final String description;
  final PrivacyField? relatedField;
  final int severityScore; // 1-10
  final bool canAutoFix;

  const PrivacyIssue({
    required this.id,
    required this.title,
    required this.description,
    this.relatedField,
    required this.severityScore,
    this.canAutoFix = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'relatedField': relatedField?.key,
      'severityScore': severityScore,
      'canAutoFix': canAutoFix,
    };
  }

  factory PrivacyIssue.fromMap(Map<String, dynamic> map) {
    return PrivacyIssue(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      relatedField: PrivacyField.fromKey(map['relatedField'] ?? ''),
      severityScore: map['severityScore'] ?? 1,
      canAutoFix: map['canAutoFix'] ?? false,
    );
  }
}

/// Privacy recommendation
class PrivacyRecommendation {
  final String id;
  final String title;
  final String description;
  final PrivacyField? relatedField;
  final String? actionLabel;
  final int priority; // 1-5

  const PrivacyRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.relatedField,
    this.actionLabel,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'relatedField': relatedField?.key,
      'actionLabel': actionLabel,
      'priority': priority,
    };
  }

  factory PrivacyRecommendation.fromMap(Map<String, dynamic> map) {
    return PrivacyRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      relatedField: PrivacyField.fromKey(map['relatedField'] ?? ''),
      actionLabel: map['actionLabel'],
      priority: map['priority'] ?? 3,
    );
  }
}

// ============================================================================
// MAIN MODEL
// ============================================================================

/// Enhanced Privacy Settings Model
class EnhancedPrivacySettingsModel {
  final ProfileVisibilitySettings profileVisibility;
  final CommunicationSettings communication;
  final ContentProtectionSettings contentProtection;
  final SecuritySettings security;
  final List<BlockedUser> blockedUsers;
  final List<LiveLocationShare> liveLocationShares;
  final PrivacyCheckupResult? lastCheckupResult;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  const EnhancedPrivacySettingsModel({
    this.profileVisibility = const ProfileVisibilitySettings(),
    this.communication = const CommunicationSettings(),
    this.contentProtection = const ContentProtectionSettings(),
    this.security = const SecuritySettings(),
    this.blockedUsers = const [],
    this.liveLocationShares = const [],
    this.lastCheckupResult,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  factory EnhancedPrivacySettingsModel.defaultSettings() {
    final now = DateTime.now();
    return EnhancedPrivacySettingsModel(
      createdAt: now,
      updatedAt: now,
    );
  }

  EnhancedPrivacySettingsModel copyWith({
    ProfileVisibilitySettings? profileVisibility,
    CommunicationSettings? communication,
    ContentProtectionSettings? contentProtection,
    SecuritySettings? security,
    List<BlockedUser>? blockedUsers,
    List<LiveLocationShare>? liveLocationShares,
    PrivacyCheckupResult? lastCheckupResult,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return EnhancedPrivacySettingsModel(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      communication: communication ?? this.communication,
      contentProtection: contentProtection ?? this.contentProtection,
      security: security ?? this.security,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      liveLocationShares: liveLocationShares ?? this.liveLocationShares,
      lastCheckupResult: lastCheckupResult ?? this.lastCheckupResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  /// Calculate current privacy score
  int calculatePrivacyScore() {
    int score = 100;
    int deductions = 0;

    // Profile visibility checks
    if (profileVisibility.lastSeen.level == VisibilityLevel.everyone) {
      deductions += 5;
    }
    if (profileVisibility.profilePhoto.level == VisibilityLevel.everyone) {
      deductions += 3;
    }
    if (profileVisibility.onlineStatus.level == VisibilityLevel.everyone) {
      deductions += 3;
    }

    // Communication checks
    if (communication.whoCanMessage.level == VisibilityLevel.everyone) {
      deductions += 5;
    }
    if (communication.whoCanAddToGroups.level == VisibilityLevel.everyone) {
      deductions += 3;
    }

    // Content protection checks
    if (contentProtection.allowScreenshots) deductions += 2;
    if (contentProtection.allowForwarding) deductions += 2;
    if (contentProtection.defaultDisappearingDuration ==
        DisappearingDuration.off) {
      deductions += 5;
    }

    // Security checks
    if (!security.twoStepVerification.enabled) deductions += 15;
    if (!security.appLock.enabled) deductions += 10;

    return (score - deductions).clamp(0, 100);
  }

  /// Check if a user is blocked
  bool isBlocked(String userId) {
    return blockedUsers.any((b) => b.userId == userId);
  }

  /// Get active live location shares
  List<LiveLocationShare> get activeLiveLocationShares {
    return liveLocationShares.where((l) => l.isActive).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility.toMap(),
      'communication': communication.toMap(),
      'contentProtection': contentProtection.toMap(),
      'security': security.toMap(),
      'blockedUsers': blockedUsers.map((b) => b.toMap()).toList(),
      'liveLocationShares': liveLocationShares.map((l) => l.toMap()).toList(),
      'lastCheckupResult': lastCheckupResult?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'schemaVersion': schemaVersion,
    };
  }

  factory EnhancedPrivacySettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EnhancedPrivacySettingsModel.defaultSettings();
    return EnhancedPrivacySettingsModel(
      profileVisibility:
          ProfileVisibilitySettings.fromMap(map['profileVisibility']),
      communication: CommunicationSettings.fromMap(map['communication']),
      contentProtection:
          ContentProtectionSettings.fromMap(map['contentProtection']),
      security: SecuritySettings.fromMap(map['security']),
      blockedUsers: (map['blockedUsers'] as List<dynamic>?)
              ?.map((b) => BlockedUser.fromMap(b))
              .toList() ??
          [],
      liveLocationShares: (map['liveLocationShares'] as List<dynamic>?)
              ?.map((l) => LiveLocationShare.fromMap(l))
              .toList() ??
          [],
      lastCheckupResult: map['lastCheckupResult'] != null
          ? PrivacyCheckupResult.fromMap(map['lastCheckupResult'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }
}

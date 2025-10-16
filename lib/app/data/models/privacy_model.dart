// Enums for privacy dropdown options
enum PrivacyLevel {
  nobody('Nobody'),
  myContacts('My Contacts'),
  everyone('Everyone');

  const PrivacyLevel(this.value);
  final String value;

  static PrivacyLevel fromString(String value) {
    return PrivacyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => PrivacyLevel.nobody,
    );
  }
}

enum ProfilePictureLevel {
  everyone('Everyone'),
  myContacts('My Contacts'),
  nobody('Nobody'),
  excluded('Excluded');

  const ProfilePictureLevel(this.value);
  final String value;

  static ProfilePictureLevel fromString(String value) {
    return ProfilePictureLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => ProfilePictureLevel.everyone,
    );
  }
}

enum LiveLocationLevel {
  none('None'),
  myContacts('My Contacts'),
  everyone('Everyone');

  const LiveLocationLevel(this.value);
  final String value;

  static LiveLocationLevel fromString(String value) {
    return LiveLocationLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => LiveLocationLevel.none,
    );
  }
}

enum BlockedLevel {
  contacts('12 Contacts'),
  allContacts('All Contacts'),
  none('None');

  const BlockedLevel(this.value);
  final String value;

  static BlockedLevel fromString(String value) {
    return BlockedLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => BlockedLevel.contacts,
    );
  }
}

enum MessageTimerLevel {
  off('Off'),
  hours24('24 Hours'),
  days7('7 Days'),
  days90('90 Days');

  const MessageTimerLevel(this.value);
  final String value;

  static MessageTimerLevel fromString(String value) {
    return MessageTimerLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => MessageTimerLevel.off,
    );
  }
}

class Privacy {
  final PrivacyLevel lastSeen;
  final ProfilePictureLevel profilePicture;
  final PrivacyLevel about;
  final PrivacyLevel groups;
  final PrivacyLevel status;
  final LiveLocationLevel liveLocation;
  final String calls;
  final BlockedLevel blocked;
  final bool timer;
  final bool receipts;
  final String appLock;
  final String chatLock;
  final bool allowCamera;
  final String advanced;
  final String checkup;
  final MessageTimerLevel defaultMessageTimer;

  Privacy({
    required this.lastSeen,
    required this.profilePicture,
    required this.about,
    required this.groups,
    required this.status,
    required this.liveLocation,
    required this.calls,
    required this.blocked,
    required this.timer,
    required this.receipts,
    required this.appLock,
    required this.chatLock,
    required this.allowCamera,
    required this.advanced,
    required this.checkup,
    required this.defaultMessageTimer,
  });

  factory Privacy.fromMap(Map<String, dynamic> map) {
    return Privacy(
      lastSeen: PrivacyLevel.fromString(map['lastSeen'] ?? 'Nobody'),
      profilePicture:
          ProfilePictureLevel.fromString(map['profilePicture'] ?? 'Everyone'),
      about: PrivacyLevel.fromString(map['about'] ?? 'Everyone'),
      groups: PrivacyLevel.fromString(map['groups'] ?? 'Everyone'),
      status: PrivacyLevel.fromString(map['status'] ?? 'My Contacts'),
      liveLocation: LiveLocationLevel.fromString(map['liveLocation'] ?? 'None'),
      calls: map['calls'] ?? '',
      blocked: BlockedLevel.fromString(map['blocked'] ?? '12 Contacts'),
      timer: map['timer'] ?? false,
      receipts: map['receipts'] ?? false,
      appLock: map['appLock'] ?? '',
      chatLock: map['chatLock'] ?? '',
      allowCamera: map['allowCamera'] ?? false,
      advanced: map['advanced'] ?? '',
      checkup: map['checkup'] ?? '',
      defaultMessageTimer:
          MessageTimerLevel.fromString(map['defaultMessageTimer'] ?? 'Off'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastSeen': lastSeen.value,
      'profilePicture': profilePicture.value,
      'about': about.value,
      'groups': groups.value,
      'status': status.value,
      'liveLocation': liveLocation.value,
      'calls': calls,
      'blocked': blocked.value,
      'timer': timer,
      'receipts': receipts,
      'appLock': appLock,
      'chatLock': chatLock,
      'allowCamera': allowCamera,
      'advanced': advanced,
      'checkup': checkup,
      'defaultMessageTimer': defaultMessageTimer.value,
    };
  }

  Privacy copyWith({
    PrivacyLevel? lastSeen,
    ProfilePictureLevel? profilePicture,
    PrivacyLevel? about,
    PrivacyLevel? groups,
    PrivacyLevel? status,
    LiveLocationLevel? liveLocation,
    String? calls,
    BlockedLevel? blocked,
    bool? timer,
    bool? receipts,
    String? appLock,
    String? chatLock,
    bool? allowCamera,
    String? advanced,
    String? checkup,
    MessageTimerLevel? defaultMessageTimer,
  }) {
    return Privacy(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePicture: profilePicture ?? this.profilePicture,
      about: about ?? this.about,
      groups: groups ?? this.groups,
      status: status ?? this.status,
      liveLocation: liveLocation ?? this.liveLocation,
      calls: calls ?? this.calls,
      blocked: blocked ?? this.blocked,
      timer: timer ?? this.timer,
      receipts: receipts ?? this.receipts,
      appLock: appLock ?? this.appLock,
      chatLock: chatLock ?? this.chatLock,
      allowCamera: allowCamera ?? this.allowCamera,
      advanced: advanced ?? this.advanced,
      checkup: checkup ?? this.checkup,
      defaultMessageTimer: defaultMessageTimer ?? this.defaultMessageTimer,
    );
  }
}

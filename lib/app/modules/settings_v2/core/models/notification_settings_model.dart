import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enhanced Notification Settings Model
/// Provides comprehensive notification control with DND, per-chat overrides,
/// and advanced customization options.

// ============================================================================
// ENUMS
// ============================================================================

/// Notification sound options
enum NotificationSound {
  none('None', null),
  defaultSound('Default', 'default'),
  chime('Chime', 'chime'),
  ding('Ding', 'ding'),
  pop('Pop', 'pop'),
  swoosh('Swoosh', 'swoosh'),
  bell('Bell', 'bell'),
  note('Note', 'note'),
  crystal('Crystal', 'crystal'),
  bubble('Bubble', 'bubble'),
  droplet('Droplet', 'droplet'),
  bamboo('Bamboo', 'bamboo'),
  chord('Chord', 'chord'),
  ping('Ping', 'ping');

  const NotificationSound(this.displayName, this.fileName);
  final String displayName;
  final String? fileName;

  static NotificationSound fromString(String? value) {
    if (value == null) return NotificationSound.defaultSound;
    return NotificationSound.values.firstWhere(
      (s) => s.fileName == value || s.name == value,
      orElse: () => NotificationSound.defaultSound,
    );
  }
}

/// Vibration pattern options
enum VibrationPattern {
  none('None', []),
  short('Short', [100]),
  medium('Medium', [200]),
  long_('Long', [400]),
  double_('Double', [100, 100, 100]),
  triple('Triple', [100, 100, 100, 100, 100]),
  heartbeat('Heartbeat', [100, 100, 300]),
  sos('SOS', [100, 100, 100, 100, 100, 100, 300, 300, 300, 100, 100, 100]),
  pulse('Pulse', [150, 50, 150, 50, 150]),
  gentle('Gentle', [50, 50, 50]);

  const VibrationPattern(this.displayName, this.pattern);
  final String displayName;
  final List<int> pattern;

  static VibrationPattern fromString(String? value) {
    if (value == null) return VibrationPattern.medium;
    return VibrationPattern.values.firstWhere(
      (p) => p.name == value,
      orElse: () => VibrationPattern.medium,
    );
  }
}

/// Notification priority levels
enum NotificationPriority {
  low('Low', 'min'),
  normal('Normal', 'default'),
  high('High', 'high'),
  urgent('Urgent', 'max');

  const NotificationPriority(this.displayName, this.channelImportance);
  final String displayName;
  final String channelImportance;

  static NotificationPriority fromString(String? value) {
    if (value == null) return NotificationPriority.high;
    return NotificationPriority.values.firstWhere(
      (p) => p.name == value || p.channelImportance == value,
      orElse: () => NotificationPriority.high,
    );
  }
}

/// Notification preview level
enum PreviewLevel {
  always('Always', 'Show message content always'),
  whenUnlocked('When Unlocked', 'Show content only when device is unlocked'),
  never('Never', 'Never show message content');

  const PreviewLevel(this.displayName, this.description);
  final String displayName;
  final String description;

  static PreviewLevel fromString(String? value) {
    if (value == null) return PreviewLevel.whenUnlocked;
    return PreviewLevel.values.firstWhere(
      (p) => p.name == value,
      orElse: () => PreviewLevel.whenUnlocked,
    );
  }
}

/// Notification grouping style
enum NotificationGrouping {
  off('Off', 'Show each notification separately'),
  byContact('By Contact', 'Group notifications by sender'),
  byChatType('By Chat Type', 'Group by messages, groups, etc.'),
  all('All', 'Group all notifications together');

  const NotificationGrouping(this.displayName, this.description);
  final String displayName;
  final String description;

  static NotificationGrouping fromString(String? value) {
    if (value == null) return NotificationGrouping.byContact;
    return NotificationGrouping.values.firstWhere(
      (g) => g.name == value,
      orElse: () => NotificationGrouping.byContact,
    );
  }
}

/// DND mode options
enum DNDMode {
  totalSilence('Total Silence', 'Block all notifications'),
  alarmsOnly('Alarms Only', 'Only allow alarms'),
  priorityOnly('Priority Only', 'Allow priority notifications');

  const DNDMode(this.displayName, this.description);
  final String displayName;
  final String description;

  static DNDMode fromString(String? value) {
    if (value == null) return DNDMode.totalSilence;
    return DNDMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => DNDMode.totalSilence,
    );
  }
}

/// Digest frequency options
enum DigestFrequency {
  never('Never', null),
  hourly('Hourly', Duration(hours: 1)),
  every3Hours('Every 3 Hours', Duration(hours: 3)),
  every6Hours('Every 6 Hours', Duration(hours: 6)),
  daily('Daily', Duration(days: 1)),
  weekly('Weekly', Duration(days: 7));

  const DigestFrequency(this.displayName, this.duration);
  final String displayName;
  final Duration? duration;

  static DigestFrequency fromString(String? value) {
    if (value == null) return DigestFrequency.never;
    return DigestFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => DigestFrequency.never,
    );
  }
}

/// Mute duration options
enum MuteDuration {
  oneHour('1 Hour', Duration(hours: 1)),
  eightHours('8 Hours', Duration(hours: 8)),
  oneDay('1 Day', Duration(days: 1)),
  oneWeek('1 Week', Duration(days: 7)),
  forever('Forever', null);

  const MuteDuration(this.displayName, this.duration);
  final String displayName;
  final Duration? duration;

  static MuteDuration fromString(String? value) {
    if (value == null) return MuteDuration.forever;
    return MuteDuration.values.firstWhere(
      (d) => d.name == value,
      orElse: () => MuteDuration.forever,
    );
  }

  DateTime? getUnmuteTime() {
    if (duration == null) return null;
    return DateTime.now().add(duration!);
  }
}

// ============================================================================
// SUB-MODELS
// ============================================================================

/// Sound configuration
class SoundConfig {
  final NotificationSound sound;
  final double volume; // 0.0 - 1.0
  final bool customSound;
  final String? customSoundPath;

  const SoundConfig({
    this.sound = NotificationSound.defaultSound,
    this.volume = 1.0,
    this.customSound = false,
    this.customSoundPath,
  });

  SoundConfig copyWith({
    NotificationSound? sound,
    double? volume,
    bool? customSound,
    String? customSoundPath,
  }) {
    return SoundConfig(
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      customSound: customSound ?? this.customSound,
      customSoundPath: customSoundPath ?? this.customSoundPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sound': sound.name,
      'volume': volume,
      'customSound': customSound,
      'customSoundPath': customSoundPath,
    };
  }

  factory SoundConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SoundConfig();
    return SoundConfig(
      sound: NotificationSound.fromString(map['sound']),
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      customSound: map['customSound'] ?? false,
      customSoundPath: map['customSoundPath'],
    );
  }

  static const SoundConfig defaultConfig = SoundConfig();
}

/// Global notification settings
class GlobalNotificationSettings {
  final bool masterSwitch;
  final PreviewLevel showPreviews;
  final NotificationGrouping grouping;
  final bool showBadgeCount;
  final bool inAppSounds;
  final bool inAppVibration;

  const GlobalNotificationSettings({
    this.masterSwitch = true,
    this.showPreviews = PreviewLevel.whenUnlocked,
    this.grouping = NotificationGrouping.byContact,
    this.showBadgeCount = true,
    this.inAppSounds = true,
    this.inAppVibration = true,
  });

  GlobalNotificationSettings copyWith({
    bool? masterSwitch,
    PreviewLevel? showPreviews,
    NotificationGrouping? grouping,
    bool? showBadgeCount,
    bool? inAppSounds,
    bool? inAppVibration,
  }) {
    return GlobalNotificationSettings(
      masterSwitch: masterSwitch ?? this.masterSwitch,
      showPreviews: showPreviews ?? this.showPreviews,
      grouping: grouping ?? this.grouping,
      showBadgeCount: showBadgeCount ?? this.showBadgeCount,
      inAppSounds: inAppSounds ?? this.inAppSounds,
      inAppVibration: inAppVibration ?? this.inAppVibration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'masterSwitch': masterSwitch,
      'showPreviews': showPreviews.name,
      'grouping': grouping.name,
      'showBadgeCount': showBadgeCount,
      'inAppSounds': inAppSounds,
      'inAppVibration': inAppVibration,
    };
  }

  factory GlobalNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GlobalNotificationSettings();
    return GlobalNotificationSettings(
      masterSwitch: map['masterSwitch'] ?? true,
      showPreviews: PreviewLevel.fromString(map['showPreviews']),
      grouping: NotificationGrouping.fromString(map['grouping']),
      showBadgeCount: map['showBadgeCount'] ?? true,
      inAppSounds: map['inAppSounds'] ?? true,
      inAppVibration: map['inAppVibration'] ?? true,
    );
  }
}

/// Message notification settings
class MessageNotificationSettings {
  final bool enabled;
  final SoundConfig sound;
  final VibrationPattern vibration;
  final NotificationPriority priority;
  final bool reactions;
  final int? ledColor;

  const MessageNotificationSettings({
    this.enabled = true,
    this.sound = const SoundConfig(),
    this.vibration = VibrationPattern.medium,
    this.priority = NotificationPriority.high,
    this.reactions = true,
    this.ledColor,
  });

  MessageNotificationSettings copyWith({
    bool? enabled,
    SoundConfig? sound,
    VibrationPattern? vibration,
    NotificationPriority? priority,
    bool? reactions,
    int? ledColor,
  }) {
    return MessageNotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      priority: priority ?? this.priority,
      reactions: reactions ?? this.reactions,
      ledColor: ledColor ?? this.ledColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sound': sound.toMap(),
      'vibration': vibration.name,
      'priority': priority.name,
      'reactions': reactions,
      'ledColor': ledColor,
    };
  }

  factory MessageNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MessageNotificationSettings();
    return MessageNotificationSettings(
      enabled: map['enabled'] ?? true,
      sound: SoundConfig.fromMap(map['sound']),
      vibration: VibrationPattern.fromString(map['vibration']),
      priority: NotificationPriority.fromString(map['priority']),
      reactions: map['reactions'] ?? true,
      ledColor: map['ledColor'],
    );
  }
}

/// Group notification settings
class GroupNotificationSettings {
  final bool enabled;
  final SoundConfig sound;
  final VibrationPattern vibration;
  final NotificationPriority priority;
  final bool reactions;
  final bool mentionsOnly;
  final int? ledColor;

  const GroupNotificationSettings({
    this.enabled = true,
    this.sound = const SoundConfig(),
    this.vibration = VibrationPattern.medium,
    this.priority = NotificationPriority.high,
    this.reactions = true,
    this.mentionsOnly = false,
    this.ledColor,
  });

  GroupNotificationSettings copyWith({
    bool? enabled,
    SoundConfig? sound,
    VibrationPattern? vibration,
    NotificationPriority? priority,
    bool? reactions,
    bool? mentionsOnly,
    int? ledColor,
  }) {
    return GroupNotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      priority: priority ?? this.priority,
      reactions: reactions ?? this.reactions,
      mentionsOnly: mentionsOnly ?? this.mentionsOnly,
      ledColor: ledColor ?? this.ledColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sound': sound.toMap(),
      'vibration': vibration.name,
      'priority': priority.name,
      'reactions': reactions,
      'mentionsOnly': mentionsOnly,
      'ledColor': ledColor,
    };
  }

  factory GroupNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GroupNotificationSettings();
    return GroupNotificationSettings(
      enabled: map['enabled'] ?? true,
      sound: SoundConfig.fromMap(map['sound']),
      vibration: VibrationPattern.fromString(map['vibration']),
      priority: NotificationPriority.fromString(map['priority']),
      reactions: map['reactions'] ?? true,
      mentionsOnly: map['mentionsOnly'] ?? false,
      ledColor: map['ledColor'],
    );
  }
}

/// Status/Story notification settings
class StatusNotificationSettings {
  final bool enabled;
  final SoundConfig sound;
  final bool contactsOnly;
  final bool reactions;

  const StatusNotificationSettings({
    this.enabled = true,
    this.sound = const SoundConfig(),
    this.contactsOnly = true,
    this.reactions = true,
  });

  StatusNotificationSettings copyWith({
    bool? enabled,
    SoundConfig? sound,
    bool? contactsOnly,
    bool? reactions,
  }) {
    return StatusNotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      contactsOnly: contactsOnly ?? this.contactsOnly,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sound': sound.toMap(),
      'contactsOnly': contactsOnly,
      'reactions': reactions,
    };
  }

  factory StatusNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const StatusNotificationSettings();
    return StatusNotificationSettings(
      enabled: map['enabled'] ?? true,
      sound: SoundConfig.fromMap(map['sound']),
      contactsOnly: map['contactsOnly'] ?? true,
      reactions: map['reactions'] ?? true,
    );
  }
}

/// Call notification settings
class CallNotificationSettings {
  final SoundConfig ringtone;
  final VibrationPattern vibration;
  final bool silentWhenDND;
  final bool flashOnRing;

  const CallNotificationSettings({
    this.ringtone = const SoundConfig(sound: NotificationSound.bell),
    this.vibration = VibrationPattern.long_,
    this.silentWhenDND = true,
    this.flashOnRing = false,
  });

  CallNotificationSettings copyWith({
    SoundConfig? ringtone,
    VibrationPattern? vibration,
    bool? silentWhenDND,
    bool? flashOnRing,
  }) {
    return CallNotificationSettings(
      ringtone: ringtone ?? this.ringtone,
      vibration: vibration ?? this.vibration,
      silentWhenDND: silentWhenDND ?? this.silentWhenDND,
      flashOnRing: flashOnRing ?? this.flashOnRing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ringtone': ringtone.toMap(),
      'vibration': vibration.name,
      'silentWhenDND': silentWhenDND,
      'flashOnRing': flashOnRing,
    };
  }

  factory CallNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CallNotificationSettings();
    return CallNotificationSettings(
      ringtone: SoundConfig.fromMap(map['ringtone']),
      vibration: VibrationPattern.fromString(map['vibration']),
      silentWhenDND: map['silentWhenDND'] ?? true,
      flashOnRing: map['flashOnRing'] ?? false,
    );
  }
}

/// Reminder notification settings
class ReminderNotificationSettings {
  final bool enabled;
  final Duration reminderDelay;
  final int maxReminders;

  const ReminderNotificationSettings({
    this.enabled = true,
    this.reminderDelay = const Duration(minutes: 15),
    this.maxReminders = 3,
  });

  ReminderNotificationSettings copyWith({
    bool? enabled,
    Duration? reminderDelay,
    int? maxReminders,
  }) {
    return ReminderNotificationSettings(
      enabled: enabled ?? this.enabled,
      reminderDelay: reminderDelay ?? this.reminderDelay,
      maxReminders: maxReminders ?? this.maxReminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'reminderDelayMinutes': reminderDelay.inMinutes,
      'maxReminders': maxReminders,
    };
  }

  factory ReminderNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ReminderNotificationSettings();
    return ReminderNotificationSettings(
      enabled: map['enabled'] ?? true,
      reminderDelay: Duration(minutes: map['reminderDelayMinutes'] ?? 15),
      maxReminders: map['maxReminders'] ?? 3,
    );
  }
}

/// Digest notification settings
class DigestNotificationSettings {
  final bool enabled;
  final DigestFrequency frequency;
  final TimeOfDay deliveryTime;
  final bool includePreview;

  const DigestNotificationSettings({
    this.enabled = false,
    this.frequency = DigestFrequency.daily,
    this.deliveryTime = const TimeOfDay(hour: 9, minute: 0),
    this.includePreview = true,
  });

  DigestNotificationSettings copyWith({
    bool? enabled,
    DigestFrequency? frequency,
    TimeOfDay? deliveryTime,
    bool? includePreview,
  }) {
    return DigestNotificationSettings(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      includePreview: includePreview ?? this.includePreview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'frequency': frequency.name,
      'deliveryTimeHour': deliveryTime.hour,
      'deliveryTimeMinute': deliveryTime.minute,
      'includePreview': includePreview,
    };
  }

  factory DigestNotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DigestNotificationSettings();
    return DigestNotificationSettings(
      enabled: map['enabled'] ?? false,
      frequency: DigestFrequency.fromString(map['frequency']),
      deliveryTime: TimeOfDay(
        hour: map['deliveryTimeHour'] ?? 9,
        minute: map['deliveryTimeMinute'] ?? 0,
      ),
      includePreview: map['includePreview'] ?? true,
    );
  }
}

// ============================================================================
// DND MODELS
// ============================================================================

/// DND Schedule configuration
class DNDSchedule {
  final String id;
  final String name;
  final bool enabled;
  final List<int> daysOfWeek; // 0-6 (Sun-Sat)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DNDMode mode;
  final List<String> allowedContacts;
  final bool allowRepeatCallers;
  final int repeatCallsThreshold; // Number of calls within minutes
  final int repeatCallsWindow; // Minutes
  final String? autoReplyMessage;

  const DNDSchedule({
    required this.id,
    required this.name,
    this.enabled = true,
    this.daysOfWeek = const [1, 2, 3, 4, 5], // Mon-Fri
    this.startTime = const TimeOfDay(hour: 22, minute: 0),
    this.endTime = const TimeOfDay(hour: 7, minute: 0),
    this.mode = DNDMode.totalSilence,
    this.allowedContacts = const [],
    this.allowRepeatCallers = true,
    this.repeatCallsThreshold = 2,
    this.repeatCallsWindow = 3,
    this.autoReplyMessage,
  });

  DNDSchedule copyWith({
    String? id,
    String? name,
    bool? enabled,
    List<int>? daysOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DNDMode? mode,
    List<String>? allowedContacts,
    bool? allowRepeatCallers,
    int? repeatCallsThreshold,
    int? repeatCallsWindow,
    String? autoReplyMessage,
  }) {
    return DNDSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      mode: mode ?? this.mode,
      allowedContacts: allowedContacts ?? this.allowedContacts,
      allowRepeatCallers: allowRepeatCallers ?? this.allowRepeatCallers,
      repeatCallsThreshold: repeatCallsThreshold ?? this.repeatCallsThreshold,
      repeatCallsWindow: repeatCallsWindow ?? this.repeatCallsWindow,
      autoReplyMessage: autoReplyMessage ?? this.autoReplyMessage,
    );
  }

  /// Check if schedule is currently active
  bool isActiveNow() {
    final now = DateTime.now();
    final currentDay = now.weekday % 7; // Convert to 0-6 (Sun-Sat)

    if (!enabled || !daysOfWeek.contains(currentDay)) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle overnight schedules (e.g., 22:00 - 07:00)
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'daysOfWeek': daysOfWeek,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'mode': mode.name,
      'allowedContacts': allowedContacts,
      'allowRepeatCallers': allowRepeatCallers,
      'repeatCallsThreshold': repeatCallsThreshold,
      'repeatCallsWindow': repeatCallsWindow,
      'autoReplyMessage': autoReplyMessage,
    };
  }

  factory DNDSchedule.fromMap(Map<String, dynamic> map) {
    return DNDSchedule(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Schedule',
      enabled: map['enabled'] ?? true,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [1, 2, 3, 4, 5]),
      startTime: TimeOfDay(
        hour: map['startTimeHour'] ?? 22,
        minute: map['startTimeMinute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['endTimeHour'] ?? 7,
        minute: map['endTimeMinute'] ?? 0,
      ),
      mode: DNDMode.fromString(map['mode']),
      allowedContacts: List<String>.from(map['allowedContacts'] ?? []),
      allowRepeatCallers: map['allowRepeatCallers'] ?? true,
      repeatCallsThreshold: map['repeatCallsThreshold'] ?? 2,
      repeatCallsWindow: map['repeatCallsWindow'] ?? 3,
      autoReplyMessage: map['autoReplyMessage'],
    );
  }

  /// Create default "Night Mode" schedule
  factory DNDSchedule.nightMode() {
    return DNDSchedule(
      id: 'night_mode',
      name: 'Night Mode',
      daysOfWeek: [0, 1, 2, 3, 4, 5, 6], // Every day
      startTime: const TimeOfDay(hour: 22, minute: 0),
      endTime: const TimeOfDay(hour: 7, minute: 0),
    );
  }

  /// Create default "Work Hours" schedule
  factory DNDSchedule.workHours() {
    return DNDSchedule(
      id: 'work_hours',
      name: 'Work Hours',
      daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      mode: DNDMode.priorityOnly,
    );
  }
}

/// DND Settings container
class DNDSettings {
  final bool quickToggleEnabled;
  final DateTime? quickToggleUntil;
  final List<DNDSchedule> schedules;
  final List<String> globalAllowedContacts;
  final bool allowStarredContacts;

  const DNDSettings({
    this.quickToggleEnabled = false,
    this.quickToggleUntil,
    this.schedules = const [],
    this.globalAllowedContacts = const [],
    this.allowStarredContacts = true,
  });

  /// Check if DND is currently active
  bool get isActive {
    // Quick toggle takes priority
    if (quickToggleEnabled) {
      if (quickToggleUntil == null) return true;
      return DateTime.now().isBefore(quickToggleUntil!);
    }

    // Check schedules
    return schedules.any((s) => s.isActiveNow());
  }

  /// Get the current active schedule if any
  DNDSchedule? get activeSchedule {
    if (!isActive) return null;
    if (schedules.isEmpty) return null;

    // Find the first schedule that is currently active
    for (final schedule in schedules) {
      if (schedule.isActiveNow()) {
        return schedule;
      }
    }

    // If quick toggle is enabled but no schedule matches, return null
    // (quick toggle doesn't require a schedule)
    if (quickToggleEnabled) return null;

    return null;
  }

  DNDSettings copyWith({
    bool? quickToggleEnabled,
    DateTime? quickToggleUntil,
    List<DNDSchedule>? schedules,
    List<String>? globalAllowedContacts,
    bool? allowStarredContacts,
  }) {
    return DNDSettings(
      quickToggleEnabled: quickToggleEnabled ?? this.quickToggleEnabled,
      quickToggleUntil: quickToggleUntil ?? this.quickToggleUntil,
      schedules: schedules ?? this.schedules,
      globalAllowedContacts: globalAllowedContacts ?? this.globalAllowedContacts,
      allowStarredContacts: allowStarredContacts ?? this.allowStarredContacts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quickToggleEnabled': quickToggleEnabled,
      'quickToggleUntil': quickToggleUntil?.millisecondsSinceEpoch,
      'schedules': schedules.map((s) => s.toMap()).toList(),
      'globalAllowedContacts': globalAllowedContacts,
      'allowStarredContacts': allowStarredContacts,
    };
  }

  factory DNDSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DNDSettings();
    return DNDSettings(
      quickToggleEnabled: map['quickToggleEnabled'] ?? false,
      quickToggleUntil: map['quickToggleUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['quickToggleUntil'])
          : null,
      schedules: (map['schedules'] as List<dynamic>?)
              ?.map((s) => DNDSchedule.fromMap(s))
              .toList() ??
          [],
      globalAllowedContacts:
          List<String>.from(map['globalAllowedContacts'] ?? []),
      allowStarredContacts: map['allowStarredContacts'] ?? true,
    );
  }
}

// ============================================================================
// PER-CHAT OVERRIDE
// ============================================================================

/// Per-chat notification override
class ChatNotificationOverride {
  final String chatId;
  final bool? enabled; // null = use global settings
  final SoundConfig? sound;
  final VibrationPattern? vibration;
  final NotificationPriority? priority;
  final bool? showPreview;
  final DateTime? mutedUntil;
  final int? ledColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatNotificationOverride({
    required this.chatId,
    this.enabled,
    this.sound,
    this.vibration,
    this.priority,
    this.showPreview,
    this.mutedUntil,
    this.ledColor,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isMuted {
    if (mutedUntil == null) return enabled == false;
    return DateTime.now().isBefore(mutedUntil!);
  }

  /// Check if this override has any customizations
  bool get hasCustomizations {
    return enabled != null ||
        sound != null ||
        vibration != null ||
        priority != null ||
        showPreview != null ||
        mutedUntil != null ||
        ledColor != null;
  }

  /// Create a new override that uses global settings for all fields.
  /// This effectively "clears" all customizations.
  ChatNotificationOverride resetToGlobalSettings() {
    return ChatNotificationOverride(
      chatId: chatId,
      enabled: null,
      sound: null,
      vibration: null,
      priority: null,
      showPreview: null,
      mutedUntil: null,
      ledColor: null,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Clear the mute (set mutedUntil to null and enabled to null)
  ChatNotificationOverride clearMute() {
    return ChatNotificationOverride(
      chatId: chatId,
      enabled: null, // Reset to use global setting
      sound: sound,
      vibration: vibration,
      priority: priority,
      showPreview: showPreview,
      mutedUntil: null, // Clear mute
      ledColor: ledColor,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  ChatNotificationOverride copyWith({
    String? chatId,
    bool? enabled,
    SoundConfig? sound,
    VibrationPattern? vibration,
    NotificationPriority? priority,
    bool? showPreview,
    DateTime? mutedUntil,
    int? ledColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatNotificationOverride(
      chatId: chatId ?? this.chatId,
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      priority: priority ?? this.priority,
      showPreview: showPreview ?? this.showPreview,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      ledColor: ledColor ?? this.ledColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'enabled': enabled,
      'sound': sound?.toMap(),
      'vibration': vibration?.name,
      'priority': priority?.name,
      'showPreview': showPreview,
      'mutedUntil': mutedUntil?.millisecondsSinceEpoch,
      'ledColor': ledColor,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ChatNotificationOverride.fromMap(Map<String, dynamic> map) {
    return ChatNotificationOverride(
      chatId: map['chatId'] ?? '',
      enabled: map['enabled'],
      sound: map['sound'] != null ? SoundConfig.fromMap(map['sound']) : null,
      vibration: map['vibration'] != null
          ? VibrationPattern.fromString(map['vibration'])
          : null,
      priority: map['priority'] != null
          ? NotificationPriority.fromString(map['priority'])
          : null,
      showPreview: map['showPreview'],
      mutedUntil: map['mutedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['mutedUntil'])
          : null,
      ledColor: map['ledColor'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}

// ============================================================================
// MAIN MODEL
// ============================================================================

/// Enhanced Notification Settings Model
class EnhancedNotificationSettingsModel {
  final GlobalNotificationSettings global;
  final MessageNotificationSettings messages;
  final GroupNotificationSettings groups;
  final StatusNotificationSettings status;
  final CallNotificationSettings calls;
  final ReminderNotificationSettings reminders;
  final DigestNotificationSettings digest;
  final DNDSettings dnd;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  const EnhancedNotificationSettingsModel({
    this.global = const GlobalNotificationSettings(),
    this.messages = const MessageNotificationSettings(),
    this.groups = const GroupNotificationSettings(),
    this.status = const StatusNotificationSettings(),
    this.calls = const CallNotificationSettings(),
    this.reminders = const ReminderNotificationSettings(),
    this.digest = const DigestNotificationSettings(),
    this.dnd = const DNDSettings(),
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  factory EnhancedNotificationSettingsModel.defaultSettings() {
    final now = DateTime.now();
    return EnhancedNotificationSettingsModel(
      createdAt: now,
      updatedAt: now,
    );
  }

  EnhancedNotificationSettingsModel copyWith({
    GlobalNotificationSettings? global,
    MessageNotificationSettings? messages,
    GroupNotificationSettings? groups,
    StatusNotificationSettings? status,
    CallNotificationSettings? calls,
    ReminderNotificationSettings? reminders,
    DigestNotificationSettings? digest,
    DNDSettings? dnd,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? schemaVersion,
  }) {
    return EnhancedNotificationSettingsModel(
      global: global ?? this.global,
      messages: messages ?? this.messages,
      groups: groups ?? this.groups,
      status: status ?? this.status,
      calls: calls ?? this.calls,
      reminders: reminders ?? this.reminders,
      digest: digest ?? this.digest,
      dnd: dnd ?? this.dnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'global': global.toMap(),
      'messages': messages.toMap(),
      'groups': groups.toMap(),
      'status': status.toMap(),
      'calls': calls.toMap(),
      'reminders': reminders.toMap(),
      'digest': digest.toMap(),
      'dnd': dnd.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'schemaVersion': schemaVersion,
    };
  }

  factory EnhancedNotificationSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return EnhancedNotificationSettingsModel.defaultSettings();
    return EnhancedNotificationSettingsModel(
      global: GlobalNotificationSettings.fromMap(map['global']),
      messages: MessageNotificationSettings.fromMap(map['messages']),
      groups: GroupNotificationSettings.fromMap(map['groups']),
      status: StatusNotificationSettings.fromMap(map['status']),
      calls: CallNotificationSettings.fromMap(map['calls']),
      reminders: ReminderNotificationSettings.fromMap(map['reminders']),
      digest: DigestNotificationSettings.fromMap(map['digest']),
      dnd: DNDSettings.fromMap(map['dnd']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }

  /// Check if notifications are effectively enabled for a category
  bool isEffectivelyEnabled(NotificationCategory category) {
    if (!global.masterSwitch) return false;
    if (dnd.isActive) return false;

    switch (category) {
      case NotificationCategory.message:
        return messages.enabled;
      case NotificationCategory.group:
        return groups.enabled;
      case NotificationCategory.status:
        return status.enabled;
      case NotificationCategory.call:
        return true; // Calls always enabled if master switch is on
      case NotificationCategory.reminder:
        return reminders.enabled;
    }
  }
}

/// Notification category enum
enum NotificationCategory {
  message,
  group,
  status,
  call,
  reminder,
}

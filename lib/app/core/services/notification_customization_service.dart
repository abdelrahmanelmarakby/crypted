import 'dart:convert';
import 'dart:developer' as dev;
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:flutter/foundation.dart';

/// Service for customizing notifications per chat
class NotificationCustomizationService {
  static final NotificationCustomizationService instance =
      NotificationCustomizationService._();
  NotificationCustomizationService._();

  static const String _settingsPrefix = 'notif_settings_';

  /// Get notification settings for a chat room
  Future<NotificationSettings> getSettings(String roomId) async {
    try {
      final key = _getSettingsKey(roomId);
      final stored = await CacheHelper.get(key: key);

      if (stored != null && stored is String) {
        final Map<String, dynamic> json = jsonDecode(stored);
        return NotificationSettings.fromMap(json);
      }

      return NotificationSettings.defaultSettings();
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error loading notification settings: $e');
      }
      return NotificationSettings.defaultSettings();
    }
  }

  /// Save notification settings for a chat room
  Future<void> saveSettings(
    String roomId,
    NotificationSettings settings,
  ) async {
    try {
      final key = _getSettingsKey(roomId);
      await CacheHelper.put(
        key: key,
        value: jsonEncode(settings.toMap()),
      );

      if (kDebugMode) {
        dev.log('💾 Saved notification settings for room: $roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error saving notification settings: $e');
      }
    }
  }

  /// Mute chat for a specific duration
  Future<void> muteChat(String roomId, Duration duration) async {
    final settings = await getSettings(roomId);
    final mutedUntil = DateTime.now().add(duration);

    final updatedSettings = settings.copyWith(
      isMuted: true,
      mutedUntil: mutedUntil,
    );

    await saveSettings(roomId, updatedSettings);

    if (kDebugMode) {
      dev.log('🔕 Muted chat $roomId until $mutedUntil');
    }
  }

  /// Unmute chat
  Future<void> unmuteChat(String roomId) async {
    final settings = await getSettings(roomId);
    final updatedSettings = settings.copyWith(
      isMuted: false,
      mutedUntil: null,
    );

    await saveSettings(roomId, updatedSettings);

    if (kDebugMode) {
      dev.log('🔔 Unmuted chat $roomId');
    }
  }

  /// Check if chat is currently muted
  Future<bool> isChatMuted(String roomId) async {
    final settings = await getSettings(roomId);

    if (!settings.isMuted) return false;

    // Check if mute has expired
    if (settings.mutedUntil != null &&
        DateTime.now().isAfter(settings.mutedUntil!)) {
      await unmuteChat(roomId);
      return false;
    }

    return true;
  }

  /// Set custom notification sound
  Future<void> setCustomSound(String roomId, String soundPath) async {
    final settings = await getSettings(roomId);
    final updatedSettings = settings.copyWith(customSound: soundPath);
    await saveSettings(roomId, updatedSettings);
  }

  /// Set custom vibration pattern
  Future<void> setVibrationPattern(
    String roomId,
    List<int> pattern,
  ) async {
    final settings = await getSettings(roomId);
    final updatedSettings = settings.copyWith(vibrationPattern: pattern);
    await saveSettings(roomId, updatedSettings);
  }

  String _getSettingsKey(String roomId) => '$_settingsPrefix$roomId';
}

/// Model for notification settings per chat
class NotificationSettings {
  final bool isMuted;
  final DateTime? mutedUntil;
  final String? customSound;
  final List<int>? vibrationPattern;
  final bool showPreviews;
  final bool notifyMentionsOnly;
  final bool highPriority;

  NotificationSettings({
    this.isMuted = false,
    this.mutedUntil,
    this.customSound,
    this.vibrationPattern,
    this.showPreviews = true,
    this.notifyMentionsOnly = false,
    this.highPriority = false,
  });

  factory NotificationSettings.defaultSettings() => NotificationSettings();

  Map<String, dynamic> toMap() => {
        'isMuted': isMuted,
        'mutedUntil': mutedUntil?.toIso8601String(),
        'customSound': customSound,
        'vibrationPattern': vibrationPattern,
        'showPreviews': showPreviews,
        'notifyMentionsOnly': notifyMentionsOnly,
        'highPriority': highPriority,
      };

  factory NotificationSettings.fromMap(Map<String, dynamic> map) =>
      NotificationSettings(
        isMuted: map['isMuted'] ?? false,
        mutedUntil: map['mutedUntil'] != null
            ? DateTime.parse(map['mutedUntil'])
            : null,
        customSound: map['customSound'],
        vibrationPattern: map['vibrationPattern'] != null
            ? List<int>.from(map['vibrationPattern'])
            : null,
        showPreviews: map['showPreviews'] ?? true,
        notifyMentionsOnly: map['notifyMentionsOnly'] ?? false,
        highPriority: map['highPriority'] ?? false,
      );

  NotificationSettings copyWith({
    bool? isMuted,
    DateTime? mutedUntil,
    String? customSound,
    List<int>? vibrationPattern,
    bool? showPreviews,
    bool? notifyMentionsOnly,
    bool? highPriority,
  }) {
    return NotificationSettings(
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      customSound: customSound ?? this.customSound,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      showPreviews: showPreviews ?? this.showPreviews,
      notifyMentionsOnly: notifyMentionsOnly ?? this.notifyMentionsOnly,
      highPriority: highPriority ?? this.highPriority,
    );
  }

  bool get isTemporarilyMuted {
    if (!isMuted) return false;
    if (mutedUntil == null) return true; // Permanently muted
    return DateTime.now().isBefore(mutedUntil!);
  }
}

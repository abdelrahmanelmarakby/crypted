import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/debouncer.dart';

/// Enhanced Notification Settings Service
/// Provides comprehensive notification settings management with:
/// - Real-time sync across devices
/// - Backend enforcement
/// - Per-chat overrides
/// - DND scheduling
/// - Caching and offline support
/// - Debounced saves to prevent race conditions

class NotificationSettingsService extends GetxService {
  static NotificationSettingsService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debouncer for save operations to prevent race conditions
  final Debouncer _saveDebouncer = Debouncer(milliseconds: 500);

  // Reactive settings
  final Rx<EnhancedNotificationSettingsModel> settings =
      EnhancedNotificationSettingsModel.defaultSettings().obs;

  // Per-chat overrides cache
  final RxMap<String, ChatNotificationOverride> _chatOverrides =
      <String, ChatNotificationOverride>{}.obs;

  // Stream subscriptions
  StreamSubscription? _settingsSubscription;
  StreamSubscription? _overridesSubscription;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  @override
  void onClose() {
    _settingsSubscription?.cancel();
    _overridesSubscription?.cancel();
    _saveDebouncer.dispose();
    super.onClose();
  }

  Future<void> _initializeSettings() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final userId = UserService.currentUserValue?.uid;
      if (userId == null) {
        developer.log('No user logged in', name: 'NotificationSettingsService');
        return;
      }

      // Load initial settings
      await _loadSettings(userId);

      // Set up real-time listener
      _setupSettingsListener(userId);

      // Load per-chat overrides
      await _loadChatOverrides(userId);
      _setupOverridesListener(userId);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize notification settings',
        name: 'NotificationSettingsService',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load notification settings';
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================================
  // LOADING
  // ============================================================================

  Future<void> _loadSettings(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .get();

    if (doc.exists) {
      settings.value = EnhancedNotificationSettingsModel.fromMap(doc.data());
    } else {
      // Create default settings - use immediate save for initial setup
      settings.value = EnhancedNotificationSettingsModel.defaultSettings();
      await _saveSettings();
    }
  }

  void _setupSettingsListener(String userId) {
    _settingsSubscription?.cancel();
    _settingsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          settings.value = EnhancedNotificationSettingsModel.fromMap(snapshot.data());
        }
      },
      onError: (error) {
        developer.log(
          'Settings listener error',
          name: 'NotificationSettingsService',
          error: error,
        );
      },
    );
  }

  Future<void> _loadChatOverrides(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chatNotificationOverrides')
        .get();

    _chatOverrides.clear();
    for (final doc in snapshot.docs) {
      final override = ChatNotificationOverride.fromMap(doc.data());
      _chatOverrides[override.chatId] = override;
    }
  }

  void _setupOverridesListener(String userId) {
    _overridesSubscription?.cancel();
    _overridesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('chatNotificationOverrides')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.removed) {
            _chatOverrides.remove(change.doc.id);
          } else {
            final override = ChatNotificationOverride.fromMap(change.doc.data()!);
            _chatOverrides[override.chatId] = override;
          }
        }
      },
      onError: (error) {
        developer.log(
          'Overrides listener error',
          name: 'NotificationSettingsService',
          error: error,
        );
      },
    );
  }

  // ============================================================================
  // SAVING
  // ============================================================================

  /// Debounced save to prevent race conditions from rapid setting changes.
  /// Multiple calls within 500ms will be coalesced into a single save.
  Future<void> _debouncedSave() {
    return _saveDebouncer.run(() => _saveSettingsInternal());
  }

  /// Immediate save without debouncing (used for initial setup).
  Future<bool> _saveSettings() async {
    _saveDebouncer.cancel(); // Cancel any pending debounced save
    return _saveSettingsInternal();
  }

  Future<bool> _saveSettingsInternal() async {
    try {
      isSaving.value = true;
      errorMessage.value = null;

      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(settings.value.toMap());

      developer.log(
        'Notification settings saved',
        name: 'NotificationSettingsService',
      );
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save notification settings',
        name: 'NotificationSettingsService',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to save settings';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================================
  // GLOBAL SETTINGS
  // ============================================================================

  /// Toggle master notification switch
  Future<void> toggleMasterSwitch(bool enabled) async {
    settings.value = settings.value.copyWith(
      global: settings.value.global.copyWith(masterSwitch: enabled),
    );
    await _debouncedSave();
  }

  /// Update preview level
  Future<void> updatePreviewLevel(PreviewLevel level) async {
    settings.value = settings.value.copyWith(
      global: settings.value.global.copyWith(showPreviews: level),
    );
    await _debouncedSave();
  }

  /// Update notification grouping
  Future<void> updateGrouping(NotificationGrouping grouping) async {
    settings.value = settings.value.copyWith(
      global: settings.value.global.copyWith(grouping: grouping),
    );
    await _debouncedSave();
  }

  /// Toggle in-app sounds
  Future<void> toggleInAppSounds(bool enabled) async {
    settings.value = settings.value.copyWith(
      global: settings.value.global.copyWith(inAppSounds: enabled),
    );
    await _debouncedSave();
  }

  /// Toggle in-app vibration
  Future<void> toggleInAppVibration(bool enabled) async {
    settings.value = settings.value.copyWith(
      global: settings.value.global.copyWith(inAppVibration: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // MESSAGE NOTIFICATIONS
  // ============================================================================

  /// Toggle message notifications
  Future<void> toggleMessageNotifications(bool enabled) async {
    settings.value = settings.value.copyWith(
      messages: settings.value.messages.copyWith(enabled: enabled),
    );
    await _debouncedSave();
  }

  /// Update message notification sound
  Future<void> updateMessageSound(SoundConfig sound) async {
    settings.value = settings.value.copyWith(
      messages: settings.value.messages.copyWith(sound: sound),
    );
    await _debouncedSave();
  }

  /// Update message notification vibration
  Future<void> updateMessageVibration(VibrationPattern pattern) async {
    settings.value = settings.value.copyWith(
      messages: settings.value.messages.copyWith(vibration: pattern),
    );
    await _debouncedSave();
  }

  /// Toggle message reaction notifications
  Future<void> toggleMessageReactions(bool enabled) async {
    settings.value = settings.value.copyWith(
      messages: settings.value.messages.copyWith(reactions: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // GROUP NOTIFICATIONS
  // ============================================================================

  /// Toggle group notifications
  Future<void> toggleGroupNotifications(bool enabled) async {
    settings.value = settings.value.copyWith(
      groups: settings.value.groups.copyWith(enabled: enabled),
    );
    await _debouncedSave();
  }

  /// Update group notification sound
  Future<void> updateGroupSound(SoundConfig sound) async {
    settings.value = settings.value.copyWith(
      groups: settings.value.groups.copyWith(sound: sound),
    );
    await _debouncedSave();
  }

  /// Update group notification vibration
  Future<void> updateGroupVibration(VibrationPattern pattern) async {
    settings.value = settings.value.copyWith(
      groups: settings.value.groups.copyWith(vibration: pattern),
    );
    await _debouncedSave();
  }

  /// Toggle mentions only for groups
  Future<void> toggleMentionsOnly(bool enabled) async {
    settings.value = settings.value.copyWith(
      groups: settings.value.groups.copyWith(mentionsOnly: enabled),
    );
    await _debouncedSave();
  }

  /// Toggle group reaction notifications
  Future<void> toggleGroupReactions(bool enabled) async {
    settings.value = settings.value.copyWith(
      groups: settings.value.groups.copyWith(reactions: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // STATUS NOTIFICATIONS
  // ============================================================================

  /// Toggle status notifications
  Future<void> toggleStatusNotifications(bool enabled) async {
    settings.value = settings.value.copyWith(
      status: settings.value.status.copyWith(enabled: enabled),
    );
    await _debouncedSave();
  }

  /// Update status notification sound
  Future<void> updateStatusSound(SoundConfig sound) async {
    settings.value = settings.value.copyWith(
      status: settings.value.status.copyWith(sound: sound),
    );
    await _debouncedSave();
  }

  /// Toggle status reaction notifications
  Future<void> toggleStatusReactions(bool enabled) async {
    settings.value = settings.value.copyWith(
      status: settings.value.status.copyWith(reactions: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // CALL NOTIFICATIONS
  // ============================================================================

  /// Update call ringtone
  Future<void> updateCallRingtone(SoundConfig sound) async {
    settings.value = settings.value.copyWith(
      calls: settings.value.calls.copyWith(ringtone: sound),
    );
    await _debouncedSave();
  }

  /// Update call vibration
  Future<void> updateCallVibration(VibrationPattern pattern) async {
    settings.value = settings.value.copyWith(
      calls: settings.value.calls.copyWith(vibration: pattern),
    );
    await _debouncedSave();
  }

  /// Toggle silent calls during DND
  Future<void> toggleSilentCallsDuringDND(bool enabled) async {
    settings.value = settings.value.copyWith(
      calls: settings.value.calls.copyWith(silentWhenDND: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // REMINDER NOTIFICATIONS
  // ============================================================================

  /// Toggle reminder notifications
  Future<void> toggleReminderNotifications(bool enabled) async {
    settings.value = settings.value.copyWith(
      reminders: settings.value.reminders.copyWith(enabled: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // DND SETTINGS
  // ============================================================================

  /// Toggle quick DND
  Future<void> toggleQuickDND(bool enabled, {DateTime? until}) async {
    settings.value = settings.value.copyWith(
      dnd: settings.value.dnd.copyWith(
        quickToggleEnabled: enabled,
        quickToggleUntil: until,
      ),
    );
    await _debouncedSave();
  }

  /// Add DND schedule
  Future<void> addDNDSchedule(DNDSchedule schedule) async {
    final schedules = [...settings.value.dnd.schedules, schedule];
    settings.value = settings.value.copyWith(
      dnd: settings.value.dnd.copyWith(schedules: schedules),
    );
    await _debouncedSave();
  }

  /// Update DND schedule
  Future<void> updateDNDSchedule(DNDSchedule schedule) async {
    final schedules = settings.value.dnd.schedules
        .map((s) => s.id == schedule.id ? schedule : s)
        .toList();
    settings.value = settings.value.copyWith(
      dnd: settings.value.dnd.copyWith(schedules: schedules),
    );
    await _debouncedSave();
  }

  /// Delete DND schedule
  Future<void> deleteDNDSchedule(String scheduleId) async {
    final schedules = settings.value.dnd.schedules
        .where((s) => s.id != scheduleId)
        .toList();
    settings.value = settings.value.copyWith(
      dnd: settings.value.dnd.copyWith(schedules: schedules),
    );
    await _debouncedSave();
  }

  /// Check if DND is currently active
  bool get isDNDActive => settings.value.dnd.isActive;

  /// Get current active DND schedule
  DNDSchedule? get activeDNDSchedule => settings.value.dnd.activeSchedule;

  // ============================================================================
  // PER-CHAT OVERRIDES
  // ============================================================================

  /// Get chat notification override
  ChatNotificationOverride? getChatOverride(String chatId) {
    return _chatOverrides[chatId];
  }

  /// Set chat notification override
  Future<void> setChatOverride(ChatNotificationOverride override) async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationOverrides')
          .doc(override.chatId)
          .set(override.toMap());

      _chatOverrides[override.chatId] = override;
    } catch (e) {
      developer.log(
        'Failed to set chat override',
        name: 'NotificationSettingsService',
        error: e,
      );
    }
  }

  /// Mute chat for duration
  Future<void> muteChat(String chatId, MuteDuration duration) async {
    final now = DateTime.now();
    final override = ChatNotificationOverride(
      chatId: chatId,
      enabled: false,
      mutedUntil: duration.getUnmuteTime(),
      createdAt: now,
      updatedAt: now,
    );
    await setChatOverride(override);
  }

  /// Unmute chat
  Future<void> unmuteChat(String chatId) async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chatNotificationOverrides')
          .doc(chatId)
          .delete();

      _chatOverrides.remove(chatId);
    } catch (e) {
      developer.log(
        'Failed to unmute chat',
        name: 'NotificationSettingsService',
        error: e,
      );
    }
  }

  /// Check if chat is muted
  bool isChatMuted(String chatId) {
    final override = _chatOverrides[chatId];
    return override?.isMuted ?? false;
  }

  /// Get all muted chats
  List<ChatNotificationOverride> get mutedChats {
    return _chatOverrides.values.where((o) => o.isMuted).toList();
  }

  // ============================================================================
  // BACKEND ENFORCEMENT
  // ============================================================================

  /// Check if notification should be delivered
  /// This is called by the backend/notification service before sending
  NotificationDecision shouldDeliverNotification({
    required String senderId,
    required String chatId,
    required NotificationCategory category,
    required bool isContact,
    required bool isStarred,
    required bool isReaction,
    required bool isMention,
  }) {
    // Check master switch
    if (!settings.value.global.masterSwitch) {
      return NotificationDecision.blocked(BlockReason.masterSwitchOff);
    }

    // Check DND
    if (settings.value.dnd.isActive) {
      final schedule = settings.value.dnd.activeSchedule;

      // Check if sender is in allowed contacts
      final isAllowed = settings.value.dnd.globalAllowedContacts.contains(senderId) ||
          (settings.value.dnd.allowStarredContacts && isStarred) ||
          (schedule?.allowedContacts.contains(senderId) ?? false);

      if (!isAllowed) {
        return NotificationDecision.blocked(BlockReason.dndActive);
      }
    }

    // Check per-chat override
    final chatOverride = _chatOverrides[chatId];
    if (chatOverride != null && chatOverride.isMuted) {
      return NotificationDecision.blocked(BlockReason.chatMuted);
    }

    // Check category settings
    switch (category) {
      case NotificationCategory.message:
        if (!settings.value.messages.enabled) {
          return NotificationDecision.blocked(BlockReason.categoryDisabled);
        }
        if (isReaction && !settings.value.messages.reactions) {
          return NotificationDecision.blocked(BlockReason.reactionsDisabled);
        }
        return NotificationDecision.allowed(
          settings.value.messages.sound,
          settings.value.messages.vibration,
          settings.value.messages.priority,
        );

      case NotificationCategory.group:
        if (!settings.value.groups.enabled) {
          return NotificationDecision.blocked(BlockReason.categoryDisabled);
        }
        if (settings.value.groups.mentionsOnly && !isMention) {
          return NotificationDecision.blocked(BlockReason.mentionsOnly);
        }
        if (isReaction && !settings.value.groups.reactions) {
          return NotificationDecision.blocked(BlockReason.reactionsDisabled);
        }
        return NotificationDecision.allowed(
          settings.value.groups.sound,
          settings.value.groups.vibration,
          settings.value.groups.priority,
        );

      case NotificationCategory.status:
        if (!settings.value.status.enabled) {
          return NotificationDecision.blocked(BlockReason.categoryDisabled);
        }
        if (settings.value.status.contactsOnly && !isContact) {
          return NotificationDecision.blocked(BlockReason.contactsOnly);
        }
        if (isReaction && !settings.value.status.reactions) {
          return NotificationDecision.blocked(BlockReason.reactionsDisabled);
        }
        return NotificationDecision.allowed(
          settings.value.status.sound,
          VibrationPattern.short,
          NotificationPriority.normal,
        );

      case NotificationCategory.call:
        if (settings.value.calls.silentWhenDND && settings.value.dnd.isActive) {
          return NotificationDecision.blocked(BlockReason.dndActive);
        }
        return NotificationDecision.allowed(
          settings.value.calls.ringtone,
          settings.value.calls.vibration,
          NotificationPriority.urgent,
        );

      case NotificationCategory.reminder:
        if (!settings.value.reminders.enabled) {
          return NotificationDecision.blocked(BlockReason.categoryDisabled);
        }
        return NotificationDecision.allowed(
          const SoundConfig(),
          VibrationPattern.short,
          NotificationPriority.normal,
        );
    }
  }

  // ============================================================================
  // RESET
  // ============================================================================

  /// Reset all notification settings to defaults
  Future<void> resetToDefaults() async {
    settings.value = EnhancedNotificationSettingsModel.defaultSettings();
    await _saveSettings(); // Use immediate save for reset operation

    // Clear all chat overrides
    final userId = UserService.currentUserValue?.uid;
    if (userId != null) {
      final batch = _firestore.batch();
      for (final chatId in _chatOverrides.keys) {
        batch.delete(_firestore
            .collection('users')
            .doc(userId)
            .collection('chatNotificationOverrides')
            .doc(chatId));
      }
      await batch.commit();
      _chatOverrides.clear();
    }
  }

  /// Refresh settings from server
  Future<void> refresh() async {
    await _initializeSettings();
  }
}

// ============================================================================
// NOTIFICATION DECISION
// ============================================================================

/// Result of notification decision check
class NotificationDecision {
  final bool shouldDeliver;
  final BlockReason? blockReason;
  final SoundConfig? sound;
  final VibrationPattern? vibration;
  final NotificationPriority? priority;

  const NotificationDecision._({
    required this.shouldDeliver,
    this.blockReason,
    this.sound,
    this.vibration,
    this.priority,
  });

  factory NotificationDecision.allowed(
    SoundConfig sound,
    VibrationPattern vibration,
    NotificationPriority priority,
  ) {
    return NotificationDecision._(
      shouldDeliver: true,
      sound: sound,
      vibration: vibration,
      priority: priority,
    );
  }

  factory NotificationDecision.blocked(BlockReason reason) {
    return NotificationDecision._(
      shouldDeliver: false,
      blockReason: reason,
    );
  }
}

/// Reason for blocking notification
enum BlockReason {
  masterSwitchOff,
  dndActive,
  chatMuted,
  categoryDisabled,
  reactionsDisabled,
  mentionsOnly,
  contactsOnly,
}

/// Extension for BlockReason display
extension BlockReasonExtension on BlockReason {
  String get displayMessage {
    switch (this) {
      case BlockReason.masterSwitchOff:
        return 'Notifications are turned off';
      case BlockReason.dndActive:
        return 'Do Not Disturb is active';
      case BlockReason.chatMuted:
        return 'This chat is muted';
      case BlockReason.categoryDisabled:
        return 'This notification type is disabled';
      case BlockReason.reactionsDisabled:
        return 'Reaction notifications are disabled';
      case BlockReason.mentionsOnly:
        return 'Only showing @mentions';
      case BlockReason.contactsOnly:
        return 'Only showing notifications from contacts';
    }
  }
}

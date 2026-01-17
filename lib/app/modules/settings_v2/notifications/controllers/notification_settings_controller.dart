import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/notification_settings_service.dart';

/// Enhanced Notification Settings Controller
/// Manages notification settings UI state and interactions

class NotificationSettingsController extends GetxController {
  late final NotificationSettingsService _service;

  // Audio player for sound preview
  AudioPlayer? _audioPlayer;

  // Computed getters for reactive UI
  EnhancedNotificationSettingsModel get settings => _service.settings.value;

  // Loading states
  bool get isLoading => _service.isLoading.value;
  bool get isSaving => _service.isSaving.value;
  String? get errorMessage => _service.errorMessage.value;

  // DND state
  bool get isDNDActive => _service.isDNDActive;
  DNDSchedule? get activeDNDSchedule => _service.activeDNDSchedule;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<NotificationSettingsService>();
    _audioPlayer = AudioPlayer();
  }

  @override
  void onClose() {
    _audioPlayer?.dispose();
    super.onClose();
  }

  // ============================================================================
  // GLOBAL SETTINGS
  // ============================================================================

  Future<void> toggleMasterSwitch(bool enabled) async {
    await _service.toggleMasterSwitch(enabled);
  }

  Future<void> updatePreviewLevel(PreviewLevel level) async {
    await _service.updatePreviewLevel(level);
  }

  Future<void> updateGrouping(NotificationGrouping grouping) async {
    await _service.updateGrouping(grouping);
  }

  Future<void> toggleInAppSounds(bool enabled) async {
    await _service.toggleInAppSounds(enabled);
  }

  Future<void> toggleInAppVibration(bool enabled) async {
    await _service.toggleInAppVibration(enabled);
  }

  // ============================================================================
  // MESSAGE NOTIFICATIONS
  // ============================================================================

  Future<void> toggleMessageNotifications(bool enabled) async {
    await _service.toggleMessageNotifications(enabled);
  }

  Future<void> updateMessageSound(NotificationSound sound) async {
    await _service.updateMessageSound(SoundConfig(sound: sound));
  }

  Future<void> updateMessageVibration(VibrationPattern pattern) async {
    await _service.updateMessageVibration(pattern);
  }

  Future<void> toggleMessageReactions(bool enabled) async {
    await _service.toggleMessageReactions(enabled);
  }

  // ============================================================================
  // GROUP NOTIFICATIONS
  // ============================================================================

  Future<void> toggleGroupNotifications(bool enabled) async {
    await _service.toggleGroupNotifications(enabled);
  }

  Future<void> updateGroupSound(NotificationSound sound) async {
    await _service.updateGroupSound(SoundConfig(sound: sound));
  }

  Future<void> updateGroupVibration(VibrationPattern pattern) async {
    await _service.updateGroupVibration(pattern);
  }

  Future<void> toggleMentionsOnly(bool enabled) async {
    await _service.toggleMentionsOnly(enabled);
  }

  Future<void> toggleGroupReactions(bool enabled) async {
    await _service.toggleGroupReactions(enabled);
  }

  // ============================================================================
  // STATUS NOTIFICATIONS
  // ============================================================================

  Future<void> toggleStatusNotifications(bool enabled) async {
    await _service.toggleStatusNotifications(enabled);
  }

  Future<void> updateStatusSound(NotificationSound sound) async {
    await _service.updateStatusSound(SoundConfig(sound: sound));
  }

  Future<void> toggleStatusReactions(bool enabled) async {
    await _service.toggleStatusReactions(enabled);
  }

  // ============================================================================
  // CALL NOTIFICATIONS
  // ============================================================================

  Future<void> updateCallRingtone(NotificationSound sound) async {
    await _service.updateCallRingtone(SoundConfig(sound: sound));
  }

  Future<void> updateCallVibration(VibrationPattern pattern) async {
    await _service.updateCallVibration(pattern);
  }

  Future<void> toggleSilentCallsDuringDND(bool enabled) async {
    await _service.toggleSilentCallsDuringDND(enabled);
  }

  // ============================================================================
  // REMINDER NOTIFICATIONS
  // ============================================================================

  Future<void> toggleReminderNotifications(bool enabled) async {
    await _service.toggleReminderNotifications(enabled);
  }

  // ============================================================================
  // DND SETTINGS
  // ============================================================================

  Future<void> toggleQuickDND(bool enabled, {Duration? duration}) async {
    DateTime? until;
    if (duration != null && enabled) {
      until = DateTime.now().add(duration);
    }
    await _service.toggleQuickDND(enabled, until: until);
  }

  Future<void> addDNDSchedule(DNDSchedule schedule) async {
    await _service.addDNDSchedule(schedule);
  }

  Future<void> updateDNDSchedule(DNDSchedule schedule) async {
    await _service.updateDNDSchedule(schedule);
  }

  Future<void> deleteDNDSchedule(String scheduleId) async {
    await _service.deleteDNDSchedule(scheduleId);
  }

  /// Update allowed contacts during DND
  Future<void> updateAllowedContacts(List<String> contactIds) async {
    final currentDnd = _service.settings.value.dnd;
    final newDnd = currentDnd.copyWith(allowedContacts: contactIds);
    await _service.updateDNDSettings(newDnd);
  }

  /// Get current allowed contacts
  List<String> get allowedContacts => _service.settings.value.dnd.allowedContacts;

  // ============================================================================
  // PER-CHAT SETTINGS
  // ============================================================================

  Future<void> muteChat(String chatId, MuteDuration duration) async {
    await _service.muteChat(chatId, duration);
  }

  Future<void> unmuteChat(String chatId) async {
    await _service.unmuteChat(chatId);
  }

  bool isChatMuted(String chatId) {
    return _service.isChatMuted(chatId);
  }

  List<ChatNotificationOverride> get mutedChats => _service.mutedChats;

  /// Get notification override for a specific chat
  ChatNotificationOverride? getChatOverride(String chatId) {
    return _service.getChatOverride(chatId);
  }

  /// Set custom notification override for a chat
  Future<void> setChatOverride(ChatNotificationOverride override) async {
    await _service.setChatOverride(override);
  }

  /// Remove custom notification override for a chat
  Future<void> removeChatOverride(String chatId) async {
    await _service.unmuteChat(chatId);
  }

  // ============================================================================
  // SOUND PREVIEW
  // ============================================================================

  /// Preview notification sound
  Future<void> previewSound(NotificationSound sound) async {
    try {
      // Stop any currently playing preview
      await _audioPlayer?.stop();

      // Map sound to asset path
      final assetPath = _getSoundAssetPath(sound);
      if (assetPath == null) {
        // If no asset, just show a message
        Get.snackbar(
          'Sound',
          sound.displayName,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
        return;
      }

      // Play the sound
      await _audioPlayer?.setAsset(assetPath);
      await _audioPlayer?.play();
    } catch (e) {
      // Fallback to snackbar if audio fails
      Get.snackbar(
        'Sound Preview',
        'Playing: ${sound.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// Get asset path for notification sound
  String? _getSoundAssetPath(NotificationSound sound) {
    switch (sound) {
      case NotificationSound.default_:
        return 'assets/sounds/notification.mp3';
      case NotificationSound.ping:
        return 'assets/sounds/ping.mp3';
      case NotificationSound.chime:
        return 'assets/sounds/chime.mp3';
      case NotificationSound.bell:
        return 'assets/sounds/bell.mp3';
      case NotificationSound.whistle:
        return 'assets/sounds/whistle.mp3';
      case NotificationSound.gentle:
        return 'assets/sounds/gentle.mp3';
      case NotificationSound.electronic:
        return 'assets/sounds/electronic.mp3';
      case NotificationSound.classic:
        return 'assets/sounds/classic.mp3';
      case NotificationSound.none:
        return null;
    }
  }

  /// Preview vibration pattern
  void previewVibration(VibrationPattern pattern) {
    switch (pattern) {
      case VibrationPattern.none:
        // No vibration
        break;
      case VibrationPattern.short:
        HapticFeedback.lightImpact();
        break;
      case VibrationPattern.medium:
        HapticFeedback.mediumImpact();
        break;
      case VibrationPattern.long_:
        HapticFeedback.heavyImpact();
        break;
      case VibrationPattern.double_:
        // Double vibration: two light impacts
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.lightImpact();
        });
        break;
      case VibrationPattern.triple:
        // Triple vibration: three light impacts
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(milliseconds: 150), () {
            HapticFeedback.lightImpact();
          });
        });
        break;
      case VibrationPattern.custom:
        // Custom pattern - use medium impact as demo
        HapticFeedback.mediumImpact();
        break;
    }
  }

  // ============================================================================
  // RESET
  // ============================================================================

  Future<void> resetToDefaults() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset Notifications'),
        content: const Text(
          'This will reset all notification settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.resetToDefaults();
      Get.snackbar(
        'Success',
        'Notification settings have been reset',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> refresh() async {
    await _service.refresh();
  }
}

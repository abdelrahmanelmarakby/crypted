import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/notification_settings_service.dart';

/// Enhanced Notification Settings Controller
/// Manages notification settings UI state and interactions

class NotificationSettingsController extends GetxController {
  late final NotificationSettingsService _service;

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

  // ============================================================================
  // SOUND PREVIEW
  // ============================================================================

  void previewSound(NotificationSound sound) {
    // TODO: Implement sound preview using audio player
    // This would play a short preview of the selected sound
    Get.snackbar(
      'Sound Preview',
      'Playing: ${sound.displayName}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void previewVibration(VibrationPattern pattern) {
    // TODO: Implement vibration preview using HapticFeedback
    // This would trigger the vibration pattern
    Get.snackbar(
      'Vibration Preview',
      'Pattern: ${pattern.displayName}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// Enhanced Privacy Settings Controller
/// Manages privacy settings UI state and interactions

class PrivacySettingsController extends GetxController {
  late final PrivacySettingsService _service;

  // Computed getters for reactive UI
  EnhancedPrivacySettingsModel get settings => _service.settings.value;
  int get privacyScore => _service.privacyScore.value;
  List<ActiveSession> get activeSessions => _service.activeSessions;
  List<SecurityLogEntry> get securityLog => _service.securityLog;

  // Loading states
  bool get isLoading => _service.isLoading.value;
  bool get isSaving => _service.isSaving.value;
  String? get errorMessage => _service.errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<PrivacySettingsService>();
  }

  // ============================================================================
  // PROFILE VISIBILITY
  // ============================================================================

  Future<void> updateLastSeenVisibility(VisibilityLevel level) async {
    await _service.updateLastSeenVisibility(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateProfilePhotoVisibility(VisibilityLevel level) async {
    await _service.updateProfilePhotoVisibility(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateAboutVisibility(VisibilityLevel level) async {
    await _service.updateAboutVisibility(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateOnlineStatusVisibility(VisibilityLevel level) async {
    await _service.updateOnlineStatusVisibility(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateStatusVisibility(VisibilityLevel level) async {
    await _service.updateStatusVisibility(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  // ============================================================================
  // COMMUNICATION
  // ============================================================================

  Future<void> updateWhoCanMessage(VisibilityLevel level) async {
    await _service.updateWhoCanMessage(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateWhoCanCall(VisibilityLevel level) async {
    await _service.updateWhoCanCall(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> updateWhoCanAddToGroups(VisibilityLevel level) async {
    await _service.updateWhoCanAddToGroups(
      VisibilitySettingWithExceptions(level: level),
    );
  }

  Future<void> toggleTypingIndicator(bool enabled) async {
    await _service.toggleTypingIndicator(enabled);
  }

  Future<void> toggleReadReceipts(bool enabled) async {
    await _service.toggleReadReceipts(enabled);
  }

  // ============================================================================
  // CONTENT PROTECTION
  // ============================================================================

  Future<void> toggleScreenshots(bool allowed) async {
    await _service.toggleScreenshots(allowed);
  }

  Future<void> toggleForwarding(bool allowed) async {
    await _service.toggleForwarding(allowed);
  }

  Future<void> updateDefaultDisappearingDuration(DisappearingDuration duration) async {
    await _service.updateDefaultDisappearingDuration(duration);
  }

  Future<void> toggleHideMediaInGallery(bool hide) async {
    await _service.toggleHideMediaInGallery(hide);
  }

  // ============================================================================
  // SECURITY
  // ============================================================================

  Future<void> toggleTwoStepVerification(bool enabled) async {
    await _service.toggleTwoStepVerification(enabled);
  }

  Future<void> toggleAppLock(bool enabled) async {
    await _service.toggleAppLock(enabled);
  }

  Future<void> updateAppLockTimeout(AppLockTimeout timeout) async {
    await _service.updateAppLockTimeout(timeout);
  }

  Future<void> toggleBiometric(bool enabled) async {
    await _service.toggleBiometric(enabled);
  }

  Future<void> lockChat(String chatId, String? chatName) async {
    await _service.lockChat(LockedChat(
      chatId: chatId,
      chatName: chatName,
      lockedAt: DateTime.now(),
    ));
  }

  Future<void> unlockChat(String chatId) async {
    await _service.unlockChat(chatId);
  }

  bool isChatLocked(String chatId) {
    return _service.isChatLocked(chatId);
  }

  // ============================================================================
  // BLOCKED USERS
  // ============================================================================

  Future<void> blockUser(String userId, String? userName, String? photoUrl) async {
    await _service.blockUser(BlockedUser(
      userId: userId,
      userName: userName,
      userPhotoUrl: photoUrl,
      blockedAt: DateTime.now(),
    ));
  }

  Future<void> unblockUser(String userId) async {
    await _service.unblockUser(userId);
  }

  bool isUserBlocked(String userId) {
    return _service.isUserBlocked(userId);
  }

  List<BlockedUser> get blockedUsers => settings.blockedUsers;

  // ============================================================================
  // SESSIONS
  // ============================================================================

  Future<void> terminateSession(String sessionId) async {
    await _service.terminateSession(sessionId);
  }

  Future<void> terminateAllOtherSessions() async {
    final confirmed = await Get.dialog<bool>(
      const _ConfirmDialog(
        title: 'Log Out Other Sessions',
        message: 'This will log you out of all other devices. You will need to sign in again on those devices.',
      ),
    );

    if (confirmed == true) {
      await _service.terminateAllOtherSessions();
      Get.snackbar(
        'Success',
        'Other sessions have been terminated',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================================================
  // PRIVACY CHECKUP
  // ============================================================================

  Future<PrivacyCheckupResult> runPrivacyCheckup() async {
    return await _service.runPrivacyCheckup();
  }

  Future<bool> autoFixIssue(String issueId) async {
    return await _service.autoFixIssue(issueId);
  }

  // ============================================================================
  // RESET
  // ============================================================================

  Future<void> resetToDefaults() async {
    final confirmed = await Get.dialog<bool>(
      const _ConfirmDialog(
        title: 'Reset Privacy Settings',
        message: 'This will reset all privacy settings to their default values. This action cannot be undone.',
      ),
    );

    if (confirmed == true) {
      await _service.resetToDefaults();
      Get.snackbar(
        'Success',
        'Privacy settings have been reset',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> refresh() async {
    await _service.refresh();
  }
}

// Simple confirm dialog widget
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;

  const _ConfirmDialog({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

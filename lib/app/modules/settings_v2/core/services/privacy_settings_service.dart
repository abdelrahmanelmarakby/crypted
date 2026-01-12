import 'dart:async';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/repositories/privacy_settings_repository.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/debouncer.dart';

/// Enhanced Privacy Settings Service
/// Provides comprehensive privacy settings management with:
/// - Real-time sync across devices
/// - Backend enforcement for visibility
/// - Privacy exceptions per contact
/// - Security logging
/// - Privacy checkup
/// - Debounced saves to prevent race conditions
/// - Repository abstraction for testability

class PrivacySettingsService extends GetxService {
  static PrivacySettingsService get instance => Get.find();

  // Repository for data access (injected for testability)
  late final PrivacySettingsRepository _repository;

  // Debouncer for save operations to prevent race conditions
  final Debouncer _saveDebouncer = Debouncer(milliseconds: 500);

  // Reactive settings
  final Rx<EnhancedPrivacySettingsModel> settings =
      EnhancedPrivacySettingsModel.defaultSettings().obs;

  // Active sessions cache
  final RxList<ActiveSession> activeSessions = <ActiveSession>[].obs;

  // Security log cache (last 20 entries)
  final RxList<SecurityLogEntry> securityLog = <SecurityLogEntry>[].obs;

  // Stream subscriptions
  StreamSubscription? _settingsSubscription;
  StreamSubscription? _sessionsSubscription;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // Current privacy score
  final RxInt privacyScore = 0.obs;

  // UUID generator for unique IDs
  static const _uuid = Uuid();

  /// Create service with optional repository injection (for testing)
  PrivacySettingsService({PrivacySettingsRepository? repository}) {
    _repository = repository ?? FirestorePrivacySettingsRepository();
  }

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
    _sessionsSubscription?.cancel();
    _saveDebouncer.dispose();
    super.onClose();
  }

  Future<void> _initializeSettings() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final userId = UserService.currentUserValue?.uid;
      if (userId == null) {
        developer.log('No user logged in', name: 'PrivacySettingsService');
        return;
      }

      // Load initial settings
      await _loadSettings(userId);

      // Calculate privacy score
      _updatePrivacyScore();

      // Set up real-time listener
      _setupSettingsListener(userId);

      // Load active sessions
      await _loadActiveSessions(userId);

      // Load security log
      await _loadSecurityLog(userId);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize privacy settings',
        name: 'PrivacySettingsService',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load privacy settings';
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================================
  // LOADING
  // ============================================================================

  Future<void> _loadSettings(String userId) async {
    final loadedSettings = await _repository.getSettings(userId);

    if (loadedSettings != null) {
      settings.value = loadedSettings;
    } else {
      // Create default settings - use immediate save for initial setup
      settings.value = EnhancedPrivacySettingsModel.defaultSettings();
      await _saveSettings();
    }
  }

  void _setupSettingsListener(String userId) {
    _settingsSubscription?.cancel();
    _settingsSubscription = _repository.watchSettings(userId).listen(
      (loadedSettings) {
        if (loadedSettings != null) {
          settings.value = loadedSettings;
          _updatePrivacyScore();
        }
      },
      onError: (error) {
        developer.log(
          'Settings listener error',
          name: 'PrivacySettingsService',
          error: error,
        );
      },
    );
  }

  Future<void> _loadActiveSessions(String userId) async {
    try {
      final sessions = await _repository.getActiveSessions(userId);
      activeSessions.clear();
      activeSessions.addAll(sessions);
    } catch (e) {
      developer.log(
        'Failed to load active sessions',
        name: 'PrivacySettingsService',
        error: e,
      );
    }
  }

  Future<void> _loadSecurityLog(String userId) async {
    try {
      final logs = await _repository.getSecurityLog(userId);
      securityLog.clear();
      securityLog.addAll(logs);
    } catch (e) {
      developer.log(
        'Failed to load security log',
        name: 'PrivacySettingsService',
        error: e,
      );
    }
  }

  void _updatePrivacyScore() {
    privacyScore.value = settings.value.calculatePrivacyScore();
  }

  // ============================================================================
  // SAVING
  // ============================================================================

  /// Debounced save to prevent race conditions from rapid setting changes.
  /// Multiple calls within 500ms will be coalesced into a single save.
  Future<void> _debouncedSave() {
    return _saveDebouncer.run(() => _saveSettingsInternal());
  }

  /// Immediate save without debouncing (used for initial setup and reset).
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

      await _repository.saveSettings(userId, settings.value);

      _updatePrivacyScore();

      developer.log(
        'Privacy settings saved',
        name: 'PrivacySettingsService',
      );
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to save privacy settings',
        name: 'PrivacySettingsService',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to save settings';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _logSecurityEvent(SecurityEventType type, {Map<String, dynamic>? metadata}) async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      final entry = SecurityLogEntry(
        id: _uuid.v4(), // Use UUID for guaranteed uniqueness
        eventType: type,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _repository.addSecurityLogEntry(userId, entry);

      securityLog.insert(0, entry);
      if (securityLog.length > 20) {
        securityLog.removeLast();
      }
    } catch (e) {
      developer.log(
        'Failed to log security event',
        name: 'PrivacySettingsService',
        error: e,
      );
    }
  }

  // ============================================================================
  // PROFILE VISIBILITY
  // ============================================================================

  /// Update last seen visibility
  Future<void> updateLastSeenVisibility(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      profileVisibility: settings.value.profileVisibility.copyWith(lastSeen: setting),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.privacyChanged, metadata: {'field': 'lastSeen'});
  }

  /// Update profile photo visibility
  Future<void> updateProfilePhotoVisibility(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      profileVisibility: settings.value.profileVisibility.copyWith(profilePhoto: setting),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.privacyChanged, metadata: {'field': 'profilePhoto'});
  }

  /// Update about visibility
  Future<void> updateAboutVisibility(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      profileVisibility: settings.value.profileVisibility.copyWith(about: setting),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.privacyChanged, metadata: {'field': 'about'});
  }

  /// Update online status visibility
  Future<void> updateOnlineStatusVisibility(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      profileVisibility: settings.value.profileVisibility.copyWith(onlineStatus: setting),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.privacyChanged, metadata: {'field': 'onlineStatus'});
  }

  /// Update status visibility
  Future<void> updateStatusVisibility(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      profileVisibility: settings.value.profileVisibility.copyWith(status: setting),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.privacyChanged, metadata: {'field': 'status'});
  }

  // ============================================================================
  // COMMUNICATION SETTINGS
  // ============================================================================

  /// Update who can message
  Future<void> updateWhoCanMessage(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      communication: settings.value.communication.copyWith(whoCanMessage: setting),
    );
    await _debouncedSave();
  }

  /// Update who can call
  Future<void> updateWhoCanCall(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      communication: settings.value.communication.copyWith(whoCanCall: setting),
    );
    await _debouncedSave();
  }

  /// Update who can add to groups
  Future<void> updateWhoCanAddToGroups(VisibilitySettingWithExceptions setting) async {
    settings.value = settings.value.copyWith(
      communication: settings.value.communication.copyWith(whoCanAddToGroups: setting),
    );
    await _debouncedSave();
  }

  /// Toggle typing indicator
  Future<void> toggleTypingIndicator(bool enabled) async {
    settings.value = settings.value.copyWith(
      communication: settings.value.communication.copyWith(showTypingIndicator: enabled),
    );
    await _debouncedSave();
  }

  /// Toggle read receipts
  Future<void> toggleReadReceipts(bool enabled) async {
    settings.value = settings.value.copyWith(
      communication: settings.value.communication.copyWith(showReadReceipts: enabled),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // CONTENT PROTECTION
  // ============================================================================

  /// Toggle screenshots
  Future<void> toggleScreenshots(bool allowed) async {
    settings.value = settings.value.copyWith(
      contentProtection: settings.value.contentProtection.copyWith(allowScreenshots: allowed),
    );
    await _debouncedSave();
  }

  /// Toggle forwarding
  Future<void> toggleForwarding(bool allowed) async {
    settings.value = settings.value.copyWith(
      contentProtection: settings.value.contentProtection.copyWith(allowForwarding: allowed),
    );
    await _debouncedSave();
  }

  /// Update default disappearing duration
  Future<void> updateDefaultDisappearingDuration(DisappearingDuration duration) async {
    settings.value = settings.value.copyWith(
      contentProtection: settings.value.contentProtection.copyWith(
        defaultDisappearingDuration: duration,
      ),
    );
    await _debouncedSave();
  }

  /// Toggle hide media in gallery
  Future<void> toggleHideMediaInGallery(bool hide) async {
    settings.value = settings.value.copyWith(
      contentProtection: settings.value.contentProtection.copyWith(hideMediaInGallery: hide),
    );
    await _debouncedSave();
  }

  // ============================================================================
  // SECURITY SETTINGS
  // ============================================================================

  /// Toggle two-step verification
  Future<void> toggleTwoStepVerification(bool enabled) async {
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(
        twoStepVerification: settings.value.security.twoStepVerification.copyWith(
          enabled: enabled,
        ),
      ),
    );
    await _debouncedSave();
    await _logSecurityEvent(
      enabled ? SecurityEventType.twoStepEnabled : SecurityEventType.twoStepDisabled,
    );
  }

  /// Update recovery email
  Future<void> updateRecoveryEmail(String email) async {
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(
        twoStepVerification: settings.value.security.twoStepVerification.copyWith(
          recoveryEmail: email,
          emailVerified: false,
        ),
      ),
    );
    await _debouncedSave();
  }

  /// Toggle app lock
  Future<void> toggleAppLock(bool enabled) async {
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(
        appLock: settings.value.security.appLock.copyWith(enabled: enabled),
      ),
    );
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.appLockChanged, metadata: {'enabled': enabled});
  }

  /// Update app lock timeout
  Future<void> updateAppLockTimeout(AppLockTimeout timeout) async {
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(
        appLock: settings.value.security.appLock.copyWith(timeout: timeout),
      ),
    );
    await _debouncedSave();
  }

  /// Toggle biometric for app lock
  Future<void> toggleBiometric(bool enabled) async {
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(
        appLock: settings.value.security.appLock.copyWith(biometricEnabled: enabled),
      ),
    );
    await _debouncedSave();
  }

  /// Lock a chat
  Future<void> lockChat(LockedChat chat) async {
    final lockedChats = [...settings.value.security.lockedChats, chat];
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(lockedChats: lockedChats),
    );
    await _debouncedSave();
  }

  /// Unlock a chat
  Future<void> unlockChat(String chatId) async {
    final lockedChats = settings.value.security.lockedChats
        .where((c) => c.chatId != chatId)
        .toList();
    settings.value = settings.value.copyWith(
      security: settings.value.security.copyWith(lockedChats: lockedChats),
    );
    await _debouncedSave();
  }

  /// Check if chat is locked
  bool isChatLocked(String chatId) {
    return settings.value.security.lockedChats.any((c) => c.chatId == chatId);
  }

  // ============================================================================
  // BLOCKED USERS
  // ============================================================================

  /// Block a user
  Future<void> blockUser(BlockedUser user) async {
    if (settings.value.isBlocked(user.userId)) return;

    final blockedUsers = [...settings.value.blockedUsers, user];
    settings.value = settings.value.copyWith(blockedUsers: blockedUsers);
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.blockedUser, metadata: {'userId': user.userId});

    // Also update the user's global blocked list
    final userId = UserService.currentUserValue?.uid;
    if (userId != null) {
      await _repository.addToBlockedList(userId, user.userId);
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userIdToUnblock) async {
    final blockedUsers = settings.value.blockedUsers
        .where((b) => b.userId != userIdToUnblock)
        .toList();
    settings.value = settings.value.copyWith(blockedUsers: blockedUsers);
    await _debouncedSave();
    await _logSecurityEvent(SecurityEventType.unblockedUser, metadata: {'userId': userIdToUnblock});

    // Also update the user's global blocked list
    final userId = UserService.currentUserValue?.uid;
    if (userId != null) {
      await _repository.removeFromBlockedList(userId, userIdToUnblock);
    }
  }

  /// Check if user is blocked
  bool isUserBlocked(String userId) {
    return settings.value.isBlocked(userId);
  }

  // ============================================================================
  // SESSIONS MANAGEMENT
  // ============================================================================

  /// Terminate a session
  Future<void> terminateSession(String sessionId) async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      await _repository.deleteSession(userId, sessionId);

      activeSessions.removeWhere((s) => s.sessionId == sessionId);
      await _logSecurityEvent(SecurityEventType.deviceRemoved, metadata: {'sessionId': sessionId});
    } catch (e) {
      developer.log(
        'Failed to terminate session',
        name: 'PrivacySettingsService',
        error: e,
      );
    }
  }

  /// Terminate all other sessions
  Future<void> terminateAllOtherSessions() async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      // Find current session ID
      final currentSession = activeSessions.firstWhereOrNull((s) => s.isCurrentSession);
      if (currentSession == null) return;

      await _repository.deleteAllOtherSessions(userId, currentSession.sessionId);

      activeSessions.removeWhere((s) => !s.isCurrentSession);
    } catch (e) {
      developer.log(
        'Failed to terminate other sessions',
        name: 'PrivacySettingsService',
        error: e,
      );
    }
  }

  // ============================================================================
  // BACKEND ENFORCEMENT
  // ============================================================================

  /// Check if user can see profile field
  /// This is called by the backend before returning user data
  VisibilityDecision canSeeProfileField({
    required String requesterId,
    required PrivacyField field,
    required bool isContact,
  }) {
    final visibilitySetting = settings.value.profileVisibility.getByField(field);
    final isVisible = visibilitySetting.isVisibleTo(requesterId, isContact: isContact);

    return VisibilityDecision(
      isVisible: isVisible,
      reason: isVisible ? null : _getVisibilityReason(visibilitySetting.level),
    );
  }

  /// Check if user can send message
  VisibilityDecision canSendMessage({
    required String senderId,
    required bool isContact,
  }) {
    // Check if blocked
    if (isUserBlocked(senderId)) {
      return VisibilityDecision(isVisible: false, reason: 'User is blocked');
    }

    final setting = settings.value.communication.whoCanMessage;
    final canMessage = setting.isVisibleTo(senderId, isContact: isContact);

    return VisibilityDecision(
      isVisible: canMessage,
      reason: canMessage ? null : _getVisibilityReason(setting.level),
    );
  }

  /// Check if user can call
  VisibilityDecision canCall({
    required String callerId,
    required bool isContact,
  }) {
    // Check if blocked
    if (isUserBlocked(callerId)) {
      return VisibilityDecision(isVisible: false, reason: 'User is blocked');
    }

    final setting = settings.value.communication.whoCanCall;
    final canCall = setting.isVisibleTo(callerId, isContact: isContact);

    return VisibilityDecision(
      isVisible: canCall,
      reason: canCall ? null : _getVisibilityReason(setting.level),
    );
  }

  /// Check if user can add to group
  VisibilityDecision canAddToGroup({
    required String adderId,
    required bool isContact,
  }) {
    // Check if blocked
    if (isUserBlocked(adderId)) {
      return VisibilityDecision(isVisible: false, reason: 'User is blocked');
    }

    final setting = settings.value.communication.whoCanAddToGroups;
    final canAdd = setting.isVisibleTo(adderId, isContact: isContact);

    return VisibilityDecision(
      isVisible: canAdd,
      reason: canAdd ? null : _getVisibilityReason(setting.level),
    );
  }

  String _getVisibilityReason(VisibilityLevel level) {
    switch (level) {
      case VisibilityLevel.nobody:
      case VisibilityLevel.nobodyExcept:
        return 'This information is private';
      case VisibilityLevel.contacts:
      case VisibilityLevel.contactsExcept:
        return 'Only visible to contacts';
      default:
        return 'Not available';
    }
  }

  // ============================================================================
  // PRIVACY CHECKUP
  // ============================================================================

  /// Run privacy checkup
  Future<PrivacyCheckupResult> runPrivacyCheckup() async {
    final issues = <PrivacyIssue>[];
    final recommendations = <PrivacyRecommendation>[];
    int totalDeductions = 0;

    // Helper to track deductions safely
    void addDeduction(int points) {
      totalDeductions += points;
    }

    // Check profile visibility settings
    if (settings.value.profileVisibility.lastSeen.level == VisibilityLevel.everyone) {
      issues.add(PrivacyIssue(
        id: 'lastSeen_everyone',
        title: 'Last Seen Visible to Everyone',
        description: 'Anyone can see when you were last online.',
        relatedField: PrivacyField.lastSeen,
        severityScore: 5,
        canAutoFix: true,
      ));
      addDeduction(5);
    }

    if (settings.value.profileVisibility.profilePhoto.level == VisibilityLevel.everyone) {
      issues.add(PrivacyIssue(
        id: 'profilePhoto_everyone',
        title: 'Profile Photo Visible to Everyone',
        description: 'Anyone can see your profile photo.',
        relatedField: PrivacyField.profilePhoto,
        severityScore: 3,
        canAutoFix: true,
      ));
      addDeduction(3);
    }

    // Check communication settings
    if (settings.value.communication.whoCanMessage.level == VisibilityLevel.everyone) {
      issues.add(PrivacyIssue(
        id: 'messages_everyone',
        title: 'Anyone Can Message You',
        description: 'Non-contacts can send you messages.',
        relatedField: PrivacyField.messages,
        severityScore: 5,
        canAutoFix: true,
      ));
      addDeduction(5);
    }

    // Check security settings
    if (!settings.value.security.twoStepVerification.enabled) {
      issues.add(PrivacyIssue(
        id: 'twoStep_disabled',
        title: 'Two-Step Verification Disabled',
        description: 'Your account is less secure without two-step verification.',
        severityScore: 10,
        canAutoFix: false,
      ));
      recommendations.add(PrivacyRecommendation(
        id: 'enable_twoStep',
        title: 'Enable Two-Step Verification',
        description: 'Add an extra layer of security to your account.',
        actionLabel: 'Enable',
        priority: 1,
      ));
      addDeduction(15);
    }

    if (!settings.value.security.appLock.enabled) {
      issues.add(PrivacyIssue(
        id: 'appLock_disabled',
        title: 'App Lock Disabled',
        description: 'Anyone with access to your phone can open the app.',
        severityScore: 7,
        canAutoFix: false,
      ));
      recommendations.add(PrivacyRecommendation(
        id: 'enable_appLock',
        title: 'Enable App Lock',
        description: 'Require authentication to open the app.',
        actionLabel: 'Enable',
        priority: 2,
      ));
      addDeduction(10);
    }

    // Check content protection
    if (settings.value.contentProtection.defaultDisappearingDuration == DisappearingDuration.off) {
      recommendations.add(PrivacyRecommendation(
        id: 'enable_disappearing',
        title: 'Enable Disappearing Messages',
        description: 'Messages will automatically disappear after a set time.',
        actionLabel: 'Configure',
        priority: 3,
      ));
      addDeduction(5);
    }

    // Check active sessions
    if (activeSessions.length > 3) {
      issues.add(PrivacyIssue(
        id: 'many_sessions',
        title: 'Multiple Active Sessions',
        description: 'You have ${activeSessions.length} active sessions.',
        severityScore: 3,
        canAutoFix: true,
      ));
      // Note: Sessions count doesn't affect score to avoid over-penalization
    }

    // Calculate final score with proper clamping
    final score = (100 - totalDeductions).clamp(0, 100);

    final result = PrivacyCheckupResult(
      score: score,
      issues: issues,
      recommendations: recommendations,
      checkedAt: DateTime.now(),
    );

    // Save checkup result
    settings.value = settings.value.copyWith(lastCheckupResult: result);
    await _debouncedSave();

    return result;
  }

  /// Apply auto-fix for an issue
  Future<bool> autoFixIssue(String issueId) async {
    switch (issueId) {
      case 'lastSeen_everyone':
        await updateLastSeenVisibility(
          const VisibilitySettingWithExceptions(level: VisibilityLevel.contacts),
        );
        return true;
      case 'profilePhoto_everyone':
        await updateProfilePhotoVisibility(
          const VisibilitySettingWithExceptions(level: VisibilityLevel.contacts),
        );
        return true;
      case 'messages_everyone':
        await updateWhoCanMessage(
          const VisibilitySettingWithExceptions(level: VisibilityLevel.contacts),
        );
        return true;
      case 'many_sessions':
        await terminateAllOtherSessions();
        return true;
      default:
        return false;
    }
  }

  // ============================================================================
  // RESET
  // ============================================================================

  /// Reset all privacy settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final userId = UserService.currentUserValue?.uid;
      if (userId == null) return;

      // Reset settings to defaults
      settings.value = EnhancedPrivacySettingsModel.defaultSettings();

      // Use repository to delete all settings (sessions, security logs)
      await _repository.deleteAllSettings(userId);

      // Save new default settings
      await _saveSettings();

      // Clear local caches
      activeSessions.clear();
      securityLog.clear();

      _updatePrivacyScore();

      developer.log(
        'Privacy settings reset to defaults',
        name: 'PrivacySettingsService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to reset privacy settings',
        name: 'PrivacySettingsService',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to reset settings';
    }
  }

  /// Refresh settings from server
  Future<void> refresh() async {
    await _initializeSettings();
  }
}

// ============================================================================
// VISIBILITY DECISION
// ============================================================================

/// Result of visibility check
class VisibilityDecision {
  final bool isVisible;
  final String? reason;

  const VisibilityDecision({
    required this.isVisible,
    this.reason,
  });
}

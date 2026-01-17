import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/services/privacy_settings_service.dart';

/// App Lock Service - Provides biometric/PIN authentication for the app
/// Features:
/// - Biometric authentication (fingerprint, face)
/// - PIN fallback
/// - Auto-lock after timeout
/// - Lock specific chats
/// - Integration with privacy settings
class AppLockService extends GetxService {
  static AppLockService get instance => Get.find();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // State
  final RxBool isLocked = false.obs;
  final RxBool isBiometricAvailable = false.obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxBool isAppLockEnabled = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  // Timestamps
  DateTime? _lastUnlockTime;
  DateTime? _lastBackgroundTime;

  // Timer for auto-lock
  Timer? _lockTimer;

  // Privacy settings reference
  PrivacySettingsService? _privacyService;

  PrivacySettingsService? get _privacy {
    if (_privacyService == null) {
      try {
        _privacyService = Get.find<PrivacySettingsService>();
      } catch (_) {
        // Service not registered yet
      }
    }
    return _privacyService;
  }

  // Storage keys
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyPinHash = 'app_lock_pin_hash';
  static const String _keyLockTimeout = 'app_lock_timeout';
  static const String _keyLastUnlock = 'app_lock_last_unlock';

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Check biometric availability
      await _checkBiometricAvailability();

      // Load settings from local storage
      await _loadSettings();

      developer.log('AppLockService initialized', name: 'AppLockService');
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing AppLockService',
        name: 'AppLockService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void onClose() {
    _lockTimer?.cancel();
    super.onClose();
  }

  // ============================================================================
  // BIOMETRIC CHECK
  // ============================================================================

  /// Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      // Check if device supports biometrics
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      isBiometricAvailable.value = canCheck && isDeviceSupported;

      if (isBiometricAvailable.value) {
        // Get available biometric types
        final biometrics = await _localAuth.getAvailableBiometrics();
        availableBiometrics.value = biometrics;

        developer.log(
          'Available biometrics: $biometrics',
          name: 'AppLockService',
        );
      }
    } on PlatformException catch (e) {
      developer.log(
        'Error checking biometrics: ${e.message}',
        name: 'AppLockService',
      );
      isBiometricAvailable.value = false;
    }
  }

  /// Get the primary biometric type available
  BiometricType? get primaryBiometric {
    if (availableBiometrics.isEmpty) return null;

    // Prefer face, then fingerprint, then others
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    } else if (availableBiometrics.contains(BiometricType.weak)) {
      return BiometricType.weak;
    }
    return availableBiometrics.first;
  }

  /// Get display name for biometric type
  String get biometricDisplayName {
    switch (primaryBiometric) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.strong:
      case BiometricType.weak:
        return 'Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get icon for biometric type
  IconData get biometricIcon {
    switch (primaryBiometric) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      default:
        return Icons.security;
    }
  }

  // ============================================================================
  // SETTINGS MANAGEMENT
  // ============================================================================

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      isAppLockEnabled.value = prefs.getBool(_keyAppLockEnabled) ?? false;
      isBiometricEnabled.value = prefs.getBool(_keyBiometricEnabled) ?? true;

      // Check if we need to lock based on last unlock time
      if (isAppLockEnabled.value) {
        final lastUnlockMs = prefs.getInt(_keyLastUnlock);
        if (lastUnlockMs != null) {
          _lastUnlockTime = DateTime.fromMillisecondsSinceEpoch(lastUnlockMs);
        }
        _checkAutoLock();
      }
    } catch (e) {
      developer.log('Error loading settings: $e', name: 'AppLockService');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_keyAppLockEnabled, isAppLockEnabled.value);
      await prefs.setBool(_keyBiometricEnabled, isBiometricEnabled.value);

      if (_lastUnlockTime != null) {
        await prefs.setInt(
          _keyLastUnlock,
          _lastUnlockTime!.millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      developer.log('Error saving settings: $e', name: 'AppLockService');
    }
  }

  // ============================================================================
  // APP LOCK CONTROL
  // ============================================================================

  /// Enable app lock
  Future<bool> enableAppLock({bool enableBiometric = true}) async {
    try {
      isAppLockEnabled.value = true;
      isBiometricEnabled.value = enableBiometric && isBiometricAvailable.value;
      await _saveSettings();

      // Update privacy settings if available
      _privacy?.toggleAppLock(true);

      developer.log('App lock enabled', name: 'AppLockService');
      return true;
    } catch (e) {
      developer.log('Error enabling app lock: $e', name: 'AppLockService');
      return false;
    }
  }

  /// Disable app lock
  Future<bool> disableAppLock() async {
    try {
      // Require authentication before disabling
      final authenticated = await authenticate(
        reason: 'Authenticate to disable app lock',
      );

      if (!authenticated) return false;

      isAppLockEnabled.value = false;
      isLocked.value = false;
      _lockTimer?.cancel();
      await _saveSettings();

      // Update privacy settings if available
      _privacy?.toggleAppLock(false);

      developer.log('App lock disabled', name: 'AppLockService');
      return true;
    } catch (e) {
      developer.log('Error disabling app lock: $e', name: 'AppLockService');
      return false;
    }
  }

  /// Toggle biometric authentication
  Future<bool> toggleBiometric(bool enabled) async {
    try {
      if (enabled && !isBiometricAvailable.value) {
        return false;
      }

      isBiometricEnabled.value = enabled;
      await _saveSettings();

      // Update privacy settings if available
      _privacy?.toggleBiometric(enabled);

      developer.log(
        'Biometric ${enabled ? 'enabled' : 'disabled'}',
        name: 'AppLockService',
      );
      return true;
    } catch (e) {
      developer.log('Error toggling biometric: $e', name: 'AppLockService');
      return false;
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Authenticate the user
  Future<bool> authenticate({
    String reason = 'Authenticate to access the app',
    bool biometricOnly = false,
  }) async {
    if (!isAppLockEnabled.value) {
      return true; // No lock enabled, always authenticated
    }

    try {
      bool authenticated = false;

      // Try biometric first if enabled
      if (isBiometricEnabled.value && isBiometricAvailable.value) {
        authenticated = await _authenticateWithBiometrics(reason);
      }

      // If biometric failed or not available, and biometricOnly is false
      if (!authenticated && !biometricOnly) {
        // Fall back to device credentials (PIN/password/pattern)
        authenticated = await _authenticateWithDeviceCredentials(reason);
      }

      if (authenticated) {
        _onAuthenticationSuccess();
      }

      return authenticated;
    } catch (e) {
      developer.log('Authentication error: $e', name: 'AppLockService');
      return false;
    }
  }

  /// Authenticate with biometrics only
  Future<bool> _authenticateWithBiometrics(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      developer.log(
        'Biometric authentication error: ${e.message}',
        name: 'AppLockService',
      );
      return false;
    }
  }

  /// Authenticate with device credentials (PIN/password/pattern)
  Future<bool> _authenticateWithDeviceCredentials(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      developer.log(
        'Device credential authentication error: ${e.message}',
        name: 'AppLockService',
      );
      return false;
    }
  }

  void _onAuthenticationSuccess() {
    isLocked.value = false;
    _lastUnlockTime = DateTime.now();
    _saveSettings();

    // Update privacy settings if available
    final settings = _privacy?.settings.value.security.appLock;
    if (settings != null) {
      _privacy?.settings.value = _privacy!.settings.value.copyWith(
        security: _privacy!.settings.value.security.copyWith(
          appLock: settings.copyWith(lastUnlocked: _lastUnlockTime),
        ),
      );
    }

    developer.log('Authentication successful', name: 'AppLockService');
  }

  // ============================================================================
  // AUTO-LOCK
  // ============================================================================

  /// Get the current lock timeout setting
  AppLockTimeout get lockTimeout {
    final settings = _privacy?.settings.value.security.appLock;
    return settings?.timeout ?? AppLockTimeout.immediately;
  }

  /// Check if the app should auto-lock based on timeout
  void _checkAutoLock() {
    if (!isAppLockEnabled.value) {
      isLocked.value = false;
      return;
    }

    if (_lastUnlockTime == null) {
      isLocked.value = true;
      return;
    }

    final timeout = lockTimeout.duration;
    if (timeout == Duration.zero) {
      // Immediately lock
      isLocked.value = true;
      return;
    }

    final elapsed = DateTime.now().difference(_lastUnlockTime!);
    if (elapsed >= timeout) {
      isLocked.value = true;
    }
  }

  /// Called when app goes to background
  void onAppPaused() {
    _lastBackgroundTime = DateTime.now();
    developer.log('App paused', name: 'AppLockService');
  }

  /// Called when app comes to foreground
  void onAppResumed() {
    if (!isAppLockEnabled.value) return;

    if (_lastBackgroundTime == null) {
      _checkAutoLock();
      return;
    }

    final timeout = lockTimeout.duration;
    final elapsed = DateTime.now().difference(_lastBackgroundTime!);

    if (timeout == Duration.zero || elapsed >= timeout) {
      isLocked.value = true;
      developer.log('App locked after timeout', name: 'AppLockService');
    }

    _lastBackgroundTime = null;
  }

  /// Lock the app immediately
  void lockNow() {
    if (!isAppLockEnabled.value) return;

    isLocked.value = true;
    developer.log('App locked manually', name: 'AppLockService');
  }

  // ============================================================================
  // CHAT LOCK
  // ============================================================================

  /// Check if a chat is locked
  bool isChatLocked(String chatId) {
    final settings = _privacy?.settings.value.security;
    if (settings == null) return false;

    return settings.lockedChats.any((c) => c.chatId == chatId);
  }

  /// Lock a specific chat
  Future<bool> lockChat({
    required String chatId,
    String? chatName,
    String? chatPhotoUrl,
    bool requireBiometric = true,
  }) async {
    try {
      // Require authentication before locking
      final authenticated = await authenticate(
        reason: 'Authenticate to lock this chat',
      );

      if (!authenticated) return false;

      final lockedChat = LockedChat(
        chatId: chatId,
        chatName: chatName,
        chatPhotoUrl: chatPhotoUrl,
        lockedAt: DateTime.now(),
        requireBiometric: requireBiometric,
      );

      await _privacy?.lockChat(lockedChat);

      developer.log('Chat locked: $chatId', name: 'AppLockService');
      return true;
    } catch (e) {
      developer.log('Error locking chat: $e', name: 'AppLockService');
      return false;
    }
  }

  /// Unlock a specific chat
  Future<bool> unlockChat(String chatId) async {
    try {
      // Require authentication before unlocking
      final authenticated = await authenticate(
        reason: 'Authenticate to unlock this chat',
      );

      if (!authenticated) return false;

      await _privacy?.unlockChat(chatId);

      developer.log('Chat unlocked: $chatId', name: 'AppLockService');
      return true;
    } catch (e) {
      developer.log('Error unlocking chat: $e', name: 'AppLockService');
      return false;
    }
  }

  /// Authenticate to access a locked chat
  Future<bool> authenticateForChat(String chatId) async {
    final settings = _privacy?.settings.value.security;
    if (settings == null) return true;

    final lockedChat = settings.lockedChats
        .cast<LockedChat?>()
        .firstWhere((c) => c?.chatId == chatId, orElse: () => null);

    if (lockedChat == null) return true; // Chat not locked

    return await authenticate(
      reason: 'Authenticate to access this chat',
      biometricOnly: lockedChat.requireBiometric,
    );
  }

  // ============================================================================
  // STATUS
  // ============================================================================

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isAppLockEnabled': isAppLockEnabled.value,
      'isBiometricEnabled': isBiometricEnabled.value,
      'isBiometricAvailable': isBiometricAvailable.value,
      'isLocked': isLocked.value,
      'availableBiometrics': availableBiometrics.map((b) => b.name).toList(),
      'lockTimeout': lockTimeout.displayName,
      'lastUnlockTime': _lastUnlockTime?.toIso8601String(),
    };
  }
}

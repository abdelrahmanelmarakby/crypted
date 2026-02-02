import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/core/services/zego/zego_call_config.dart';

/// Result of a ZEGO call invitation attempt.
///
/// Replaces the raw `bool` return from `sendCallInvitation()` so callers
/// can show specific error messages instead of generic failures.
class ZegoCallInvitationResult {
  final bool success;
  final String? errorMessage;
  final int? errorCode;

  const ZegoCallInvitationResult._({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });

  factory ZegoCallInvitationResult.ok() =>
      const ZegoCallInvitationResult._(success: true);

  factory ZegoCallInvitationResult.failed({
    String? message,
    int? code,
  }) =>
      ZegoCallInvitationResult._(
        success: false,
        errorMessage: message ?? 'Call invitation failed',
        errorCode: code,
      );

  /// Map known ZIM error codes to user-friendly messages.
  String get userFacingMessage {
    if (success) return '';
    switch (errorCode) {
      case 107026:
        return 'This user is not available for calls. '
            'They may need to update their app.';
      case 6000281:
        // Wrapper code for ZIM callInvite failure — check inner code
        return errorMessage ?? 'Could not reach the other user.';
      case 301003001:
        // Signaling plugin error wrapping a ZIM failure
        return errorMessage ?? 'Call service error. Please try again.';
      default:
        return errorMessage ?? 'Could not connect the call. Please try again.';
    }
  }
}

/// Centralized service for managing ZEGO Cloud video/audio calls.
///
/// This service handles:
/// - ZEGO SDK initialization and cleanup
/// - Call invitation service setup
/// - User login/logout for call features
/// - Call configuration management
class ZegoCallService extends GetxService {
  static ZegoCallService get instance => Get.find<ZegoCallService>();

  // Private constructor for singleton pattern
  ZegoCallService._();

  static ZegoCallService? _instance;

  /// Factory constructor to get singleton instance
  factory ZegoCallService() {
    _instance ??= ZegoCallService._();
    return _instance!;
  }

  // State management
  final RxBool _isInitialized = false.obs;
  final RxBool _isUserLoggedIn = false.obs;
  final Rxn<String> _currentUserId = Rxn<String>();
  final Rxn<String> _currentUserName = Rxn<String>();

  // Track current outgoing call invitees for cancellation
  List<ZegoCallUser>? _currentCallInvitees;

  // ZIM connection state monitoring
  StreamSubscription? _connectionStateSubscription;

  // Getters
  bool get isInitialized => _isInitialized.value;
  bool get isUserLoggedIn => _isUserLoggedIn.value;
  String? get currentUserId => _currentUserId.value;
  String? get currentUserName => _currentUserName.value;

  /// Initialize ZEGO SDK with navigator key.
  /// Call this in main() before runApp().
  Future<void> initializeSDK(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized.value) {
      log('[ZegoCallService] SDK already initialized');
      return;
    }

    try {
      log('[ZegoCallService] Initializing ZEGO SDK...');

      // Set navigator key for call invitation service
      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

      // Initialize ZEGO logging
      await ZegoUIKit().initLog();

      // Enable system calling UI (CallKit) for non-China regions
      if (!_isUserInChina()) {
        ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
          [ZegoUIKitSignalingPlugin()],
        );
        log('[ZegoCallService] CallKit enabled for non-China region');
      } else {
        log('[ZegoCallService] CallKit disabled for China region (MIIT compliance)');
      }

      _isInitialized.value = true;
      log('[ZegoCallService] SDK initialized successfully');
    } catch (e, stackTrace) {
      log('[ZegoCallService] Failed to initialize SDK: $e');
      log('[ZegoCallService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Login user to ZEGO call service.
  /// Call this after user authentication succeeds.
  Future<void> loginUser({
    required String userId,
    required String userName,
    String? userAvatarUrl,
  }) async {
    if (!_isInitialized.value) {
      log('[ZegoCallService] Cannot login - SDK not initialized');
      throw Exception('ZEGO SDK not initialized. Call initializeSDK first.');
    }

    if (_isUserLoggedIn.value && _currentUserId.value == userId) {
      log('[ZegoCallService] User already logged in: $userId');
      return;
    }

    try {
      log('[ZegoCallService] Logging in user: $userId ($userName)');

      // Auth strategy:
      // - appSign → used for both ZIM SDK init (ZIM.create) and ZIM login.
      // - Do NOT pass client-generated Token04 to init() — it causes ZIM to
      //   hang in 'connecting' state when the server can't validate it.
      //   ZIM.login() resolves its Future BEFORE the server acknowledges,
      //   so the SDK thinks login succeeded while ZIM stays stuck.
      // - Express room auth also uses appSign. The onTokenExpired callback
      //   provides Token04 for renewal if needed during an active call.
      log('[ZegoCallService] Initializing ZEGO invitation service (appSign auth)...');

      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConstants.appID,
        appSign: AppConstants.appSign,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],

        // Notification configuration using new API
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            callChannel: ZegoCallAndroidNotificationChannelConfig(
              channelID: "crypted_calls",
              channelName: "Crypted Calls",
              sound: "zego_incoming",
              icon: "ic_launcher",
            ),
          ),
          iOSNotificationConfig: ZegoCallIOSNotificationConfig(
            systemCallingIconName: 'CallKitIcon',
            isSandboxEnvironment: false,
          ),
        ),

        // Call invitation configuration using new API
        config: ZegoCallInvitationConfig(
          inCalling: ZegoCallInvitationInCallingConfig(
            canInvitingInCalling: false,
            onlyInitiatorCanInvite: false,
          ),
          endCallWhenInitiatorLeave: true,
        ),

        // Incoming call configuration
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallDeclineButtonPressed: () {
            log('[ZegoCallService] User declined incoming call');
          },
          onIncomingCallAcceptButtonPressed: () {
            log('[ZegoCallService] User accepted incoming call');
          },
          onOutgoingCallCancelButtonPressed: () {
            log('[ZegoCallService] User cancelled outgoing call');
          },
          onIncomingCallReceived: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            log('[ZegoCallService] Incoming call received: $callID from ${caller.name}');
          },
          onIncomingCallCanceled: (
            String callID,
            ZegoCallUser caller,
            String customData,
          ) {
            log('[ZegoCallService] Incoming call cancelled: $callID');
          },
          onOutgoingCallAccepted: (
            String callID,
            ZegoCallUser callee,
          ) {
            log('[ZegoCallService] Outgoing call accepted by ${callee.name}');
          },
          onOutgoingCallRejectedCauseBusy: (
            String callID,
            ZegoCallUser callee,
            String customData,
          ) {
            log('[ZegoCallService] Call rejected - user busy: ${callee.name}');
            Get.snackbar(
              'Call Failed',
              '${callee.name} is busy',
              snackPosition: SnackPosition.TOP,
            );
          },
          onOutgoingCallDeclined: (
            String callID,
            ZegoCallUser callee,
            String customData,
          ) {
            log('[ZegoCallService] Outgoing call declined by ${callee.name}');
          },
          onOutgoingCallTimeout: (
            String callID,
            List<ZegoCallUser> callees,
            bool isVideoCall,
          ) {
            log('[ZegoCallService] Outgoing call timeout');
            Get.snackbar(
              'Call Failed',
              'No answer',
              snackPosition: SnackPosition.TOP,
            );
          },
          onIncomingCallTimeout: (
            String callID,
            ZegoCallUser caller,
          ) {
            log('[ZegoCallService] Incoming call timeout from ${caller.name}');
          },
        ),
      );

      _currentUserId.value = userId;
      _currentUserName.value = userName;
      _isUserLoggedIn.value = true;

      // Monitor ZIM connection state changes for diagnostics.
      // ZIM.login() resolves before the server responds, so we need the
      // stream to know when the connection is actually established.
      _connectionStateSubscription?.cancel();
      try {
        _connectionStateSubscription = ZegoUIKit()
            .getSignalingPlugin()
            .getConnectionStateStream()
            .listen((event) {
          log('[ZegoCallService] 📡 ZIM state: ${event.state} (action: ${event.action})');
        });

        final immediateState =
            ZegoUIKit().getSignalingPlugin().getConnectionState();
        log('[ZegoCallService] Post-init ZIM state: $immediateState');
      } catch (e) {
        log('[ZegoCallService] Connection state monitoring failed: $e');
      }

      log('[ZegoCallService] User logged in successfully: $userId');
    } catch (e, stackTrace) {
      log('[ZegoCallService] Failed to login user: $e');
      log('[ZegoCallService] Stack trace: $stackTrace');
      _isUserLoggedIn.value = false;
      rethrow;
    }
  }

  /// Logout user from ZEGO call service.
  /// Call this when user logs out of the app.
  Future<void> logoutUser() async {
    if (!_isUserLoggedIn.value) {
      log('[ZegoCallService] No user logged in');
      return;
    }

    try {
      log('[ZegoCallService] Logging out user: ${_currentUserId.value}');

      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      await ZegoUIKitPrebuiltCallInvitationService().uninit();

      _currentUserId.value = null;
      _currentUserName.value = null;
      _isUserLoggedIn.value = false;

      log('[ZegoCallService] User logged out successfully');
    } catch (e) {
      log('[ZegoCallService] Error during logout: $e');
    }
  }

  /// Send a call invitation to a user.
  ///
  /// Returns a [ZegoCallInvitationResult] with success/failure status and,
  /// on failure, the ZIM error code and a user-facing error message.
  ///
  /// [callID] is the ZEGO room ID both parties will join. If provided,
  /// ensures the caller and callee end up in the same room.
  Future<ZegoCallInvitationResult> sendCallInvitation({
    required String calleeId,
    required String calleeName,
    required bool isVideoCall,
    String? callID,
    String? resourceID,
    int timeoutSeconds = 60,
  }) async {
    if (!_isUserLoggedIn.value) {
      log('[ZegoCallService] Cannot send call - user not logged in');
      return ZegoCallInvitationResult.failed(
        message: 'Not logged in to call service',
      );
    }

    try {
      log('[ZegoCallService] Sending ${isVideoCall ? "video" : "audio"} call to $calleeId (room: $callID)');

      // ── Pre-Send State Check ──
      ZegoSignalingPluginConnectionState signalingState;
      try {
        signalingState = ZegoUIKit().getSignalingPlugin().getConnectionState();
        final localUser = ZegoUIKit().getLocalUser();
        log('[ZegoCallService] Pre-send: signaling=$signalingState, '
            'localUser="${localUser.id}"');

        if (localUser.id.isEmpty) {
          log('[ZegoCallService] ⚠️ Local user ID empty — invitation will fail');
          return ZegoCallInvitationResult.failed(
            message: 'Call service not ready. Please restart the app.',
          );
        }
      } catch (e) {
        log('[ZegoCallService] Failed to get pre-send state: $e');
        signalingState = ZegoSignalingPluginConnectionState.disconnected;
      }

      // Wait for signaling to connect if it's still connecting
      if (signalingState != ZegoSignalingPluginConnectionState.connected) {
        log('[ZegoCallService] Signaling not connected ($signalingState), waiting up to 5s...');
        final connected = await _waitForSignalingConnection(
          timeout: const Duration(seconds: 5),
        );
        if (!connected) {
          final finalState =
              ZegoUIKit().getSignalingPlugin().getConnectionState();
          log('[ZegoCallService] ❌ ZIM not connected after 5s (state: $finalState)');
          return ZegoCallInvitationResult.failed(
            message: 'Call service not connected. Check your internet.',
          );
        }
        log('[ZegoCallService] Signaling connected after wait');
      }

      // ── Listen for ZIM errors during send ──
      // The SDK's send() swallows error details into a boolean.
      // Capture the actual ZIM error from the signaling error stream.
      int? capturedErrorCode;
      String? capturedErrorMessage;
      StreamSubscription<ZegoSignalingError>? errorSub;
      try {
        errorSub = ZegoUIKit()
            .getSignalingPlugin()
            .getErrorStream()
            .listen((error) {
          capturedErrorCode = error.code;
          capturedErrorMessage = error.message;
          log('[ZegoCallService] ⚠️ ZIM error: code=${error.code}, '
              'message=${error.message}');
        });
      } catch (e) {
        log('[ZegoCallService] Could not listen to error stream: $e');
      }

      final invitees = [ZegoCallUser(calleeId, calleeName)];
      _currentCallInvitees = invitees;

      final result = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: invitees,
        isVideoCall: isVideoCall,
        callID: callID ?? '',
        resourceID: resourceID ?? 'zego_data',
        timeoutSeconds: timeoutSeconds,
        customData: '${isVideoCall ? "video" : "audio"}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Give error stream a moment to deliver any queued errors
      await Future.delayed(const Duration(milliseconds: 300));
      await errorSub?.cancel();

      if (!result) {
        _currentCallInvitees = null;

        // Parse inner ZIM error code from wrapper message if present
        // Example: "callInvite failed with code: 107026, message: ..."
        int? innerCode = capturedErrorCode;
        if (capturedErrorMessage != null &&
            capturedErrorMessage!.contains('code: ')) {
          final match = RegExp(r'code:\s*(\d+)')
              .firstMatch(capturedErrorMessage!);
          if (match != null) {
            innerCode = int.tryParse(match.group(1)!);
          }
        }

        log('[ZegoCallService] ❌ Invitation failed '
            '(zimCode: $capturedErrorCode, innerCode: $innerCode)');

        return ZegoCallInvitationResult.failed(
          code: innerCode ?? capturedErrorCode,
          message: capturedErrorMessage,
        );
      }

      log('[ZegoCallService] ✅ Call invitation sent successfully');
      return ZegoCallInvitationResult.ok();
    } catch (e, stackTrace) {
      log('[ZegoCallService] Failed to send call invitation: $e');
      log('[ZegoCallService] Stack trace: $stackTrace');
      return ZegoCallInvitationResult.failed(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Cancel the current outgoing call invitation.
  Future<void> cancelCallInvitation() async {
    if (_currentCallInvitees == null || _currentCallInvitees!.isEmpty) {
      log('[ZegoCallService] No active call invitations to cancel');
      return;
    }

    try {
      await ZegoUIKitPrebuiltCallInvitationService().cancel(
        callees: _currentCallInvitees!,
      );
      _currentCallInvitees = null;
      log('[ZegoCallService] Call invitation cancelled');
    } catch (e) {
      log('[ZegoCallService] Error cancelling call: $e');
    }
  }

  /// Wait for ZIM signaling to reach connected state.
  ///
  /// Returns true if connected within [timeout], false otherwise.
  /// Polls every 200ms to check the connection state.
  Future<bool> _waitForSignalingConnection({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final state = ZegoUIKit().getSignalingPlugin().getConnectionState();
        if (state == ZegoSignalingPluginConnectionState.connected) {
          return true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  /// Get call configuration for 1-on-1 calls.
  ZegoUIKitPrebuiltCallConfig getOneOnOneCallConfig(bool isVideoCall) {
    return ZegoCallConfig.getOneOnOneConfig(isVideoCall);
  }

  /// Get call configuration for group calls.
  ZegoUIKitPrebuiltCallConfig getGroupCallConfig(bool isVideoCall) {
    return ZegoCallConfig.getGroupConfig(isVideoCall);
  }

  /// Check if user is in China region (for MIIT compliance).
  bool _isUserInChina() {
    try {
      final locale = Platform.localeName.toLowerCase();

      // Check for Chinese locales (zh_CN, zh_Hans_CN, etc.)
      if (locale.contains('_cn') || locale.contains('-cn')) {
        return true;
      }

      // Also check the language code for simplified Chinese in mainland China context
      if (locale.startsWith('zh_hans') &&
          !locale.contains('_hk') &&
          !locale.contains('_tw')) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cleanup resources when service is disposed.
  @override
  void onClose() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    logoutUser();
    super.onClose();
  }
}

/// Extension methods for CallModel integration with ZegoCallService.
extension CallModelZegoExtension on CallModel {
  /// Create a ZegoCallUser from callee information.
  ZegoCallUser toZegoCalleeUser() {
    return ZegoCallUser(calleeId ?? '', calleeUserName ?? '');
  }

  /// Create a ZegoCallUser from caller information.
  ZegoCallUser toZegoCallerUser() {
    return ZegoCallUser(callerId ?? '', callerUserName ?? '');
  }

  /// Check if this is a video call.
  bool get isVideoCall => callType == CallType.video;
}

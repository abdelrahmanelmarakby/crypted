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
  /// Returns true if invitation was sent successfully.
  Future<bool> sendCallInvitation({
    required String calleeId,
    required String calleeName,
    required bool isVideoCall,
    String? resourceID,
    int timeoutSeconds = 60,
  }) async {
    if (!_isUserLoggedIn.value) {
      log('[ZegoCallService] Cannot send call - user not logged in');
      return false;
    }

    try {
      log('[ZegoCallService] Sending ${isVideoCall ? "video" : "audio"} call to $calleeId');

      final invitees = [ZegoCallUser(calleeId, calleeName)];
      _currentCallInvitees = invitees; // Store for potential cancellation

      final result = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: invitees,
        isVideoCall: isVideoCall,
        resourceID: resourceID ?? 'zego_data',
        timeoutSeconds: timeoutSeconds,
        customData: '${isVideoCall ? "video" : "audio"}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!result) {
        _currentCallInvitees = null;
      }

      log('[ZegoCallService] Call invitation sent: $result');
      return result;
    } catch (e) {
      log('[ZegoCallService] Failed to send call invitation: $e');
      return false;
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

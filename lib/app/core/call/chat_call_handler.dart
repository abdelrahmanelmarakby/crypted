import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:crypted_app/app/core/services/zego/zego_call_service.dart';

/// Result of a call operation.
class CallResult {
  final bool success;
  final String? error;
  final CallModel? callModel;
  final String? callId;

  const CallResult({
    required this.success,
    this.error,
    this.callModel,
    this.callId,
  });

  factory CallResult.success(CallModel model, {String? callId}) => CallResult(
        success: true,
        callModel: model,
        callId: callId,
      );

  factory CallResult.failure(String error) => CallResult(
        success: false,
        error: error,
      );
}

/// Service to handle call operations for chat screens.
///
/// This handler manages:
/// - Initiating audio/video calls
/// - Storing call records in Firestore
/// - Sending call messages in chat
/// - Navigating to call screen
class ChatCallHandler {
  final CallDataSources _callDataSource;
  final String roomId;
  final Future<void> Function(Message message) sendMessage;

  ChatCallHandler({
    required this.roomId,
    required this.sendMessage,
    CallDataSources? callDataSource,
  }) : _callDataSource = callDataSource ?? CallDataSources();

  /// Initiate an audio call.
  Future<CallResult> initiateAudioCall(SocialMediaUser otherUser) async {
    return _initiateCall(otherUser, isVideoCall: false);
  }

  /// Initiate a video call.
  Future<CallResult> initiateVideoCall(SocialMediaUser otherUser) async {
    return _initiateCall(otherUser, isVideoCall: true);
  }

  /// Internal method to initiate a call.
  Future<CallResult> _initiateCall(
    SocialMediaUser otherUser, {
    required bool isVideoCall,
  }) async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      // Validate current user
      final currentUser = UserService.currentUser.value;
      if (currentUser == null) {
        return CallResult.failure('User not authenticated');
      }

      // Validate callee
      if (otherUser.uid == null || otherUser.uid!.isEmpty) {
        return CallResult.failure('Invalid recipient');
      }

      log('[ChatCallHandler] Initiating ${isVideoCall ? "video" : "audio"} call to ${otherUser.uid}');

      // Check if user is already in a call
      final isInCall = await _callDataSource.isUserInActiveCall(currentUser.uid ?? '');
      if (isInCall) {
        _showError('You are already in a call');
        return CallResult.failure('Already in a call');
      }

      // Create call model
      final callModel = CallModel(
        callType: isVideoCall ? CallType.video : CallType.audio,
        callStatus: CallStatus.outgoing,
        calleeId: otherUser.uid ?? '',
        calleeImage: otherUser.imageUrl ?? '',
        calleeUserName: otherUser.fullName ?? '',
        callerId: currentUser.uid ?? '',
        callerImage: currentUser.imageUrl ?? '',
        callerUserName: currentUser.fullName ?? '',
        time: DateTime.now(),
      );

      // Store call in Firestore and get the ID
      final callId = await _callDataSource.storeCall(callModel);

      if (callId == null) {
        _showError('Failed to create call record');
        return CallResult.failure('Failed to create call record');
      }

      // Update call model with the generated ID
      final callWithId = callModel.copyWith(callId: callId);

      // Send call message in chat
      await _sendCallMessage(callWithId);

      // Send ZEGO call invitation (for push notification).
      // Pass the Firestore callId as the ZEGO room ID so both parties
      // join the same room when the callee accepts the invitation.
      final invitationResult = await ZegoCallService.instance.sendCallInvitation(
        calleeId: otherUser.uid ?? '',
        calleeName: otherUser.fullName ?? '',
        isVideoCall: isVideoCall,
        callID: callId,
        resourceID: 'zego_data',
      );

      if (invitationResult.success) {
        // Invitation succeeded — ZegoUIKitPrebuiltCallInvitationService
        // handles the outgoing call UI and room joining automatically.
        // Do NOT navigate to a custom CallScreen (avoids engine conflict).
        log('[ChatCallHandler] ZEGO invitation sent — invitation service handles UI');
      } else {
        // Invitation failed — show the specific error from ZIM.
        // Do NOT fall back to CallScreen — ZegoUIKitPrebuiltCall conflicts with the
        // invitation service's Express Engine and causes error 1001004 (LoginFailed).
        log('[ChatCallHandler] ZEGO invitation failed: '
            'code=${invitationResult.errorCode}, '
            'msg=${invitationResult.errorMessage}');
        _showError(invitationResult.userFacingMessage);

        // Mark call as cancelled since invitation couldn't be sent
        try {
          await _callDataSource.markCallAsCancelled(callId);
        } catch (e) {
          log('[ChatCallHandler] Failed to cancel call record: $e');
        }
      }

      // Refresh calls list
      _refreshCallsList();

      return CallResult.success(callWithId, callId: callId);
    } catch (e, stackTrace) {
      log('[ChatCallHandler] Error initiating call: $e');
      log('[ChatCallHandler] Stack trace: $stackTrace');

      final errorMessage =
          'Failed to start ${isVideoCall ? "video" : "audio"} call';
      _showError(errorMessage);
      return CallResult.failure('$errorMessage: ${e.toString()}');
    }
  }

  /// Send a call message in the chat.
  Future<void> _sendCallMessage(CallModel callModel) async {
    try {
      final callMessage = CallMessage(
        id: 'call_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        senderId: UserService.currentUser.value?.uid ?? '',
        timestamp: DateTime.now(),
        callModel: callModel,
      );

      await sendMessage(callMessage);
      log('[ChatCallHandler] Call message sent in chat');
    } catch (e) {
      log('[ChatCallHandler] Error sending call message: $e');
      // Don't throw - call can proceed even if message fails
    }
  }

  /// Refresh calls list in CallsController if available.
  void _refreshCallsList() {
    try {
      if (Get.isRegistered<CallsController>()) {
        Get.find<CallsController>().refreshCalls();
      }
    } catch (e) {
      log('[ChatCallHandler] Could not refresh calls list: $e');
    }
  }

  /// Show error snackbar.
  void _showError(String message) {
    Get.snackbar(
      'Call Error',
      message,
      backgroundColor: ColorsManager.error,
      colorText: ColorsManager.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}

/// Mixin to add call handling capabilities to GetX controllers.
///
/// Usage:
/// ```dart
/// class ChatController extends GetxController with CallHandlerMixin {
///   @override
///   void onInit() {
///     super.onInit();
///     initializeCallHandler(
///       roomId: 'room_123',
///       sendMessage: (message) async {
///         // Send message logic
///       },
///     );
///   }
///
///   void makeAudioCall(SocialMediaUser user) {
///     startAudioCall(user);
///   }
///
///   @override
///   void onClose() {
///     disposeCallHandler();
///     super.onClose();
///   }
/// }
/// ```
mixin CallHandlerMixin {
  ChatCallHandler? _callHandler;

  /// Initialize call handler.
  void initializeCallHandler({
    required String roomId,
    required Future<void> Function(Message message) sendMessage,
  }) {
    _callHandler = ChatCallHandler(
      roomId: roomId,
      sendMessage: sendMessage,
    );
  }

  /// Dispose call handler.
  void disposeCallHandler() {
    _callHandler = null;
  }

  /// Initiate audio call.
  Future<CallResult> startAudioCall(SocialMediaUser otherUser) async {
    if (_callHandler == null) {
      return CallResult.failure('Call handler not initialized');
    }
    return _callHandler!.initiateAudioCall(otherUser);
  }

  /// Initiate video call.
  Future<CallResult> startVideoCall(SocialMediaUser otherUser) async {
    if (_callHandler == null) {
      return CallResult.failure('Call handler not initialized');
    }
    return _callHandler!.initiateVideoCall(otherUser);
  }

  /// Check if call handler is initialized.
  bool get isCallHandlerReady => _callHandler != null;
}

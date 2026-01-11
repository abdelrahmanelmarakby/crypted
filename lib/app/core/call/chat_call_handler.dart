// ARCH-008 FIX: Call Handler Service
// Moves call logic from view to a dedicated service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Result of a call operation
class CallResult {
  final bool success;
  final String? error;
  final CallModel? callModel;

  const CallResult({
    required this.success,
    this.error,
    this.callModel,
  });

  factory CallResult.success(CallModel model) => CallResult(
        success: true,
        callModel: model,
      );

  factory CallResult.failure(String error) => CallResult(
        success: false,
        error: error,
      );
}

/// Service to handle call operations for chat
class ChatCallHandler {
  final CallDataSources _callDataSource;
  final String roomId;
  final Future<void> Function(Message message) sendMessage;

  ChatCallHandler({
    required this.roomId,
    required this.sendMessage,
    CallDataSources? callDataSource,
  }) : _callDataSource = callDataSource ?? CallDataSources();

  /// Initiate an audio call
  Future<CallResult> initiateAudioCall(SocialMediaUser otherUser) async {
    return _initiateCall(otherUser, isVideoCall: false);
  }

  /// Initiate a video call
  Future<CallResult> initiateVideoCall(SocialMediaUser otherUser) async {
    return _initiateCall(otherUser, isVideoCall: true);
  }

  /// Internal method to initiate a call
  Future<CallResult> _initiateCall(
    SocialMediaUser otherUser, {
    required bool isVideoCall,
  }) async {
    HapticFeedback.lightImpact();

    try {
      final currentUser = UserService.currentUser.value;
      if (currentUser == null) {
        return CallResult.failure('User not authenticated');
      }

      if (otherUser.uid == null || otherUser.uid!.isEmpty) {
        return CallResult.failure('Invalid recipient');
      }

      // Send call invitation
      final invitationSuccess = await _callDataSource.sendCallInvitation(
        callerId: currentUser.uid ?? '',
        callerName: currentUser.fullName ?? '',
        calleeId: otherUser.uid ?? '',
        calleeName: otherUser.fullName ?? '',
        isVideoCall: isVideoCall,
        customData:
            '${isVideoCall ? "video" : "audio"}_call_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!invitationSuccess) {
        _showError('Failed to send call invitation');
        return CallResult.failure('Failed to send call invitation');
      }

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

      // Store call data and send message
      await _storeCallAndSendMessage(callModel);

      // Navigate to call screen
      Get.toNamed('/call', arguments: callModel);

      return CallResult.success(callModel);
    } catch (e) {
      final errorMessage =
          'Failed to start ${isVideoCall ? "video" : "audio"} call: ${e.toString()}';
      _showError(errorMessage);
      return CallResult.failure(errorMessage);
    }
  }

  /// Store call data and send call message
  Future<void> _storeCallAndSendMessage(CallModel callModel) async {
    try {
      final success = await _callDataSource.storeCall(callModel);

      if (success) {
        // Send call message to chat
        await sendMessage(CallMessage(
          id: '${Timestamp.now().toDate()}',
          roomId: roomId,
          senderId: UserService.currentUser.value?.uid ?? '',
          timestamp: Timestamp.now().toDate(),
          callModel: callModel,
        ));

        // Refresh calls list
        _refreshCallsList();
      }
    } catch (e) {
      print('❌ Error handling call: $e');
      rethrow;
    }
  }

  /// Refresh calls list in CallsController if available
  void _refreshCallsList() {
    try {
      if (Get.isRegistered<CallsController>()) {
        Get.find<CallsController>().refreshCalls();
      }
    } catch (e) {
      print('[ChatCallHandler] Could not refresh calls list: $e');
    }
  }

  /// Show error snackbar
  void _showError(String message) {
    Get.snackbar(
      'Call Error',
      message,
      backgroundColor: ColorsManager.error,
      colorText: ColorsManager.white,
    );
  }
}

/// Mixin to add call handling capabilities to controllers
mixin CallHandlerMixin {
  ChatCallHandler? _callHandler;

  /// Initialize call handler
  void initializeCallHandler({
    required String roomId,
    required Future<void> Function(Message message) sendMessage,
  }) {
    _callHandler = ChatCallHandler(
      roomId: roomId,
      sendMessage: sendMessage,
    );
  }

  /// Dispose call handler
  void disposeCallHandler() {
    _callHandler = null;
  }

  /// Initiate audio call
  Future<CallResult> startAudioCall(SocialMediaUser otherUser) async {
    if (_callHandler == null) {
      return CallResult.failure('Call handler not initialized');
    }
    return _callHandler!.initiateAudioCall(otherUser);
  }

  /// Initiate video call
  Future<CallResult> startVideoCall(SocialMediaUser otherUser) async {
    if (_callHandler == null) {
      return CallResult.failure('Call handler not initialized');
    }
    return _callHandler!.initiateVideoCall(otherUser);
  }
}

// ARCH-008 FIX: Call Handler Service
// Extracted call handling business logic from chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/calls/controllers/calls_controller.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Result of a call initiation attempt
class CallResult {
  final bool success;
  final CallModel? callModel;
  final CallMessage? callMessage;
  final String? errorMessage;

  CallResult.success({
    required this.callModel,
    required this.callMessage,
  })  : success = true,
        errorMessage = null;

  CallResult.failure(this.errorMessage)
      : success = false,
        callModel = null,
        callMessage = null;
}

/// Service for handling call operations
/// Extracted from ChatScreen view for better separation of concerns
class CallHandlerService {
  final CallDataSources _callDataSource;
  final ErrorHandler _errorHandler;

  CallHandlerService({
    CallDataSources? callDataSource,
    ErrorHandler? errorHandler,
  })  : _callDataSource = callDataSource ?? CallDataSources(),
        _errorHandler = errorHandler ?? ErrorHandler();

  /// Start an audio call
  Future<CallResult> startAudioCall({
    required SocialMediaUser otherUser,
    required String roomId,
    required Future<void> Function(Message) sendMessage,
  }) async {
    return _startCall(
      otherUser: otherUser,
      roomId: roomId,
      isVideoCall: false,
      sendMessage: sendMessage,
    );
  }

  /// Start a video call
  Future<CallResult> startVideoCall({
    required SocialMediaUser otherUser,
    required String roomId,
    required Future<void> Function(Message) sendMessage,
  }) async {
    return _startCall(
      otherUser: otherUser,
      roomId: roomId,
      isVideoCall: true,
      sendMessage: sendMessage,
    );
  }

  /// Internal method to start a call
  Future<CallResult> _startCall({
    required SocialMediaUser otherUser,
    required String roomId,
    required bool isVideoCall,
    required Future<void> Function(Message) sendMessage,
  }) async {
    HapticFeedback.lightImpact();

    try {
      final currentUser = UserService.currentUser.value;
      if (currentUser == null) {
        return CallResult.failure('User not logged in');
      }

      // Validate other user data
      if (otherUser.uid == null || otherUser.uid!.isEmpty) {
        return CallResult.failure('Invalid recipient');
      }

      // Send call invitation via Zego/FCM
      final callType = isVideoCall ? 'video' : 'audio';
      final invitationSuccess = await _callDataSource.sendCallInvitation(
        callerId: currentUser.uid ?? "",
        callerName: currentUser.fullName ?? "",
        calleeId: otherUser.uid ?? "",
        calleeName: otherUser.fullName ?? "",
        isVideoCall: isVideoCall,
        customData: "${callType}_call_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!invitationSuccess) {
        return CallResult.failure('Failed to send call invitation');
      }

      // Create call model
      final callModel = CallModel(
        callType: isVideoCall ? CallType.video : CallType.audio,
        callStatus: CallStatus.outgoing,
        calleeId: otherUser.uid ?? "",
        calleeImage: otherUser.imageUrl ?? "",
        calleeUserName: otherUser.fullName ?? "",
        callerId: currentUser.uid ?? "",
        callerImage: currentUser.imageUrl ?? "",
        callerUserName: currentUser.fullName ?? "",
        time: DateTime.now(),
      );

      // Store call in database
      final storeSuccess = await _callDataSource.storeCall(callModel);
      if (!storeSuccess) {
        return CallResult.failure('Failed to store call record');
      }

      // Create and send call message
      final callMessage = CallMessage(
        id: "${Timestamp.now().toDate()}",
        roomId: roomId,
        senderId: currentUser.uid ?? "",
        timestamp: Timestamp.now().toDate(),
        callModel: callModel,
      );

      await sendMessage(callMessage);

      // Refresh calls list
      _refreshCallsList();

      return CallResult.success(
        callModel: callModel,
        callMessage: callMessage,
      );
    } catch (e) {
      _errorHandler.handle(e, context: 'CallHandlerService._startCall');
      return CallResult.failure(e.toString());
    }
  }

  /// Navigate to call screen
  void navigateToCallScreen(CallModel callModel) {
    Get.toNamed('/call', arguments: callModel);
  }

  /// Start call and navigate to call screen
  Future<bool> startCallAndNavigate({
    required SocialMediaUser otherUser,
    required String roomId,
    required bool isVideoCall,
    required Future<void> Function(Message) sendMessage,
  }) async {
    final result = isVideoCall
        ? await startVideoCall(
            otherUser: otherUser,
            roomId: roomId,
            sendMessage: sendMessage,
          )
        : await startAudioCall(
            otherUser: otherUser,
            roomId: roomId,
            sendMessage: sendMessage,
          );

    if (result.success && result.callModel != null) {
      navigateToCallScreen(result.callModel!);
      return true;
    } else {
      _errorHandler.showWarning(result.errorMessage ?? 'Failed to start call');
      return false;
    }
  }

  void _refreshCallsList() {
    try {
      if (Get.isRegistered<CallsController>()) {
        Get.find<CallsController>().refreshCalls();
      }
    } catch (e) {
      // Silently ignore if controller not found
    }
  }
}

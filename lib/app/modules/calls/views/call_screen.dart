import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CallModel callModel = Get.arguments as CallModel;

    // Generate unique call ID if not provided
    final String callID = callModel.callId ?? '${callModel.callerId}_${callModel.calleeId}_${DateTime.now().millisecondsSinceEpoch}';

    return ZegoUIKitPrebuiltCall(
      appID: AppConstants.appID,
      appSign: AppConstants.appSign,
      userID: callModel.callerId ?? '',
      userName: callModel.callerUserName ?? '',
      callID: callID,
      config: (callModel.callType == CallType.video)
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}

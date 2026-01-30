/// ZEGO Cloud services for audio/video calls.
///
/// This module provides a clean abstraction over the ZEGO UIKit SDK
/// for implementing voice and video calling features.
///
/// Usage:
/// ```dart
/// // In main.dart (before runApp)
/// await ZegoCallService().initializeSDK(navigatorKey);
///
/// // After user login
/// await ZegoCallService.instance.loginUser(
///   userId: user.uid,
///   userName: user.name,
/// );
///
/// // To make a call
/// await ZegoCallService.instance.sendCallInvitation(
///   calleeId: otherUser.uid,
///   calleeName: otherUser.name,
///   isVideoCall: true,
/// );
///
/// // On logout
/// await ZegoCallService.instance.logoutUser();
/// ```
library;

export 'zego_call_service.dart';
export 'zego_call_config.dart';
export 'zego_token_generator.dart';

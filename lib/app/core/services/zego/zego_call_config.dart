import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

/// Configuration factory for ZEGO call presets.
///
/// Provides customized call configurations for different call types:
/// - One-on-one audio calls
/// - One-on-one video calls
/// - Group audio calls
/// - Group video calls
class ZegoCallConfig {
  ZegoCallConfig._();

  /// Get configuration for 1-on-1 calls.
  static ZegoUIKitPrebuiltCallConfig getOneOnOneConfig(bool isVideoCall) {
    final config = isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    return _applyCommonConfig(config, isVideoCall);
  }

  /// Get configuration for group calls.
  static ZegoUIKitPrebuiltCallConfig getGroupConfig(bool isVideoCall) {
    final config = isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        : ZegoUIKitPrebuiltCallConfig.groupVoiceCall();

    return _applyCommonConfig(config, isVideoCall);
  }

  /// Apply common configuration to all call types.
  static ZegoUIKitPrebuiltCallConfig _applyCommonConfig(
    ZegoUIKitPrebuiltCallConfig config,
    bool isVideoCall,
  ) {
    // Duration configuration
    config.duration = ZegoCallDurationConfig(
      isVisible: true,
      onDurationUpdate: (Duration duration) {
        // Duration updates can be handled here if needed
      },
    );

    // Top menu bar configuration
    config.topMenuBar = ZegoCallTopMenuBarConfig(
      isVisible: true,
      buttons: [
        ZegoCallMenuBarButtonName.minimizingButton,
        ZegoCallMenuBarButtonName.showMemberListButton,
        ZegoCallMenuBarButtonName.pipButton, 
      ],
      style: ZegoCallMenuBarStyle.dark,
    );

    // Bottom menu bar configuration
    config.bottomMenuBar = ZegoCallBottomMenuBarConfig(
      buttons: isVideoCall
          ? [
              ZegoCallMenuBarButtonName.toggleCameraButton,
              ZegoCallMenuBarButtonName.switchCameraButton,
              ZegoCallMenuBarButtonName.hangUpButton,
              ZegoCallMenuBarButtonName.toggleMicrophoneButton,
              ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ]
          : [
              ZegoCallMenuBarButtonName.toggleMicrophoneButton,
              ZegoCallMenuBarButtonName.hangUpButton,
              ZegoCallMenuBarButtonName.switchAudioOutputButton,
            ],
      style: ZegoCallMenuBarStyle.dark,
      
      hideAutomatically: false,
    );

    // Audio/Video configuration
    config.audioVideoView = ZegoCallAudioVideoViewConfig(
      showMicrophoneStateOnView: true,
      showCameraStateOnView: isVideoCall,
      showUserNameOnView: true,
      useVideoViewAspectFill: true,
      showAvatarInAudioMode: true,
      showSoundWavesInAudioMode: true,
    );

    // Layout configuration is set by the preset configs

    return config;
  }

  /// Get call invitation UI configuration.
  static ZegoCallInvitationUIConfig getInvitationUIConfig() {
    return ZegoCallInvitationUIConfig(
      // Additional UI configuration can be added here
    );
  }
}

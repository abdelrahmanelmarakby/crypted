import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'package:crypted_app/core/themes/color_manager.dart';

/// A customizable button for sending call invitations using ZEGO.
///
/// This widget wraps [ZegoSendCallInvitationButton] with custom styling
/// to match the app's design language.
///
/// Usage:
/// ```dart
/// CallInvitationButton(
///   calleeId: user.uid,
///   calleeName: user.fullName,
///   isVideoCall: true,
/// )
/// ```
class CallInvitationButton extends StatelessWidget {
  /// The ID of the user to call.
  final String calleeId;

  /// The display name of the user to call.
  final String calleeName;

  /// Whether this is a video call (true) or audio call (false).
  final bool isVideoCall;

  /// Optional callback when call invitation is sent.
  final VoidCallback? onPressed;

  /// Custom icon widget.
  final Widget? icon;

  /// Button size.
  final double size;

  /// Resource ID for push notifications (created in ZEGO console).
  final String? resourceID;

  /// Timeout in seconds for the call invitation.
  final int timeoutSeconds;

  /// Custom data to send with the invitation.
  final String? customData;

  const CallInvitationButton({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.isVideoCall,
    this.onPressed,
    this.icon,
    this.size = 40,
    this.resourceID,
    this.timeoutSeconds = 60,
    this.customData,
  });

  @override
  Widget build(BuildContext context) {
    return ZegoSendCallInvitationButton(
      isVideoCall: isVideoCall,
      invitees: [
        ZegoUIKitUser(id: calleeId, name: calleeName),
      ],
      resourceID: resourceID ?? 'zego_data',
      timeoutSeconds: timeoutSeconds,
      customData: customData ?? '',
      iconSize: Size(size, size),
      buttonSize: Size(size, size),
      icon: icon != null
          ? ButtonIcon(icon: icon)
          : ButtonIcon(
              icon: Icon(
                isVideoCall ? Icons.videocam : Icons.call,
                color: ColorsManager.primary,
                size: size * 0.6,
              ),
            ),
      onWillPressed: () async {
        onPressed?.call();
        return true;
      },
      onPressed: (code, message, userIds) {
        if (code.isNotEmpty) {
          // Error occurred
          debugPrint('[CallInvitationButton] Error: $code - $message');
        } else {
          debugPrint('[CallInvitationButton] Invitation sent to: ${userIds.join(", ")}');
        }
      },
    );
  }
}

/// A row of call buttons (audio and video) for chat headers.
class CallButtonsRow extends StatelessWidget {
  /// The ID of the user to call.
  final String calleeId;

  /// The display name of the user to call.
  final String calleeName;

  /// Optional callback when audio call button is pressed.
  final VoidCallback? onAudioCallPressed;

  /// Optional callback when video call button is pressed.
  final VoidCallback? onVideoCallPressed;

  /// Button size.
  final double buttonSize;

  /// Spacing between buttons.
  final double spacing;

  const CallButtonsRow({
    super.key,
    required this.calleeId,
    required this.calleeName,
    this.onAudioCallPressed,
    this.onVideoCallPressed,
    this.buttonSize = 36,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio call button
        CallInvitationButton(
          calleeId: calleeId,
          calleeName: calleeName,
          isVideoCall: false,
          size: buttonSize,
          onPressed: onAudioCallPressed,
          icon: Icon(
            Icons.call,
            color: ColorsManager.primary,
            size: buttonSize * 0.6,
          ),
        ),
        SizedBox(width: spacing),
        // Video call button
        CallInvitationButton(
          calleeId: calleeId,
          calleeName: calleeName,
          isVideoCall: true,
          size: buttonSize,
          onPressed: onVideoCallPressed,
          icon: Icon(
            Icons.videocam,
            color: ColorsManager.primary,
            size: buttonSize * 0.6,
          ),
        ),
      ],
    );
  }
}

/// Circular call button with custom styling.
class CircularCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const CircularCallButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor = ColorsManager.primary,
    this.iconColor = Colors.white,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// End call button with red background.
class EndCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const EndCallButton({
    super.key,
    required this.onPressed,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return CircularCallButton(
      onPressed: onPressed,
      icon: Icons.call_end,
      backgroundColor: Colors.red,
      iconColor: Colors.white,
      size: size,
    );
  }
}

/// Accept call button with green background.
class AcceptCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isVideoCall;
  final double size;

  const AcceptCallButton({
    super.key,
    required this.onPressed,
    this.isVideoCall = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return CircularCallButton(
      onPressed: onPressed,
      icon: isVideoCall ? Icons.videocam : Icons.call,
      backgroundColor: ColorsManager.primary,
      iconColor: Colors.white,
      size: size,
    );
  }
}

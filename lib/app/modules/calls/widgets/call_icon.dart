import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';

class CallIcon extends StatelessWidget {
  const CallIcon({super.key, required this.callModel});
  final CallModel callModel;

  @override
  Widget build(BuildContext context) {
    IconData? iconData;
    Color? backgroundColor;

    switch (callModel.callStatus) {
      case CallStatus.missed:
        iconData = Icons.call_missed;
        backgroundColor = Colors.red;
        break;
      case CallStatus.incoming:
        iconData = Icons.call_received;
        backgroundColor = ColorsManager.primary;
        break;
      case CallStatus.outgoing:
        iconData = Icons.call_made;
        backgroundColor = ColorsManager.primary;
        break;
      default:
        return const SizedBox();
    }

    return CircleAvatar(
      backgroundColor: ColorsManager.white,
      radius: Radiuss.small,
      child: CircleAvatar(
        backgroundColor: backgroundColor,
        radius: Radiuss.xSmall,
        child: Icon(iconData, color: ColorsManager.white, size: Sizes.size12),
      ),
    );
  }
}

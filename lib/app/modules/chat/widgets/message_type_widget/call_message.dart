import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:intl/intl.dart';
import 'package:crypted_app/app/data/models/call_model.dart';

class CallMessageWidget extends StatelessWidget {
  const CallMessageWidget({super.key, required this.message});

  final CallMessage message;

  @override
  Widget build(BuildContext context) {
    final call = message.callModel;
    final isOutgoing = call.callStatus == CallStatus.outgoing;
    final isMissed = call.callStatus == CallStatus.missed;
    final isVideo = call.callType == CallType.video;
    final participantName =
        (isOutgoing ? call.calleeUserName : call.callerUserName) ?? '';
    final participantImage =
        (isOutgoing ? call.calleeImage : call.callerImage) ?? '';
    final time = DateFormat('hh:mm a').format(message.timestamp);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isMissed) {
      statusColor = ColorsManager.red;
      statusIcon = Icons.call_missed;
      statusText = 'Missed';
    } else if (isOutgoing) {
      statusColor = ColorsManager.blue;
      statusIcon = Icons.call_made;
      statusText = 'Outgoing';
    } else {
      statusColor = ColorsManager.primary;
      statusIcon = Icons.call_received;
      statusText = 'Incoming';
    }

    return Container(
      height: Sizes.size100,
      width: Sizes.size200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radiuss.normal),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar
          CircleAvatar(
            radius: Radiuss.xXLarge29,
            backgroundImage: participantImage.isNotEmpty
                ? NetworkImage(participantImage)
                : null,
            backgroundColor: ColorsManager.white,
            child: participantImage.isEmpty
                ? Icon(Icons.person,
                    size: Sizes.size32, color: ColorsManager.grey)
                : null,
          ),
          const SizedBox(width: Sizes.size12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  participantName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Sizes.size4),
                Row(
                  children: [
                    Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      size: Sizes.size18,
                      color: ColorsManager.primary,
                    ),
                    const SizedBox(width: Sizes.size4),
                    Text(
                      isVideo ? 'Video Call' : 'Audio Call',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: Sizes.size4),
                Row(
                  children: [
                    Icon(statusIcon, size: Sizes.size16, color: statusColor),
                    const SizedBox(width: Sizes.size4),
                    Text(
                      statusText,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time
          // Flexible(
          //   fit: FlexFit.loose,
          //   child: Column(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text(
          //         time,
          //         style: Theme.of(context)
          //             .textTheme
          //             .bodySmall
          //             ?.copyWith(color: ColorsManager.grey),
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

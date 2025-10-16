import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/calls/widgets/call_icon.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class ItemOutSideCall extends StatelessWidget {
  const ItemOutSideCall({super.key, required this.callModel});

  final CallModel callModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Paddings.small),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: callModel.calleeImage != null &&
                            callModel.calleeImage.toString().isNotEmpty
                        ? NetworkImage(callModel.calleeImage.toString())
                        : null,
                    radius: Radiuss.xXLarge,
                    child: (callModel.calleeImage == null ||
                            callModel.calleeImage.toString().isEmpty)
                        ? Icon(Icons.person, size: Radiuss.xXLarge)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CallIcon(callModel: callModel),
                  ),
                ],
              ),
              SizedBox(width: Sizes.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      callModel.calleeUserName.toString(),
                      style: StylesManager.regular(fontSize: FontSize.small),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Sizes.size4),
                    Text(
                      callModel.callStatus.toString(),
                      style: StylesManager.medium(fontSize: FontSize.xSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Sizes.size10),
              Text(
                formatCallTime(callModel.time ?? DateTime.now()),
                style: StylesManager.medium(fontSize: FontSize.xXSmall),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String formatCallTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('d MMMM - h:mm a', 'ar').format(time);
    }
  }
}

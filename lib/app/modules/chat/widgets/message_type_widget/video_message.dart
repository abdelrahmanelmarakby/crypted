import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

class VideoMessageWidget extends StatelessWidget {
  const VideoMessageWidget({super.key, required this.message});

  final VideoMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.size200,
      height: Sizes.size150,
      decoration: BoxDecoration(
        color: ColorsManager.lightGrey,
        borderRadius: BorderRadius.circular(Radiuss.normal),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: Sizes.size48,
          color: ColorsManager.grey,
        ),
      ),
    );
  }
}

import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class TextMessageWidget extends StatelessWidget {
  const TextMessageWidget({super.key, required this.message});

  final TextMessage message;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text ?? '',
          style: StylesManager.medium(
            fontSize: FontSize.small,
            color: ColorsManager.black,
          ),
        ),
        if (message.isEdited) ...[
          SizedBox(height: Paddings.xSmall / 2),
          Text(
            'Edited',
            style: StylesManager.regular(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

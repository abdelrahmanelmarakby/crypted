import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class TextMessageWidget extends StatelessWidget {
  const TextMessageWidget({super.key, required this.message});

  final TextMessage message;
  @override
  Widget build(BuildContext context) {
    return Text(
      message.text ?? '',
      style: StylesManager.medium(
        fontSize: FontSize.small,
        color: ColorsManager.black,
      ),
    );
  }
}

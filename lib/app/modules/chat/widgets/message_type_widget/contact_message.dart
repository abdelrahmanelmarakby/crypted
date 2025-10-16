import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';

class ContactMessageWidget extends StatelessWidget {
  const ContactMessageWidget({super.key, required this.message});

  final ContactMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: Sizes.size150,
        height: Sizes.size70,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Radiuss.normal),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                message.name,
                style: StylesManager.bold(
                  color: ColorsManager.primary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                message.phoneNumber,
                style: StylesManager.regular(
                  color: ColorsManager.veryLightGrey,
                ),
              ),
            ],
          ),
        ));
  }
}

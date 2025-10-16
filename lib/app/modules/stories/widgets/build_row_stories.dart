// ignore_for_file: camel_case_types

import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class buildRowStories extends StatelessWidget {
  const buildRowStories({
    super.key,
    required this.imageUser,
    required this.nameUser,
    required this.timeUnread,
  });

  final String imageUser;
  final String nameUser;
  final String timeUnread;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: Radiuss.xLarge23,
                backgroundColor: ColorsManager.grey,
                child: CircleAvatar(
                  radius: Radiuss.xLarge,
                  backgroundColor: ColorsManager.white,
                  child: CircleAvatar(
                    backgroundImage: AssetImage(imageUser),
                    radius: Radiuss.xLarge19,
                    child: const SizedBox(),
                  ),
                ),
              ),
              SizedBox(width: Sizes.size10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameUser,
                    style: StylesManager.medium(fontSize: FontSize.medium),
                  ),
                  Text(
                    timeUnread,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert_outlined),
                onSelected: (value) {
                  if (value == 0) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Muted')));
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radiuss.normal),
                ),
                color: Colors.white,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/fi_8114095.svg',
                          width: Sizes.size20,
                          height: Sizes.size20,
                        ),
                        SizedBox(width: Sizes.size8),
                        Text(
                          'Mute',
                          style: StylesManager.medium(
                            fontSize: FontSize.small,
                          ),
                        ),
                        SizedBox(width: Sizes.size24),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

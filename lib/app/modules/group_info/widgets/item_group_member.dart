import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemGroupMember extends StatelessWidget {
  const ItemGroupMember({
    super.key,
    this.isAdmin = false,
    required this.imageUser,
    required this.userName,
    this.userStatus,
  });
  final bool? isAdmin;
  final String imageUser, userName;
  final String? userStatus;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.normal),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(imageUser),
                radius: Radiuss.xLarge,
                child: SizedBox(),
              ),
            ],
          ),
          SizedBox(width: Sizes.size10),
          SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: StylesManager.regular(fontSize: FontSize.xSmall),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userStatus ?? '',
                  style: StylesManager.medium(
                    fontSize: FontSize.xXSmall,
                    color: ColorsManager.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacer(),
          (isAdmin == true)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Constants.kAdmin.tr,
                      style: StylesManager.medium(
                        fontSize: FontSize.xXSmall,
                        color: ColorsManager.primary,
                      ),
                    ),
                  ],
                )
              : Text(''),
        ],
      ),
    );
  }
}

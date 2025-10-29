import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/item_out_side_chat_model.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import '../controllers/invite_friend_controller.dart';

class ItemInvite extends GetView<InviteFriendController> {
  const ItemInvite({super.key, required this.itemOutSideChatModel});
  final ItemOutSideChatModel itemOutSideChatModel;

  void _inviteContact() {
    controller.inviteContact(itemOutSideChatModel);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Sizes.size10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(itemOutSideChatModel.imageUser),
            radius: Radiuss.xLarge,
          ),
          SizedBox(width: Sizes.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemOutSideChatModel.nameUser,
                  style: StylesManager.medium(fontSize: FontSize.xSmall),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  itemOutSideChatModel.phoneNumber,
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
          SizedBox(width: Sizes.size10),
          // زر الدعوة
          GestureDetector(
            onTap: _inviteContact,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Sizes.size12,
                vertical: Sizes.size8,
              ),
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(Radiuss.normal),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share,
                    color: ColorsManager.white,
                    size: Sizes.size16,
                  ),
                  SizedBox(width: Sizes.size4),
                  Text(
                    'Invite',
                    style: StylesManager.medium(
                      fontSize: FontSize.xXSmall,
                      color: ColorsManager.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

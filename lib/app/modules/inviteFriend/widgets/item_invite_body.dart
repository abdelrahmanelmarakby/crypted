import 'package:crypted_app/app/data/models/item_out_side_chat_model.dart';
import 'package:crypted_app/app/modules/inviteFriend/widgets/item_invite.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/invite_friend_controller.dart';

class ItemInviteBody extends GetView<InviteFriendController> {
  const ItemInviteBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final contacts = controller.contactsToDisplay;

      if (contacts.isEmpty && controller.isSearchActive) {
        // Show no results message when searching and no results found
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: ColorsManager.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No contacts found',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try searching with a different name or phone number',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorsManager.lightGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ItemInvite(itemOutSideChatModel: contacts[index]);
        },
        separatorBuilder: (context, index) =>
            Divider(color: ColorsManager.veryLightGrey, thickness: 0.5),
        itemCount: contacts.length,
      );
    });
  }
}

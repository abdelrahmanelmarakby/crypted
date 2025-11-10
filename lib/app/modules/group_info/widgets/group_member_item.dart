import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_info_controller.dart';

class GroupMemberItem extends GetView<GroupInfoController> {
  final dynamic member;

  const GroupMemberItem({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Paddings.xXSmall,
        horizontal: Paddings.normal,
      ),
      child: Row(
        children: [
          // Member avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorsManager.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: ColorsManager.primary.withOpacity(0.1),
              backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty
                  ? NetworkImage(member.imageUrl!)
                  : null,
              child: member.imageUrl == null || member.imageUrl!.isEmpty
                  ? Text(
                      member.fullName?.substring(0, 1).toUpperCase() ?? '?',
                      style: StylesManager.bold(
                        fontSize: FontSize.medium,
                        color: ColorsManager.primary,
                      ),
                    )
                  : null,
            ),
          ),

          SizedBox(width: Sizes.size4),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName ?? 'Unknown User',
                  style: StylesManager.medium(fontSize: FontSize.medium),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.uid == controller.currentUser?.uid ? 'You' : 'Member',
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),

          // Admin badge for current user
          if (member.uid == controller.currentUser?.uid && controller.isCurrentUserAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Admin',
                style: StylesManager.medium(
                  fontSize: FontSize.xSmall,
                  color: ColorsManager.primary,
                ),
              ),
            ),

          // Remove button for non-admin members (if current user is admin)
          if (member.uid != controller.currentUser?.uid && controller.isCurrentUserAdmin)
            IconButton(
              icon: Icon(Icons.remove_circle, color: ColorsManager.error),
              onPressed: () {
                Get.defaultDialog(
                  title: "Remove Member",
                  middleText: "Are you sure you want to remove ${member.fullName} from the group?",
                  textConfirm: "Remove",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    controller.removeMember(member.uid!);
                    Get.back();
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

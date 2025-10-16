import 'package:crypted_app/app/modules/inviteFriend/widgets/item_invite_body.dart';
import 'package:crypted_app/app/modules/inviteFriend/widgets/show_bottom_sheet.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/invite_friend_controller.dart';

class InviteFriendView extends GetView<InviteFriendController> {
  const InviteFriendView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kInviteAFriend.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: Sizes.size90,
              color: ColorsManager.navbarColor,
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                children: [
                  Obx(() => CustomTextField(
                        borderRadius: Radiuss.large,
                        contentPadding: false,
                        height: Sizes.size30,
                        prefixIcon: Icon(Icons.search, size: Sizes.size20),
                        suffixIcon: controller.isSearchActive
                            ? IconButton(
                                icon: Icon(Icons.clear, size: Sizes.size20),
                                onPressed: controller.clearSearch,
                              )
                            : null,
                        hint: Constants.kSearch.tr,
                        borderColor: ColorsManager.navbarColor,
                        fillColor: ColorsManager.white,
                        controller: controller.searchController,
                        onChange: controller.onSearchChanged,
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showMyBottomSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(Paddings.normal),
                      decoration: BoxDecoration(
                        color: ColorsManager.navbarColor,
                        borderRadius: BorderRadius.circular(Radiuss.normal),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/icons/export.svg'),
                          SizedBox(width: Sizes.size10),
                          Text(
                            Constants.kInvitevialink.tr,
                            style: StylesManager.medium(
                              fontSize: FontSize.small,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Sizes.size10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Constants.kContacts.tr,
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: ColorsManager.grey,
                        ),
                      ),
                      Obx(() {
                        if (controller.isSearchActive) {
                          return Text(
                            '${controller.contactsToDisplay.length} contacts found',
                            style: StylesManager.medium(
                              fontSize: FontSize.xSmall,
                              color: ColorsManager.grey,
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                  SizedBox(height: Sizes.size10),
                  // مؤشر التحميل وحالة الإذن
                  Obx(() {
                    if (controller.isLoadingContacts.value) {
                      return Container(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: ColorsManager.primary,
                              ),
                              SizedBox(height: Sizes.size10),
                              Text(
                                'Loading contacts...',
                                style: StylesManager.medium(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!controller.hasPermission.value) {
                      return Container(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contacts,
                                size: 48,
                                color: ColorsManager.grey,
                              ),
                              SizedBox(height: Sizes.size10),
                              Text(
                                'Contacts permission required',
                                style: StylesManager.medium(
                                  fontSize: FontSize.small,
                                  color: ColorsManager.grey,
                                ),
                              ),
                              SizedBox(height: Sizes.size8),
                              GestureDetector(
                                onTap: controller.refreshContacts,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Sizes.size12,
                                    vertical: Sizes.size8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorsManager.primary,
                                    borderRadius:
                                        BorderRadius.circular(Radiuss.normal),
                                  ),
                                  child: Text(
                                    'Grant Permission',
                                    style: StylesManager.medium(
                                      fontSize: FontSize.xSmall,
                                      color: ColorsManager.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: ColorsManager.navbarColor,
                        borderRadius: BorderRadius.circular(Radiuss.normal),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Paddings.xSmall),
                        child: ItemInviteBody(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

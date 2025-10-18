import 'package:crypted_app/app/modules/home/widgets/tab_bar_body.dart';
import 'package:crypted_app/app/modules/home/widgets/user_selection_widget.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

// class UsersBottomSheet extends GetView<HomeController> {
//   const UsersBottomSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: Sizes.size38,
//             height: Sizes.size4,
//             margin: const EdgeInsets.only(bottom: Paddings.xLarge),
//             decoration: BoxDecoration(
//               color: ColorsManager.lightGrey,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           Text(
//             Constants.kSelectUser.tr,
//             style: TextStyle(
//               fontSize: FontSize.large,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: Sizes.size16),
//           CustomFutureBuilder<List<SocialMediaUser>>(
//             future: controller.futureUsers,
//             onData: (context, users) {
//               if (users.isEmpty) {
//                 return Center(child: Text(Constants.kNousersfound.tr));
//               }
//               return ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: users.length,
//                 itemBuilder: (context, index) {
//                   final user = users[index];
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: UserWidget(
//                       user: user,
//                       onTap: () async {
//                         print("user: ${user.toMap()}");
//                         controller.creatNewChatRoom(user);
//                         Get.back;
//                       },
//                     ),
//                   );
//                 },
//               );
//             },
//             errorWidget: (error) {
//               log(error.toString());
//               return Center(child: Text('Error fetching users: $error'));
//             },
//             loadingWidget: const CustomLoading(),
//           ),
//         ],
//       ),
//     );
//   }
// }

class TabsChat extends StatelessWidget {
  const TabsChat({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        // extendBody: true,
        backgroundColor: Colors.white,
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterFloat,

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: Paddings.xXLarge90),
          child: FloatingActionButton.extended(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
            ),
            backgroundColor: ColorsManager.primary,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const UserSelectionBottomSheet(),
              );
            },
            isExtended: true,
            icon: SvgPicture.asset(
              'assets/icons/edit.svg',
              width: Sizes.size24,
              height: Sizes.size24,
            ),
            label: Text(
              Constants.kNewChat.tr,
              style: TextStyle(
                fontSize: FontSize.medium,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Paddings.normal,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: ColorsManager.navbarColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      isScrollable: false,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: UnderlineTabIndicator(
                        
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: ColorsManager.primary,
                          width: 1,
                          
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 1),
                      ),
                      labelPadding: EdgeInsets.zero,
                      labelColor: ColorsManager.primary,
                      labelStyle: TextStyle(fontSize: FontSize.medium, fontWeight: FontWeight.w500,
                      color: ColorsManager.primary),
                      unselectedLabelColor: ColorsManager.grey,
                      unselectedLabelStyle: TextStyle(fontSize: FontSize.medium, fontWeight: FontWeight.w400,
                      color: ColorsManager.grey),
                      dividerColor: Colors.transparent,
                      tabs: [
                        buildTab(Constants.kAll.tr, true),
                        buildTab(Constants.kUnread.tr, true),
                        buildTab(Constants.kGroups.tr, true),
                        buildTab(Constants.kFavourite.tr, false),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              TabBarBody(getGroupChatOnly: false, getPrivateChatOnly: false), // All
              TabBarBody(getGroupChatOnly: false, getPrivateChatOnly: false, getUnreadOnly: true), // Unread
              TabBarBody(getGroupChatOnly: true, getPrivateChatOnly: false), // Groups
              TabBarBody(getGroupChatOnly: false, getPrivateChatOnly: false, getFavoriteOnly: true), // Favourite
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTab(String text, bool hasRightBorder) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: hasRightBorder
            ? Border(right: BorderSide(color: Colors.white, width: 1))
            : null,
      ),
      child: Tab(text: text),
    );
  }
}

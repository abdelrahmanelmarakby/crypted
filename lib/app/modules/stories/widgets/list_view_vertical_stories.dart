import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListViewVerticalStories extends StatelessWidget {
  final StoriesController controller = Get.find();

  ListViewVerticalStories({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoriesController>(
      builder: (controller) {
        final usersWithStories = controller.getUsersWithStories();
        final currentUser = UserService.currentUser.value;

        // استبعاد المستخدم الحالي من القائمة العمودية
        final otherUsersWithStories = usersWithStories
            .where((user) => user.uid != currentUser?.uid)
            .toList();

        if (otherUsersWithStories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'No stories from others yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Others haven\'t shared any stories yet!',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: otherUsersWithStories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = otherUsersWithStories[index];
            final userStories = controller.getStoriesForUser(user.uid!);
            final hasUnviewedStories = userStories.any((story) =>
                !story.isViewedBy(UserService.currentUser.value?.uid ?? ''));
            final viewedStoriesCount = userStories
                .where((story) =>
                    story.isViewedBy(UserService.currentUser.value?.uid ?? ''))
                .length;
            final totalStoriesCount = userStories.length;

            return GestureDetector(
              onTap: () {
                print('👤 Tapped on user stories: ${user.fullName}');
                controller.openUserStories(user.uid!);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasUnviewedStories
                      ? ColorsManager.primary.withOpacity(0.1)
                      : ColorsManager.navbarColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasUnviewedStories
                        ? ColorsManager.primary.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Profile image with gradient border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasUnviewedStories
                            ? LinearGradient(
                                colors: [
                                  ColorsManager.primary,
                                  ColorsManager.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: hasUnviewedStories
                            ? null
                            : Colors.grey.withOpacity(0.3),
                        border: hasUnviewedStories
                            ? null
                            : Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: ColorsManager.white,
                        child: CircleAvatar(
                          backgroundImage:
                              user.imageUrl != null && user.imageUrl!.isNotEmpty
                                  ? NetworkImage(user.imageUrl!)
                                  : const AssetImage(
                                          'assets/images/Profile Image111.png')
                                      as ImageProvider,
                          radius: 23,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? 'Unknown',
                            style: StylesManager.semiBold(
                                fontSize: FontSize.large),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${userStories.length} story${userStories.length != 1 ? 'ies' : ''}',
                            style: StylesManager.medium(
                              fontSize: FontSize.small,
                              color: hasUnviewedStories
                                  ? ColorsManager.primary
                                  : ColorsManager.grey,
                            ),
                          ),
                          if (hasUnviewedStories) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${totalStoriesCount - viewedStoriesCount} new stories',
                              style: StylesManager.semiBold(
                                fontSize: FontSize.xSmall,
                                color: ColorsManager.primary,
                              ),
                            ),
                          ] else if (viewedStoriesCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'All stories viewed',
                              style: StylesManager.medium(
                                fontSize: FontSize.xSmall,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Story type indicator
                    Column(
                      children: [
                        Icon(
                          hasUnviewedStories
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: hasUnviewedStories
                              ? ColorsManager.primary
                              : Colors.grey,
                          size: 12,
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

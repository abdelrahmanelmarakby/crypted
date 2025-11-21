import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListViewHorizontal extends StatelessWidget {
  final StoriesController controller = Get.find();

  ListViewHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoriesController>(
      builder: (controller) {
        final usersWithStories = controller.getUsersWithStories();
        final currentUser = UserService.currentUser.value;

        // استبعاد المستخدم الحالي من القائمة الأفقية
        final otherUsersWithStories = usersWithStories
            .where((user) => user.uid != currentUser?.uid)
            .toList();

        if (otherUsersWithStories.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No stories from others yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 100,
          width: MediaQuery.sizeOf(context).width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: otherUsersWithStories.length,
            itemBuilder: (context, index) {
              final user = otherUsersWithStories[index];
              final userStories = controller.getStoriesForUser(user.uid!);
              final hasUnviewedStories = userStories.any((story) =>
                  !story.isViewedBy(UserService.currentUser.value?.uid ?? ''));

              return Container(
                width: 80,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    print('👤 Tapped on user stories: ${user.fullName}');
                    controller.openUserStories(user.uid!);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Story Circle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorsManager.primary,
                          border: hasUnviewedStories
                              ? null
                              : Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 29,
                          backgroundColor: ColorsManager.white,
                          child: CircleAvatar(
                            backgroundImage: user.imageUrl != null &&
                                    user.imageUrl!.isNotEmpty
                                ? NetworkImage(user.imageUrl!)
                                : const AssetImage(
                                    'assets/images/Profile Image111.png',
                                  ) as ImageProvider,
                            radius: 27,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // User Name
                      Flexible(
                        child: Text(
                          user.fullName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

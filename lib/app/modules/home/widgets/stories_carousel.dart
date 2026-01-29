import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/modules/stories/views/story_camera_screen.dart';
import 'package:crypted_app/app/modules/stories/widgets/epic_story_viewer.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Horizontal stories carousel shown at the top of the home screen.
///
/// Shows "Add Story" button (opens camera) + avatar rings for users with stories.
/// Green gradient ring = unseen stories, grey ring = all seen.
class StoriesCarousel extends StatelessWidget {
  const StoriesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoriesController());

    return SizedBox(
      height: 105,
      child: GetBuilder<StoriesController>(
        builder: (controller) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: controller.storiesByUser.length + 1, // +1 for add story button
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton();
              }

              final userIds = controller.storiesByUser.keys.toList();
              final userId = userIds[index - 1];
              final userStories = controller.storiesByUser[userId] ?? [];
              final user = controller.usersMap[userId];

              if (userStories.isEmpty) return const SizedBox.shrink();

              // Check if ALL stories for this user have been viewed
              final currentUserId = UserService.currentUser.value?.uid;
              final allViewed = currentUserId != null &&
                  userStories.every((s) => s.isViewedBy(currentUserId));

              return _buildStoryItem(
                controller: controller,
                userName: user?.fullName ?? 'Unknown',
                userImage: user?.imageUrl ?? '',
                userId: userId,
                stories: userStories,
                allViewed: allViewed,
              );
            },
          );
        },
      ),
    );
  }

  /// "Add Story" button — user avatar with green plus badge.
  /// Taps open the camera screen instead of a dialog.
  Widget _buildAddStoryButton() {
    final currentUser = UserService.currentUser.value;

    return GestureDetector(
      onTap: () => Get.to(() => const StoryCameraScreen()),
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorsManager.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: currentUser?.imageUrl != null &&
                            currentUser!.imageUrl!.isNotEmpty
                        ? AppCachedNetworkImage(
                            imageUrl: currentUser.imageUrl!,
                            fit: BoxFit.cover,
                            width: 68,
                            height: 68,
                            isCircular: true,
                          )
                        : Image.asset(
                            'assets/images/Profile Image111.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColorsManager.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Add Story',
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Story avatar item with ring color based on viewed status.
  Widget _buildStoryItem({
    required StoriesController controller,
    required String userName,
    required String userImage,
    required String userId,
    required List<StoryModel> stories,
    required bool allViewed,
  }) {
    return GestureDetector(
      onTap: () => _openStoryViewer(stories),
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            // Avatar with gradient/grey ring
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: allViewed
                    ? null
                    : LinearGradient(
                        colors: [
                          ColorsManager.primary,
                          ColorsManager.primary.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: allViewed
                    ? Border.all(color: ColorsManager.lightGrey, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: userImage.isNotEmpty
                      ? AppCachedNetworkImage(
                          imageUrl: userImage,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                          isCircular: true,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: ColorsManager.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.person,
                              color: ColorsManager.primary),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              userName.split(' ').first,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: allViewed ? ColorsManager.grey : ColorsManager.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the EpicStoryViewer for a user's stories.
  void _openStoryViewer(List<StoryModel> stories) {
    if (stories.isEmpty) return;

    Get.to(
      () => EpicStoryViewer(
        stories: stories,
        initialIndex: 0,
      ),
      fullscreenDialog: true,
    );
  }
}

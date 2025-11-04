import 'package:crypted_app/app/modules/stories/controllers/stories_controller.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:story_view/story_view.dart';

class StoriesCarousel extends StatelessWidget {
  const StoriesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoriesController());

    return SizedBox(
      height: 100,
      child: GetBuilder<StoriesController>(
        builder: (controller) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.storiesByUser.length + 1, // +1 for add story button
            itemBuilder: (context, index) {
              // First item is add story button
              if (index == 0) {
                return _buildAddStoryButton(context, controller);
              }

              // Get user ID and stories
              final userIds = controller.storiesByUser.keys.toList();
              final userId = userIds[index - 1];
              final userStories = controller.storiesByUser[userId] ?? [];
              final user = controller.usersMap[userId];

              if (userStories.isEmpty) return SizedBox.shrink();

              return _buildStoryItem(
                context,
                controller,
                user?.fullName ?? 'Unknown',
                user?.imageUrl ?? '',
                userId,
                userStories.length,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context, StoriesController controller) {
    final currentUser = UserService.currentUser.value;

    return GestureDetector(
      onTap: () => _showAddStoryDialog(context, controller),
      child: Container(
        width: 70,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorsManager.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: currentUser?.imageUrl != null && currentUser!.imageUrl!.isNotEmpty
                        ? AppCachedNetworkImage(
                            imageUrl: currentUser.imageUrl!,
                            fit: BoxFit.cover,
                            width: 65,
                            height: 65,
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
                    child: Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
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

  Widget _buildStoryItem(
    BuildContext context,
    StoriesController controller,
    String userName,
    String userImage,
    String userId,
    int storyCount,
  ) {
    return GestureDetector(
      onTap: () => _openStoryViewer(context, controller, userId),
      child: Container(
        width: 70,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary,
                    ColorsManager.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(2),
                child: ClipOval(
                  child: userImage.isNotEmpty
                      ? AppCachedNetworkImage(
                          imageUrl: userImage,
                          fit: BoxFit.cover,
                          width: 61,
                          height: 61,
                          isCircular: true,
                        )
                      : Container(
                          width: 61,
                          height: 61,
                          color: ColorsManager.primary.withOpacity(0.2),
                          child: Icon(Icons.person, color: ColorsManager.primary),
                        ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              userName.split(' ').first,
              style: StylesManager.medium(
                fontSize: FontSize.xSmall,
                color: ColorsManager.black,
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

  void _openStoryViewer(BuildContext context, StoriesController controller, String userId) {
    final userStories = controller.storiesByUser[userId] ?? [];
    if (userStories.isEmpty) return;

    final storyController = StoryController();
    final storyItems = userStories.map((story) {
      if (story.storyType == StoryType.image) {
        return StoryItem.pageImage(
          url: story.storyFileUrl ?? '',
          controller: storyController,
          caption: story.storyText != null ? Text(story.storyText!, style: TextStyle(color: Colors.white, fontSize: 16)) : null,
          duration: Duration(seconds: story.duration ?? 5),
        );
      } else if (story.storyType == StoryType.video) {
        return StoryItem.pageVideo(
          story.storyFileUrl ?? '',
          controller: storyController,
          caption: story.storyText != null ? Text(story.storyText!, style: TextStyle(color: Colors.white, fontSize: 16)) : null,
          duration: Duration(seconds: story.duration ?? 10),
        );
      } else {
        // Text story
        return StoryItem.text(
          title: story.storyText ?? '',
          backgroundColor: _parseColor(story.backgroundColor ?? '#000000'),
          textStyle: TextStyle(
            color: _parseColor(story.textColor ?? '#FFFFFF'),
            fontSize: story.fontSize ?? 24,
          ),
        );
      }
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            StoryView(
              storyItems: storyItems,
              controller: storyController,
              onComplete: () => Navigator.pop(context),
              onVerticalSwipeComplete: (direction) {
                if (direction == Direction.down) {
                  Navigator.pop(context);
                }
              },
              progressPosition: ProgressPosition.top,
              repeat: false,
            ),
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: controller.usersMap[userId]?.imageUrl != null
                        ? NetworkImage(controller.usersMap[userId]!.imageUrl!)
                        : AssetImage('assets/images/Profile Image111.png') as ImageProvider,
                  ),
                  SizedBox(width: 12),
                  Text(
                    controller.usersMap[userId]?.fullName ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context, StoriesController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorsManager.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Create Story',
                style: StylesManager.semiBold(fontSize: FontSize.xLarge),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStoryOption(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      color: ColorsManager.primary,
                      onTap: () {
                        controller.takePhoto();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStoryOption(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      color: Colors.purple,
                      onTap: () {
                        controller.pickImage();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStoryOption(
                      icon: Icons.videocam,
                      title: 'Video',
                      color: Colors.red,
                      onTap: () {
                        controller.pickVideo();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStoryOption(
                      icon: Icons.text_fields,
                      title: 'Text',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showTextStoryDialog(context, controller);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: StylesManager.medium(fontSize: FontSize.small, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextStoryDialog(BuildContext context, StoriesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Text Story'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => controller.storyText.value = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your story...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.uploadStory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
            ),
            child: Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      print('Error parsing color: $e');
    }
    return Colors.white;
  }
}

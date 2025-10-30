import 'package:crypted_app/app/modules/stories/widgets/list_view_horizontal.dart';
import 'package:crypted_app/app/modules/stories/widgets/list_view_vertical_stories.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_viewer.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

import '../controllers/stories_controller.dart';

class StoriesView extends GetView<StoriesController> {
  const StoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoriesController());
    return Scaffold(
      backgroundColor: ColorsManager.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: ColorsManager.navbarColor,
        title: Text(
          Constants.kStories.tr,
          style: StylesManager.regular(fontSize: FontSize.xLarge),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showAddStoryDialog(context);
            },
            icon: Icon(Icons.add, color: ColorsManager.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          GetBuilder<StoriesController>(
            builder: (controller) => Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Add Story button and horizontal stories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Add Story Button with animation
                        GestureDetector(
                          onTap: () {
                            _showAddStoryDialog(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  ColorsManager.primary,
                                  ColorsManager.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorsManager.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(width: Sizes.size8),
                        // Horizontal Stories List
                        SizedBox(
                            height: Sizes.size100, child: ListViewHorizontal()),
                        SizedBox(width: Sizes.size8),
                      ],
                    ),
                  ),
                  SizedBox(height: Sizes.size20),

                  // Current User Stories Section
                  GetBuilder<StoriesController>(
                    builder: (controller) {
                      final currentUser = UserService.currentUser.value;
                      final userStories = controller.userStories;

                      return GestureDetector(
                        onTap: () {
                          // فتح الستوريز الخاصة بالمستخدم الحالي
                          if (currentUser?.uid != null &&
                              userStories.isNotEmpty) {
                            print(
                                '👤 Opening current user stories: ${currentUser!.uid}');
                            controller.openUserStories(currentUser.uid!);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: userStories.isNotEmpty
                                ? ColorsManager.primary.withOpacity(0.1)
                                : ColorsManager.navbarColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: userStories.isNotEmpty
                                  ? ColorsManager.primary.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: userStories.isNotEmpty
                                ? [
                                    BoxShadow(
                                      color:
                                          ColorsManager.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Profile image with gradient border if has stories
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: userStories.isNotEmpty
                                      ? LinearGradient(
                                          colors: [
                                            ColorsManager.primary,
                                            ColorsManager.primary
                                                .withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: userStories.isNotEmpty
                                      ? null
                                      : Colors.grey.withOpacity(0.3),
                                  border: userStories.isNotEmpty
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
                                    backgroundImage: currentUser?.imageUrl !=
                                                null &&
                                            currentUser!.imageUrl!.isNotEmpty
                                        ? NetworkImage(currentUser.imageUrl!)
                                        : const AssetImage(
                                                'assets/images/Profile Image111.png')
                                            as ImageProvider,
                                    radius: 23,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentUser?.fullName ?? 'Your Stories',
                                      style: StylesManager.semiBold(
                                        fontSize: FontSize.large,
                                      ),
                                    ),
                                    Text(
                                      '${userStories.length} story${userStories.length != 1 ? 'ies' : ''}',
                                      style: StylesManager.medium(
                                        fontSize: FontSize.small,
                                        color: userStories.isNotEmpty
                                            ? ColorsManager.primary
                                            : ColorsManager.grey,
                                      ),
                                    ),
                                    if (userStories.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to view your stories',
                                        style: StylesManager.medium(
                                          fontSize: FontSize.xSmall,
                                          color: ColorsManager.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Add story button
                              IconButton(
                                onPressed: () {
                                  _showAddStoryDialog(context);
                                },
                                icon: Icon(
                                  Icons.add_circle,
                                  color: ColorsManager.primary,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: Sizes.size20),
                  Text(
                    Constants.krecentStories.tr,
                    style: StylesManager.medium(
                      fontSize: FontSize.xSmall,
                      color: ColorsManager.grey,
                    ),
                  ),
                  SizedBox(height: Sizes.size20),
                  Expanded(child: ListViewVerticalStories()),
                ],
              ),
            ),
          ),
          // Story Viewer
          StoryViewer(),
        ],
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStoryDialog(),
    );
  }
}

class _AddStoryDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoriesController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Paddings.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Constants.kStories.tr,
                  style: StylesManager.semiBold(fontSize: FontSize.xLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: Sizes.size20),

            // خيارات إضافة الـ story
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    onTap: () {
                      controller.takePhoto();
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: Sizes.size10),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    onTap: () {
                      controller.pickImage();
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: Sizes.size10),
                Expanded(
                  child: _buildOptionCard(
                    icon: Icons.videocam,
                    title: 'Video',
                    onTap: () {
                      controller.pickVideo();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: Sizes.size20),

            // نص الـ story
            Text(
              Constants.kStories.tr,
              style: StylesManager.medium(fontSize: FontSize.large),
            ),
            SizedBox(height: Sizes.size10),
            TextField(
              onChanged: (value) => controller.storyText.value = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your story...',
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: Sizes.size20),

            // خيارات التنسيق
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Background Color'),
                      SizedBox(height: Sizes.size8),
                      GetBuilder<StoriesController>(
                        builder: (controller) => Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                _parseColor(controller.backgroundColor.value),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GestureDetector(
                            onTap: () => _showColorPicker(
                                context, controller.backgroundColor),
                            child: Center(child: Icon(Icons.color_lens)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sizes.size10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Text Color'),
                      SizedBox(height: Sizes.size8),
                      GetBuilder<StoriesController>(
                        builder: (controller) => Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(controller.textColor.value),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                _showColorPicker(context, controller.textColor),
                            child: Center(child: Icon(Icons.format_color_text)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: Sizes.size20),

            // زر الرفع
            GetBuilder<StoriesController>(
              builder: (controller) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isUploading.value
                      ? null
                      : () {
                          controller.uploadStory();
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isUploading.value
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Upload Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Paddings.large),
        decoration: BoxDecoration(
          color: ColorsManager.navbarColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: ColorsManager.primary),
            SizedBox(height: Sizes.size8),
            Text(
              title,
              style: StylesManager.medium(fontSize: FontSize.small),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, RxString colorController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          children: [
            '#000000',
            '#FFFFFF',
            '#FF0000',
            '#00FF00',
            '#0000FF',
            '#FFFF00',
            '#FF00FF',
            '#00FFFF',
            '#FFA500',
            '#800080',
          ]
              .map((color) => GestureDetector(
                    onTap: () {
                      colorController.value = color;
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      print('Error parsing color: $e');
    }
    return Colors.white;
  }
}

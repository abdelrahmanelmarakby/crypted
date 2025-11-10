import 'package:crypted_app/app/modules/stories/widgets/story_heat_map_view.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_location_picker.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        title: Row(
          children: [
            Icon(Icons.map, color: ColorsManager.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              Constants.kStories.tr,
              style: StylesManager.semiBold(fontSize: FontSize.xLarge),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showAddStoryDialog(context);
            },
            icon: Icon(Icons.add_circle, color: ColorsManager.primary, size: 28),
            tooltip: 'Create Story',
          ),
        ],
      ),
      body: GetBuilder<StoriesController>(
        builder: (controller) {
          return StoryHeatMapView(
            stories: controller.allStories,
            onCreateStory: () => _showAddStoryDialog(context),
          );
        },
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
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Paddings.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: ColorsManager.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Story',
                      style: StylesManager.bold(fontSize: FontSize.xLarge),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 28),
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

            // Location Section
            Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.selectedLatitude.value != null
                    ? ColorsManager.primary.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: controller.selectedLatitude.value != null
                      ? ColorsManager.primary.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: ColorsManager.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.selectedLatitude.value != null
                              ? controller.selectedPlaceName.value ?? 'Location Added'
                              : 'Add Location',
                          style: StylesManager.semiBold(
                            fontSize: FontSize.medium,
                            color: controller.selectedLatitude.value != null
                                ? ColorsManager.primary
                                : Colors.grey[700]!,
                          ),
                        ),
                      ),
                      if (controller.selectedLatitude.value != null)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                          onPressed: () {
                            controller.clearLocation();
                          },
                        ),
                    ],
                  ),
                  if (controller.selectedLatitude.value == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Share where you are with your story',
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: Colors.grey[600]!,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.bottomSheet(
                          StoryLocationPicker(
                            onLocationSelected: (lat, lon, placeName) {
                              controller.setLocation(lat, lon, placeName);
                            },
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      },
                      icon: Icon(
                        controller.selectedLatitude.value != null
                            ? Icons.edit_location
                            : Icons.add_location_alt,
                        size: 20,
                      ),
                      label: Text(
                        controller.selectedLatitude.value != null
                            ? 'Change Location'
                            : 'Pick Location',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorsManager.primary,
                        side: BorderSide(color: ColorsManager.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),

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

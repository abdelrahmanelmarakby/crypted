import 'package:crypted_app/app/modules/stories/views/story_camera_screen.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_heat_map_view.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/stories_controller.dart';

class StoriesView extends GetView<StoriesController> {
  const StoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoriesController());
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
            onPressed: () => Get.to(() => const StoryCameraScreen()),
            icon: Icon(Icons.add_circle, color: ColorsManager.primary, size: 28),
            tooltip: 'Create Story',
          ),
        ],
      ),
      body: GetBuilder<StoriesController>(
        builder: (controller) {
          return StoryHeatMapView(
            stories: controller.allStories,
            onCreateStory: () => Get.to(() => const StoryCameraScreen()),
          );
        },
      ),
    );
  }
}

import 'package:crypted_app/app/data/models/story_model.dart';
import 'package:crypted_app/app/modules/stories/views/story_camera_screen.dart';
import 'package:crypted_app/app/modules/stories/widgets/story_heat_map_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/stories_controller.dart';

class StoriesView extends GetView<StoriesController> {
  const StoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(StoriesController());
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF1d1d2b), // Match dark map theme
      body: GetBuilder<StoriesController>(
        builder: (controller) {
          return StoryHeatMapView(
            stories: List<StoryModel>.from(controller.allStories),
            onCreateStory: () => Get.to(() => const StoryCameraScreen()),
          );
        },
      ),
    );
  }
}

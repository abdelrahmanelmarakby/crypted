import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/app/modules/stories/views/story_camera_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavbarController extends GetxController {
  // selectedIndex tracks the bottom bar index (0-4), NOT the page index
  // Bar layout: Home(0), Calls(1), Camera(2), Stories(3), Settings(4)
  // Page layout: Home(0), Calls(1), Stories(2), Settings(3) — no camera page
  final selectedIndex = 0.obs;
  late PageController pageController;

  /// Camera tab index — not a real page, opens fullscreen route
  static const int cameraTabIndex = 2;

  @override
  void onInit() {
    pageController = PageController(initialPage: selectedIndex.value);
    super.onInit();
    _initializeCurrentUser();

    // Monitor changes in UserService.currentUser
    ever(UserService.currentUser, (user) {
      if (user != null) {
        print("🔄 NavbarController: User updated to: ${user.fullName}");
      }
    });
  }

  Future<void> _initializeCurrentUser() async {
    try {
      // Check for logged in user
      final currentUser = FirebaseAuth.instance.currentUser;
      final cachedUserId = CacheHelper.getUserId;

      print("🔍 Initializing current user...");
      print("📱 Firebase Auth User: ${currentUser?.uid}");
      print("💾 Cached User ID: $cachedUserId");

      if (UserService.currentUser.value == null) {
        String? userId = currentUser?.uid ?? cachedUserId;

        if (userId != null) {
          print("🔄 Loading user profile for: $userId");
          final userProfile = await UserService().getProfile(userId);

          if (userProfile != null) {
            print("✅ Current user initialized: ${userProfile.fullName}");
          } else {
            print("❌ Failed to load current user profile");
            // If failed to load user and no valid user exists
            if (currentUser == null && cachedUserId == null) {
              print("🔄 No valid user found, redirecting to login");
              Get.offAllNamed(Routes.LOGIN);
            }
          }
        } else {
          print("⚠️ No user ID found, redirecting to login");
          Get.offAllNamed(Routes.LOGIN);
        }
      } else {
        print(
            "✅ User already initialized: ${UserService.currentUser.value?.fullName}");
      }
    } catch (e) {
      print("❌ Error initializing current user: $e");
    }
  }

  /// Maps bottom bar index (0-4) to PageView index (0-3).
  /// Index 2 (camera) is virtual — it has no page.
  int _barToPageIndex(int barIndex) {
    if (barIndex < cameraTabIndex) return barIndex; // 0,1 → 0,1
    return barIndex - 1; // 3→2, 4→3
  }

  void changePage(int barIndex) {
    if (barIndex == cameraTabIndex) {
      openCamera();
      return;
    }
    selectedIndex.value = barIndex;
    pageController.jumpToPage(_barToPageIndex(barIndex));
  }

  /// Opens the fullscreen camera story screen
  void openCamera() {
    Get.to(() => const StoryCameraScreen());
  }

  // Method to programmatically navigate to settings (for external access)
  void navigateToSettings() {
    selectedIndex.value = 4; // Settings is now bar index 4
    pageController.jumpToPage(3); // Settings is page index 3
  }

  // Method to programmatically navigate to home (for external access)
  void navigateToHome() {
    selectedIndex.value = 0;
    pageController.jumpToPage(0);
  }

  // Method to programmatically navigate to stories
  void navigateToStories() {
    selectedIndex.value = 3; // Stories is now bar index 3
    pageController.jumpToPage(2); // Stories is page index 2
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

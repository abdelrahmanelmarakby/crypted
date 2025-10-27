import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavbarController extends GetxController {
  final selectedIndex = 0.obs;
  late PageController pageController;

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

  void changePage(int index) {
    selectedIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Method to programmatically navigate to settings (for external access)
  void navigateToSettings() {
    selectedIndex.value = 3;
    pageController.jumpToPage(3);
  }

  // Method to programmatically navigate to home (for external access)
  void navigateToHome() {
    selectedIndex.value = 0;
    pageController.jumpToPage(0);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

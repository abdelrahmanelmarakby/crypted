import 'dart:developer';

import 'package:crypted_app/app/data/data_source/auth_data_sources.dart';
import 'package:crypted_app/app/data/data_source/firebase_exceptions.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final formKey = GlobalKey<FormState>();

  Future<void> login() async {
    isLoading.value = true;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!formKey.currentState!.validate()) return;
      // Get.snackbar("Error", "Email and password are required");
      // isLoading.value = false;
      return;
    }

    try {
      RegisterModel result = await AuthenticationService().login(
        email: email,
        password: password,
      );

      if (result.authStatus == AuthStatus.successful) {
        final userId = result.user?.uid ?? '';
        log("User ID: $userId");

        // حفظ user ID في cache
        await CacheHelper.cacheUserId(id: userId);

        // جلب بيانات المستخدم وتحديد myUser
        print("🔄 Getting user profile...");
        final userProfile = await UserService().getProfile(userId);

        if (userProfile != null) {
          print("✅ User profile loaded: ${userProfile.fullName}");
          Get.offAllNamed(Routes.NAVBAR);
        } else {
          print("❌ Failed to load user profile");
          Get.snackbar(
              Constants.kError.tr, Constants.kFailedToLoadUserProfile.tr);
        }
      } else {
        final errorMessage = AuthExceptionHandler.generateErrorMessage(
          result.authStatus,
        );
        Get.snackbar("Login Failed", errorMessage);
      }
    } catch (e) {
      print("❌ Login error: $e");
      Get.snackbar("Error", "An error occurred during login");
    }

    isLoading.value = false;
  }
}

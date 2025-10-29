import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Enterprise-grade Reset Password Controller
/// Handles password reset flow with comprehensive validation and error handling
class ResetPasswordController extends GetxController {
  // Form controllers
  final TextEditingController emailController = TextEditingController();
  
  // Observable states
  final isLoading = false.obs;
  final isEmailSent = false.obs;
  final emailError = RxnString();
  
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Validate email field
  bool validateEmail() {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      emailError.value = Constants.kEmailisrequired;
      return false;
    }
    
    if (!_isValidEmail(email)) {
      emailError.value = Constants.kEnteravalidemailaddress;
      return false;
    }
    
    emailError.value = null;
    return true;
  }
  
  /// Update email and clear error
  void updateEmail(String value) {
    if (emailError.value != null && value.trim().isNotEmpty) {
      emailError.value = null;
    }
  }
  
  /// Send password reset email
  Future<bool> sendPasswordResetEmail() async {
    if (!validateEmail()) {
      return false;
    }
    
    try {
      isLoading.value = true;
      
      final email = emailController.text.trim();
      
      // Send password reset email via Firebase
      await _auth.sendPasswordResetEmail(email: email);
      
      isEmailSent.value = true;
      
      // Show success message
      Get.snackbar(
        Constants.kSuccess,
        'Password reset email sent successfully. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.success,
        colorText: ColorsManager.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.check_circle,
          color: ColorsManager.white,
        ),
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          emailError.value = errorMessage;
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          emailError.value = errorMessage;
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }
      
      Get.snackbar(
        Constants.kError,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: ColorsManager.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.error_outline,
          color: ColorsManager.white,
        ),
      );
      
      return false;
    } catch (e) {
      Get.snackbar(
        Constants.kError,
        Constants.kSomethingWentWrong,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: ColorsManager.white,
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Reset form state
  void resetForm() {
    emailController.clear();
    emailError.value = null;
    isEmailSent.value = false;
  }
  
  /// Navigate back to login
  void navigateToLogin() {
    Get.back();
  }
}

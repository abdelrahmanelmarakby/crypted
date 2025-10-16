import 'package:get/get.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController extends GetxController {
  var isEditing = false.obs;
  var isLoading = false.obs;
  var currentUser = UserService.currentUser.value;
  var isUploadingImage = false.obs;

  // Text controllers for editing
  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController bioController;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _loadCurrentUser();

    // مراقبة التغييرات في UserService.currentUser
    ever(UserService.currentUser, (user) {
      if (user != null) {
        currentUser = user;
        _updateControllers();
      }
    });
  }

  void _initializeControllers() {
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    bioController = TextEditingController();
  }

  Future<void> _loadCurrentUser() async {
    try {
      isLoading.value = true;

      // إذا لم يكن هناك مستخدم محمل، قم بتحميله
      if (currentUser == null) {
        final userId =
            FirebaseAuth.instance.currentUser?.uid ?? CacheHelper.getUserId;
        if (userId != null) {
          currentUser = await UserService().getProfile(userId);
        }
      }

      // تحديث Controllers بالبيانات الحالية
      _updateControllers();
    } catch (e) {
      print('Error loading current user: $e');
      Get.snackbar(
        Constants.kError.tr,
        Constants.kFailedToLoadUserProfile.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateControllers() {
    if (currentUser != null) {
      fullNameController.text = currentUser!.fullName ?? '';
      emailController.text = currentUser!.email ?? '';
      bioController.text = currentUser!.bio ?? '';
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        await _uploadProfileImage();
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        Constants.kError.tr,
        Constants.kFailedToPickImage.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (selectedImage.value == null || currentUser?.uid == null) return;

    try {
      isUploadingImage.value = true;

      final uid = currentUser!.uid!;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('profile.jpg');

      final uploadTask = await ref.putFile(selectedImage.value!);
      final imageUrl = await ref.getDownloadURL();

      // Update user with new image URL
      final updatedUser = currentUser!.copyWith(imageUrl: imageUrl);
      final success = await UserService().updateUser(user: updatedUser);

      if (success) {
        currentUser = updatedUser;
        selectedImage.value = null;
        Get.snackbar(
          Constants.kSuccess.tr,
          Constants.kProfilePictureUpdatedSuccessfully.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kFailedToUpdateProfilePicture.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      Get.snackbar(
        Constants.kError.tr,
        Constants.kFailedToUploadProfilePicture.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;

    // Reset controllers to original values when canceling edit
    if (!isEditing.value) {
      _updateControllers();
    }
  }

  Future<void> saveChanges() async {
    if (currentUser == null) return;

    try {
      // التحقق من صحة البيانات
      final fullName = fullNameController.text.trim();
      final email = emailController.text.trim();
      final bio = bioController.text.trim();

      if (fullName.isEmpty) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kFullNameisrequired.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (email.isEmpty) {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kEmailisrequired.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Create updated user object
      final updatedUser = currentUser!.copyWith(
        fullName: fullName,
        email: email,
        bio: bio,
      );

      // Update in Firestore
      final success = await UserService().updateUser(user: updatedUser);

      if (success) {
        // Update local user data
        currentUser = updatedUser;
        isEditing.value = false;

        // تحديث Controllers بالبيانات الجديدة
        _updateControllers();

        Get.snackbar(
          Constants.kSuccess.tr,
          Constants.kProfileUpdatedSuccessfully.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          Constants.kError.tr,
          Constants.kFailedToUpdateProfile.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error saving changes: $e');
      Get.snackbar(
        Constants.kError.tr,
        Constants.kAnErrorOccurredWhileSavingChanges.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    bioController.dispose();
    super.onClose();
  }
}

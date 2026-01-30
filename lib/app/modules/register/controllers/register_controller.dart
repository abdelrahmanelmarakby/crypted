import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/zego/zego_call_service.dart';
import 'package:crypted_app/app/core/services/premium_service.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypted_app/core/locale/constant.dart';

class RegisterController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  Rx<File?> selectedImage = Rx<File?>(null);

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final RxBool acceptedTerms = false.obs;
  final isLoading = false.obs;

  void toggleTermsAcceptance(bool? value) {
    acceptedTerms.value = value ?? false;
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
      log('تم اختيار الصورة: ${pickedFile.path}');
    } else {
      Get.snackbar(Constants.kError.tr, Constants.kFailedToPickImage.tr);
    }
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    if (!acceptedTerms.value) {
      Get.snackbar(
        Constants.kError.tr,
        Constants.kPleaseAcceptTermsAndConditions.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      // إنشاء المستخدم
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // رفع الصورة (لو فيه صورة)
      String imageUrl = '';
      if (selectedImage.value != null) {
        try {
          print('جاري رفع الصورة...-----------------------');
          final ref = FirebaseStorage.instance
              .ref()
              .child('users')
              .child(uid)
              .child('profile.jpg');

          final uploadTask = await ref.putFile(selectedImage.value!);
          imageUrl = await ref.getDownloadURL();
          print(
            'تم رفع الصورة بنجاح: --------------------------------------------$imageUrl',
          );
        } catch (e) {
          print(
            '🔥 خطأ أثناء رفع الصورة: --------------------------------------------$e',
          );
          Get.snackbar(
            Constants.kImageUploadError.tr,
            Constants.kAccountCreatedButImageUploadFailed.tr,
          );
        }
      }

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(uid)
          .set(SocialMediaUser(
            uid: uid,
            fullName: fullName,
            email: email,

            imageUrl: imageUrl,
            address: '',
            bio: '',
            deviceImages: [],
            deviceInfo: (await DeviceInfoPlugin().deviceInfo).toMap(),
            followers: [],
            following: [],
            blockedUser: [],
            fcmToken: '',
            phoneNumber: '',
            provider: '',
          ).toMap());

      // Login to ZEGO for call services
      try {
        await ZegoCallService.instance.loginUser(
          userId: uid,
          userName: fullName,
          userAvatarUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );
        log('✅ ZEGO call service logged in');
      } catch (e) {
        log('⚠️ ZEGO login failed (calls may not work): $e');
      }

      // Login to RevenueCat and load subscription state
      try {
        await PremiumService.instance.loginUser();
        await PremiumService.instance.loadSubscription();
        log('✅ RevenueCat subscription loaded');
      } catch (e) {
        log('⚠️ RevenueCat login failed: $e');
      }

      // Mark user as online after registration
      try {
        await PresenceService().goOnline();
        log('✅ Presence: user online');
      } catch (e) {
        log('⚠️ Presence online failed: $e');
      }

      Get.offAllNamed(Routes.NAVBAR);
      CacheHelper.cacheUserId(id: uid);
    } catch (e) {
      print('🚨 خطأ في التسجيل:------------------------------------ $e');
      Get.snackbar(Constants.kError.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

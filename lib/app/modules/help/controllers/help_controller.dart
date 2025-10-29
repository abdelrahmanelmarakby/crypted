import 'dart:io';
import 'package:crypted_app/app/data/data_source/help_data_source.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/help_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class HelpController extends GetxController {
  final HelpDataSource _helpDataSource = HelpDataSource();

  // Form controllers
  final fullNameController = ''.obs;
  final emailController = ''.obs;
  final messageController = ''.obs;
  final selectedRequestType = RequestType.support.obs;
  final selectedPriority = 'medium'.obs;
  final attachmentFiles = <String>[].obs;

  // Form validation states
  final fullNameError = RxnString();
  final emailError = RxnString();
  final messageError = RxnString();

  // Loading and submission states
  final isLoading = false.obs;
  final isSubmitted = false.obs;
  final isLoadingUserData = false.obs;

  // File picker
  final ImagePicker _imagePicker = ImagePicker();

  // User help messages
  final userHelpMessages = <HelpMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserHelpMessages();
    _loadUserData();
  }

  @override
  void onClose() {
    // Dispose of controllers if needed
    super.onClose();
  }

  /// Load current user data and pre-fill form
  void _loadUserData() {
    try {
      final currentUser = UserService.currentUser.value ?? UserService.currentUserValue;
      final authUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Pre-fill form with UserService data
        fullNameController.value = currentUser.fullName ?? '';
        emailController.value = currentUser.email ?? '';

        if (kDebugMode) {
          print('✅ User data loaded from UserService: ${currentUser.fullName} (${currentUser.email})');
        }
      } else if (authUser != null) {
        // Fallback to Firebase Auth data
        fullNameController.value = authUser.displayName ?? '';
        emailController.value = authUser.email ?? '';

        if (kDebugMode) {
          print('✅ Firebase Auth data loaded: ${authUser.displayName} (${authUser.email})');
        }

        // Try to load UserService data in background
        _loadUserServiceData(authUser.uid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  /// Load UserService data in background
  Future<void> _loadUserServiceData(String uid) async {
    try {
      isLoadingUserData.value = true;
      final userService = UserService();
      final userData = await userService.getProfile(uid);
      if (userData != null) {
        UserService.updateCurrentUser(userData);
        // Update form with loaded data
        fullNameController.value = userData.fullName ?? '';
        emailController.value = userData.email ?? '';

        if (kDebugMode) {
          print('✅ UserService data loaded successfully: ${userData.fullName}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading UserService data: $e');
      }
    } finally {
      isLoadingUserData.value = false;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate full name
  bool _isValidFullName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  /// Validate message
  bool _isValidMessage(String message) {
    return message.trim().isNotEmpty &&
           message.trim().length >= 10 &&
           message.trim().length <= 500;
  }

  /// Validate form fields
  bool validateForm() {
    bool isValid = true;

    // Validate full name
    if (!_isValidFullName(fullNameController.value)) {
      fullNameError.value = Constants.kFullNameisrequired;
      isValid = false;
    } else {
      fullNameError.value = null;
    }

    // Validate email
    if (emailController.value.isEmpty) {
      emailError.value = Constants.kEmailisrequired;
      isValid = false;
    } else if (!_isValidEmail(emailController.value)) {
      emailError.value = Constants.kEnteravalidemailaddress;
      isValid = false;
    } else {
      emailError.value = null;
    }

    // Validate message
    if (!_isValidMessage(messageController.value)) {
      if (messageController.value.trim().isEmpty) {
        messageError.value = 'Please enter a message';
      } else if (messageController.value.trim().length < 10) {
        messageError.value = 'Message must be at least 10 characters';
      } else {
        messageError.value = 'Message must not exceed 500 characters';
      }
      isValid = false;
    } else {
      messageError.value = null;
    }

    return isValid;
  }

  /// Submit help message
  Future<bool> submitHelpMessage() async {
    if (!validateForm()) {
      return false;
    }

    try {
      isLoading.value = true;

      // Enhanced authentication check with fallback to Firebase Auth
      final currentUser = UserService.currentUser.value ?? UserService.currentUserValue;
      final authUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null && authUser == null) {
        Get.snackbar(
          Constants.kError,
          Constants.kPleaseLoginFirst,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Use UserService data if available, otherwise fallback to Firebase Auth data
      final userData = currentUser ?? await _getFirebaseAuthUserData();

      if (userData == null) {
        Get.snackbar(
          Constants.kError,
          Constants.kPleaseLoginFirst,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Upload attachments if any
      final uploadedAttachmentUrls = await _uploadAttachments();

      // Submit help message with user data
      final success = await _helpDataSource.submitHelpMessage(
        fullName: fullNameController.value.trim().isNotEmpty
            ? fullNameController.value.trim()
            : (userData.fullName ?? authUser?.displayName ?? 'Unknown User'),
        email: emailController.value.trim().isNotEmpty
            ? emailController.value.trim()
            : (userData.email ?? authUser?.email ?? ''),
        message: messageController.value.trim(),
        requestType: selectedRequestType.value,
        priority: selectedPriority.value,
        attachmentUrls: uploadedAttachmentUrls,
      );

      if (success) {
        isSubmitted.value = true;

        // Clear form and reload user data
        resetFormAfterSubmission();

        // Show success message
        Get.snackbar(
          Constants.kSuccess,
          'Thank you! Your help request has been submitted successfully. We will respond to you within 24 hours.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
          backgroundColor:ColorsManager.offWhite,
          colorText: ColorsManager.success,
        );

        // Refresh user messages
        await _loadUserHelpMessages();

        return true;
      } else {
        Get.snackbar(
          Constants.kError,
          Constants.kSomethingWentWrong,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting help message: $e');
      }

      Get.snackbar(
        Constants.kError,
        Constants.kSomethingWentWrong,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Upload attachments to Firebase Storage
  /// Returns list of download URLs for uploaded files
  Future<List<String>?> _uploadAttachments() async {
    if (attachmentFiles.isEmpty) return null;

    try {
      final uploadedUrls = <String>[];
      final currentUser = UserService.currentUser.value ?? UserService.currentUserValue;
      final authUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null && authUser == null) {
        if (kDebugMode) {
          print('No authenticated user for file upload');
        }
        return null;
      }
      
      final userId = currentUser?.uid ?? authUser?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Upload each file to Firebase Storage
      for (int i = 0; i < attachmentFiles.length; i++) {
        final filePath = attachmentFiles[i];
        final file = File(filePath);
        
        if (!await file.exists()) {
          if (kDebugMode) {
            print('File does not exist: $filePath');
          }
          continue;
        }
        
        // Generate unique filename
        final fileExtension = filePath.split('.').last;
        final fileName = 'help_attachment_${userId}_${timestamp}_$i.$fileExtension';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('help_attachments')
            .child(userId)
            .child(fileName);
        
        // Upload file with metadata
        final metadata = SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': timestamp.toString(),
            'originalName': filePath.split('/').last,
          },
        );
        
        if (kDebugMode) {
          print('Uploading file: $fileName');
        }
        
        // Upload file
        final uploadTask = await storageRef.putFile(file, metadata);
        
        // Get download URL
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
        
        if (kDebugMode) {
          print('File uploaded successfully: $downloadUrl');
        }
      }
      
      return uploadedUrls.isNotEmpty ? uploadedUrls : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading attachments: $e');
      }
      
      Get.snackbar(
        'Upload Error',
        'Some files could not be uploaded. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorsManager.error,
        colorText: ColorsManager.white,
      );
      
      return null;
    }
  }
  
  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Pick files for attachment
  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        attachmentFiles.addAll(result.files.map((file) => file.path!).where((path) => path != null));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking files: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to select files',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick images for attachment
  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxHeight: 1800,
        maxWidth: 1800,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        attachmentFiles.addAll(images.map((image) => image.path));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking images: $e');
      }
      Get.snackbar(
        'Error',
        'Failed to select images',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove attachment at index
  void removeAttachment(int index) {
    if (index >= 0 && index < attachmentFiles.length) {
      attachmentFiles.removeAt(index);
    }
  }

  /// Clear all attachments
  void clearAttachments() {
    attachmentFiles.clear();
  }

  /// Update message text
  void updateMessage(String value) {
    messageController.value = value;
    // Clear error when user starts typing
    if (messageError.value != null && value.trim().isNotEmpty) {
      messageError.value = null;
    }
  }

  /// Update request type
  void updateRequestType(RequestType type) {
    selectedRequestType.value = type;
  }

  /// Update priority
  void updatePriority(String priority) {
    selectedPriority.value = priority;
  }

  /// Get user data from Firebase Auth if UserService data is not available
  Future<SocialMediaUser?> _getFirebaseAuthUserData() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return null;

      // Try to get user data from UserService first
      final userServiceData = await UserService().getProfile(authUser.uid);
      if (userServiceData != null) {
        return userServiceData;
      }

      // Fallback to creating user data from Firebase Auth
      return SocialMediaUser(
        uid: authUser.uid,
        fullName: authUser.displayName ?? 'Unknown User',
        email: authUser.email ?? '',
        imageUrl: authUser.photoURL ?? '',
        provider: authUser.providerData.isNotEmpty ? authUser.providerData.first.providerId : '',
        phoneNumber: authUser.phoneNumber ?? '',
        privacySettings: PrivacySettings.defaultSettings(),
        chatSettings: ChatSettings.defaultSettings(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting Firebase Auth user data: $e');
      }
      return null;
    }
  }

  /// Load user's help messages
  Future<void> _loadUserHelpMessages() async {
    try {
      final currentUser = UserService.currentUser.value ?? UserService.currentUserValue;
      final authUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null && authUser == null) {
        if (kDebugMode) {
          print('No authenticated user found for loading help messages');
        }
        return;
      }

      _helpDataSource.getUserHelpMessages().listen((messages) {
        userHelpMessages.assignAll(messages);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user help messages: $e');
      }
    }
  }

  /// Update full name field
  void updateFullName(String value) {
    fullNameController.value = value;
    if (fullNameError.value != null && _isValidFullName(value)) {
      fullNameError.value = null;
    }
  }

  /// Update email field
  void updateEmail(String value) {
    emailController.value = value;
    if (emailError.value != null && _isValidEmail(value)) {
      emailError.value = null;
    }
  }

  /// Reset form after successful submission
  void resetFormAfterSubmission() {
    clearForm();
    isSubmitted.value = false;
    clearAttachments();
    selectedRequestType.value = RequestType.support;
    selectedPriority.value = 'medium';
    // Reload user data to ensure form is pre-filled correctly
    _loadUserData();
  }

  /// Clear form fields
  void clearForm() {
    fullNameController.value = '';
    emailController.value = '';
    messageController.value = '';
    fullNameError.value = null;
    emailError.value = null;
    messageError.value = null;
  }

  /// Reset submission state
  void resetSubmission() {
    isSubmitted.value = false;
  }

  /// Get status color for help message
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA500); // Orange
      case 'in_progress':
        return const Color(0xFF2196F3); // Blue
      case 'resolved':
        return const Color(0xFF4CAF50); // Green
      case 'closed':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Get status text for help message
  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Check if user is authenticated
  bool get isUserAuthenticated {
    return UserService.currentUser.value != null ||
           UserService.currentUserValue != null ||
           FirebaseAuth.instance.currentUser != null;
  }
}

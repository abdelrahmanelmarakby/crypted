// ARCH-001 FIX: Group Management Controller
// Extracted group management logic from ChatController

import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Controller responsible for group chat management operations
/// Extracted from ChatController to follow Single Responsibility Principle
class GroupManagementController extends GetxController {
  final IChatRepository _repository;
  final ErrorHandler _errorHandler;
  final ImagePicker _imagePicker;

  /// Group info observables
  final RxString groupName = ''.obs;
  final RxString groupDescription = ''.obs;
  final RxString groupImageUrl = ''.obs;
  final RxInt memberCount = 0.obs;
  final RxList<SocialMediaUser> members = <SocialMediaUser>[].obs;
  final RxList<String> adminIds = <String>[].obs;

  /// Loading states
  final RxBool isUpdatingInfo = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isAddingMember = false.obs;
  final RxBool isRemovingMember = false.obs;

  /// Current room ID
  String roomId = '';

  GroupManagementController({
    required IChatRepository repository,
    ErrorHandler? errorHandler,
    ImagePicker? imagePicker,
  })  : _repository = repository,
        _errorHandler = errorHandler ?? ErrorHandler(),
        _imagePicker = imagePicker ?? ImagePicker();

  /// Initialize with room data
  void initialize({
    required String roomId,
    required String name,
    required String description,
    required String imageUrl,
    required List<SocialMediaUser> membersList,
    required List<String> admins,
  }) {
    this.roomId = roomId;
    groupName.value = name;
    groupDescription.value = description;
    groupImageUrl.value = imageUrl;
    members.value = membersList;
    memberCount.value = membersList.length;
    adminIds.value = admins;
  }

  // =================== GROUP INFO OPERATIONS ===================

  /// Update group name
  Future<bool> updateGroupName(String newName) async {
    if (newName.isEmpty || newName == groupName.value) return false;

    try {
      isUpdatingInfo.value = true;

      final success = await _repository.updateChatRoom(
        roomId: roomId,
        name: newName,
      );

      if (success) {
        groupName.value = newName;
        _showToast('Group name updated');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'updateGroupName');
      return false;
    } finally {
      isUpdatingInfo.value = false;
    }
  }

  /// Update group description
  Future<bool> updateGroupDescription(String newDescription) async {
    if (newDescription == groupDescription.value) return false;

    try {
      isUpdatingInfo.value = true;

      final success = await _repository.updateChatRoom(
        roomId: roomId,
        description: newDescription,
      );

      if (success) {
        groupDescription.value = newDescription;
        _showToast('Group description updated');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'updateGroupDescription');
      return false;
    } finally {
      isUpdatingInfo.value = false;
    }
  }

  /// Update group info (name and/or description)
  Future<bool> updateGroupInfo({
    String? name,
    String? description,
  }) async {
    try {
      isUpdatingInfo.value = true;

      final success = await _repository.updateChatRoom(
        roomId: roomId,
        name: name,
        description: description,
      );

      if (success) {
        if (name != null) groupName.value = name;
        if (description != null) groupDescription.value = description;
        _showToast('Group info updated');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'updateGroupInfo');
      return false;
    } finally {
      isUpdatingInfo.value = false;
    }
  }

  // =================== GROUP IMAGE OPERATIONS ===================

  /// Change group photo from camera or gallery
  Future<bool> changeGroupPhoto({required bool fromCamera}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile == null) return false;

      isUploadingImage.value = true;

      // Upload to Firebase Storage
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('$roomId.jpg');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update in Firestore
      final success = await _repository.updateChatRoom(
        roomId: roomId,
        imageUrl: downloadUrl,
      );

      if (success) {
        groupImageUrl.value = downloadUrl;
        _showToast('Group photo updated');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'changeGroupPhoto');
      return false;
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// Remove group photo
  Future<bool> removeGroupPhoto() async {
    try {
      isUploadingImage.value = true;

      // Delete from storage if exists
      if (groupImageUrl.value.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('group_images')
              .child('$roomId.jpg');
          await storageRef.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete old group image: $e');
          }
        }
      }

      // Update in Firestore
      final success = await _repository.updateChatRoom(
        roomId: roomId,
        imageUrl: '',
      );

      if (success) {
        groupImageUrl.value = '';
        _showToast('Group photo removed');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'removeGroupPhoto');
      return false;
    } finally {
      isUploadingImage.value = false;
    }
  }

  // =================== MEMBER OPERATIONS ===================

  /// Add a member to the group
  Future<bool> addMember(SocialMediaUser member) async {
    if (members.any((m) => m.uid == member.uid)) {
      _showToast('Member already in group');
      return false;
    }

    try {
      isAddingMember.value = true;

      final success = await _repository.addMember(
        roomId: roomId,
        member: member,
      );

      if (success) {
        members.add(member);
        memberCount.value = members.length;
        _showToast('${member.fullName} added to group');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'addMember');
      return false;
    } finally {
      isAddingMember.value = false;
    }
  }

  /// Add multiple members to the group
  Future<int> addMembers(List<SocialMediaUser> newMembers) async {
    int successCount = 0;

    isAddingMember.value = true;

    for (final member in newMembers) {
      if (!members.any((m) => m.uid == member.uid)) {
        final success = await _repository.addMember(
          roomId: roomId,
          member: member,
        );

        if (success) {
          members.add(member);
          successCount++;
        }
      }
    }

    memberCount.value = members.length;
    isAddingMember.value = false;

    if (successCount > 0) {
      _showToast('$successCount member(s) added');
    }

    return successCount;
  }

  /// Remove a member from the group
  Future<bool> removeMember(String memberId) async {
    final memberToRemove = members.firstWhereOrNull((m) => m.uid == memberId);
    if (memberToRemove == null) {
      _showToast('Member not found');
      return false;
    }

    try {
      isRemovingMember.value = true;

      final success = await _repository.removeMember(
        roomId: roomId,
        memberId: memberId,
      );

      if (success) {
        members.removeWhere((m) => m.uid == memberId);
        memberCount.value = members.length;
        _showToast('${memberToRemove.fullName} removed from group');
      }

      return success;
    } catch (e) {
      _errorHandler.handle(e, context: 'removeMember');
      return false;
    } finally {
      isRemovingMember.value = false;
    }
  }

  /// Leave the group
  Future<bool> leaveGroup(String currentUserId) async {
    return await removeMember(currentUserId);
  }

  /// Check if user is admin
  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Get member by ID
  SocialMediaUser? getMemberById(String id) {
    return members.firstWhereOrNull((m) => m.uid == id);
  }

  // =================== HELPERS ===================

  void _showToast(String message) {
    BotToast.showText(
      text: message,
      duration: const Duration(seconds: 2),
    );
  }
}

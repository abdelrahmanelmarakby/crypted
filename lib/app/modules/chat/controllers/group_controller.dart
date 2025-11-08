import 'dart:io';
import 'package:crypted_app/app/core/exceptions/app_exceptions.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/core/services/error_handler_service.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

/// Group Controller - Handles all group chat operations
///
/// Responsibilities:
/// - Add/remove members
/// - Manage group admins
/// - Update group info (name, description, image)
/// - Group permissions
/// - Member management
///
/// Features:
/// - Professional error handling
/// - Proper logging
/// - Validation
/// - Permission checks
class GroupController extends GetxController {
  final String roomId;

  GroupController({required this.roomId});

  // Group state
  final RxBool isGroupChat = false.obs;
  final RxString groupName = ''.obs;
  final RxString groupDescription = ''.obs;
  final RxString groupImageUrl = ''.obs;
  final RxList<SocialMediaUser> members = <SocialMediaUser>[].obs;
  final RxList<String> adminIds = <String>[].obs;
  final RxInt memberCount = 0.obs;

  // Services
  final _logger = LoggerService.instance;
  final _errorHandler = ErrorHandlerService.instance;

  // Firestore reference
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Getters
  SocialMediaUser? get currentUser => UserService.currentUser.value;
  bool get isCurrentUserAdmin => isUserAdmin(currentUser?.uid ?? '');

  @override
  void onInit() {
    super.onInit();
    _logger.info('GroupController initialized', context: 'GroupController', data: {
      'roomId': roomId,
    });
  }

  // ========== MEMBER MANAGEMENT ==========

  /// Add member to group
  Future<bool> addMember(SocialMediaUser newMember) async {
    if (!isGroupChat.value) {
      _errorHandler.handleError(
        ValidationException('groupType', 'Cannot add members to non-group chat'),
        context: 'GroupController.addMember',
        showToUser: true,
      );
      return false;
    }

    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can add members'),
        context: 'GroupController.addMember',
        showToUser: true,
      );
      return false;
    }

    // Check if member already exists
    if (isMember(newMember.uid!)) {
      _errorHandler.showWarning('العضو موجود بالفعل / Member already exists');
      return false;
    }

    _logger.debug('Adding member to group', context: 'GroupController', data: {
      'memberId': newMember.uid,
      'memberName': newMember.fullName,
    });

    try {
      // Add via ChatSessionManager if available
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        final success = sessionManager.addMember(newMember);
        if (success) {
          members.value = sessionManager.members;
          memberCount.value = members.length;

          _logger.info('Member added successfully', context: 'GroupController');
          _errorHandler.showSuccess(
            'تمت إضافة ${newMember.fullName} / ${newMember.fullName} added',
          );

          return true;
        }
      } else {
        // Fallback: Add directly to local state
        members.add(newMember);
        memberCount.value = members.length;

        _logger.info('Member added successfully (fallback)', context: 'GroupController');
        _errorHandler.showSuccess(
          'تمت إضافة ${newMember.fullName} / ${newMember.fullName} added',
        );

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.addMember',
        showToUser: true,
      );
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMember(String userId) async {
    if (!isGroupChat.value) {
      _errorHandler.handleError(
        ValidationException('groupType', 'Cannot remove members from non-group chat'),
        context: 'GroupController.removeMember',
        showToUser: true,
      );
      return false;
    }

    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can remove members'),
        context: 'GroupController.removeMember',
        showToUser: true,
      );
      return false;
    }

    // Cannot remove current user
    if (userId == currentUser?.uid) {
      _errorHandler.showWarning('لا يمكن إزالة نفسك / Cannot remove yourself');
      return false;
    }

    _logger.debug('Removing member from group', context: 'GroupController', data: {
      'userId': userId,
    });

    try {
      // Remove via ChatSessionManager if available
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        final success = sessionManager.removeMember(userId);
        if (success) {
          members.value = sessionManager.members;
          memberCount.value = members.length;

          _logger.info('Member removed successfully', context: 'GroupController');
          _errorHandler.showSuccess('تمت الإزالة / Member removed');

          // Check if group still has enough members
          if (members.length < 2) {
            _errorHandler.showWarning('المجموعة تحتاج عضوين على الأقل / Group needs at least 2 members');
            return false;
          }

          return true;
        }
      } else {
        // Fallback: Remove from local state
        members.removeWhere((member) => member.uid == userId);
        memberCount.value = members.length;

        _logger.info('Member removed successfully (fallback)', context: 'GroupController');
        _errorHandler.showSuccess('تمت الإزالة / Member removed');

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.removeMember',
        showToUser: true,
      );
      return false;
    }
  }

  // ========== ADMIN MANAGEMENT ==========

  /// Make user admin
  Future<bool> makeAdmin(String userId) async {
    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can make other admins'),
        context: 'GroupController.makeAdmin',
        showToUser: true,
      );
      return false;
    }

    if (adminIds.contains(userId)) {
      _errorHandler.showInfo('العضو مسؤول بالفعل / Already an admin');
      return false;
    }

    _logger.debug('Making user admin', context: 'GroupController', data: {
      'userId': userId,
    });

    try {
      adminIds.add(userId);

      await _firestore.collection('chats').doc(roomId).update({
        'adminIds': adminIds.toList(),
      });

      _logger.info('User made admin', context: 'GroupController');
      _errorHandler.showSuccess('تمت ترقيته لمسؤول / Promoted to admin');

      return true;
    } catch (e, stackTrace) {
      adminIds.remove(userId); // Rollback

      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.makeAdmin',
        showToUser: true,
      );
      return false;
    }
  }

  /// Remove admin privileges
  Future<bool> removeAdmin(String userId) async {
    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can remove other admins'),
        context: 'GroupController.removeAdmin',
        showToUser: true,
      );
      return false;
    }

    // Must have at least one admin
    if (adminIds.length <= 1) {
      _errorHandler.showWarning(
        'المجموعة تحتاج مسؤول واحد على الأقل / Group needs at least one admin',
      );
      return false;
    }

    _logger.debug('Removing admin privileges', context: 'GroupController', data: {
      'userId': userId,
    });

    try {
      adminIds.remove(userId);

      await _firestore.collection('chats').doc(roomId).update({
        'adminIds': adminIds.toList(),
      });

      _logger.info('Admin privileges removed', context: 'GroupController');
      _errorHandler.showSuccess('تمت إزالة صلاحيات المسؤول / Admin removed');

      return true;
    } catch (e, stackTrace) {
      adminIds.add(userId); // Rollback

      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.removeAdmin',
        showToUser: true,
      );
      return false;
    }
  }

  // ========== GROUP INFO MANAGEMENT ==========

  /// Update group name
  Future<bool> updateGroupName(String name) async {
    if (name.trim().isEmpty) {
      _errorHandler.handleValidationError('groupName', 'اسم المجموعة مطلوب / Group name required');
      return false;
    }

    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can update group name'),
        context: 'GroupController.updateGroupName',
        showToUser: true,
      );
      return false;
    }

    _logger.debug('Updating group name', context: 'GroupController', data: {
      'newName': name,
    });

    try {
      // Update via ChatSessionManager if available
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        sessionManager.updateGroupInfo(name: name);
        groupName.value = sessionManager.chatName;
      } else {
        groupName.value = name;
      }

      // Update Firestore
      await _firestore.collection('chats').doc(roomId).update({
        'groupName': name,
      });

      _logger.info('Group name updated', context: 'GroupController');
      _errorHandler.showSuccess('تم تحديث الاسم / Name updated');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.updateGroupName',
        showToUser: true,
      );
      return false;
    }
  }

  /// Update group description
  Future<bool> updateGroupDescription(String description) async {
    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can update group description'),
        context: 'GroupController.updateGroupDescription',
        showToUser: true,
      );
      return false;
    }

    _logger.debug('Updating group description', context: 'GroupController');

    try {
      // Update via ChatSessionManager if available
      final sessionManager = ChatSessionManager.instance;
      if (sessionManager.hasActiveSession) {
        sessionManager.updateGroupInfo(description: description);
        groupDescription.value = sessionManager.chatDescription;
      } else {
        groupDescription.value = description;
      }

      // Update Firestore
      await _firestore.collection('chats').doc(roomId).update({
        'groupDescription': description,
      });

      _logger.info('Group description updated', context: 'GroupController');
      _errorHandler.showSuccess('تم تحديث الوصف / Description updated');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.updateGroupDescription',
        showToUser: true,
      );
      return false;
    }
  }

  /// Update group image
  Future<bool> updateGroupImage(File imageFile) async {
    if (!isCurrentUserAdmin) {
      _errorHandler.handleError(
        PermissionException('admin', 'Only admins can update group image'),
        context: 'GroupController.updateGroupImage',
        showToUser: true,
      );
      return false;
    }

    _logger.debug('Updating group image', context: 'GroupController');

    try {
      // Upload to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_group_image.jpg';
      final ref = _storage.ref().child('groups/$roomId/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('chats').doc(roomId).update({
        'groupImageUrl': downloadUrl,
      });

      groupImageUrl.value = downloadUrl;

      _logger.info('Group image updated', context: 'GroupController', data: {
        'url': downloadUrl,
      });
      _errorHandler.showSuccess('تم تحديث الصورة / Image updated');

      return true;
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.updateGroupImage',
        showToUser: true,
      );
      return false;
    }
  }

  // ========== PERMISSION CHECKS ==========

  /// Check if user is a member
  bool isMember(String userId) {
    return members.any((member) => member.uid == userId);
  }

  /// Check if user is admin
  bool isUserAdmin(String userId) {
    return adminIds.contains(userId);
  }

  /// Check if user can send messages
  bool canUserSendMessages(String userId) {
    // For now, all members can send messages
    // Can be extended with more granular permissions
    return isMember(userId);
  }

  /// Check if user can add members
  bool canUserAddMembers(String userId) {
    return isUserAdmin(userId);
  }

  /// Check if user can remove members
  bool canUserRemoveMembers(String userId) {
    return isUserAdmin(userId);
  }

  // ========== UTILITY METHODS ==========

  /// Get member by ID
  SocialMediaUser? getMemberById(String userId) {
    try {
      return members.firstWhere((member) => member.uid == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get other members (excluding current user)
  List<SocialMediaUser> getOtherMembers() {
    return members.where((member) => member.uid != currentUser?.uid).toList();
  }

  /// Get admin members
  List<SocialMediaUser> getAdmins() {
    return members.where((member) => adminIds.contains(member.uid)).toList();
  }

  /// Load group info from Firestore
  Future<void> loadGroupInfo() async {
    try {
      _logger.debug('Loading group info', context: 'GroupController');

      final doc = await _firestore.collection('chats').doc(roomId).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          groupName.value = data['groupName'] ?? '';
          groupDescription.value = data['groupDescription'] ?? '';
          groupImageUrl.value = data['groupImageUrl'] ?? '';
          adminIds.value = List<String>.from(data['adminIds'] ?? []);
          isGroupChat.value = data['isGroup'] ?? false;

          _logger.info('Group info loaded', context: 'GroupController');
        }
      }
    } catch (e, stackTrace) {
      _errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        context: 'GroupController.loadGroupInfo',
        showToUser: false,
      );
    }
  }

  @override
  void onClose() {
    _logger.info('GroupController disposed', context: 'GroupController');
    super.onClose();
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';
import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:flutter/foundation.dart';

/// Implementation of IGroupRepository
///
/// Handles all group operations with:
/// - Atomic transactions for member operations
/// - System message generation
/// - Event emission for real-time updates
/// - Role-based permission validation
class GroupRepositoryImpl implements IGroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final EventBus _eventBus;

  GroupRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required EventBus eventBus,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _eventBus = eventBus;

  // Collection references
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // =================== Member Operations ===================

  @override
  Future<Result<MemberOperationResult, RepositoryError>> addMember({
    required String groupId,
    required SocialMediaUser member,
    required String addedByUserId,
  }) async {
    try {
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        // 1. Get current group data
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['membersIds'] ?? []);
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);

        // 2. Check if already a member
        if (memberIds.contains(member.uid)) {
          throw Exception('User is already a member');
        }

        // 3. Check member limit
        if (memberIds.length >= kMaxGroupMembers) {
          throw Exception('Group has reached maximum member limit');
        }

        // 4. Add member
        memberIds.add(member.uid!);
        members.add(member.toMap());

        // 5. Update keywords for search
        final keywords = List<String>.from(data['keywords'] ?? []);
        _addMemberKeywords(keywords, member);

        // 6. Update group
        transaction.update(groupRef, {
          'membersIds': memberIds,
          'members': members,
          'keywords': keywords,
          'lastMsg': '${member.fullName ?? 'Someone'} joined the group',
          'lastChat': FieldValue.serverTimestamp(),
        });

        // 7. Add system message
        final systemMsgRef = groupRef.collection('chat').doc();
        transaction.set(systemMsgRef, {
          'type': 'system',
          'text': '${member.fullName ?? 'Someone'} was added to the group',
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'action': 'member_added',
            'memberId': member.uid,
            'memberName': member.fullName,
            'addedBy': addedByUserId,
          },
        });
        systemMessageId = systemMsgRef.id;
      });

      // Emit event
      _eventBus.emit(GroupMemberAddedEvent(
        roomId: groupId,
        memberId: member.uid!,
        memberName: member.fullName ?? 'Unknown',
        addedByUserId: addedByUserId,
        systemMessageId: systemMessageId,
      ));

      if (kDebugMode) {
        print('✅ Member added: ${member.fullName}');
      }

      return Result.success(MemberOperationResult(
        memberId: member.uid!,
        memberName: member.fullName ?? 'Unknown',
        success: true,
        systemMessageId: systemMessageId,
      ));
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Error adding member: $e');
      }
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<MemberOperationResult>, RepositoryError>> addMembers({
    required String groupId,
    required List<SocialMediaUser> members,
    required String addedByUserId,
  }) async {
    final results = <MemberOperationResult>[];

    for (final member in members) {
      final result = await addMember(
        groupId: groupId,
        member: member,
        addedByUserId: addedByUserId,
      );

      result.fold(
        onSuccess: (opResult) => results.add(opResult),
        onFailure: (error) => results.add(MemberOperationResult(
          memberId: member.uid ?? '',
          memberName: member.fullName ?? 'Unknown',
          success: false,
        )),
      );
    }

    return Result.success(results);
  }

  @override
  Future<Result<MemberOperationResult, RepositoryError>> removeMember({
    required String groupId,
    required String memberId,
    required String removedByUserId,
  }) async {
    try {
      String? memberName;
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        // 1. Get current group data
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['membersIds'] ?? []);
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        final adminIds = List<String>.from(data['adminIds'] ?? []);
        final createdBy = data['createdBy'] as String?;

        // 2. Check if member exists
        if (!memberIds.contains(memberId)) {
          throw Exception('User is not a member');
        }

        // 3. Cannot remove creator
        if (createdBy == memberId) {
          throw Exception('Cannot remove the group creator');
        }

        // 4. Check minimum members
        if (memberIds.length <= kMinGroupMembers) {
          throw Exception('Group must have at least one member');
        }

        // 5. Get member name before removing
        final memberData = members.firstWhere(
          (m) => m['uid'] == memberId,
          orElse: () => <String, dynamic>{},
        );
        memberName = memberData['fullName'] as String? ?? 'Unknown';

        // 6. Remove member
        memberIds.remove(memberId);
        members.removeWhere((m) => m['uid'] == memberId);

        // Also remove from admins if applicable
        adminIds.remove(memberId);

        // 7. Update group
        transaction.update(groupRef, {
          'membersIds': memberIds,
          'members': members,
          'adminIds': adminIds,
          'lastMsg': '$memberName was removed from the group',
          'lastChat': FieldValue.serverTimestamp(),
        });

        // 8. Add system message
        final systemMsgRef = groupRef.collection('chat').doc();
        transaction.set(systemMsgRef, {
          'type': 'system',
          'text': '$memberName was removed from the group',
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'action': 'member_removed',
            'memberId': memberId,
            'memberName': memberName,
            'removedBy': removedByUserId,
          },
        });
        systemMessageId = systemMsgRef.id;
      });

      // Emit event
      _eventBus.emit(GroupMemberRemovedEvent(
        roomId: groupId,
        memberId: memberId,
        memberName: memberName ?? 'Unknown',
        removedByUserId: removedByUserId,
        systemMessageId: systemMessageId,
      ));

      if (kDebugMode) {
        print('✅ Member removed: $memberName');
      }

      return Result.success(MemberOperationResult(
        memberId: memberId,
        memberName: memberName ?? 'Unknown',
        success: true,
        systemMessageId: systemMessageId,
      ));
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Error removing member: $e');
      }
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      String? memberName;
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        // 1. Get current group data
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['membersIds'] ?? []);
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        final adminIds = List<String>.from(data['adminIds'] ?? []);

        // 2. Check if member exists
        if (!memberIds.contains(userId)) {
          throw Exception('You are not a member of this group');
        }

        // 3. Get member name
        final memberData = members.firstWhere(
          (m) => m['uid'] == userId,
          orElse: () => <String, dynamic>{},
        );
        memberName = memberData['fullName'] as String? ?? 'Unknown';

        // 4. Check if only admin leaving
        final isOnlyAdmin = adminIds.length == 1 && adminIds.contains(userId);
        final hasOtherMembers = memberIds.length > 1;

        if (isOnlyAdmin && hasOtherMembers) {
          throw Exception('You must transfer admin role before leaving');
        }

        // 5. Remove member
        memberIds.remove(userId);
        members.removeWhere((m) => m['uid'] == userId);
        adminIds.remove(userId);

        // 6. If last member, mark group as deleted
        if (memberIds.isEmpty) {
          transaction.update(groupRef, {
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Update group
          transaction.update(groupRef, {
            'membersIds': memberIds,
            'members': members,
            'adminIds': adminIds,
            'lastMsg': '$memberName left the group',
            'lastChat': FieldValue.serverTimestamp(),
          });

          // Add system message
          final systemMsgRef = groupRef.collection('chat').doc();
          transaction.set(systemMsgRef, {
            'type': 'system',
            'text': '$memberName left the group',
            'senderId': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'metadata': {
              'action': 'member_left',
              'memberId': userId,
              'memberName': memberName,
            },
          });
          systemMessageId = systemMsgRef.id;
        }
      });

      // Emit event
      _eventBus.emit(GroupMemberLeftEvent(
        roomId: groupId,
        memberId: userId,
        memberName: memberName ?? 'Unknown',
        systemMessageId: systemMessageId,
      ));

      if (kDebugMode) {
        print('✅ Left group: $memberName');
      }

      return Result.success(null);
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Error leaving group: $e');
      }
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Admin Operations ===================

  @override
  Future<Result<void, RepositoryError>> makeAdmin({
    required String groupId,
    required String memberId,
    required String promotedByUserId,
  }) async {
    try {
      String? memberName;
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(data['membersIds'] ?? []);
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        final adminIds = List<String>.from(data['adminIds'] ?? []);

        // Check member exists
        if (!memberIds.contains(memberId)) {
          throw Exception('User is not a member');
        }

        // Check not already admin
        if (adminIds.contains(memberId)) {
          throw Exception('User is already an admin');
        }

        // Get member name
        final memberData = members.firstWhere(
          (m) => m['uid'] == memberId,
          orElse: () => <String, dynamic>{},
        );
        memberName = memberData['fullName'] as String? ?? 'Unknown';

        // Add to admins
        adminIds.add(memberId);

        transaction.update(groupRef, {
          'adminIds': adminIds,
        });

        // Add system message
        final systemMsgRef = groupRef.collection('chat').doc();
        transaction.set(systemMsgRef, {
          'type': 'system',
          'text': '$memberName is now an admin',
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'action': 'admin_added',
            'memberId': memberId,
            'memberName': memberName,
            'promotedBy': promotedByUserId,
          },
        });
        systemMessageId = systemMsgRef.id;
      });

      // Emit event
      _eventBus.emit(GroupAdminChangedEvent(
        roomId: groupId,
        memberId: memberId,
        memberName: memberName ?? 'Unknown',
        isNowAdmin: true,
        changedByUserId: promotedByUserId,
        systemMessageId: systemMessageId,
      ));

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> removeAdmin({
    required String groupId,
    required String memberId,
    required String demotedByUserId,
  }) async {
    try {
      String? memberName;
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        final adminIds = List<String>.from(data['adminIds'] ?? []);
        final createdBy = data['createdBy'] as String?;

        // Cannot demote creator
        if (createdBy == memberId) {
          throw Exception('Cannot demote the group creator');
        }

        // Check is admin
        if (!adminIds.contains(memberId)) {
          throw Exception('User is not an admin');
        }

        // Check at least one admin remains
        if (adminIds.length <= 1) {
          throw Exception('Group must have at least one admin');
        }

        // Get member name
        final memberData = members.firstWhere(
          (m) => m['uid'] == memberId,
          orElse: () => <String, dynamic>{},
        );
        memberName = memberData['fullName'] as String? ?? 'Unknown';

        // Remove from admins
        adminIds.remove(memberId);

        transaction.update(groupRef, {
          'adminIds': adminIds,
        });

        // Add system message
        final systemMsgRef = groupRef.collection('chat').doc();
        transaction.set(systemMsgRef, {
          'type': 'system',
          'text': '$memberName is no longer an admin',
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'action': 'admin_removed',
            'memberId': memberId,
            'memberName': memberName,
            'demotedBy': demotedByUserId,
          },
        });
        systemMessageId = systemMsgRef.id;
      });

      // Emit event
      _eventBus.emit(GroupAdminChangedEvent(
        roomId: groupId,
        memberId: memberId,
        memberName: memberName ?? 'Unknown',
        isNowAdmin: false,
        changedByUserId: demotedByUserId,
        systemMessageId: systemMessageId,
      ));

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> transferOwnership({
    required String groupId,
    required String newOwnerId,
    required String currentOwnerId,
  }) async {
    try {
      String? newOwnerName;
      String? systemMessageId;

      await _firestore.runTransaction((transaction) async {
        final groupRef = _chatsCollection.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found');
        }

        final data = groupDoc.data() as Map<String, dynamic>;
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
        final adminIds = List<String>.from(data['adminIds'] ?? []);
        final createdBy = data['createdBy'] as String?;

        // Verify current owner
        if (createdBy != currentOwnerId) {
          throw Exception('Only the creator can transfer ownership');
        }

        // Get new owner name
        final newOwnerData = members.firstWhere(
          (m) => m['uid'] == newOwnerId,
          orElse: () => <String, dynamic>{},
        );
        newOwnerName = newOwnerData['fullName'] as String? ?? 'Unknown';

        // Add new owner to admins if not already
        if (!adminIds.contains(newOwnerId)) {
          adminIds.add(newOwnerId);
        }

        // Keep old owner as admin
        if (!adminIds.contains(currentOwnerId)) {
          adminIds.add(currentOwnerId);
        }

        transaction.update(groupRef, {
          'createdBy': newOwnerId,
          'adminIds': adminIds,
        });

        // Add system message
        final systemMsgRef = groupRef.collection('chat').doc();
        transaction.set(systemMsgRef, {
          'type': 'system',
          'text': '$newOwnerName is now the group owner',
          'senderId': 'system',
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'action': 'ownership_transferred',
            'previousOwner': currentOwnerId,
            'newOwner': newOwnerId,
            'newOwnerName': newOwnerName,
          },
        });
        systemMessageId = systemMsgRef.id;
      });

      // Emit event
      _eventBus.emit(GroupOwnershipTransferredEvent(
        roomId: groupId,
        previousOwnerId: currentOwnerId,
        newOwnerId: newOwnerId,
        newOwnerName: newOwnerName ?? 'Unknown',
        systemMessageId: systemMessageId,
      ));

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Group Info Operations ===================

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupName({
    required String groupId,
    required String newName,
    required String updatedByUserId,
  }) async {
    try {
      await _chatsCollection.doc(groupId).update({
        'groupName': newName,
        'keywords': FieldValue.arrayUnion(newName.toLowerCase().split(' ')),
      });

      // Add system message
      final systemMsgRef =
          await _chatsCollection.doc(groupId).collection('chat').add({
        'type': 'system',
        'text': 'Group name changed to "$newName"',
        'senderId': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'action': 'name_changed',
          'newName': newName,
          'changedBy': updatedByUserId,
        },
      });

      // Emit event
      _eventBus.emit(GroupInfoUpdatedEvent(
        roomId: groupId,
        updatedFields: {'groupName': newName},
        updatedByUserId: updatedByUserId,
        systemMessageId: systemMsgRef.id,
      ));

      return Result.success(GroupUpdateResult(
        groupId: groupId,
        updatedFields: {'groupName': newName},
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupDescription({
    required String groupId,
    required String newDescription,
    required String updatedByUserId,
  }) async {
    try {
      await _chatsCollection.doc(groupId).update({
        'groupDescription': newDescription,
      });

      // Emit event
      _eventBus.emit(GroupInfoUpdatedEvent(
        roomId: groupId,
        updatedFields: {'groupDescription': newDescription},
        updatedByUserId: updatedByUserId,
      ));

      return Result.success(GroupUpdateResult(
        groupId: groupId,
        updatedFields: {'groupDescription': newDescription},
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<GroupUpdateResult, RepositoryError>> updateGroupImage({
    required String groupId,
    required String imagePath,
    required String updatedByUserId,
  }) async {
    try {
      // 1. Upload image to storage
      final file = File(imagePath);
      final ref = _storage.ref().child('group_images/$groupId.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // 2. Update Firestore
      await _chatsCollection.doc(groupId).update({
        'groupImageUrl': imageUrl,
      });

      // Emit event
      _eventBus.emit(GroupInfoUpdatedEvent(
        roomId: groupId,
        updatedFields: {'groupImageUrl': imageUrl},
        updatedByUserId: updatedByUserId,
      ));

      return Result.success(GroupUpdateResult(
        groupId: groupId,
        updatedFields: {'groupImageUrl': imageUrl},
        newImageUrl: imageUrl,
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<void, RepositoryError>> updatePermissions({
    required String groupId,
    required GroupPermissions permissions,
    required String updatedByUserId,
  }) async {
    try {
      await _chatsCollection.doc(groupId).update({
        'permissions': permissions.toMap(),
      });

      // Emit event
      _eventBus.emit(GroupPermissionsUpdatedEvent(
        roomId: groupId,
        newPermissions: permissions.toMap(),
        updatedByUserId: updatedByUserId,
      ));

      return Result.success(null);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Query Operations ===================

  @override
  Future<Result<GroupInfo, RepositoryError>> getGroupInfo(String groupId) async {
    try {
      final doc = await _chatsCollection.doc(groupId).get();

      if (!doc.exists) {
        return Result.failure(RepositoryError.notFound('Group'));
      }

      final data = doc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['membersIds'] ?? []);
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final adminIds = List<String>.from(data['adminIds'] ?? []);
      final createdBy = data['createdBy'] as String? ?? '';

      // Convert members to GroupMember objects
      final groupMembers = members.map((m) {
        final id = m['uid'] as String? ?? '';
        final isCreator = id == createdBy;
        final isAdmin = adminIds.contains(id);

        return GroupMember(
          id: id,
          name: m['fullName'] as String? ?? 'Unknown',
          avatarUrl: m['imageUrl'] as String?,
          role: isCreator
              ? GroupRole.creator
              : isAdmin
                  ? GroupRole.admin
                  : GroupRole.member,
        );
      }).toList();

      return Result.success(GroupInfo(
        id: groupId,
        name: data['groupName'] as String? ?? 'Group',
        description: data['groupDescription'] as String?,
        imageUrl: data['groupImageUrl'] as String?,
        members: groupMembers,
        createdBy: createdBy,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        permissions: GroupPermissions.fromMap(
          data['permissions'] as Map<String, dynamic>?,
        ),
      ));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<List<GroupMember>, RepositoryError>> getMembers(
    String groupId,
  ) async {
    final result = await getGroupInfo(groupId);
    return result.fold(
      onSuccess: (info) => Result.success(info.members),
      onFailure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<List<GroupMember>, RepositoryError>> getAdmins(
    String groupId,
  ) async {
    final result = await getGroupInfo(groupId);
    return result.fold(
      onSuccess: (info) =>
          Result.success(info.members.where((m) => m.isAdmin).toList()),
      onFailure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<bool, RepositoryError>> isMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final doc = await _chatsCollection.doc(groupId).get();

      if (!doc.exists) {
        return Result.failure(RepositoryError.notFound('Group'));
      }

      final data = doc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['membersIds'] ?? []);

      return Result.success(memberIds.contains(userId));
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  @override
  Future<Result<bool, RepositoryError>> isAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      final doc = await _chatsCollection.doc(groupId).get();

      if (!doc.exists) {
        return Result.failure(RepositoryError.notFound('Group'));
      }

      final data = doc.data() as Map<String, dynamic>;
      final adminIds = List<String>.from(data['adminIds'] ?? []);
      final createdBy = data['createdBy'] as String?;

      return Result.success(adminIds.contains(userId) || createdBy == userId);
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Permission Validation ===================

  @override
  Future<Result<bool, RepositoryError>> canPerformAction({
    required String groupId,
    required String userId,
    required GroupAction action,
  }) async {
    try {
      final doc = await _chatsCollection.doc(groupId).get();

      if (!doc.exists) {
        return Result.failure(RepositoryError.notFound('Group'));
      }

      final data = doc.data() as Map<String, dynamic>;
      final adminIds = List<String>.from(data['adminIds'] ?? []);
      final createdBy = data['createdBy'] as String?;
      final permissions = GroupPermissions.fromMap(
        data['permissions'] as Map<String, dynamic>?,
      );

      final isCreator = createdBy == userId;
      final isAdmin = adminIds.contains(userId) || isCreator;

      switch (action) {
        case GroupAction.addMember:
          return Result.success(
            _checkPermission(permissions.addMembers, isCreator, isAdmin),
          );
        case GroupAction.removeMember:
          return Result.success(
            _checkPermission(permissions.removeMembers, isCreator, isAdmin),
          );
        case GroupAction.editInfo:
          return Result.success(
            _checkPermission(permissions.editGroupInfo, isCreator, isAdmin),
          );
        case GroupAction.sendMessage:
          return Result.success(
            _checkPermission(permissions.sendMessages, isCreator, isAdmin),
          );
        case GroupAction.pinMessage:
          return Result.success(
            _checkPermission(permissions.pinMessages, isCreator, isAdmin),
          );
        case GroupAction.makeAdmin:
        case GroupAction.removeAdmin:
        case GroupAction.updatePermissions:
          // Only admins can manage other admins
          return Result.success(isAdmin);
        case GroupAction.deleteGroup:
          // Only creator can delete
          return Result.success(isCreator);
      }
    } catch (e, st) {
      return Result.failure(RepositoryError.fromException(e, st));
    }
  }

  // =================== Private Helpers ===================

  bool _checkPermission(PermissionLevel level, bool isCreator, bool isAdmin) {
    switch (level) {
      case PermissionLevel.everyone:
        return true;
      case PermissionLevel.adminsOnly:
        return isAdmin;
      case PermissionLevel.creatorOnly:
        return isCreator;
    }
  }

  void _addMemberKeywords(List<String> keywords, SocialMediaUser member) {
    final name = member.fullName?.toLowerCase() ?? '';
    final nameParts = name.split(' ');
    for (final part in nameParts) {
      if (part.isNotEmpty && !keywords.contains(part)) {
        keywords.add(part);
      }
    }
  }
}

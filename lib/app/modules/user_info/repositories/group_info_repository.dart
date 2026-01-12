import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/modules/user_info/repositories/user_info_repository.dart';

/// Repository interface for group info operations
abstract class GroupInfoRepository {
  /// Get group by room ID
  Future<ChatRoom?> getGroupById(String roomId);

  /// Watch group for real-time updates
  Stream<ChatRoom?> watchGroup(String roomId);

  /// Get group members
  Future<List<SocialMediaUser>> getGroupMembers(List<String> memberIds);

  /// Get shared media count
  Future<MediaCounts> getSharedMediaCounts(String roomId);

  /// Update group info
  Future<void> updateGroupInfo({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  });

  /// Add member to group
  Future<void> addMember(String roomId, SocialMediaUser member);

  /// Remove member from group
  Future<void> removeMember(String roomId, String memberId);

  /// Leave group
  Future<void> leaveGroup(String roomId, String userId);

  /// Toggle favorite status
  Future<void> toggleFavorite(String roomId);

  /// Toggle mute status
  Future<void> toggleMute(String roomId);

  /// Report group
  Future<void> reportGroup({
    required String groupId,
    required String reporterId,
    required String reason,
    String? details,
  });

  /// Delete group (admin only)
  Future<void> deleteGroup(String roomId);

  /// Make user admin
  Future<void> makeAdmin(String roomId, String userId);

  /// Remove admin status
  Future<void> removeAdmin(String roomId, String userId);

  /// Get group admins
  Future<List<String>> getGroupAdmins(String roomId);
}

/// Firestore implementation of GroupInfoRepository
class FirestoreGroupInfoRepository implements GroupInfoRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupInfoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ChatRoom?> getGroupById(String roomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  @override
  Stream<ChatRoom?> watchGroup(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? ChatRoom.fromJson(doc.data()!) : null);
  }

  @override
  Future<List<SocialMediaUser>> getGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];

    try {
      final members = <SocialMediaUser>[];

      // Firestore whereIn has a limit of 10, so we need to batch
      for (var i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.sublist(
          i,
          i + 10 > memberIds.length ? memberIds.length : i + 10,
        );

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          members.add(SocialMediaUser.fromQuery(doc));
        }
      }

      return members;
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }

  @override
  Future<MediaCounts> getSharedMediaCounts(String roomId) async {
    try {
      final chatRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat');

      final results = await Future.wait([
        chatRef.where('type', isEqualTo: 'photo').count().get(),
        chatRef.where('type', isEqualTo: 'video').count().get(),
        chatRef.where('type', isEqualTo: 'file').count().get(),
        chatRef.where('type', isEqualTo: 'audio').count().get(),
        chatRef.where('type', isEqualTo: 'link').count().get(),
      ]);

      return MediaCounts(
        photos: results[0].count ?? 0,
        videos: results[1].count ?? 0,
        files: results[2].count ?? 0,
        audio: results[3].count ?? 0,
        links: results[4].count ?? 0,
      );
    } catch (e) {
      print('Error getting media counts: $e');
      return const MediaCounts();
    }
  }

  @override
  Future<void> updateGroupInfo({
    required String roomId,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (imageUrl != null) updates['groupImageUrl'] = imageUrl;

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('chat_rooms').doc(roomId).update(updates);
    }
  }

  @override
  Future<void> addMember(String roomId, SocialMediaUser member) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'membersIds': FieldValue.arrayUnion([member.uid]),
      'members': FieldValue.arrayUnion([member.toMap()]),
    });
  }

  @override
  Future<void> removeMember(String roomId, String memberId) async {
    // First get the current members to find the full member object
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    if (!doc.exists) return;

    final members = List<Map<String, dynamic>>.from(doc.data()?['members'] ?? []);
    final memberToRemove = members.firstWhere(
      (m) => m['uid'] == memberId,
      orElse: () => {},
    );

    await _firestore.collection('chat_rooms').doc(roomId).update({
      'membersIds': FieldValue.arrayRemove([memberId]),
      if (memberToRemove.isNotEmpty) 'members': FieldValue.arrayRemove([memberToRemove]),
    });
  }

  @override
  Future<void> leaveGroup(String roomId, String userId) async {
    await removeMember(roomId, userId);
  }

  @override
  Future<void> toggleFavorite(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    final currentValue = doc.data()?['isFavorite'] ?? false;
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'isFavorite': !currentValue,
    });
  }

  @override
  Future<void> toggleMute(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    final currentValue = doc.data()?['isMuted'] ?? false;
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'isMuted': !currentValue,
    });
  }

  @override
  Future<void> reportGroup({
    required String groupId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection('reports').add({
      'reportedGroupId': groupId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
      'type': 'group',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteGroup(String roomId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('chat')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Delete the group document
    await _firestore.collection('chat_rooms').doc(roomId).delete();
  }

  @override
  Future<void> makeAdmin(String roomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'admins': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> removeAdmin(String roomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<List<String>> getGroupAdmins(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    return List<String>.from(doc.data()?['admins'] ?? []);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';

/// Repository interface for user info operations
abstract class UserInfoRepository {
  /// Get user by ID
  Future<SocialMediaUser?> getUserById(String userId);

  /// Watch user for real-time updates
  Stream<SocialMediaUser?> watchUser(String userId);

  /// Get chat room by ID
  Future<ChatRoom?> getChatRoomById(String roomId);

  /// Watch chat room for real-time updates
  Stream<ChatRoom?> watchChatRoom(String roomId);

  /// Get shared media count between users
  Future<MediaCounts> getSharedMediaCounts(String roomId);

  /// Get mutual contacts between two users
  Future<List<SocialMediaUser>> getMutualContacts(String userId1, String userId2);

  /// Block a user in a chat
  Future<void> blockUser(String roomId, String userId);

  /// Unblock a user in a chat
  Future<void> unblockUser(String roomId, String userId);

  /// Toggle favorite status
  Future<void> toggleFavorite(String roomId);

  /// Toggle archive status
  Future<void> toggleArchive(String roomId);

  /// Toggle mute status
  Future<void> toggleMute(String roomId);

  /// Clear chat messages
  Future<void> clearChat(String roomId);

  /// Report user
  Future<void> reportUser({
    required String reportedUserId,
    required String reporterId,
    required String reason,
    String? details,
  });

  /// Get online status
  Stream<bool> watchOnlineStatus(String userId);

  /// Get last seen timestamp
  Future<DateTime?> getLastSeen(String userId);

  /// Update disappearing messages duration for a chat
  Future<void> updateDisappearingDuration(String roomId, DisappearingDuration duration);

  /// Get all messages from a chat room for export
  Future<List<Message>> getChatMessages(String roomId);
}

/// Media counts for a chat
class MediaCounts {
  final int photos;
  final int videos;
  final int files;
  final int audio;
  final int links;

  const MediaCounts({
    this.photos = 0,
    this.videos = 0,
    this.files = 0,
    this.audio = 0,
    this.links = 0,
  });

  int get total => photos + videos + files + audio + links;

  factory MediaCounts.fromMap(Map<String, dynamic> map) {
    return MediaCounts(
      photos: map['photos'] as int? ?? 0,
      videos: map['videos'] as int? ?? 0,
      files: map['files'] as int? ?? 0,
      audio: map['audio'] as int? ?? 0,
      links: map['links'] as int? ?? 0,
    );
  }
}

/// Firestore implementation of UserInfoRepository
class FirestoreUserInfoRepository implements UserInfoRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserInfoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<SocialMediaUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return SocialMediaUser.fromQuery(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  @override
  Stream<SocialMediaUser?> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? SocialMediaUser.fromQuery(doc) : null);
  }

  @override
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  @override
  Stream<ChatRoom?> watchChatRoom(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? ChatRoom.fromJson(doc.data()!) : null);
  }

  @override
  Future<MediaCounts> getSharedMediaCounts(String roomId) async {
    try {
      final chatRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat');

      // Run all queries in parallel
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
  Future<List<SocialMediaUser>> getMutualContacts(String userId1, String userId2) async {
    try {
      // Get both users' contacts
      final user1Doc = await _firestore.collection('users').doc(userId1).get();
      final user2Doc = await _firestore.collection('users').doc(userId2).get();

      if (!user1Doc.exists || !user2Doc.exists) return [];

      final user1Contacts = List<String>.from(user1Doc.data()?['contacts'] ?? []);
      final user2Contacts = List<String>.from(user2Doc.data()?['contacts'] ?? []);

      // Find mutual contacts
      final mutualIds = user1Contacts.toSet().intersection(user2Contacts.toSet());

      if (mutualIds.isEmpty) return [];

      // Fetch mutual contact details
      final mutualUsers = <SocialMediaUser>[];
      for (final contactId in mutualIds.take(10)) {
        final contactDoc = await _firestore.collection('users').doc(contactId).get();
        if (contactDoc.exists) {
          mutualUsers.add(SocialMediaUser.fromQuery(contactDoc));
        }
      }

      return mutualUsers;
    } catch (e) {
      print('Error getting mutual contacts: $e');
      return [];
    }
  }

  @override
  Future<void> blockUser(String roomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'blockedUsers': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> unblockUser(String roomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });
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
  Future<void> toggleArchive(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    final currentValue = doc.data()?['isArchived'] ?? false;
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'isArchived': !currentValue,
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
  Future<void> clearChat(String roomId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('chat')
        .get();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  Future<void> reportUser({
    required String reportedUserId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    await _firestore.collection('reports').add({
      'reportedUserId': reportedUserId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
      'type': 'user',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<bool> watchOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }

  @override
  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final lastSeen = doc.data()?['lastSeen'];
      if (lastSeen is Timestamp) {
        return lastSeen.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateDisappearingDuration(
    String roomId,
    DisappearingDuration duration,
  ) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'disappearingDuration': duration.name,
      'disappearingDurationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Message>> getChatMessages(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('chat')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['roomId'] = roomId;
        return Message.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// DATA-005: Member Data Denormalization Handler
/// Handles the denormalized member data in chat rooms
/// Provides sync mechanisms to keep data fresh

class MemberDataHandler {
  static final MemberDataHandler instance = MemberDataHandler._();
  MemberDataHandler._();

  final _logger = LoggerService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for member data
  final Map<String, MemberCache> _memberCache = {};

  // Subscription for user updates
  final Map<String, StreamSubscription> _userSubscriptions = {};

  /// Get member data with freshness check
  Future<SocialMediaUser?> getMember(String roomId, String userId) async {
    // Check cache first
    final cached = _getCachedMember(roomId, userId);
    if (cached != null && !cached.isStale) {
      return cached.user;
    }

    // Fetch fresh data
    final fresh = await _fetchMember(userId);
    if (fresh != null) {
      _cacheMember(roomId, userId, fresh);
    }

    return fresh;
  }

  /// Get all members with optional refresh
  Future<List<SocialMediaUser>> getMembers(
    String roomId,
    List<String> memberIds, {
    bool forceRefresh = false,
  }) async {
    final members = <SocialMediaUser>[];

    for (final userId in memberIds) {
      if (forceRefresh) {
        final fresh = await _fetchMember(userId);
        if (fresh != null) {
          _cacheMember(roomId, userId, fresh);
          members.add(fresh);
        }
      } else {
        final member = await getMember(roomId, userId);
        if (member != null) {
          members.add(member);
        }
      }
    }

    return members;
  }

  /// Sync member data in a chat room document
  Future<bool> syncMembersInRoom(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('chats').doc(roomId).get();
      if (!roomDoc.exists) return false;

      final data = roomDoc.data()!;
      final memberIds = List<String>.from(data['membersIds'] ?? []);

      // Fetch fresh member data
      final freshMembers = await getMembers(roomId, memberIds, forceRefresh: true);

      // Update the room document
      await _firestore.collection('chats').doc(roomId).update({
        'members': freshMembers.map((m) => m.toMap()).toList(),
        'membersUpdatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info(
        'Synced members in room',
        context: 'MemberDataHandler',
        data: {'roomId': roomId, 'count': freshMembers.length},
      );

      return true;
    } catch (e) {
      _logger.logError('Failed to sync members', error: e, context: 'MemberDataHandler');
      return false;
    }
  }

  /// Start listening to a user's profile for updates
  void watchMember(String userId, void Function(SocialMediaUser) onUpdate) {
    if (_userSubscriptions.containsKey(userId)) return;

    final subscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final user = SocialMediaUser.fromMap(snapshot.data()!);
          onUpdate(user);

          // Update all rooms containing this user
          _updateUserInAllRooms(userId, user);
        }
      },
      onError: (error) {
        _logger.logError('Error watching member', error: error, context: 'MemberDataHandler');
      },
    );

    _userSubscriptions[userId] = subscription;
  }

  /// Stop watching a user
  void unwatchMember(String userId) {
    _userSubscriptions[userId]?.cancel();
    _userSubscriptions.remove(userId);
  }

  /// Update a user's data in all rooms they belong to
  Future<void> _updateUserInAllRooms(String userId, SocialMediaUser user) async {
    try {
      // Find all rooms containing this user
      final roomsQuery = await _firestore
          .collection('chats')
          .where('membersIds', arrayContains: userId)
          .get();

      final batch = _firestore.batch();

      for (final roomDoc in roomsQuery.docs) {
        final data = roomDoc.data();
        final members = List<Map<String, dynamic>>.from(data['members'] ?? []);

        // Update the member data
        final updatedMembers = members.map((m) {
          if (m['uid'] == userId) {
            return user.toMap();
          }
          return m;
        }).toList();

        batch.update(roomDoc.reference, {'members': updatedMembers});
      }

      await batch.commit();

      _logger.debug(
        'Updated user in rooms',
        context: 'MemberDataHandler',
        data: {'userId': userId, 'roomCount': roomsQuery.docs.length},
      );
    } catch (e) {
      _logger.logError('Failed to update user in rooms', error: e, context: 'MemberDataHandler');
    }
  }

  /// Get minimal member reference (ID only) for storage
  Map<String, dynamic> toMemberReference(SocialMediaUser user) {
    return {
      'uid': user.uid,
      'fullName': user.fullName,
      'imageUrl': user.imageUrl,
      // Only essential fields, not the full user object
    };
  }

  /// Create optimized member list for storage
  List<Map<String, dynamic>> toMemberReferences(List<SocialMediaUser> members) {
    return members.map(toMemberReference).toList();
  }

  /// Fetch member from Firestore
  Future<SocialMediaUser?> _fetchMember(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return SocialMediaUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.logError('Failed to fetch member', error: e, context: 'MemberDataHandler');
      return null;
    }
  }

  /// Get cached member
  MemberCache? _getCachedMember(String roomId, String userId) {
    final cacheKey = '$roomId:$userId';
    return _memberCache[cacheKey];
  }

  /// Cache member
  void _cacheMember(String roomId, String userId, SocialMediaUser user) {
    final cacheKey = '$roomId:$userId';
    _memberCache[cacheKey] = MemberCache(
      user: user,
      cachedAt: DateTime.now(),
    );
  }

  /// Clear cache for a room
  void clearRoomCache(String roomId) {
    _memberCache.removeWhere((key, _) => key.startsWith('$roomId:'));
  }

  /// Clear all cache
  void clearAllCache() {
    _memberCache.clear();
  }

  /// Dispose all subscriptions
  void dispose() {
    for (final subscription in _userSubscriptions.values) {
      subscription.cancel();
    }
    _userSubscriptions.clear();
    _memberCache.clear();
  }
}

/// Cached member data
class MemberCache {
  final SocialMediaUser user;
  final DateTime cachedAt;

  // Cache validity duration
  static const Duration validityDuration = Duration(minutes: 5);

  MemberCache({
    required this.user,
    required this.cachedAt,
  });

  bool get isStale => DateTime.now().difference(cachedAt) > validityDuration;
}

/// Member sync status
class MemberSyncStatus {
  final String roomId;
  final DateTime lastSyncAt;
  final int memberCount;
  final bool hasErrors;

  MemberSyncStatus({
    required this.roomId,
    required this.lastSyncAt,
    required this.memberCount,
    this.hasErrors = false,
  });
}

/// Mixin for controllers that need member data handling
mixin MemberDataMixin {
  final _memberHandler = MemberDataHandler.instance;

  /// Get member by ID
  Future<SocialMediaUser?> getMemberById(String roomId, String userId) {
    return _memberHandler.getMember(roomId, userId);
  }

  /// Get all members
  Future<List<SocialMediaUser>> getAllMembers(
    String roomId,
    List<String> memberIds,
  ) {
    return _memberHandler.getMembers(roomId, memberIds);
  }

  /// Sync members
  Future<bool> syncMembers(String roomId) {
    return _memberHandler.syncMembersInRoom(roomId);
  }

  /// Watch member for updates
  void watchMember(String userId, void Function(SocialMediaUser) onUpdate) {
    _memberHandler.watchMember(userId, onUpdate);
  }

  /// Stop watching member
  void unwatchMember(String userId) {
    _memberHandler.unwatchMember(userId);
  }
}

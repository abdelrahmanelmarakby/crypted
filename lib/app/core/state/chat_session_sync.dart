import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:get/get.dart';

/// STATE-002: ChatSessionManager Firestore Sync
/// Keeps ChatSessionManager in sync with Firestore changes in real-time

class ChatSessionSync extends GetxService {
  static ChatSessionSync get instance => Get.find<ChatSessionSync>();

  final _logger = LoggerService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Active subscriptions by room ID
  final Map<String, StreamSubscription> _roomSubscriptions = {};

  // Cached session data
  final Map<String, RxChatSession> _sessions = {};

  // Callbacks for session changes
  final Map<String, List<void Function(RxChatSession)>> _callbacks = {};

  @override
  void onClose() {
    disposeAll();
    super.onClose();
  }

  /// Start syncing a chat room session
  void startSync(String roomId) {
    if (_roomSubscriptions.containsKey(roomId)) {
      _logger.debug('Already syncing room', context: 'ChatSessionSync', data: {
        'roomId': roomId,
      });
      return;
    }

    _logger.info('Starting session sync', context: 'ChatSessionSync', data: {
      'roomId': roomId,
    });

    // Initialize session if not exists
    _sessions[roomId] ??= RxChatSession(roomId: roomId);

    // Subscribe to room document changes
    final subscription = _firestore
        .collection(FirebaseCollections.chats)
        .doc(roomId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          _updateSessionFromSnapshot(roomId, snapshot);
        }
      },
      onError: (error) {
        _logger.logError('Session sync error', error: error, context: 'ChatSessionSync');
      },
    );

    _roomSubscriptions[roomId] = subscription;
  }

  /// Stop syncing a chat room session
  void stopSync(String roomId) {
    _roomSubscriptions[roomId]?.cancel();
    _roomSubscriptions.remove(roomId);
    _callbacks.remove(roomId);

    _logger.debug('Stopped session sync', context: 'ChatSessionSync', data: {
      'roomId': roomId,
    });
  }

  /// Dispose all subscriptions
  void disposeAll() {
    for (final subscription in _roomSubscriptions.values) {
      subscription.cancel();
    }
    _roomSubscriptions.clear();
    _sessions.clear();
    _callbacks.clear();
  }

  /// Update session from Firestore snapshot
  void _updateSessionFromSnapshot(String roomId, DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final session = _sessions[roomId];
    if (session == null) return;

    // Update session properties
    session.updateFromMap(data);

    // Notify callbacks
    _notifyCallbacks(roomId, session);

    _logger.debug('Session updated from Firestore', context: 'ChatSessionSync', data: {
      'roomId': roomId,
    });
  }

  /// Get session for a room
  RxChatSession? getSession(String roomId) => _sessions[roomId];

  /// Get or create session for a room
  RxChatSession getOrCreateSession(String roomId) {
    _sessions[roomId] ??= RxChatSession(roomId: roomId);
    return _sessions[roomId]!;
  }

  /// Register callback for session changes
  void onSessionChange(String roomId, void Function(RxChatSession) callback) {
    _callbacks[roomId] ??= [];
    _callbacks[roomId]!.add(callback);
  }

  /// Remove session change callback
  void removeCallback(String roomId, void Function(RxChatSession) callback) {
    _callbacks[roomId]?.remove(callback);
  }

  /// Notify all callbacks for a room
  void _notifyCallbacks(String roomId, RxChatSession session) {
    final callbacks = _callbacks[roomId];
    if (callbacks == null) return;

    for (final callback in callbacks) {
      callback(session);
    }
  }

  /// Update session and sync to Firestore
  Future<bool> updateSession(
    String roomId, {
    String? name,
    String? description,
    String? imageUrl,
    List<SocialMediaUser>? members,
    List<String>? adminIds,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['chatName'] = name;
      if (description != null) updates['chatDescription'] = description;
      if (imageUrl != null) updates['groupImageUrl'] = imageUrl;
      if (members != null) {
        updates['members'] = members.map((m) => m.toMap()).toList();
        updates['membersIds'] = members.map((m) => m.uid).toList();
      }
      if (adminIds != null) updates['adminIds'] = adminIds;

      if (updates.isEmpty) return true;

      await _firestore.collection(FirebaseCollections.chats).doc(roomId).update(updates);

      _logger.info('Session updated to Firestore', context: 'ChatSessionSync', data: {
        'roomId': roomId,
        'fields': updates.keys.toList(),
      });

      return true;
    } catch (e) {
      _logger.logError('Failed to update session', error: e, context: 'ChatSessionSync');
      return false;
    }
  }
}

/// Reactive chat session that syncs with Firestore
class RxChatSession {
  final String roomId;

  // Observables
  final RxString name = ''.obs;
  final RxString description = ''.obs;
  final RxString imageUrl = ''.obs;
  final RxList<SocialMediaUser> members = <SocialMediaUser>[].obs;
  final RxList<String> adminIds = <String>[].obs;
  final RxList<String> memberIds = <String>[].obs;
  final RxBool isGroupChat = false.obs;
  final RxBool isMuted = false.obs;
  final RxBool isPinned = false.obs;
  final RxBool isArchived = false.obs;
  final Rx<DateTime?> lastMessageTime = Rx<DateTime?>(null);
  final RxString lastMessage = ''.obs;
  final RxInt unreadCount = 0.obs;

  RxChatSession({required this.roomId});

  /// Update from Firestore data
  void updateFromMap(Map<String, dynamic> data) {
    // Update name
    if (data.containsKey('chatName')) {
      name.value = data['chatName'] ?? '';
    }

    // Update description
    if (data.containsKey('chatDescription')) {
      description.value = data['chatDescription'] ?? '';
    }

    // Update image
    if (data.containsKey('groupImageUrl')) {
      imageUrl.value = data['groupImageUrl'] ?? '';
    }

    // Update members
    if (data.containsKey('members')) {
      final membersList = data['members'] as List<dynamic>? ?? [];
      members.value = membersList
          .map((m) => SocialMediaUser.fromMap(m as Map<String, dynamic>))
          .toList();
    }

    // Update member IDs
    if (data.containsKey('membersIds')) {
      memberIds.value = List<String>.from(data['membersIds'] ?? []);
    }

    // Update admin IDs
    if (data.containsKey('adminIds')) {
      adminIds.value = List<String>.from(data['adminIds'] ?? []);
    }

    // Update flags
    if (data.containsKey('isGroupChat')) {
      isGroupChat.value = data['isGroupChat'] ?? false;
    }

    if (data.containsKey('isMuted')) {
      isMuted.value = data['isMuted'] ?? false;
    }

    if (data.containsKey('isPinned')) {
      isPinned.value = data['isPinned'] ?? false;
    }

    if (data.containsKey('isArchived')) {
      isArchived.value = data['isArchived'] ?? false;
    }

    // Update last message info
    if (data.containsKey('lastMessage')) {
      lastMessage.value = data['lastMessage'] ?? '';
    }

    if (data.containsKey('lastChat')) {
      final lastChat = data['lastChat'];
      if (lastChat is Timestamp) {
        lastMessageTime.value = lastChat.toDate();
      }
    }

    if (data.containsKey('unreadCount')) {
      unreadCount.value = data['unreadCount'] ?? 0;
    }
  }

  /// Get member by ID
  SocialMediaUser? getMemberById(String id) {
    return members.firstWhereOrNull((m) => m.uid == id);
  }

  /// Check if user is admin
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Get member count
  int get memberCount => members.length;
}

/// Mixin for controllers that need session sync
mixin ChatSessionSyncMixin on GetxController {
  late final ChatSessionSync _sessionSync;
  String? _syncedRoomId;

  /// Initialize session sync for a room
  void initSessionSync(String roomId) {
    if (Get.isRegistered<ChatSessionSync>()) {
      _sessionSync = ChatSessionSync.instance;
      _syncedRoomId = roomId;
      _sessionSync.startSync(roomId);
    }
  }

  /// Get reactive session
  RxChatSession? get session =>
      _syncedRoomId != null ? _sessionSync.getSession(_syncedRoomId!) : null;

  /// Update session
  Future<bool> updateSessionData({
    String? name,
    String? description,
    String? imageUrl,
    List<SocialMediaUser>? members,
    List<String>? adminIds,
  }) async {
    if (_syncedRoomId == null) return false;

    return await _sessionSync.updateSession(
      _syncedRoomId!,
      name: name,
      description: description,
      imageUrl: imageUrl,
      members: members,
      adminIds: adminIds,
    );
  }

  /// Dispose session sync
  void disposeSessionSync() {
    if (_syncedRoomId != null) {
      _sessionSync.stopSync(_syncedRoomId!);
    }
  }
}

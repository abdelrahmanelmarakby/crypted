import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// STATE-004: Reactive Read State Service
/// Manages message read receipts with reactive updates
class ReadStateService extends GetxService {
  static ReadStateService get instance => Get.find<ReadStateService>();

  final _logger = LoggerService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for read states per room
  final Map<String, RxMap<String, List<String>>> _readStates = {};

  // Active subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Callbacks for read state changes
  final Map<String, List<void Function(String messageId, List<String> readBy)>> _callbacks = {};

  String? get _currentUserId => UserService.currentUser.value?.uid;

  @override
  void onClose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _readStates.clear();
    super.onClose();
  }

  /// Start listening to read states for a room
  void startListening(String roomId) {
    if (_subscriptions.containsKey(roomId)) return;

    _logger.debug('Starting read state listener', context: 'ReadStateService', data: {
      'roomId': roomId,
    });

    _readStates[roomId] = <String, List<String>>{}.obs;

    final subscription = _firestore
        .collection('chats')
        .doc(roomId)
        .collection('chat')
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data != null) {
              final messageId = change.doc.id;
              final readBy = List<String>.from(data['readBy'] ?? []);

              // Update local state
              _readStates[roomId]![messageId] = readBy;

              // Notify callbacks
              _notifyCallbacks(roomId, messageId, readBy);
            }
          }
        }
      },
      onError: (error) {
        _logger.logError('Read state listener error', error: error);
      },
    );

    _subscriptions[roomId] = subscription;
  }

  /// Stop listening to read states for a room
  void stopListening(String roomId) {
    _subscriptions[roomId]?.cancel();
    _subscriptions.remove(roomId);
    _readStates.remove(roomId);
    _callbacks.remove(roomId);

    _logger.debug('Stopped read state listener', context: 'ReadStateService', data: {
      'roomId': roomId,
    });
  }

  /// Mark a message as read
  Future<bool> markAsRead(String roomId, String messageId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('chat')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([_currentUserId]),
      });

      _logger.debug('Marked message as read', context: 'ReadStateService', data: {
        'roomId': roomId,
        'messageId': messageId,
      });

      return true;
    } catch (e) {
      _logger.logError('Failed to mark message as read', error: e);
      return false;
    }
  }

  /// Mark multiple messages as read
  Future<int> markMultipleAsRead(String roomId, List<String> messageIds) async {
    if (_currentUserId == null) return 0;

    int successCount = 0;
    final batch = _firestore.batch();

    for (final messageId in messageIds) {
      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('chat')
          .doc(messageId);

      batch.update(docRef, {
        'readBy': FieldValue.arrayUnion([_currentUserId]),
      });
      successCount++;
    }

    try {
      await batch.commit();
      _logger.debug('Marked multiple messages as read', context: 'ReadStateService', data: {
        'roomId': roomId,
        'count': successCount,
      });
      return successCount;
    } catch (e) {
      _logger.logError('Failed to mark multiple messages as read', error: e);
      return 0;
    }
  }

  /// Mark all messages in a room as read
  Future<bool> markAllAsRead(String roomId) async {
    if (_currentUserId == null) return false;

    try {
      // Get all unread messages
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('chat')
          .where('senderId', isNotEqualTo: _currentUserId)
          .get();

      final unreadIds = unreadMessages.docs
          .where((doc) {
            final readBy = List<String>.from(doc.data()['readBy'] ?? []);
            return !readBy.contains(_currentUserId);
          })
          .map((doc) => doc.id)
          .toList();

      if (unreadIds.isEmpty) return true;

      await markMultipleAsRead(roomId, unreadIds);
      return true;
    } catch (e) {
      _logger.logError('Failed to mark all as read', error: e);
      return false;
    }
  }

  /// Check if a message has been read by a specific user
  bool isReadBy(String roomId, String messageId, String userId) {
    final readBy = _readStates[roomId]?[messageId] ?? [];
    return readBy.contains(userId);
  }

  /// Check if a message has been read by current user
  bool isReadByMe(String roomId, String messageId) {
    if (_currentUserId == null) return false;
    return isReadBy(roomId, messageId, _currentUserId!);
  }

  /// Get read count for a message
  int getReadCount(String roomId, String messageId) {
    return _readStates[roomId]?[messageId]?.length ?? 0;
  }

  /// Get list of users who read a message
  List<String> getReadBy(String roomId, String messageId) {
    return _readStates[roomId]?[messageId] ?? [];
  }

  /// Get unread count for a room
  int getUnreadCount(String roomId) {
    if (_currentUserId == null) return 0;

    final readStates = _readStates[roomId];
    if (readStates == null) return 0;

    return readStates.values
        .where((readBy) => !readBy.contains(_currentUserId))
        .length;
  }

  /// Get observable read state for a room
  RxMap<String, List<String>>? getReadStatesForRoom(String roomId) {
    return _readStates[roomId];
  }

  /// Register callback for read state changes
  void onReadStateChange(
    String roomId,
    void Function(String messageId, List<String> readBy) callback,
  ) {
    _callbacks[roomId] ??= [];
    _callbacks[roomId]!.add(callback);
  }

  /// Remove callback
  void removeCallback(
    String roomId,
    void Function(String messageId, List<String> readBy) callback,
  ) {
    _callbacks[roomId]?.remove(callback);
  }

  /// Notify all callbacks for a room
  void _notifyCallbacks(String roomId, String messageId, List<String> readBy) {
    final callbacks = _callbacks[roomId];
    if (callbacks == null) return;

    for (final callback in callbacks) {
      callback(messageId, readBy);
    }
  }
}

/// Read receipt widget that updates reactively
class ReadReceiptIndicator extends StatelessWidget {
  final String roomId;
  final String messageId;
  final String senderId;
  final int totalRecipients;

  const ReadReceiptIndicator({
    super.key,
    required this.roomId,
    required this.messageId,
    required this.senderId,
    this.totalRecipients = 1,
  });

  @override
  Widget build(BuildContext context) {
    final service = ReadStateService.instance;
    final readStates = service.getReadStatesForRoom(roomId);

    if (readStates == null) {
      return const _DeliveredIcon();
    }

    return Obx(() {
      final readBy = readStates[messageId] ?? [];
      final readCount = readBy.where((id) => id != senderId).length;

      if (readCount >= totalRecipients) {
        return const _ReadIcon();
      } else if (readCount > 0) {
        return _PartiallyReadIcon(
          readCount: readCount,
          totalCount: totalRecipients,
        );
      } else {
        return const _DeliveredIcon();
      }
    });
  }
}

class _DeliveredIcon extends StatelessWidget {
  const _DeliveredIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.done,
      size: 14,
      color: Colors.grey,
    );
  }
}

class _ReadIcon extends StatelessWidget {
  const _ReadIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.done_all,
      size: 14,
      color: Colors.blue[400],
    );
  }
}

class _PartiallyReadIcon extends StatelessWidget {
  final int readCount;
  final int totalCount;

  const _PartiallyReadIcon({
    required this.readCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue[400],
        ),
        const SizedBox(width: 2),
        Text(
          '$readCount/$totalCount',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Mixin for controllers that need read state management
mixin ReadStateMixin on GetxController {
  late final ReadStateService _readStateService;
  String? _activeRoomId;

  /// Initialize read state tracking for a room
  void initReadState(String roomId) {
    if (Get.isRegistered<ReadStateService>()) {
      _readStateService = ReadStateService.instance;
      _activeRoomId = roomId;
      _readStateService.startListening(roomId);
    }
  }

  /// Mark message as read
  Future<bool> markMessageRead(String messageId) async {
    if (_activeRoomId == null) return false;
    return await _readStateService.markAsRead(_activeRoomId!, messageId);
  }

  /// Mark all messages as read
  Future<bool> markAllMessagesRead() async {
    if (_activeRoomId == null) return false;
    return await _readStateService.markAllAsRead(_activeRoomId!);
  }

  /// Get unread count
  int get unreadCount {
    if (_activeRoomId == null) return 0;
    return _readStateService.getUnreadCount(_activeRoomId!);
  }

  /// Dispose read state tracking
  void disposeReadState() {
    if (_activeRoomId != null) {
      _readStateService.stopListening(_activeRoomId!);
    }
  }
}

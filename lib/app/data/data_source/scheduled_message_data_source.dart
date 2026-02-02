import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/models/scheduled_message_model.dart';

/// Data source for scheduled messages.
///
/// Provides CRUD operations for the `scheduled_messages` Firestore collection.
/// Messages are written by the client and processed by a Cloud Function that
/// runs every minute, sending pending messages whose `scheduledFor` <= now.
class ScheduledMessageDataSource {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance
          .collection(FirebaseCollections.scheduledMessages);

  /// Schedule a new message to be sent at [scheduledFor].
  ///
  /// [messageData] should be a full `Message.toMap()` output.
  /// [members] is the list of chat room members (serialized).
  Future<ScheduledMessage?> scheduleMessage({
    required String chatRoomId,
    required Map<String, dynamic> messageData,
    required DateTime scheduledFor,
    required List<Map<String, dynamic>> members,
  }) async {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return null;

    final currentUser = UserService.currentUser.value;

    final scheduled = ScheduledMessage(
      chatRoomId: chatRoomId,
      senderId: uid,
      senderName: currentUser?.fullName,
      senderImageUrl: currentUser?.imageUrl,
      messageData: messageData,
      scheduledFor: scheduledFor,
      createdAt: DateTime.now(),
      status: ScheduledMessageStatus.pending,
      members: members,
    );

    try {
      final docRef = await _collection.add(scheduled.toMap());
      await _collection.doc(docRef.id).update({'id': docRef.id});
      log('[ScheduledMessages] Message scheduled for $scheduledFor in room $chatRoomId');
      return scheduled.copyWith(id: docRef.id);
    } catch (e) {
      log('[ScheduledMessages] Error scheduling message: $e');
      return null;
    }
  }

  /// Cancel a scheduled message (only if still pending).
  Future<bool> cancelScheduledMessage(String messageId) async {
    try {
      final doc = await _collection.doc(messageId).get();
      if (!doc.exists) return false;

      final status = doc.data()?['status'] as String?;
      if (status != 'pending') {
        log('[ScheduledMessages] Cannot cancel message with status: $status');
        return false;
      }

      await _collection.doc(messageId).update({
        'status': 'cancelled',
      });
      log('[ScheduledMessages] Message $messageId cancelled');
      return true;
    } catch (e) {
      log('[ScheduledMessages] Error cancelling message: $e');
      return false;
    }
  }

  /// Reschedule a pending message to a new time.
  Future<bool> rescheduleMessage(String messageId, DateTime newTime) async {
    try {
      final doc = await _collection.doc(messageId).get();
      if (!doc.exists) return false;

      final status = doc.data()?['status'] as String?;
      if (status != 'pending') return false;

      await _collection.doc(messageId).update({
        'scheduledFor': Timestamp.fromDate(newTime),
      });
      log('[ScheduledMessages] Message $messageId rescheduled to $newTime');
      return true;
    } catch (e) {
      log('[ScheduledMessages] Error rescheduling: $e');
      return false;
    }
  }

  /// Stream all scheduled messages for the current user.
  /// Ordered by scheduledFor ascending (soonest first).
  Stream<List<ScheduledMessage>> getMyScheduledMessages() {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return Stream.value([]);

    return _collection
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('scheduledFor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledMessage.fromQuery(doc))
            .toList());
  }

  /// Stream scheduled messages for a specific chat room (current user only).
  Stream<List<ScheduledMessage>> getScheduledMessagesForRoom(String roomId) {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return Stream.value([]);

    return _collection
        .where('senderId', isEqualTo: uid)
        .where('chatRoomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'pending')
        .orderBy('scheduledFor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledMessage.fromQuery(doc))
            .toList());
  }

  /// Get count of pending scheduled messages for a room.
  Future<int> getPendingCountForRoom(String roomId) async {
    final uid = UserService.currentUser.value?.uid;
    if (uid == null) return 0;

    final snapshot = await _collection
        .where('senderId', isEqualTo: uid)
        .where('chatRoomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}

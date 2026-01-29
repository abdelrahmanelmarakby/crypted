import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/core/services/zego/zego_call_service.dart';

/// Data source for call-related Firestore operations.
///
/// Handles:
/// - Storing call records to Firestore
/// - Retrieving call history
/// - Updating call status and duration
/// - Cleaning up stale calls
class CallDataSources {
  /// Firestore collection reference for calls.
  final CollectionReference<Map<String, dynamic>> _callsCollection =
      FirebaseFirestore.instance.collection(FirebaseCollections.calls);

  /// Default page size for call history pagination.
  static const int defaultPageSize = 20;

  // ============================================================
  // CALL STORAGE OPERATIONS
  // ============================================================

  /// Store a new call record in Firestore.
  ///
  /// Creates a new document with auto-generated ID and updates the
  /// callModel with the generated ID.
  Future<String?> storeCall(CallModel callModel) async {
    try {
      final docRef = _callsCollection.doc();
      final callWithId = callModel.copyWith(callId: docRef.id);

      await docRef.set(callWithId.toMap());

      log('[CallDataSources] Call stored: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('[CallDataSources] Error storing call: $e');
      return null;
    }
  }

  /// Delete a call record by ID.
  Future<bool> deleteCall(String callId) async {
    try {
      await _callsCollection.doc(callId).delete();
      log('[CallDataSources] Call deleted: $callId');
      return true;
    } catch (e) {
      log('[CallDataSources] Error deleting call: $e');
      return false;
    }
  }

  /// Get a call by its ID.
  Future<CallModel?> getCallById(String callId) async {
    try {
      final doc = await _callsCollection.doc(callId).get();
      if (doc.exists && doc.data() != null) {
        return CallModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      log('[CallDataSources] Error getting call: $e');
      return null;
    }
  }

  // ============================================================
  // CALL STATUS UPDATES
  // ============================================================

  /// Update call status.
  Future<bool> updateCallStatus(
    String callId,
    CallStatus status, {
    num? duration,
  }) async {
    try {
      final doc = await _callsCollection.doc(callId).get();
      if (!doc.exists) {
        log('[CallDataSources] Call not found: $callId');
        return false;
      }

      final updates = <String, dynamic>{
        'callStatus': status.name,
      };

      if (duration != null) {
        updates['callDuration'] = duration;
      }

      await _callsCollection.doc(callId).update(updates);

      log('[CallDataSources] Call status updated: $callId -> ${status.name}');
      return true;
    } catch (e) {
      log('[CallDataSources] Error updating call status: $e');
      return false;
    }
  }

  /// End a call and record duration.
  Future<bool> endCall(String callId, num durationSeconds) async {
    return updateCallStatus(
      callId,
      CallStatus.ended,
      duration: durationSeconds,
    );
  }

  /// Mark a call as missed.
  Future<bool> markCallAsMissed(String callId) async {
    return updateCallStatus(callId, CallStatus.missed);
  }

  /// Mark a call as cancelled.
  Future<bool> markCallAsCancelled(String callId) async {
    return updateCallStatus(callId, CallStatus.canceled);
  }

  /// Mark a call as connected.
  Future<bool> markCallAsConnected(String callId) async {
    return updateCallStatus(callId, CallStatus.connected);
  }

  // ============================================================
  // CALL HISTORY STREAMS
  // ============================================================

  /// Get real-time stream of user's call history.
  ///
  /// Combines both outgoing and incoming calls sorted by time.
  Stream<List<CallModel>> getMyCallsStream(
    String userId, {
    int pageSize = defaultPageSize,
  }) {
    log('[CallDataSources] Getting calls stream for: $userId');

    // Outgoing calls (user is caller)
    final outgoingCalls = _callsCollection
        .where('callerId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallModel.fromMap(doc.data()))
            .toList());

    // Incoming calls (user is callee)
    final incomingCalls = _callsCollection
        .where('calleeId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallModel.fromMap(doc.data()))
            .toList());

    // Combine and sort
    return Rx.combineLatest2(
      outgoingCalls,
      incomingCalls,
      (List<CallModel> outgoing, List<CallModel> incoming) {
        final allCalls = [...outgoing, ...incoming];

        // Sort by time (newest first)
        allCalls.sort((a, b) =>
            (b.time ?? DateTime.now()).compareTo(a.time ?? DateTime.now()));

        // Limit to pageSize
        if (allCalls.length > pageSize) {
          return allCalls.take(pageSize).toList();
        }

        return allCalls;
      },
    ).shareReplay(maxSize: 1);
  }

  /// Load more calls for pagination (one-time fetch).
  Future<List<CallModel>> loadMoreCalls(
    String userId, {
    DateTime? afterTime,
    int pageSize = defaultPageSize,
  }) async {
    try {
      final allCalls = <CallModel>[];

      // Build queries
      Query<Map<String, dynamic>> outgoingQuery = _callsCollection
          .where('callerId', isEqualTo: userId)
          .orderBy('time', descending: true)
          .limit(pageSize);

      Query<Map<String, dynamic>> incomingQuery = _callsCollection
          .where('calleeId', isEqualTo: userId)
          .orderBy('time', descending: true)
          .limit(pageSize);

      // Apply pagination cursor if provided
      if (afterTime != null) {
        final timestamp = Timestamp.fromDate(afterTime);
        outgoingQuery = outgoingQuery.startAfter([timestamp]);
        incomingQuery = incomingQuery.startAfter([timestamp]);
      }

      // Fetch both
      final results = await Future.wait([
        outgoingQuery.get(),
        incomingQuery.get(),
      ]);

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          allCalls.add(CallModel.fromMap(doc.data()));
        }
      }

      // Sort and limit
      allCalls.sort((a, b) =>
          (b.time ?? DateTime.now()).compareTo(a.time ?? DateTime.now()));

      if (allCalls.length > pageSize) {
        return allCalls.take(pageSize).toList();
      }

      return allCalls;
    } catch (e) {
      log('[CallDataSources] Error loading more calls: $e');
      return [];
    }
  }

  /// Get missed calls count for a user.
  Future<int> getMissedCallsCount(String userId) async {
    try {
      final snapshot = await _callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', isEqualTo: CallStatus.missed.name)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      log('[CallDataSources] Error getting missed calls count: $e');
      return 0;
    }
  }

  // ============================================================
  // ACTIVE CALL MANAGEMENT
  // ============================================================

  /// Check if user is currently in an active call.
  Future<bool> isUserInActiveCall(String userId) async {
    try {
      final activeStatuses = [
        CallStatus.outgoing.name,
        CallStatus.incoming.name,
        CallStatus.ringing.name,
        CallStatus.connected.name,
      ];

      // Check outgoing
      final outgoingSnapshot = await _callsCollection
          .where('callerId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .limit(1)
          .get();

      if (outgoingSnapshot.docs.isNotEmpty) {
        return true;
      }

      // Check incoming
      final incomingSnapshot = await _callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .limit(1)
          .get();

      return incomingSnapshot.docs.isNotEmpty;
    } catch (e) {
      log('[CallDataSources] Error checking active call: $e');
      return false;
    }
  }

  /// Get active call for user if any.
  Future<CallModel?> getActiveCallForUser(String userId) async {
    try {
      final activeStatuses = [
        CallStatus.outgoing.name,
        CallStatus.incoming.name,
        CallStatus.ringing.name,
        CallStatus.connected.name,
      ];

      // Check outgoing
      final outgoingSnapshot = await _callsCollection
          .where('callerId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .limit(1)
          .get();

      if (outgoingSnapshot.docs.isNotEmpty) {
        return CallModel.fromMap(outgoingSnapshot.docs.first.data());
      }

      // Check incoming
      final incomingSnapshot = await _callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .limit(1)
          .get();

      if (incomingSnapshot.docs.isNotEmpty) {
        return CallModel.fromMap(incomingSnapshot.docs.first.data());
      }

      return null;
    } catch (e) {
      log('[CallDataSources] Error getting active call: $e');
      return null;
    }
  }

  // ============================================================
  // CLEANUP OPERATIONS
  // ============================================================

  /// Clean up stale calls that are stuck in active states.
  ///
  /// Marks calls older than [staleThresholdMinutes] as ended.
  Future<int> cleanupStaleCalls(
    String userId, {
    int staleThresholdMinutes = 5,
  }) async {
    try {
      final cutoffTime = DateTime.now()
          .subtract(Duration(minutes: staleThresholdMinutes))
          .millisecondsSinceEpoch;

      final activeStatuses = [
        CallStatus.outgoing.name,
        CallStatus.incoming.name,
        CallStatus.ringing.name,
        CallStatus.connected.name,
      ];

      int cleanedCount = 0;

      // Clean outgoing
      final staleOutgoing = await _callsCollection
          .where('callerId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .where('time', isLessThan: cutoffTime)
          .get();

      // Clean incoming
      final staleIncoming = await _callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', whereIn: activeStatuses)
          .where('time', isLessThan: cutoffTime)
          .get();

      // Batch update
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in [...staleOutgoing.docs, ...staleIncoming.docs]) {
        batch.update(doc.reference, {
          'callStatus': CallStatus.ended.name,
        });
        cleanedCount++;
      }

      if (cleanedCount > 0) {
        await batch.commit();
        log('[CallDataSources] Cleaned up $cleanedCount stale calls');
      }

      return cleanedCount;
    } catch (e) {
      log('[CallDataSources] Error cleaning up stale calls: $e');
      return 0;
    }
  }

  /// Delete all calls for a user (use with caution).
  Future<bool> deleteAllUserCalls(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final outgoingDocs = await _callsCollection
          .where('callerId', isEqualTo: userId)
          .get();

      final incomingDocs = await _callsCollection
          .where('calleeId', isEqualTo: userId)
          .get();

      for (final doc in [...outgoingDocs.docs, ...incomingDocs.docs]) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      log('[CallDataSources] Deleted all calls for user: $userId');
      return true;
    } catch (e) {
      log('[CallDataSources] Error deleting all calls: $e');
      return false;
    }
  }

  // ============================================================
  // ZEGO SERVICE INTEGRATION
  // ============================================================

  /// Initialize ZEGO for user login.
  ///
  /// This delegates to ZegoCallService for actual ZEGO operations.
  Future<void> onUserLogin(String userId, String userName) async {
    try {
      await ZegoCallService.instance.loginUser(
        userId: userId,
        userName: userName,
      );

      // Clean up any stale calls from previous sessions
      await cleanupStaleCalls(userId);

      log('[CallDataSources] User logged in to call service: $userId');
    } catch (e) {
      log('[CallDataSources] Error during user login: $e');
      rethrow;
    }
  }

  /// Logout user from ZEGO.
  void onUserLogout() {
    ZegoCallService.instance.logoutUser();
    log('[CallDataSources] User logged out from call service');
  }
}

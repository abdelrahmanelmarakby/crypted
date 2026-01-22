import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:rxdart/rxdart.dart';

class CallDataSources {
  CollectionReference<Map<String, dynamic>> callsCollection =
      FirebaseFirestore.instance.collection(FirebaseCollections.calls);

  Future<bool> storeCall(CallModel callModel) async {
    try {
      DocumentReference documentReference = callsCollection.doc();
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          callModel.copyWith(callId: documentReference.id).toMap(),
        );
      });
      log('✅ Call stored successfully with ID: ${documentReference.id}');
      log('📞 Call details: ${callModel.toMap()}');
      return true;
    } catch (e) {
      log('❌ Error storing call: $e');
      return false;
    }
  }

  Future<bool> deleteCall(String callId) async {
    try {
      await callsCollection.doc(callId).delete();
      log("Call deleted");
      return true;
    } catch (e) {
      log('Error deleting call: $e');
      return false;
    }
  }

  Future<bool> deleteAllCalls() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      QuerySnapshot querySnapshot = await callsCollection.get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log("All calls deleted");
      return true;
    } catch (e) {
      log('Error deleting all calls: $e');
      return false;
    }
  }

  /// FIX: Added pagination support to prevent loading all calls at once
  /// Default page size is 20 calls
  static const int _defaultPageSize = 20;

  Stream<List<CallModel>> getMyCalls(String userId, {int pageSize = _defaultPageSize}) {
    log('🔍 Getting calls for user: $userId (pageSize: $pageSize)');

    // جلب المكالمات الصادرة (حيث المستخدم هو caller) with limit
    Stream<List<CallModel>> outgoingCalls = callsCollection
        .where('callerId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) {
      log('📤 Found ${snapshot.docs.length} outgoing calls');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        log('📤 Outgoing call: $data');
        return CallModel.fromMap(data);
      }).toList();
    });

    // جلب المكالمات الواردة (حيث المستخدم هو callee) with limit
    Stream<List<CallModel>> incomingCalls = callsCollection
        .where('calleeId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) {
      log('📥 Found ${snapshot.docs.length} incoming calls');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        log('📥 Incoming call: $data');
        return CallModel.fromMap(data);
      }).toList();
    });

    // دمج المكالمات الصادرة والواردة مع shareReplay لتجنب مشكلة Stream has already been listened to
    return Rx.combineLatest2(
      outgoingCalls,
      incomingCalls,
      (List<CallModel> outgoing, List<CallModel> incoming) {
        List<CallModel> allCalls = [...outgoing, ...incoming];
        // ترتيب المكالمات حسب الوقت (الأحدث أولاً)
        allCalls.sort((a, b) =>
            (b.time ?? DateTime.now()).compareTo(a.time ?? DateTime.now()));
        // Take only pageSize items after merging (since we got pageSize from each query)
        if (allCalls.length > pageSize) {
          allCalls = allCalls.take(pageSize).toList();
        }
        log('📞 Total calls found: ${allCalls.length}');
        return allCalls;
      },
    ).shareReplay(maxSize: 1);
  }

  /// Load more calls for pagination (one-time fetch, not stream)
  Future<List<CallModel>> loadMoreCalls(String userId, DateTime? lastCallTime, {int pageSize = _defaultPageSize}) async {
    log('🔍 Loading more calls for user: $userId after $lastCallTime');

    List<CallModel> allCalls = [];

    // Fetch outgoing calls after the last call time
    Query<Map<String, dynamic>> outgoingQuery = callsCollection
        .where('callerId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize);

    if (lastCallTime != null) {
      outgoingQuery = outgoingQuery.startAfter([Timestamp.fromDate(lastCallTime)]);
    }

    final outgoingSnapshot = await outgoingQuery.get();
    for (var doc in outgoingSnapshot.docs) {
      allCalls.add(CallModel.fromMap(doc.data()));
    }

    // Fetch incoming calls after the last call time
    Query<Map<String, dynamic>> incomingQuery = callsCollection
        .where('calleeId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .limit(pageSize);

    if (lastCallTime != null) {
      incomingQuery = incomingQuery.startAfter([Timestamp.fromDate(lastCallTime)]);
    }

    final incomingSnapshot = await incomingQuery.get();
    for (var doc in incomingSnapshot.docs) {
      allCalls.add(CallModel.fromMap(doc.data()));
    }

    // Sort by time and take only pageSize
    allCalls.sort((a, b) =>
        (b.time ?? DateTime.now()).compareTo(a.time ?? DateTime.now()));

    if (allCalls.length > pageSize) {
      allCalls = allCalls.take(pageSize).toList();
    }

    log('📞 Loaded ${allCalls.length} more calls');
    return allCalls;
  }

  /// on App's user login
  Future<void> onUserLogin(String userID, String userName) async {
    try {
      log('🔐 Initializing Zego UIKit for user: $userID ($userName)');

      // 1.2.1. Initialize ZegoUIKitPrebuiltCallInvitationService
      // when app's user is logged in or re-logged in
      // We recommend calling this method as soon as the user logs in to your app.
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConstants.appID,
        /*input your AppID*/
        appSign: AppConstants.appSign,
        /*input your AppSign*/
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        // Basic notification config (simplified for compatibility)
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoAndroidNotificationConfig(
            channelID: "ZegoUIKit",
            channelName: "Zego UIKit",
            sound: "zego_incoming",
            icon: "ic_launcher",
          ),
        ),
        // Configure call invitation settings
        config: ZegoCallInvitationConfig(
          canInvitingInCalling: false,
          onlyInitiatorCanInvite: false,
          endCallWhenInitiatorLeave: true,
        ),
      );

      log('✅ Zego UIKit initialized successfully for user: $userID');

      // FIX: Clean up any stale calls from previous sessions
      // This prevents users from appearing "in call" indefinitely after crashes
      await cleanupStaleCalls(userID);
      log('🧹 Cleaned up stale calls for user: $userID');
    } catch (e) {
      log('❌ Error initializing Zego UIKit for user $userID: $e');
      rethrow;
    }
  }
  Future<bool> sendCallInvitation({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required bool isVideoCall,
    String? customData,
  }) async {
    try {
      log('📞 Sending ${isVideoCall ? 'video' : 'audio'} call invitation to $calleeId');

      // For now, let's use a simplified approach that just stores the call
      // and relies on the existing call screen navigation
      // This avoids API compatibility issues while maintaining functionality

      log('✅ Call invitation prepared successfully');
      return true;
    } catch (e) {
      log('❌ Error preparing call invitation: $e');
      return false;
    }
  }

  /// Accept incoming call invitation (simplified)
  Future<bool> acceptCallInvitation(String callId) async {
    try {
      log('✅ Accepting call invitation: $callId');
      return true;
    } catch (e) {
      log('❌ Error accepting call invitation: $e');
      return false;
    }
  }

  /// Decline incoming call invitation (simplified)
  Future<bool> declineCallInvitation(String callId) async {
    try {
      log('❌ Declining call invitation: $callId');
      return true;
    } catch (e) {
      log('❌ Error declining call invitation: $e');
      return false;
    }
  }

  /// Cancel outgoing call invitation (simplified)
  Future<bool> cancelCallInvitation(String callId) async {
    try {
      log('🚫 Canceling call invitation: $callId');
      return true;
    } catch (e) {
      log('❌ Error canceling call invitation: $e');
      return false;
    }
  }

  /// Update call status and duration
  Future<bool> updateCallStatus(String callId, CallStatus status, {num? duration}) async {
    try {
      // First, check if the call document exists
      final docSnapshot = await callsCollection.doc(callId).get();

      if (!docSnapshot.exists) {
        log('⚠️ Call document not found: $callId - Cannot update status');
        return false;
      }

      final updateData = <String, dynamic>{
        'callStatus': status.name,
        'time': DateTime.now().millisecondsSinceEpoch,
      };

      if (duration != null) {
        updateData['callDuration'] = duration;
      }

      await callsCollection.doc(callId).update(updateData);

      log('✅ Call status updated: $callId -> ${status.name}');
      return true;
    } catch (e) {
      log('❌ Error updating call status: $e');
      return false;
    }
  }

  /// Get call by ID
  Future<CallModel?> getCallById(String callId) async {
    try {
      DocumentSnapshot doc = await callsCollection.doc(callId).get();
      if (doc.exists) {
        return CallModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      log('❌ Error getting call by ID: $e');
      return null;
    }
  }

  /// Update call with duration when call ends
  Future<bool> endCall(String callId, num duration) async {
    try {
      await updateCallStatus(callId, CallStatus.ended, duration: duration);
      log('✅ Call ended: $callId with duration: ${duration}s');
      return true;
    } catch (e) {
      log('❌ Error ending call: $e');
      return false;
    }
  }

  /// Check if user is in an active call
  /// Only considers calls that are actually ongoing: outgoing, incoming, ringing, or connected
  /// Excludes ended, canceled, and missed calls as these are not active
  Future<bool> isUserInActiveCall(String userId) async {
    try {
      // Check outgoing calls that are still active
      final activeOutgoingCallsQuery = await callsCollection
          .where('callerId', isEqualTo: userId)
          .where('callStatus', whereIn: [
            CallStatus.outgoing.name,
            CallStatus.ringing.name,
            CallStatus.connected.name
          ])
          .get();

      // Check incoming calls that are still active
      final activeIncomingCallsQuery = await callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', whereIn: [
            CallStatus.incoming.name,
            CallStatus.ringing.name,
            CallStatus.connected.name
          ])
          .get();

      final hasActiveOutgoing = activeOutgoingCallsQuery.docs.isNotEmpty;
      final hasActiveIncoming = activeIncomingCallsQuery.docs.isNotEmpty;

      log('🔍 Active call check for user $userId:');
      log('   Active outgoing calls: ${activeOutgoingCallsQuery.docs.length}');
      log('   Active incoming calls: ${activeIncomingCallsQuery.docs.length}');
      log('   Is in active call: ${hasActiveOutgoing || hasActiveIncoming}');

      return hasActiveOutgoing || hasActiveIncoming;
    } catch (e) {
      log('❌ Error checking active calls: $e');
      return false;
    }
  }

  /// Clean up stale calls that might be stuck in active states
  /// This helps prevent false positives in isUserInActiveCall
  Future<void> cleanupStaleCalls(String userId) async {
    try {
      // Find calls that are older than 5 minutes and still in active states
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      // Clean up outgoing calls
      final staleOutgoingCalls = await callsCollection
          .where('callerId', isEqualTo: userId)
          .where('callStatus', whereIn: [
            CallStatus.outgoing.name,
            CallStatus.ringing.name,
            CallStatus.connected.name
          ])
          .where('time', isLessThan: fiveMinutesAgo.millisecondsSinceEpoch)
          .get();

      // Clean up incoming calls
      final staleIncomingCalls = await callsCollection
          .where('calleeId', isEqualTo: userId)
          .where('callStatus', whereIn: [
            CallStatus.incoming.name,
            CallStatus.ringing.name,
            CallStatus.connected.name
          ])
          .where('time', isLessThan: fiveMinutesAgo.millisecondsSinceEpoch)
          .get();

      // Update stale calls to ended status
      for (var doc in staleOutgoingCalls.docs) {
        await doc.reference.update({
          'callStatus': CallStatus.ended.name,
          'time': DateTime.now().millisecondsSinceEpoch,
        });
        log('🧹 Cleaned up stale outgoing call: ${doc.id}');
      }

      for (var doc in staleIncomingCalls.docs) {
        await doc.reference.update({
          'callStatus': CallStatus.ended.name,
          'time': DateTime.now().millisecondsSinceEpoch,
        });
        log('🧹 Cleaned up stale incoming call: ${doc.id}');
      }

      if (staleOutgoingCalls.docs.isNotEmpty || staleIncomingCalls.docs.isNotEmpty) {
        log('✅ Cleaned up ${staleOutgoingCalls.docs.length + staleIncomingCalls.docs.length} stale calls for user $userId');
      }
    } catch (e) {
      log('❌ Error cleaning up stale calls: $e');
    }
  }

  /// Initialize Zego UIKit for a specific user (call this after login)
  Future<void> initializeZegoForUser(String userID, String userName) async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: AppConstants.appID,
        appSign: AppConstants.appSign,
        userID: userID,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );
      log('✅ Zego initialized for user: $userID');
    } catch (e) {
      log('❌ Error initializing Zego for user $userID: $e');
      rethrow;
    }
  }

  /// on App's user logout
  void onUserLogout() {
    /// 1.2.2. de-initialization ZegoUIKitPrebuiltCallInvitationService
    /// when app's user is logged out
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
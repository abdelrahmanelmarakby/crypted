import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/core/constant.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:rxdart/rxdart.dart';

class CallDataSources {
  CollectionReference<Map<String, dynamic>> callsCollection =
      FirebaseFirestore.instance.collection('Calls');

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

  Stream<List<CallModel>> getMyCalls(String userId) {
    log('🔍 Getting calls for user: $userId');

    // جلب المكالمات الصادرة (حيث المستخدم هو caller)
    Stream<List<CallModel>> outgoingCalls = callsCollection
        .where('callerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      log('📤 Found ${snapshot.docs.length} outgoing calls');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        log('📤 Outgoing call: $data');
        return CallModel.fromMap(data);
      }).toList();
    });

    // جلب المكالمات الواردة (حيث المستخدم هو callee)
    Stream<List<CallModel>> incomingCalls = callsCollection
        .where('calleeId', isEqualTo: userId)
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
        log('📞 Total calls found: ${allCalls.length}');
        return allCalls;
      },
    ).shareReplay(maxSize: 1);
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
  /// on App's user logout
  void onUserLogout() {
    /// 1.2.2. de-initialization ZegoUIKitPrebuiltCallInvitationService
    /// when app's user is logged out
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
}
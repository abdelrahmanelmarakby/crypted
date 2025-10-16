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
    /// 1.2.1. initialized ZegoUIKitPrebuiltCallInvitationService
    /// when app's user is logged in or re-logged in
    /// We recommend calling this method as soon as the user logs in to your app.
    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: AppConstants.appID,
      /*input your AppID*/
      appSign: AppConstants.appSign,
      /*input your AppSign*/
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  /// on App's user logout
  void onUserLogout() {
    /// 1.2.2. de-initialization ZegoUIKitPrebuiltCallInvitationService
    /// when app's user is logged out
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}

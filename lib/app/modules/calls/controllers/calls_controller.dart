import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallsController extends GetxController {
  CallDataSources callDataSource = CallDataSources();
  ChatDataSources chatDataSource = ChatDataSources(
    chatConfiguration: ChatConfiguration(
      members: [ UserService.currentUser.value??SocialMediaUser(
        uid: FirebaseAuth.instance.currentUser?.uid,
        fullName: FirebaseAuth.instance.currentUser?.displayName,
        imageUrl  : FirebaseAuth.instance.currentUser?.photoURL,
      ), ],
    ),
  );

  late Stream<List<CallModel>> calls;
  late Stream<List<CallModel>> callsFromChat;

  // متغير للبحث
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    // استخدام UserService.currentUser.value بدلاً من CacheHelper
    final userId =
        UserService.currentUser.value?.uid ?? CacheHelper.getUserId ?? '';
    print('🔍 CallsController: Initializing with userId: $userId');

    // إنشاء streams مع shareReplay
    calls = callDataSource.getMyCalls(userId);
    callsFromChat = _getCallsFromChat(userId);

    // إضافة listener للتحديثات
    ever(UserService.currentUser, (user) {
      if (user != null) {
        print('🔍 CallsController: User updated, refreshing calls');
        final newUserId = user.uid ?? CacheHelper.getUserId ?? '';
        calls = callDataSource.getMyCalls(newUserId);
        callsFromChat = _getCallsFromChat(newUserId);
        update();
      }
    });

    super.onInit();
  }

  Stream<List<CallModel>> _getCallsFromChat(String userId) {
    return chatDataSource.getChats(getGroupChatOnly: false, getPrivateChatOnly: false).map((chatRooms) {
      List<CallModel> callModels = [];
      for (var chatRoom in chatRooms) {
        // هذا الجزء يحتاج إلى إعادة تقييم لأن getLivePrivateMessage مصمم لغرفة شات محددة
        chatDataSource.getLivePrivateMessage(chatRoom.id??"").listen((messages) {
          for (var message in messages) {
            if (message is CallMessage) {
              CallModel callModel = CallModel(
                callId: message.id,
                channelName: message.roomId,
                callerId: message.callModel.callerId,
                callerUserName: message.callModel.callerUserName,
                callerImage: message.callModel.callerImage,
                calleeId: message.callModel.calleeId,
                calleeUserName: message.callModel.calleeUserName,
                calleeImage: message.callModel.calleeImage,
                time: message.timestamp,
                callDuration: message.callModel.callDuration,
                callType: message.callModel.callType,
                callStatus: message.callModel.callStatus,
              );
              callModels.add(callModel);
            }
          }
        });
      }
      return callModels;
    }).shareReplay(maxSize: 1);
  }

  // دالة لتحديث المكالمات يدوياً
  void refreshCalls() {
    final userId =
        UserService.currentUser.value?.uid ?? CacheHelper.getUserId ?? '';
    print('🔍 CallsController: Manually refreshing calls for user: $userId');

    // إعادة إنشاء streams
    calls = callDataSource.getMyCalls(userId);
    callsFromChat = _getCallsFromChat(userId);

    // تحديث الواجهة
    update();

    print('✅ CallsController: Refresh completed');
  }

  // دالة لحفظ مكالمة جديدة
  Future<void> saveCallToFirestore(CallModel callModel) async {
    try {
      await callDataSource.storeCall(callModel);
      print('✅ Call saved to Firestore successfully');
      // تحديث المكالمات بعد الحفظ
      refreshCalls();
    } catch (e) {
      print('❌ Error saving call to Firestore: $e');
    }
  }

  // دالة لحذف مكالمة
  Future<void> deleteCall(String callId) async {
    try {
      await callDataSource.deleteCall(callId);
      print('✅ Call deleted from Firestore successfully');
      // تحديث المكالمات بعد الحذف
      refreshCalls();
    } catch (e) {
      print('❌ Error deleting call from Firestore: $e');
    }
  }

  // دالة للبحث في المكالمات
  void searchCalls(String query) {
    searchQuery.value = query.toLowerCase();
    print('🔍 Searching calls with query: $query');
    update(); // تحديث الواجهة
  }

  // دالة لمسح البحث
  void clearSearch() {
    searchQuery.value = '';
    print('🔍 Search cleared');
  }

  // دالة للحصول على المكالمات المفلترة حسب البحث والحالة
  Stream<List<CallModel>> getFilteredCalls(CallStatus callStatus) {
    return calls.map((allCalls) {
      // أولاً، فلترة حسب البحث
      List<CallModel> searchFiltered = allCalls;
      final currentSearchQuery = searchQuery.value;

      if (currentSearchQuery.isNotEmpty) {
        searchFiltered = allCalls.where((call) {
          final callerName = call.callerUserName?.toLowerCase() ?? '';
          final calleeName = call.calleeUserName?.toLowerCase() ?? '';
          final callerId = call.callerId?.toLowerCase() ?? '';
          final calleeId = call.calleeId?.toLowerCase() ?? '';

          return callerName.contains(currentSearchQuery) ||
              calleeName.contains(currentSearchQuery) ||
              callerId.contains(currentSearchQuery) ||
              calleeId.contains(currentSearchQuery);
        }).toList();
      }

      // ثانياً، فلترة حسب الحالة
      List<CallModel> statusFiltered = searchFiltered.where((call) {
        switch (callStatus) {
          case CallStatus.incoming:
            return call.callStatus == CallStatus.incoming;
          case CallStatus.outgoing:
            return call.callStatus == CallStatus.outgoing;
          case CallStatus.connected:
            return call.callStatus == CallStatus.connected;
          case CallStatus.missed:
            return call.callStatus == CallStatus.missed;
          case CallStatus.uknown:
            // في حالة All، نعرض جميع المكالمات
            return true;
          default:
            // في حالة All، نعرض جميع المكالمات
            return true;
        }
      }).toList();

      print('🔍 Search query: "$currentSearchQuery"');
      print('🔍 Call status filter: $callStatus');
      print('🔍 Total calls: ${allCalls.length}');
      print('🔍 Search filtered: ${searchFiltered.length}');
      print('🔍 Status filtered: ${statusFiltered.length}');

      return statusFiltered;
    }).shareReplay(maxSize: 1);
  }
}

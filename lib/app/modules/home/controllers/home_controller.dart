import 'package:bot_toast/bot_toast.dart';
import 'package:crypted_app/app/core/services/chat_session_manager.dart';
import 'package:crypted_app/app/data/data_source/call_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/data_source/chat/chat_services_parameters.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/core/extensions/string.dart';
import 'package:crypted_app/core/services/cache_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/auth_data_sources.dart';

class HomeController extends GetxController {
  final RxList<SocialMediaUser> users = <SocialMediaUser>[].obs;
  late Future<List<SocialMediaUser>> futureUsers;
  late RxList<SocialMediaUser> selectedUsers = <SocialMediaUser>[].obs;
  CallDataSources callDataSources = CallDataSources();

  // إضافة متغير المستخدم التفاعلي
  Rxn<SocialMediaUser> myUser = Rxn<SocialMediaUser>();

  // متغير البحث
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    futureUsers = AuthenticationService.getAllUsers();
    fetchUsers();

    // مراقبة التغييرات في UserService.currentUser
    ever(UserService.currentUser, (user) {
      if (user != null) {
        myUser.value = user;
      }
    });
  }

  @override
  void onReady() async {
    SocialMediaUser? user = await UserService().getProfile(
        FirebaseAuth.instance.currentUser?.uid ?? CacheHelper.getUserId ?? "");
    myUser.value = user;
    // إعادة تهيئة Zego عند كل دخول مستخدم
    if (user != null && user.uid != null && user.fullName != null) {
      await CallDataSources().onUserLogin(user.uid!, user.fullName!);
    }
    super.onReady();
  }

  void creatNewChatRoom(SocialMediaUser user) async {
    try {
      // التأكد من وجود المستخدم الحالي
      if (UserService.currentUser.value == null) {
        BotToast.showText(text: 'User not loaded. Please try again.');
        return;
      }

      // تحديد المرسل والمستقبل من البداية
      final currentUser = UserService.currentUser.value!;
      final otherUser = user;

      print("🎯 Setting up chat session:");
      print(
          "👤 Current User (Sender): ${currentUser.fullName} (${currentUser.uid})");
      print(
          "👥 Selected User (Receiver): ${otherUser.fullName} (${otherUser.uid})");

      // بدء جلسة الشات باستخدام مدير الجلسة
      ChatSessionManager.instance.startChatSession(
        sender: currentUser,
        receiver: otherUser,
      );

      Get.dialog(
        const Center(child: CustomLoading()),
        barrierDismissible: false,
      );

      final ChatDataSources chatDataSources = ChatDataSources(
        chatConfiguration: ChatConfiguration(
          members: [ currentUser, otherUser ],
        ),
      );

      final chatRoom = await chatDataSources.createNewChatRoom(
        members: [ currentUser, otherUser ],
        isGroupChat: false);
      print("✅ Chat room created: ${chatRoom.toMap()}");

      Get.back();

      Get.toNamed(
        Routes.CHAT,
        arguments: {
          "useSessionManager": true,
          "roomId": chatRoom.id,
          "members": [ currentUser, otherUser ],
        },
      );
    } catch (e) {
      print("❌ Error creating chat room: $e");
      Get.back();
      BotToast.showText(text: 'Failed to create chat room. Please try again.');
    }
  }

  void fetchUsers() async {
    try {
      final userList = await futureUsers;
      users.value = userList;
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  
// Add these methods
void toggleUserSelection(SocialMediaUser user) {
  if (selectedUsers.contains(user)) {
    selectedUsers.remove(user);
  } else {
    selectedUsers.add(user);
  }
}
}

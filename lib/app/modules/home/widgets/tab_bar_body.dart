import 'dart:developer';

import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/core/extensions/string.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/data_source/chat/chat_data_sources.dart';
import '../../../data/data_source/chat/chat_services_parameters.dart';
import '../../../data/data_source/user_services.dart';
import '../../../data/models/chat/chat_room_model.dart';
import 'chat_row.dart';

class TabBarBody extends StatelessWidget {
  const TabBarBody({super.key,  this.getGroupChatOnly, required this.getPrivateChatOnly});
  final bool? getGroupChatOnly;
  final bool? getPrivateChatOnly;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatDataSources(
        chatConfiguration: ChatConfiguration(
          members: [ UserService.currentUser.value??SocialMediaUser(
            uid: FirebaseAuth.instance.currentUser?.uid,
            fullName: FirebaseAuth.instance.currentUser?.displayName,
            imageUrl  : FirebaseAuth.instance.currentUser?.photoURL,
          ), ],
        ),
      ).getChats(getGroupChatOnly: getGroupChatOnly??false, getPrivateChatOnly: getPrivateChatOnly??false),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<ChatRoom>? getRecentChat = snapshot.data;
          
          final myId = UserService.currentUser.value?.uid;
          final myChats = getRecentChat
              ?.where((chatRoom) =>
                  chatRoom.membersIds?.contains(myId) ?? false)
              .toList();

          if (myChats?.isNotEmpty ?? false) {
            return ListView.builder(
              itemCount: myChats?.length ?? 0,
              itemBuilder: (context, index) {
                ChatRoom? chatRoom = myChats?[index];
                return ChatRow(
                  chatRoom: chatRoom,
                );
              },
            );
          } else {
            return Center(
              child: Text(
                Constants.kNoChatsyet.tr,
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: FontSize.small,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
        } else if (snapshot.hasError) {
          log("Error fetching chats: ${snapshot.error}");
          return const Center(child: Text("‼️ Ooooh no! Could not fetch chats ‼️", style: TextStyle(color: ColorsManager.error),));
        } else {
          return const CustomLoading();
        }
      },
    );
  }
}

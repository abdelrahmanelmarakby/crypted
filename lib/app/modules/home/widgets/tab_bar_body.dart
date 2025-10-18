import 'dart:developer';

import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/data_source/chat/chat_data_sources.dart';
import '../../../data/data_source/chat/chat_services_parameters.dart';
import '../../../data/data_source/user_services.dart';
import '../../../data/models/chat/chat_room_model.dart';
import 'chat_row.dart';

class TabBarBody extends StatelessWidget {
  const TabBarBody({
    super.key,
    this.getGroupChatOnly,
    this.getPrivateChatOnly,
    this.getUnreadOnly = false,
    this.getFavoriteOnly = false,
  });

  final bool? getGroupChatOnly;
  final bool? getPrivateChatOnly;
  final bool getUnreadOnly;
  final bool getFavoriteOnly;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatDataSources(
        chatConfiguration: ChatConfiguration(
          members: [UserService.currentUser.value ?? SocialMediaUser(
            uid: FirebaseAuth.instance.currentUser?.uid,
            fullName: FirebaseAuth.instance.currentUser?.displayName,
            imageUrl: FirebaseAuth.instance.currentUser?.photoURL,
          )],
        ),
      ).getChats(
        getGroupChatOnly: getGroupChatOnly ?? false,
        getPrivateChatOnly: getPrivateChatOnly ?? false,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<ChatRoom>? allChats = snapshot.data;

          // Apply additional filtering based on tab selection
          List<ChatRoom>? filteredChats = _applyAdditionalFilters(allChats);

          final myId = UserService.currentUser.value?.uid;
          final myChats = filteredChats
              ?.where((chatRoom) =>
                  chatRoom.membersIds?.contains(myId) ?? false)
              .toList();

          print("DEBUG: Total chats: ${allChats?.length ?? 0}, Filtered chats: ${filteredChats?.length ?? 0}, My chats: ${myChats?.length ?? 0}");

          if (myChats?.isNotEmpty ?? false) {
            return ListView.builder(
              itemCount: myChats?.length ?? 0,
              itemBuilder: (context, index) {
                ChatRoom? chatRoom = myChats?[index];
                print("Chatrow members: ${chatRoom?.members}");
                print("Chatrow ${chatRoom}");
                return ChatRow(
                  chatRoom: chatRoom,
                );
              },
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: ColorsManager.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _getEmptyStateMessage(),
                    style: TextStyle(
                      color: ColorsManager.primary,
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getEmptyStateSubMessage(),
                    style: TextStyle(
                      color: ColorsManager.grey,
                      fontSize: FontSize.small,
                    ),
                  ),
                ],
              ),
            );
          }
        } else if (snapshot.hasError) {
          log("Error fetching chats: ${snapshot.error}");
          return const Center(
            child: Text(
              "‼️ Ooooh no! Could not fetch chats ‼️",
              style: TextStyle(color: ColorsManager.error),
            ),
          );
        } else {
          return const CustomLoading();
        }
      },
    );
  }

  /// Apply additional filters based on tab selection
  List<ChatRoom>? _applyAdditionalFilters(List<ChatRoom>? chats) {
    if (chats == null) return null;

    List<ChatRoom> filteredChats = chats;

    // Filter by unread status if required
    if (getUnreadOnly) {
      filteredChats = filteredChats.where((chat) {
        // Consider a chat unread if the last sender is not the current user
        return chat.lastSender != UserService.currentUser.value?.uid;
      }).toList();
    }

    // Filter by favorite status if required
    if (getFavoriteOnly) {
      // For now, we'll assume favorite chats are group chats or chats with specific criteria
      // This could be enhanced by adding a 'isFavorite' field to ChatRoom model
      filteredChats = filteredChats.where((chat) {
        // Example: Consider group chats as favorites, or implement proper favorite logic
        return chat.isGroupChat == true;
      }).toList();
    }

    return filteredChats;
  }

  /// Get appropriate empty state message based on current filter
  String _getEmptyStateMessage() {
    if (getUnreadOnly) {
      return "No unread chats";
    } else if (getFavoriteOnly) {
      return "No favorite chats";
    } else if (getGroupChatOnly == true) {
      return "No group chats yet";
    } else if (getPrivateChatOnly == true) {
      return "No private chats yet";
    } else {
      return "No chats yet";
    }
  }

  /// Get appropriate empty state sub-message based on current filter
  String _getEmptyStateSubMessage() {
    if (getUnreadOnly) {
      return "All your messages have been read";
    } else if (getFavoriteOnly) {
      return "Mark your favorite chats to see them here";
    } else if (getGroupChatOnly == true) {
      return "Create or join group chats to see them here";
    } else if (getPrivateChatOnly == true) {
      return "Start private conversations to see them here";
    } else {
      return "Start a conversation to see your chats here";
    }
  }
}

import 'dart:developer';

import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/data_source/chat/chat_data_sources.dart';
import '../../../data/data_source/chat/chat_services_parameters.dart';
import '../../../data/data_source/user_services.dart';
import '../../../data/models/chat/chat_room_model.dart';
import 'chat_row.dart';

class TabBarBody extends StatefulWidget {
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
  State<TabBarBody> createState() => _TabBarBodyState();
}

class _TabBarBodyState extends State<TabBarBody> {
  bool _archivedExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoom>>(
      stream: ChatDataSources(
        chatConfiguration: ChatConfiguration(
          members: [
            UserService.currentUser.value ??
                SocialMediaUser(
                  uid: FirebaseAuth.instance.currentUser?.uid,
                  fullName: FirebaseAuth.instance.currentUser?.displayName,
                  imageUrl: FirebaseAuth.instance.currentUser?.photoURL,
                )
          ],
        ),
      ).getChats(
        getGroupChatOnly: widget.getGroupChatOnly ?? false,
        getPrivateChatOnly: widget.getPrivateChatOnly ?? false,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<ChatRoom>? allChats = snapshot.data;

          // Apply additional filtering based on tab selection
          List<ChatRoom>? filteredChats = _applyAdditionalFilters(allChats);

          final myId = UserService.currentUser.value?.uid;
          final myChats = filteredChats
              ?.where(
                  (chatRoom) => chatRoom.membersIds?.contains(myId) ?? false)
              .toList();

          // Split into active and archived
          final activeChats =
              myChats?.where((c) => !(c.isArchived ?? false)).toList();
          final archivedChats =
              myChats?.where((c) => c.isArchived ?? false).toList();

          // Sort active chats: pinned first, then by time
          _sortChats(activeChats);
          // Sort archived chats by time only (no pin priority)
          _sortChatsByTime(archivedChats);

          print(
              "DEBUG: Total chats: ${allChats?.length ?? 0}, Active: ${activeChats?.length ?? 0}, Archived: ${archivedChats?.length ?? 0}");

          final hasActive = activeChats?.isNotEmpty ?? false;
          final hasArchived = archivedChats?.isNotEmpty ?? false;

          if (hasActive || hasArchived) {
            return ListView.builder(
              itemCount: (activeChats?.length ?? 0) +
                  (hasArchived ? 1 : 0) // archive header row
                  +
                  (_archivedExpanded ? (archivedChats?.length ?? 0) : 0),
              itemBuilder: (context, index) {
                final activeCount = activeChats?.length ?? 0;

                // Active chat rows
                if (index < activeCount) {
                  return ChatRow(chatRoom: activeChats?[index]);
                }

                // Archive section header
                if (index == activeCount && hasArchived) {
                  return _buildArchivedHeader(archivedChats?.length ?? 0);
                }

                // Archived chat rows (only if expanded)
                if (_archivedExpanded) {
                  final archivedIndex = index - activeCount - 1;
                  if (archivedIndex >= 0 &&
                      archivedIndex < (archivedChats?.length ?? 0)) {
                    return ChatRow(chatRoom: archivedChats?[archivedIndex]);
                  }
                }

                return const SizedBox.shrink();
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
          log("Error fetching chats: ${snapshot.error.toString() + snapshot.stackTrace.toString()}");
          return const Center(
            child: Text(
              "Ooooh no! Could not fetch chats",
              style: TextStyle(color: ColorsManager.error),
            ),
          );
        } else {
          return const CustomLoading();
        }
      },
    );
  }

  /// Collapsible archived chats section header
  Widget _buildArchivedHeader(int count) {
    return InkWell(
      onTap: () => setState(() => _archivedExpanded = !_archivedExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.small,
        ),
        decoration: BoxDecoration(
          color: ColorsManager.grey.withValues(alpha: 0.08),
          border: const Border(
            top: BorderSide(color: ColorsManager.border, width: 0.5),
            bottom: BorderSide(color: ColorsManager.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.archive_outlined,
              size: 18,
              color: ColorsManager.grey,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                'Archived ($count)',
                style: StylesManager.semiBold(
                  fontSize: FontSize.small,
                  color: ColorsManager.grey,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _archivedExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: ColorsManager.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sort active chats: pinned first, then by last message time
  void _sortChats(List<ChatRoom>? chats) {
    if (chats == null || chats.isEmpty) return;
    chats.sort((a, b) {
      // Pinned chats first
      if ((a.isPinned ?? false) && !(b.isPinned ?? false)) return -1;
      if (!(a.isPinned ?? false) && (b.isPinned ?? false)) return 1;
      // Then by time
      return _compareByTime(a, b);
    });
  }

  /// Sort chats by last message time only (no pin priority)
  void _sortChatsByTime(List<ChatRoom>? chats) {
    if (chats == null || chats.isEmpty) return;
    chats.sort(_compareByTime);
  }

  int _compareByTime(ChatRoom a, ChatRoom b) {
    final aTime = _parseTimestamp(a.lastChat);
    final bTime = _parseTimestamp(b.lastChat);
    if (aTime != null && bTime != null) return bTime.compareTo(aTime);
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    return 0;
  }

  /// Apply additional filters based on tab selection
  List<ChatRoom>? _applyAdditionalFilters(List<ChatRoom>? chats) {
    if (chats == null) return null;

    List<ChatRoom> filteredChats = chats;

    // Filter by unread status if required
    if (widget.getUnreadOnly) {
      filteredChats = filteredChats.where((chat) {
        // Consider a chat unread if the last sender is not the current user
        return chat.lastSender != UserService.currentUser.value?.uid;
      }).toList();
    }

    // Filter by favorite status if required
    if (widget.getFavoriteOnly) {
      filteredChats = filteredChats.where((chat) {
        return chat.isFavorite == true;
      }).toList();
    }

    return filteredChats;
  }

  /// Get appropriate empty state message based on current filter
  String _getEmptyStateMessage() {
    if (widget.getUnreadOnly) {
      return "No unread chats";
    } else if (widget.getFavoriteOnly) {
      return "No favorite chats";
    } else if (widget.getGroupChatOnly == true) {
      return "No group chats yet";
    } else if (widget.getPrivateChatOnly == true) {
      return "No private chats yet";
    } else {
      return "No chats yet";
    }
  }

  /// Get appropriate empty state sub-message based on current filter
  String _getEmptyStateSubMessage() {
    if (widget.getUnreadOnly) {
      return "All your messages have been read";
    } else if (widget.getFavoriteOnly) {
      return "Mark your favorite chats to see them here";
    } else if (widget.getGroupChatOnly == true) {
      return "Create or join group chats to see them here";
    } else if (widget.getPrivateChatOnly == true) {
      return "Start private conversations to see them here";
    } else {
      return "Start a conversation to see your chats here";
    }
  }

  /// Parse timestamp string to DateTime for sorting
  DateTime? _parseTimestamp(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return null;

    try {
      // Try to parse as ISO string first
      return DateTime.tryParse(timestampStr);
    } catch (e) {
      print("Failed to parse timestamp: $timestampStr");
      return null;
    }
  }
}

import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

class MessageSearchController extends GetxController {
  final ChatDataSources _chatDataSources = ChatDataSources();

  final RxList<Message> _searchResults = <Message>[].obs;
  final RxList<SocialMediaUser> _userResults = <SocialMediaUser>[].obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;

  List<Message> get searchResults => _searchResults;
  List<SocialMediaUser> get userResults => _userResults;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;

  void searchMessages(String query) {
    _searchQuery.value = query.trim();

    if (_searchQuery.value.isEmpty) {
      _clearResults();
      return;
    }

    _isSearching.value = true;

    // Search in messages
    _searchInMessages();

    // Search in users (for starting new chats)
    _searchInUsers();
  }

  void _searchInMessages() {
    _chatDataSources.getChats(getGroupChatOnly: false, getPrivateChatOnly: false)
        .listen((chatRooms) async {
      List<Message> results = [];
      Map<String, String> chatNames = {}; // Cache for chat names

      // For each chat room, search through recent messages
      for (var chatRoom in chatRooms) {
        try {
          // Get chat name for display
          String chatName = await _getChatNameForSearch(chatRoom);
          chatNames[chatRoom.id ?? ''] = chatName;

          // Get recent messages from this chat room
          final messages = await _chatDataSources.getLivePrivateMessage(chatRoom.id ?? "").first;

          // Search through messages in this chat room
          for (var message in messages) {
            if (_messageMatchesQuery(message, _searchQuery.value)) {
              // Create a copy of the message with chat name info
              final messageWithChatName = await _enhanceMessageWithChatInfo(message, chatName);
              results.add(messageWithChatName);
            }
          }
        } catch (e) {
          print('Error searching in chat ${chatRoom.id}: $e');
        }
      }

      // Sort results by relevance and timestamp
      results.sort((a, b) {
        // More recent messages first
        final aTime = a.timestamp;
        final bTime = b.timestamp;
        if (aTime == null && bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      // Limit results to prevent UI overload
      if (results.length > 50) {
        results = results.sublist(0, 50);
      }

      _searchResults.assignAll(results);
      _isSearching.value = false;
    });
  }

  Future<String> _getChatNameForSearch(ChatRoom chatRoom) async {
    try {
      final currentUserId = UserService.currentUserValue?.uid ?? '';

      // Handle group chats
      if (chatRoom.isGroupChat == true && chatRoom.name != null && chatRoom.name!.isNotEmpty) {
        return chatRoom.name!;
      }

      // Handle private chats (1-on-1)
      if (chatRoom.membersIds != null && chatRoom.membersIds!.length == 2) {
        // Find the other user (not current user)
        final otherUserId = chatRoom.membersIds!.firstWhere((id) => id != currentUserId);
        if (otherUserId.isNotEmpty) {
          // Get the other user's profile
          final otherUser = await UserService().getProfile(otherUserId);
          if (otherUser != null && otherUser.fullName != null && otherUser.fullName!.isNotEmpty) {
            return otherUser.fullName!;
          }
        }
      }

      // Fallback to group name if available
      if (chatRoom.name != null && chatRoom.name!.isNotEmpty) {
        return chatRoom.name!;
      }

      // Final fallback
      return chatRoom.id ?? 'Unknown Chat';
    } catch (e) {
      print('Error resolving chat name: $e');
      return chatRoom.id ?? 'Unknown Chat';
    }
  }

  Future<Message> _enhanceMessageWithChatInfo(Message message, String chatName) async {
    // For now, just return the original message
    // In a more advanced implementation, you could create a wrapper
    // that includes chat name information
    return message;
  }

  bool _messageMatchesQuery(Message message, String query) {
    if (query.isEmpty) return false;

    // Search in message content based on type
    String? content = _getMessageContent(message);
    if (content != null && content.toLowerCase().contains(query.toLowerCase())) {
      return true;
    }

    // Search in sender name (if available)
    // This would require getting user data for the sender ID
    // For now, we'll just search in content

    return false;
  }

  String? _getMessageContent(Message message) {
    // Handle different message types
    if (message is TextMessage) {
      return message.text;
    } else if (message is PhotoMessage) {
      return '📷 Photo';
    } else if (message is VideoMessage) {
      return '🎥 Video';
    } else if (message is AudioMessage) {
      return '🎵 Audio';
    } else if (message is FileMessage) {
      return '📄 File: ${message.fileName}';
    } else if (message is ContactMessage) {
      return '👤 Contact';
    } else if (message is LocationMessage) {
      return '📍 Location';
    } else if (message is PollMessage) {
      return '📊 Poll';
    } else if (message is CallMessage) {
      return '📞 ${message.callModel.callType == CallType.video ? 'Video' : 'Voice'} Call';
    } else {
      return null;
    }
  }

  void _searchInUsers() {
    // Search for users to start new chats
    if (_searchQuery.value.isEmpty) {
      _userResults.clear();
      _isSearching.value = false;
      return;
    }

    try {
      // Search for users using UserService
      UserService().getAllUsers(searchQuery: _searchQuery.value).then((users) {
        // Filter out current user and limit results
        final filteredUsers = users
            .where((user) => user.uid != UserService.currentUserValue?.uid)
            .take(20) // Limit to 20 results
            .toList();

        _userResults.assignAll(filteredUsers);
        _isSearching.value = false;
      }).catchError((e) {
        print('Error searching users: $e');
        _userResults.clear();
        _isSearching.value = false;
      });
    } catch (e) {
      print('Error in user search: $e');
      _userResults.clear();
      _isSearching.value = false;
    }
  }

  void _clearResults() {
    _searchResults.clear();
    _userResults.clear();
    _isSearching.value = false;
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearResults();
  }

  @override
  void onClose() {
    _searchResults.close();
    _userResults.close();
    _searchQuery.close();
    _isSearching.close();
    super.onClose();
  }
}

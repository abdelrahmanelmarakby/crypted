import 'package:crypted_app/app/data/data_source/chat/chat_data_sources.dart';
import 'package:crypted_app/app/data/models/call_model.dart';
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
    // This is a simplified search - in a real implementation,
    // you would search through all messages across all chats
    // For now, we'll implement a basic search that would need
    // to be expanded based on your data structure

    // TODO: Implement proper message search across all chats
    // This would require:
    // 1. Getting all chat rooms for current user
    // 2. Searching messages in each chat
    // 3. Filtering and ranking results

    _chatDataSources.getChats(getGroupChatOnly: false, getPrivateChatOnly: false)
        .listen((chatRooms) {
      List<Message> results = [];

      // For each chat room, search through recent messages
      for (var chatRoom in chatRooms) {
        // Get recent messages from this chat room
        _chatDataSources.getLivePrivateMessage(chatRoom.id ?? "").listen((messages) {
          // Search through messages in this chat room
          for (var message in messages) {
            if (_messageMatchesQuery(message, _searchQuery.value)) {
              results.add(message);
            }
          }

          // Update results (this will cause duplicates if multiple rooms have results)
          // In a real implementation, you'd want to deduplicate and limit results
          _searchResults.assignAll(results);
          _isSearching.value = false;
        });
      }

      // If no chat rooms or no results after a delay, mark as not searching
      Future.delayed(const Duration(milliseconds: 500), () {
        if (results.isEmpty) {
          _isSearching.value = false;
        }
      });
    });
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
    // TODO: Implement user search functionality
    // This would search through your user database

    _userResults.clear();
    _isSearching.value = false;
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

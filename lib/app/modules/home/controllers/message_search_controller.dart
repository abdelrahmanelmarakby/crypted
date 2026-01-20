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
import 'package:shared_preferences/shared_preferences.dart';

enum MessageTypeFilter {
  all,
  text,
  photo,
  video,
  audio,
  file,
  poll,
  call,
  contact,
  location,
}

class MessageSearchController extends GetxController {
  final ChatDataSources _chatDataSources = ChatDataSources();

  final RxList<Message> _searchResults = <Message>[].obs;
  final RxList<Message> _allSearchResults = <Message>[].obs; // Store all results before filtering
  final RxList<SocialMediaUser> _userResults = <SocialMediaUser>[].obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final Rx<MessageTypeFilter> _selectedFilter = MessageTypeFilter.all.obs;
  final RxList<String> _recentSearches = <String>[].obs;

  List<Message> get searchResults => _searchResults;
  List<SocialMediaUser> get userResults => _userResults;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;
  MessageTypeFilter get selectedFilter => _selectedFilter.value;
  List<String> get recentSearches => _recentSearches;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  // Filter methods
  void selectFilter(MessageTypeFilter filter) {
    _selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    if (_selectedFilter.value == MessageTypeFilter.all) {
      _searchResults.assignAll(_allSearchResults);
      return;
    }

    final filtered = _allSearchResults.where((message) {
      switch (_selectedFilter.value) {
        case MessageTypeFilter.text:
          return message is TextMessage;
        case MessageTypeFilter.photo:
          return message is PhotoMessage;
        case MessageTypeFilter.video:
          return message is VideoMessage;
        case MessageTypeFilter.audio:
          return message is AudioMessage;
        case MessageTypeFilter.file:
          return message is FileMessage;
        case MessageTypeFilter.poll:
          return message is PollMessage;
        case MessageTypeFilter.call:
          return message is CallMessage;
        case MessageTypeFilter.contact:
          return message is ContactMessage;
        case MessageTypeFilter.location:
          return message is LocationMessage;
        default:
          return true;
      }
    }).toList();

    _searchResults.assignAll(filtered);
  }

  // Recent searches methods
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      _recentSearches.assignAll(searches);
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // Remove if already exists (to move to top)
      _recentSearches.remove(query);

      // Add to beginning
      _recentSearches.insert(0, query);

      // Keep only last 10 searches
      if (_recentSearches.length > 10) {
        _recentSearches.removeRange(10, _recentSearches.length);
      }

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      _recentSearches.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  void searchFromRecent(String query) {
    _searchQuery.value = query;
    searchMessages(query);
  }

  void searchMessages(String query) {
    _searchQuery.value = query.trim();

    if (_searchQuery.value.isEmpty) {
      _clearResults();
      return;
    }

    _isSearching.value = true;

    // Save to recent searches
    _saveRecentSearch(_searchQuery.value);

    // Reset filter to "All" when starting a new search
    _selectedFilter.value = MessageTypeFilter.all;

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
        final aTime = a.timestamp ?? DateTime.now();
        final bTime = b.timestamp ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Limit results to prevent UI overload
      if (results.length > 50) {
        results = results.sublist(0, 50);
      }

      // Store all results and filtered results
      _allSearchResults.assignAll(results);
      _applyFilter(); // Apply current filter
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
    _allSearchResults.clear();
    _userResults.clear();
    _isSearching.value = false;
  }

  void clearSearch() {
    _searchQuery.value = '';
    _selectedFilter.value = MessageTypeFilter.all;
    _clearResults();
  }

  /// Browse all messages of a specific type without requiring a search query.
  /// Used for quick access from search suggestions.
  void browseByType(MessageTypeFilter filter) {
    _selectedFilter.value = filter;
    _searchQuery.value = '*'; // Indicate we're browsing, not searching
    _isSearching.value = true;

    _chatDataSources.getChats(getGroupChatOnly: false, getPrivateChatOnly: false)
        .first.then((chatRooms) async {
      List<Message> results = [];

      // For each chat room, get messages of the selected type
      for (var chatRoom in chatRooms) {
        try {
          // Get chat name for display
          String chatName = await _getChatNameForSearch(chatRoom);

          // Get recent messages from this chat room
          final messages = await _chatDataSources.getLivePrivateMessage(chatRoom.id ?? "").first;

          // Filter messages by type (no query match needed)
          for (var message in messages) {
            if (_messageMatchesType(message, filter)) {
              final messageWithChatName = await _enhanceMessageWithChatInfo(message, chatName);
              results.add(messageWithChatName);
            }
          }
        } catch (e) {
          print('Error browsing chat ${chatRoom.id}: $e');
        }
      }

      // Sort by most recent first
      results.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.now();
        final bTime = b.timestamp ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Limit results
      if (results.length > 100) {
        results = results.sublist(0, 100);
      }

      _allSearchResults.assignAll(results);
      _searchResults.assignAll(results); // No additional filtering needed
      _isSearching.value = false;
      update();
    }).catchError((e) {
      print('Error browsing by type: $e');
      _isSearching.value = false;
    });
  }

  /// Check if a message matches the specified type filter
  bool _messageMatchesType(Message message, MessageTypeFilter filter) {
    switch (filter) {
      case MessageTypeFilter.all:
        return true;
      case MessageTypeFilter.text:
        return message is TextMessage;
      case MessageTypeFilter.photo:
        return message is PhotoMessage;
      case MessageTypeFilter.video:
        return message is VideoMessage;
      case MessageTypeFilter.audio:
        return message is AudioMessage;
      case MessageTypeFilter.file:
        return message is FileMessage;
      case MessageTypeFilter.poll:
        return message is PollMessage;
      case MessageTypeFilter.call:
        return message is CallMessage;
      case MessageTypeFilter.contact:
        return message is ContactMessage;
      case MessageTypeFilter.location:
        return message is LocationMessage;
    }
  }

  @override
  void onClose() {
    _searchResults.close();
    _allSearchResults.close();
    _userResults.close();
    _searchQuery.close();
    _isSearching.close();
    _selectedFilter.close();
    _recentSearches.close();
    super.onClose();
  }
}

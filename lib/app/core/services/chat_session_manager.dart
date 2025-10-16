import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

/// Enhanced Chat Session Manager supporting both individual and group chats
class ChatSessionManager extends GetxController {
  static ChatSessionManager get instance => Get.find<ChatSessionManager>();

  // List to store all chat participants (supports 2+ members)
  final RxList<SocialMediaUser> _members = <SocialMediaUser>[].obs;

  // Chat session metadata
  final RxString _chatId = ''.obs;
  final RxString _chatName = ''.obs;
  final RxString _chatDescription = ''.obs;
  final RxBool _isGroupChat = false.obs;
  final RxBool _hasActiveSession = false.obs;

  // Getters for accessing chat data
  List<SocialMediaUser> get members => _members.toList();
  String get chatId => _chatId.value;
  String get chatName => _chatName.value;
  String get chatDescription => _chatDescription.value;
  bool get isGroupChat => _isGroupChat.value;
  bool get hasActiveSession => _hasActiveSession.value;
  int get memberCount => _members.length;

  // Legacy getters for backward compatibility (works for 1-on-1 chats)
  SocialMediaUser? get sender => _members.isNotEmpty ? _members[0] : null;
  SocialMediaUser? get receiver => _members.length > 1 ? _members[1] : null;

  // Streams for listening to changes
  Stream<List<SocialMediaUser>> get membersStream => _members.stream;
  Stream<SocialMediaUser?> get senderStream => _members.stream.map((list) => list.isNotEmpty ? list[0] : null);
  Stream<SocialMediaUser?> get receiverStream => _members.stream.map((list) => list.length > 1 ? list[1] : null);
  Stream<bool> get isGroupChatStream => _isGroupChat.stream;
  Stream<String> get chatNameStream => _chatName.stream;

  @override
  void onInit() {
    super.onInit();
    // Listen to member changes and update session status
    ever(_members, (_) => _updateSessionStatus());
  }

  /// Start a new 1-on-1 chat session (backward compatibility)
  void startChatSession({
    required SocialMediaUser sender,
    required SocialMediaUser receiver,
  }) {
    print("🚀 Starting 1-on-1 chat session:");
    print("👤 Sender: ${sender.fullName} (${sender.uid})");
    print("👥 Receiver: ${receiver.fullName} (${receiver.uid})");

    // Verify sender and receiver are different
    if (sender.uid == receiver.uid) {
      print("❌ ERROR: Sender and receiver cannot be the same user!");
      return;
    }

    // Ensure the sender is the current user
    final currentUser = UserService.currentUser.value;
    if (currentUser == null) {
      print("❌ ERROR: No current user found!");
      return;
    }

    List<SocialMediaUser> participants = [];

    // Always set current user as the first member (sender)
    if (sender.uid == currentUser.uid) {
      participants = [sender, receiver];
    } else if (receiver.uid == currentUser.uid) {
      print("🔄 Correcting: current user is receiver, swapping to be sender...");
      participants = [receiver, sender];
    } else {
      print("🔄 Correcting: current user is not in the chat, adding as sender...");
      participants = [currentUser, receiver];
    }

    _startSession(
      participants: participants,
      chatId: _generateChatId(participants),
      chatName: participants[1].fullName??"Unknown", // Use other user's name
      isGroup: false,
    );
  }

  /// Start a new group chat session
  void startGroupChatSession({
    required List<SocialMediaUser> participants,
    required String groupName,
    String? groupDescription,
    String? customChatId,
  }) {
    print("🚀 Starting group chat session:");
    print("👥 Group: $groupName");
    print("🔢 Participants: ${participants.length}");

    if (participants.length < 2) {
      print("❌ ERROR: Group chat must have at least 2 participants!");
      return;
    }

    // Ensure current user is in the participants
    final currentUser = UserService.currentUser.value;
    if (currentUser == null) {
      print("❌ ERROR: No current user found!");
      return;
    }

    List<SocialMediaUser> finalParticipants = List.from(participants);
    
    // Check if current user is already in participants
    bool currentUserIncluded = finalParticipants.any((user) => user.uid == currentUser.uid);
    
    if (!currentUserIncluded) {
      print("🔄 Adding current user to group participants...");
      finalParticipants.insert(0, currentUser);
    } else {
      // Move current user to first position if not already
      int currentUserIndex = finalParticipants.indexWhere((user) => user.uid == currentUser.uid);
      if (currentUserIndex > 0) {
        print("🔄 Moving current user to first position...");
        SocialMediaUser currentUserObj = finalParticipants.removeAt(currentUserIndex);
        finalParticipants.insert(0, currentUserObj);
      }
    }

    // Remove any duplicate users
    final uniqueParticipants = <SocialMediaUser>[];
    final seenUids = <String>{};
    
    for (var participant in finalParticipants) {
      if (!seenUids.contains(participant.uid)) {
        uniqueParticipants.add(participant);
        seenUids.add(participant.uid??"Unknown");
      }
    }

    _startSession(
      participants: uniqueParticipants,
      chatId: customChatId ?? _generateGroupChatId(uniqueParticipants, groupName),
      chatName: groupName??"Unknown",
      chatDescription: groupDescription,
      isGroup: true,
    );
  }

  /// Internal method to start any type of chat session
  void _startSession({
    required List<SocialMediaUser> participants,
    required String chatId,
    required String chatName,
    String? chatDescription,
    required bool isGroup,
  }) {
    _members.value = participants;
    _chatId.value = chatId;
    _chatName.value = chatName;
    _chatDescription.value = chatDescription ?? '';
    _isGroupChat.value = isGroup;
    _hasActiveSession.value = true;

    print("✅ Chat session started successfully");
    print("🎯 Session details:");
    print("   Chat ID: $chatId");
    print("   Chat Name: $chatName");
    print("   Type: ${isGroup ? 'Group Chat' : '1-on-1 Chat'}");
    print("   Participants: ${participants.length}");
    
    for (int i = 0; i < participants.length; i++) {
      String role = i == 0 ? "(Current User)" : isGroup ? "(Member)" : "(Receiver)";
      print("   ${i + 1}. ${participants[i].fullName} ${participants[i].uid} $role");
    }
  }

  /// End the current chat session
  void endChatSession() {
    print("🔚 Ending chat session: $_chatName");
    _members.clear();
    _chatId.value = '';
    _chatName.value = '';
    _chatDescription.value = '';
    _isGroupChat.value = false;
    _hasActiveSession.value = false;
    print("✅ Chat session ended");
  }

  /// Check if the current session is valid
  bool isSessionValid() {
    if (_members.length < 2) {
      print("⚠️ Invalid chat session: Not enough participants");
      return false;
    }

    // Check for duplicate users
    final uniqueUids = _members.map((user) => user.uid).toSet();
    if (uniqueUids.length != _members.length) {
      print("⚠️ Invalid chat session: Duplicate participants found");
      return false;
    }

    // Ensure current user is the first participant
    final currentUser = UserService.currentUser.value;
    if (currentUser != null && _members.isNotEmpty && _members[0].uid != currentUser.uid) {
      print("⚠️ Invalid chat session: Current user is not the first participant");
      return false;
    }

    return true;
  }

  /// Add a new member to the group chat
  bool addMember(SocialMediaUser newMember) {
    if (!_isGroupChat.value) {
      print("❌ Cannot add member to non-group chat");
      return false;
    }

    if (_members.any((member) => member.uid == newMember.uid)) {
      print("❌ Member ${newMember.fullName} is already in the chat");
      return false;
    }

    _members.add(newMember);
    print("✅ Added ${newMember.fullName} to group chat");
    return true;
  }

  /// Remove a member from the group chat
  bool removeMember(String userId) {
    if (!_isGroupChat.value) {
      print("❌ Cannot remove member from non-group chat");
      return false;
    }

    final currentUser = UserService.currentUser.value;
    if (currentUser?.uid == userId) {
      print("❌ Cannot remove current user from chat");
      return false;
    }

    final memberIndex = _members.indexWhere((member) => member.uid == userId);
    if (memberIndex == -1) {
      print("❌ Member not found in chat");
      return false;
    }

    final removedMember = _members.removeAt(memberIndex);
    print("✅ Removed ${removedMember.fullName} from group chat");
    
    // End session if not enough participants
    if (_members.length < 2) {
      print("⚠️ Not enough participants, ending chat session");
      endChatSession();
    }
    
    return true;
  }

  /// Update group chat information
  void updateGroupInfo({String? name, String? description}) {
    if (!_isGroupChat.value) {
      print("❌ Cannot update info for non-group chat");
      return;
    }

    if (name != null && name.isNotEmpty) {
      _chatName.value = name;
      print("✅ Updated group name to: $name");
    }

    if (description != null) {
      _chatDescription.value = description;
      print("✅ Updated group description");
    }
  }

  /// Get session data as a Map
  Map<String, dynamic> getSessionData() {
    return {
      'chatId': _chatId.value,
      'chatName': _chatName.value,
      'chatDescription': _chatDescription.value,
      'isGroupChat': _isGroupChat.value,
      'members': _members.map((user) => user.toJson()).toList(),
      'memberCount': _members.length,
      'hasActiveSession': _hasActiveSession.value,
      // Legacy fields for backward compatibility
      'sender': sender,
      'receiver': receiver,
    };
  }

  /// Update session status based on members
  void _updateSessionStatus() {
    _hasActiveSession.value = _members.length >= 2;
  }

  /// Check if the user is a member of the chat
  bool isMember(String userId) {
    return _members.any((member) => member.uid == userId);
  }

  /// Check if the user is the current user (first member)
  bool isCurrentUser(String userId) {
    return _members.isNotEmpty && _members[0].uid == userId;
  }

  /// Legacy methods for backward compatibility
  bool isUserSender(String userId) => isCurrentUser(userId);
  bool isUserReceiver(String userId) => _members.length > 1 && _members[1].uid == userId;

  /// Get another user in the chat (works for 1-on-1, returns null for groups)
  SocialMediaUser? getOtherUser(String currentUserId) {
    if (_isGroupChat.value) {
      return null; // Use getOtherMembers for group chats
    }
    
    if (_members.isEmpty) return null;
    
    if (_members[0].uid == currentUserId) {
      return _members.length > 1 ? _members[1] : null;
    } else if (_members.length > 1 && _members[1].uid == currentUserId) {
      return _members[0];
    }
    return null;
  }

  /// Get all other members in the chat (excluding current user)
  List<SocialMediaUser> getOtherMembers(String currentUserId) {
    return _members.where((member) => member.uid != currentUserId).toList();
  }

  /// Get member by user ID
  SocialMediaUser? getMemberById(String userId) {
    try {
      return _members.firstWhere((member) => member.uid == userId);
    } catch (e) {
      return null;
    }
  }

  /// Generate chat ID for 1-on-1 chats
  String _generateChatId(List<SocialMediaUser> participants) {
    if (participants.length != 2) return '';
    
    final uids = participants.map((user) => user.uid).toList()..sort();
    return 'chat_${uids[0]}_${uids[1]}';
  }

  /// Generate chat ID for group chats
  String _generateGroupChatId(List<SocialMediaUser> participants, String groupName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final memberCount = participants.length;
    return 'group_${groupName.replaceAll(' ', '_').toLowerCase()}_${memberCount}_$timestamp';
  }

  /// Print current session info (for development)
  void printSessionInfo() {
    print("📋 Current Chat Session Info:");
    print("   Chat ID: $_chatId");
    print("   Chat Name: $_chatName");
    print("   Chat Type: ${_isGroupChat.value ? 'Group Chat' : '1-on-1 Chat'}");
    print("   Total Members: ${_members.length}");
    print("   Has Active Session: $_hasActiveSession");
    print("   Session Valid: ${isSessionValid()}");
    
    if (_chatDescription.value.isNotEmpty) {
      print("   Description: $_chatDescription");
    }
    
    print("   Members:");
    for (int i = 0; i < _members.length; i++) {
      String role = i == 0 ? " (Current User)" : _isGroupChat.value ? " (Member)" : " (Receiver)";
      print("   ${i + 1}. ${_members[i].fullName} (${_members[i].uid})$role");
    }
  }
}
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';
import 'package:get/get.dart';

/// Enhanced Chat Session Manager - Single Source of Truth for Chat State
///
/// This class provides a comprehensive solution for managing chat sessions with the following features:
/// - Support for both 1-on-1 and group chats
/// - Reactive state management using GetX observables
/// - Automatic session validation and cleanup
/// - Convenient methods for common operations
/// - Robust error handling and logging
/// - Backward compatibility with existing code
///
/// Key Features:
/// - [members]: List of all chat participants (reactive)
/// - [chatName]: Display name of the chat (reactive)
/// - [chatDescription]: Optional description for group chats (reactive)
/// - [isGroupChat]: Whether this is a group chat or 1-on-1 (reactive)
/// - [hasActiveSession]: Whether there's an active chat session (reactive)
/// - [roomId]: Unique identifier for the chat room (computed)
///
/// Usage:
/// ```dart
/// // Start a 1-on-1 chat
/// ChatSessionManager.instance.startChatSession(
///   sender: currentUser,
///   receiver: otherUser,
/// );
///
/// // Start a group chat
/// ChatSessionManager.instance.startGroupChatSession(
///   participants: users,
///   groupName: 'My Group',
/// );
///
/// // Listen to changes
/// ChatSessionManager.instance.membersStream.listen((members) {
///   // Handle member changes
/// });
/// ```
class ChatSessionManager extends GetxController {
  static ChatSessionManager get instance => Get.find<ChatSessionManager>();

  // Core reactive state
  final RxList<SocialMediaUser> _members = <SocialMediaUser>[].obs;
  final RxString _chatId = ''.obs;
  final RxString _chatName = ''.obs;
  final RxString _chatDescription = ''.obs;
  final RxBool _isGroupChat = false.obs;
  final RxBool _hasActiveSession = false.obs;

  // Computed getters
  List<SocialMediaUser> get members => _members.toList();
  String get chatId => _chatId.value;
  String get chatName => _chatName.value;
  String get chatDescription => _chatDescription.value;
  bool get isGroupChat => _isGroupChat.value;
  bool get hasActiveSession => _hasActiveSession.value;
  int get memberCount => _members.length;

  // Legacy getters for backward compatibility
  SocialMediaUser? get sender => _members.isNotEmpty ? _members[0] : null;
  SocialMediaUser? get receiver => _members.length > 1 ? _members[1] : null;

  // Computed property for room ID
  String get roomId => _chatId.value;

  // Streams for reactive updates
  Stream<List<SocialMediaUser>> get membersStream => _members.stream;
  Stream<String> get chatNameStream => _chatName.stream;
  Stream<bool> get isGroupChatStream => _isGroupChat.stream;
  Stream<bool> get hasActiveSessionStream => _hasActiveSession.stream;

  @override
  void onInit() {
    super.onInit();
    // Listen to member changes and update session status
    ever(_members, (_) => _updateSessionStatus());
  }

  /// Update session status based on members
  void _updateSessionStatus() {
    _hasActiveSession.value =
        _members.length >= 2 && _validateCurrentUserPosition();
  }

  /// Validate that current user is properly positioned in members list
  bool _validateCurrentUserPosition() {
    final currentUser = UserService.currentUser.value;
    if (currentUser == null) return false;

    return _members.isNotEmpty && _members[0].uid == currentUser.uid;
  }

  /// Start a new 1-on-1 chat session (backward compatibility)
  bool startChatSession({
    required SocialMediaUser sender,
    required SocialMediaUser receiver,
  }) {
    try {
      _logOperation('Starting 1-on-1 chat session', {
        'sender': '${sender.fullName} (${sender.uid})',
        'receiver': '${receiver.fullName} (${receiver.uid})',
      });

      // Validate inputs
      if (!_validateChatSessionInputs(sender, receiver)) {
        return false;
      }

      final participants = _prepareParticipants(sender, receiver);
      final chatId = _generateChatId(participants);
      final chatName = participants[1].fullName ?? 'Chat';

      return _startSession(
        participants: participants,
        chatId: chatId,
        chatName: chatName,
        isGroup: false,
      );
    } catch (e) {
      _logError('Failed to start 1-on-1 chat session', e);
      return false;
    }
  }

  /// Start a new group chat session
  bool startGroupChatSession({
    required List<SocialMediaUser> participants,
    required String groupName,
    String? groupDescription,
    String? customChatId,
  }) {
    try {
      _logOperation('Starting group chat session', {
        'groupName': groupName,
        'participantCount': participants.length,
      });

      // Validate inputs
      if (!_validateGroupChatInputs(participants, groupName)) {
        return false;
      }

      final finalParticipants = _prepareGroupParticipants(participants);
      final chatId =
          customChatId ?? _generateGroupChatId(finalParticipants, groupName);

      return _startSession(
        participants: finalParticipants,
        chatId: chatId,
        chatName: groupName,
        chatDescription: groupDescription,
        isGroup: true,
      );
    } catch (e) {
      _logError('Failed to start group chat session', e);
      return false;
    }
  }

  /// Internal method to start any type of chat session
  bool _startSession({
    required List<SocialMediaUser> participants,
    required String chatId,
    required String chatName,
    String? chatDescription,
    required bool isGroup,
  }) {
    try {
      _members.assignAll(participants);
      _chatId.value = chatId;
      _chatName.value = chatName;
      _chatDescription.value = chatDescription ?? '';
      _isGroupChat.value = isGroup;
      _hasActiveSession.value = true;

      _logOperation('Chat session started successfully', {
        'chatId': chatId,
        'chatName': chatName,
        'isGroup': isGroup,
        'participantCount': participants.length,
      });

      return true;
    } catch (e) {
      _logError('Error starting chat session', e);
      _resetSession();
      return false;
    }
  }

  /// Reset session to initial state
  void _resetSession() {
    _members.clear();
    _chatId.value = '';
    _chatName.value = '';
    _chatDescription.value = '';
    _isGroupChat.value = false;
    _hasActiveSession.value = false;
  }

  /// End the current chat session
  void endChatSession() {
    _logOperation('Ending chat session', {'chatName': _chatName.value});
    _resetSession();
  }

  /// Validate 1-on-1 chat session inputs
  bool _validateChatSessionInputs(
      SocialMediaUser sender, SocialMediaUser receiver) {
    if (sender.uid == receiver.uid) {
      _logError('Sender and receiver cannot be the same user', null);
      return false;
    }

    final currentUser = UserService.currentUser.value;
    if (currentUser == null) {
      _logError('No current user found', null);
      return false;
    }

    return true;
  }

  /// Validate group chat inputs
  bool _validateGroupChatInputs(
      List<SocialMediaUser> participants, String groupName) {
    if (participants.length < 2) {
      _logError('Group chat must have at least 2 participants', null);
      return false;
    }

    if (groupName.trim().isEmpty) {
      _logError('Group name cannot be empty', null);
      return false;
    }

    final currentUser = UserService.currentUser.value;
    if (currentUser == null) {
      _logError('No current user found', null);
      return false;
    }

    return true;
  }

  /// Prepare participants for 1-on-1 chat
  List<SocialMediaUser> _prepareParticipants(
      SocialMediaUser sender, SocialMediaUser receiver) {
    final currentUser = UserService.currentUser.value!;
    List<SocialMediaUser> participants = [];

    // Always set current user as the first member (sender)
    if (sender.uid == currentUser.uid) {
      participants = [sender, receiver];
    } else if (receiver.uid == currentUser.uid) {
      _logOperation(
          'Correcting participant order', {'currentUserIsReceiver': true});
      participants = [receiver, sender];
    } else {
      _logOperation('Adding current user as sender', {});
      participants = [currentUser, receiver];
    }

    return participants;
  }

  /// Prepare participants for group chat
  List<SocialMediaUser> _prepareGroupParticipants(
      List<SocialMediaUser> participants) {
    final currentUser = UserService.currentUser.value!;
    List<SocialMediaUser> finalParticipants = List.from(participants);

    // Check if current user is already in participants
    bool currentUserIncluded =
        finalParticipants.any((user) => user.uid == currentUser.uid);

    if (!currentUserIncluded) {
      _logOperation('Adding current user to group participants', {});
      finalParticipants.insert(0, currentUser);
    } else {
      // Move current user to first position if not already
      int currentUserIndex =
          finalParticipants.indexWhere((user) => user.uid == currentUser.uid);
      if (currentUserIndex > 0) {
        _logOperation('Moving current user to first position', {});
        SocialMediaUser currentUserObj =
            finalParticipants.removeAt(currentUserIndex);
        finalParticipants.insert(0, currentUserObj);
      }
    }

    // Remove duplicates
    final uniqueParticipants = <SocialMediaUser>[];
    final seenUids = <String>{};

    for (var participant in finalParticipants) {
      final uid = participant.uid ?? 'unknown_${participant.hashCode}';
      if (!seenUids.contains(uid)) {
        uniqueParticipants.add(participant);
        seenUids.add(uid);
      }
    }

    return uniqueParticipants;
  }

  /// Check if the current session is valid
  bool isSessionValid() {
    if (_members.length < 2) {
      _logError('Invalid chat session: Not enough participants', null);
      return false;
    }

    // Check for duplicate users
    final uniqueUids =
        _members.map((user) => user.uid).where((uid) => uid != null).toSet();
    if (uniqueUids.length != _members.length) {
      _logError('Invalid chat session: Duplicate participants found', null);
      return false;
    }

    // Ensure current user is the first participant
    if (!_validateCurrentUserPosition()) {
      _logError(
          'Invalid chat session: Current user is not the first participant',
          null);
      return false;
    }

    return true;
  }

  /// Add a new member to the group chat
  bool addMember(SocialMediaUser newMember) {
    if (!_isGroupChat.value) {
      _logError('Cannot add member to non-group chat', null);
      return false;
    }

    if (_members.any((member) => member.uid == newMember.uid)) {
      _logError('Member ${newMember.fullName} is already in the chat', null);
      return false;
    }

    _members.add(newMember);
    _logOperation(
        'Added member to group chat', {'memberName': newMember.fullName});
    return true;
  }

  /// Remove a member from the group chat
  bool removeMember(String userId) {
    if (!_isGroupChat.value) {
      _logError('Cannot remove member from non-group chat', null);
      return false;
    }

    final currentUser = UserService.currentUser.value;
    if (currentUser?.uid == userId) {
      _logError('Cannot remove current user from chat', null);
      return false;
    }

    final memberIndex = _members.indexWhere((member) => member.uid == userId);
    if (memberIndex == -1) {
      _logError('Member not found in chat', null);
      return false;
    }

    final removedMember = _members.removeAt(memberIndex);
    _logOperation('Removed member from group chat',
        {'memberName': removedMember.fullName});

    // End session if not enough participants for a group chat
    if (_members.length < 2) {
      _logError('Not enough participants for group chat, ending session', null);
      endChatSession();
    }

    return true;
  }

  /// Update group chat information
  void updateGroupInfo({String? name, String? description}) {
    if (!_isGroupChat.value) {
      _logError('Cannot update info for non-group chat', null);
      return;
    }

    if (name != null && name.isNotEmpty) {
      _chatName.value = name;
      _logOperation('Updated group name', {'newName': name});
    }

    if (description != null) {
      _chatDescription.value = description;
      _logOperation('Updated group description', {});
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
      'roomId': _chatId.value,
      // Legacy fields for backward compatibility
      'sender': sender,
      'receiver': receiver,
    };
  }

  /// Set loading state
  void setLoading(bool loading) {
    // Note: This method is for backward compatibility
    // Consider using a separate loading state manager
    _logOperation('Loading state changed', {'loading': loading});
  }

  /// Set recording state
  void setRecording(bool recording) {
    // Note: This method is for backward compatibility
    // Consider using a separate recording state manager
    _logOperation('Recording state changed', {'recording': recording});
  }

  /// Toggle recording state
  void toggleRecording() {
    // Note: This method is for backward compatibility
    // Consider using a separate recording state manager
    _logOperation('Recording state toggled', {});
  }

  /// Check if a user can be added to the current chat
  bool canAddMember(String userId) {
    if (!_isGroupChat.value) return false;
    return !_members.any((member) => member.uid == userId);
  }

  /// Check if a user can be removed from the current chat
  bool canRemoveMember(String userId) {
    if (!_isGroupChat.value) return false;
    final currentUser = UserService.currentUser.value;
    if (currentUser?.uid == userId) return false;
    return _members.any((member) => member.uid == userId);
  }

  /// Get chat type as string
  String get chatType => _isGroupChat.value ? 'group' : 'individual';

  /// Get formatted member count string
  String get memberCountText {
    if (!_isGroupChat.value) return '1-on-1';
    return '$memberCount members';
  }

  /// Check if current user is the chat owner/admin
  bool get isCurrentUserOwner {
    final currentUser = UserService.currentUser.value;
    return currentUser != null &&
        _members.isNotEmpty &&
        _members[0].uid == currentUser.uid;
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
  bool isUserReceiver(String userId) =>
      _members.length > 1 && _members[1].uid == userId;

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

    final uids = participants
        .map((user) => user.uid)
        .where((uid) => uid != null)
        .toList()
      ..sort();
    return 'chat_${uids[0]}_${uids[1]}';
  }

  /// Generate chat ID for group chats
  String _generateGroupChatId(
      List<SocialMediaUser> participants, String groupName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final memberCount = participants.length;
    return 'group_${groupName.replaceAll(' ', '_').toLowerCase()}_${memberCount}_$timestamp';
  }

  /// Print current session info (for development)
  void printSessionInfo() {
    _logOperation('Current Chat Session Info', {
      'chatId': _chatId.value,
      'chatName': _chatName.value,
      'chatType': _isGroupChat.value ? 'Group Chat' : '1-on-1 Chat',
      'memberCount': _members.length,
      'hasActiveSession': _hasActiveSession.value,
      'isSessionValid': isSessionValid(),
      'chatDescription':
          _chatDescription.value.isNotEmpty ? _chatDescription.value : 'N/A',
    });

    print("   Members:");
    for (int i = 0; i < _members.length; i++) {
      String role = i == 0
          ? " (Current User)"
          : _isGroupChat.value
              ? " (Member)"
              : " (Receiver)";
      print("   ${i + 1}. ${_members[i].fullName} (${_members[i].uid})$role");
    }
  }

  /// Log operation for debugging
  void _logOperation(String operation, Map<String, dynamic> details) {
    print("🔧 ChatSessionManager: $operation");
    if (details.isNotEmpty) {
      details.forEach((key, value) => print("   $key: $value"));
    }
  }

  /// Log error for debugging
  void _logError(String error, dynamic exception) {
    print("❌ ChatSessionManager Error: $error");
    if (exception != null) {
      print("   Exception: $exception");
    }
  }
}

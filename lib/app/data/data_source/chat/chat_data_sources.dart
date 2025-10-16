import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/data/models/messages/audio_message_model.dart';
import 'package:crypted_app/app/data/models/messages/call_message_model.dart';
import 'package:crypted_app/app/data/models/messages/contact_message_model.dart';
import 'package:crypted_app/app/data/models/messages/event_message_model.dart';
import 'package:crypted_app/app/data/models/messages/file_message_model.dart';
import 'package:crypted_app/app/data/models/messages/image_message_model.dart';
import 'package:crypted_app/app/data/models/messages/location_message_model.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/messages/poll_message_model.dart';
import 'package:crypted_app/app/data/models/messages/text_message_model.dart';
import 'package:crypted_app/app/data/models/messages/video_message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../user_services.dart';
import 'chat_services_parameters.dart';

enum MessageType {
  text,
  photo,
  audio,
  location,
  contact,
  poll,
  event,
  file,
  call,
  video,
}

class ChatDataSources {
  // =================== PROPERTIES ===================
  final ChatConfiguration chatConfiguration;
  final CollectionReference chatCollection = FirebaseFirestore.instance.collection('chats');
  final String userId = UserService.currentUser.value?.uid.toString() ?? 
                       FirebaseAuth.instance.currentUser?.uid.toString() ?? '';
  
  ChatDataSources({required this.chatConfiguration});

  // =================== CHAT ROOM QUERIES ===================
  
  /// Get all chats for the current user with optional filters
  Stream<List<ChatRoom>> getChats({
    bool getGroupChatOnly = false, 
    bool getPrivateChatOnly = false,
  }) {
    if (userId.isEmpty) return Stream.value([]);
    
    Query query = chatCollection
        .where('membersIds', arrayContains: userId)
        .orderBy('lastChat', descending: true)
        .orderBy('__name__', descending: true);
    
    if (getGroupChatOnly) {
      query = query.where('isGroupChat', isEqualTo: true);
    }
    if (getPrivateChatOnly) {
      query = query.where('isGroupChat', isEqualTo: false);
    }

    final querySnapshotStream = query.snapshots().map(ChatRoom().fromQuery);

    if (kDebugMode) {
      querySnapshotStream.listen((querySnapshot) {
        for (var doc in querySnapshot) {
          print('Chat members: ${doc.membersIds}');
        }
      });
    }
    
    return querySnapshotStream;
  }

  /// Get a specific chat room by ID
  Future<ChatRoom?> getChatRoomById(String roomId) async {
    try {
      DocumentSnapshot chatRoomSnapshot = await chatCollection.doc(roomId).get();
      if (chatRoomSnapshot.exists) {
        return ChatRoom.fromMap(chatRoomSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat room by ID: $e');
      }
      return null;
    }
  }

  /// Check if a chat room exists between specific members
  Future<bool> chatRoomExists() async {
    final querySnapshot = await chatCollection
        .where('membersIds', isEqualTo: chatConfiguration.members.map((e) => e.uid).toList())
        .get();
    
    if (kDebugMode) {
      print("✅ Chat room exists: ${querySnapshot.docs.isNotEmpty}");
    }
    return querySnapshot.docs.isNotEmpty;
  }

  /// Find existing chat room between specific members
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    try {
      memberIds.sort(); // Sort to ensure consistent comparison
      final querySnapshot = await chatCollection
          .where('membersIds', arrayContainsAny: memberIds)
          .get();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomMemberIds = List<String>.from(data['membersIds'] ?? []);
        roomMemberIds.sort();
        
        if (_listsEqual(roomMemberIds, memberIds)) {
          return ChatRoom.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding existing chat room: $e');
      }
      return null;
    }
  }

  // =================== CHAT ROOM MANAGEMENT ===================
  
  /// Create a new chat room
  Future<ChatRoom> createNewChatRoom({
    Message? privateMessage,
    String? roomId,
    bool isGroupChat = false,
    required List<SocialMediaUser>? members,
    String? groupName,
    String? groupDescription,
  }) async {
    try {
      roomId = roomId ?? chatCollection.doc().id;
      final newChatRoom = chatCollection.doc(roomId);
      
      // Check blocked users
      final currentUserDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(UserService.currentUser.value?.uid);
      var userSnapshot = await currentUserDoc.get();
      List blockedList = [];

      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        blockedList = userData["blockedUser"] ?? [];
        
        final memberUids = chatConfiguration.members.map((e) => e.uid).toList();
        if (blockedList.any((blocked) => memberUids.contains(blocked))) {
          throw Exception('Cannot create chat room with blocked users');
        }
      }

      final chatRoom = ChatRoom(
        id: roomId,
        keywords: List.generate(
          chatConfiguration.members.length, 
          (index) => 'id+${chatConfiguration.members[index].uid}+'
        ),
        read: false,
        membersIds: List.generate(
          chatConfiguration.members.length, 
          (index) => chatConfiguration.members[index].uid ?? ""
        ),
        members: chatConfiguration.members,
        lastMsg: setLastMessage(privateMessage),
        lastSender: userId,
        lastChat: DateTime.now().toIso8601String(),
        isGroupChat: isGroupChat,
        name: groupName,
        description: groupDescription,
      );
      
      await newChatRoom.set(chatRoom.toMap());
      
      if (kDebugMode) {
        print('✅ Created new chat room: $roomId');
      }
      
      return chatRoom;
    } catch (e) {
      log("Error creating new chat room: ${e.toString()}");
      throw Exception('Failed to create new chat room: $e');
    }
  }

  /// Add member to existing chat room
  Future<bool> addMemberToChat({
    required String roomId,
    required SocialMediaUser newMember,
  }) async {
    try {
      final chatRoomRef = chatCollection.doc(roomId);
      final chatRoomSnapshot = await chatRoomRef.get();
      
      if (!chatRoomSnapshot.exists) {
        throw Exception('Chat room not found');
      }
      
      final chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>;
      final currentMembers = List<SocialMediaUser>.from(
        (chatRoomData['members'] ?? []).map((member) => SocialMediaUser.fromMap(member))
      );
      final currentMemberIds = List<String>.from(chatRoomData['membersIds'] ?? []);
      
      // Check if member already exists
      if (currentMemberIds.contains(newMember.uid)) {
        if (kDebugMode) {
          print('Member already exists in chat room');
        }
        return false;
      }
      
      // Check if it's a group chat (can't add members to private chats)
      final isGroupChat = chatRoomData['isGroupChat'] ?? false;
      if (!isGroupChat) {
        throw Exception('Cannot add members to private chat');
      }
      
      // Add new member
      currentMembers.add(newMember);
      currentMemberIds.add(newMember.uid ?? "");
      
      // Update keywords
      final newKeywords = List.generate(
        currentMembers.length, 
        (index) => 'id+${currentMembers[index].uid}+'
      );
      
      // Update chat room
      await chatRoomRef.update({
        'members': currentMembers.map((member) => member.toMap()).toList(),
        'membersIds': currentMemberIds,
        'keywords': newKeywords,
        'lastChat': DateTime.now().toIso8601String(),
        'lastMsg': '${newMember.fullName} joined the group',
        'lastSender': userId,
      });
      
      // Add system message about member joining
      await _addSystemMessage(
        roomId: roomId,
        message: '${newMember.fullName} joined the group',
        messageType: 'member_added',
      );
      
      if (kDebugMode) {
        print('✅ Member added to chat room: ${newMember.fullName}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding member to chat: $e');
      }
      return false;
    }
  }

  /// Remove member from chat room
  Future<bool> removeMemberFromChat({
    required String roomId,
    required String memberIdToRemove,
  }) async {
    try {
      final chatRoomRef = chatCollection.doc(roomId);
      final chatRoomSnapshot = await chatRoomRef.get();
      
      if (!chatRoomSnapshot.exists) {
        throw Exception('Chat room not found');
      }
      
      final chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>;
      final currentMembers = List<SocialMediaUser>.from(
        (chatRoomData['members'] ?? []).map((member) => SocialMediaUser.fromMap(member))
      );
      final currentMemberIds = List<String>.from(chatRoomData['membersIds'] ?? []);
      
      // Check if member exists
      if (!currentMemberIds.contains(memberIdToRemove)) {
        if (kDebugMode) {
          print('Member not found in chat room');
        }
        return false;
      }
      
      // Check if it's a group chat
      final isGroupChat = chatRoomData['isGroupChat'] ?? false;
      if (!isGroupChat) {
        throw Exception('Cannot remove members from private chat');
      }
      
      // Don't allow removing the last member
      if (currentMemberIds.length <= 1) {
        throw Exception('Cannot remove the last member from group chat');
      }
      
      // Find and remove member
      final memberToRemove = currentMembers.firstWhere(
        (member) => member.uid == memberIdToRemove,
      );
      
      currentMembers.removeWhere((member) => member.uid == memberIdToRemove);
      currentMemberIds.remove(memberIdToRemove);
      
      // Update keywords
      final newKeywords = List.generate(
        currentMembers.length, 
        (index) => 'id+${currentMembers[index].uid}+'
      );
      
      // Update chat room
      await chatRoomRef.update({
        'members': currentMembers.map((member) => member.toMap()).toList(),
        'membersIds': currentMemberIds,
        'keywords': newKeywords,
        'lastChat': DateTime.now().toIso8601String(),
        'lastMsg': '${memberToRemove.fullName} left the group',
        'lastSender': userId,
      });
      
      // Add system message about member leaving
      await _addSystemMessage(
        roomId: roomId,
        message: '${memberToRemove.fullName} left the group',
        messageType: 'member_removed',
      );
      
      if (kDebugMode) {
        print('✅ Member removed from chat room: ${memberToRemove?.fullName}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing member from chat: $e');
      }
      return false;
    }
  }

  /// Update chat room information (name, description, etc.)
  Future<bool> updateChatRoomInfo({
    required String roomId,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'lastChat': DateTime.now().toIso8601String(),
      };
      
      if (groupName != null) updateData['groupName'] = groupName;
      if (groupDescription != null) updateData['groupDescription'] = groupDescription;
      if (groupImageUrl != null) updateData['groupImageUrl'] = groupImageUrl;
      
      await chatCollection.doc(roomId).update(updateData);
      
      if (kDebugMode) {
        print('✅ Chat room info updated: $roomId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating chat room info: $e');
      }
      return false;
    }
  }

  // =================== MESSAGE OPERATIONS ===================
  
  /// Get live messages for a chat room
  Stream<List<Message>> getLivePrivateMessage(String roomId) {
    return chatCollection
        .doc(roomId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  /// Send a message to a chat room
  Future<void> sendMessage({
    Message? privateMessage,
    required String roomId,
    required List<SocialMediaUser>? members,
  }) async {
    try {
      bool exists = await chatRoomExists();
      
      if (!exists) {
        if (kDebugMode) {
          print("✅ Chat room does not exist, creating new chat room");
        }
        await createNewChatRoom(
          privateMessage: privateMessage,
          roomId: roomId,
          members: members,
        );
      }
      
      if (kDebugMode) {
        print("✅ Chat room exists, posting message");
      }
      
      await postMessageToChat(privateMessage, roomId);
    } catch (error) {
      if (kDebugMode) {
        print('Message data: ${privateMessage?.toMap().toString()}');
        print('Room ID: $roomId');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  /// Post message to chat collection
  Future<void> postMessageToChat(Message? privateMessage, String roomId) async {
    final newPrivateMessage = chatCollection
        .doc(roomId)
        .collection('chat')
        .doc();
    
    await newPrivateMessage.set(
      privateMessage!
          .copyWith(id: newPrivateMessage.id)
          .toMap(),
    );
    
    await updateChatRoom(privateMessage, roomId);
  }

  /// Update chat room with latest message info
  Future<void> updateChatRoom(Message? privateMessage, String roomId) async {
    final room = ChatRoom(
      id: roomId,
      read: false,
      keywords: List<String>.generate(
        chatConfiguration.members.length,
        (index) => 'id+${chatConfiguration.members[index].uid}+'
      ),
      membersIds: List<String>.generate(
        chatConfiguration.members.length,
        (index) => chatConfiguration.members[index].uid ?? ""
      ),
      members: chatConfiguration.members,
      lastMsg: setLastMessage(privateMessage),
      lastSender: userId,
      lastChat: DateTime.now().toIso8601String(),
    );
    
    if (kDebugMode) {
      print("✅ Chat room updated: ${room.id}");
    }
    
    await chatCollection.doc(roomId).update(room.toMap());
  }

  /// Add system message (for member joins/leaves, etc.)
  Future<void> _addSystemMessage({
    required String roomId,
    required String message,
    required String messageType,
  }) async {
    try {
      final systemMessage = TextMessage(
        id: '',
        roomId: roomId,
        senderId: userId,
        timestamp: DateTime.now(),
        text: message,
      );
      
      await postMessageToChat(systemMessage, roomId);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding system message: $e');
      }
    }
  }

  // =================== MESSAGE UTILITIES ===================
  
  /// Generate preview text for last message
  String setLastMessage(Message? message) {
    if (message == null) return '';
    
    switch (message) {
      case TextMessage():
        return message.text.length > 50
            ? '${message.text.substring(0, 50)}...'
            : message.text;
      case PhotoMessage():
        return '📷 Photo';
      case AudioMessage():
        return '🎵 Audio';
      case LocationMessage():
        return '📍 Location';
      case ContactMessage():
        return '👤 Contact';
      case PollMessage():
        return '📊 Poll';
      case EventMessage():
        return '📅 Event';
      case FileMessage():
        return '📄 File';
      case VideoMessage():
        return '📹 Video';
      case CallMessage():
        return '📞 Call';
      default:
        return '📩 Message';
    }
  }

  /// Get message type enum from message object
  MessageType? getMessageType(Message message) {
    switch (message) {
      case TextMessage():
        return MessageType.text;
      case PhotoMessage():
        return MessageType.photo;
      case AudioMessage():
        return MessageType.audio;
      case LocationMessage():
        return MessageType.location;
      case ContactMessage():
        return MessageType.contact;
      case PollMessage():
        return MessageType.poll;
      case EventMessage():
        return MessageType.event;
      case FileMessage():
        return MessageType.file;
      case VideoMessage():
        return MessageType.video;
      case CallMessage():
        return MessageType.call;
      default:
        return null;
    }
  }

  // =================== DELETE OPERATIONS ===================
  
  /// Delete a specific message
  Future<void> deletePrivateMessage(String msgId, String roomId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(roomId)
          .collection('chat')
          .doc(msgId)
          .delete();
      
      if (kDebugMode) {
        print('✅ Message deleted: $msgId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting message: $error');
      }
    }
  }

  /// Delete entire chat room and all its messages
  Future<bool> deleteRoom(String roomId) async {
    try {
      // Delete messages from 'chats' collection
      try {
        final messagesQuery = await chatCollection.doc(roomId).collection('chat').get();
        await _deleteMessageFiles(messagesQuery.docs);
        
        for (var doc in messagesQuery.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting messages from chats collection: $e');
        }
      }

      // Delete messages from 'Chats' collection (legacy support)
      try {
        final messagesQuery2 = await FirebaseFirestore.instance
            .collection('Chats')
            .doc(roomId)
            .collection('chat')
            .get();
        
        await _deleteMessageFiles(messagesQuery2.docs);
        
        for (var doc in messagesQuery2.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting messages from Chats collection: $e');
        }
      }

      // Delete chat room document
      await chatCollection.doc(roomId).delete();

      // Delete from legacy 'Chats' collection
      try {
        await FirebaseFirestore.instance
            .collection('Chats')
            .doc(roomId)
            .delete();
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting room from Chats collection: $e');
        }
      }

      if (kDebugMode) {
        print('✅ Chat room deleted: $roomId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting room: $e');
      }
      return false;
    }
  }

  /// Delete all media files associated with messages
  Future<void> _deleteMessageFiles(List<QueryDocumentSnapshot> messages) async {
    try {
      for (var doc in messages) {
        final data = doc.data() as Map<String, dynamic>;
        final messageType = data['messageType']?.toString();

        String? fileUrl;
        switch (messageType) {
          case 'image':
          case 'photo':
            fileUrl = data['imageUrl']?.toString();
            break;
          case 'audio':
            fileUrl = data['audioUrl']?.toString();
            break;
          case 'video':
            fileUrl = data['videoUrl']?.toString();
            break;
          case 'file':
            fileUrl = data['fileUrl']?.toString();
            break;
        }

        if (fileUrl != null && fileUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
            if (kDebugMode) {
              print('Deleted file: $fileUrl');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error deleting file: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message files: $e');
      }
    }
  }

  // =================== UTILITY METHODS ===================
  
  /// Compare two lists for equality
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Check if current user is admin of a group chat
  // Future<bool> isUserAdmin(String roomId, String userId) async {
  //   try {
  //     final chatRoom = await getChatRoomById(roomId);
  //     if (chatRoom == null) return false;
      
  //     // Assuming there's an admins field in ChatRoom model
  //     // You might need to add this field to your ChatRoom model
  //     final adminIds = chatRoom.adminIds ?? [];
  //     return adminIds.contains(userId);
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error checking admin status: $e');
  //     }
  //     return false;
  //   }
  // }
  

  /// Get chat room members count
  Future<int> getMemberCount(String roomId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      return chatRoom?.membersIds?.length ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting member count: $e');
      }
      return 0;
    }
  }
}
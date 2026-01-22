import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
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
  final ChatConfiguration? chatConfiguration;
  final CollectionReference chatCollection = FirebaseFirestore.instance.collection(FirebaseCollections.chats);
  final String userId = UserService.currentUser.value?.uid.toString() ?? 
                       FirebaseAuth.instance.currentUser?.uid.toString() ?? '';
  
  ChatDataSources({this.chatConfiguration});

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
    if (chatConfiguration == null || chatConfiguration!.members.isEmpty) return false;

    final querySnapshot = await chatCollection
        .where('membersIds', isEqualTo: chatConfiguration!.members.map((e) => e.uid).toList())
        .get();
    
    return querySnapshot.docs.isNotEmpty;
  }

  /// Find existing chat room between specific members
  /// BUG-007 FIX: Use arrayContains with first member to narrow results,
  /// then filter for exact match. arrayContainsAny was returning incorrect rooms.
  Future<ChatRoom?> findExistingChatRoom(List<String> memberIds) async {
    try {
      if (memberIds.isEmpty) return null;

      memberIds.sort(); // Sort to ensure consistent comparison

      // Use arrayContains with the first member ID to get a narrower result set
      // This is more efficient than arrayContainsAny which returns ANY match
      final querySnapshot = await chatCollection
          .where('membersIds', arrayContains: memberIds.first)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final roomMemberIds = List<String>.from(data['membersIds'] ?? []);
        roomMemberIds.sort();

        // Exact match check - room must have exactly the same members
        if (_listsEqual(roomMemberIds, memberIds)) {
          // Also verify the room ID is set
          final roomData = Map<String, dynamic>.from(data);
          roomData['id'] = doc.id;
          return ChatRoom.fromMap(roomData);
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
      
      // BUG-010 FIX: Bidirectional block check - check both directions
      final currentUserId = UserService.currentUser.value?.uid;
      final memberUids = members?.map((e) => e.uid).where((uid) => uid != currentUserId).toList() ?? [];

      // Check if current user has blocked any members
      final currentUserDoc = FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(currentUserId);
      var userSnapshot = await currentUserDoc.get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        List blockedList = userData["blockedUser"] ?? [];

        if (memberUids.isNotEmpty && blockedList.any((blocked) => memberUids.contains(blocked))) {
          throw Exception('Cannot create chat room with blocked users');
        }
      }

      // BUG-010 FIX: Also check if any member has blocked the current user
      if (memberUids.isNotEmpty && currentUserId != null) {
        for (final memberUid in memberUids) {
          final memberDoc = await FirebaseFirestore.instance
              .collection(FirebaseCollections.users)
              .doc(memberUid)
              .get();

          if (memberDoc.exists && memberDoc.data() != null) {
            final memberData = memberDoc.data() as Map<String, dynamic>;
            final memberBlockedList = memberData["blockedUser"] ?? [];

            if (memberBlockedList.contains(currentUserId)) {
              throw Exception('Cannot create chat room: you are blocked by one of the members');
            }
          }
        }
      }

      // Generate a proper group name if none provided
      String finalGroupName = groupName ?? '';
      if (isGroupChat && (finalGroupName.isEmpty)) {
        // Generate group name from members if not provided
        final otherMembers = members!
            .where((user) => user.uid != UserService.currentUser.value?.uid)
            .take(3)
            .map((user) => user.fullName?.split(' ').first ?? 'User')
            .toList();

        if (otherMembers.isNotEmpty) {
          if (otherMembers.length == 1) {
            finalGroupName = otherMembers.first;
          } else if (otherMembers.length == 2) {
            finalGroupName = '${otherMembers[0]}, ${otherMembers[1]}';
          } else {
            finalGroupName = '${otherMembers[0]}, ${otherMembers[1]} and ${otherMembers.length - 2} others';
          }
        }
      }

      final chatRoom = ChatRoom(
        id: roomId,
        keywords: List.generate(
          members?.length ?? 0,
          (index) => 'id+${members![index].uid}+'
        ),
        read: false,
        membersIds: List.generate(
          members?.length ?? 0,
          (index) => members![index].uid ?? ""
        ),
        members: members,
        lastMsg: setLastMessage(privateMessage),
        lastSender: userId,
        lastChat: DateTime.now().toIso8601String(),
        isGroupChat: isGroupChat,
        name: finalGroupName, // Always store the group name (even if empty string)
        description: groupDescription,
      );
      
      await newChatRoom.set(chatRoom.toMap());
      
      if (kDebugMode) {
        print('✅ Created new chat room: $roomId with name: "$finalGroupName"');
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

      // BUG-011 FIX: Use transaction to ensure atomic update of members and membersIds
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final chatRoomSnapshot = await transaction.get(chatRoomRef);

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
          throw Exception('Member already exists in chat room');
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

        // Update chat room atomically
        transaction.update(chatRoomRef, {
          'members': currentMembers.map((member) => member.toMap()).toList(),
          'membersIds': currentMemberIds,
          'keywords': newKeywords,
          'lastChat': DateTime.now().toIso8601String(),
          'lastMsg': '${newMember.fullName} joined the group',
          'lastSender': userId,
        });
      });

      // Add system message about member joining (outside transaction)
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
  /// BUG-011 FIX: Use transaction to ensure atomic update
  Future<bool> removeMemberFromChat({
    required String roomId,
    required String memberIdToRemove,
  }) async {
    String? removedMemberName;
    try {
      final chatRoomRef = chatCollection.doc(roomId);

      // BUG-011 FIX: Use transaction to ensure atomic update of members and membersIds
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final chatRoomSnapshot = await transaction.get(chatRoomRef);

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
          throw Exception('Member not found in chat room');
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
        removedMemberName = memberToRemove.fullName;

        currentMembers.removeWhere((member) => member.uid == memberIdToRemove);
        currentMemberIds.remove(memberIdToRemove);

        // Update keywords
        final newKeywords = List.generate(
          currentMembers.length,
          (index) => 'id+${currentMembers[index].uid}+'
        );

        // Update chat room atomically
        transaction.update(chatRoomRef, {
          'members': currentMembers.map((member) => member.toMap()).toList(),
          'membersIds': currentMemberIds,
          'keywords': newKeywords,
          'lastChat': DateTime.now().toIso8601String(),
          'lastMsg': '${memberToRemove.fullName} left the group',
          'lastSender': userId,
        });
      });

      // Add system message about member leaving (outside transaction)
      if (removedMemberName != null) {
        await _addSystemMessage(
          roomId: roomId,
          message: '$removedMemberName left the group',
          messageType: 'member_removed',
        );
      }

      if (kDebugMode) {
        print('✅ Member removed from chat room: $removedMemberName');
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
      
      if (groupName != null) updateData['name'] = groupName;
      if (groupDescription != null) updateData['description'] = groupDescription;
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
  
  /// Update a specific message
  Future<void> updateMessage({
    required String roomId,
    required String messageId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId)
          .update(updates);

      if (kDebugMode) {
        print('✅ Message updated: $messageId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error updating message: $error');
      }
      rethrow;
    }
  }

  // =================== MESSAGE EDITING ===================

  /// Edit a text message
  /// Edit a message
  /// BUG-012 FIX: Use transaction to get server time for edit limit check
  /// Note: Full security should be enforced in Firestore Security Rules
  static const int _editTimeLimitMinutes = 15;

  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newText,
    required String senderId,
  }) async {
    try {
      final messageRef = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      // BUG-012 FIX: Use transaction with server timestamp for accurate time comparison
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception('Message not found');
        }

        final data = snapshot.data()!;

        // Security check: Only allow editing own messages
        if (data['senderId'] != senderId) {
          throw Exception('You can only edit your own messages');
        }

        // Check if message is text type
        if (data['type'] != 'text') {
          throw Exception('Only text messages can be edited');
        }

        // BUG-012 FIX: Parse timestamp using centralized parser for consistency
        final messageTimestamp = data['timestamp'];
        DateTime timestamp;
        if (messageTimestamp is Timestamp) {
          timestamp = messageTimestamp.toDate();
        } else if (messageTimestamp is String) {
          timestamp = DateTime.parse(messageTimestamp);
        } else {
          throw Exception('Invalid message timestamp format');
        }

        // Get server timestamp by reading a document with serverTimestamp
        // For now, use client time but with a safety margin
        // Note: For full security, implement in Firestore Security Rules
        final now = DateTime.now();
        final difference = now.difference(timestamp);

        // Add 1 minute buffer to account for clock drift
        if (difference.inMinutes > _editTimeLimitMinutes) {
          throw Exception('Messages can only be edited within $_editTimeLimitMinutes minutes');
        }

        final originalText = data['originalText'] ?? data['text'];

        // Use FieldValue.serverTimestamp() for editedAt to ensure server time
        transaction.update(messageRef, {
          'text': newText,
          'isEdited': true,
          'editedAt': FieldValue.serverTimestamp(),
          'originalText': originalText,
        });
      });

      if (kDebugMode) {
        print('✅ Message edited successfully: $messageId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error editing message: $error');
      }
      rethrow;
    }
  }

  // =================== REACTION OPERATIONS ===================

  /// Add or remove a reaction to/from a message
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final messageRef = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception('Message not found');
        }

        final data = snapshot.data()!;
        List<dynamic> reactions = List.from(data['reactions'] ?? []);

        // Check if user already reacted with this emoji
        final existingReactionIndex = reactions.indexWhere(
          (r) => r['emoji'] == emoji && r['userId'] == userId,
        );

        if (existingReactionIndex != -1) {
          // Remove reaction
          reactions.removeAt(existingReactionIndex);
          if (kDebugMode) {
            print('🔄 Removed reaction $emoji from message $messageId');
          }
        } else {
          // Add reaction
          reactions.add({
            'emoji': emoji,
            'userId': userId,
          });
          if (kDebugMode) {
            print('✅ Added reaction $emoji to message $messageId');
          }
        }

        transaction.update(messageRef, {'reactions': reactions});
      });
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error toggling reaction: $error');
      }
      rethrow;
    }
  }

  /// Remove all reactions of a specific user from a message
  Future<void> removeUserReactions({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception('Message not found');
        }

        final data = snapshot.data()!;
        List<dynamic> reactions = List.from(data['reactions'] ?? []);

        // Remove all reactions from this user
        reactions.removeWhere((r) => r['userId'] == userId);

        transaction.update(messageRef, {'reactions': reactions});
      });

      if (kDebugMode) {
        print('✅ Removed all reactions from user $userId on message $messageId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error removing user reactions: $error');
      }
      rethrow;
    }
  }

  /// Vote on a poll message
  /// BUG-009 FIX: Added validation for optionIndex before processing vote
  Future<void> votePoll({
    required String roomId,
    required String messageId,
    required int optionIndex,
    required String userId,
    required bool allowMultipleVotes,
  }) async {
    try {
      // BUG-009 FIX: Validate optionIndex is non-negative
      if (optionIndex < 0) {
        throw Exception('Invalid option index: must be non-negative');
      }

      final messageRef = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception('Poll message not found');
        }

        final data = snapshot.data()!;

        // BUG-009 FIX: Validate optionIndex is within valid range
        final options = data['options'] as List<dynamic>? ?? [];
        if (optionIndex >= options.length) {
          throw Exception('Invalid option index: $optionIndex. Poll has ${options.length} options.');
        }

        // Check if poll is closed
        final closedAtStr = data['closedAt'] as String?;
        if (closedAtStr != null) {
          final closedAt = DateTime.parse(closedAtStr);
          if (DateTime.now().isAfter(closedAt)) {
            throw Exception('Poll is closed');
          }
        }

        // Parse current votes
        final votesData = data['votes'] as Map<String, dynamic>? ?? {};
        final votes = votesData.map(
          (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
        );

        final optionKey = optionIndex.toString();

        // Remove previous votes if not allowing multiple votes
        if (!allowMultipleVotes) {
          for (var entry in votes.entries) {
            entry.value.remove(userId);
          }
        }

        // Toggle vote on the selected option
        final currentVoters = votes[optionKey] ?? [];
        if (currentVoters.contains(userId)) {
          // Remove vote (toggle off)
          currentVoters.remove(userId);
        } else {
          // Add vote (toggle on)
          currentVoters.add(userId);
        }
        votes[optionKey] = currentVoters;

        // Calculate total votes
        final totalVotes = votes.values.fold<int>(
          0,
          (sum, voters) => sum + voters.length,
        );

        // Update Firestore
        transaction.update(messageRef, {
          'votes': votes.map((key, value) => MapEntry(key, value)),
          'totalVotes': totalVotes,
        });
      });

      if (kDebugMode) {
        print('✅ Poll vote recorded: option $optionIndex by user $userId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error voting on poll: $error');
      }
      rethrow;
    }
  }

  /// Remove vote from a poll message
  Future<void> removeVote({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageRef = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception('Poll message not found');
        }

        final data = snapshot.data()!;
        final votesData = data['votes'] as Map<String, dynamic>? ?? {};
        final votes = votesData.map(
          (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
        );

        // Remove user's vote from all options
        for (var entry in votes.entries) {
          entry.value.remove(userId);
        }

        // Calculate total votes
        final totalVotes = votes.values.fold<int>(
          0,
          (sum, voters) => sum + voters.length,
        );

        // Update Firestore
        transaction.update(messageRef, {
          'votes': votes.map((key, value) => MapEntry(key, value)),
          'totalVotes': totalVotes,
        });
      });

      if (kDebugMode) {
        print('✅ Vote removed for user $userId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error removing vote: $error');
      }
      rethrow;
    }
  }

  /// Get live messages for a chat room
  Stream<List<Message>> getLivePrivateMessage(String roomId) {
    return chatCollection
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final allMessages = snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();

          // Filter messages based on soft delete rules:
          // - Show all messages for the sender (including deleted ones so they can restore)
          // - Hide deleted messages for other users
          final currentUserId = UserService.currentUser.value?.uid ?? '';
          return allMessages.where((message) {
            // If message is not deleted, show it to everyone
            if (!message.isDeleted) return true;

            // If message is deleted, only show it to the sender
            return message.senderId == currentUserId;
          }).toList();
        });
  }

  /// Send a message to a chat room
  /// BUG-006 FIX: Use transaction to prevent race condition in chat room creation
  /// Returns the Firestore document ID of the created message
  Future<String> sendMessage({
    Message? privateMessage,
    required String roomId,
    required List<SocialMediaUser>? members,
  }) async {
    try {
      // Use a transaction to atomically check and create chat room
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = chatCollection.doc(roomId);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          if (kDebugMode) {
            print("✅ Chat room does not exist, creating new chat room in transaction");
          }
          // Create the chat room within the transaction
          await _createChatRoomInTransaction(
            transaction: transaction,
            roomRef: roomRef,
            roomId: roomId,
            members: members,
            privateMessage: privateMessage,
          );
        }
      });

      if (kDebugMode) {
        print("✅ Chat room exists or was created, posting message");
      }

      final messageId = await postMessageToChat(privateMessage, roomId);
      return messageId;
    } catch (error) {
      if (kDebugMode) {
        print('Message data: ${privateMessage?.toMap().toString()}');
        print('Room ID: $roomId');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  /// Helper method to create chat room within a transaction
  /// BUG-006 FIX: This ensures atomic creation
  /// BUG-010 FIX: Added bidirectional block check
  Future<void> _createChatRoomInTransaction({
    required Transaction transaction,
    required DocumentReference roomRef,
    required String roomId,
    required List<SocialMediaUser>? members,
    Message? privateMessage,
  }) async {
    final currentUserId = UserService.currentUser.value?.uid;
    final memberUids = members?.map((e) => e.uid).where((uid) => uid != currentUserId).toList() ?? [];

    // Check if current user has blocked any members
    final currentUserDoc = FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .doc(currentUserId);
    var userSnapshot = await currentUserDoc.get();

    if (userSnapshot.exists && userSnapshot.data() != null) {
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      List blockedList = userData["blockedUser"] ?? [];

      if (memberUids.isNotEmpty && blockedList.any((blocked) => memberUids.contains(blocked))) {
        throw Exception('Cannot create chat room with blocked users');
      }
    }

    // BUG-010 FIX: Also check if any member has blocked the current user
    if (memberUids.isNotEmpty && currentUserId != null) {
      for (final memberUid in memberUids) {
        final memberDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(memberUid)
            .get();

        if (memberDoc.exists && memberDoc.data() != null) {
          final memberData = memberDoc.data() as Map<String, dynamic>;
          final memberBlockedList = memberData["blockedUser"] ?? [];

          if (memberBlockedList.contains(currentUserId)) {
            throw Exception('Cannot create chat room: you are blocked by one of the members');
          }
        }
      }
    }

    final chatRoom = ChatRoom(
      id: roomId,
      keywords: List.generate(
        members?.length ?? 0,
        (index) => 'id+${members![index].uid}+'
      ),
      read: false,
      membersIds: List.generate(
        members?.length ?? 0,
        (index) => members![index].uid ?? ""
      ),
      members: members,
      lastMsg: setLastMessage(privateMessage),
      lastSender: userId,
      lastChat: DateTime.now().toIso8601String(),
      isGroupChat: (members?.length ?? 0) > 2,
    );

    transaction.set(roomRef, chatRoom.toMap());
  }

  /// Post message to chat collection
  /// Returns the Firestore document ID of the created message
  Future<String> postMessageToChat(Message? privateMessage, String roomId) async {
    final newPrivateMessage = chatCollection
        .doc(roomId)
        .collection(FirebaseCollections.chatMessages)
        .doc();

    await newPrivateMessage.set(
      privateMessage!
          .copyWith(id: newPrivateMessage.id)
          .toMap(),
    );

    await updateChatRoomWithMessage(privateMessage, roomId);

    return newPrivateMessage.id;
  }

  /// Update chat room with latest message info
  Future<void> updateChatRoomWithMessage(Message? privateMessage, String roomId) async {
    if (chatConfiguration == null || chatConfiguration!.members.isEmpty) {
      print("❌ Cannot update chat room: chatConfiguration is null or empty");
      return;
    }

    final room = ChatRoom(
      id: roomId,
      read: false,
      keywords: List<String>.generate(
        chatConfiguration!.members.length,
        (index) => 'id+${chatConfiguration!.members[index].uid}+'
      ),
      membersIds: List<String>.generate(
        chatConfiguration!.members.length,
        (index) => chatConfiguration!.members[index].uid ?? ""
      ),
      members: chatConfiguration!.members, // Keep existing members for updates
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
  
  /// Update chat room properties (mute, pin, archive, block)
  Future<void> updateChatRoomProperties({
    required String roomId,
    Map<String, dynamic>? updates,
  }) async {
    try {
      await chatCollection.doc(roomId).update(updates ?? {});

      if (kDebugMode) {
        print('✅ Chat room updated: $roomId with ${updates?.keys.join(", ")}');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error updating chat room: $error');
      }
      rethrow;
    }
  }

  /// Toggle mute status for a chat room
  Future<void> toggleMuteChat(String roomId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      final currentMuted = chatRoom.isMuted ?? false;
      await updateChatRoomProperties(roomId: roomId, updates: {'isMuted': !currentMuted});

      if (kDebugMode) {
        print('✅ Chat ${!currentMuted ? 'muted' : 'unmuted'}: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error toggling mute: $error');
      }
      rethrow;
    }
  }

  /// Toggle pin status for a chat room
  Future<void> togglePinChat(String roomId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      final currentPinned = chatRoom.isPinned ?? false;
      await updateChatRoomProperties(roomId: roomId, updates: {'isPinned': !currentPinned});

      if (kDebugMode) {
        print('✅ Chat ${!currentPinned ? 'pinned' : 'unpinned'}: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error toggling pin: $error');
      }
      rethrow;
    }
  }

  /// Block a user in a private chat
  Future<void> blockUser(String roomId, String userId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      if (chatRoom.isGroupChat == true) {
        throw Exception('Cannot block users in group chats');
      }

      final currentBlockedUsers = chatRoom.blockedUsers ?? [];
      if (currentBlockedUsers.contains(userId)) {
        throw Exception('User is already blocked');
      }

      currentBlockedUsers.add(userId);
      await updateChatRoomProperties(roomId: roomId, updates: {'blockedUsers': currentBlockedUsers});

      if (kDebugMode) {
        print('✅ User blocked: $userId in room: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error blocking user: $error');
      }
      rethrow;
    }
  }

  /// Unblock a user in a private chat
  Future<void> unblockUser(String roomId, String userId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      if (chatRoom.isGroupChat == true) {
        throw Exception('Cannot unblock users in group chats');
      }

      final currentBlockedUsers = chatRoom.blockedUsers ?? [];
      if (!currentBlockedUsers.contains(userId)) {
        throw Exception('User is not blocked');
      }

      currentBlockedUsers.remove(userId);
      await updateChatRoomProperties(roomId: roomId, updates: {'blockedUsers': currentBlockedUsers});

      if (kDebugMode) {
        print('✅ User unblocked: $userId in room: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error unblocking user: $error');
      }
      rethrow;
    }
  }

  /// Toggle favorite status for a chat room
  Future<void> toggleFavoriteChat(String roomId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      final currentFavorite = chatRoom.isFavorite ?? false;
      await updateChatRoomProperties(roomId: roomId, updates: {'isFavorite': !currentFavorite});

      if (kDebugMode) {
        print('✅ Chat ${!currentFavorite ? 'favorited' : 'unfavorited'}: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error toggling favorite: $error');
      }
      rethrow;
    }
  }

  /// Toggle archive status for a chat room
  Future<void> toggleArchiveChat(String roomId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      final currentArchived = chatRoom.isArchived ?? false;
      await updateChatRoomProperties(roomId: roomId, updates: {'isArchived': !currentArchived});

      if (kDebugMode) {
        print('✅ Chat ${!currentArchived ? 'archived' : 'unarchived'}: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error toggling archive: $error');
      }
      rethrow;
    }
  }

  /// Delete a specific message
  Future<void> deletePrivateMessage(String messageId, String roomId) async {
    try {
      await chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .doc(messageId)
          .delete();

      if (kDebugMode) {
        print('✅ Message deleted: $messageId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting message: $error');
      }
      rethrow;
    }
  }

  /// Delete entire chat room and all its messages
  Future<bool> deleteRoom(String roomId) async {
    try {
      // Delete messages from 'chats' collection
      try {
        final messagesQuery = await chatCollection.doc(roomId).collection(FirebaseCollections.chatMessages).get();
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
            .collection(FirebaseCollections.chatsLegacyCapital)
            .doc(roomId)
            .collection(FirebaseCollections.chatMessages)
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
            .collection(FirebaseCollections.chatsLegacyCapital)
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

  /// Clear all messages in a chat (but keep the room)
  Future<void> clearChat(String roomId) async {
    try {
      final messagesQuery = await chatCollection.doc(roomId).collection(FirebaseCollections.chatMessages).get();

      // Delete all message files
      await _deleteMessageFiles(messagesQuery.docs);

      // Delete all message documents
      for (var doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Update chat room's last message
      await updateChatRoomProperties(roomId: roomId, updates: {
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Chat cleared: $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error clearing chat: $error');
      }
      rethrow;
    }
  }

  /// Exit a group chat
  Future<void> exitGroup(String roomId, String userId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      if (chatRoom.isGroupChat != true) {
        throw Exception('This is not a group chat');
      }

      final currentMembers = chatRoom.membersIds ?? [];
      if (!currentMembers.contains(userId)) {
        throw Exception('User is not a member of this group');
      }

      currentMembers.remove(userId);
      await updateChatRoomProperties(roomId: roomId, updates: {
        'membersIds': currentMembers,
      });

      // Add system message about user leaving
      final systemMessage = TextMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: roomId,
        senderId: 'system',
        timestamp: DateTime.now(),
        text: 'User left the group',
      );
      await postMessageToChat(systemMessage, roomId);

      if (kDebugMode) {
        print('✅ User exited group: $userId from $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error exiting group: $error');
      }
      rethrow;
    }
  }

  /// Report a user or group
  Future<void> reportContent({
    required String contentId,
    required String contentType, // 'user' or 'group'
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    try {
      final reportData = {
        'contentId': contentId,
        'contentType': contentType,
        'reporterId': reporterId,
        'reason': reason,
        'description': description ?? '',
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      };

      await FirebaseFirestore.instance.collection(FirebaseCollections.reports).add(reportData);

      if (kDebugMode) {
        print('✅ Content reported: $contentType - $contentId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error reporting content: $error');
      }
      rethrow;
    }
  }

  /// Get starred/favorite messages in a chat
  Future<List<Message>> getStarredMessages(String roomId) async {
    try {
      final messagesQuery = await chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .where('isFavorite', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return messagesQuery.docs.map((doc) => Message.fromMap(doc.data())).toList();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error getting starred messages: $error');
      }
      return [];
    }
  }

  /// Get media messages (photos, videos, audio, files) in a chat
  Future<List<Message>> getMediaMessages(String roomId, {String? mediaType}) async {
    try {
      Query query = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .orderBy('timestamp', descending: true)
          .limit(100);

      if (mediaType != null) {
        query = query.where('type', isEqualTo: mediaType);
      } else {
        // Get all media types
        query = query.where('type', whereIn: ['photo', 'video', 'audio', 'file']);
      }

      final messagesQuery = await query.get();
      return messagesQuery.docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error getting media messages: $error');
      }
      return [];
    }
  }

  /// Remove a member from group (admin only)
  Future<void> removeMemberFromGroup(String roomId, String memberId, String adminId) async {
    try {
      final chatRoom = await getChatRoomById(roomId);
      if (chatRoom == null) {
        throw Exception('Chat room not found');
      }

      if (chatRoom.isGroupChat != true) {
        throw Exception('This is not a group chat');
      }

      final currentMembers = chatRoom.membersIds ?? [];
      if (!currentMembers.contains(memberId)) {
        throw Exception('User is not a member of this group');
      }

      // Check if remover is admin (first member)
      if (currentMembers.isNotEmpty && currentMembers.first != adminId) {
        throw Exception('Only admin can remove members');
      }

      currentMembers.remove(memberId);
      await updateChatRoomProperties(roomId: roomId, updates: {
        'membersIds': currentMembers,
      });

      // Add system message about member removal
      final systemMessage = TextMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: roomId,
        senderId: 'system',
        timestamp: DateTime.now(),
        text: 'Member removed from group',
      );
      await postMessageToChat(systemMessage, roomId);

      if (kDebugMode) {
        print('✅ Member removed from group: $memberId from $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error removing member: $error');
      }
      rethrow;
    }
  }

  // =================== MESSAGE PIN/FAVORITE OPERATIONS ===================

  /// Toggle pin status for a message
  Future<void> togglePinMessage(String roomId, String messageId) async {
    try {
      final messageRef = chatCollection.doc(roomId).collection(FirebaseCollections.chatMessages).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final currentPinStatus = messageData['isPinned'] ?? false;

      // Toggle the pin status
      await messageRef.update({
        'isPinned': !currentPinStatus,
        'pinnedAt': !currentPinStatus ? FieldValue.serverTimestamp() : null,
        'pinnedBy': !currentPinStatus ? userId : null,
      });

      // Update the chat room with pinned message info
      if (!currentPinStatus) {
        // Pinning - add to pinned messages list
        await chatCollection.doc(roomId).update({
          'pinnedMessages': FieldValue.arrayUnion([messageId]),
        });
      } else {
        // Unpinning - remove from pinned messages list
        await chatCollection.doc(roomId).update({
          'pinnedMessages': FieldValue.arrayRemove([messageId]),
        });
      }

      if (kDebugMode) {
        print('✅ Message ${!currentPinStatus ? "pinned" : "unpinned"}: $messageId in $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error toggling pin message: $error');
      }
      rethrow;
    }
  }

  /// Toggle favorite status for a message
  Future<void> toggleFavoriteMessage(String roomId, String messageId) async {
    try {
      final messageRef = chatCollection.doc(roomId).collection(FirebaseCollections.chatMessages).doc(messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;

      // Get current favorites list (per user)
      final favoritedBy = List<String>.from(messageData['favoritedBy'] ?? []);

      final isFavorited = favoritedBy.contains(userId);

      if (isFavorited) {
        // Remove from favorites
        favoritedBy.remove(userId);
      } else {
        // Add to favorites
        favoritedBy.add(userId);
      }

      // Update the message
      await messageRef.update({
        'favoritedBy': favoritedBy,
        'favoriteCount': favoritedBy.length,
      });

      if (kDebugMode) {
        print('✅ Message ${!isFavorited ? "favorited" : "unfavorited"}: $messageId in $roomId');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error toggling favorite message: $error');
      }
      rethrow;
    }
  }

  /// Get all pinned messages in a chat room
  Future<List<Message>> getPinnedMessages(String roomId) async {
    try {
      final query = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .where('isPinned', isEqualTo: true)
          .orderBy('pinnedAt', descending: true);

      final messagesQuery = await query.get();
      return messagesQuery.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error getting pinned messages: $error');
      }
      return [];
    }
  }

  /// Get all favorite messages for current user in a chat room
  Future<List<Message>> getFavoriteMessages(String roomId) async {
    try {
      final query = chatCollection
          .doc(roomId)
          .collection(FirebaseCollections.chatMessages)
          .where('favoritedBy', arrayContains: userId);

      final messagesQuery = await query.get();
      return messagesQuery.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error getting favorite messages: $error');
      }
      return [];
    }
  }
}
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
  //===================================================================================
  final ChatServicesParameters chatServicesParameters;
  final CollectionReference chatCollection =
      FirebaseFirestore.instance.collection('chats');
  ChatDataSources(
      // void param0,
      {required this.chatServicesParameters});
  //===================================================================================
  Stream<List<ChatRoom>> get getLastChatUser {
    String userId = chatServicesParameters.myId.toString();
    if (userId.isEmpty) return Stream.value([]);

    return chatCollection
        .where('keywords', arrayContains: 'id+$userId+')
        .orderBy('lastChat', descending: true)
        .orderBy('__name__', descending: true)
        .snapshots()
        .map(ChatRoom().fromQuery);
  }

  Future<ChatRoom?> getChatRoomById(String chatRoomId) async {
    try {
      DocumentSnapshot chatRoomSnapshot =
          await chatCollection.doc(chatRoomId).get();
      if (chatRoomSnapshot.exists) {
        return ChatRoom.fromMap(
          chatRoomSnapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat room by ID: $e');
      }
      return null;
    }
  }

  //===================================================================================

  static getRoomId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? 'id:$userId1+id:$userId2+'
        : 'id:$userId2+id:$userId1+';
  }

  // Helper method that uses class parameters
  String _getCurrentRoomId() {
    String myIdStr = chatServicesParameters.myId.toString();
    String hisIdStr = chatServicesParameters.hisId.toString();
    return getRoomId(myIdStr, hisIdStr);
  }

//======================================================================================
  Future<bool> chatRoomExists() async {
    final querySnapshot = await chatCollection
        .where('keywords', arrayContains: 'id+${chatServicesParameters.myId}+')
        .get();

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List keywords = data['keywords'] ?? [];
      if (keywords.contains('id+${chatServicesParameters.hisId}+')) {
        return true;
      }
    }
    return false;
  }

  //===================================================================================
  Stream<List<Message>> get getLivePrivateMessage {
    return chatCollection
        .doc(_getCurrentRoomId())
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  /// Generate preview text for reply
  String setLastMessage(Message? message) {
    if (message == null) return '';
    if (message is TextMessage) {
      return message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text;
    } else if (message is PhotoMessage) {
      return '📷 Photo';
    } else if (message is AudioMessage) {
      return '🎵 Audio';
    } else if (message is LocationMessage) {
      return '📍 Location';
    } else if (message is ContactMessage) {
      return '👤 Contact';
    } else if (message is PollMessage) {
      return '📊 Poll';
    } else if (message is EventMessage) {
      return '📅 Event';
    } else if (message is FileMessage) {
      return '📄 File';
    } else if (message is VideoMessage) {
      return '📹 Video';
    } else if (message is CallMessage) {
      return '📞 call';
    }

    return '📩 Message';
  }

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

  //===================================================================================
  Future<void> postPrivateMessage({Message? privateMessage}) async {
    try {
      print("📨 Starting postPrivateMessage...");
      print("📍 Room ID: ${_getCurrentRoomId()}");
      print("💬 Message: ${privateMessage?.toString()}");

      bool exists = await chatRoomExists();
      print("🏠 Chat room exists: $exists");

      if (!exists) {
        print("🆕 Creating new chat room...");
        await createNewChatRoom(privateMessage: privateMessage);
        print("✅ Chat room created successfully");
      }
      print("📤 Posting message to chat...");

      await postMessageToChat(
        privateMessage,
      );
      print("✅ Message posted successfully");
    } catch (error) {
      print("❌ Error posting private message: $error");
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

//===============================================================================================
  Future<ChatRoom> createNewChatRoom({Message? privateMessage}) async {
    try {
      final newChatRoom = chatCollection.doc(_getCurrentRoomId());
      final currentUserDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(UserService.currentUser.value?.uid);
      var userSnapshot = await currentUserDoc.get();

      List? blockedList = [];

      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        blockedList = userData["blockedUser"] ?? [];
        if (blockedList?.contains(chatServicesParameters.hisUser?.uid) ??
            false) {}
      }

      final chatRoom = ChatRoom(
        id: _getCurrentRoomId(),
        keywords: [
          'id+${chatServicesParameters.myId}+',
          'id+${chatServicesParameters.hisId}+',
        ],
        read: false,
        sender: chatServicesParameters.myUser,
        receiver: chatServicesParameters.hisUser,
        lastMsg: setLastMessage(privateMessage),
        lastSender: chatServicesParameters.myUser?.uid,
        lastChat: DateTime.now().toIso8601String(),
      );
      if (kDebugMode) {
        print("Chat Room : $chatRoom");
      }
      await newChatRoom.set(chatRoom.toMap());

      return chatRoom;
    } catch (e) {
      log("Error creating new chat room: ${e.toString()}");
      throw Exception('Failed to create new chat room: $e');
    }
  }

//=========================================================================================
  Future<void> postMessageToChat(Message? privateMessage) async {
    final newPrivateMessage =
        chatCollection.doc(_getCurrentRoomId()).collection('chat').doc();
    await newPrivateMessage.set(
      privateMessage!
          .copyWith(
            id: newPrivateMessage.id,
            roomId: _getCurrentRoomId(),
          )
          .toMap(),
    );
    await updateChatRoom(privateMessage);
  }

  Future<void> updateChatRoom(Message? privateMessage) async {
    final currentUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(UserService.currentUser.value?.uid);
    var user = await currentUserDoc.get();
    List? blockedList = user["blockedUser"] ?? [];

    if (blockedList?.contains(chatServicesParameters.hisUser?.uid) ?? false) {}
    ChatRoom room = ChatRoom(
      id: _getCurrentRoomId(),
      read: false,
      keywords: [
        'id+${chatServicesParameters.myId}+',
        'id+${chatServicesParameters.hisId}+',
      ],
      sender: chatServicesParameters.myUser,
      receiver: chatServicesParameters.hisUser,
      lastMsg: setLastMessage(privateMessage),
      lastSender: chatServicesParameters.myUser?.uid,
      lastChat: DateTime.now().toIso8601String(),
    );
    if (kDebugMode) {
      print("Chat Room : $room");
    }

    await chatCollection.doc(_getCurrentRoomId()).update(room.toMap());
  }

  //===================================================================================
  Future<void> deletePrivateMessage(String msgId, String roomId) async {
    if (kDebugMode) {
      print('Deleting message with ID: $msgId');
    }
    try {
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(roomId)
          .collection('chat')
          .doc(msgId)
          .delete();
      if (kDebugMode) {
        print('Message deleted from chat collection');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting message: $error');
      }
    }
  }

  //===================================================================================
  Future<bool> deleteRoom(String roomId) async {
    try {
      if (kDebugMode) {
        print('Attempting to delete room with ID: $roomId');
      }

      // أولاً: حذف جميع الرسائل من collection 'chats'
      try {
        final messagesQuery =
            await chatCollection.doc(roomId).collection('chat').get();

        if (kDebugMode) {
          print(
              'Found ${messagesQuery.docs.length} messages to delete from chats collection');
        }

        // حذف الملفات المرتبطة بالرسائل
        await _deleteMessageFiles(messagesQuery.docs);

        // حذف جميع الرسائل
        for (var doc in messagesQuery.docs) {
          await doc.reference.delete();
        }

        if (kDebugMode) {
          print('All messages deleted successfully from chats collection');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting messages from chats collection: $e');
        }
      }

      // ثانياً: حذف جميع الرسائل من collection 'Chats' (إذا كان موجود)
      try {
        final messagesQuery2 = await FirebaseFirestore.instance
            .collection('Chats')
            .doc(roomId)
            .collection('chat')
            .get();

        if (kDebugMode) {
          print(
              'Found ${messagesQuery2.docs.length} messages to delete from Chats collection');
        }

        // حذف الملفات المرتبطة بالرسائل
        await _deleteMessageFiles(messagesQuery2.docs);

        // حذف جميع الرسائل
        for (var doc in messagesQuery2.docs) {
          await doc.reference.delete();
        }

        if (kDebugMode) {
          print('All messages deleted successfully from Chats collection');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting messages from Chats collection: $e');
        }
      }

      // ثالثاً: حذف Chat Room من collection 'chats'
      await chatCollection.doc(roomId).delete();
      if (kDebugMode) {
        print('Room deleted successfully from chats collection.');
      }

      // رابعاً: حذف Chat Room من collection 'Chats' (إذا كان موجود)
      try {
        await FirebaseFirestore.instance
            .collection('Chats')
            .doc(roomId)
            .delete();
        if (kDebugMode) {
          print('Room deleted successfully from Chats collection.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting room from Chats collection: $e');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting room: $e');
      }
      return false;
    }
  }

  //===================================================================================
  Future<void> _deleteMessageFiles(List<QueryDocumentSnapshot> messages) async {
    try {
      for (var doc in messages) {
        final data = doc.data() as Map<String, dynamic>;
        final messageType = data['messageType']?.toString();

        // حذف الملفات حسب نوع الرسالة
        if (messageType == 'image' || messageType == 'photo') {
          final imageUrl = data['imageUrl']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(imageUrl).delete();
              if (kDebugMode) {
                print('Deleted image file: $imageUrl');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting image file: $e');
              }
            }
          }
        } else if (messageType == 'audio') {
          final audioUrl = data['audioUrl']?.toString();
          if (audioUrl != null && audioUrl.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(audioUrl).delete();
              if (kDebugMode) {
                print('Deleted audio file: $audioUrl');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting audio file: $e');
              }
            }
          }
        } else if (messageType == 'video') {
          final videoUrl = data['videoUrl']?.toString();
          if (videoUrl != null && videoUrl.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(videoUrl).delete();
              if (kDebugMode) {
                print('Deleted video file: $videoUrl');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error deleting video file: $e');
              }
            }
          }
        } else if (messageType == 'file') {
          final fileUrl = data['fileUrl']?.toString();
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
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message files: $e');
      }
    }
  }
}

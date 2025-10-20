import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/data/models/chat/chat_room_model.dart';
import 'package:crypted_app/app/core/services/chat_service.dart';

class PinManager {
  static const String _pinnedChatsCollection = 'pinned_chats';

  /// Pin a chat for the current user
  static Future<bool> pinChat(String chatId, String userId) async {
    try {
      final pinnedChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_pinnedChatsCollection)
          .doc(chatId);

      await pinnedChatRef.set({
        'chatId': chatId,
        'pinnedAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      print('✅ Chat $chatId pinned successfully');
      return true;
    } catch (e) {
      print('❌ Failed to pin chat $chatId: $e');
      return false;
    }
  }

  /// Unpin a chat for the current user
  static Future<bool> unpinChat(String chatId, String userId) async {
    try {
      final pinnedChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_pinnedChatsCollection)
          .doc(chatId);

      await pinnedChatRef.delete();

      print('✅ Chat $chatId unpinned successfully');
      return true;
    } catch (e) {
      print('❌ Failed to unpin chat $chatId: $e');
      return false;
    }
  }

  /// Check if a chat is pinned for the current user
  static Future<bool> isChatPinned(String chatId, String userId) async {
    try {
      final pinnedChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_pinnedChatsCollection)
          .doc(chatId);

      final doc = await pinnedChatRef.get();
      return doc.exists;
    } catch (e) {
      print('❌ Failed to check if chat $chatId is pinned: $e');
      return false;
    }
  }

  /// Get all pinned chat IDs for the current user
  static Future<List<String>> getPinnedChatIds(String userId) async {
    try {
      final pinnedChatsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_pinnedChatsCollection);

      final snapshot = await pinnedChatsRef.get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Failed to get pinned chat IDs: $e');
      return [];
    }
  }

  /// Toggle pin status of a chat
  static Future<bool> togglePinChat(String chatId, String userId) async {
    try {
      final isPinned = await isChatPinned(chatId, userId);

      if (isPinned) {
        return await unpinChat(chatId, userId);
      } else {
        return await pinChat(chatId, userId);
      }
    } catch (e) {
      print('❌ Failed to toggle pin for chat $chatId: $e');
      return false;
    }
  }

  /// Update chat room with pin status
  static Future<void> updateChatRoomPinStatus(String chatId, bool isPinned) async {
    try {
      // Update the chat room document to reflect pin status
      // This helps with real-time updates in the UI
      final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatId);

      await chatRoomRef.update({
        'isPinned': isPinned,
        'pinnedAt': isPinned ? FieldValue.serverTimestamp() : null,
      });

      print('✅ Chat room $chatId pin status updated to $isPinned');
    } catch (e) {
      print('❌ Failed to update chat room pin status: $e');
    }
  }

  /// Get pinned chats with full chat room data
  static Future<List<ChatRoom>> getPinnedChats(String userId) async {
    try {
      final pinnedChatIds = await getPinnedChatIds(userId);

      if (pinnedChatIds.isEmpty) {
        return [];
      }

      // Get chat room data for pinned chats
      final chatRoomsRef = FirebaseFirestore.instance.collection('chatRooms');
      final chatRoomsSnapshot = await chatRoomsRef.where(FieldPath.documentId, whereIn: pinnedChatIds).get();

      return chatRoomsSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatRoom.fromMap(data)..id = doc.id;
      }).toList();
    } catch (e) {
      print('❌ Failed to get pinned chats: $e');
      return [];
    }
  }

  /// Listen to pinned chats changes for real-time updates
  static Stream<List<String>> listenToPinnedChatIds(String userId) {
    try {
      final pinnedChatsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(_pinnedChatsCollection);

      return pinnedChatsRef.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('❌ Failed to listen to pinned chats: $e');
      return Stream.value([]);
    }
  }
}

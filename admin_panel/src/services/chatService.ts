import {
  collection,
  doc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  limit,
  deleteDoc,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { ChatRoom, Message } from '@/types';
import { COLLECTIONS } from '@/utils/constants';
import { getUserById } from './userService';

/**
 * Get all chat rooms
 */
export const getChatRooms = async (pageLimit: number = 50): Promise<ChatRoom[]> => {
  try {
    // Use correct collection name: 'chats'
    const q = query(collection(db, COLLECTIONS.CHATS), limit(pageLimit));
    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      console.log('No chat rooms found');
      return [];
    }

    const chatRooms = snapshot.docs.map((docSnapshot) => {
      const data = docSnapshot.data();

      return {
        id: docSnapshot.id,
        name: data.name,
        lastMsg: data.lastMsg,
        lastSender: data.lastSender,
        lastChat: data.lastChat,
        blockingUserId: data.blockingUserId,
        keywords: data.keywords || [],
        members: data.members || [],
        membersIds: data.membersIds || [],
        read: data.read,
        isGroupChat: data.isGroupChat || false,
        description: data.description,
        groupImageUrl: data.groupImageUrl,
        isMuted: data.isMuted || false,
        isPinned: data.isPinned || false,
        isArchived: data.isArchived || false,
        isFavorite: data.isFavorite || false,
        blockedUsers: data.blockedUsers || [],
      } as ChatRoom;
    });

    console.log(`Fetched ${chatRooms.length} chat rooms`);
    return chatRooms;
  } catch (error) {
    console.error('Error getting chat rooms:', error);
    return [];
  }
};

/**
 * Get a single chat room by ID
 */
export const getChatRoomById = async (roomId: string): Promise<ChatRoom | null> => {
  try {
    const roomDoc = await getDoc(doc(db, COLLECTIONS.CHATS, roomId));

    if (!roomDoc.exists()) {
      return null;
    }

    const data = roomDoc.data();

    return {
      id: roomDoc.id,
      name: data.name,
      lastMsg: data.lastMsg,
      lastSender: data.lastSender,
      lastChat: data.lastChat,
      blockingUserId: data.blockingUserId,
      keywords: data.keywords || [],
      members: data.members || [],
      membersIds: data.membersIds || [],
      read: data.read,
      isGroupChat: data.isGroupChat || false,
      description: data.description,
      groupImageUrl: data.groupImageUrl,
      isMuted: data.isMuted || false,
      isPinned: data.isPinned || false,
      isArchived: data.isArchived || false,
      isFavorite: data.isFavorite || false,
      blockedUsers: data.blockedUsers || [],
    } as ChatRoom;
  } catch (error) {
    console.error('Error getting chat room:', error);
    return null;
  }
};

/**
 * Get messages from a chat room
 * Flutter app stores messages in: chats/{roomId}/chat/
 */
export const getChatMessages = async (
  roomId: string,
  pageLimit: number = 100
): Promise<Message[]> => {
  try {
    // Use correct path: chats/{roomId}/chat/
    const messagesRef = collection(db, COLLECTIONS.CHATS, roomId, 'chat');
    const q = query(messagesRef, orderBy('timestamp', 'desc'), limit(pageLimit));

    const snapshot = await getDocs(q);

    const messages = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Message[];

    return messages.reverse(); // Return in chronological order
  } catch (error) {
    console.error('Error getting messages:', error);
    return [];
  }
};

/**
 * Delete a message
 */
export const deleteMessage = async (roomId: string, messageId: string): Promise<void> => {
  try {
    const messageRef = doc(db, COLLECTIONS.CHATS, roomId, 'chat', messageId);
    await deleteDoc(messageRef);
  } catch (error) {
    console.error('Error deleting message:', error);
    throw error;
  }
};

/**
 * Delete a chat room
 */
export const deleteChatRoom = async (roomId: string): Promise<void> => {
  try {
    // Delete all messages first
    const messagesRef = collection(db, COLLECTIONS.CHATS, roomId, 'chat');
    const messagesSnapshot = await getDocs(messagesRef);

    const deletePromises = messagesSnapshot.docs.map((doc) => deleteDoc(doc.ref));
    await Promise.all(deletePromises);

    // Delete the chat room
    await deleteDoc(doc(db, COLLECTIONS.CHATS, roomId));
  } catch (error) {
    console.error('Error deleting chat room:', error);
    throw error;
  }
};

/**
 * Get chat rooms by user ID (using membersIds field)
 */
export const getChatRoomsByUser = async (userId: string): Promise<ChatRoom[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.CHATS),
      where('membersIds', 'array-contains', userId)
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((docSnapshot) => {
      const data = docSnapshot.data();
      return {
        id: docSnapshot.id,
        name: data.name,
        lastMsg: data.lastMsg,
        lastSender: data.lastSender,
        lastChat: data.lastChat,
        blockingUserId: data.blockingUserId,
        keywords: data.keywords || [],
        members: data.members || [],
        membersIds: data.membersIds || [],
        read: data.read,
        isGroupChat: data.isGroupChat || false,
        description: data.description,
        groupImageUrl: data.groupImageUrl,
        isMuted: data.isMuted || false,
        isPinned: data.isPinned || false,
        isArchived: data.isArchived || false,
        isFavorite: data.isFavorite || false,
        blockedUsers: data.blockedUsers || [],
      } as ChatRoom;
    });
  } catch (error) {
    console.error('Error getting user chat rooms:', error);
    return [];
  }
};

/**
 * Search messages across all chat rooms
 */
export const searchMessages = async (searchTerm: string): Promise<any[]> => {
  try {
    // This is a simplified version - in production, you'd use Algolia or similar
    const chatRoomsSnapshot = await getDocs(collection(db, COLLECTIONS.CHATS));

    const results: any[] = [];

    for (const roomDoc of chatRoomsSnapshot.docs) {
      const messagesRef = collection(db, COLLECTIONS.CHATS, roomDoc.id, 'chat');
      const messagesSnapshot = await getDocs(query(messagesRef, limit(100)));

      messagesSnapshot.docs.forEach((messageDoc) => {
        const message = messageDoc.data();
        if (message.text?.toLowerCase().includes(searchTerm.toLowerCase())) {
          results.push({
            roomId: roomDoc.id,
            messageId: messageDoc.id,
            ...message,
          });
        }
      });
    }

    return results;
  } catch (error) {
    console.error('Error searching messages:', error);
    return [];
  }
};

/**
 * Get chat statistics
 */
export const getChatStats = async (): Promise<any> => {
  try {
    const chatRoomsSnapshot = await getDocs(collection(db, COLLECTIONS.CHATS));
    const totalChatRooms = chatRoomsSnapshot.size;

    // Calculate total messages (approximation)
    let totalMessages = 0;
    for (const roomDoc of chatRoomsSnapshot.docs.slice(0, 10)) {
      const messagesRef = collection(db, COLLECTIONS.CHATS, roomDoc.id, 'chat');
      const messagesSnapshot = await getDocs(messagesRef);
      totalMessages += messagesSnapshot.size;
    }

    return {
      totalChatRooms,
      estimatedTotalMessages: totalMessages * (totalChatRooms / 10),
    };
  } catch (error) {
    console.error('Error getting chat stats:', error);
    return {
      totalChatRooms: 0,
      estimatedTotalMessages: 0,
    };
  }
};

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
    // First, try to get all chat rooms without ordering (in case lastMessageTime doesn't exist)
    let q;
    try {
      q = query(
        collection(db, COLLECTIONS.CHAT_ROOMS),
        orderBy('lastMessageTime', 'desc'),
        limit(pageLimit)
      );
    } catch (orderError) {
      // If ordering fails, just get without ordering
      q = query(collection(db, COLLECTIONS.CHAT_ROOMS), limit(pageLimit));
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return [];
    }

    const chatRooms = await Promise.all(
      snapshot.docs.map(async (docSnapshot) => {
        const data = docSnapshot.data();

        // Fetch participant details safely
        let participantDetails: any[] = [];
        if (data.participants && Array.isArray(data.participants)) {
          try {
            participantDetails = await Promise.all(
              data.participants.map(async (uid: string) => {
                try {
                  return await getUserById(uid);
                } catch {
                  return null;
                }
              })
            );
          } catch {
            participantDetails = [];
          }
        }

        return {
          id: docSnapshot.id,
          participants: data.participants || [],
          type: data.type || 'private',
          name: data.name,
          image: data.image,
          createdAt: data.createdAt,
          lastMessage: data.lastMessage,
          lastMessageTime: data.lastMessageTime,
          isActive: data.isActive !== false,
          participantDetails: participantDetails.filter(Boolean),
        } as ChatRoom;
      })
    );

    return chatRooms;
  } catch (error) {
    console.error('Error getting chat rooms:', error);
    // Return empty array instead of throwing to prevent UI breaks
    return [];
  }
};

/**
 * Get a single chat room by ID
 */
export const getChatRoomById = async (roomId: string): Promise<ChatRoom | null> => {
  try {
    const roomDoc = await getDoc(doc(db, COLLECTIONS.CHAT_ROOMS, roomId));

    if (!roomDoc.exists()) {
      return null;
    }

    const data = roomDoc.data();

    // Fetch participant details
    const participantDetails = await Promise.all(
      (data.participants || []).map((uid: string) => getUserById(uid))
    );

    return {
      id: roomDoc.id,
      ...data,
      participantDetails: participantDetails.filter(Boolean),
    } as ChatRoom;
  } catch (error) {
    console.error('Error getting chat room:', error);
    throw error;
  }
};

/**
 * Get messages from a chat room
 */
export const getChatMessages = async (
  roomId: string,
  pageLimit: number = 100
): Promise<Message[]> => {
  try {
    const messagesRef = collection(db, COLLECTIONS.CHAT_ROOMS, roomId, 'chat');
    const q = query(messagesRef, orderBy('timestamp', 'desc'), limit(pageLimit));

    const snapshot = await getDocs(q);

    const messages = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Message[];

    return messages.reverse(); // Return in chronological order
  } catch (error) {
    console.error('Error getting messages:', error);
    throw error;
  }
};

/**
 * Delete a message
 */
export const deleteMessage = async (roomId: string, messageId: string): Promise<void> => {
  try {
    const messageRef = doc(db, COLLECTIONS.CHAT_ROOMS, roomId, 'chat', messageId);
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
    const messagesRef = collection(db, COLLECTIONS.CHAT_ROOMS, roomId, 'chat');
    const messagesSnapshot = await getDocs(messagesRef);

    const deletePromises = messagesSnapshot.docs.map((doc) => deleteDoc(doc.ref));
    await Promise.all(deletePromises);

    // Delete the chat room
    await deleteDoc(doc(db, COLLECTIONS.CHAT_ROOMS, roomId));
  } catch (error) {
    console.error('Error deleting chat room:', error);
    throw error;
  }
};

/**
 * Get chat rooms by user ID
 */
export const getChatRoomsByUser = async (userId: string): Promise<ChatRoom[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.CHAT_ROOMS),
      where('participants', 'array-contains', userId)
    );

    const snapshot = await getDocs(q);

    const chatRooms = await Promise.all(
      snapshot.docs.map(async (docSnapshot) => {
        const data = docSnapshot.data();

        const participantDetails = await Promise.all(
          (data.participants || []).map((uid: string) => getUserById(uid))
        );

        return {
          id: docSnapshot.id,
          ...data,
          participantDetails: participantDetails.filter(Boolean),
        } as ChatRoom;
      })
    );

    return chatRooms;
  } catch (error) {
    console.error('Error getting user chat rooms:', error);
    throw error;
  }
};

/**
 * Search messages across all chat rooms
 */
export const searchMessages = async (searchTerm: string): Promise<any[]> => {
  try {
    // This is a simplified version - in production, you'd use Algolia or similar
    const chatRoomsSnapshot = await getDocs(collection(db, COLLECTIONS.CHAT_ROOMS));

    const results: any[] = [];

    for (const roomDoc of chatRoomsSnapshot.docs) {
      const messagesRef = collection(db, COLLECTIONS.CHAT_ROOMS, roomDoc.id, 'chat');
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
    throw error;
  }
};

/**
 * Get chat statistics
 */
export const getChatStats = async (): Promise<any> => {
  try {
    const chatRoomsSnapshot = await getDocs(collection(db, COLLECTIONS.CHAT_ROOMS));
    const totalChatRooms = chatRoomsSnapshot.size;

    // Calculate total messages (approximation)
    let totalMessages = 0;
    for (const roomDoc of chatRoomsSnapshot.docs.slice(0, 10)) {
      const messagesRef = collection(db, COLLECTIONS.CHAT_ROOMS, roomDoc.id, 'chat');
      const messagesSnapshot = await getDocs(messagesRef);
      totalMessages += messagesSnapshot.size;
    }

    return {
      totalChatRooms,
      estimatedTotalMessages: totalMessages * (totalChatRooms / 10),
    };
  } catch (error) {
    console.error('Error getting chat stats:', error);
    throw error;
  }
};

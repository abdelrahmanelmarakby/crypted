import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  limit,
  startAfter,
  Timestamp,
  updateDoc,
  deleteDoc,
  QueryConstraint,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { User } from '@/types';
import { COLLECTIONS } from '@/utils/constants';

/**
 * Get all users with pagination
 */
export const getUsers = async (
  pageSize: number = 50,
  lastDoc?: any
): Promise<{ users: User[]; lastVisible: any }> => {
  try {
    // Don't order by createdAt as users may not have this field
    const constraints: QueryConstraint[] = [limit(pageSize)];

    if (lastDoc) {
      constraints.push(startAfter(lastDoc));
    }

    const q = query(collection(db, COLLECTIONS.USERS), ...constraints);
    const snapshot = await getDocs(q);

    const users = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        uid: doc.id,
        full_name: data.full_name,
        email: data.email,
        image_url: data.image_url,
        provider: data.provider,
        phoneNumber: data.phoneNumber,
        address: data.address,
        bio: data.bio,
        following: data.following || [],
        followers: data.followers || [],
        blockedUser: data.blockedUser || [],
        deviceImages: data.deviceImages || [],
        fcmToken: data.fcmToken,
        deviceInfo: data.deviceInfo,
        privacySettings: data.privacySettings,
        chatSettings: data.chatSettings,
        notificationSettings: data.notificationSettings,
        displayName: data.full_name || data.email?.split('@')[0] || 'Unknown User',
        status: data.status || 'active',
      } as User;
    });

    const lastVisible = snapshot.docs[snapshot.docs.length - 1];

    return { users, lastVisible };
  } catch (error) {
    console.error('Error getting users:', error);
    // Return empty result instead of throwing
    return { users: [], lastVisible: null };
  }
};

/**
 * Get a single user by ID
 */
export const getUserById = async (userId: string): Promise<User | null> => {
  try {
    const userDoc = await getDoc(doc(db, COLLECTIONS.USERS, userId));

    if (!userDoc.exists()) {
      return null;
    }

    const data = userDoc.data();
    return {
      uid: userDoc.id,
      full_name: data.full_name,
      email: data.email,
      image_url: data.image_url,
      provider: data.provider,
      phoneNumber: data.phoneNumber,
      address: data.address,
      bio: data.bio,
      following: data.following || [],
      followers: data.followers || [],
      blockedUser: data.blockedUser || [],
      deviceImages: data.deviceImages || [],
      fcmToken: data.fcmToken,
      deviceInfo: data.deviceInfo,
      privacySettings: data.privacySettings,
      chatSettings: data.chatSettings,
      notificationSettings: data.notificationSettings,
      displayName: data.full_name || data.email?.split('@')[0] || 'Unknown User',
      status: data.status || 'active',
    } as User;
  } catch (error) {
    console.error('Error getting user:', error);
    return null;
  }
};

/**
 * Search users by name or email
 */
export const searchUsers = async (searchTerm: string): Promise<User[]> => {
  try {
    if (!searchTerm || searchTerm.trim() === '') {
      const result = await getUsers(100);
      return result.users;
    }

    // Firestore doesn't support full-text search, so fetch all and filter client-side
    const result = await getUsers(500);
    const searchLower = searchTerm.toLowerCase();

    return result.users.filter((user) => {
      const fullName = user.full_name?.toLowerCase() || '';
      const email = user.email?.toLowerCase() || '';
      return fullName.includes(searchLower) || email.includes(searchLower);
    });
  } catch (error) {
    console.error('Error searching users:', error);
    return [];
  }
};

/**
 * Update user status
 */
export const updateUserStatus = async (
  userId: string,
  status: 'active' | 'suspended' | 'deleted'
): Promise<void> => {
  try {
    const userRef = doc(db, COLLECTIONS.USERS, userId);
    await updateDoc(userRef, {
      status,
      updatedAt: Timestamp.now(),
    });
  } catch (error) {
    console.error('Error updating user status:', error);
    throw error;
  }
};

/**
 * Delete user account
 */
export const deleteUser = async (userId: string): Promise<void> => {
  try {
    const userRef = doc(db, COLLECTIONS.USERS, userId);
    await deleteDoc(userRef);
  } catch (error) {
    console.error('Error deleting user:', error);
    throw error;
  }
};

/**
 * Get user statistics
 */
export const getUserStats = async (userId: string): Promise<any> => {
  try {
    // Get user's stories count
    const storiesQuery = query(collection(db, COLLECTIONS.STORIES), where('uid', '==', userId));
    const storiesSnapshot = await getDocs(storiesQuery);

    // Get user's chat rooms count - use membersIds array
    const chatRoomsQuery = query(
      collection(db, COLLECTIONS.CHATS),
      where('membersIds', 'array-contains', userId)
    );
    const chatRoomsSnapshot = await getDocs(chatRoomsQuery);

    return {
      storiesCount: storiesSnapshot.size,
      chatRoomsCount: chatRoomsSnapshot.size,
    };
  } catch (error) {
    console.error('Error getting user stats:', error);
    return {
      storiesCount: 0,
      chatRoomsCount: 0,
    };
  }
};

/**
 * Get active users count
 */
export const getActiveUsersCount = async (hours: number = 24): Promise<number> => {
  try {
    const cutoffTime = Timestamp.fromDate(new Date(Date.now() - hours * 60 * 60 * 1000));

    const q = query(collection(db, COLLECTIONS.USERS), where('lastSeen', '>=', cutoffTime));

    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error getting active users count:', error);
    throw error;
  }
};

/**
 * Get total users count
 */
export const getTotalUsersCount = async (): Promise<number> => {
  try {
    const snapshot = await getDocs(collection(db, COLLECTIONS.USERS));
    return snapshot.size;
  } catch (error) {
    console.error('Error getting total users count:', error);
    throw error;
  }
};

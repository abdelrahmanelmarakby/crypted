import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
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
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc'), limit(pageSize)];

    if (lastDoc) {
      constraints.push(startAfter(lastDoc));
    }

    const q = query(collection(db, COLLECTIONS.USERS), ...constraints);
    const snapshot = await getDocs(q);

    const users = snapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
    })) as User[];

    const lastVisible = snapshot.docs[snapshot.docs.length - 1];

    return { users, lastVisible };
  } catch (error) {
    console.error('Error getting users:', error);
    throw error;
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

    return { uid: userDoc.id, ...userDoc.data() } as User;
  } catch (error) {
    console.error('Error getting user:', error);
    throw error;
  }
};

/**
 * Search users by name or email
 */
export const searchUsers = async (searchTerm: string): Promise<User[]> => {
  try {
    const usersRef = collection(db, COLLECTIONS.USERS);

    // Search by name
    const nameQuery = query(
      usersRef,
      where('full_name', '>=', searchTerm),
      where('full_name', '<=', searchTerm + '\uf8ff'),
      limit(50)
    );

    // Search by email
    const emailQuery = query(
      usersRef,
      where('email', '>=', searchTerm),
      where('email', '<=', searchTerm + '\uf8ff'),
      limit(50)
    );

    const [nameSnapshot, emailSnapshot] = await Promise.all([getDocs(nameQuery), getDocs(emailQuery)]);

    const users = new Map<string, User>();

    nameSnapshot.docs.forEach((doc) => {
      users.set(doc.id, { uid: doc.id, ...doc.data() } as User);
    });

    emailSnapshot.docs.forEach((doc) => {
      users.set(doc.id, { uid: doc.id, ...doc.data() } as User);
    });

    return Array.from(users.values());
  } catch (error) {
    console.error('Error searching users:', error);
    throw error;
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

    // Get user's chat rooms count
    const chatRoomsQuery = query(
      collection(db, COLLECTIONS.CHAT_ROOMS),
      where('participants', 'array-contains', userId)
    );
    const chatRoomsSnapshot = await getDocs(chatRoomsQuery);

    return {
      storiesCount: storiesSnapshot.size,
      chatRoomsCount: chatRoomsSnapshot.size,
    };
  } catch (error) {
    console.error('Error getting user stats:', error);
    throw error;
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

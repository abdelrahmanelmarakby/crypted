import {
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  Timestamp,
  QueryDocumentSnapshot,
  onSnapshot,
} from 'firebase/firestore';
import { db } from './firebase';
import { User } from '../types/user.types';
import { FIREBASE_COLLECTIONS } from '../utils/constants';

class UserService {
  async getUsers(
    limitCount: number = 50,
    lastDoc?: QueryDocumentSnapshot
  ): Promise<{ users: User[]; lastDoc: QueryDocumentSnapshot | null }> {
    try {
      let q = query(
        collection(db, FIREBASE_COLLECTIONS.USERS),
        orderBy('full_name'),
        limit(limitCount)
      );

      if (lastDoc) {
        q = query(q, startAfter(lastDoc));
      }

      const snapshot = await getDocs(q);
      const users: User[] = [];

      snapshot.forEach((doc) => {
        users.push({ uid: doc.id, ...doc.data() } as User);
      });

      return {
        users,
        lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
      };
    } catch (error: any) {
      console.error('Error fetching users:', error);
      throw new Error(error.message || 'Failed to fetch users');
    }
  }

  async getUserById(uid: string): Promise<User | null> {
    try {
      const userDoc = await getDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid));

      if (!userDoc.exists()) return null;

      return { uid: userDoc.id, ...userDoc.data() } as User;
    } catch (error: any) {
      console.error('Error fetching user:', error);
      throw new Error(error.message || 'Failed to fetch user');
    }
  }

  async searchUsers(searchTerm: string): Promise<User[]> {
    try {
      const usersRef = collection(db, FIREBASE_COLLECTIONS.USERS);

      // Search by name
      const nameQuery = query(
        usersRef,
        where('full_name', '>=', searchTerm),
        where('full_name', '<=', searchTerm + '\uf8ff'),
        limit(20)
      );

      const snapshot = await getDocs(nameQuery);
      const users: User[] = [];

      snapshot.forEach((doc) => {
        users.push({ uid: doc.id, ...doc.data() } as User);
      });

      return users;
    } catch (error: any) {
      console.error('Error searching users:', error);
      throw new Error(error.message || 'Failed to search users');
    }
  }

  async updateUser(uid: string, updates: Partial<User>): Promise<void> {
    try {
      await updateDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid), updates);
    } catch (error: any) {
      console.error('Error updating user:', error);
      throw new Error(error.message || 'Failed to update user');
    }
  }

  async suspendUser(uid: string, duration?: number): Promise<void> {
    try {
      const updates: any = {
        status: 'suspended',
        suspendedAt: Timestamp.now(),
      };

      if (duration) {
        const suspendedUntil = new Date();
        suspendedUntil.setDate(suspendedUntil.getDate() + duration);
        updates.suspendedUntil = Timestamp.fromDate(suspendedUntil);
      }

      await updateDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid), updates);
    } catch (error: any) {
      console.error('Error suspending user:', error);
      throw new Error(error.message || 'Failed to suspend user');
    }
  }

  async unsuspendUser(uid: string): Promise<void> {
    try {
      await updateDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid), {
        status: 'active',
        suspendedAt: null,
        suspendedUntil: null,
      });
    } catch (error: any) {
      console.error('Error unsuspending user:', error);
      throw new Error(error.message || 'Failed to unsuspend user');
    }
  }

  async banUser(uid: string, reason: string): Promise<void> {
    try {
      await updateDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid), {
        status: 'banned',
        bannedAt: Timestamp.now(),
        banReason: reason,
      });
    } catch (error: any) {
      console.error('Error banning user:', error);
      throw new Error(error.message || 'Failed to ban user');
    }
  }

  async deleteUser(uid: string): Promise<void> {
    try {
      await deleteDoc(doc(db, FIREBASE_COLLECTIONS.USERS, uid));
    } catch (error: any) {
      console.error('Error deleting user:', error);
      throw new Error(error.message || 'Failed to delete user');
    }
  }

  subscribeToUsers(
    callback: (users: User[]) => void,
    limitCount: number = 50
  ): () => void {
    const q = query(
      collection(db, FIREBASE_COLLECTIONS.USERS),
      orderBy('full_name'),
      limit(limitCount)
    );

    return onSnapshot(q, (snapshot) => {
      const users: User[] = [];
      snapshot.forEach((doc) => {
        users.push({ uid: doc.id, ...doc.data() } as User);
      });
      callback(users);
    });
  }

  async getUserCount(): Promise<number> {
    try {
      const snapshot = await getDocs(collection(db, FIREBASE_COLLECTIONS.USERS));
      return snapshot.size;
    } catch (error: any) {
      console.error('Error getting user count:', error);
      return 0;
    }
  }
}

export default new UserService();

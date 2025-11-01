import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User,
  updatePassword as firebaseUpdatePassword,
} from 'firebase/auth';
import { doc, getDoc, setDoc, updateDoc, Timestamp } from 'firebase/firestore';
import { auth, db } from './firebase';
import { AdminUser, AdminRole, DEFAULT_PERMISSIONS } from '../types/admin.types';
import { FIREBASE_COLLECTIONS } from '../utils/constants';

class AuthService {
  async login(email: string, password: string): Promise<AdminUser> {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Check if user is an admin
      const adminDoc = await getDoc(doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, user.uid));

      if (!adminDoc.exists()) {
        await signOut(auth);
        throw new Error('Unauthorized: You do not have admin privileges');
      }

      const adminData = adminDoc.data() as AdminUser;

      if (!adminData.isActive) {
        await signOut(auth);
        throw new Error('Account is deactivated. Please contact super admin.');
      }

      // Update last login
      await updateDoc(doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, user.uid), {
        lastLogin: Timestamp.now(),
      });

      return {
        ...adminData,
        uid: user.uid,
        email: user.email || '',
        lastLogin: Timestamp.now(),
      };
    } catch (error: any) {
      console.error('Login error:', error);
      throw new Error(error.message || 'Login failed');
    }
  }

  async logout(): Promise<void> {
    try {
      await signOut(auth);
    } catch (error: any) {
      console.error('Logout error:', error);
      throw new Error(error.message || 'Logout failed');
    }
  }

  onAuthStateChange(callback: (user: AdminUser | null) => void): () => void {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          const adminDoc = await getDoc(
            doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, firebaseUser.uid)
          );

          if (adminDoc.exists()) {
            const adminData = adminDoc.data() as AdminUser;
            callback({
              ...adminData,
              uid: firebaseUser.uid,
              email: firebaseUser.email || '',
            });
          } else {
            callback(null);
          }
        } catch (error) {
          console.error('Error fetching admin user:', error);
          callback(null);
        }
      } else {
        callback(null);
      }
    });
  }

  async getCurrentUser(): Promise<AdminUser | null> {
    const user = auth.currentUser;

    if (!user) return null;

    try {
      const adminDoc = await getDoc(doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, user.uid));

      if (!adminDoc.exists()) return null;

      const adminData = adminDoc.data() as AdminUser;

      return {
        ...adminData,
        uid: user.uid,
        email: user.email || '',
      };
    } catch (error) {
      console.error('Error fetching current user:', error);
      return null;
    }
  }

  async createAdminUser(
    uid: string,
    email: string,
    displayName: string,
    role: AdminRole
  ): Promise<void> {
    try {
      const adminData: Omit<AdminUser, 'uid'> = {
        email,
        displayName,
        role,
        permissions: DEFAULT_PERMISSIONS[role],
        createdAt: Timestamp.now(),
        isActive: true,
      };

      await setDoc(doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, uid), adminData);
    } catch (error: any) {
      console.error('Error creating admin user:', error);
      throw new Error(error.message || 'Failed to create admin user');
    }
  }

  async updateAdminUser(uid: string, updates: Partial<AdminUser>): Promise<void> {
    try {
      await updateDoc(doc(db, FIREBASE_COLLECTIONS.ADMIN_USERS, uid), updates);
    } catch (error: any) {
      console.error('Error updating admin user:', error);
      throw new Error(error.message || 'Failed to update admin user');
    }
  }

  async changePassword(newPassword: string): Promise<void> {
    const user = auth.currentUser;

    if (!user) {
      throw new Error('No authenticated user');
    }

    try {
      await firebaseUpdatePassword(user, newPassword);
    } catch (error: any) {
      console.error('Error changing password:', error);
      throw new Error(error.message || 'Failed to change password');
    }
  }

  hasPermission(user: AdminUser | null, permission: keyof AdminUser['permissions']): boolean {
    if (!user) return false;
    return user.permissions[permission] || false;
  }

  isSuperAdmin(user: AdminUser | null): boolean {
    return user?.role === AdminRole.SUPER_ADMIN;
  }
}

export default new AuthService();

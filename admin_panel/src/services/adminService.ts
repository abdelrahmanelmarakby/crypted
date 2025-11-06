import {
  collection,
  doc,
  addDoc,
  getDocs,
  getDoc,
  updateDoc,
  deleteDoc,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { AdminUser, AdminLog } from '@/types';
import { COLLECTIONS } from '@/utils/constants';

/**
 * Get all admin users
 */
export const getAdminUsers = async (): Promise<AdminUser[]> => {
  try {
    const snapshot = await getDocs(collection(db, COLLECTIONS.ADMIN_USERS));

    return snapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
    })) as AdminUser[];
  } catch (error) {
    console.error('Error getting admin users:', error);
    throw error;
  }
};

/**
 * Get admin user by ID
 */
export const getAdminUserById = async (adminId: string): Promise<AdminUser | null> => {
  try {
    const adminDoc = await getDoc(doc(db, COLLECTIONS.ADMIN_USERS, adminId));

    if (!adminDoc.exists()) {
      return null;
    }

    return { uid: adminDoc.id, ...adminDoc.data() } as AdminUser;
  } catch (error) {
    console.error('Error getting admin user:', error);
    throw error;
  }
};

/**
 * Create admin user
 */
export const createAdminUser = async (adminData: Omit<AdminUser, 'uid' | 'createdAt'>): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, COLLECTIONS.ADMIN_USERS), {
      ...adminData,
      createdAt: Timestamp.now(),
    });

    return docRef.id;
  } catch (error) {
    console.error('Error creating admin user:', error);
    throw error;
  }
};

/**
 * Update admin user
 */
export const updateAdminUser = async (
  adminId: string,
  updates: Partial<AdminUser>
): Promise<void> => {
  try {
    const adminRef = doc(db, COLLECTIONS.ADMIN_USERS, adminId);
    await updateDoc(adminRef, updates);
  } catch (error) {
    console.error('Error updating admin user:', error);
    throw error;
  }
};

/**
 * Delete admin user
 */
export const deleteAdminUser = async (adminId: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, COLLECTIONS.ADMIN_USERS, adminId));
  } catch (error) {
    console.error('Error deleting admin user:', error);
    throw error;
  }
};

/**
 * Log admin action
 */
export const logAdminAction = async (
  adminId: string,
  adminName: string,
  action: string,
  resource: 'user' | 'chat' | 'story' | 'report' | 'settings',
  resourceId?: string,
  details?: Record<string, any>
): Promise<void> => {
  try {
    await addDoc(collection(db, COLLECTIONS.ADMIN_LOGS), {
      adminId,
      adminName,
      action,
      resource,
      resourceId,
      timestamp: Timestamp.now(),
      details,
    });
  } catch (error) {
    console.error('Error logging admin action:', error);
    throw error;
  }
};

/**
 * Get admin logs
 */
export const getAdminLogs = async (
  pageLimit: number = 100,
  resourceFilter?: string
): Promise<AdminLog[]> => {
  try {
    let q;

    if (resourceFilter) {
      try {
        q = query(
          collection(db, COLLECTIONS.ADMIN_LOGS),
          where('resource', '==', resourceFilter),
          orderBy('timestamp', 'desc'),
          limit(pageLimit)
        );
      } catch {
        q = query(
          collection(db, COLLECTIONS.ADMIN_LOGS),
          where('resource', '==', resourceFilter),
          limit(pageLimit)
        );
      }
    } else {
      try {
        q = query(
          collection(db, COLLECTIONS.ADMIN_LOGS),
          orderBy('timestamp', 'desc'),
          limit(pageLimit)
        );
      } catch {
        q = query(collection(db, COLLECTIONS.ADMIN_LOGS), limit(pageLimit));
      }
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        adminId: data.adminId || '',
        adminName: data.adminName || 'Unknown',
        action: data.action || '',
        resource: data.resource || 'user',
        resourceId: data.resourceId,
        timestamp: data.timestamp,
        ipAddress: data.ipAddress,
        details: data.details,
      } as AdminLog;
    });
  } catch (error) {
    console.error('Error getting admin logs:', error);
    // Return empty array instead of throwing
    return [];
  }
};

/**
 * Get admin logs by admin ID
 */
export const getAdminLogsByAdmin = async (adminId: string): Promise<AdminLog[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.ADMIN_LOGS),
      where('adminId', '==', adminId),
      orderBy('timestamp', 'desc'),
      limit(100)
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as AdminLog[];
  } catch (error) {
    console.error('Error getting admin logs by admin:', error);
    throw error;
  }
};

/**
 * Get logs by date range
 */
export const getLogsByDateRange = async (
  startDate: Date,
  endDate: Date
): Promise<AdminLog[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.ADMIN_LOGS),
      where('timestamp', '>=', Timestamp.fromDate(startDate)),
      where('timestamp', '<=', Timestamp.fromDate(endDate)),
      orderBy('timestamp', 'desc')
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as AdminLog[];
  } catch (error) {
    console.error('Error getting logs by date range:', error);
    throw error;
  }
};

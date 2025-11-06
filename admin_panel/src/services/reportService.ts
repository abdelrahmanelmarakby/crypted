import {
  collection,
  doc,
  addDoc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  Timestamp,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { Report } from '@/types';
import { COLLECTIONS } from '@/utils/constants';

/**
 * Get all reports with optional filters
 */
export const getReports = async (
  status?: 'pending' | 'reviewed' | 'action_taken' | 'dismissed',
  pageLimit: number = 50
): Promise<Report[]> => {
  try {
    let q;

    if (status) {
      try {
        q = query(
          collection(db, COLLECTIONS.REPORTS),
          where('status', '==', status),
          orderBy('createdAt', 'desc'),
          limit(pageLimit)
        );
      } catch {
        // If ordering fails, try without it
        q = query(
          collection(db, COLLECTIONS.REPORTS),
          where('status', '==', status),
          limit(pageLimit)
        );
      }
    } else {
      try {
        q = query(
          collection(db, COLLECTIONS.REPORTS),
          orderBy('createdAt', 'desc'),
          limit(pageLimit)
        );
      } catch {
        // If ordering fails, just get all
        q = query(collection(db, COLLECTIONS.REPORTS), limit(pageLimit));
      }
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return [];
    }

    const reports = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        reporterId: data.reporterId || '',
        reportedUserId: data.reportedUserId,
        reportedMessageId: data.reportedMessageId,
        reportedStoryId: data.reportedStoryId,
        contentType: data.contentType || 'user',
        reason: data.reason || '',
        description: data.description,
        status: data.status || 'pending',
        priority: data.priority || 'medium',
        createdAt: data.createdAt,
        reviewedAt: data.reviewedAt,
        reviewedBy: data.reviewedBy,
        action: data.action,
        notes: data.notes,
      } as Report;
    });

    return reports;
  } catch (error) {
    console.error('Error getting reports:', error);
    // Return empty array instead of throwing
    return [];
  }
};

/**
 * Get a single report by ID
 */
export const getReportById = async (reportId: string): Promise<Report | null> => {
  try {
    const reportDoc = await getDoc(doc(db, COLLECTIONS.REPORTS, reportId));

    if (!reportDoc.exists()) {
      return null;
    }

    return { id: reportDoc.id, ...reportDoc.data() } as Report;
  } catch (error) {
    console.error('Error getting report:', error);
    throw error;
  }
};

/**
 * Update report status
 */
export const updateReportStatus = async (
  reportId: string,
  status: 'pending' | 'reviewed' | 'action_taken' | 'dismissed',
  reviewedBy: string,
  action?: string,
  notes?: string
): Promise<void> => {
  try {
    const reportRef = doc(db, COLLECTIONS.REPORTS, reportId);
    await updateDoc(reportRef, {
      status,
      reviewedBy,
      reviewedAt: Timestamp.now(),
      action,
      notes,
    });
  } catch (error) {
    console.error('Error updating report status:', error);
    throw error;
  }
};

/**
 * Delete a report
 */
export const deleteReport = async (reportId: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, COLLECTIONS.REPORTS, reportId));
  } catch (error) {
    console.error('Error deleting report:', error);
    throw error;
  }
};

/**
 * Get pending reports count
 */
export const getPendingReportsCount = async (): Promise<number> => {
  try {
    const q = query(collection(db, COLLECTIONS.REPORTS), where('status', '==', 'pending'));

    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error getting pending reports count:', error);
    throw error;
  }
};

/**
 * Create a new report (for testing)
 */
export const createReport = async (reportData: Omit<Report, 'id' | 'createdAt'>): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, COLLECTIONS.REPORTS), {
      ...reportData,
      createdAt: Timestamp.now(),
    });

    return docRef.id;
  } catch (error) {
    console.error('Error creating report:', error);
    throw error;
  }
};

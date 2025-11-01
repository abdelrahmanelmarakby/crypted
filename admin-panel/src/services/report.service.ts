import {
  collection,
  doc,
  getDocs,
  updateDoc,
  deleteDoc,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
} from 'firebase/firestore';
import { db } from './firebase';
import { FIREBASE_COLLECTIONS } from '../utils/constants';

export interface Report {
  id: string;
  reporterId: string;
  reporterName?: string;
  reportedUserId?: string;
  reportedUserName?: string;
  reportedContentId?: string;
  contentType: 'user' | 'message' | 'story' | 'other';
  reason: string;
  description?: string;
  status: 'pending' | 'reviewed' | 'resolved' | 'dismissed';
  createdAt: Timestamp;
  reviewedAt?: Timestamp;
  reviewedBy?: string;
  action?: string;
}

class ReportService {
  async getReports(limitCount: number = 50): Promise<Report[]> {
    try {
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.REPORTS || 'reports'),
        orderBy('createdAt', 'desc'),
        limit(limitCount)
      );

      const snapshot = await getDocs(q);
      const reports: Report[] = [];

      snapshot.forEach((doc) => {
        reports.push({ id: doc.id, ...doc.data() } as Report);
      });

      return reports;
    } catch (error: any) {
      console.error('Error fetching reports:', error);
      throw new Error(error.message || 'Failed to fetch reports');
    }
  }

  async getPendingReports(): Promise<Report[]> {
    try {
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.REPORTS || 'reports'),
        where('status', '==', 'pending'),
        orderBy('createdAt', 'desc'),
        limit(100)
      );

      const snapshot = await getDocs(q);
      const reports: Report[] = [];

      snapshot.forEach((doc) => {
        reports.push({ id: doc.id, ...doc.data() } as Report);
      });

      return reports;
    } catch (error: any) {
      console.error('Error fetching pending reports:', error);
      throw new Error(error.message || 'Failed to fetch pending reports');
    }
  }

  async updateReportStatus(
    reportId: string,
    status: 'reviewed' | 'resolved' | 'dismissed',
    action?: string,
    reviewerId?: string
  ): Promise<void> {
    try {
      const updates: any = {
        status,
        reviewedAt: Timestamp.now(),
      };

      if (action) updates.action = action;
      if (reviewerId) updates.reviewedBy = reviewerId;

      await updateDoc(doc(db, FIREBASE_COLLECTIONS.REPORTS || 'reports', reportId), updates);
    } catch (error: any) {
      console.error('Error updating report:', error);
      throw new Error(error.message || 'Failed to update report');
    }
  }

  async deleteReport(reportId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, FIREBASE_COLLECTIONS.REPORTS || 'reports', reportId));
    } catch (error: any) {
      console.error('Error deleting report:', error);
      throw new Error(error.message || 'Failed to delete report');
    }
  }

  async getPendingCount(): Promise<number> {
    try {
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.REPORTS || 'reports'),
        where('status', '==', 'pending')
      );
      const snapshot = await getDocs(q);
      return snapshot.size;
    } catch (error: any) {
      console.error('Error getting pending count:', error);
      return 0;
    }
  }
}

export default new ReportService();

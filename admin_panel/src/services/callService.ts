import {
  collection,
  doc,
  getDocs,
  getDoc,
  query,
  where,
  orderBy,
  limit,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { Call } from '@/types';
import { COLLECTIONS } from '@/utils/constants';
/**
 * Get all calls
 */
export const getCalls = async (pageLimit: number = 100): Promise<Call[]> => {
  try {
    let q;
    try {
      q = query(
        collection(db, COLLECTIONS.CALLS),
        orderBy('startTime', 'desc'),
        limit(pageLimit)
      );
    } catch {
      // If ordering fails, just get without ordering
      q = query(collection(db, COLLECTIONS.CALLS), limit(pageLimit));
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return [];
    }

    const calls = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        callerId: data.callerId || '',
        receiverId: data.receiverId || '',
        participants: data.participants || [],
        type: data.type || 'audio',
        duration: data.duration,
        status: data.status || 'completed',
        startTime: data.startTime,
        endTime: data.endTime,
      } as Call;
    });

    return calls;
  } catch (error) {
    console.error('Error getting calls:', error);
    // Return empty array instead of throwing
    return [];
  }
};

/**
 * Get call by ID
 */
export const getCallById = async (callId: string): Promise<Call | null> => {
  try {
    const callDoc = await getDoc(doc(db, COLLECTIONS.CALLS, callId));

    if (!callDoc.exists()) {
      return null;
    }

    return { id: callDoc.id, ...callDoc.data() } as Call;
  } catch (error) {
    console.error('Error getting call:', error);
    throw error;
  }
};

/**
 * Get calls by user ID
 */
export const getCallsByUser = async (userId: string): Promise<Call[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.CALLS),
      where('participants', 'array-contains', userId),
      orderBy('startTime', 'desc'),
      limit(50)
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Call[];
  } catch (error) {
    console.error('Error getting user calls:', error);
    throw error;
  }
};

/**
 * Get call statistics
 */
export const getCallStats = async (): Promise<any> => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Get all calls
    const allCallsSnapshot = await getDocs(collection(db, COLLECTIONS.CALLS));
    const totalCalls = allCallsSnapshot.size;

    // Calls today
    const todayQuery = query(
      collection(db, COLLECTIONS.CALLS),
      where('startTime', '>=', Timestamp.fromDate(today))
    );
    const todaySnapshot = await getDocs(todayQuery);
    const callsToday = todaySnapshot.size;

    // Calculate stats
    let audioCallsCount = 0;
    let videoCallsCount = 0;
    let completedCalls = 0;
    let missedCalls = 0;
    let totalDuration = 0;

    allCallsSnapshot.docs.forEach((doc) => {
      const call = doc.data() as Call;

      if (call.type === 'audio') audioCallsCount++;
      if (call.type === 'video') videoCallsCount++;
      if (call.status === 'completed') completedCalls++;
      if (call.status === 'missed') missedCalls++;
      if (call.duration) totalDuration += call.duration;
    });

    const averageDuration = totalCalls > 0 ? Math.floor(totalDuration / totalCalls) : 0;

    return {
      totalCalls,
      callsToday,
      audioCallsCount,
      videoCallsCount,
      completedCalls,
      missedCalls,
      averageDuration,
      successRate: totalCalls > 0 ? Math.round((completedCalls / totalCalls) * 100) : 0,
    };
  } catch (error) {
    console.error('Error getting call stats:', error);
    throw error;
  }
};

/**
 * Get calls by date range
 */
export const getCallsByDateRange = async (
  startDate: Date,
  endDate: Date
): Promise<Call[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.CALLS),
      where('startTime', '>=', Timestamp.fromDate(startDate)),
      where('startTime', '<=', Timestamp.fromDate(endDate)),
      orderBy('startTime', 'desc')
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Call[];
  } catch (error) {
    console.error('Error getting calls by date range:', error);
    throw error;
  }
};

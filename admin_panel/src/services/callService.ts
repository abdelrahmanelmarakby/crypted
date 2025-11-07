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
 * Convert time field to Date
 */
const parseCallTime = (time: any): Date | undefined => {
  if (!time) return undefined;

  if (time instanceof Timestamp) {
    return time.toDate();
  }

  if (typeof time === 'number') {
    return new Date(time);
  }

  return undefined;
};

/**
 * Get all calls
 */
export const getCalls = async (pageLimit: number = 100): Promise<Call[]> => {
  try {
    let q;
    try {
      // Try ordering by time field
      q = query(
        collection(db, COLLECTIONS.CALLS),
        orderBy('time', 'desc'),
        limit(pageLimit)
      );
    } catch {
      // If ordering fails, just get without ordering
      q = query(collection(db, COLLECTIONS.CALLS), limit(pageLimit));
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      console.log('No calls found');
      return [];
    }

    const calls = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        callId: data.callId || doc.id,
        id: data.callId || doc.id,
        channelName: data.channelName,
        callerId: data.callerId || '',
        callerImage: data.callerImage,
        callerUserName: data.callerUserName,
        calleeId: data.calleeId || '',
        calleeImage: data.calleeImage,
        calleeUserName: data.calleeUserName,
        time: data.time,
        callDuration: data.callDuration,
        duration: data.callDuration, // alias
        callType: data.callType || 'audio',
        type: data.callType || 'audio', // alias
        callStatus: data.callStatus || 'ended',
        status: data.callStatus || 'ended', // alias
        startTime: parseCallTime(data.time),
      } as Call;
    });

    console.log(`Fetched ${calls.length} calls`);
    return calls;
  } catch (error) {
    console.error('Error getting calls:', error);
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

    const data = callDoc.data();
    return {
      callId: data.callId || callDoc.id,
      id: data.callId || callDoc.id,
      channelName: data.channelName,
      callerId: data.callerId || '',
      callerImage: data.callerImage,
      callerUserName: data.callerUserName,
      calleeId: data.calleeId || '',
      calleeImage: data.calleeImage,
      calleeUserName: data.calleeUserName,
      time: data.time,
      callDuration: data.callDuration,
      duration: data.callDuration,
      callType: data.callType || 'audio',
      type: data.callType || 'audio',
      callStatus: data.callStatus || 'ended',
      status: data.callStatus || 'ended',
      startTime: parseCallTime(data.time),
    } as Call;
  } catch (error) {
    console.error('Error getting call:', error);
    return null;
  }
};

/**
 * Get calls by user ID (where user is either caller or callee)
 */
export const getCallsByUser = async (userId: string): Promise<Call[]> => {
  try {
    // Get calls where user is caller
    const callerQuery = query(
      collection(db, COLLECTIONS.CALLS),
      where('callerId', '==', userId),
      limit(50)
    );

    // Get calls where user is callee
    const calleeQuery = query(
      collection(db, COLLECTIONS.CALLS),
      where('calleeId', '==', userId),
      limit(50)
    );

    const [callerSnapshot, calleeSnapshot] = await Promise.all([
      getDocs(callerQuery),
      getDocs(calleeQuery),
    ]);

    const calls = new Map<string, Call>();

    [...callerSnapshot.docs, ...calleeSnapshot.docs].forEach((doc) => {
      const data = doc.data();
      calls.set(doc.id, {
        callId: data.callId || doc.id,
        id: data.callId || doc.id,
        channelName: data.channelName,
        callerId: data.callerId || '',
        callerImage: data.callerImage,
        callerUserName: data.callerUserName,
        calleeId: data.calleeId || '',
        calleeImage: data.calleeImage,
        calleeUserName: data.calleeUserName,
        time: data.time,
        callDuration: data.callDuration,
        duration: data.callDuration,
        callType: data.callType || 'audio',
        type: data.callType || 'audio',
        callStatus: data.callStatus || 'ended',
        status: data.callStatus || 'ended',
        startTime: parseCallTime(data.time),
      } as Call);
    });

    return Array.from(calls.values());
  } catch (error) {
    console.error('Error getting user calls:', error);
    return [];
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

    // Calculate stats
    let audioCallsCount = 0;
    let videoCallsCount = 0;
    let completedCalls = 0;
    let endedCalls = 0;
    let connectedCalls = 0;
    let missedCalls = 0;
    let canceledCalls = 0;
    let totalDuration = 0;
    let callsToday = 0;

    allCallsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      const callType = data.callType || '';
      const callStatus = data.callStatus || '';
      const callTime = data.time;
      const callDuration = data.callDuration || 0;

      // Count by type
      if (callType === 'audio') audioCallsCount++;
      if (callType === 'video') videoCallsCount++;

      // Count by status
      if (callStatus === 'ended') endedCalls++;
      if (callStatus === 'connected') connectedCalls++;
      if (callStatus === 'missed') missedCalls++;
      if (callStatus === 'canceled') canceledCalls++;

      // Completed means ended with duration > 0
      if (callStatus === 'ended' && callDuration > 0) {
        completedCalls++;
        totalDuration += callDuration;
      }

      // Check if call was today
      if (callTime) {
        const callDate = parseCallTime(callTime);
        if (callDate && callDate >= today) {
          callsToday++;
        }
      }
    });

    const averageDuration = completedCalls > 0 ? Math.floor(totalDuration / completedCalls) : 0;
    const successRate = totalCalls > 0 ? Math.round((completedCalls / totalCalls) * 100) : 0;

    return {
      totalCalls,
      callsToday,
      audioCallsCount,
      videoCallsCount,
      completedCalls,
      endedCalls,
      missedCalls,
      canceledCalls,
      averageDuration,
      successRate,
    };
  } catch (error) {
    console.error('Error getting call stats:', error);
    return {
      totalCalls: 0,
      callsToday: 0,
      audioCallsCount: 0,
      videoCallsCount: 0,
      completedCalls: 0,
      endedCalls: 0,
      missedCalls: 0,
      canceledCalls: 0,
      averageDuration: 0,
      successRate: 0,
    };
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
      where('time', '>=', Timestamp.fromDate(startDate)),
      where('time', '<=', Timestamp.fromDate(endDate)),
      orderBy('time', 'desc')
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        callId: data.callId || doc.id,
        id: data.callId || doc.id,
        channelName: data.channelName,
        callerId: data.callerId || '',
        callerImage: data.callerImage,
        callerUserName: data.callerUserName,
        calleeId: data.calleeId || '',
        calleeImage: data.calleeImage,
        calleeUserName: data.calleeUserName,
        time: data.time,
        callDuration: data.callDuration,
        duration: data.callDuration,
        callType: data.callType || 'audio',
        type: data.callType || 'audio',
        callStatus: data.callStatus || 'ended',
        status: data.callStatus || 'ended',
        startTime: parseCallTime(data.time),
      } as Call;
    });
  } catch (error) {
    console.error('Error getting calls by date range:', error);
    return [];
  }
};

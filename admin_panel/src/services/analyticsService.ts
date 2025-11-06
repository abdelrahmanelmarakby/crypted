import { collection, getDocs, query, where, Timestamp } from 'firebase/firestore';
import { db } from '@/config/firebase';
import { COLLECTIONS } from '@/utils/constants';
import { DashboardStats, UserGrowthData, MessageActivityData } from '@/types';

/**
 * Get dashboard statistics
 */
export const getDashboardStats = async (): Promise<DashboardStats> => {
  try {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const last24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const last7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const last30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Get total users
    const usersSnapshot = await getDocs(collection(db, COLLECTIONS.USERS));
    const totalUsers = usersSnapshot.size;

    // Get active users
    const activeUsers24h = usersSnapshot.docs.filter((doc) => {
      const lastSeen = doc.data().lastSeen?.toDate();
      return lastSeen && lastSeen >= last24h;
    }).length;

    const activeUsers7d = usersSnapshot.docs.filter((doc) => {
      const lastSeen = doc.data().lastSeen?.toDate();
      return lastSeen && lastSeen >= last7d;
    }).length;

    const activeUsers30d = usersSnapshot.docs.filter((doc) => {
      const lastSeen = doc.data().lastSeen?.toDate();
      return lastSeen && lastSeen >= last30d;
    }).length;

    // Get chat rooms
    const chatRoomsSnapshot = await getDocs(collection(db, COLLECTIONS.CHAT_ROOMS));
    const activeChatRooms = chatRoomsSnapshot.size;

    // Get active stories (not expired)
    const storiesQuery = query(
      collection(db, COLLECTIONS.STORIES),
      where('expiresAt', '>', Timestamp.now())
    );
    const storiesSnapshot = await getDocs(storiesQuery);
    const activeStories = storiesSnapshot.size;

    // Get calls today
    const callsQuery = query(
      collection(db, COLLECTIONS.CALLS),
      where('startTime', '>=', Timestamp.fromDate(today))
    );
    const callsSnapshot = await getDocs(callsQuery);
    const callsToday = callsSnapshot.size;

    // Get total calls
    const totalCallsSnapshot = await getDocs(collection(db, COLLECTIONS.CALLS));
    const totalCalls = totalCallsSnapshot.size;

    // Get pending reports
    const reportsQuery = query(collection(db, COLLECTIONS.REPORTS), where('status', '==', 'pending'));
    const reportsSnapshot = await getDocs(reportsQuery);
    const pendingReports = reportsSnapshot.size;

    // Estimate messages (this would need a more complex query in production)
    const totalMessages = activeChatRooms * 50; // Placeholder
    const messagesToday = Math.floor(totalMessages * 0.1); // Placeholder

    return {
      totalUsers,
      activeUsers24h,
      activeUsers7d,
      activeUsers30d,
      totalMessages,
      messagesToday,
      activeChatRooms,
      activeStories,
      totalCalls,
      callsToday,
      pendingReports,
      storageUsage: 0, // Would need Cloud Functions to calculate
    };
  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    throw error;
  }
};

/**
 * Get user growth data for charts
 */
export const getUserGrowthData = async (days: number = 30): Promise<UserGrowthData[]> => {
  try {
    const usersSnapshot = await getDocs(collection(db, COLLECTIONS.USERS));

    const growthMap = new Map<string, number>();

    // Initialize dates
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      growthMap.set(dateStr, 0);
    }

    // Count users per day
    usersSnapshot.docs.forEach((doc) => {
      const createdAt = doc.data().createdAt?.toDate();
      if (createdAt) {
        const dateStr = createdAt.toISOString().split('T')[0];
        if (growthMap.has(dateStr)) {
          growthMap.set(dateStr, (growthMap.get(dateStr) || 0) + 1);
        }
      }
    });

    // Convert to array and sort
    const data: UserGrowthData[] = Array.from(growthMap.entries())
      .map(([date, users]) => ({ date, users }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return data;
  } catch (error) {
    console.error('Error getting user growth data:', error);
    throw error;
  }
};

/**
 * Get message activity data for charts
 */
export const getMessageActivityData = async (days: number = 7): Promise<MessageActivityData[]> => {
  try {
    // This is a placeholder - in production, you'd need to aggregate messages from all chat rooms
    const data: MessageActivityData[] = [];

    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];

      // Placeholder data
      data.push({
        date: dateStr,
        messages: Math.floor(Math.random() * 10000) + 5000,
      });
    }

    return data.sort((a, b) => a.date.localeCompare(b.date));
  } catch (error) {
    console.error('Error getting message activity data:', error);
    throw error;
  }
};

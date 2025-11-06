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
  deleteDoc,
  updateDoc,
} from 'firebase/firestore';
import { db } from '@/config/firebase';
import { Story } from '@/types';
import { COLLECTIONS } from '@/utils/constants';

/**
 * Get all stories with optional filters
 */
export const getStories = async (
  status?: 'active' | 'expired',
  pageLimit: number = 50
): Promise<Story[]> => {
  try {
    let q;

    if (status === 'active') {
      try {
        q = query(
          collection(db, COLLECTIONS.STORIES),
          where('expiresAt', '>', Timestamp.now()),
          orderBy('expiresAt', 'desc'),
          limit(pageLimit)
        );
      } catch {
        q = query(
          collection(db, COLLECTIONS.STORIES),
          where('expiresAt', '>', Timestamp.now()),
          limit(pageLimit)
        );
      }
    } else if (status === 'expired') {
      try {
        q = query(
          collection(db, COLLECTIONS.STORIES),
          where('expiresAt', '<=', Timestamp.now()),
          orderBy('expiresAt', 'desc'),
          limit(pageLimit)
        );
      } catch {
        q = query(
          collection(db, COLLECTIONS.STORIES),
          where('expiresAt', '<=', Timestamp.now()),
          limit(pageLimit)
        );
      }
    } else {
      try {
        q = query(collection(db, COLLECTIONS.STORIES), orderBy('createdAt', 'desc'), limit(pageLimit));
      } catch {
        q = query(collection(db, COLLECTIONS.STORIES), limit(pageLimit));
      }
    }

    const snapshot = await getDocs(q);

    if (snapshot.empty) {
      return [];
    }

    const stories = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        uid: data.uid || '',
        user: data.user || { full_name: 'Unknown', image_url: '' },
        storyFileUrl: data.storyFileUrl,
        storyText: data.storyText,
        createdAt: data.createdAt,
        expiresAt: data.expiresAt,
        storyType: data.storyType || 'text',
        status: data.status || 'active',
        viewedBy: data.viewedBy || [],
        duration: data.duration,
      } as Story;
    });

    return stories;
  } catch (error) {
    console.error('Error getting stories:', error);
    // Return empty array instead of throwing
    return [];
  }
};

/**
 * Get a single story by ID
 */
export const getStoryById = async (storyId: string): Promise<Story | null> => {
  try {
    const storyDoc = await getDoc(doc(db, COLLECTIONS.STORIES, storyId));

    if (!storyDoc.exists()) {
      return null;
    }

    return { id: storyDoc.id, ...storyDoc.data() } as Story;
  } catch (error) {
    console.error('Error getting story:', error);
    throw error;
  }
};

/**
 * Get stories by user
 */
export const getStoriesByUser = async (userId: string): Promise<Story[]> => {
  try {
    const q = query(
      collection(db, COLLECTIONS.STORIES),
      where('uid', '==', userId),
      orderBy('createdAt', 'desc')
    );

    const snapshot = await getDocs(q);

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Story[];
  } catch (error) {
    console.error('Error getting stories by user:', error);
    throw error;
  }
};

/**
 * Delete a story
 */
export const deleteStory = async (storyId: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, COLLECTIONS.STORIES, storyId));
  } catch (error) {
    console.error('Error deleting story:', error);
    throw error;
  }
};

/**
 * Update story status
 */
export const updateStoryStatus = async (
  storyId: string,
  status: 'active' | 'expired' | 'deleted'
): Promise<void> => {
  try {
    const storyRef = doc(db, COLLECTIONS.STORIES, storyId);
    await updateDoc(storyRef, {
      status,
      updatedAt: Timestamp.now(),
    });
  } catch (error) {
    console.error('Error updating story status:', error);
    throw error;
  }
};

/**
 * Get active stories count
 */
export const getActiveStoriesCount = async (): Promise<number> => {
  try {
    const q = query(collection(db, COLLECTIONS.STORIES), where('expiresAt', '>', Timestamp.now()));

    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error('Error getting active stories count:', error);
    throw error;
  }
};

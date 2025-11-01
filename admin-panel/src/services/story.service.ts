import {
  collection,
  doc,
  getDocs,
  deleteDoc,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
} from 'firebase/firestore';
import { db } from './firebase';
import { FIREBASE_COLLECTIONS } from '../utils/constants';

export interface Story {
  id: string;
  userId: string;
  userName?: string;
  userAvatar?: string;
  type: 'image' | 'video' | 'text';
  mediaUrl?: string;
  textContent?: string;
  backgroundColor?: string;
  createdAt: Timestamp;
  expiresAt: Timestamp;
  viewedBy: string[];
  viewCount: number;
}

class StoryService {
  async getStories(limitCount: number = 50): Promise<Story[]> {
    try {
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.STORIES),
        orderBy('createdAt', 'desc'),
        limit(limitCount)
      );

      const snapshot = await getDocs(q);
      const stories: Story[] = [];

      snapshot.forEach((doc) => {
        stories.push({ id: doc.id, ...doc.data() } as Story);
      });

      return stories;
    } catch (error: any) {
      console.error('Error fetching stories:', error);
      throw new Error(error.message || 'Failed to fetch stories');
    }
  }

  async getActiveStories(): Promise<Story[]> {
    try {
      const now = Timestamp.now();
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.STORIES),
        where('expiresAt', '>', now),
        orderBy('expiresAt', 'desc'),
        limit(100)
      );

      const snapshot = await getDocs(q);
      const stories: Story[] = [];

      snapshot.forEach((doc) => {
        stories.push({ id: doc.id, ...doc.data() } as Story);
      });

      return stories;
    } catch (error: any) {
      console.error('Error fetching active stories:', error);
      throw new Error(error.message || 'Failed to fetch active stories');
    }
  }

  async deleteStory(storyId: string): Promise<void> {
    try {
      await deleteDoc(doc(db, FIREBASE_COLLECTIONS.STORIES, storyId));
    } catch (error: any) {
      console.error('Error deleting story:', error);
      throw new Error(error.message || 'Failed to delete story');
    }
  }

  async getStoryCount(): Promise<number> {
    try {
      const snapshot = await getDocs(collection(db, FIREBASE_COLLECTIONS.STORIES));
      return snapshot.size;
    } catch (error: any) {
      console.error('Error getting story count:', error);
      return 0;
    }
  }

  async getActiveStoryCount(): Promise<number> {
    try {
      const now = Timestamp.now();
      const q = query(
        collection(db, FIREBASE_COLLECTIONS.STORIES),
        where('expiresAt', '>', now)
      );
      const snapshot = await getDocs(q);
      return snapshot.size;
    } catch (error: any) {
      console.error('Error getting active story count:', error);
      return 0;
    }
  }
}

export default new StoryService();

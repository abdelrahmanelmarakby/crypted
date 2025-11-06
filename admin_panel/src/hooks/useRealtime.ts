import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, QueryConstraint } from 'firebase/firestore';
import { db } from '@/config/firebase';

/**
 * Hook for real-time data updates from Firestore
 */
export const useRealtimeCollection = <T>(
  collectionName: string,
  constraints: QueryConstraint[] = []
) => {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);

    try {
      const q = query(collection(db, collectionName), ...constraints);

      const unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const items = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
          })) as T[];

          setData(items);
          setLoading(false);
          setError(null);
        },
        (err) => {
          console.error(`Error listening to ${collectionName}:`, err);
          setError(err as Error);
          setLoading(false);
        }
      );

      return () => unsubscribe();
    } catch (err) {
      console.error(`Error setting up listener for ${collectionName}:`, err);
      setError(err as Error);
      setLoading(false);
    }
  }, [collectionName, constraints]);

  return { data, loading, error };
};

/**
 * Hook for real-time stats that refresh every interval
 */
export const useRealtimeStats = <T>(
  fetchFunction: () => Promise<T>,
  intervalMs: number = 30000 // Default: 30 seconds
) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const result = await fetchFunction();
        setData(result);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching realtime stats:', error);
        setLoading(false);
      }
    };

    // Initial fetch
    fetchData();

    // Set up interval for updates
    const interval = setInterval(fetchData, intervalMs);

    return () => clearInterval(interval);
  }, [fetchFunction, intervalMs]);

  return { data, loading };
};

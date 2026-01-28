/**
 * Multi-Layer Cache Service for Admin Panel Analytics
 *
 * Implements a 3-tier caching strategy:
 * 1. Memory Cache - Fastest, session-only, limited capacity
 * 2. localStorage - Persistent across sessions, ~5-10MB limit
 * 3. IndexedDB - Large datasets, persistent, practically unlimited
 *
 * Cache Hierarchy:
 * - Memory: Hot data, frequently accessed (< 1MB per item)
 * - localStorage: Warm data, moderate size (< 5MB per item)
 * - IndexedDB: Cold data, large datasets (> 5MB per item)
 */

// TTL Configuration (in milliseconds)
export const CACHE_TTL = {
  DASHBOARD_STATS: 5 * 60 * 1000, // 5 minutes
  RETENTION_DATA: 24 * 60 * 60 * 1000, // 24 hours
  TIME_SERIES: 15 * 60 * 1000, // 15 minutes
  USER_BEHAVIOR: 30 * 60 * 1000, // 30 minutes
  EVENT_ANALYTICS: 10 * 60 * 1000, // 10 minutes
  GEO_ANALYTICS: 60 * 60 * 1000, // 1 hour
  REAL_TIME_METRICS: 1 * 60 * 1000, // 1 minute
} as const;

// Cache entry interface
interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
  size?: number; // Size in bytes (approximate)
}

// IndexedDB configuration
const DB_NAME = 'crypted_admin_cache';
const DB_VERSION = 1;
const STORE_NAME = 'analytics_cache';

// Memory cache size limits
const MAX_MEMORY_CACHE_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_LOCALSTORAGE_SIZE = 5 * 1024 * 1024; // 5MB per item

class CacheService {
  private memoryCache: Map<string, CacheEntry<any>> = new Map();
  private memoryCacheSize = 0;
  private db: IDBDatabase | null = null;
  private dbInitPromise: Promise<void> | null = null;

  constructor() {
    this.dbInitPromise = this.initIndexedDB();
  }

  /**
   * Initialize IndexedDB
   */
  private async initIndexedDB(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!window.indexedDB) {
        console.warn('IndexedDB not supported, falling back to localStorage only');
        resolve();
        return;
      }

      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error('IndexedDB failed to open:', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        console.log('✅ IndexedDB initialized');
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Create object store if it doesn't exist
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME);
        }
      };
    });
  }

  /**
   * Get data from cache (checks all layers)
   */
  async get<T>(key: string): Promise<T | null> {
    // Check memory cache first
    const memoryEntry = this.memoryCache.get(key);
    if (memoryEntry && this.isValid(memoryEntry)) {
      console.log(`🟢 Cache HIT (memory): ${key}`);
      return memoryEntry.data as T;
    }

    // Check localStorage
    try {
      const localStorageData = localStorage.getItem(this.getStorageKey(key));
      if (localStorageData) {
        const entry: CacheEntry<T> = JSON.parse(localStorageData);
        if (this.isValid(entry)) {
          console.log(`🟡 Cache HIT (localStorage): ${key}`);
          // Promote to memory cache
          this.setMemoryCache(key, entry.data, entry.ttl);
          return entry.data;
        } else {
          localStorage.removeItem(this.getStorageKey(key));
        }
      }
    } catch (error) {
      console.error('localStorage read error:', error);
    }

    // Check IndexedDB
    const idbData = await this.getFromIndexedDB<T>(key);
    if (idbData) {
      console.log(`🔵 Cache HIT (IndexedDB): ${key}`);
      // Promote to localStorage and memory cache
      try {
        const entry: CacheEntry<T> = {
          data: idbData.data,
          timestamp: idbData.timestamp,
          ttl: idbData.ttl,
        };
        this.setLocalStorage(key, entry);
        this.setMemoryCache(key, idbData.data, idbData.ttl);
      } catch (error) {
        console.warn('Failed to promote from IndexedDB:', error);
      }
      return idbData.data;
    }

    console.log(`🔴 Cache MISS: ${key}`);
    return null;
  }

  /**
   * Set data in cache (auto-selects appropriate layer)
   */
  async set<T>(key: string, data: T, ttl: number = CACHE_TTL.DASHBOARD_STATS): Promise<void> {
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      ttl,
      size: this.estimateSize(data),
    };

    // Choose storage layer based on data size
    const size = entry.size || 0;

    if (size < 1024 * 1024) {
      // < 1MB: Use memory cache
      this.setMemoryCache(key, data, ttl);
    } else if (size < 5 * 1024 * 1024) {
      // 1-5MB: Use localStorage + memory cache
      this.setMemoryCache(key, data, ttl);
      this.setLocalStorage(key, entry);
    } else {
      // > 5MB: Use IndexedDB only
      await this.setIndexedDB(key, entry);
    }
  }

  /**
   * Set data in memory cache
   */
  private setMemoryCache<T>(key: string, data: T, ttl: number): void {
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      ttl,
      size: this.estimateSize(data),
    };

    // Check if we need to evict old entries
    const entrySize = entry.size || 0;
    if (this.memoryCacheSize + entrySize > MAX_MEMORY_CACHE_SIZE) {
      this.evictMemoryCache(entrySize);
    }

    this.memoryCache.set(key, entry);
    this.memoryCacheSize += entrySize;
  }

  /**
   * Set data in localStorage
   */
  private setLocalStorage<T>(key: string, entry: CacheEntry<T>): void {
    try {
      const storageKey = this.getStorageKey(key);
      const serialized = JSON.stringify(entry);

      if (serialized.length > MAX_LOCALSTORAGE_SIZE) {
        console.warn(`Data too large for localStorage: ${key} (${serialized.length} bytes)`);
        return;
      }

      localStorage.setItem(storageKey, serialized);
    } catch (error: any) {
      // Handle quota exceeded error
      if (error.name === 'QuotaExceededError') {
        console.warn('localStorage quota exceeded, clearing old entries');
        this.clearExpiredLocalStorage();
        try {
          localStorage.setItem(this.getStorageKey(key), JSON.stringify(entry));
        } catch (retryError) {
          console.error('Failed to save to localStorage after clearing:', retryError);
        }
      } else {
        console.error('localStorage write error:', error);
      }
    }
  }

  /**
   * Set data in IndexedDB
   */
  private async setIndexedDB<T>(key: string, entry: CacheEntry<T>): Promise<void> {
    await this.dbInitPromise;

    if (!this.db) {
      console.warn('IndexedDB not available');
      return;
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(entry, key);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get data from IndexedDB
   */
  private async getFromIndexedDB<T>(key: string): Promise<CacheEntry<T> | null> {
    await this.dbInitPromise;

    if (!this.db) {
      return null;
    }

    return new Promise((resolve) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get(key);

      request.onsuccess = () => {
        const entry = request.result as CacheEntry<T> | undefined;
        if (entry && this.isValid(entry)) {
          resolve(entry);
        } else {
          if (entry) {
            // Delete expired entry
            this.deleteFromIndexedDB(key);
          }
          resolve(null);
        }
      };

      request.onerror = () => {
        console.error('IndexedDB read error:', request.error);
        resolve(null);
      };
    });
  }

  /**
   * Delete from IndexedDB
   */
  private async deleteFromIndexedDB(key: string): Promise<void> {
    if (!this.db) return;

    return new Promise((resolve) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.delete(key);

      request.onsuccess = () => resolve();
      request.onerror = () => resolve(); // Ignore errors
    });
  }

  /**
   * Check if cache entry is still valid
   */
  private isValid<T>(entry: CacheEntry<T>): boolean {
    const now = Date.now();
    return now - entry.timestamp < entry.ttl;
  }

  /**
   * Estimate size of data in bytes
   */
  private estimateSize(data: any): number {
    try {
      return new Blob([JSON.stringify(data)]).size;
    } catch {
      // Fallback estimation
      return JSON.stringify(data).length * 2; // Rough estimate (UTF-16)
    }
  }

  /**
   * Evict old entries from memory cache
   */
  private evictMemoryCache(requiredSpace: number): void {
    // Sort entries by timestamp (oldest first)
    const entries = Array.from(this.memoryCache.entries())
      .sort((a, b) => a[1].timestamp - b[1].timestamp);

    let freedSpace = 0;

    for (const [key, entry] of entries) {
      if (this.memoryCacheSize - freedSpace + requiredSpace <= MAX_MEMORY_CACHE_SIZE) {
        break;
      }

      this.memoryCache.delete(key);
      freedSpace += entry.size || 0;
    }

    this.memoryCacheSize -= freedSpace;
    console.log(`🗑️ Evicted ${freedSpace} bytes from memory cache`);
  }

  /**
   * Clear expired entries from localStorage
   */
  private clearExpiredLocalStorage(): void {
    const prefix = 'crypted_cache_';
    const keysToDelete: string[] = [];

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(prefix)) {
        try {
          const entry: CacheEntry<any> = JSON.parse(localStorage.getItem(key)!);
          if (!this.isValid(entry)) {
            keysToDelete.push(key);
          }
        } catch {
          keysToDelete.push(key);
        }
      }
    }

    keysToDelete.forEach((key) => localStorage.removeItem(key));
    console.log(`🗑️ Cleared ${keysToDelete.length} expired localStorage entries`);
  }

  /**
   * Invalidate cache by pattern
   */
  async invalidate(pattern: string | RegExp): Promise<void> {
    const regex = typeof pattern === 'string' ? new RegExp(pattern) : pattern;

    // Clear from memory cache
    const keysToDelete: string[] = [];
    this.memoryCache.forEach((entry, key) => {
      if (regex.test(key)) {
        this.memoryCacheSize -= entry?.size || 0;
        keysToDelete.push(key);
      }
    });
    keysToDelete.forEach((key) => this.memoryCache.delete(key));

    // Clear from localStorage
    const prefix = 'crypted_cache_';
    const localStorageKeysToDelete: string[] = [];

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(prefix)) {
        const originalKey = key.substring(prefix.length);
        if (regex.test(originalKey)) {
          localStorageKeysToDelete.push(key);
        }
      }
    }

    localStorageKeysToDelete.forEach((key) => localStorage.removeItem(key));

    // Clear from IndexedDB
    await this.dbInitPromise;
    if (this.db) {
      const transaction = this.db.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.getAllKeys();

      request.onsuccess = async () => {
        const keys = request.result as string[];
        const idbKeysToDelete = keys.filter((key) => regex.test(key));

        for (let i = 0; i < idbKeysToDelete.length; i++) {
          await this.deleteFromIndexedDB(idbKeysToDelete[i]);
        }
      };
    }

    console.log(`🗑️ Invalidated cache pattern: ${pattern}`);
  }

  /**
   * Clear all caches
   */
  async clearAll(): Promise<void> {
    // Clear memory cache
    this.memoryCache.clear();
    this.memoryCacheSize = 0;

    // Clear localStorage
    const prefix = 'crypted_cache_';
    const keysToDelete: string[] = [];

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(prefix)) {
        keysToDelete.push(key);
      }
    }

    keysToDelete.forEach((key) => localStorage.removeItem(key));

    // Clear IndexedDB
    await this.dbInitPromise;
    if (this.db) {
      const transaction = this.db.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      store.clear();
    }

    console.log('🗑️ Cleared all caches');
  }

  /**
   * Get cache statistics
   */
  async getStats(): Promise<{
    memoryEntries: number;
    memorySize: number;
    localStorageEntries: number;
    indexedDBEntries: number;
  }> {
    // Count localStorage entries
    const prefix = 'crypted_cache_';
    let localStorageEntries = 0;

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(prefix)) {
        localStorageEntries++;
      }
    }

    // Count IndexedDB entries
    let indexedDBEntries = 0;
    await this.dbInitPromise;
    if (this.db) {
      try {
        const transaction = this.db.transaction([STORE_NAME], 'readonly');
        const store = transaction.objectStore(STORE_NAME);
        const request = store.count();
        indexedDBEntries = await new Promise((resolve) => {
          request.onsuccess = () => resolve(request.result);
          request.onerror = () => resolve(0);
        });
      } catch {
        indexedDBEntries = 0;
      }
    }

    return {
      memoryEntries: this.memoryCache.size,
      memorySize: this.memoryCacheSize,
      localStorageEntries,
      indexedDBEntries,
    };
  }

  /**
   * Get storage key for localStorage
   */
  private getStorageKey(key: string): string {
    return `crypted_cache_${key}`;
  }
}

// Export singleton instance
export const cacheService = new CacheService();
export default cacheService;

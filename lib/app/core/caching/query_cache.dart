// PERF-002 FIX: Query Caching Service
// Caches Firebase queries to reduce redundant reads

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Cache entry with TTL
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.ttl,
  }) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  /// Time remaining before expiry
  Duration get timeRemaining {
    final elapsed = DateTime.now().difference(createdAt);
    final remaining = ttl - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// In-memory cache for query results
class QueryCache {
  static final QueryCache _instance = QueryCache._internal();
  factory QueryCache() => _instance;
  QueryCache._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Map<String, List<String>> _tagIndex = {};

  // Default TTLs for different data types
  static const Duration chatRoomTtl = Duration(minutes: 5);
  static const Duration userProfileTtl = Duration(minutes: 10);
  static const Duration membersTtl = Duration(minutes: 5);
  static const Duration messageTtl = Duration(seconds: 30);

  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  /// Set cached value
  void set<T>(String key, T value, {Duration? ttl, List<String>? tags}) {
    _cache[key] = CacheEntry(
      data: value,
      ttl: ttl ?? const Duration(minutes: 5),
    );

    // Index by tags for group invalidation
    if (tags != null) {
      for (final tag in tags) {
        _tagIndex.putIfAbsent(tag, () => []).add(key);
      }
    }
  }

  /// Get or fetch value
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
    List<String>? tags,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) {
        if (kDebugMode) {
          print('[QueryCache] Cache hit: $key');
        }
        return cached;
      }
    }

    if (kDebugMode) {
      print('[QueryCache] Cache miss: $key - fetching...');
    }

    final value = await fetcher();
    set(key, value, ttl: ttl, tags: tags);
    return value;
  }

  /// Invalidate by key
  void invalidate(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      print('[QueryCache] Invalidated: $key');
    }
  }

  /// Invalidate by tag
  void invalidateByTag(String tag) {
    final keys = _tagIndex[tag];
    if (keys != null) {
      for (final key in keys) {
        _cache.remove(key);
      }
      _tagIndex.remove(tag);
      if (kDebugMode) {
        print('[QueryCache] Invalidated ${keys.length} entries with tag: $tag');
      }
    }
  }

  /// Invalidate by prefix
  void invalidateByPrefix(String prefix) {
    final keysToRemove = _cache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    if (kDebugMode) {
      print('[QueryCache] Invalidated ${keysToRemove.length} entries with prefix: $prefix');
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _tagIndex.clear();
    if (kDebugMode) {
      print('[QueryCache] Cache cleared');
    }
  }

  /// Remove expired entries
  void cleanup() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      print('[QueryCache] Cleaned up ${expiredKeys.length} expired entries');
    }
  }

  /// Get cache stats
  CacheStats get stats => CacheStats(
        totalEntries: _cache.length,
        expiredEntries: _cache.values.where((e) => e.isExpired).length,
        tags: _tagIndex.keys.toList(),
      );
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final List<String> tags;

  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.tags,
  });

  int get validEntries => totalEntries - expiredEntries;

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, expired: $expiredEntries, tags: ${tags.length})';
  }
}

/// Cached chat room service
class CachedChatRoomService {
  final QueryCache _cache = QueryCache();

  /// Cache keys
  String _roomKey(String roomId) => 'room:$roomId';
  String _userKey(String oderId) => 'user:$oderId';

  /// Get or fetch chat room
  Future<Map<String, dynamic>?> getChatRoom(
    String roomId,
    Future<Map<String, dynamic>?> Function() fetcher,
  ) {
    return _cache.getOrFetch(
      _roomKey(roomId),
      fetcher,
      ttl: QueryCache.chatRoomTtl,
      tags: ['rooms', 'room:$roomId'],
    );
  }

  /// Get or fetch user profile
  Future<Map<String, dynamic>?> getUserProfile(
    String userId,
    Future<Map<String, dynamic>?> Function() fetcher,
  ) {
    return _cache.getOrFetch(
      _userKey(userId),
      fetcher,
      ttl: QueryCache.userProfileTtl,
      tags: ['users'],
    );
  }

  /// Batch get user profiles
  Future<Map<String, Map<String, dynamic>>> batchGetUserProfiles(
    List<String> userIds,
    Future<Map<String, dynamic>?> Function(String oderId) fetcher,
  ) async {
    final results = <String, Map<String, dynamic>>{};
    final idsToFetch = <String>[];

    // Check cache first
    for (final userId in userIds) {
      final cached = _cache.get<Map<String, dynamic>>(_userKey(userId));
      if (cached != null) {
        results[userId] = cached;
      } else {
        idsToFetch.add(userId);
      }
    }

    // Fetch missing users in parallel
    if (idsToFetch.isNotEmpty) {
      final futures = idsToFetch.map((id) async {
        final data = await fetcher(id);
        if (data != null) {
          _cache.set(_userKey(id), data, ttl: QueryCache.userProfileTtl, tags: ['users']);
          return MapEntry(id, data);
        }
        return null;
      });

      final fetched = await Future.wait(futures);
      for (final entry in fetched) {
        if (entry != null) {
          results[entry.key] = entry.value;
        }
      }
    }

    if (kDebugMode) {
      print('[CachedChatRoom] Batch get: ${userIds.length} requested, '
          '${userIds.length - idsToFetch.length} cached, ${idsToFetch.length} fetched');
    }

    return results;
  }

  /// Invalidate room cache
  void invalidateRoom(String roomId) {
    _cache.invalidateByTag('room:$roomId');
  }

  /// Invalidate user cache
  void invalidateUser(String userId) {
    _cache.invalidate(_userKey(userId));
  }

  /// Invalidate all rooms
  void invalidateAllRooms() {
    _cache.invalidateByTag('rooms');
  }
}

/// Mixin for controllers to use caching
mixin CachedQueriesMixin {
  final _queryCache = QueryCache();
  final _chatRoomCache = CachedChatRoomService();

  /// Get cached value or fetch
  Future<T> cachedQuery<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    return _queryCache.getOrFetch(key, fetcher, ttl: ttl, forceRefresh: forceRefresh);
  }

  /// Invalidate cache by key
  void invalidateCache(String key) {
    _queryCache.invalidate(key);
  }

  /// Invalidate cache by prefix
  void invalidateCachePrefix(String prefix) {
    _queryCache.invalidateByPrefix(prefix);
  }

  /// Get chat room cache service
  CachedChatRoomService get chatRoomCache => _chatRoomCache;
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// Cache for user profiles with batch loading capability
/// Prevents N+1 queries when loading multiple user profiles (e.g., reactions)
class UserProfileCache {
  final Map<String, _CachedProfile> _cache = {};
  final FirebaseFirestore _firestore;

  /// TTL for cached profiles (5 minutes)
  static const Duration cacheTtl = Duration(minutes: 5);

  /// Maximum batch size for Firestore whereIn queries (Firestore limit is 30)
  static const int maxBatchSize = 30;

  UserProfileCache({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get a single user profile (cache-aware)
  Future<SocialMediaUser?> getProfile(String userId) async {
    // Check cache first
    final cached = _cache[userId];
    if (cached != null && !cached.isExpired) {
      return cached.user;
    }

    // Fetch from Firestore
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final user = SocialMediaUser.fromMap(doc.data()!);
      _cache[userId] = _CachedProfile(user);
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Batch load user profiles (cache-aware)
  /// This is the KEY performance optimization
  ///
  /// For 10 user IDs:
  /// - Old approach: 10 individual queries
  /// - New approach: Check cache, fetch only missing in 1 query
  Future<Map<String, SocialMediaUser>> batchGetProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final results = <String, SocialMediaUser>{};
    final idsToFetch = <String>[];

    // 1. Check cache first
    for (final id in userIds) {
      final cached = _cache[id];
      if (cached != null && !cached.isExpired) {
        results[id] = cached.user;
      } else {
        idsToFetch.add(id);
      }
    }

    if (kDebugMode && idsToFetch.isNotEmpty) {
      print('📦 Cache hit: ${results.length}, fetching: ${idsToFetch.length}');
    }

    // 2. Batch fetch missing from Firebase
    if (idsToFetch.isNotEmpty) {
      // Split into batches of maxBatchSize (Firestore limit)
      for (var i = 0; i < idsToFetch.length; i += maxBatchSize) {
        final batch = idsToFetch.skip(i).take(maxBatchSize).toList();

        try {
          final snapshot = await _firestore
              .collection(FirebaseCollections.users)
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in snapshot.docs) {
            final user = SocialMediaUser.fromMap(doc.data());
            _cache[doc.id] = _CachedProfile(user);
            results[doc.id] = user;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error batch fetching users: $e');
          }
        }
      }
    }

    return results;
  }

  /// Preload profiles for a list of user IDs (fire and forget)
  void preloadProfiles(List<String> userIds) {
    batchGetProfiles(userIds);
  }

  /// Invalidate a specific user's cache
  void invalidate(String userId) {
    _cache.remove(userId);
  }

  /// Clear all cached profiles
  void clear() {
    _cache.clear();
  }

  /// Remove expired entries
  void cleanup() {
    _cache.removeWhere((_, cached) => cached.isExpired);
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
        size: _cache.length,
        validCount: _cache.values.where((c) => !c.isExpired).length,
        expiredCount: _cache.values.where((c) => c.isExpired).length,
      );
}

/// Internal class for cached profile with expiration
class _CachedProfile {
  final SocialMediaUser user;
  final DateTime cachedAt;

  _CachedProfile(this.user) : cachedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > UserProfileCache.cacheTtl;
}

/// Cache statistics for monitoring
class CacheStats {
  final int size;
  final int validCount;
  final int expiredCount;

  const CacheStats({
    required this.size,
    required this.validCount,
    required this.expiredCount,
  });

  double get hitRate => size > 0 ? validCount / size : 0;

  @override
  String toString() =>
      'CacheStats(size: $size, valid: $validCount, expired: $expiredCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}

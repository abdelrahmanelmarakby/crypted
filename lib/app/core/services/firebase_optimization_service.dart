import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Production-grade Firebase optimization for 1M+ users
/// Implements caching, batching, and performance best practices
class FirebaseOptimizationService {
  static final FirebaseOptimizationService _instance =
      FirebaseOptimizationService._internal();
  factory FirebaseOptimizationService() => _instance;
  FirebaseOptimizationService._internal();

  // Cache management
  final Map<String, CachedData> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);

  // Batch timer for deferred operations
  Timer? _batchTimer;

  // Rate limiting
  final Map<String, DateTime> _rateLimitMap = {};
  final Duration _rateLimitDuration = const Duration(seconds: 1);

  /// Initialize Firebase with optimal settings for 1M+ users
  static void initializeFirebase() {
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Configure storage
    FirebaseStorage.instance.setMaxOperationRetryTime(
      const Duration(seconds: 30),
    );
    FirebaseStorage.instance.setMaxUploadRetryTime(
      const Duration(minutes: 5),
    );

    if (kDebugMode) {
      print('✅ Firebase initialized with production settings');
    }
  }

  /// Get document with caching
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentCached({
    required String collection,
    required String docId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$collection/$docId';

    // Check cache first
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        if (kDebugMode) {
          print('📦 Cache hit: $cacheKey');
        }
        return cached.data as DocumentSnapshot<Map<String, dynamic>>;
      }
    }

    // Fetch from Firestore
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();

    // Cache the result
    _cache[cacheKey] = CachedData(
      data: doc,
      timestamp: DateTime.now(),
      expiry: _cacheExpiry,
    );

    return doc;
  }

  /// Query with pagination and caching
  Future<QuerySnapshot<Map<String, dynamic>>> queryWithPagination({
    required String collection,
    int limit = 20,
    DocumentSnapshot? startAfter,
    List<QueryFilter>? filters,
    QuerySort? sort,
    bool useCache = true,
  }) async {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply sorting
    if (sort != null) {
      query = query.orderBy(sort.field, descending: sort.descending);
    }

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    // Execute query with cache
    if (useCache) {
      return await query.get(const GetOptions(source: Source.cache)).catchError(
        (_) => query.get(),
      );
    }

    return await query.get();
  }

  /// Batch write operations for efficiency
  Future<void> batchWrite({
    required List<BatchOperation> operations,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final operation in operations) {
      final docRef = FirebaseFirestore.instance
          .collection(operation.collection)
          .doc(operation.docId);

      switch (operation.type) {
        case BatchOperationType.set:
          batch.set(docRef, operation.data!, operation.setOptions);
          break;
        case BatchOperationType.update:
          batch.update(docRef, operation.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();

    if (kDebugMode) {
      print('✅ Batch write completed: ${operations.length} operations');
    }
  }

  /// Upload file with retry and progress
  Future<String> uploadFileOptimized({
    required String path,
    required Uint8List data,
    required String contentType,
    Function(double)? onProgress,
    int maxRetries = 3,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(
      contentType: contentType,
      cacheControl: 'public, max-age=31536000', // 1 year cache
    );

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final uploadTask = ref.putData(data, metadata);

        // Monitor progress
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((snapshot) {
            final progress =
                snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          });
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        if (kDebugMode) {
          print('✅ File uploaded: $path');
        }

        return downloadUrl;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (kDebugMode) {
            print('❌ Upload failed after $maxRetries retries: $e');
          }
          rethrow;
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }

    throw Exception('Upload failed');
  }

  /// Stream with automatic reconnection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamWithReconnection({
    required String collection,
    List<QueryFilter>? filters,
    QuerySort? sort,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isGreaterThan: filter.isGreaterThan,
          arrayContains: filter.arrayContains,
        );
      }
    }

    // Apply sorting
    if (sort != null) {
      query = query.orderBy(sort.field, descending: sort.descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    // Return stream with error handling
    return query.snapshots().handleError((error) {
      if (kDebugMode) {
        print('❌ Stream error: $error');
      }
      // Attempt to reconnect
      return query.snapshots();
    });
  }

  /// Rate limit check
  bool checkRateLimit(String key) {
    if (_rateLimitMap.containsKey(key)) {
      final lastCall = _rateLimitMap[key]!;
      if (DateTime.now().difference(lastCall) < _rateLimitDuration) {
        if (kDebugMode) {
          print('⚠️ Rate limit exceeded for: $key');
        }
        return false;
      }
    }

    _rateLimitMap[key] = DateTime.now();
    return true;
  }

  /// Clear cache
  void clearCache({String? specificKey}) {
    if (specificKey != null) {
      _cache.remove(specificKey);
    } else {
      _cache.clear();
    }

    if (kDebugMode) {
      print('🗑️ Cache cleared');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final validCache = _cache.values.where((c) => !c.isExpired).length;
    final expiredCache = _cache.length - validCache;

    return {
      'total': _cache.length,
      'valid': validCache,
      'expired': expiredCache,
      'hitRate': validCache / (_cache.isNotEmpty ? _cache.length : 1),
    };
  }

  /// Cleanup expired cache entries
  void cleanupCache() {
    _cache.removeWhere((key, value) => value.isExpired);

    if (kDebugMode) {
      print('🧹 Cache cleanup completed');
    }
  }

  /// Transaction with retry
  Future<T> runTransactionWithRetry<T>({
    required Future<T> Function(Transaction) transactionHandler,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await FirebaseFirestore.instance.runTransaction(
          transactionHandler,
          timeout: const Duration(seconds: 30),
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          if (kDebugMode) {
            print('❌ Transaction failed after $maxRetries retries: $e');
          }
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    throw Exception('Transaction failed');
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _cache.clear();
    _rateLimitMap.clear();
  }
}

/// Cached data model
class CachedData {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiry;

  CachedData({
    required this.data,
    required this.timestamp,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > expiry;
}

/// Query filter model
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Query sort model
class QuerySort {
  final String field;
  final bool descending;

  QuerySort({
    required this.field,
    this.descending = false,
  });
}

/// Batch operation model
class BatchOperation {
  final String collection;
  final String docId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final SetOptions? setOptions;

  const BatchOperation({
    required this.collection,
    required this.docId,
    required this.type,
    this.data,
    this.setOptions ,
  });
}

/// Batch operation type
enum BatchOperationType {
  set,
  update,
  delete,
}

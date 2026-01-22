/// Transaction helper for atomic Firestore operations
///
/// Provides utilities for performing atomic updates across multiple
/// documents with rollback support and optimistic locking.

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';

/// Result of a transaction operation
class TransactionResult<T> {
  final bool success;
  final T? value;
  final String? errorMessage;
  final TransactionErrorType? errorType;

  const TransactionResult._({
    required this.success,
    this.value,
    this.errorMessage,
    this.errorType,
  });

  factory TransactionResult.success(T value) {
    return TransactionResult._(
      success: true,
      value: value,
    );
  }

  factory TransactionResult.failure(String message, {TransactionErrorType? type}) {
    return TransactionResult._(
      success: false,
      errorMessage: message,
      errorType: type ?? TransactionErrorType.unknown,
    );
  }
}

/// Types of transaction errors
enum TransactionErrorType {
  /// Data was modified by another transaction
  concurrentModification,

  /// Document doesn't exist
  notFound,

  /// Permission denied
  permissionDenied,

  /// Network error
  networkError,

  /// Validation failed
  validationFailed,

  /// Unknown error
  unknown,
}

/// Atomic operations builder for settings
class SettingsTransactionHelper {
  final FirebaseFirestore _firestore;

  SettingsTransactionHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Run a transaction with automatic retry on concurrent modification
  Future<TransactionResult<T>> runWithRetry<T>({
    required Future<T> Function(Transaction) transactionHandler,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final result = await _firestore.runTransaction(transactionHandler);
        return TransactionResult.success(result);
      } on FirebaseException catch (e) {
        attempts++;

        final errorType = _mapFirebaseError(e);

        // Only retry on concurrent modification
        if (errorType != TransactionErrorType.concurrentModification ||
            attempts >= maxRetries) {
          return TransactionResult.failure(
            e.message ?? 'Transaction failed',
            type: errorType,
          );
        }

        developer.log(
          'Transaction retry $attempts/$maxRetries after concurrent modification',
          name: 'SettingsTransactionHelper',
        );

        await Future.delayed(retryDelay * attempts);
      } catch (e) {
        return TransactionResult.failure(
          e.toString(),
          type: TransactionErrorType.unknown,
        );
      }
    }

    return TransactionResult.failure(
      'Max retries exceeded',
      type: TransactionErrorType.concurrentModification,
    );
  }

  /// Atomic update of notification settings with version check
  Future<TransactionResult<void>> updateNotificationSettings({
    required String userId,
    required Map<String, dynamic> updates,
    int? expectedVersion,
  }) async {
    return runWithRetry(
      transactionHandler: (transaction) async {
        final docRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.settings)
            .doc('notifications');

        final snapshot = await transaction.get(docRef);

        // Check version if optimistic locking is enabled
        if (expectedVersion != null && snapshot.exists) {
          final currentVersion = snapshot.data()?['_version'] as int? ?? 0;
          if (currentVersion != expectedVersion) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'aborted',
              message: 'Concurrent modification detected',
            );
          }
        }

        final currentData = snapshot.data() ?? {};
        final newVersion = (currentData['_version'] as int? ?? 0) + 1;

        final mergedData = {
          ...currentData,
          ...updates,
          '_version': newVersion,
          '_updatedAt': FieldValue.serverTimestamp(),
        };

        if (snapshot.exists) {
          transaction.update(docRef, mergedData);
        } else {
          transaction.set(docRef, {
            ...mergedData,
            '_createdAt': FieldValue.serverTimestamp(),
          });
        }
      },
    );
  }

  /// Atomic update of privacy settings with version check
  Future<TransactionResult<void>> updatePrivacySettings({
    required String userId,
    required Map<String, dynamic> updates,
    int? expectedVersion,
  }) async {
    return runWithRetry(
      transactionHandler: (transaction) async {
        final docRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.settings)
            .doc('privacy');

        final snapshot = await transaction.get(docRef);

        // Check version if optimistic locking is enabled
        if (expectedVersion != null && snapshot.exists) {
          final currentVersion = snapshot.data()?['_version'] as int? ?? 0;
          if (currentVersion != expectedVersion) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'aborted',
              message: 'Concurrent modification detected',
            );
          }
        }

        final currentData = snapshot.data() ?? {};
        final newVersion = (currentData['_version'] as int? ?? 0) + 1;

        final mergedData = {
          ...currentData,
          ...updates,
          '_version': newVersion,
          '_updatedAt': FieldValue.serverTimestamp(),
        };

        if (snapshot.exists) {
          transaction.update(docRef, mergedData);
        } else {
          transaction.set(docRef, {
            ...mergedData,
            '_createdAt': FieldValue.serverTimestamp(),
          });
        }
      },
    );
  }

  /// Atomic block/unblock user operation
  /// Updates both privacy settings and user's global blocked list atomically
  Future<TransactionResult<void>> atomicBlockUser({
    required String userId,
    required String targetUserId,
    required bool block,
    required Map<String, dynamic> blockedUserData,
  }) async {
    return runWithRetry(
      transactionHandler: (transaction) async {
        final privacyDocRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.settings)
            .doc('privacy');

        final userDocRef = _firestore.collection(FirebaseCollections.users).doc(userId);

        // Get both documents
        final privacySnapshot = await transaction.get(privacyDocRef);
        final userSnapshot = await transaction.get(userDocRef);

        if (!userSnapshot.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'not-found',
            message: 'User document not found',
          );
        }

        // Update privacy settings blocked users list
        final privacyData = privacySnapshot.data() ?? {};
        var blockedUsers = List<Map<String, dynamic>>.from(
          privacyData['blockedUsers'] ?? [],
        );

        if (block) {
          // Add to blocked list if not already present
          if (!blockedUsers.any((u) => u['userId'] == targetUserId)) {
            blockedUsers.add(blockedUserData);
          }
        } else {
          // Remove from blocked list
          blockedUsers.removeWhere((u) => u['userId'] == targetUserId);
        }

        // Update privacy settings
        transaction.set(
          privacyDocRef,
          {
            ...privacyData,
            'blockedUsers': blockedUsers,
            '_updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Update user's global blocked list
        if (block) {
          transaction.update(userDocRef, {
            'blockedUser': FieldValue.arrayUnion([targetUserId]),
          });
        } else {
          transaction.update(userDocRef, {
            'blockedUser': FieldValue.arrayRemove([targetUserId]),
          });
        }
      },
    );
  }

  /// Atomic chat mute operation
  /// Updates chat override and optionally updates chat metadata
  Future<TransactionResult<void>> atomicMuteChat({
    required String userId,
    required String chatId,
    required Map<String, dynamic> overrideData,
    bool updateChatMetadata = false,
  }) async {
    return runWithRetry(
      transactionHandler: (transaction) async {
        final overrideDocRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.chatNotificationOverrides)
            .doc(chatId);

        // Set the override
        transaction.set(overrideDocRef, {
          ...overrideData,
          '_updatedAt': FieldValue.serverTimestamp(),
        });

        // Optionally update chat metadata for UI indicators
        if (updateChatMetadata) {
          final chatDocRef = _firestore.collection(FirebaseCollections.chats).doc(chatId);
          final chatSnapshot = await transaction.get(chatDocRef);

          if (chatSnapshot.exists) {
            final participants =
                chatSnapshot.data()?['mutedBy'] as List<dynamic>? ?? [];

            if (!participants.contains(userId)) {
              transaction.update(chatDocRef, {
                'mutedBy': FieldValue.arrayUnion([userId]),
              });
            }
          }
        }
      },
    );
  }

  /// Atomic session termination with cleanup
  Future<TransactionResult<void>> atomicTerminateSession({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> securityLogEntry,
  }) async {
    return runWithRetry(
      transactionHandler: (transaction) async {
        final sessionDocRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.sessions)
            .doc(sessionId);

        final securityLogDocRef = _firestore
            .collection(FirebaseCollections.users)
            .doc(userId)
            .collection(FirebaseCollections.securityLog)
            .doc(securityLogEntry['id'] as String);

        // Delete session
        transaction.delete(sessionDocRef);

        // Add security log entry
        transaction.set(securityLogDocRef, {
          ...securityLogEntry,
          'timestamp': FieldValue.serverTimestamp(),
        });
      },
    );
  }

  TransactionErrorType _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'aborted':
      case 'failed-precondition':
        return TransactionErrorType.concurrentModification;
      case 'not-found':
        return TransactionErrorType.notFound;
      case 'permission-denied':
        return TransactionErrorType.permissionDenied;
      case 'unavailable':
        return TransactionErrorType.networkError;
      default:
        return TransactionErrorType.unknown;
    }
  }
}

/// Batch operations helper for non-transactional bulk updates
class SettingsBatchHelper {
  final FirebaseFirestore _firestore;

  SettingsBatchHelper({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Execute batch operations with chunking for large datasets
  Future<TransactionResult<int>> executeBatch({
    required List<BatchOperation> operations,
    int chunkSize = 500, // Firestore limit
  }) async {
    if (operations.isEmpty) {
      return TransactionResult.success(0);
    }

    int processedCount = 0;

    try {
      // Split into chunks
      final chunks = <List<BatchOperation>>[];
      for (var i = 0; i < operations.length; i += chunkSize) {
        chunks.add(
          operations.sublist(
            i,
            i + chunkSize > operations.length ? operations.length : i + chunkSize,
          ),
        );
      }

      // Execute each chunk
      for (final chunk in chunks) {
        final batch = _firestore.batch();

        for (final operation in chunk) {
          switch (operation.type) {
            case BatchOperationType.set:
              batch.set(operation.reference, operation.data!, operation.options);
              break;
            case BatchOperationType.update:
              batch.update(operation.reference, operation.data!);
              break;
            case BatchOperationType.delete:
              batch.delete(operation.reference);
              break;
          }
        }

        await batch.commit();
        processedCount += chunk.length;
      }

      return TransactionResult.success(processedCount);
    } catch (e) {
      developer.log(
        'Batch operation failed after processing $processedCount items',
        name: 'SettingsBatchHelper',
        error: e,
      );
      return TransactionResult.failure(
        'Batch operation failed: $e',
        type: TransactionErrorType.unknown,
      );
    }
  }
}

/// Types of batch operations
enum BatchOperationType { set, update, delete }

/// A single batch operation
class BatchOperation {
  final BatchOperationType type;
  final DocumentReference reference;
  final Map<String, dynamic>? data;
  final SetOptions? options;

  const BatchOperation._({
    required this.type,
    required this.reference,
    this.data,
    this.options,
  });

  factory BatchOperation.set(
    DocumentReference reference,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) {
    return BatchOperation._(
      type: BatchOperationType.set,
      reference: reference,
      data: data,
      options: options ?? SetOptions(merge: true),
    );
  }

  factory BatchOperation.update(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) {
    return BatchOperation._(
      type: BatchOperationType.update,
      reference: reference,
      data: data,
    );
  }

  factory BatchOperation.delete(DocumentReference reference) {
    return BatchOperation._(
      type: BatchOperationType.delete,
      reference: reference,
    );
  }
}

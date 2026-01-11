import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// DATA-002: Collection Name Standardization
/// Provides consistent collection name access and handles legacy collection migration
/// Eliminates the mix of 'Chats' and 'chats' collections

class CollectionNames {
  // Private constructor - use static constants
  CollectionNames._();

  // ============================================================================
  // STANDARDIZED COLLECTION NAMES (lowercase, snake_case)
  // ============================================================================

  /// Chat rooms collection
  static const String chats = 'chats';

  /// Messages subcollection within chat rooms
  static const String messages = 'chat';

  /// Users collection
  static const String users = 'users';

  /// Stories collection
  static const String stories = 'Stories'; // Legacy name, kept for compatibility

  /// Calls collection
  static const String calls = 'calls';

  /// Reports collection
  static const String reports = 'reports';

  /// Notifications collection
  static const String notifications = 'notifications';

  /// Presence/online status collection
  static const String presence = 'presence';

  /// Typing indicators collection (or subcollection)
  static const String typing = 'typing';

  /// File metadata collection
  static const String files = 'files';

  // ============================================================================
  // LEGACY COLLECTION NAMES (to be migrated)
  // ============================================================================

  /// Legacy chat rooms collection (uppercase)
  @Deprecated('Use CollectionNames.chats instead')
  static const String legacyChats = 'Chats';

  /// Legacy messages subcollection
  @Deprecated('Use CollectionNames.messages instead')
  static const String legacyMessages = 'messages';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the standardized collection name
  static String standardize(String name) {
    switch (name) {
      case 'Chats':
        return chats;
      case 'messages':
        return messages;
      default:
        return name;
    }
  }

  /// Check if a collection name is legacy
  static bool isLegacy(String name) {
    return name == legacyChats || name == legacyMessages;
  }

  /// Get all legacy collection names
  static List<String> get legacyNames => [legacyChats, legacyMessages];

  /// Get all current collection names
  static List<String> get currentNames => [
        chats,
        messages,
        users,
        stories,
        calls,
        reports,
        notifications,
        presence,
        typing,
        files,
      ];
}

/// Collection reference provider with standardization
class CollectionProvider {
  static final CollectionProvider instance = CollectionProvider._();
  CollectionProvider._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = LoggerService.instance;

  // ============================================================================
  // COLLECTION REFERENCES
  // ============================================================================

  /// Get chats collection reference
  CollectionReference<Map<String, dynamic>> get chats {
    return _firestore.collection(CollectionNames.chats);
  }

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get users {
    return _firestore.collection(CollectionNames.users);
  }

  /// Get stories collection reference
  CollectionReference<Map<String, dynamic>> get stories {
    return _firestore.collection(CollectionNames.stories);
  }

  /// Get calls collection reference
  CollectionReference<Map<String, dynamic>> get calls {
    return _firestore.collection(CollectionNames.calls);
  }

  /// Get reports collection reference
  CollectionReference<Map<String, dynamic>> get reports {
    return _firestore.collection(CollectionNames.reports);
  }

  /// Get notifications collection reference
  CollectionReference<Map<String, dynamic>> get notifications {
    return _firestore.collection(CollectionNames.notifications);
  }

  // ============================================================================
  // SUBCOLLECTION REFERENCES
  // ============================================================================

  /// Get messages subcollection for a chat room
  CollectionReference<Map<String, dynamic>> messagesFor(String roomId) {
    return chats.doc(roomId).collection(CollectionNames.messages);
  }

  /// Get typing subcollection for a chat room
  CollectionReference<Map<String, dynamic>> typingFor(String roomId) {
    return chats.doc(roomId).collection(CollectionNames.typing);
  }

  // ============================================================================
  // DOCUMENT REFERENCES
  // ============================================================================

  /// Get chat room document reference
  DocumentReference<Map<String, dynamic>> chatRoom(String roomId) {
    return chats.doc(roomId);
  }

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> user(String userId) {
    return users.doc(userId);
  }

  /// Get message document reference
  DocumentReference<Map<String, dynamic>> message(String roomId, String messageId) {
    return messagesFor(roomId).doc(messageId);
  }

  // ============================================================================
  // LEGACY SUPPORT
  // ============================================================================

  /// Get legacy chats collection (for migration purposes only)
  @Deprecated('Use chats instead - this is for migration only')
  CollectionReference<Map<String, dynamic>> get legacyChats {
    return _firestore.collection(CollectionNames.legacyChats);
  }

  /// Check if a room exists in either collection
  Future<DocumentSnapshot<Map<String, dynamic>>?> findChatRoom(String roomId) async {
    // First check the standard collection
    final standardDoc = await chats.doc(roomId).get();
    if (standardDoc.exists) {
      return standardDoc;
    }

    // Fall back to legacy collection
    // ignore: deprecated_member_use_from_same_package
    final legacyDoc = await legacyChats.doc(roomId).get();
    if (legacyDoc.exists) {
      _logger.warning(
        'Found room in legacy collection',
        context: 'CollectionProvider',
      );
      return legacyDoc;
    }

    return null;
  }

  /// Get any collection by standardized name
  CollectionReference<Map<String, dynamic>> collection(String name) {
    final standardName = CollectionNames.standardize(name);
    return _firestore.collection(standardName);
  }
}

/// Collection migrator for moving data from legacy to standard collections
class CollectionMigrator {
  static final CollectionMigrator instance = CollectionMigrator._();
  CollectionMigrator._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = LoggerService.instance;
  final _provider = CollectionProvider.instance;

  /// Migrate a single chat room from legacy to standard collection
  Future<MigrationResult> migrateChatRoom(String roomId) async {
    try {
      // Check if already in standard collection
      final standardDoc = await _provider.chats.doc(roomId).get();
      if (standardDoc.exists) {
        return MigrationResult.alreadyMigrated(roomId);
      }

      // Get from legacy collection
      // ignore: deprecated_member_use_from_same_package
      final legacyDoc = await _provider.legacyChats.doc(roomId).get();
      if (!legacyDoc.exists) {
        return MigrationResult.notFound(roomId);
      }

      final data = legacyDoc.data()!;

      // Add migration metadata
      final migratedData = {
        ...data,
        '_migratedAt': FieldValue.serverTimestamp(),
        '_migratedFrom': CollectionNames.legacyChats,
      };

      // Write to standard collection
      await _provider.chats.doc(roomId).set(migratedData);

      // Migrate messages subcollection
      await _migrateMessages(roomId);

      // Optionally delete from legacy collection
      // await legacyDoc.reference.delete();

      _logger.info(
        'Migrated chat room',
        context: 'CollectionMigrator',
        data: {'roomId': roomId},
      );

      return MigrationResult.success(roomId);
    } catch (e) {
      _logger.logError(
        'Failed to migrate chat room',
        error: e,
        context: 'CollectionMigrator',
      );
      return MigrationResult.failed(roomId, e.toString());
    }
  }

  /// Migrate messages from legacy to standard subcollection
  Future<int> _migrateMessages(String roomId) async {
    int count = 0;

    try {
      // Get legacy messages
      // ignore: deprecated_member_use_from_same_package
      final legacyMessages = await _provider.legacyChats
          .doc(roomId)
          .collection('messages')
          .get();

      if (legacyMessages.docs.isEmpty) {
        return 0;
      }

      // Batch write to standard subcollection
      final batch = _firestore.batch();
      final standardMessagesRef = _provider.messagesFor(roomId);

      for (final doc in legacyMessages.docs) {
        batch.set(standardMessagesRef.doc(doc.id), doc.data());
        count++;
      }

      await batch.commit();

      _logger.debug(
        'Migrated messages',
        context: 'CollectionMigrator',
        data: {'roomId': roomId, 'count': count},
      );
    } catch (e) {
      _logger.logError(
        'Failed to migrate messages',
        error: e,
        context: 'CollectionMigrator',
      );
    }

    return count;
  }

  /// Migrate all legacy chat rooms
  Future<BatchMigrationResult> migrateAllChatRooms({
    int batchSize = 50,
    void Function(int migrated, int total)? onProgress,
  }) async {
    int migrated = 0;
    int failed = 0;
    int alreadyMigrated = 0;

    try {
      // Get all legacy rooms
      // ignore: deprecated_member_use_from_same_package
      final legacyRooms = await _provider.legacyChats.get();
      final total = legacyRooms.docs.length;

      for (final doc in legacyRooms.docs) {
        final result = await migrateChatRoom(doc.id);

        switch (result.status) {
          case MigrationStatus.success:
            migrated++;
            break;
          case MigrationStatus.alreadyMigrated:
            alreadyMigrated++;
            break;
          case MigrationStatus.failed:
            failed++;
            break;
          case MigrationStatus.notFound:
            break;
        }

        onProgress?.call(migrated + alreadyMigrated + failed, total);
      }

      return BatchMigrationResult(
        total: total,
        migrated: migrated,
        alreadyMigrated: alreadyMigrated,
        failed: failed,
      );
    } catch (e) {
      _logger.logError(
        'Batch migration failed',
        error: e,
        context: 'CollectionMigrator',
      );
      return BatchMigrationResult(
        total: 0,
        migrated: migrated,
        alreadyMigrated: alreadyMigrated,
        failed: failed,
        error: e.toString(),
      );
    }
  }

  /// Check migration status for a room
  Future<MigrationStatus> checkStatus(String roomId) async {
    final standardExists = (await _provider.chats.doc(roomId).get()).exists;
    // ignore: deprecated_member_use_from_same_package
    final legacyExists = (await _provider.legacyChats.doc(roomId).get()).exists;

    if (standardExists && !legacyExists) {
      return MigrationStatus.success;
    } else if (standardExists && legacyExists) {
      return MigrationStatus.alreadyMigrated; // Exists in both
    } else if (!standardExists && legacyExists) {
      return MigrationStatus.notFound; // Needs migration
    } else {
      return MigrationStatus.notFound; // Doesn't exist
    }
  }

  /// Delete legacy collection data after successful migration
  Future<int> cleanupLegacyData({bool dryRun = true}) async {
    int deleted = 0;

    try {
      // ignore: deprecated_member_use_from_same_package
      final legacyRooms = await _provider.legacyChats.get();

      for (final doc in legacyRooms.docs) {
        // Verify room exists in standard collection
        final standardExists = (await _provider.chats.doc(doc.id).get()).exists;

        if (standardExists) {
          if (!dryRun) {
            // Delete legacy messages first
            final messages = await doc.reference.collection('messages').get();
            for (final msg in messages.docs) {
              await msg.reference.delete();
            }
            // Delete legacy room
            await doc.reference.delete();
          }
          deleted++;
        }
      }

      _logger.info(
        dryRun ? 'Dry run cleanup' : 'Cleaned up legacy data',
        context: 'CollectionMigrator',
        data: {'deleted': deleted},
      );

      return deleted;
    } catch (e) {
      _logger.logError(
        'Cleanup failed',
        error: e,
        context: 'CollectionMigrator',
      );
      return deleted;
    }
  }
}

/// Migration result for a single document
class MigrationResult {
  final String roomId;
  final MigrationStatus status;
  final String? error;

  const MigrationResult._({
    required this.roomId,
    required this.status,
    this.error,
  });

  factory MigrationResult.success(String roomId) => MigrationResult._(
        roomId: roomId,
        status: MigrationStatus.success,
      );

  factory MigrationResult.alreadyMigrated(String roomId) => MigrationResult._(
        roomId: roomId,
        status: MigrationStatus.alreadyMigrated,
      );

  factory MigrationResult.notFound(String roomId) => MigrationResult._(
        roomId: roomId,
        status: MigrationStatus.notFound,
      );

  factory MigrationResult.failed(String roomId, String error) =>
      MigrationResult._(
        roomId: roomId,
        status: MigrationStatus.failed,
        error: error,
      );
}

/// Migration status
enum MigrationStatus {
  success,
  alreadyMigrated,
  notFound,
  failed,
}

/// Batch migration result
class BatchMigrationResult {
  final int total;
  final int migrated;
  final int alreadyMigrated;
  final int failed;
  final String? error;

  const BatchMigrationResult({
    required this.total,
    required this.migrated,
    required this.alreadyMigrated,
    required this.failed,
    this.error,
  });

  bool get isSuccess => failed == 0 && error == null;
  int get processed => migrated + alreadyMigrated + failed;

  @override
  String toString() => 'BatchMigrationResult('
      'total: $total, '
      'migrated: $migrated, '
      'alreadyMigrated: $alreadyMigrated, '
      'failed: $failed)';
}

/// Mixin for classes that need collection access
mixin CollectionAccessMixin {
  final _provider = CollectionProvider.instance;

  /// Get chats collection
  CollectionReference<Map<String, dynamic>> get chatsCollection =>
      _provider.chats;

  /// Get users collection
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _provider.users;

  /// Get messages for a room
  CollectionReference<Map<String, dynamic>> messagesCollection(String roomId) =>
      _provider.messagesFor(roomId);

  /// Get chat room document
  DocumentReference<Map<String, dynamic>> chatRoomDoc(String roomId) =>
      _provider.chatRoom(roomId);

  /// Get user document
  DocumentReference<Map<String, dynamic>> userDoc(String userId) =>
      _provider.user(userId);

  /// Get message document
  DocumentReference<Map<String, dynamic>> messageDoc(
    String roomId,
    String messageId,
  ) =>
      _provider.message(roomId, messageId);
}

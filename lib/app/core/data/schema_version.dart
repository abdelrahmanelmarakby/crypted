import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// DATA-003: Schema Version Management
/// Provides versioning for Firestore documents to enable safe migrations

class SchemaVersionManager {
  static final SchemaVersionManager instance = SchemaVersionManager._();
  SchemaVersionManager._();

  final _logger = LoggerService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current schema versions by collection
  static const Map<String, int> currentVersions = {
    'users': 2,
    'chats': 3,
    'messages': 2,
    'stories': 1,
    'calls': 1,
    'reports': 1,
  };

  /// Get the current schema version for a collection
  int getCurrentVersion(String collection) {
    return currentVersions[collection] ?? 1;
  }

  /// Check if a document needs migration
  bool needsMigration(String collection, Map<String, dynamic> data) {
    final currentVersion = getCurrentVersion(collection);
    final docVersion = data['_schemaVersion'] ?? 1;
    return docVersion < currentVersion;
  }

  /// Get document schema version
  int getDocumentVersion(Map<String, dynamic> data) {
    return data['_schemaVersion'] ?? 1;
  }

  /// Add schema version to new document
  Map<String, dynamic> addVersion(String collection, Map<String, dynamic> data) {
    return {
      ...data,
      '_schemaVersion': getCurrentVersion(collection),
      '_createdAt': FieldValue.serverTimestamp(),
      '_updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update schema version on document update
  Map<String, dynamic> updateVersion(Map<String, dynamic> data) {
    return {
      ...data,
      '_updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Migrate a document to the latest schema version
  Future<Map<String, dynamic>> migrateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final currentVersion = getCurrentVersion(collection);
    var docVersion = getDocumentVersion(data);
    var migratedData = Map<String, dynamic>.from(data);

    while (docVersion < currentVersion) {
      final nextVersion = docVersion + 1;
      _logger.info(
        'Migrating document',
        context: 'SchemaVersion',
        data: {
          'collection': collection,
          'docId': docId,
          'from': docVersion,
          'to': nextVersion,
        },
      );

      migratedData = await _applyMigration(
        collection,
        docVersion,
        nextVersion,
        migratedData,
      );

      docVersion = nextVersion;
    }

    migratedData['_schemaVersion'] = currentVersion;
    migratedData['_migratedAt'] = DateTime.now().toIso8601String();

    return migratedData;
  }

  /// Apply a specific migration
  Future<Map<String, dynamic>> _applyMigration(
    String collection,
    int fromVersion,
    int toVersion,
    Map<String, dynamic> data,
  ) async {
    final migrationKey = '${collection}_${fromVersion}_$toVersion';

    switch (migrationKey) {
      // User migrations
      case 'users_1_2':
        return _migrateUsers1To2(data);

      // Chat room migrations
      case 'chats_1_2':
        return _migrateChats1To2(data);
      case 'chats_2_3':
        return _migrateChats2To3(data);

      // Message migrations
      case 'messages_1_2':
        return _migrateMessages1To2(data);

      default:
        _logger.warning(
          'No migration handler found',
          context: 'SchemaVersion',
          data: {'migrationKey': migrationKey},
        );
        return data;
    }
  }

  // ============================================================================
  // USER MIGRATIONS
  // ============================================================================

  /// Migrate users from v1 to v2
  /// - Add displayName field (copy from fullName)
  /// - Add isVerified field
  Map<String, dynamic> _migrateUsers1To2(Map<String, dynamic> data) {
    return {
      ...data,
      'displayName': data['displayName'] ?? data['fullName'] ?? '',
      'isVerified': data['isVerified'] ?? false,
    };
  }

  // ============================================================================
  // CHAT ROOM MIGRATIONS
  // ============================================================================

  /// Migrate chats from v1 to v2
  /// - Rename 'membersIds' to 'memberIds' for consistency
  /// - Add 'settings' object
  Map<String, dynamic> _migrateChats1To2(Map<String, dynamic> data) {
    return {
      ...data,
      'memberIds': data['memberIds'] ?? data['membersIds'] ?? [],
      'settings': data['settings'] ?? {
        'muteNotifications': false,
        'pinned': false,
        'archived': false,
      },
    };
  }

  /// Migrate chats from v2 to v3
  /// - Add 'lastReadBy' map for read receipts
  /// - Add 'typing' map for typing indicators
  Map<String, dynamic> _migrateChats2To3(Map<String, dynamic> data) {
    return {
      ...data,
      'lastReadBy': data['lastReadBy'] ?? {},
      'typing': data['typing'] ?? {},
    };
  }

  // ============================================================================
  // MESSAGE MIGRATIONS
  // ============================================================================

  /// Migrate messages from v1 to v2
  /// - Add 'readBy' array
  /// - Add 'reactions' map
  Map<String, dynamic> _migrateMessages1To2(Map<String, dynamic> data) {
    return {
      ...data,
      'readBy': data['readBy'] ?? [],
      'reactions': data['reactions'] ?? {},
    };
  }

  /// Batch migrate documents in a collection
  Future<int> batchMigrate(
    String collection, {
    int batchSize = 100,
    void Function(int migrated, int total)? onProgress,
  }) async {
    final currentVersion = getCurrentVersion(collection);
    int migratedCount = 0;

    // Query documents with old schema versions
    QuerySnapshot? snapshot;
    do {
      var query = _firestore
          .collection(collection)
          .where('_schemaVersion', isLessThan: currentVersion)
          .limit(batchSize);

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(snapshot.docs.last);
      }

      snapshot = await query.get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final migratedData = await migrateDocument(collection, doc.id, data);

        await _firestore.collection(collection).doc(doc.id).update(migratedData);
        migratedCount++;
      }

      onProgress?.call(migratedCount, migratedCount + snapshot.docs.length);

      _logger.info(
        'Batch migration progress',
        context: 'SchemaVersion',
        data: {
          'collection': collection,
          'migrated': migratedCount,
        },
      );
    } while (snapshot.docs.length == batchSize);

    return migratedCount;
  }
}

/// Schema-aware document parser
class SchemaAwareParser<T> {
  final String collection;
  final T Function(Map<String, dynamic>) parser;
  final SchemaVersionManager _versionManager = SchemaVersionManager.instance;

  SchemaAwareParser({
    required this.collection,
    required this.parser,
  });

  /// Parse a document, migrating if necessary
  Future<T> parse(String docId, Map<String, dynamic> data) async {
    var parsableData = data;

    if (_versionManager.needsMigration(collection, data)) {
      parsableData = await _versionManager.migrateDocument(
        collection,
        docId,
        data,
      );
    }

    return parser(parsableData);
  }

  /// Parse synchronously (skips migration)
  T parseSync(Map<String, dynamic> data) {
    return parser(data);
  }
}

/// Extension for adding schema version to documents
extension SchemaVersionExtension on Map<String, dynamic> {
  /// Add schema version for a collection
  Map<String, dynamic> withSchemaVersion(String collection) {
    return SchemaVersionManager.instance.addVersion(collection, this);
  }

  /// Check if document needs migration
  bool needsMigration(String collection) {
    return SchemaVersionManager.instance.needsMigration(collection, this);
  }

  /// Get schema version
  int get schemaVersion {
    return SchemaVersionManager.instance.getDocumentVersion(this);
  }
}

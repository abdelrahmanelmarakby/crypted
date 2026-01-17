import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/retry_helper.dart';

/// Abstract repository interface for privacy settings.
///
/// This abstraction allows for:
/// - Easy mocking in unit tests
/// - Swapping backends (Firestore, local storage, mock)
/// - Clear separation of data access from business logic
abstract class PrivacySettingsRepository {
  /// Get the current privacy settings for a user.
  Future<EnhancedPrivacySettingsModel?> getSettings(String userId);

  /// Save privacy settings for a user.
  Future<void> saveSettings(String userId, EnhancedPrivacySettingsModel settings);

  /// Watch privacy settings for real-time updates.
  Stream<EnhancedPrivacySettingsModel?> watchSettings(String userId);

  /// Get active sessions for a user.
  Future<List<ActiveSession>> getActiveSessions(String userId, {int limit = 10});

  /// Watch active sessions for real-time updates.
  Stream<List<ActiveSession>> watchActiveSessions(String userId, {int limit = 10});

  /// Delete a session.
  Future<void> deleteSession(String userId, String sessionId);

  /// Delete all sessions except current.
  Future<void> deleteAllOtherSessions(String userId, String currentSessionId);

  /// Get security log entries.
  Future<List<SecurityLogEntry>> getSecurityLog(String userId, {int limit = 20});

  /// Add a security log entry.
  Future<void> addSecurityLogEntry(String userId, SecurityLogEntry entry);

  /// Update user's blocked list in the main user document.
  Future<void> updateBlockedUsersList(String userId, List<String> blockedUserIds);

  /// Add a user to the blocked list.
  Future<void> addToBlockedList(String userId, String blockedUserId);

  /// Remove a user from the blocked list.
  Future<void> removeFromBlockedList(String userId, String blockedUserId);

  /// Delete all settings for a user (used for reset).
  Future<void> deleteAllSettings(String userId);
}

/// Firestore implementation of [PrivacySettingsRepository].
///
/// Stores settings in the following structure:
/// - users/{userId}/settings/privacy - Main privacy settings document
/// - users/{userId}/sessions/{sessionId} - Active sessions
/// - users/{userId}/securityLog/{entryId} - Security log entries
class FirestorePrivacySettingsRepository implements PrivacySettingsRepository {
  final FirebaseFirestore _firestore;

  // Collection and document paths
  static const String _usersCollection = 'users';
  static const String _settingsCollection = 'settings';
  static const String _privacyDoc = 'privacy';
  static const String _sessionsCollection = 'sessions';
  static const String _securityLogCollection = 'securityLog';

  FirestorePrivacySettingsRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the settings document reference for a user.
  DocumentReference<Map<String, dynamic>> _settingsRef(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_settingsCollection)
        .doc(_privacyDoc);
  }

  /// Get the sessions collection reference for a user.
  CollectionReference<Map<String, dynamic>> _sessionsRef(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_sessionsCollection);
  }

  /// Get the security log collection reference for a user.
  CollectionReference<Map<String, dynamic>> _securityLogRef(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_securityLogCollection);
  }

  /// Get the user document reference.
  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
  }

  @override
  Future<EnhancedPrivacySettingsModel?> getSettings(String userId) async {
    return RetryHelper.withRetry(
      () async {
        final doc = await _settingsRef(userId).get();
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        return EnhancedPrivacySettingsModel.fromMap(doc.data());
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
      onRetry: (attempt, error, delay) {
        developer.log(
          'Retrying getSettings for user $userId',
          name: 'PrivacySettingsRepository',
        );
      },
    );
  }

  @override
  Future<void> saveSettings(
    String userId,
    EnhancedPrivacySettingsModel settings,
  ) async {
    return RetryHelper.withRetry(
      () => _settingsRef(userId).set(settings.toMap()),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
      onRetry: (attempt, error, delay) {
        developer.log(
          'Retrying saveSettings for user $userId',
          name: 'PrivacySettingsRepository',
        );
      },
    );
  }

  @override
  Stream<EnhancedPrivacySettingsModel?> watchSettings(String userId) {
    return _settingsRef(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return EnhancedPrivacySettingsModel.fromMap(snapshot.data());
    }).handleError((error) {
      developer.log(
        'Error watching settings for user $userId',
        name: 'PrivacySettingsRepository',
        error: error,
      );
    });
  }

  @override
  Future<List<ActiveSession>> getActiveSessions(String userId, {int limit = 10}) async {
    return RetryHelper.withRetry(
      () async {
        final snapshot = await _sessionsRef(userId)
            .orderBy('lastActive', descending: true)
            .limit(limit)
            .get();
        return snapshot.docs
            .map((doc) => ActiveSession.fromMap(doc.data()))
            .toList();
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Stream<List<ActiveSession>> watchActiveSessions(String userId, {int limit = 10}) {
    return _sessionsRef(userId)
        .orderBy('lastActive', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActiveSession.fromMap(doc.data()))
          .toList();
    }).handleError((error) {
      developer.log(
        'Error watching sessions for user $userId',
        name: 'PrivacySettingsRepository',
        error: error,
      );
    });
  }

  @override
  Future<void> deleteSession(String userId, String sessionId) async {
    return RetryHelper.withRetry(
      () => _sessionsRef(userId).doc(sessionId).delete(),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> deleteAllOtherSessions(String userId, String currentSessionId) async {
    return RetryHelper.withRetry(
      () async {
        final sessions = await _sessionsRef(userId).get();
        final batch = _firestore.batch();

        for (final doc in sessions.docs) {
          if (doc.id != currentSessionId) {
            batch.delete(doc.reference);
          }
        }

        await batch.commit();
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<List<SecurityLogEntry>> getSecurityLog(String userId, {int limit = 20}) async {
    return RetryHelper.withRetry(
      () async {
        final snapshot = await _securityLogRef(userId)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();
        return snapshot.docs
            .map((doc) => SecurityLogEntry.fromMap(doc.data()))
            .toList();
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> addSecurityLogEntry(String userId, SecurityLogEntry entry) async {
    return RetryHelper.withRetry(
      () => _securityLogRef(userId).doc(entry.id).set(entry.toMap()),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> updateBlockedUsersList(String userId, List<String> blockedUserIds) async {
    return RetryHelper.withRetry(
      () => _userRef(userId).update({'blockedUser': blockedUserIds}),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> addToBlockedList(String userId, String blockedUserId) async {
    return RetryHelper.withRetry(
      () => _userRef(userId).update({
        'blockedUser': FieldValue.arrayUnion([blockedUserId]),
      }),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> removeFromBlockedList(String userId, String blockedUserId) async {
    return RetryHelper.withRetry(
      () => _userRef(userId).update({
        'blockedUser': FieldValue.arrayRemove([blockedUserId]),
      }),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> deleteAllSettings(String userId) async {
    return RetryHelper.withRetry(
      () async {
        final batch = _firestore.batch();

        // Delete all sessions
        final sessions = await _sessionsRef(userId).get();
        for (final doc in sessions.docs) {
          batch.delete(doc.reference);
        }

        // Delete all security log entries
        final logs = await _securityLogRef(userId).get();
        for (final doc in logs.docs) {
          batch.delete(doc.reference);
        }

        // Delete main settings document
        batch.delete(_settingsRef(userId));

        await batch.commit();
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }
}

/// In-memory implementation for testing.
class InMemoryPrivacySettingsRepository implements PrivacySettingsRepository {
  final Map<String, EnhancedPrivacySettingsModel> _settings = {};
  final Map<String, List<ActiveSession>> _sessions = {};
  final Map<String, List<SecurityLogEntry>> _securityLogs = {};
  final Map<String, List<String>> _blockedUsers = {};
  final Map<String, StreamController<EnhancedPrivacySettingsModel?>> _settingsControllers = {};
  final Map<String, StreamController<List<ActiveSession>>> _sessionsControllers = {};

  @override
  Future<EnhancedPrivacySettingsModel?> getSettings(String userId) async {
    return _settings[userId];
  }

  @override
  Future<void> saveSettings(String userId, EnhancedPrivacySettingsModel settings) async {
    _settings[userId] = settings;
    _settingsControllers[userId]?.add(settings);
  }

  @override
  Stream<EnhancedPrivacySettingsModel?> watchSettings(String userId) {
    _settingsControllers[userId] ??= StreamController<EnhancedPrivacySettingsModel?>.broadcast();
    return _settingsControllers[userId]!.stream;
  }

  @override
  Future<List<ActiveSession>> getActiveSessions(String userId, {int limit = 10}) async {
    final sessions = _sessions[userId] ?? [];
    sessions.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    return sessions.take(limit).toList();
  }

  @override
  Stream<List<ActiveSession>> watchActiveSessions(String userId, {int limit = 10}) {
    _sessionsControllers[userId] ??= StreamController<List<ActiveSession>>.broadcast();
    return _sessionsControllers[userId]!.stream;
  }

  @override
  Future<void> deleteSession(String userId, String sessionId) async {
    _sessions[userId]?.removeWhere((s) => s.sessionId == sessionId);
    _notifySessionsChange(userId);
  }

  @override
  Future<void> deleteAllOtherSessions(String userId, String currentSessionId) async {
    _sessions[userId]?.removeWhere((s) => s.sessionId != currentSessionId);
    _notifySessionsChange(userId);
  }

  @override
  Future<List<SecurityLogEntry>> getSecurityLog(String userId, {int limit = 20}) async {
    final logs = _securityLogs[userId] ?? [];
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }

  @override
  Future<void> addSecurityLogEntry(String userId, SecurityLogEntry entry) async {
    _securityLogs[userId] ??= [];
    _securityLogs[userId]!.insert(0, entry);
    // Keep only last 100 entries
    if (_securityLogs[userId]!.length > 100) {
      _securityLogs[userId] = _securityLogs[userId]!.sublist(0, 100);
    }
  }

  @override
  Future<void> updateBlockedUsersList(String userId, List<String> blockedUserIds) async {
    _blockedUsers[userId] = blockedUserIds;
  }

  @override
  Future<void> addToBlockedList(String userId, String blockedUserId) async {
    _blockedUsers[userId] ??= [];
    if (!_blockedUsers[userId]!.contains(blockedUserId)) {
      _blockedUsers[userId]!.add(blockedUserId);
    }
  }

  @override
  Future<void> removeFromBlockedList(String userId, String blockedUserId) async {
    _blockedUsers[userId]?.remove(blockedUserId);
  }

  @override
  Future<void> deleteAllSettings(String userId) async {
    _settings.remove(userId);
    _sessions.remove(userId);
    _securityLogs.remove(userId);
    _settingsControllers[userId]?.add(null);
    _notifySessionsChange(userId);
  }

  void _notifySessionsChange(String userId) {
    final sessions = _sessions[userId] ?? [];
    _sessionsControllers[userId]?.add(sessions);
  }

  /// Add a session (for testing)
  void addSession(String userId, ActiveSession session) {
    _sessions[userId] ??= [];
    _sessions[userId]!.add(session);
    _notifySessionsChange(userId);
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _settingsControllers.values) {
      controller.close();
    }
    for (final controller in _sessionsControllers.values) {
      controller.close();
    }
  }
}

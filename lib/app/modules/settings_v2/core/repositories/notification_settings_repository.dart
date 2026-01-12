import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/retry_helper.dart';

/// Abstract repository interface for notification settings.
///
/// This abstraction allows for:
/// - Easy mocking in unit tests
/// - Swapping backends (Firestore, local storage, mock)
/// - Clear separation of data access from business logic
abstract class NotificationSettingsRepository {
  /// Get the current notification settings for a user.
  Future<EnhancedNotificationSettingsModel?> getSettings(String userId);

  /// Save notification settings for a user.
  Future<void> saveSettings(String userId, EnhancedNotificationSettingsModel settings);

  /// Watch notification settings for real-time updates.
  Stream<EnhancedNotificationSettingsModel?> watchSettings(String userId);

  /// Get a specific chat notification override.
  Future<ChatNotificationOverride?> getChatOverride(String userId, String chatId);

  /// Save a chat notification override.
  Future<void> saveChatOverride(String userId, ChatNotificationOverride override);

  /// Delete a chat notification override.
  Future<void> deleteChatOverride(String userId, String chatId);

  /// Get all chat notification overrides for a user.
  Future<List<ChatNotificationOverride>> getAllChatOverrides(String userId);

  /// Watch all chat notification overrides for real-time updates.
  Stream<List<ChatNotificationOverride>> watchChatOverrides(String userId);

  /// Delete all settings for a user (used for reset).
  Future<void> deleteAllSettings(String userId);
}

/// Firestore implementation of [NotificationSettingsRepository].
///
/// Stores settings in the following structure:
/// - users/{userId}/settings/notifications - Main settings document
/// - users/{userId}/settings/notifications/chatOverrides/{chatId} - Per-chat overrides
class FirestoreNotificationSettingsRepository implements NotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  // Collection and document paths
  static const String _usersCollection = 'users';
  static const String _settingsCollection = 'settings';
  static const String _notificationsDoc = 'notifications';
  static const String _chatOverridesCollection = 'chatOverrides';

  FirestoreNotificationSettingsRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the settings document reference for a user.
  DocumentReference<Map<String, dynamic>> _settingsRef(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_settingsCollection)
        .doc(_notificationsDoc);
  }

  /// Get the chat overrides collection reference for a user.
  CollectionReference<Map<String, dynamic>> _chatOverridesRef(String userId) {
    return _settingsRef(userId).collection(_chatOverridesCollection);
  }

  @override
  Future<EnhancedNotificationSettingsModel?> getSettings(String userId) async {
    return RetryHelper.withRetry(
      () async {
        final doc = await _settingsRef(userId).get();
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        return EnhancedNotificationSettingsModel.fromMap(doc.data());
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
      onRetry: (attempt, error, delay) {
        developer.log(
          'Retrying getSettings for user $userId',
          name: 'NotificationSettingsRepository',
        );
      },
    );
  }

  @override
  Future<void> saveSettings(
    String userId,
    EnhancedNotificationSettingsModel settings,
  ) async {
    return RetryHelper.withRetry(
      () => _settingsRef(userId).set(settings.toMap()),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
      onRetry: (attempt, error, delay) {
        developer.log(
          'Retrying saveSettings for user $userId',
          name: 'NotificationSettingsRepository',
        );
      },
    );
  }

  @override
  Stream<EnhancedNotificationSettingsModel?> watchSettings(String userId) {
    return _settingsRef(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return EnhancedNotificationSettingsModel.fromMap(snapshot.data());
    }).handleError((error) {
      developer.log(
        'Error watching settings for user $userId',
        name: 'NotificationSettingsRepository',
        error: error,
      );
    });
  }

  @override
  Future<ChatNotificationOverride?> getChatOverride(
    String userId,
    String chatId,
  ) async {
    return RetryHelper.withRetryOrNull(
      () async {
        final doc = await _chatOverridesRef(userId).doc(chatId).get();
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        return ChatNotificationOverride.fromMap(doc.data()!);
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> saveChatOverride(
    String userId,
    ChatNotificationOverride override,
  ) async {
    return RetryHelper.withRetry(
      () => _chatOverridesRef(userId).doc(override.chatId).set(override.toMap()),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<void> deleteChatOverride(String userId, String chatId) async {
    return RetryHelper.withRetry(
      () => _chatOverridesRef(userId).doc(chatId).delete(),
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Future<List<ChatNotificationOverride>> getAllChatOverrides(String userId) async {
    return RetryHelper.withRetry(
      () async {
        final snapshot = await _chatOverridesRef(userId).get();
        return snapshot.docs
            .map((doc) => ChatNotificationOverride.fromMap(doc.data()))
            .toList();
      },
      maxAttempts: 3,
      retryIf: RetryHelper.isRetryableException,
    );
  }

  @override
  Stream<List<ChatNotificationOverride>> watchChatOverrides(String userId) {
    return _chatOverridesRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatNotificationOverride.fromMap(doc.data()))
          .toList();
    }).handleError((error) {
      developer.log(
        'Error watching chat overrides for user $userId',
        name: 'NotificationSettingsRepository',
        error: error,
      );
    });
  }

  @override
  Future<void> deleteAllSettings(String userId) async {
    return RetryHelper.withRetry(
      () async {
        final batch = _firestore.batch();

        // Delete all chat overrides
        final overrides = await _chatOverridesRef(userId).get();
        for (final doc in overrides.docs) {
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
class InMemoryNotificationSettingsRepository implements NotificationSettingsRepository {
  final Map<String, EnhancedNotificationSettingsModel> _settings = {};
  final Map<String, Map<String, ChatNotificationOverride>> _chatOverrides = {};
  final Map<String, StreamController<EnhancedNotificationSettingsModel?>> _settingsControllers = {};
  final Map<String, StreamController<List<ChatNotificationOverride>>> _overridesControllers = {};

  @override
  Future<EnhancedNotificationSettingsModel?> getSettings(String userId) async {
    return _settings[userId];
  }

  @override
  Future<void> saveSettings(String userId, EnhancedNotificationSettingsModel settings) async {
    _settings[userId] = settings;
    _settingsControllers[userId]?.add(settings);
  }

  @override
  Stream<EnhancedNotificationSettingsModel?> watchSettings(String userId) {
    _settingsControllers[userId] ??= StreamController<EnhancedNotificationSettingsModel?>.broadcast();
    return _settingsControllers[userId]!.stream;
  }

  @override
  Future<ChatNotificationOverride?> getChatOverride(String userId, String chatId) async {
    return _chatOverrides[userId]?[chatId];
  }

  @override
  Future<void> saveChatOverride(String userId, ChatNotificationOverride override) async {
    _chatOverrides[userId] ??= {};
    _chatOverrides[userId]![override.chatId] = override;
    _notifyOverridesChange(userId);
  }

  @override
  Future<void> deleteChatOverride(String userId, String chatId) async {
    _chatOverrides[userId]?.remove(chatId);
    _notifyOverridesChange(userId);
  }

  @override
  Future<List<ChatNotificationOverride>> getAllChatOverrides(String userId) async {
    return _chatOverrides[userId]?.values.toList() ?? [];
  }

  @override
  Stream<List<ChatNotificationOverride>> watchChatOverrides(String userId) {
    _overridesControllers[userId] ??= StreamController<List<ChatNotificationOverride>>.broadcast();
    return _overridesControllers[userId]!.stream;
  }

  @override
  Future<void> deleteAllSettings(String userId) async {
    _settings.remove(userId);
    _chatOverrides.remove(userId);
    _settingsControllers[userId]?.add(null);
    _notifyOverridesChange(userId);
  }

  void _notifyOverridesChange(String userId) {
    final overrides = _chatOverrides[userId]?.values.toList() ?? [];
    _overridesControllers[userId]?.add(overrides);
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _settingsControllers.values) {
      controller.close();
    }
    for (final controller in _overridesControllers.values) {
      controller.close();
    }
  }
}

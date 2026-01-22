import 'package:crypted_app/app/core/di/chat_architecture_bindings.dart';
import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/domain/repositories/i_reaction_repository.dart';
import 'package:crypted_app/app/modules/chat/services/new_architecture_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Mixin to add new architecture support to ChatController
///
/// This mixin provides:
/// 1. NewArchitectureAdapter integration
/// 2. Methods that use new architecture with fallback to legacy
/// 3. Feature flag support for gradual migration
///
/// Usage:
/// ```dart
/// class ChatController extends GetxController with NewArchitectureMixin {
///   @override
///   void onInit() {
///     super.onInit();
///     // ... existing initialization ...
///     initializeNewArchitectureMixin(roomId, messages);
///   }
///
///   Future<void> sendMessage(Message message) async {
///     // Use the mixin method instead of direct implementation
///     await sendMessageWithNewArchitecture(
///       message: message,
///       members: members,
///       legacyPath: () => chatDataSource.sendMessage(...),
///     );
///   }
/// }
/// ```
mixin NewArchitectureMixin on GetxController {
  /// The new architecture adapter
  NewArchitectureAdapter? _newArchAdapter;

  /// Whether new architecture is enabled and ready
  bool get isNewArchitectureEnabled =>
      _newArchAdapter?.isEnabled ?? false;

  /// Whether new architecture should be used for this operation
  bool get shouldUseNewArchitecture =>
      ChatArchitectureConfig.shouldUseNewArchitecture &&
      _newArchAdapter?.isReady == true;

  // =================== Initialization ===================

  /// Initialize the new architecture mixin
  ///
  /// Call this from onInit() after roomId is set.
  void initializeNewArchitectureMixin(String roomId, RxList<Message> messages) {
    // Create adapter with shared messages list
    _newArchAdapter = NewArchitectureAdapter(messages: messages);

    // Initialize for this room
    _newArchAdapter!.initialize(roomId);

    if (kDebugMode) {
      print('🔧 NewArchitectureMixin initialized');
      print('   - Adapter ready: ${_newArchAdapter?.isReady}');
      print('   - Feature enabled: ${ChatArchitectureConfig.shouldUseNewArchitecture}');
    }
  }

  // =================== Message Operations ===================

  /// Send a message using new architecture with fallback
  ///
  /// [message] - The message to send
  /// [members] - Chat members for notification
  /// [legacyPath] - Fallback function to use legacy implementation
  /// [onOptimisticUpdate] - Called when optimistic update is applied
  /// [onSuccess] - Called with message ID on success
  /// [onError] - Called with error message on failure
  Future<String?> sendMessageWithNewArchitecture({
    required Message message,
    required List<SocialMediaUser> members,
    required Future<String> Function() legacyPath,
    VoidCallback? onOptimisticUpdate,
    void Function(String messageId)? onSuccess,
    void Function(String error)? onError,
  }) async {
    // Check if we should use new architecture
    if (shouldUseNewArchitecture) {
      try {
        final messageId = await _newArchAdapter!.sendMessage(
          message: message,
          members: members,
          onOptimisticUpdate: onOptimisticUpdate,
        );

        if (messageId != null) {
          if (kDebugMode) {
            print('✅ Message sent via new architecture: $messageId');
          }
          onSuccess?.call(messageId);
          return messageId;
        }

        // messageId is null, fall through to legacy
        if (kDebugMode) {
          print('⚠️ New architecture returned null, using legacy path');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ New architecture error, falling back to legacy: $e');
        }
        // Fall through to legacy path
      }
    }

    // Use legacy path
    try {
      final messageId = await legacyPath();
      onSuccess?.call(messageId);
      return messageId;
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Edit a message using new architecture with fallback
  Future<bool> editMessageWithNewArchitecture({
    required String messageId,
    required String newText,
    required String userId,
    DateTime? originalTimestamp,
    required Future<void> Function() legacyPath,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (shouldUseNewArchitecture) {
      try {
        final result = await _newArchAdapter!.editMessage(
          messageId: messageId,
          newText: newText,
          userId: userId,
          originalTimestamp: originalTimestamp,
        );

        if (result == true) {
          if (kDebugMode) {
            print('✅ Message edited via new architecture: $messageId');
          }
          onSuccess?.call();
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ New architecture edit error, falling back to legacy: $e');
        }
      }
    }

    // Use legacy path
    try {
      await legacyPath();
      onSuccess?.call();
      return true;
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Delete a message using new architecture with fallback
  Future<bool> deleteMessageWithNewArchitecture({
    required String messageId,
    required String userId,
    bool permanent = false,
    required Future<void> Function() legacyPath,
    void Function()? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (shouldUseNewArchitecture) {
      try {
        final result = await _newArchAdapter!.deleteMessage(
          messageId: messageId,
          userId: userId,
          permanent: permanent,
        );

        if (result == true) {
          if (kDebugMode) {
            print('✅ Message deleted via new architecture: $messageId');
          }
          onSuccess?.call();
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ New architecture delete error, falling back to legacy: $e');
        }
      }
    }

    // Use legacy path
    try {
      await legacyPath();
      onSuccess?.call();
      return true;
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Toggle a reaction using new architecture with fallback
  Future<ReactionResult?> toggleReactionWithNewArchitecture({
    required String messageId,
    required String emoji,
    required String userId,
    required Future<void> Function() legacyPath,
    void Function(ReactionResult result)? onSuccess,
    void Function(String error)? onError,
  }) async {
    if (shouldUseNewArchitecture) {
      try {
        final result = await _newArchAdapter!.toggleReaction(
          messageId: messageId,
          emoji: emoji,
          userId: userId,
        );

        if (result != null) {
          if (kDebugMode) {
            print('✅ Reaction toggled via new architecture: $emoji on $messageId');
          }
          onSuccess?.call(result);
          return result;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ New architecture reaction error, falling back to legacy: $e');
        }
      }
    }

    // Use legacy path
    try {
      await legacyPath();
      return null; // Legacy path doesn't return reaction result
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  // =================== Optimistic Updates ===================

  /// Add a local message optimistically (uses new architecture if enabled)
  void addLocalMessageWithNewArchitecture(Message message) {
    if (shouldUseNewArchitecture && _newArchAdapter != null) {
      _newArchAdapter!.addLocalMessage(message);
    }
  }

  /// Register confirmed message ID mapping
  void registerConfirmedWithNewArchitecture(String tempId, String actualId) {
    _newArchAdapter?.registerConfirmed(tempId, actualId);
  }

  /// Register pending upload
  void registerPendingUploadWithNewArchitecture(String uploadId, String actualId) {
    _newArchAdapter?.registerPendingUpload(uploadId, actualId);
  }

  /// Rollback a failed message
  void rollbackWithNewArchitecture(String tempId) {
    _newArchAdapter?.rollback(tempId);
  }

  // =================== Cleanup ===================

  /// Dispose the new architecture resources
  void disposeNewArchitectureMixin() {
    _newArchAdapter?.dispose();
    _newArchAdapter = null;

    if (kDebugMode) {
      print('🧹 NewArchitectureMixin disposed');
    }
  }
}

/// Helper class for migration statistics and debugging
class NewArchitectureStats {
  static int _newArchCalls = 0;
  static int _legacyCalls = 0;
  static int _fallbackCalls = 0;

  static void recordNewArchCall() => _newArchCalls++;
  static void recordLegacyCall() => _legacyCalls++;
  static void recordFallbackCall() => _fallbackCalls++;

  static Map<String, int> get stats => {
    'newArchCalls': _newArchCalls,
    'legacyCalls': _legacyCalls,
    'fallbackCalls': _fallbackCalls,
    'totalCalls': _newArchCalls + _legacyCalls + _fallbackCalls,
  };

  static void printStats() {
    if (kDebugMode) {
      print('📊 New Architecture Migration Stats:');
      print('   New Architecture: $_newArchCalls calls');
      print('   Legacy: $_legacyCalls calls');
      print('   Fallbacks: $_fallbackCalls calls');
    }
  }

  static void reset() {
    _newArchCalls = 0;
    _legacyCalls = 0;
    _fallbackCalls = 0;
  }
}

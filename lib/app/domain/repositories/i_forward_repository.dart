import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/app/domain/core/result.dart';

/// Result of a forward operation
class ForwardResult {
  /// The ID of the newly created forwarded message
  final String messageId;

  /// The room ID where the message was forwarded to
  final String targetRoomId;

  /// Whether a new room was created for this forward
  final bool newRoomCreated;

  const ForwardResult({
    required this.messageId,
    required this.targetRoomId,
    this.newRoomCreated = false,
  });
}

/// Result of a batch forward operation
class BatchForwardResult {
  /// Successfully forwarded messages
  final List<ForwardResult> successful;

  /// Failed forwards with error messages
  final Map<String, String> failed;

  /// Total count of messages attempted
  int get totalAttempted => successful.length + failed.length;

  /// Success rate as percentage
  double get successRate =>
      totalAttempted > 0 ? (successful.length / totalAttempted) * 100 : 0;

  const BatchForwardResult({
    required this.successful,
    required this.failed,
  });

  /// Check if all forwards succeeded
  bool get allSucceeded => failed.isEmpty;

  /// Check if any forwards succeeded
  bool get anySucceeded => successful.isNotEmpty;
}

/// Forward options for customizing forward behavior
class ForwardOptions {
  /// Whether to include original sender attribution
  final bool includeAttribution;

  /// Whether to strip media (forward as text description only)
  final bool stripMedia;

  /// Custom forward message prefix
  final String? customPrefix;

  const ForwardOptions({
    this.includeAttribution = true,
    this.stripMedia = false,
    this.customPrefix,
  });

  static const ForwardOptions defaultOptions = ForwardOptions();
}

/// Abstract interface for message forwarding repository
///
/// Handles all message forwarding operations with:
/// - Single and batch forwarding
/// - Privacy validation
/// - Rate limiting support
/// - Event emission for real-time updates
abstract class IForwardRepository {
  // =================== Core Operations ===================

  /// Forward a single message to a target room
  ///
  /// If [targetRoomId] is null and [targetUserId] is provided,
  /// creates or finds an existing private chat with that user.
  ///
  /// Validates:
  /// - Message exists and is not pending
  /// - User has permission to forward (privacy settings)
  /// - Target room/user exists
  /// - Rate limits not exceeded
  ///
  /// Emits MessageForwardedEvent on success
  Future<Result<ForwardResult, RepositoryError>> forwardMessage({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  });

  /// Forward multiple messages to a single target
  ///
  /// Messages are forwarded in order (oldest first).
  /// Continues on individual failures, returns batch result.
  Future<Result<BatchForwardResult, RepositoryError>> forwardMessages({
    required String sourceRoomId,
    required List<Message> messages,
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  });

  /// Forward a single message to multiple targets
  ///
  /// Useful for "share to multiple chats" feature.
  Future<Result<BatchForwardResult, RepositoryError>> forwardToMultiple({
    required String sourceRoomId,
    required Message message,
    required String currentUserId,
    required List<String> targetRoomIds,
    ForwardOptions options = ForwardOptions.defaultOptions,
  });

  // =================== Validation ===================

  /// Check if a message can be forwarded by the current user
  ///
  /// Checks:
  /// - Message is not pending
  /// - Original sender allows forwarding (privacy settings)
  /// - Message type supports forwarding
  Future<Result<bool, RepositoryError>> canForwardMessage({
    required String roomId,
    required String messageId,
    required String currentUserId,
  });

  /// Check if user can forward to a specific target
  ///
  /// Checks:
  /// - Target exists and is accessible
  /// - User is not blocked by target
  /// - User has permission to send to target
  Future<Result<bool, RepositoryError>> canForwardToTarget({
    required String currentUserId,
    String? targetRoomId,
    String? targetUserId,
  });

  // =================== Helper Operations ===================

  /// Get or create a private chat room with a user
  ///
  /// Used when forwarding to a user (not a room).
  /// Returns existing room ID if found, creates new if not.
  Future<Result<String, RepositoryError>> getOrCreatePrivateRoom({
    required String currentUserId,
    required String targetUserId,
  });

  /// Create a forwarded copy of a message
  ///
  /// Returns a new Message instance with:
  /// - New ID (empty for Firestore to assign)
  /// - Current timestamp
  /// - isForwarded = true
  /// - forwardedFrom = original sender ID
  Message createForwardedMessage({
    required Message original,
    required String forwarderId,
    ForwardOptions options = ForwardOptions.defaultOptions,
  });
}

/// Message types that support forwarding
const Set<String> kForwardableMessageTypes = {
  'text',
  'photo',
  'video',
  'audio',
  'file',
  'location',
  'contact',
  'poll',
  'event',
  'sticker',
  'gif',
};

/// Message types that cannot be forwarded
const Set<String> kNonForwardableMessageTypes = {
  'call', // Call messages are contextual
  'system', // System messages are contextual
};

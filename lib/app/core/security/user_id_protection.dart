import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// SEC-003: User ID Exposure Mitigation
/// Provides utilities to hash and obfuscate user IDs in client-visible contexts
/// while maintaining functionality for server-side operations

class UserIdProtection {
  static final UserIdProtection instance = UserIdProtection._();
  UserIdProtection._();

  final _logger = LoggerService.instance;

  // Salt for hashing (should be stored securely in production)
  static const String _salt = 'crypted_app_user_salt_v1';

  // Cache for ID mappings (userId -> publicId)
  final Map<String, String> _publicIdCache = {};

  // Reverse cache for lookups
  final Map<String, String> _reverseCache = {};

  /// Generate a public-facing ID from a private user ID
  /// This ID can be safely exposed in URLs, logs, etc.
  String toPublicId(String userId) {
    if (userId.isEmpty) return '';

    // Check cache first
    if (_publicIdCache.containsKey(userId)) {
      return _publicIdCache[userId]!;
    }

    // Generate hash-based public ID
    final bytes = utf8.encode('$_salt$userId');
    final digest = sha256.convert(bytes);
    final publicId = digest.toString().substring(0, 16);

    // Cache both directions
    _publicIdCache[userId] = publicId;
    _reverseCache[publicId] = userId;

    return publicId;
  }

  /// Look up the original user ID from a public ID
  /// Returns null if not found in cache
  String? fromPublicId(String publicId) {
    return _reverseCache[publicId];
  }

  /// Generate a temporary session-specific public ID
  /// This is more secure as it changes each session
  String toSessionPublicId(String userId, String sessionId) {
    if (userId.isEmpty) return '';

    final bytes = utf8.encode('$_salt$userId$sessionId');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Generate a room-scoped public ID
  /// Different rooms will have different public IDs for the same user
  String toRoomScopedId(String userId, String roomId) {
    if (userId.isEmpty) return '';

    final bytes = utf8.encode('$_salt$userId$roomId');
    final digest = sha256.convert(bytes);
    return 'u_${digest.toString().substring(0, 12)}';
  }

  /// Mask a user ID for display/logging
  /// Shows first and last 2 characters with asterisks in between
  String maskUserId(String userId) {
    if (userId.isEmpty) return '';
    if (userId.length <= 6) {
      return '${userId[0]}${'*' * (userId.length - 2)}${userId[userId.length - 1]}';
    }
    return '${userId.substring(0, 2)}${'*' * 8}${userId.substring(userId.length - 2)}';
  }

  /// Clear cached mappings
  void clearCache() {
    _publicIdCache.clear();
    _reverseCache.clear();
  }

  /// Generate a random anonymous ID for guests
  String generateAnonymousId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return 'anon_${base64Url.encode(bytes).substring(0, 16)}';
  }
}

/// User reference that can be safely serialized without exposing the real ID
class SafeUserReference {
  final String publicId;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? lastSeen;

  const SafeUserReference({
    required this.publicId,
    this.displayName,
    this.avatarUrl,
    this.lastSeen,
  });

  factory SafeUserReference.fromUserId(
    String userId, {
    String? displayName,
    String? avatarUrl,
    DateTime? lastSeen,
  }) {
    return SafeUserReference(
      publicId: UserIdProtection.instance.toPublicId(userId),
      displayName: displayName,
      avatarUrl: avatarUrl,
      lastSeen: lastSeen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publicId': publicId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
    };
  }

  factory SafeUserReference.fromMap(Map<String, dynamic> map) {
    return SafeUserReference(
      publicId: map['publicId'] ?? '',
      displayName: map['displayName'],
      avatarUrl: map['avatarUrl'],
      lastSeen: map['lastSeen'] != null
          ? DateTime.tryParse(map['lastSeen'])
          : null,
    );
  }
}

/// Mixin for classes that need user ID protection
mixin UserIdProtectionMixin {
  final _protection = UserIdProtection.instance;

  /// Get public ID for a user
  String getPublicId(String userId) => _protection.toPublicId(userId);

  /// Get masked ID for logging
  String getMaskedId(String userId) => _protection.maskUserId(userId);

  /// Create safe user reference
  SafeUserReference createSafeReference(
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) {
    return SafeUserReference.fromUserId(
      userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}

/// Extension for safe logging of user IDs
extension SafeUserIdLogging on String {
  /// Get a masked version for logging
  String get masked => UserIdProtection.instance.maskUserId(this);

  /// Get a public ID version
  String get publicId => UserIdProtection.instance.toPublicId(this);
}

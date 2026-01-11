import 'dart:math';

/// DATA-006: Standardized Message ID Generation
/// Provides consistent message ID generation across the app
/// Supports various ID formats for different use cases

class MessageIdGenerator {
  static final MessageIdGenerator instance = MessageIdGenerator._();
  MessageIdGenerator._();

  final Random _random = Random.secure();

  // Counter for additional uniqueness within millisecond
  int _counter = 0;
  int _lastTimestamp = 0;

  /// Generate a unique message ID
  /// Format: {timestamp}-{counter}-{random}
  String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Reset counter if new millisecond
    if (timestamp != _lastTimestamp) {
      _counter = 0;
      _lastTimestamp = timestamp;
    } else {
      _counter++;
    }

    final random = _generateRandomPart(6);
    return '${timestamp.toRadixString(36)}-${_counter.toRadixString(36)}-$random';
  }

  /// Generate a temporary ID for optimistic updates
  /// Prefix with 'temp_' for easy identification
  String generateTempId() {
    return 'temp_${generate()}';
  }

  /// Generate a client-side ID with user prefix
  /// Format: {userId prefix}-{timestamp}-{random}
  String generateWithUser(String userId) {
    final userPrefix = userId.length > 4 ? userId.substring(0, 4) : userId;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = _generateRandomPart(4);
    return '$userPrefix-$timestamp-$random';
  }

  /// Generate a room-scoped ID
  /// Format: {roomId prefix}-{timestamp}-{random}
  String generateForRoom(String roomId) {
    final roomPrefix = roomId.length > 4 ? roomId.substring(0, 4) : roomId;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = _generateRandomPart(4);
    return '$roomPrefix-$timestamp-$random';
  }

  /// Generate a sortable ID (lexicographically sortable by time)
  /// Format: {padded timestamp}-{random}
  String generateSortable() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final paddedTimestamp = timestamp.toString().padLeft(15, '0');
    final random = _generateRandomPart(8);
    return '$paddedTimestamp-$random';
  }

  /// Generate a short ID for display purposes
  /// Not guaranteed unique across long time periods
  String generateShortId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final random = _generateRandomPart(4);
    return '${timestamp.toRadixString(36)}$random';
  }

  /// Generate a UUID-like ID
  /// Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  String generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  /// Check if an ID is a temporary ID
  bool isTempId(String id) {
    return id.startsWith('temp_');
  }

  /// Convert temp ID to permanent ID
  String tempToPermanent(String tempId, String permanentId) {
    return permanentId;
  }

  /// Extract timestamp from a generated ID
  DateTime? extractTimestamp(String id) {
    try {
      // Try to parse the first part as base36 timestamp
      final parts = id.split('-');
      if (parts.isEmpty) return null;

      // Handle temp_ prefix
      var timestampPart = parts[0];
      if (timestampPart.startsWith('temp_')) {
        timestampPart = parts[1];
      }

      // Try base36 first (our format)
      final timestamp = int.tryParse(timestampPart, radix: 36);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Try decimal (sortable format)
      final decimalTimestamp = int.tryParse(timestampPart);
      if (decimalTimestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(decimalTimestamp);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate ID format
  bool isValidId(String id) {
    if (id.isEmpty) return false;

    // Check for temp ID
    if (isTempId(id)) {
      return id.length > 5; // 'temp_' + at least 1 char
    }

    // Check for valid characters
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  }

  /// Compare IDs for ordering
  int compare(String id1, String id2) {
    final time1 = extractTimestamp(id1);
    final time2 = extractTimestamp(id2);

    if (time1 != null && time2 != null) {
      return time1.compareTo(time2);
    }

    // Fall back to string comparison
    return id1.compareTo(id2);
  }

  /// Generate random alphanumeric string
  String _generateRandomPart(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

/// ID types for different use cases
enum IdType {
  /// Standard unique ID
  standard,

  /// Temporary ID for optimistic updates
  temporary,

  /// User-scoped ID
  userScoped,

  /// Room-scoped ID
  roomScoped,

  /// Sortable ID for ordered queries
  sortable,

  /// Short ID for display
  short,

  /// UUID format
  uuid,
}

/// ID generator factory
class IdFactory {
  static String generate({
    IdType type = IdType.standard,
    String? userId,
    String? roomId,
  }) {
    final generator = MessageIdGenerator.instance;

    switch (type) {
      case IdType.standard:
        return generator.generate();
      case IdType.temporary:
        return generator.generateTempId();
      case IdType.userScoped:
        return generator.generateWithUser(userId ?? 'unknown');
      case IdType.roomScoped:
        return generator.generateForRoom(roomId ?? 'unknown');
      case IdType.sortable:
        return generator.generateSortable();
      case IdType.short:
        return generator.generateShortId();
      case IdType.uuid:
        return generator.generateUuid();
    }
  }
}

/// Extension for ID operations
extension MessageIdExtension on String {
  /// Check if this is a temporary ID
  bool get isTempMessageId => MessageIdGenerator.instance.isTempId(this);

  /// Check if this is a valid message ID
  bool get isValidMessageId => MessageIdGenerator.instance.isValidId(this);

  /// Extract timestamp from this ID
  DateTime? get messageIdTimestamp =>
      MessageIdGenerator.instance.extractTimestamp(this);
}

/// Mixin for classes that need ID generation
mixin MessageIdMixin {
  final _idGenerator = MessageIdGenerator.instance;

  /// Generate a new message ID
  String generateMessageId() => _idGenerator.generate();

  /// Generate a temporary message ID
  String generateTempMessageId() => _idGenerator.generateTempId();

  /// Check if ID is temporary
  bool isTemporaryId(String id) => _idGenerator.isTempId(id);
}

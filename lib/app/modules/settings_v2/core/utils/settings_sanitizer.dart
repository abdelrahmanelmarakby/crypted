/// Data sanitization utilities for settings
///
/// Provides deep sanitization of settings data before persistence
/// to prevent injection attacks and data corruption.

import 'dart:convert';
import 'dart:developer' as developer;

/// Sanitizer for settings data
class SettingsSanitizer {
  /// Maximum depth for nested object sanitization
  static const int maxDepth = 10;

  /// Maximum string length before truncation
  static const int maxStringLength = 10000;

  /// Sanitize a complete settings map
  static Map<String, dynamic> sanitizeSettings(
    Map<String, dynamic>? input, {
    int currentDepth = 0,
  }) {
    if (input == null) return {};
    if (currentDepth > maxDepth) {
      developer.log(
        'Max sanitization depth exceeded, truncating',
        name: 'SettingsSanitizer',
      );
      return {};
    }

    final result = <String, dynamic>{};

    for (final entry in input.entries) {
      final sanitizedKey = sanitizeKey(entry.key);
      if (sanitizedKey == null) continue;

      final sanitizedValue = sanitizeValue(
        entry.value,
        currentDepth: currentDepth,
      );

      if (sanitizedValue != null) {
        result[sanitizedKey] = sanitizedValue;
      }
    }

    return result;
  }

  /// Sanitize a map key
  static String? sanitizeKey(String? key) {
    if (key == null || key.isEmpty) return null;

    // Remove null bytes and control characters
    var sanitized = key.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Limit key length
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }

    // Don't allow keys starting with $ (Firestore reserved)
    if (sanitized.startsWith('\$')) {
      sanitized = '_${sanitized.substring(1)}';
    }

    // Don't allow keys with dots (Firestore path separator)
    sanitized = sanitized.replaceAll('.', '_');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize a value based on its type
  static dynamic sanitizeValue(
    dynamic value, {
    int currentDepth = 0,
  }) {
    if (value == null) return null;

    if (value is String) {
      return sanitizeString(value);
    }

    if (value is num) {
      return sanitizeNumber(value);
    }

    if (value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is List) {
      return sanitizeList(value, currentDepth: currentDepth);
    }

    if (value is Map<String, dynamic>) {
      return sanitizeSettings(value, currentDepth: currentDepth + 1);
    }

    if (value is Map) {
      // Convert to Map<String, dynamic>
      final converted = <String, dynamic>{};
      for (final entry in value.entries) {
        converted[entry.key.toString()] = entry.value;
      }
      return sanitizeSettings(converted, currentDepth: currentDepth + 1);
    }

    // Unknown type - try to convert to string
    try {
      return sanitizeString(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Sanitize a string value
  static String sanitizeString(String input) {
    // Remove null bytes
    var sanitized = input.replaceAll('\x00', '');

    // Remove other dangerous control characters but keep newlines and tabs
    sanitized = sanitized.replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Limit length
    if (sanitized.length > maxStringLength) {
      sanitized = sanitized.substring(0, maxStringLength);
    }

    // Normalize Unicode to NFC form
    // Note: Dart's built-in normalization is limited, but we can at least
    // handle some common cases
    sanitized = _normalizeUnicode(sanitized);

    return sanitized;
  }

  /// Sanitize a number value
  static num sanitizeNumber(num input) {
    if (input.isNaN || input.isInfinite) {
      return 0;
    }
    return input;
  }

  /// Sanitize a list
  static List<dynamic> sanitizeList(
    List<dynamic> input, {
    int currentDepth = 0,
  }) {
    if (currentDepth > maxDepth) {
      return [];
    }

    // Limit list size
    const maxListSize = 1000;
    final limitedInput = input.length > maxListSize
        ? input.sublist(0, maxListSize)
        : input;

    return limitedInput
        .map((item) => sanitizeValue(item, currentDepth: currentDepth + 1))
        .where((item) => item != null)
        .toList();
  }

  /// Normalize Unicode string (basic implementation)
  static String _normalizeUnicode(String input) {
    // Remove zero-width characters that could be used for obfuscation
    return input.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
  }

  /// Sanitize user ID
  static String? sanitizeUserId(String? userId) {
    if (userId == null || userId.isEmpty) return null;

    // Firebase UIDs are typically alphanumeric with some special chars
    final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-:.]'), '');

    if (sanitized.length > 128) {
      return sanitized.substring(0, 128);
    }

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitize email address
  static String? sanitizeEmail(String? email) {
    if (email == null || email.isEmpty) return null;

    var sanitized = email.trim().toLowerCase();

    // Remove any characters that aren't valid in emails
    sanitized = sanitized.replaceAll(RegExp(r'[^\w.@+\-]'), '');

    if (sanitized.length > 254) {
      return null; // Email too long
    }

    // Basic email format check
    if (!sanitized.contains('@') || !sanitized.contains('.')) {
      return null;
    }

    return sanitized;
  }

  /// Create a safe copy of settings for logging (masks sensitive data)
  static Map<String, dynamic> maskSensitiveData(Map<String, dynamic> settings) {
    final masked = Map<String, dynamic>.from(settings);

    // List of sensitive field patterns
    final sensitivePatterns = [
      'password',
      'pin',
      'secret',
      'token',
      'key',
      'email',
      'phone',
      'recoveryEmail',
    ];

    void maskRecursive(Map<String, dynamic> map) {
      for (final key in map.keys.toList()) {
        final lowerKey = key.toLowerCase();

        if (sensitivePatterns.any((p) => lowerKey.contains(p))) {
          if (map[key] is String) {
            final value = map[key] as String;
            map[key] = value.isNotEmpty ? '***MASKED***' : '';
          }
        } else if (map[key] is Map<String, dynamic>) {
          maskRecursive(map[key] as Map<String, dynamic>);
        } else if (map[key] is List) {
          final list = map[key] as List;
          for (var i = 0; i < list.length; i++) {
            if (list[i] is Map<String, dynamic>) {
              maskRecursive(list[i] as Map<String, dynamic>);
            }
          }
        }
      }
    }

    maskRecursive(masked);
    return masked;
  }
}

/// JSON sanitization utilities
class JsonSanitizer {
  /// Safely parse JSON with depth limit
  static Map<String, dynamic>? safeParseJson(
    String? jsonString, {
    int maxDepth = 10,
  }) {
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;

      // Check depth
      if (!_checkDepth(decoded, maxDepth, 0)) {
        developer.log(
          'JSON exceeds max depth of $maxDepth',
          name: 'JsonSanitizer',
        );
        return null;
      }

      return SettingsSanitizer.sanitizeSettings(decoded);
    } catch (e) {
      developer.log(
        'Failed to parse JSON',
        name: 'JsonSanitizer',
        error: e,
      );
      return null;
    }
  }

  static bool _checkDepth(dynamic value, int maxDepth, int currentDepth) {
    if (currentDepth > maxDepth) return false;

    if (value is Map) {
      for (final v in value.values) {
        if (!_checkDepth(v, maxDepth, currentDepth + 1)) return false;
      }
    } else if (value is List) {
      for (final item in value) {
        if (!_checkDepth(item, maxDepth, currentDepth + 1)) return false;
      }
    }

    return true;
  }

  /// Safely encode to JSON with error handling
  static String? safeToJson(Map<String, dynamic>? data) {
    if (data == null) return null;

    try {
      final sanitized = SettingsSanitizer.sanitizeSettings(data);
      return json.encode(sanitized);
    } catch (e) {
      developer.log(
        'Failed to encode JSON',
        name: 'JsonSanitizer',
        error: e,
      );
      return null;
    }
  }
}

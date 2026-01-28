/// Validation utilities for settings
///
/// Provides input validation, sanitization, and data integrity checks
/// for notification and privacy settings.
library;

import 'dart:developer' as developer;

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedValue;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.sanitizedValue,
  });

  factory ValidationResult.valid({String? sanitizedValue}) {
    return ValidationResult._(
      isValid: true,
      sanitizedValue: sanitizedValue,
    );
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}

/// Validation result for typed values
class TypedValidationResult<T> {
  final bool isValid;
  final String? errorMessage;
  final T? value;

  const TypedValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.value,
  });

  factory TypedValidationResult.valid(T value) {
    return TypedValidationResult._(
      isValid: true,
      value: value,
    );
  }

  factory TypedValidationResult.invalid(String message) {
    return TypedValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}

/// Settings validation utilities
class SettingsValidator {
  // Maximum lengths for string fields
  static const int maxEmailLength = 254;
  static const int maxUserIdLength = 128;
  static const int maxChatIdLength = 128;
  static const int maxScheduleNameLength = 50;
  static const int maxSoundNameLength = 100;
  static const int maxMetadataValueLength = 1000;

  // Maximum collection sizes
  static const int maxBlockedUsers = 1000;
  static const int maxExceptionContacts = 500;
  static const int maxDndSchedules = 20;
  static const int maxLockedChats = 100;
  static const int maxSecurityLogEntries = 100;

  /// Validate email format
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.valid();
    }

    final trimmed = email.trim().toLowerCase();

    if (trimmed.length > maxEmailLength) {
      return ValidationResult.invalid(
        'Email exceeds maximum length of $maxEmailLength characters',
      );
    }

    // RFC 5322 compliant email regex (simplified)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return ValidationResult.invalid('Invalid email format');
    }

    return ValidationResult.valid(sanitizedValue: trimmed);
  }

  /// Validate user ID format
  static ValidationResult validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      return ValidationResult.invalid('User ID is required');
    }

    final trimmed = userId.trim();

    if (trimmed.length > maxUserIdLength) {
      return ValidationResult.invalid(
        'User ID exceeds maximum length of $maxUserIdLength characters',
      );
    }

    // Firebase UID format: alphanumeric with some special chars
    final userIdRegex = RegExp(r'^[a-zA-Z0-9_\-:.]+$');
    if (!userIdRegex.hasMatch(trimmed)) {
      return ValidationResult.invalid('Invalid user ID format');
    }

    return ValidationResult.valid(sanitizedValue: trimmed);
  }

  /// Validate chat ID format
  static ValidationResult validateChatId(String? chatId) {
    if (chatId == null || chatId.isEmpty) {
      return ValidationResult.invalid('Chat ID is required');
    }

    final trimmed = chatId.trim();

    if (trimmed.length > maxChatIdLength) {
      return ValidationResult.invalid(
        'Chat ID exceeds maximum length of $maxChatIdLength characters',
      );
    }

    return ValidationResult.valid(sanitizedValue: trimmed);
  }

  /// Validate schedule name
  static ValidationResult validateScheduleName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.invalid('Schedule name is required');
    }

    final trimmed = name.trim();

    if (trimmed.length > maxScheduleNameLength) {
      return ValidationResult.invalid(
        'Schedule name exceeds maximum length of $maxScheduleNameLength characters',
      );
    }

    // Remove potentially dangerous characters
    final sanitized = _sanitizeText(trimmed);

    return ValidationResult.valid(sanitizedValue: sanitized);
  }

  /// Validate time of day for schedules
  static TypedValidationResult<Duration> validateTimeOfDay(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      return TypedValidationResult.invalid('Hour must be between 0 and 23');
    }

    if (minute < 0 || minute > 59) {
      return TypedValidationResult.invalid('Minute must be between 0 and 59');
    }

    return TypedValidationResult.valid(
      Duration(hours: hour, minutes: minute),
    );
  }

  /// Validate schedule time range
  static ValidationResult validateScheduleTimeRange(
    Duration startTime,
    Duration endTime,
  ) {
    // Allow overnight schedules (start > end means next day)
    // Just ensure both are valid durations within 24 hours
    if (startTime.inMinutes < 0 || startTime.inMinutes >= 24 * 60) {
      return ValidationResult.invalid('Invalid start time');
    }

    if (endTime.inMinutes < 0 || endTime.inMinutes >= 24 * 60) {
      return ValidationResult.invalid('Invalid end time');
    }

    return ValidationResult.valid();
  }

  /// Validate weekdays list
  static TypedValidationResult<List<int>> validateWeekdays(List<int>? days) {
    if (days == null || days.isEmpty) {
      return TypedValidationResult.invalid('At least one weekday must be selected');
    }

    final validDays = days.where((d) => d >= 1 && d <= 7).toSet().toList();
    validDays.sort();

    if (validDays.length != days.length) {
      developer.log(
        'Invalid weekdays filtered out',
        name: 'SettingsValidator',
      );
    }

    if (validDays.isEmpty) {
      return TypedValidationResult.invalid('No valid weekdays provided');
    }

    return TypedValidationResult.valid(validDays);
  }

  /// Validate blocked users list size
  static ValidationResult validateBlockedUsersCount(int count) {
    if (count > maxBlockedUsers) {
      return ValidationResult.invalid(
        'Maximum of $maxBlockedUsers blocked users allowed',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate exception contacts list size
  static ValidationResult validateExceptionContactsCount(int count) {
    if (count > maxExceptionContacts) {
      return ValidationResult.invalid(
        'Maximum of $maxExceptionContacts exception contacts allowed',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate DND schedules count
  static ValidationResult validateDndSchedulesCount(int count) {
    if (count > maxDndSchedules) {
      return ValidationResult.invalid(
        'Maximum of $maxDndSchedules DND schedules allowed',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate locked chats count
  static ValidationResult validateLockedChatsCount(int count) {
    if (count > maxLockedChats) {
      return ValidationResult.invalid(
        'Maximum of $maxLockedChats locked chats allowed',
      );
    }
    return ValidationResult.valid();
  }

  /// Validate mute duration
  static TypedValidationResult<DateTime?> validateMuteUntil(DateTime? muteUntil) {
    if (muteUntil == null) {
      return TypedValidationResult.valid(muteUntil);
    }

    final now = DateTime.now();

    // Mute until must be in the future
    if (muteUntil.isBefore(now)) {
      return TypedValidationResult.invalid('Mute end time must be in the future');
    }

    // Maximum mute duration: 1 year
    final maxMuteDate = now.add(const Duration(days: 365));
    if (muteUntil.isAfter(maxMuteDate)) {
      return TypedValidationResult.invalid('Mute duration cannot exceed 1 year');
    }

    return TypedValidationResult.valid(muteUntil);
  }

  /// Validate sound configuration
  static ValidationResult validateSoundName(String? soundName) {
    if (soundName == null || soundName.isEmpty) {
      return ValidationResult.valid(); // Default sound is OK
    }

    final trimmed = soundName.trim();

    if (trimmed.length > maxSoundNameLength) {
      return ValidationResult.invalid(
        'Sound name exceeds maximum length of $maxSoundNameLength characters',
      );
    }

    // Only allow alphanumeric, spaces, and basic punctuation
    final sanitized = _sanitizeText(trimmed);

    return ValidationResult.valid(sanitizedValue: sanitized);
  }

  /// Validate metadata map
  static TypedValidationResult<Map<String, dynamic>> validateMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null || metadata.isEmpty) {
      return TypedValidationResult.valid({});
    }

    final sanitized = <String, dynamic>{};

    for (final entry in metadata.entries) {
      // Validate key
      if (entry.key.length > 100) {
        continue; // Skip overly long keys
      }

      final sanitizedKey = _sanitizeText(entry.key);

      // Validate value based on type
      if (entry.value is String) {
        final stringValue = entry.value as String;
        if (stringValue.length > maxMetadataValueLength) {
          sanitized[sanitizedKey] = stringValue.substring(0, maxMetadataValueLength);
        } else {
          sanitized[sanitizedKey] = _sanitizeText(stringValue);
        }
      } else if (entry.value is num || entry.value is bool) {
        sanitized[sanitizedKey] = entry.value;
      }
      // Skip complex nested objects for safety
    }

    return TypedValidationResult.valid(sanitized);
  }

  /// Sanitize text by removing potentially dangerous characters
  static String _sanitizeText(String input) {
    // Remove null bytes and control characters except newlines and tabs
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
}

/// Data integrity checker for settings
class SettingsIntegrityChecker {
  /// Check notification settings integrity
  static List<String> checkNotificationSettingsIntegrity(
    Map<String, dynamic> settingsMap,
  ) {
    final issues = <String>[];

    // Check required fields exist
    final requiredFields = ['global', 'messages', 'groups', 'calls', 'dnd'];
    for (final field in requiredFields) {
      if (!settingsMap.containsKey(field)) {
        issues.add('Missing required field: $field');
      }
    }

    // Check DND schedules validity
    final dnd = settingsMap['dnd'] as Map<String, dynamic>?;
    if (dnd != null) {
      final schedules = dnd['schedules'] as List<dynamic>?;
      if (schedules != null && schedules.length > SettingsValidator.maxDndSchedules) {
        issues.add('Too many DND schedules (max: ${SettingsValidator.maxDndSchedules})');
      }
    }

    return issues;
  }

  /// Check privacy settings integrity
  static List<String> checkPrivacySettingsIntegrity(
    Map<String, dynamic> settingsMap,
  ) {
    final issues = <String>[];

    // Check required fields exist
    final requiredFields = ['profileVisibility', 'communication', 'security'];
    for (final field in requiredFields) {
      if (!settingsMap.containsKey(field)) {
        issues.add('Missing required field: $field');
      }
    }

    // Check blocked users count
    final blockedUsers = settingsMap['blockedUsers'] as List<dynamic>?;
    if (blockedUsers != null && blockedUsers.length > SettingsValidator.maxBlockedUsers) {
      issues.add('Too many blocked users (max: ${SettingsValidator.maxBlockedUsers})');
    }

    // Check security settings
    final security = settingsMap['security'] as Map<String, dynamic>?;
    if (security != null) {
      final lockedChats = security['lockedChats'] as List<dynamic>?;
      if (lockedChats != null && lockedChats.length > SettingsValidator.maxLockedChats) {
        issues.add('Too many locked chats (max: ${SettingsValidator.maxLockedChats})');
      }
    }

    return issues;
  }

  /// Repair notification settings by filling missing fields with defaults
  static Map<String, dynamic> repairNotificationSettings(
    Map<String, dynamic> settingsMap,
    Map<String, dynamic> defaults,
  ) {
    final repaired = Map<String, dynamic>.from(defaults);

    // Merge existing valid values
    for (final entry in settingsMap.entries) {
      if (repaired.containsKey(entry.key) && entry.value != null) {
        if (entry.value is Map<String, dynamic> && repaired[entry.key] is Map<String, dynamic>) {
          // Recursively merge nested maps
          repaired[entry.key] = _mergeMap(
            repaired[entry.key] as Map<String, dynamic>,
            entry.value as Map<String, dynamic>,
          );
        } else {
          repaired[entry.key] = entry.value;
        }
      }
    }

    return repaired;
  }

  static Map<String, dynamic> _mergeMap(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
  ) {
    final result = Map<String, dynamic>.from(base);
    for (final entry in overlay.entries) {
      if (result.containsKey(entry.key) && entry.value != null) {
        if (entry.value is Map<String, dynamic> && result[entry.key] is Map<String, dynamic>) {
          result[entry.key] = _mergeMap(
            result[entry.key] as Map<String, dynamic>,
            entry.value as Map<String, dynamic>,
          );
        } else {
          result[entry.key] = entry.value;
        }
      }
    }
    return result;
  }
}

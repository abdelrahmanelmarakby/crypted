/// Validated settings wrappers
///
/// Provides type-safe, validated wrappers around settings operations
/// to ensure data integrity before persistence.
library;

import 'dart:developer' as developer;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:crypted_app/app/modules/settings_v2/core/models/notification_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/validation.dart';
import 'package:crypted_app/app/modules/settings_v2/core/utils/settings_sanitizer.dart';

/// Result of a validated operation
class ValidatedResult<T> {
  final bool isValid;
  final T? value;
  final List<String> errors;
  final List<String> warnings;

  const ValidatedResult._({
    required this.isValid,
    this.value,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidatedResult.success(T value, {List<String>? warnings}) {
    return ValidatedResult._(
      isValid: true,
      value: value,
      warnings: warnings ?? [],
    );
  }

  factory ValidatedResult.failure(List<String> errors, {List<String>? warnings}) {
    return ValidatedResult._(
      isValid: false,
      errors: errors,
      warnings: warnings ?? [],
    );
  }

  /// Log validation result
  void log(String operation) {
    if (!isValid) {
      developer.log(
        '$operation validation failed: ${errors.join(", ")}',
        name: 'ValidatedSettings',
      );
    } else if (warnings.isNotEmpty) {
      developer.log(
        '$operation completed with warnings: ${warnings.join(", ")}',
        name: 'ValidatedSettings',
      );
    }
  }
}

/// Validated notification settings operations
class ValidatedNotificationSettings {
  /// Validate and create a chat notification override
  static ValidatedResult<ChatNotificationOverride> createChatOverride({
    required String chatId,
    required bool enabled,
    DateTime? mutedUntil,
    SoundConfig? customSound,
    VibrationPattern? customVibration,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate chat ID
    final chatIdResult = SettingsValidator.validateChatId(chatId);
    if (!chatIdResult.isValid) {
      errors.add(chatIdResult.errorMessage!);
    }

    // Validate mute until if provided
    DateTime? validatedMuteUntil = mutedUntil;
    if (mutedUntil != null) {
      final muteResult = SettingsValidator.validateMuteUntil(mutedUntil);
      if (!muteResult.isValid) {
        errors.add(muteResult.errorMessage!);
      } else {
        validatedMuteUntil = muteResult.value;
      }
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    final now = DateTime.now();
    return ValidatedResult.success(
      ChatNotificationOverride(
        chatId: chatIdResult.sanitizedValue ?? chatId,
        enabled: enabled,
        mutedUntil: validatedMuteUntil,
        sound: customSound,
        vibration: customVibration,
        createdAt: now,
        updatedAt: now,
      ),
      warnings: warnings,
    );
  }

  /// Validate and create a DND schedule
  static ValidatedResult<DNDSchedule> createDNDSchedule({
    required String id,
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<int> daysOfWeek,
    List<String>? allowedContacts,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate name
    final nameResult = SettingsValidator.validateScheduleName(name);
    if (!nameResult.isValid) {
      errors.add(nameResult.errorMessage!);
    }

    // Validate time range using Duration for validation
    final startDuration = Duration(hours: startTime.hour, minutes: startTime.minute);
    final endDuration = Duration(hours: endTime.hour, minutes: endTime.minute);
    final timeResult = SettingsValidator.validateScheduleTimeRange(startDuration, endDuration);
    if (!timeResult.isValid) {
      errors.add(timeResult.errorMessage!);
    }

    // Validate weekdays
    final weekdaysResult = SettingsValidator.validateWeekdays(daysOfWeek);
    if (!weekdaysResult.isValid) {
      errors.add(weekdaysResult.errorMessage!);
    }

    // Validate allowed contacts count
    if (allowedContacts != null) {
      final contactsResult = SettingsValidator.validateExceptionContactsCount(
        allowedContacts.length,
      );
      if (!contactsResult.isValid) {
        errors.add(contactsResult.errorMessage!);
      }
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    return ValidatedResult.success(
      DNDSchedule(
        id: id,
        name: nameResult.sanitizedValue ?? name,
        enabled: true,
        startTime: startTime,
        endTime: endTime,
        daysOfWeek: weekdaysResult.value ?? daysOfWeek,
        allowedContacts: allowedContacts ?? [],
      ),
      warnings: warnings,
    );
  }

  /// Validate notification settings before save
  static ValidatedResult<Map<String, dynamic>> validateForSave(
    EnhancedNotificationSettingsModel settings,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate DND schedules count
    final schedulesResult = SettingsValidator.validateDndSchedulesCount(
      settings.dnd.schedules.length,
    );
    if (!schedulesResult.isValid) {
      errors.add(schedulesResult.errorMessage!);
    }

    // Check integrity
    final settingsMap = settings.toMap();
    final integrityIssues = SettingsIntegrityChecker.checkNotificationSettingsIntegrity(
      settingsMap,
    );
    if (integrityIssues.isNotEmpty) {
      warnings.addAll(integrityIssues);
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    // Sanitize before returning
    final sanitized = SettingsSanitizer.sanitizeSettings(settingsMap);
    return ValidatedResult.success(sanitized, warnings: warnings);
  }
}

/// Validated privacy settings operations
class ValidatedPrivacySettings {
  /// Validate and create a blocked user entry
  static ValidatedResult<BlockedUser> createBlockedUser({
    required String userId,
    required String displayName,
    String? photoUrl,
    String? reason,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate user ID
    final userIdResult = SettingsValidator.validateUserId(userId);
    if (!userIdResult.isValid) {
      errors.add(userIdResult.errorMessage!);
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    // Sanitize display name
    final sanitizedName = SettingsSanitizer.sanitizeString(displayName);
    final sanitizedPhotoUrl = photoUrl != null
        ? SettingsSanitizer.sanitizeString(photoUrl)
        : null;
    final sanitizedReason = reason != null
        ? SettingsSanitizer.sanitizeString(reason)
        : null;

    return ValidatedResult.success(
      BlockedUser(
        userId: userIdResult.sanitizedValue ?? userId,
        userName: sanitizedName,
        userPhotoUrl: sanitizedPhotoUrl,
        reason: sanitizedReason,
        blockedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }

  /// Validate and create a locked chat entry
  static ValidatedResult<LockedChat> createLockedChat({
    required String chatId,
    required String chatName,
    bool requireBiometric = false,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate chat ID
    final chatIdResult = SettingsValidator.validateChatId(chatId);
    if (!chatIdResult.isValid) {
      errors.add(chatIdResult.errorMessage!);
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    // Sanitize chat name
    final sanitizedName = SettingsSanitizer.sanitizeString(chatName);

    return ValidatedResult.success(
      LockedChat(
        chatId: chatIdResult.sanitizedValue ?? chatId,
        chatName: sanitizedName,
        requireBiometric: requireBiometric,
        lockedAt: DateTime.now(),
      ),
      warnings: warnings,
    );
  }

  /// Validate two-step verification setup
  static ValidatedResult<TwoStepVerificationSettings> validateTwoStepSetup({
    required bool enabled,
    String? recoveryEmail,
    String? hint,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate recovery email if provided
    String? validatedEmail;
    if (recoveryEmail != null && recoveryEmail.isNotEmpty) {
      final emailResult = SettingsValidator.validateEmail(recoveryEmail);
      if (!emailResult.isValid) {
        errors.add(emailResult.errorMessage!);
      } else {
        validatedEmail = emailResult.sanitizedValue;
      }
    }

    // Warn if enabling without recovery email
    if (enabled && (recoveryEmail == null || recoveryEmail.isEmpty)) {
      warnings.add('Two-step verification enabled without recovery email');
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    // Sanitize hint
    final sanitizedHint = hint != null
        ? SettingsSanitizer.sanitizeString(hint)
        : null;

    return ValidatedResult.success(
      TwoStepVerificationSettings(
        enabled: enabled,
        recoveryEmail: validatedEmail,
        emailVerified: false, // Must be verified separately
        hint: sanitizedHint,
      ),
      warnings: warnings,
    );
  }

  /// Validate privacy settings before save
  static ValidatedResult<Map<String, dynamic>> validateForSave(
    EnhancedPrivacySettingsModel settings,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate blocked users count
    final blockedResult = SettingsValidator.validateBlockedUsersCount(
      settings.blockedUsers.length,
    );
    if (!blockedResult.isValid) {
      errors.add(blockedResult.errorMessage!);
    }

    // Validate locked chats count
    final lockedChatsResult = SettingsValidator.validateLockedChatsCount(
      settings.security.lockedChats.length,
    );
    if (!lockedChatsResult.isValid) {
      errors.add(lockedChatsResult.errorMessage!);
    }

    // Check integrity
    final settingsMap = settings.toMap();
    final integrityIssues = SettingsIntegrityChecker.checkPrivacySettingsIntegrity(
      settingsMap,
    );
    if (integrityIssues.isNotEmpty) {
      warnings.addAll(integrityIssues);
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    // Sanitize before returning
    final sanitized = SettingsSanitizer.sanitizeSettings(settingsMap);
    return ValidatedResult.success(sanitized, warnings: warnings);
  }

  /// Validate a visibility setting change
  static ValidatedResult<VisibilitySettingWithExceptions> validateVisibilitySetting({
    required VisibilityLevel level,
    List<String>? exceptContacts,
    List<String>? onlyContacts,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate except contacts count
    if (exceptContacts != null) {
      final result = SettingsValidator.validateExceptionContactsCount(
        exceptContacts.length,
      );
      if (!result.isValid) {
        errors.add(result.errorMessage!);
      }

      // Validate each contact ID
      final validContacts = <String>[];
      for (final contactId in exceptContacts) {
        final contactResult = SettingsValidator.validateUserId(contactId);
        if (contactResult.isValid) {
          validContacts.add(contactResult.sanitizedValue ?? contactId);
        } else {
          warnings.add('Skipped invalid contact ID: $contactId');
        }
      }

      if (errors.isEmpty) {
        exceptContacts = validContacts;
      }
    }

    // Validate only contacts count
    if (onlyContacts != null) {
      final result = SettingsValidator.validateExceptionContactsCount(
        onlyContacts.length,
      );
      if (!result.isValid) {
        errors.add(result.errorMessage!);
      }

      // Validate each contact ID
      final validContacts = <String>[];
      for (final contactId in onlyContacts) {
        final contactResult = SettingsValidator.validateUserId(contactId);
        if (contactResult.isValid) {
          validContacts.add(contactResult.sanitizedValue ?? contactId);
        } else {
          warnings.add('Skipped invalid contact ID: $contactId');
        }
      }

      if (errors.isEmpty) {
        onlyContacts = validContacts;
      }
    }

    if (errors.isNotEmpty) {
      return ValidatedResult.failure(errors, warnings: warnings);
    }

    return ValidatedResult.success(
      VisibilitySettingWithExceptions(
        level: level,
        excludedUsers: (exceptContacts ?? []).map((id) => PrivacyException(
          userId: id,
          addedAt: DateTime.now(),
        )).toList(),
        includedUsers: (onlyContacts ?? []).map((id) => PrivacyException(
          userId: id,
          addedAt: DateTime.now(),
        )).toList(),
      ),
      warnings: warnings,
    );
  }
}

/// Extension to add validation to notification settings model
extension NotificationSettingsValidation on EnhancedNotificationSettingsModel {
  /// Validate the model and return any issues
  List<String> validate() {
    final issues = <String>[];

    // Check DND schedules
    final schedulesResult = SettingsValidator.validateDndSchedulesCount(
      dnd.schedules.length,
    );
    if (!schedulesResult.isValid) {
      issues.add(schedulesResult.errorMessage!);
    }

    // Check each schedule
    for (final schedule in dnd.schedules) {
      final nameResult = SettingsValidator.validateScheduleName(schedule.name);
      if (!nameResult.isValid) {
        issues.add('Schedule "${schedule.name}": ${nameResult.errorMessage}');
      }

      final weekdaysResult = SettingsValidator.validateWeekdays(schedule.weekdays);
      if (!weekdaysResult.isValid) {
        issues.add('Schedule "${schedule.name}": ${weekdaysResult.errorMessage}');
      }
    }

    return issues;
  }
}

/// Extension to add validation to privacy settings model
extension PrivacySettingsValidation on EnhancedPrivacySettingsModel {
  /// Validate the model and return any issues
  List<String> validate() {
    final issues = <String>[];

    // Check blocked users count
    final blockedResult = SettingsValidator.validateBlockedUsersCount(
      blockedUsers.length,
    );
    if (!blockedResult.isValid) {
      issues.add(blockedResult.errorMessage!);
    }

    // Check locked chats count
    final lockedResult = SettingsValidator.validateLockedChatsCount(
      security.lockedChats.length,
    );
    if (!lockedResult.isValid) {
      issues.add(lockedResult.errorMessage!);
    }

    // Validate recovery email if set
    if (security.twoStepVerification.recoveryEmail != null) {
      final emailResult = SettingsValidator.validateEmail(
        security.twoStepVerification.recoveryEmail,
      );
      if (!emailResult.isValid) {
        issues.add('Recovery email: ${emailResult.errorMessage}');
      }
    }

    return issues;
  }
}

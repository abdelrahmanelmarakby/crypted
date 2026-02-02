import 'package:crypted_app/app/core/constants/chat_constants.dart';
import 'package:crypted_app/app/core/services/premium_service.dart';

/// DATA-001: Message Validator
/// Validates message data before saving to Firestore
class MessageValidator {
  static final MessageValidator instance = MessageValidator._();
  MessageValidator._();

  /// Validate a text message
  ValidationResult validateTextMessage({
    required String text,
    required String senderId,
    required String roomId,
  }) {
    final errors = <String>[];

    // Validate text
    if (text.trim().isEmpty) {
      errors.add('Message text cannot be empty');
    }

    if (text.length > ChatConstants.maxMessageLength) {
      errors.add(
          'Message exceeds maximum length of ${ChatConstants.maxMessageLength} characters');
    }

    // Validate sender
    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    // Validate room
    if (roomId.isEmpty) {
      errors.add('Room ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate a media message (image, video, audio, file)
  ValidationResult validateMediaMessage({
    required String url,
    required String senderId,
    required String roomId,
    String? fileName,
    int? fileSize,
  }) {
    final errors = <String>[];

    // Validate URL
    if (url.isEmpty) {
      errors.add('Media URL is required');
    }

    if (!_isValidUrl(url)) {
      errors.add('Invalid media URL format');
    }

    // Validate file size (premium-aware)
    final maxSizeMB = PremiumService.instance.fileUploadLimitMB;
    if (fileSize != null && fileSize > maxSizeMB * 1024 * 1024) {
      errors.add('File size exceeds maximum of ${maxSizeMB}MB');
    }

    // Validate sender
    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    // Validate room
    if (roomId.isEmpty) {
      errors.add('Room ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate a poll message
  ValidationResult validatePollMessage({
    required String question,
    required List<String> options,
    required String senderId,
    required String roomId,
  }) {
    final errors = <String>[];

    // Validate question
    if (question.trim().isEmpty) {
      errors.add('Poll question is required');
    }

    if (question.length > 500) {
      errors.add('Poll question exceeds maximum length of 500 characters');
    }

    // Validate options
    if (options.length < ChatConstants.minPollOptions) {
      errors.add(
          'Poll must have at least ${ChatConstants.minPollOptions} options');
    }

    if (options.length > ChatConstants.maxPollOptions) {
      errors.add(
          'Poll cannot have more than ${ChatConstants.maxPollOptions} options');
    }

    for (int i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        errors.add('Option ${i + 1} cannot be empty');
      }
      if (options[i].length > 200) {
        errors.add('Option ${i + 1} exceeds maximum length of 200 characters');
      }
    }

    // Check for duplicate options
    final uniqueOptions = options.map((o) => o.trim().toLowerCase()).toSet();
    if (uniqueOptions.length != options.length) {
      errors.add('Poll options must be unique');
    }

    // Validate sender
    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    // Validate room
    if (roomId.isEmpty) {
      errors.add('Room ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate a location message
  ValidationResult validateLocationMessage({
    required double latitude,
    required double longitude,
    required String senderId,
    required String roomId,
  }) {
    final errors = <String>[];

    // Validate coordinates
    if (latitude < -90 || latitude > 90) {
      errors.add('Invalid latitude value');
    }

    if (longitude < -180 || longitude > 180) {
      errors.add('Invalid longitude value');
    }

    // Validate sender
    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    // Validate room
    if (roomId.isEmpty) {
      errors.add('Room ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate a contact message
  ValidationResult validateContactMessage({
    required String name,
    required String phoneNumber,
    required String senderId,
    required String roomId,
  }) {
    final errors = <String>[];

    // Validate name
    if (name.trim().isEmpty) {
      errors.add('Contact name is required');
    }

    if (name.length > 100) {
      errors.add('Contact name exceeds maximum length of 100 characters');
    }

    // Validate phone
    if (phoneNumber.trim().isEmpty) {
      errors.add('Phone number is required');
    }

    if (!_isValidPhoneNumber(phoneNumber)) {
      errors.add('Invalid phone number format');
    }

    // Validate sender
    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    // Validate room
    if (roomId.isEmpty) {
      errors.add('Room ID is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate chat room data
  ValidationResult validateChatRoom({
    required List<String> memberIds,
    required bool isGroupChat,
    String? groupName,
    String? groupDescription,
  }) {
    final errors = <String>[];

    // Validate members
    if (memberIds.isEmpty) {
      errors.add('Chat room must have at least one member');
    }

    if (memberIds.length > ChatConstants.maxGroupMembers) {
      errors
          .add('Group cannot exceed ${ChatConstants.maxGroupMembers} members');
    }

    // Check for duplicate member IDs
    final uniqueMembers = memberIds.toSet();
    if (uniqueMembers.length != memberIds.length) {
      errors.add('Duplicate member IDs found');
    }

    // Validate group-specific fields
    if (isGroupChat) {
      if (groupName == null || groupName.trim().isEmpty) {
        errors.add('Group name is required');
      }

      if (groupName != null &&
          groupName.length > ChatConstants.maxGroupNameLength) {
        errors.add(
            'Group name exceeds maximum length of ${ChatConstants.maxGroupNameLength} characters');
      }

      if (groupDescription != null &&
          groupDescription.length > ChatConstants.maxGroupDescriptionLength) {
        errors.add(
            'Group description exceeds maximum length of ${ChatConstants.maxGroupDescriptionLength} characters');
      }

      if (memberIds.length < 2) {
        errors.add('Group must have at least 2 members');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate report data
  ValidationResult validateReport({
    required String reporterId,
    required String contentType,
    required String contentId,
    required String reason,
  }) {
    final errors = <String>[];

    if (reporterId.isEmpty) {
      errors.add('Reporter ID is required');
    }

    if (contentType.isEmpty) {
      errors.add('Content type is required');
    }

    if (contentId.isEmpty) {
      errors.add('Content ID is required');
    }

    if (reason.trim().isEmpty) {
      errors.add('Report reason is required');
    }

    if (reason.length > 1000) {
      errors.add('Report reason exceeds maximum length of 1000 characters');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Check if URL is valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if phone number is valid (basic validation)
  bool _isValidPhoneNumber(String phone) {
    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Check if remaining characters are digits
    return cleaned.length >= 7 &&
        cleaned.length <= 15 &&
        RegExp(r'^\d+$').hasMatch(cleaned);
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  /// Get first error message
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  /// Get all errors as a single string
  String get errorMessage => errors.join(', ');

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Mixin for controllers that need validation
mixin ValidationMixin {
  final _validator = MessageValidator.instance;

  /// Validate and get result
  ValidationResult validate(
      ValidationResult Function(MessageValidator) validation) {
    return validation(_validator);
  }

  /// Throw exception if validation fails
  void validateOrThrow(ValidationResult result) {
    if (!result.isValid) {
      throw ValidationException(result.errors);
    }
  }
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final List<String> errors;

  ValidationException(this.errors);

  String get message => errors.join(', ');

  @override
  String toString() => 'ValidationException: $message';
}

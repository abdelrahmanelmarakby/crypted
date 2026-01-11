// SEC-001 FIX: Input Sanitization Service
// Sanitizes and validates user input to prevent injection attacks

import 'package:flutter/foundation.dart';

/// Configuration for content validation
class ContentValidationConfig {
  final int maxLength;
  final bool allowHtml;
  final bool allowUrls;
  final List<String> blockedPatterns;
  final List<String> allowedUrlSchemes;

  const ContentValidationConfig({
    this.maxLength = 5000,
    this.allowHtml = false,
    this.allowUrls = true,
    this.blockedPatterns = const [],
    this.allowedUrlSchemes = const ['http', 'https', 'mailto', 'tel'],
  });

  /// Default config for text messages
  static const textMessage = ContentValidationConfig(
    maxLength: 5000,
    allowHtml: false,
    allowUrls: true,
  );

  /// Config for group names
  static const groupName = ContentValidationConfig(
    maxLength: 100,
    allowHtml: false,
    allowUrls: false,
  );

  /// Config for group descriptions
  static const groupDescription = ContentValidationConfig(
    maxLength: 500,
    allowHtml: false,
    allowUrls: true,
  );

  /// Config for usernames
  static const username = ContentValidationConfig(
    maxLength: 50,
    allowHtml: false,
    allowUrls: false,
  );

  /// Config for report reasons
  static const reportReason = ContentValidationConfig(
    maxLength: 1000,
    allowHtml: false,
    allowUrls: false,
  );
}

/// Result of content sanitization
class SanitizationResult {
  final String sanitized;
  final bool wasModified;
  final List<String> warnings;
  final bool isValid;
  final String? error;

  const SanitizationResult({
    required this.sanitized,
    required this.wasModified,
    this.warnings = const [],
    this.isValid = true,
    this.error,
  });

  factory SanitizationResult.valid(String sanitized, {bool wasModified = false, List<String>? warnings}) {
    return SanitizationResult(
      sanitized: sanitized,
      wasModified: wasModified,
      warnings: warnings ?? [],
      isValid: true,
    );
  }

  factory SanitizationResult.invalid(String error) {
    return SanitizationResult(
      sanitized: '',
      wasModified: false,
      isValid: false,
      error: error,
    );
  }
}

/// Input sanitization service
class InputSanitizer {
  static final InputSanitizer _instance = InputSanitizer._internal();
  factory InputSanitizer() => _instance;
  InputSanitizer._internal();

  // HTML tag pattern
  static final _htmlTagPattern = RegExp(r'<[^>]*>', multiLine: true);

  // Script injection patterns
  static final _scriptPatterns = [
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false), // onclick=, onerror=, etc.
    RegExp(r'<script', caseSensitive: false),
    RegExp(r'</script>', caseSensitive: false),
    RegExp(r'eval\s*\(', caseSensitive: false),
    RegExp(r'expression\s*\(', caseSensitive: false),
  ];

  // SQL injection patterns (basic)
  static final _sqlPatterns = [
    RegExp(r"('\s*(OR|AND)\s*')", caseSensitive: false),
    RegExp(r'(--\s*$)', multiLine: true),
    RegExp(r'(;\s*(DROP|DELETE|UPDATE|INSERT)\s)', caseSensitive: false),
  ];

  // URL pattern
  static final _urlPattern = RegExp(
    r'(https?:\/\/|mailto:|tel:)[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  /// Sanitize text content
  SanitizationResult sanitize(
    String input, {
    ContentValidationConfig config = ContentValidationConfig.textMessage,
  }) {
    if (input.isEmpty) {
      return SanitizationResult.valid(input);
    }

    String sanitized = input;
    bool wasModified = false;
    final warnings = <String>[];

    // Check length
    if (sanitized.length > config.maxLength) {
      sanitized = sanitized.substring(0, config.maxLength);
      wasModified = true;
      warnings.add('Content truncated to ${config.maxLength} characters');
    }

    // Remove HTML if not allowed
    if (!config.allowHtml) {
      final htmlRemoved = _removeHtml(sanitized);
      if (htmlRemoved != sanitized) {
        sanitized = htmlRemoved;
        wasModified = true;
        warnings.add('HTML tags removed');
      }
    }

    // Check for script injection
    for (final pattern in _scriptPatterns) {
      if (pattern.hasMatch(sanitized)) {
        sanitized = sanitized.replaceAll(pattern, '');
        wasModified = true;
        warnings.add('Potentially dangerous content removed');
      }
    }

    // Check for SQL injection patterns
    for (final pattern in _sqlPatterns) {
      if (pattern.hasMatch(sanitized)) {
        sanitized = sanitized.replaceAll(pattern, '');
        wasModified = true;
        warnings.add('Suspicious pattern removed');
      }
    }

    // Validate URLs if present
    if (!config.allowUrls) {
      final urlRemoved = _removeUrls(sanitized);
      if (urlRemoved != sanitized) {
        sanitized = urlRemoved;
        wasModified = true;
        warnings.add('URLs removed');
      }
    } else {
      // Validate URL schemes
      final urlValidation = _validateUrls(sanitized, config.allowedUrlSchemes);
      if (urlValidation.wasModified) {
        sanitized = urlValidation.sanitized;
        wasModified = true;
        warnings.addAll(urlValidation.warnings);
      }
    }

    // Check blocked patterns
    for (final pattern in config.blockedPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(sanitized)) {
        sanitized = sanitized.replaceAll(regex, '***');
        wasModified = true;
        warnings.add('Blocked content masked');
      }
    }

    // Normalize whitespace
    final normalized = _normalizeWhitespace(sanitized);
    if (normalized != sanitized) {
      sanitized = normalized;
      wasModified = true;
    }

    // Trim
    final trimmed = sanitized.trim();
    if (trimmed != sanitized) {
      sanitized = trimmed;
      wasModified = true;
    }

    if (kDebugMode && wasModified) {
      print('[Sanitizer] Content was modified. Warnings: $warnings');
    }

    return SanitizationResult.valid(
      sanitized,
      wasModified: wasModified,
      warnings: warnings,
    );
  }

  /// Validate message content
  SanitizationResult validateMessage(String content) {
    if (content.trim().isEmpty) {
      return SanitizationResult.invalid('Message cannot be empty');
    }

    return sanitize(content, config: ContentValidationConfig.textMessage);
  }

  /// Validate group name
  SanitizationResult validateGroupName(String name) {
    if (name.trim().isEmpty) {
      return SanitizationResult.invalid('Group name cannot be empty');
    }

    if (name.trim().length < 3) {
      return SanitizationResult.invalid('Group name must be at least 3 characters');
    }

    return sanitize(name, config: ContentValidationConfig.groupName);
  }

  /// Validate username
  SanitizationResult validateUsername(String username) {
    if (username.trim().isEmpty) {
      return SanitizationResult.invalid('Username cannot be empty');
    }

    if (username.trim().length < 2) {
      return SanitizationResult.invalid('Username must be at least 2 characters');
    }

    // Check for valid characters
    if (!RegExp(r'^[\w\s\-\.]+$').hasMatch(username)) {
      return SanitizationResult.invalid('Username contains invalid characters');
    }

    return sanitize(username, config: ContentValidationConfig.username);
  }

  /// Validate URL
  bool isValidUrl(String url, {List<String>? allowedSchemes}) {
    final schemes = allowedSchemes ?? ['http', 'https'];

    try {
      final uri = Uri.parse(url);
      return schemes.contains(uri.scheme.toLowerCase()) && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Extract URLs from text
  List<String> extractUrls(String text) {
    return _urlPattern.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Remove HTML tags
  String _removeHtml(String input) {
    return input.replaceAll(_htmlTagPattern, '');
  }

  /// Remove URLs
  String _removeUrls(String input) {
    return input.replaceAll(_urlPattern, '[link removed]');
  }

  /// Validate URLs in text
  SanitizationResult _validateUrls(String input, List<String> allowedSchemes) {
    final urls = extractUrls(input);
    String sanitized = input;
    bool wasModified = false;
    final warnings = <String>[];

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (!allowedSchemes.contains(uri.scheme.toLowerCase())) {
          sanitized = sanitized.replaceAll(url, '[invalid link]');
          wasModified = true;
          warnings.add('Invalid URL scheme: ${uri.scheme}');
        }
      } catch (e) {
        sanitized = sanitized.replaceAll(url, '[invalid link]');
        wasModified = true;
        warnings.add('Malformed URL removed');
      }
    }

    return SanitizationResult(
      sanitized: sanitized,
      wasModified: wasModified,
      warnings: warnings,
    );
  }

  /// Normalize whitespace
  String _normalizeWhitespace(String input) {
    // Replace multiple spaces with single space
    String normalized = input.replaceAll(RegExp(r' +'), ' ');
    // Replace multiple newlines with double newline
    normalized = normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return normalized;
  }

  /// Escape special characters for safe display
  String escapeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Validate file name
  SanitizationResult validateFileName(String fileName) {
    if (fileName.trim().isEmpty) {
      return SanitizationResult.invalid('File name cannot be empty');
    }

    // Remove path traversal attempts
    String sanitized = fileName.replaceAll(RegExp(r'\.{2,}'), '.');
    sanitized = sanitized.replaceAll(RegExp(r'[/\\]'), '_');

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Limit length
    if (sanitized.length > 255) {
      final ext = _getFileExtension(sanitized);
      sanitized = '${sanitized.substring(0, 250 - ext.length)}$ext';
    }

    return SanitizationResult.valid(
      sanitized,
      wasModified: sanitized != fileName,
    );
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot);
  }
}

/// Mixin to add sanitization to controllers
mixin SanitizedInputMixin {
  final _sanitizer = InputSanitizer();

  /// Sanitize text message
  SanitizationResult sanitizeMessage(String text) {
    return _sanitizer.validateMessage(text);
  }

  /// Sanitize group name
  SanitizationResult sanitizeGroupName(String name) {
    return _sanitizer.validateGroupName(name);
  }

  /// Sanitize username
  SanitizationResult sanitizeUsername(String username) {
    return _sanitizer.validateUsername(username);
  }

  /// Check if input is safe
  bool isSafeInput(String input) {
    final result = _sanitizer.sanitize(input);
    return result.isValid && !result.wasModified;
  }
}

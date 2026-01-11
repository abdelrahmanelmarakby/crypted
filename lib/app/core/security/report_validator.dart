import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/security/input_sanitizer.dart';

/// SEC-005: Report Content Validation
/// Validates and sanitizes report submissions to prevent abuse

class ReportValidator {
  static final ReportValidator instance = ReportValidator._();
  ReportValidator._();

  final _logger = LoggerService.instance;
  final _sanitizer = InputSanitizer();

  // Valid report categories
  static const List<String> validCategories = [
    'spam',
    'harassment',
    'hate_speech',
    'violence',
    'nudity',
    'false_information',
    'scam',
    'impersonation',
    'copyright',
    'other',
  ];

  // Report reason constraints
  static const int minReasonLength = 10;
  static const int maxReasonLength = 1000;
  static const int maxReportsPerDay = 10;

  // Track user report counts (should use persistent storage in production)
  final Map<String, List<DateTime>> _userReportCounts = {};

  /// Validate a report submission
  ReportValidationResult validate({
    required String reporterId,
    required String contentId,
    required String contentType,
    required String category,
    required String reason,
    String? additionalInfo,
  }) {
    final errors = <String>[];

    // Validate reporter ID
    if (reporterId.isEmpty) {
      errors.add('Reporter ID is required');
    }

    // Validate content ID
    if (contentId.isEmpty) {
      errors.add('Content ID is required');
    }

    // Validate content type
    if (!_isValidContentType(contentType)) {
      errors.add('Invalid content type');
    }

    // Validate category
    if (!validCategories.contains(category.toLowerCase())) {
      errors.add('Invalid report category. Valid categories: ${validCategories.join(', ')}');
    }

    // Validate reason
    final reasonValidation = _validateReason(reason);
    if (!reasonValidation.isValid) {
      errors.add(reasonValidation.error!);
    }

    // Check rate limiting
    if (!_checkRateLimit(reporterId)) {
      errors.add('You have reached the maximum number of reports for today');
    }

    // Validate additional info if provided
    if (additionalInfo != null && additionalInfo.length > 500) {
      errors.add('Additional information exceeds maximum length of 500 characters');
    }

    if (errors.isNotEmpty) {
      return ReportValidationResult.invalid(errors);
    }

    // Sanitize the content
    final sanitizedReason = _sanitizer.sanitizeText(reason);
    final sanitizedAdditionalInfo = additionalInfo != null
        ? _sanitizer.sanitizeText(additionalInfo)
        : null;

    // Track this report
    _trackReport(reporterId);

    return ReportValidationResult.valid(
      sanitizedReason: sanitizedReason,
      sanitizedAdditionalInfo: sanitizedAdditionalInfo,
      normalizedCategory: category.toLowerCase(),
    );
  }

  /// Validate a quick report (predefined reason)
  ReportValidationResult validateQuickReport({
    required String reporterId,
    required String contentId,
    required String contentType,
    required String category,
  }) {
    final predefinedReason = _getPredefinedReason(category);
    return validate(
      reporterId: reporterId,
      contentId: contentId,
      contentType: contentType,
      category: category,
      reason: predefinedReason,
    );
  }

  /// Check if content type is valid
  bool _isValidContentType(String contentType) {
    const validTypes = [
      'message',
      'user',
      'group',
      'story',
      'comment',
      'profile',
    ];
    return validTypes.contains(contentType.toLowerCase());
  }

  /// Validate report reason
  _ReasonValidation _validateReason(String reason) {
    if (reason.trim().isEmpty) {
      return _ReasonValidation(false, 'Report reason is required');
    }

    if (reason.trim().length < minReasonLength) {
      return _ReasonValidation(
        false,
        'Report reason must be at least $minReasonLength characters',
      );
    }

    if (reason.length > maxReasonLength) {
      return _ReasonValidation(
        false,
        'Report reason exceeds maximum length of $maxReasonLength characters',
      );
    }

    // Check for spam-like content
    if (_isSpamContent(reason)) {
      return _ReasonValidation(false, 'Report appears to contain spam');
    }

    return _ReasonValidation(true, null);
  }

  /// Check for spam-like content
  bool _isSpamContent(String text) {
    // Check for repeated characters
    if (RegExp(r'(.)\1{9,}').hasMatch(text)) {
      return true;
    }

    // Check for excessive caps
    final caps = text.replaceAll(RegExp(r'[^A-Z]'), '');
    if (text.length > 20 && caps.length > text.length * 0.8) {
      return true;
    }

    // Check for common spam patterns
    final spamPatterns = [
      RegExp(r'http[s]?://\S+\s*$', caseSensitive: false),
      RegExp(r'@\w+\s+@\w+\s+@\w+', caseSensitive: false), // Multiple mentions
      RegExp(r'(.{5,})\1\1', caseSensitive: false), // Repeated phrases
    ];

    return spamPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Check rate limiting for user
  bool _checkRateLimit(String userId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Get user's reports for today
    final reports = _userReportCounts[userId] ?? [];
    final todayReports = reports.where((dt) => dt.isAfter(todayStart)).length;

    return todayReports < maxReportsPerDay;
  }

  /// Track a report submission
  void _trackReport(String userId) {
    _userReportCounts[userId] ??= [];
    _userReportCounts[userId]!.add(DateTime.now());

    // Clean up old entries
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    _userReportCounts[userId]!.removeWhere((dt) => dt.isBefore(cutoff));
  }

  /// Get predefined reason for a category
  String _getPredefinedReason(String category) {
    const reasons = {
      'spam': 'This content appears to be spam or unwanted commercial content.',
      'harassment': 'This content contains harassment or bullying behavior.',
      'hate_speech': 'This content contains hate speech or discriminatory language.',
      'violence': 'This content contains violent or threatening content.',
      'nudity': 'This content contains nudity or sexual content.',
      'false_information': 'This content appears to contain false or misleading information.',
      'scam': 'This content appears to be a scam or fraudulent.',
      'impersonation': 'This account appears to be impersonating someone.',
      'copyright': 'This content appears to violate copyright or intellectual property.',
      'other': 'This content violates community guidelines.',
    };
    return reasons[category.toLowerCase()] ?? reasons['other']!;
  }

  /// Get remaining reports for user today
  int getRemainingReports(String userId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final reports = _userReportCounts[userId] ?? [];
    final todayReports = reports.where((dt) => dt.isAfter(todayStart)).length;
    return maxReportsPerDay - todayReports;
  }

  /// Reset rate limiting (for testing)
  void resetRateLimiting() {
    _userReportCounts.clear();
  }
}

class _ReasonValidation {
  final bool isValid;
  final String? error;

  _ReasonValidation(this.isValid, this.error);
}

/// Report validation result
class ReportValidationResult {
  final bool isValid;
  final List<String> errors;
  final String? sanitizedReason;
  final String? sanitizedAdditionalInfo;
  final String? normalizedCategory;

  const ReportValidationResult._({
    required this.isValid,
    this.errors = const [],
    this.sanitizedReason,
    this.sanitizedAdditionalInfo,
    this.normalizedCategory,
  });

  factory ReportValidationResult.valid({
    required String sanitizedReason,
    String? sanitizedAdditionalInfo,
    required String normalizedCategory,
  }) {
    return ReportValidationResult._(
      isValid: true,
      sanitizedReason: sanitizedReason,
      sanitizedAdditionalInfo: sanitizedAdditionalInfo,
      normalizedCategory: normalizedCategory,
    );
  }

  factory ReportValidationResult.invalid(List<String> errors) {
    return ReportValidationResult._(
      isValid: false,
      errors: errors,
    );
  }

  String get firstError => errors.isNotEmpty ? errors.first : '';

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: ${errors.join(', ')}';
}

/// Report builder for structured report creation
class ReportBuilder {
  String? _reporterId;
  String? _contentId;
  String? _contentType;
  String? _category;
  String? _reason;
  String? _additionalInfo;

  ReportBuilder reporter(String id) {
    _reporterId = id;
    return this;
  }

  ReportBuilder content(String id, String type) {
    _contentId = id;
    _contentType = type;
    return this;
  }

  ReportBuilder category(String category) {
    _category = category;
    return this;
  }

  ReportBuilder reason(String reason) {
    _reason = reason;
    return this;
  }

  ReportBuilder additionalInfo(String info) {
    _additionalInfo = info;
    return this;
  }

  ReportValidationResult validate() {
    return ReportValidator.instance.validate(
      reporterId: _reporterId ?? '',
      contentId: _contentId ?? '',
      contentType: _contentType ?? '',
      category: _category ?? '',
      reason: _reason ?? '',
      additionalInfo: _additionalInfo,
    );
  }
}

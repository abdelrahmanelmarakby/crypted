import 'package:crypted_app/app/core/services/logger_service.dart';

/// SEC-006: File URL Verification
/// Verifies that file URLs belong to the app's Firebase Storage
/// Prevents loading of malicious external content

class FileUrlVerifier {
  static final FileUrlVerifier instance = FileUrlVerifier._();
  FileUrlVerifier._();

  final _logger = LoggerService.instance;

  // Allowed Firebase Storage domains
  static const List<String> _allowedDomains = [
    'firebasestorage.googleapis.com',
    'storage.googleapis.com',
  ];

  // Allowed Firebase Storage bucket patterns
  static const List<String> _allowedBucketPatterns = [
    'crypted', // App bucket name
    'crypted-app',
    'crypted_app',
  ];

  // Allowed file extensions by type
  static const Map<FileType, List<String>> _allowedExtensions = {
    FileType.image: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
    FileType.video: ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'],
    FileType.audio: ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
    FileType.document: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
  };

  /// Verify if a URL is a valid Firebase Storage URL for this app
  VerificationResult verify(String url, {FileType? expectedType}) {
    if (url.isEmpty) {
      return VerificationResult.invalid('URL is empty');
    }

    try {
      final uri = Uri.parse(url);

      // Check scheme
      if (uri.scheme != 'https') {
        return VerificationResult.invalid('URL must use HTTPS');
      }

      // Check domain
      if (!_isAllowedDomain(uri.host)) {
        _logger.warning('Blocked URL with disallowed domain',
            context: 'FileUrlVerifier',
            data: {'domain': uri.host});
        return VerificationResult.invalid('URL domain not allowed');
      }

      // Check bucket
      if (!_isAllowedBucket(url)) {
        _logger.warning('Blocked URL with disallowed bucket',
            context: 'FileUrlVerifier');
        return VerificationResult.invalid('Storage bucket not allowed');
      }

      // Check file extension if type is specified
      if (expectedType != null) {
        final extension = _getExtension(url);
        if (!_isAllowedExtension(extension, expectedType)) {
          return VerificationResult.invalid(
              'File extension not allowed for ${expectedType.name}');
        }
      }

      // Check for suspicious patterns
      if (_hasSuspiciousPatterns(url)) {
        _logger.warning('Blocked URL with suspicious pattern',
            context: 'FileUrlVerifier');
        return VerificationResult.invalid('URL contains suspicious patterns');
      }

      return VerificationResult.valid();
    } catch (e) {
      _logger.logError('URL verification failed', error: e,
          context: 'FileUrlVerifier');
      return VerificationResult.invalid('Invalid URL format');
    }
  }

  /// Verify an image URL
  VerificationResult verifyImageUrl(String url) {
    return verify(url, expectedType: FileType.image);
  }

  /// Verify a video URL
  VerificationResult verifyVideoUrl(String url) {
    return verify(url, expectedType: FileType.video);
  }

  /// Verify an audio URL
  VerificationResult verifyAudioUrl(String url) {
    return verify(url, expectedType: FileType.audio);
  }

  /// Verify a document URL
  VerificationResult verifyDocumentUrl(String url) {
    return verify(url, expectedType: FileType.document);
  }

  /// Check if domain is allowed
  bool _isAllowedDomain(String domain) {
    return _allowedDomains.any((allowed) => domain.endsWith(allowed));
  }

  /// Check if bucket is allowed
  bool _isAllowedBucket(String url) {
    final lowerUrl = url.toLowerCase();
    return _allowedBucketPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  /// Get file extension from URL
  String _getExtension(String url) {
    try {
      // Remove query parameters
      final path = url.split('?').first;
      final lastDot = path.lastIndexOf('.');
      if (lastDot == -1) return '';
      return path.substring(lastDot + 1).toLowerCase();
    } catch (e) {
      return '';
    }
  }

  /// Check if extension is allowed for type
  bool _isAllowedExtension(String extension, FileType type) {
    final allowed = _allowedExtensions[type];
    if (allowed == null) return false;
    return allowed.contains(extension.toLowerCase());
  }

  /// Check for suspicious URL patterns
  bool _hasSuspiciousPatterns(String url) {
    final suspiciousPatterns = [
      RegExp(r'\.\.\/'), // Directory traversal
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'%3Cscript', caseSensitive: false),
      RegExp(r'on\w+=', caseSensitive: false), // Event handlers
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Sanitize URL by removing potentially dangerous parts
  String sanitize(String url) {
    if (url.isEmpty) return url;

    // Remove any fragment identifier
    var sanitized = url.split('#').first;

    // Ensure HTTPS
    if (sanitized.startsWith('http://')) {
      sanitized = 'https://${sanitized.substring(7)}';
    }

    // Remove double slashes (except after protocol)
    sanitized = sanitized.replaceAll(RegExp(r'(?<!:)\/\/'), '/');

    // URL encode special characters in path
    try {
      final uri = Uri.parse(sanitized);
      sanitized = uri.toString();
    } catch (e) {
      // If parsing fails, return empty
      return '';
    }

    return sanitized;
  }

  /// Generate a signed URL for temporary access (placeholder for Firebase)
  Future<String?> getSignedUrl(
    String storagePath, {
    Duration validity = const Duration(hours: 1),
  }) async {
    // In production, this would call Firebase Storage to generate a signed URL
    // For now, return the path as-is
    _logger.debug('Generating signed URL', context: 'FileUrlVerifier', data: {
      'path': storagePath,
      'validityMinutes': validity.inMinutes,
    });
    return storagePath;
  }
}

/// Verification result
class VerificationResult {
  final bool isValid;
  final String? error;

  const VerificationResult._({
    required this.isValid,
    this.error,
  });

  factory VerificationResult.valid() => const VerificationResult._(isValid: true);

  factory VerificationResult.invalid(String error) => VerificationResult._(
        isValid: false,
        error: error,
      );

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $error';
}

/// File types for verification
enum FileType {
  image,
  video,
  audio,
  document,
}

/// Extension for easy URL verification
extension UrlVerification on String {
  /// Verify as a Firebase Storage URL
  VerificationResult verifyAsStorageUrl({FileType? expectedType}) {
    return FileUrlVerifier.instance.verify(this, expectedType: expectedType);
  }

  /// Check if URL is valid for images
  bool get isValidImageUrl =>
      FileUrlVerifier.instance.verifyImageUrl(this).isValid;

  /// Check if URL is valid for videos
  bool get isValidVideoUrl =>
      FileUrlVerifier.instance.verifyVideoUrl(this).isValid;

  /// Check if URL is valid for audio
  bool get isValidAudioUrl =>
      FileUrlVerifier.instance.verifyAudioUrl(this).isValid;

  /// Check if URL is valid for documents
  bool get isValidDocumentUrl =>
      FileUrlVerifier.instance.verifyDocumentUrl(this).isValid;

  /// Sanitize the URL
  String get sanitizedUrl => FileUrlVerifier.instance.sanitize(this);
}

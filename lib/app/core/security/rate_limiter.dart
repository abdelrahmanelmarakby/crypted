import 'dart:async';
import 'package:crypted_app/app/core/constants/chat_constants.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';

/// SEC-004: Rate Limiter
/// Prevents abuse by limiting the rate of operations
class RateLimiter {
  static final RateLimiter instance = RateLimiter._();
  RateLimiter._();

  final _logger = LoggerService.instance;

  // Rate limit buckets
  final Map<String, _RateBucket> _buckets = {};

  /// Check if an action is allowed
  bool isAllowed(String action, String userId) {
    final key = '${action}_$userId';
    final bucket = _buckets[key] ?? _createBucket(action, key);

    return bucket.tryConsume();
  }

  /// Check and consume a rate limit token
  /// Returns true if allowed, false if rate limited
  bool checkAndConsume(String action, String userId) {
    if (!isAllowed(action, userId)) {
      _logger.warning('Rate limit exceeded', context: 'RateLimiter', data: {
        'action': action,
        'userId': userId,
      });
      return false;
    }
    return true;
  }

  /// Get remaining tokens for an action
  int getRemainingTokens(String action, String userId) {
    final key = '${action}_$userId';
    final bucket = _buckets[key];
    return bucket?.remainingTokens ?? _getMaxTokens(action);
  }

  /// Get time until next token is available
  Duration getTimeUntilNextToken(String action, String userId) {
    final key = '${action}_$userId';
    final bucket = _buckets[key];
    return bucket?.timeUntilNextToken ?? Duration.zero;
  }

  /// Reset rate limit for a specific action
  void reset(String action, String userId) {
    final key = '${action}_$userId';
    _buckets.remove(key);
  }

  /// Reset all rate limits for a user
  void resetAll(String userId) {
    _buckets.removeWhere((key, _) => key.endsWith('_$userId'));
  }

  /// Create a new rate bucket for an action
  _RateBucket _createBucket(String action, String key) {
    final maxTokens = _getMaxTokens(action);
    final refillDuration = _getRefillDuration(action);

    final bucket = _RateBucket(
      maxTokens: maxTokens,
      refillDuration: refillDuration,
    );

    _buckets[key] = bucket;
    return bucket;
  }

  /// Get max tokens based on action type
  int _getMaxTokens(String action) {
    switch (action) {
      case RateLimitActions.sendMessage:
        return ChatConstants.maxMessagesPerMinute;
      case RateLimitActions.addReaction:
        return ChatConstants.maxReactionsPerMinute;
      case RateLimitActions.uploadFile:
        return 10; // 10 uploads per minute
      case RateLimitActions.createRoom:
        return 5; // 5 room creations per minute
      case RateLimitActions.report:
        return 3; // 3 reports per minute
      case RateLimitActions.search:
        return 30; // 30 searches per minute
      default:
        return 60; // Default: 60 per minute
    }
  }

  /// Get refill duration based on action type
  Duration _getRefillDuration(String action) {
    switch (action) {
      case RateLimitActions.sendMessage:
        return const Duration(minutes: 1);
      case RateLimitActions.addReaction:
        return const Duration(minutes: 1);
      case RateLimitActions.uploadFile:
        return const Duration(minutes: 1);
      case RateLimitActions.createRoom:
        return const Duration(minutes: 1);
      case RateLimitActions.report:
        return const Duration(minutes: 5);
      case RateLimitActions.search:
        return const Duration(minutes: 1);
      default:
        return const Duration(minutes: 1);
    }
  }
}

/// Rate limit bucket using token bucket algorithm
class _RateBucket {
  final int maxTokens;
  final Duration refillDuration;

  int _tokens;
  DateTime _lastRefill;

  _RateBucket({
    required this.maxTokens,
    required this.refillDuration,
  })  : _tokens = maxTokens,
        _lastRefill = DateTime.now();

  /// Try to consume a token
  /// Returns true if successful, false if no tokens available
  bool tryConsume() {
    _refill();

    if (_tokens > 0) {
      _tokens--;
      return true;
    }

    return false;
  }

  /// Get remaining tokens after refill
  int get remainingTokens {
    _refill();
    return _tokens;
  }

  /// Get time until next token is available
  Duration get timeUntilNextToken {
    if (_tokens > 0) return Duration.zero;

    final elapsed = DateTime.now().difference(_lastRefill);
    final tokenInterval = refillDuration.inMilliseconds / maxTokens;
    final nextTokenAt = Duration(milliseconds: tokenInterval.toInt());

    if (elapsed >= nextTokenAt) return Duration.zero;
    return nextTokenAt - elapsed;
  }

  /// Refill tokens based on elapsed time
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);

    if (elapsed >= refillDuration) {
      // Full refill
      _tokens = maxTokens;
      _lastRefill = now;
    } else {
      // Partial refill based on elapsed time
      final tokensToAdd = (elapsed.inMilliseconds / refillDuration.inMilliseconds * maxTokens).floor();
      if (tokensToAdd > 0) {
        _tokens = (_tokens + tokensToAdd).clamp(0, maxTokens);
        _lastRefill = now;
      }
    }
  }
}

/// Rate limit action constants
class RateLimitActions {
  RateLimitActions._();

  static const String sendMessage = 'send_message';
  static const String addReaction = 'add_reaction';
  static const String uploadFile = 'upload_file';
  static const String createRoom = 'create_room';
  static const String report = 'report';
  static const String search = 'search';
  static const String editMessage = 'edit_message';
  static const String deleteMessage = 'delete_message';
  static const String forwardMessage = 'forward_message';
  static const String votePoll = 'vote_poll';
}

/// Mixin for controllers that need rate limiting
mixin RateLimitMixin {
  final _rateLimiter = RateLimiter.instance;

  /// Check if action is rate limited
  bool isRateLimited(String action, String userId) {
    return !_rateLimiter.isAllowed(action, userId);
  }

  /// Execute action with rate limiting
  Future<T?> withRateLimit<T>({
    required String action,
    required String userId,
    required Future<T> Function() operation,
    String? errorMessage,
  }) async {
    if (!_rateLimiter.checkAndConsume(action, userId)) {
      // Rate limited
      final waitTime = _rateLimiter.getTimeUntilNextToken(action, userId);
      throw RateLimitException(
        errorMessage ?? 'Too many requests. Please wait ${waitTime.inSeconds} seconds.',
        waitTime,
      );
    }

    return await operation();
  }
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;
  final Duration waitTime;

  RateLimitException(this.message, this.waitTime);

  @override
  String toString() => message;
}

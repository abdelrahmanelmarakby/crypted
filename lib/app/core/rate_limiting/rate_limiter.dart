// SEC-004 FIX: Rate Limiting Service
// Prevents abuse by limiting request frequency

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Rate limit configuration
class RateLimitConfig {
  /// Maximum number of requests allowed in the time window
  final int maxRequests;

  /// Time window in milliseconds
  final int windowMs;

  /// Cooldown period after hitting limit (in milliseconds)
  final int cooldownMs;

  const RateLimitConfig({
    required this.maxRequests,
    required this.windowMs,
    this.cooldownMs = 5000,
  });

  /// Preset for message sending (10 messages per 10 seconds)
  static const messages = RateLimitConfig(
    maxRequests: 10,
    windowMs: 10000,
    cooldownMs: 5000,
  );

  /// Preset for reactions (20 per 30 seconds)
  static const reactions = RateLimitConfig(
    maxRequests: 20,
    windowMs: 30000,
    cooldownMs: 3000,
  );

  /// Preset for poll voting (5 per 10 seconds)
  static const pollVotes = RateLimitConfig(
    maxRequests: 5,
    windowMs: 10000,
    cooldownMs: 2000,
  );

  /// Preset for reports (3 per minute)
  static const reports = RateLimitConfig(
    maxRequests: 3,
    windowMs: 60000,
    cooldownMs: 30000,
  );

  /// Preset for search (10 per 5 seconds)
  static const search = RateLimitConfig(
    maxRequests: 10,
    windowMs: 5000,
    cooldownMs: 2000,
  );

  /// Preset for file uploads (5 per minute)
  static const uploads = RateLimitConfig(
    maxRequests: 5,
    windowMs: 60000,
    cooldownMs: 10000,
  );
}

/// Result of a rate limit check
class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int resetInMs;
  final String? message;

  const RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.resetInMs,
    this.message,
  });

  factory RateLimitResult.allowed(int remaining, int resetInMs) {
    return RateLimitResult(
      allowed: true,
      remaining: remaining,
      resetInMs: resetInMs,
    );
  }

  factory RateLimitResult.denied(int resetInMs, [String? message]) {
    return RateLimitResult(
      allowed: false,
      remaining: 0,
      resetInMs: resetInMs,
      message: message ?? 'Rate limit exceeded. Please wait.',
    );
  }
}

/// Rate limiter using sliding window algorithm
class RateLimiter {
  final RateLimitConfig config;
  final List<int> _timestamps = [];
  int? _cooldownUntil;

  RateLimiter(this.config);

  /// Check if action is allowed and record if it is
  RateLimitResult checkAndRecord() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if in cooldown
    if (_cooldownUntil != null && now < _cooldownUntil!) {
      final resetIn = _cooldownUntil! - now;
      return RateLimitResult.denied(
        resetIn,
        'Rate limit exceeded. Try again in ${(resetIn / 1000).ceil()} seconds.',
      );
    }

    // Clear cooldown if passed
    if (_cooldownUntil != null && now >= _cooldownUntil!) {
      _cooldownUntil = null;
    }

    // Remove timestamps outside the window
    final windowStart = now - config.windowMs;
    _timestamps.removeWhere((ts) => ts < windowStart);

    // Check if limit exceeded
    if (_timestamps.length >= config.maxRequests) {
      _cooldownUntil = now + config.cooldownMs;
      final resetIn = config.cooldownMs;
      return RateLimitResult.denied(
        resetIn,
        'Rate limit exceeded. Try again in ${(resetIn / 1000).ceil()} seconds.',
      );
    }

    // Record this request
    _timestamps.add(now);

    // Calculate remaining and reset time
    final remaining = config.maxRequests - _timestamps.length;
    final oldestTimestamp = _timestamps.isNotEmpty ? _timestamps.first : now;
    final resetIn = (oldestTimestamp + config.windowMs) - now;

    return RateLimitResult.allowed(remaining, resetIn);
  }

  /// Check without recording (dry run)
  RateLimitResult check() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if in cooldown
    if (_cooldownUntil != null && now < _cooldownUntil!) {
      return RateLimitResult.denied(_cooldownUntil! - now);
    }

    // Remove timestamps outside the window
    final windowStart = now - config.windowMs;
    final validTimestamps = _timestamps.where((ts) => ts >= windowStart).length;

    if (validTimestamps >= config.maxRequests) {
      return RateLimitResult.denied(config.cooldownMs);
    }

    final remaining = config.maxRequests - validTimestamps;
    return RateLimitResult.allowed(remaining, config.windowMs);
  }

  /// Reset the rate limiter
  void reset() {
    _timestamps.clear();
    _cooldownUntil = null;
  }
}

/// Global rate limiter registry
class RateLimiterRegistry {
  static final RateLimiterRegistry _instance = RateLimiterRegistry._internal();
  factory RateLimiterRegistry() => _instance;
  RateLimiterRegistry._internal();

  final Map<String, RateLimiter> _limiters = {};

  /// Get or create a rate limiter for a specific key
  RateLimiter getOrCreate(String key, RateLimitConfig config) {
    return _limiters.putIfAbsent(key, () => RateLimiter(config));
  }

  /// Get limiter for messages
  RateLimiter messages(String roomId) {
    return getOrCreate('messages_$roomId', RateLimitConfig.messages);
  }

  /// Get limiter for reactions
  RateLimiter reactions(String roomId) {
    return getOrCreate('reactions_$roomId', RateLimitConfig.reactions);
  }

  /// Get limiter for poll votes
  RateLimiter pollVotes(String roomId) {
    return getOrCreate('polls_$roomId', RateLimitConfig.pollVotes);
  }

  /// Get limiter for reports
  RateLimiter reports(String userId) {
    return getOrCreate('reports_$userId', RateLimitConfig.reports);
  }

  /// Get limiter for search
  RateLimiter search(String userId) {
    return getOrCreate('search_$userId', RateLimitConfig.search);
  }

  /// Get limiter for uploads
  RateLimiter uploads(String roomId) {
    return getOrCreate('uploads_$roomId', RateLimitConfig.uploads);
  }

  /// Clear all limiters
  void clearAll() {
    _limiters.clear();
  }

  /// Clear limiter for specific key
  void clear(String key) {
    _limiters.remove(key);
  }
}

/// Mixin to add rate limiting to controllers
mixin RateLimitedController {
  final _registry = RateLimiterRegistry();

  /// Check rate limit for messages
  RateLimitResult checkMessageRateLimit(String roomId) {
    return _registry.messages(roomId).check();
  }

  /// Record message send
  RateLimitResult recordMessageSend(String roomId) {
    final result = _registry.messages(roomId).checkAndRecord();
    if (!result.allowed && kDebugMode) {
      print('[RateLimit] Message rate limit exceeded for room $roomId');
    }
    return result;
  }

  /// Check rate limit for reactions
  RateLimitResult checkReactionRateLimit(String roomId) {
    return _registry.reactions(roomId).check();
  }

  /// Record reaction
  RateLimitResult recordReaction(String roomId) {
    return _registry.reactions(roomId).checkAndRecord();
  }

  /// Check rate limit for poll votes
  RateLimitResult checkPollVoteRateLimit(String roomId) {
    return _registry.pollVotes(roomId).check();
  }

  /// Record poll vote
  RateLimitResult recordPollVote(String roomId) {
    return _registry.pollVotes(roomId).checkAndRecord();
  }

  /// Execute action with rate limiting
  Future<T?> executeWithRateLimit<T>({
    required RateLimiter limiter,
    required Future<T> Function() action,
    required void Function(String message) onRateLimited,
  }) async {
    final result = limiter.checkAndRecord();
    if (!result.allowed) {
      onRateLimited(result.message ?? 'Rate limit exceeded');
      return null;
    }
    return await action();
  }
}

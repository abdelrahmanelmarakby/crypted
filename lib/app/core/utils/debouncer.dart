// PERF-005 FIX: Debounce Utility
// Prevents excessive calls for search and other frequent operations

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Simple debouncer for single operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run the action after the delay
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose the debouncer
  void dispose() {
    cancel();
  }
}

/// Debouncer that returns a Future
class AsyncDebouncer<T> {
  final Duration delay;
  Timer? _timer;
  Completer<T>? _completer;

  AsyncDebouncer({this.delay = const Duration(milliseconds: 300)});

  /// Run the async action after the delay
  Future<T> run(Future<T> Function() action) {
    _timer?.cancel();
    _completer = Completer<T>();

    _timer = Timer(delay, () async {
      try {
        final result = await action();
        if (!_completer!.isCompleted) {
          _completer!.complete(result);
        }
      } catch (e) {
        if (!_completer!.isCompleted) {
          _completer!.completeError(e);
        }
      }
    });

    return _completer!.future;
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(CancelledException());
    }
  }

  /// Dispose the debouncer
  void dispose() {
    cancel();
  }
}

/// Exception thrown when debounced action is cancelled
class CancelledException implements Exception {
  final String message;
  CancelledException([this.message = 'Operation was cancelled']);

  @override
  String toString() => 'CancelledException: $message';
}

/// Throttler - limits execution to once per interval
class Throttler {
  final Duration interval;
  DateTime? _lastExecution;
  Timer? _pendingTimer;
  VoidCallback? _pendingAction;

  Throttler({this.interval = const Duration(milliseconds: 300)});

  /// Run the action, throttled
  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecution == null ||
        now.difference(_lastExecution!) >= interval) {
      // Execute immediately
      _lastExecution = now;
      action();
    } else {
      // Schedule for later
      _pendingAction = action;
      _pendingTimer?.cancel();

      final remaining = interval - now.difference(_lastExecution!);
      _pendingTimer = Timer(remaining, () {
        _lastExecution = DateTime.now();
        _pendingAction?.call();
        _pendingAction = null;
      });
    }
  }

  /// Cancel pending action
  void cancel() {
    _pendingTimer?.cancel();
    _pendingAction = null;
  }

  /// Dispose the throttler
  void dispose() {
    cancel();
  }
}

/// Search debouncer with query caching
class SearchDebouncer<T> {
  final Duration delay;
  final Future<T> Function(String query) searchFunction;
  final int minQueryLength;

  Timer? _timer;
  String? _lastQuery;
  T? _lastResult;
  Completer<T>? _currentSearch;

  SearchDebouncer({
    required this.searchFunction,
    this.delay = const Duration(milliseconds: 300),
    this.minQueryLength = 2,
  });

  /// Search with debouncing and caching
  Future<T?> search(String query) async {
    // Cancel any pending search
    _timer?.cancel();

    // Check minimum query length
    if (query.length < minQueryLength) {
      return null;
    }

    // Return cached result if same query
    if (query == _lastQuery && _lastResult != null) {
      return _lastResult;
    }

    // Create new completer for this search
    _currentSearch = Completer<T>();

    _timer = Timer(delay, () async {
      try {
        final result = await searchFunction(query);
        _lastQuery = query;
        _lastResult = result;

        if (!_currentSearch!.isCompleted) {
          _currentSearch!.complete(result);
        }
      } catch (e) {
        if (!_currentSearch!.isCompleted) {
          _currentSearch!.completeError(e);
        }
      }
    });

    return _currentSearch!.future;
  }

  /// Clear cache
  void clearCache() {
    _lastQuery = null;
    _lastResult = null;
  }

  /// Cancel pending search
  void cancel() {
    _timer?.cancel();
    if (_currentSearch != null && !_currentSearch!.isCompleted) {
      _currentSearch!.completeError(CancelledException('Search cancelled'));
    }
  }

  /// Dispose
  void dispose() {
    cancel();
    clearCache();
  }
}

/// Extension to add debouncing to any function
extension DebouncedFunction<T> on Future<T> Function() {
  /// Create a debounced version of this function
  Future<T> Function() debounced([Duration delay = const Duration(milliseconds: 300)]) {
    final debouncer = AsyncDebouncer<T>(delay: delay);
    return () => debouncer.run(this);
  }
}

/// Mixin to add debouncing capabilities to controllers
mixin DebouncedControllerMixin {
  final Map<String, Debouncer> _debouncers = {};
  final Map<String, Throttler> _throttlers = {};

  /// Get or create a debouncer for a key
  Debouncer getDebouncer(String key, [Duration? delay]) {
    return _debouncers.putIfAbsent(
      key,
      () => Debouncer(delay: delay ?? const Duration(milliseconds: 300)),
    );
  }

  /// Get or create a throttler for a key
  Throttler getThrottler(String key, [Duration? interval]) {
    return _throttlers.putIfAbsent(
      key,
      () => Throttler(interval: interval ?? const Duration(milliseconds: 300)),
    );
  }

  /// Debounce an action
  void debounce(String key, VoidCallback action, [Duration? delay]) {
    getDebouncer(key, delay).run(action);
  }

  /// Throttle an action
  void throttle(String key, VoidCallback action, [Duration? interval]) {
    getThrottler(key, interval).run(action);
  }

  /// Dispose all debouncers and throttlers
  void disposeDebouncers() {
    for (final debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    for (final throttler in _throttlers.values) {
      throttler.dispose();
    }
    _debouncers.clear();
    _throttlers.clear();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';

/// PERF-005: Search Debouncer
/// Debounces search queries to prevent excessive API calls
/// while typing
class SearchDebouncer {
  final Duration delay;
  Timer? _timer;
  String _lastQuery = '';

  SearchDebouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  /// Run the callback after the delay if no new calls are made
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Run with a query, only if query has changed
  void runWithQuery(String query, void Function(String) action) {
    if (query == _lastQuery) return;
    _lastQuery = query;

    _timer?.cancel();
    _timer = Timer(delay, () => action(query));
  }

  /// Cancel any pending operation
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of resources
  void dispose() {
    cancel();
  }

  /// Check if there's a pending operation
  bool get isPending => _timer?.isActive ?? false;
}

/// Async version of search debouncer that returns results
class AsyncSearchDebouncer<T> {
  final Duration delay;
  Timer? _timer;
  String _lastQuery = '';
  Completer<T?>? _completer;

  AsyncSearchDebouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  /// Run an async search after debounce delay
  Future<T?> search(
    String query,
    Future<T> Function(String) searchFunction,
  ) async {
    // Cancel previous timer
    _timer?.cancel();

    // If same query, don't search again
    if (query == _lastQuery && _completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }

    _lastQuery = query;
    _completer = Completer<T?>();

    // Handle empty query
    if (query.trim().isEmpty) {
      _completer!.complete(null);
      return _completer!.future;
    }

    _timer = Timer(delay, () async {
      try {
        final result = await searchFunction(query);
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

  /// Cancel pending search
  void cancel() {
    _timer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(null);
    }
  }

  /// Dispose resources
  void dispose() {
    cancel();
    _timer = null;
    _completer = null;
  }
}

/// Mixin for controllers that need debounced search
mixin SearchDebounceMixin {
  final SearchDebouncer _searchDebouncer = SearchDebouncer();

  /// Debounced search method - override searchAction in your controller
  void debouncedSearch(String query) {
    _searchDebouncer.runWithQuery(query, onSearchQuery);
  }

  /// Override this method to handle the debounced search query
  void onSearchQuery(String query);

  /// Cancel any pending search
  void cancelSearch() {
    _searchDebouncer.cancel();
  }

  /// Dispose search debouncer
  void disposeSearchDebouncer() {
    _searchDebouncer.dispose();
  }
}

/// Stream-based search debouncer for reactive programming
class StreamSearchDebouncer<T> {
  final Duration delay;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  StreamSubscription? _subscription;

  StreamSearchDebouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  /// Get the debounced stream
  Stream<T> debounce(Future<T> Function(String) searchFunction) {
    return _controller.stream
        .distinct()
        .transform(
          StreamTransformer.fromHandlers(
            handleData: (query, sink) {
              // Use timer to debounce
              Timer? timer;
              timer = Timer(delay, () async {
                try {
                  final result = await searchFunction(query);
                  sink.add(result);
                } catch (e) {
                  sink.addError(e);
                }
              });
            },
          ),
        );
  }

  /// Add a query to be searched
  void search(String query) {
    _controller.add(query);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

/// Throttler for rate limiting (different from debounce)
/// Ensures a function runs at most once per duration
class Throttler {
  final Duration duration;
  DateTime? _lastRun;

  Throttler({
    this.duration = const Duration(milliseconds: 300),
  });

  /// Run the action if enough time has passed since the last run
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    }
  }

  /// Run with a return value
  T? runWithReturn<T>(T Function() action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      return action();
    }
    return null;
  }

  /// Reset the throttler
  void reset() {
    _lastRun = null;
  }

  /// Check if ready to run
  bool get isReady {
    if (_lastRun == null) return true;
    return DateTime.now().difference(_lastRun!) >= duration;
  }
}

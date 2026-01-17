import 'dart:async';

/// A utility class that debounces function calls.
///
/// Use this to prevent rapid successive calls to expensive operations
/// like saving settings to Firestore. Only the last call within the
/// debounce duration will be executed.
///
/// Example:
/// ```dart
/// final _saveDebouncer = Debouncer(milliseconds: 500);
///
/// void onSettingChanged() {
///   _saveDebouncer.run(() => _saveSettings());
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Completer<void>? _completer;

  Debouncer({this.milliseconds = 300});

  /// Run the given action after the debounce period.
  ///
  /// If called again before the period expires, the previous call is cancelled
  /// and a new timer starts. Returns a Future that completes when the action
  /// is executed.
  Future<void> run(FutureOr<void> Function() action) {
    _timer?.cancel();

    // If there's an existing completer that hasn't completed, reuse it
    _completer ??= Completer<void>();
    final currentCompleter = _completer!;

    _timer = Timer(Duration(milliseconds: milliseconds), () async {
      try {
        await action();
        if (!currentCompleter.isCompleted) {
          currentCompleter.complete();
        }
      } catch (e) {
        if (!currentCompleter.isCompleted) {
          currentCompleter.completeError(e);
        }
      } finally {
        _completer = null;
      }
    });

    return currentCompleter.future;
  }

  /// Run the given action immediately, cancelling any pending debounced call.
  Future<void> runImmediately(FutureOr<void> Function() action) async {
    cancel();
    await action();
  }

  /// Cancel any pending debounced call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(
        StateError('Debounced action was cancelled'),
      );
    }
    _completer = null;
  }

  /// Check if there's a pending debounced call.
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debouncer and cancel any pending calls.
  void dispose() {
    cancel();
  }
}

/// A utility class for throttling function calls.
///
/// Unlike debouncing (which delays execution until activity stops),
/// throttling ensures a function is called at most once per time period.
///
/// Example:
/// ```dart
/// final _saveThrottler = Throttler(milliseconds: 1000);
///
/// void onRapidChanges() {
///   _saveThrottler.run(() => _saveSettings());
/// }
/// ```
class Throttler {
  final int milliseconds;
  DateTime? _lastExecutionTime;
  Timer? _pendingTimer;
  FutureOr<void> Function()? _pendingAction;

  Throttler({this.milliseconds = 300});

  /// Run the given action, throttled to the specified interval.
  ///
  /// If called within the throttle period after the last execution,
  /// the action is queued and will execute after the period expires.
  Future<void> run(FutureOr<void> Function() action) async {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!).inMilliseconds >= milliseconds) {
      // Execute immediately
      _lastExecutionTime = now;
      _pendingTimer?.cancel();
      _pendingAction = null;
      await action();
    } else {
      // Queue for later execution
      _pendingAction = action;
      _pendingTimer?.cancel();
      final remainingTime =
          milliseconds - now.difference(_lastExecutionTime!).inMilliseconds;
      _pendingTimer = Timer(Duration(milliseconds: remainingTime), () async {
        _lastExecutionTime = DateTime.now();
        final pending = _pendingAction;
        _pendingAction = null;
        if (pending != null) {
          await pending();
        }
      });
    }
  }

  /// Cancel any pending throttled call.
  void cancel() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
  }

  /// Dispose the throttler and cancel any pending calls.
  void dispose() {
    cancel();
  }
}

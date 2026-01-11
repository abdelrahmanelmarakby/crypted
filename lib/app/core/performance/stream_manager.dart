// PERF-007 FIX: Stream Subscription Management
// Centralized management of stream subscriptions to prevent memory leaks

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Manager for handling stream subscriptions
class StreamSubscriptionManager {
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, List<StreamSubscription>> _groupedSubscriptions = {};

  /// Add a named subscription
  void add(String key, StreamSubscription subscription) {
    // Cancel existing subscription with same key
    cancel(key);
    _subscriptions[key] = subscription;

    if (kDebugMode) {
      print('[StreamManager] Added subscription: $key');
    }
  }

  /// Add subscription to a group
  void addToGroup(String groupKey, StreamSubscription subscription) {
    _groupedSubscriptions.putIfAbsent(groupKey, () => []);
    _groupedSubscriptions[groupKey]!.add(subscription);

    if (kDebugMode) {
      print('[StreamManager] Added subscription to group: $groupKey');
    }
  }

  /// Cancel a specific subscription
  Future<void> cancel(String key) async {
    final subscription = _subscriptions.remove(key);
    if (subscription != null) {
      await subscription.cancel();
      if (kDebugMode) {
        print('[StreamManager] Cancelled subscription: $key');
      }
    }
  }

  /// Cancel all subscriptions in a group
  Future<void> cancelGroup(String groupKey) async {
    final subscriptions = _groupedSubscriptions.remove(groupKey);
    if (subscriptions != null) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      if (kDebugMode) {
        print('[StreamManager] Cancelled group: $groupKey (${subscriptions.length} subscriptions)');
      }
    }
  }

  /// Pause a subscription
  void pause(String key) {
    _subscriptions[key]?.pause();
  }

  /// Resume a subscription
  void resume(String key) {
    _subscriptions[key]?.resume();
  }

  /// Check if a subscription exists
  bool has(String key) => _subscriptions.containsKey(key);

  /// Get subscription count
  int get count => _subscriptions.length +
      _groupedSubscriptions.values.fold(0, (sum, list) => sum + list.length);

  /// Cancel all subscriptions
  Future<void> cancelAll() async {
    // Cancel named subscriptions
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel grouped subscriptions
    for (final subscriptions in _groupedSubscriptions.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    _groupedSubscriptions.clear();

    if (kDebugMode) {
      print('[StreamManager] Cancelled all subscriptions');
    }
  }

  /// Dispose the manager
  Future<void> dispose() async {
    await cancelAll();
  }
}

/// Mixin for controllers that use stream subscriptions
mixin StreamSubscriptionMixin on GetxController {
  final StreamSubscriptionManager _streamManager = StreamSubscriptionManager();

  /// Add a named subscription
  void addSubscription(String key, StreamSubscription subscription) {
    _streamManager.add(key, subscription);
  }

  /// Add subscription to a group
  void addGroupedSubscription(String groupKey, StreamSubscription subscription) {
    _streamManager.addToGroup(groupKey, subscription);
  }

  /// Cancel a specific subscription
  Future<void> cancelSubscription(String key) async {
    await _streamManager.cancel(key);
  }

  /// Cancel a group of subscriptions
  Future<void> cancelSubscriptionGroup(String groupKey) async {
    await _streamManager.cancelGroup(groupKey);
  }

  /// Listen to a stream with automatic management
  StreamSubscription<T> listenToStream<T>(
    String key,
    Stream<T> stream,
    void Function(T data) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    addSubscription(key, subscription);
    return subscription;
  }

  /// Dispose all subscriptions
  @override
  void onClose() {
    _streamManager.dispose();
    super.onClose();
  }
}

/// A debounced stream transformer
class DebouncedStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;

  DebouncedStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          Timer(duration, () => sink.add(data));
        },
      ),
    );
  }
}

/// A throttled stream transformer
class ThrottledStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  DateTime? _lastEmit;

  ThrottledStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) {
          final now = DateTime.now();
          if (_lastEmit == null || now.difference(_lastEmit!) >= duration) {
            _lastEmit = now;
            sink.add(data);
          }
        },
      ),
    );
  }
}

/// Extension methods for streams
extension StreamExtensions<T> on Stream<T> {
  /// Debounce the stream
  Stream<T> debounce(Duration duration) {
    return transform(DebouncedStreamTransformer<T>(duration));
  }

  /// Throttle the stream
  Stream<T> throttle(Duration duration) {
    return transform(ThrottledStreamTransformer<T>(duration));
  }

  /// Take until another stream emits
  Stream<T> takeUntilSignal(Stream signal) {
    return takeWhile((_) {
      var shouldContinue = true;
      signal.first.then((_) => shouldContinue = false);
      return shouldContinue;
    });
  }
}

/// Combines multiple streams into one
class CombinedStream<T> {
  final List<Stream<T>> _streams;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  final List<StreamSubscription<T>> _subscriptions = [];

  CombinedStream(this._streams) {
    for (final stream in _streams) {
      _subscriptions.add(
        stream.listen(
          (data) => _controller.add(data),
          onError: (error) => _controller.addError(error),
        ),
      );
    }
  }

  Stream<T> get stream => _controller.stream;

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.close();
  }
}

/// Auto-reconnecting stream wrapper
class ReconnectingStream<T> {
  final Stream<T> Function() _streamFactory;
  final Duration _reconnectDelay;
  final int _maxReconnectAttempts;

  StreamController<T>? _controller;
  StreamSubscription<T>? _subscription;
  int _reconnectAttempts = 0;

  ReconnectingStream({
    required Stream<T> Function() streamFactory,
    Duration reconnectDelay = const Duration(seconds: 5),
    int maxReconnectAttempts = 5,
  })  : _streamFactory = streamFactory,
        _reconnectDelay = reconnectDelay,
        _maxReconnectAttempts = maxReconnectAttempts;

  Stream<T> get stream {
    _controller ??= StreamController<T>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  void _connect() {
    _subscription?.cancel();
    _subscription = _streamFactory().listen(
      (data) {
        _reconnectAttempts = 0;
        _controller?.add(data);
      },
      onError: (error) {
        _controller?.addError(error);
        _attemptReconnect();
      },
      onDone: _attemptReconnect,
    );
  }

  void _attemptReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(_reconnectDelay * _reconnectAttempts, _connect);
    }
  }

  void _disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    _disconnect();
    await _controller?.close();
    _controller = null;
  }
}

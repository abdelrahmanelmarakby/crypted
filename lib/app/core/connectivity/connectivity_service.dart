// PERF-008 FIX: Connectivity Monitoring Service
// Monitors network connectivity and handles offline/online transitions

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';

/// Connection status
enum ConnectionStatus {
  online,
  offline,
  unknown,
}

/// Connectivity change event
class ConnectivityChangeEvent {
  final ConnectionStatus status;
  final DateTime timestamp;

  ConnectivityChangeEvent(this.status) : timestamp = DateTime.now();
}

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final EventBus _eventBus = EventBus();
  final OfflineQueue _offlineQueue = OfflineQueue();

  Timer? _periodicCheck;
  ConnectionStatus _lastStatus = ConnectionStatus.unknown;
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// Stream of connectivity status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectionStatus get currentStatus => _lastStatus;

  /// Check if currently online
  bool get isOnline => _lastStatus == ConnectionStatus.online;

  /// Start monitoring connectivity
  void startMonitoring({
    Duration checkInterval = const Duration(seconds: 30),
    List<String>? testUrls,
  }) {
    // Initial check
    _checkConnectivity(testUrls);

    // Periodic checks
    _periodicCheck?.cancel();
    _periodicCheck = Timer.periodic(checkInterval, (_) {
      _checkConnectivity(testUrls);
    });

    if (kDebugMode) {
      print('[Connectivity] Monitoring started with ${checkInterval.inSeconds}s interval');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _periodicCheck?.cancel();
    _periodicCheck = null;
  }

  /// Force a connectivity check
  Future<ConnectionStatus> checkNow({List<String>? testUrls}) async {
    return _checkConnectivity(testUrls);
  }

  /// Check connectivity by attempting to reach a server
  Future<ConnectionStatus> _checkConnectivity([List<String>? testUrls]) async {
    final urls = testUrls ??
        [
          'google.com',
          'cloudflare.com',
          'firebase.google.com',
        ];

    bool isConnected = false;

    for (final url in urls) {
      try {
        final result = await InternetAddress.lookup(url)
            .timeout(const Duration(seconds: 5));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          isConnected = true;
          break;
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }

    final newStatus =
        isConnected ? ConnectionStatus.online : ConnectionStatus.offline;

    _updateStatus(newStatus);
    return newStatus;
  }

  /// Update status and notify listeners
  void _updateStatus(ConnectionStatus newStatus) {
    if (newStatus == _lastStatus) return;

    final previousStatus = _lastStatus;
    _lastStatus = newStatus;

    // Emit to status stream
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }

    // Emit event bus event
    _eventBus.emit(ConnectivityChangedEvent(isOnline: newStatus == ConnectionStatus.online));

    // Update offline queue
    _offlineQueue.setOnlineStatus(newStatus == ConnectionStatus.online);

    if (kDebugMode) {
      print('[Connectivity] Status changed: $previousStatus -> $newStatus');
    }

    // If we just came online, trigger sync
    if (previousStatus == ConnectionStatus.offline &&
        newStatus == ConnectionStatus.online) {
      _onReconnected();
    }
  }

  /// Handle reconnection
  void _onReconnected() {
    if (kDebugMode) {
      print('[Connectivity] Reconnected - triggering sync');
    }

    // Sync pending operations
    _offlineQueue.syncPendingOperations();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}

/// Widget to display connectivity status
/// Usage: ConnectivityIndicator() in your app bar or status area
class ConnectivityIndicatorController {
  final ConnectivityService _service = ConnectivityService();

  Stream<ConnectionStatus> get statusStream => _service.statusStream;
  ConnectionStatus get currentStatus => _service.currentStatus;
  bool get isOnline => _service.isOnline;

  void startMonitoring() => _service.startMonitoring();
  void stopMonitoring() => _service.stopMonitoring();
}

/// Extension for easy integration with app lifecycle
extension ConnectivityAppLifecycle on ConnectivityService {
  /// Call when app comes to foreground
  void onAppResumed() {
    checkNow();
    startMonitoring();
  }

  /// Call when app goes to background
  void onAppPaused() {
    stopMonitoring();
  }
}

/// Retry configuration for network operations
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Calculate delay for a specific retry attempt
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;

    final delayMs = initialDelay.inMilliseconds *
        (backoffMultiplier * (attempt - 1)).clamp(1, double.infinity);

    return Duration(
      milliseconds: delayMs.toInt().clamp(0, maxDelay.inMilliseconds),
    );
  }
}

/// Utility for retrying network operations
class NetworkRetry {
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    RetryConfig config = const RetryConfig(),
    bool Function(Exception)? shouldRetry,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < config.maxRetries) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastError = e;
        attempt++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        if (attempt < config.maxRetries) {
          onRetry?.call(attempt, e);

          // Wait before retrying
          final delay = config.delayForAttempt(attempt);
          await Future.delayed(delay);

          if (kDebugMode) {
            print('[NetworkRetry] Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms');
          }
        }
      }
    }

    throw lastError ?? Exception('Operation failed after ${config.maxRetries} attempts');
  }
}

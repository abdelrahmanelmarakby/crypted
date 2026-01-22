import 'dart:async';
import 'dart:ui' show VoidCallback;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypted_app/app/core/constants/firebase_collections.dart';
import 'package:crypted_app/app/core/services/logger_service.dart';
import 'package:crypted_app/app/core/connectivity/connectivity_service.dart';
import 'package:get/get.dart';

/// PERF-008: Connection State Handler
/// Manages Firebase connection state and handles reconnection
/// with exponential backoff for network issues
class ConnectionStateHandler extends GetxController {
  static ConnectionStateHandler get instance =>
      Get.find<ConnectionStateHandler>();

  final _logger = LoggerService.instance;

  // Connection state
  final RxBool isConnected = true.obs;
  final RxBool isFirestoreConnected = true.obs;
  final Rx<FirestoreConnectionState> firestoreState =
      FirestoreConnectionState.connected.obs;

  // Retry configuration
  final int maxRetries = 5;
  final Duration initialRetryDelay = const Duration(seconds: 2);
  int _currentRetryCount = 0;
  Timer? _retryTimer;

  // Subscriptions
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _firestoreSubscription;

  // Callbacks
  final List<VoidCallback> _onConnectedCallbacks = [];
  final List<VoidCallback> _onDisconnectedCallbacks = [];
  final List<void Function(FirestoreConnectionState)> _onStateChangeCallbacks =
      [];

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
    _setupFirestoreListener();
    _logger.info('ConnectionStateHandler initialized', context: 'Connection');
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _firestoreSubscription?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }

  /// Setup network connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = ConnectivityService().statusStream.listen(
      (status) {
        final wasConnected = isConnected.value;
        isConnected.value = status == ConnectionStatus.online;

        if (isConnected.value && !wasConnected) {
          _logger.info('Network connection restored', context: 'Connection');
          _onNetworkRestored();
        } else if (!isConnected.value && wasConnected) {
          _logger.warning('Network connection lost', context: 'Connection');
          _notifyDisconnected();
        }
      },
    );
  }

  /// Setup Firestore connection state listener
  void _setupFirestoreListener() {
    // Listen to Firestore network state using a simple connectivity check
    _checkFirestoreConnection();

    // Periodically check Firestore connection
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected.value) {
        _checkFirestoreConnection();
      }
    });
  }

  /// Check Firestore connection by attempting a read
  Future<void> _checkFirestoreConnection() async {
    try {
      // Try to read from Firestore to verify connection
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.connectionCheck)
          .doc('ping')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));

      if (!isFirestoreConnected.value) {
        isFirestoreConnected.value = true;
        firestoreState.value = FirestoreConnectionState.connected;
        _notifyConnected();
      }
    } catch (e) {
      // Connection failed
      if (isFirestoreConnected.value) {
        isFirestoreConnected.value = false;
        firestoreState.value = FirestoreConnectionState.disconnected;
        _notifyStateChange(FirestoreConnectionState.disconnected);
      }
    }
  }

  /// Handle network restored
  void _onNetworkRestored() {
    firestoreState.value = FirestoreConnectionState.reconnecting;
    _notifyStateChange(FirestoreConnectionState.reconnecting);
    _attemptReconnection();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnection() {
    if (_currentRetryCount >= maxRetries) {
      _logger.warning('Max retries reached', context: 'Connection');
      firestoreState.value = FirestoreConnectionState.failed;
      _notifyStateChange(FirestoreConnectionState.failed);
      return;
    }

    final delay = _calculateBackoffDelay(_currentRetryCount);
    _logger.debug('Attempting reconnection', context: 'Connection', data: {
      'attempt': _currentRetryCount + 1,
      'delay': delay.inMilliseconds,
    });

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () async {
      try {
        await _checkFirestoreConnection();

        if (isFirestoreConnected.value) {
          _currentRetryCount = 0;
          _notifyConnected();
        } else {
          _currentRetryCount++;
          _attemptReconnection();
        }
      } catch (e) {
        _currentRetryCount++;
        _attemptReconnection();
      }
    });
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int retryCount) {
    final delayMs = initialRetryDelay.inMilliseconds * (1 << retryCount);
    // Cap at 1 minute
    return Duration(milliseconds: delayMs.clamp(0, 60000));
  }

  /// Force reconnection attempt
  void forceReconnect() {
    _logger.info('Force reconnection requested', context: 'Connection');
    _currentRetryCount = 0;
    _attemptReconnection();
  }

  /// Register callback for when connected
  void onConnected(VoidCallback callback) {
    _onConnectedCallbacks.add(callback);
  }

  /// Register callback for when disconnected
  void onDisconnected(VoidCallback callback) {
    _onDisconnectedCallbacks.add(callback);
  }

  /// Register callback for state changes
  void onStateChange(void Function(FirestoreConnectionState) callback) {
    _onStateChangeCallbacks.add(callback);
  }

  /// Remove connected callback
  void removeConnectedCallback(VoidCallback callback) {
    _onConnectedCallbacks.remove(callback);
  }

  /// Remove disconnected callback
  void removeDisconnectedCallback(VoidCallback callback) {
    _onDisconnectedCallbacks.remove(callback);
  }

  /// Notify connected callbacks
  void _notifyConnected() {
    for (final callback in _onConnectedCallbacks) {
      callback();
    }
  }

  /// Notify disconnected callbacks
  void _notifyDisconnected() {
    for (final callback in _onDisconnectedCallbacks) {
      callback();
    }
  }

  /// Notify state change callbacks
  void _notifyStateChange(FirestoreConnectionState state) {
    for (final callback in _onStateChangeCallbacks) {
      callback(state);
    }
  }

  /// Execute an operation with retry logic
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          rethrow;
        }

        _logger.debug('Operation failed, retrying', context: 'Connection', data: {
          'attempt': attempts,
          'delay': delay.inMilliseconds,
        });

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// Execute operation only when connected
  Future<T?> whenConnected<T>(Future<T> Function() operation) async {
    if (!isConnected.value || !isFirestoreConnected.value) {
      _logger.warning('Operation skipped: not connected', context: 'Connection');
      return null;
    }

    return await operation();
  }

  /// Queue operation for when connected
  void queueForConnection(Future<void> Function() operation) {
    if (isConnected.value && isFirestoreConnected.value) {
      operation();
    } else {
      // Add to connected callbacks
      late VoidCallback callback;
      callback = () {
        operation();
        removeConnectedCallback(callback);
      };
      onConnected(callback);
    }
  }
}

/// Firestore connection states
enum FirestoreConnectionState {
  connected,
  disconnected,
  reconnecting,
  failed,
}

/// Mixin for controllers that need connection state awareness
mixin ConnectionAwareMixin on GetxController {
  late final ConnectionStateHandler _connectionHandler;
  bool _connectionInitialized = false;

  /// Initialize connection awareness
  void initConnectionAwareness() {
    if (_connectionInitialized) return;

    if (Get.isRegistered<ConnectionStateHandler>()) {
      _connectionHandler = ConnectionStateHandler.instance;
      _connectionHandler.onConnected(_onConnectionRestored);
      _connectionHandler.onDisconnected(_onConnectionLost);
      _connectionInitialized = true;
    }
  }

  /// Called when connection is restored - override in subclass
  void _onConnectionRestored() {
    onConnectionRestored();
  }

  /// Called when connection is lost - override in subclass
  void _onConnectionLost() {
    onConnectionLost();
  }

  /// Override to handle connection restored
  void onConnectionRestored() {}

  /// Override to handle connection lost
  void onConnectionLost() {}

  /// Check if currently connected
  bool get isConnectionOnline =>
      _connectionHandler.isConnected.value &&
      _connectionHandler.isFirestoreConnected.value;

  /// Dispose connection awareness
  void disposeConnectionAwareness() {
    if (_connectionInitialized) {
      _connectionHandler.removeConnectedCallback(_onConnectionRestored);
      _connectionHandler.removeDisconnectedCallback(_onConnectionLost);
    }
  }
}

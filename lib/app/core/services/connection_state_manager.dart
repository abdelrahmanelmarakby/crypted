import 'dart:async';
import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Connection states
enum ConnectionState {
  connected,
  connecting,
  disconnected,
  error,
}

/// Manager for monitoring and maintaining connection state
class ConnectionStateManager {
  static final ConnectionStateManager instance = ConnectionStateManager._();
  ConnectionStateManager._();

  final Rx<ConnectionState> _connectionState = ConnectionState.disconnected.obs;
  final RxBool _isOnline = false.obs;
  final RxString _connectionType = 'none'.obs;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DatabaseEvent>? _firebaseSubscription;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // Getters
  Rx<ConnectionState> get connectionState => _connectionState;
  ConnectionState get currentState => _connectionState.value;
  bool get isOnline => _isOnline.value;
  String get connectionType => _connectionType.value;

  /// Initialize connection monitoring
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        dev.log('🔌 Initializing connection state manager');
      }

      // Check initial connectivity
      await _checkInitialConnectivity();

      // Listen to connectivity changes
      _listenToConnectivityChanges();

      // Monitor Firebase connection
      _monitorFirebaseConnection();

      if (kDebugMode) {
        dev.log('✅ Connection state manager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing connection manager: $e');
      }
    }
  }

  /// Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error checking connectivity: $e');
      }
    }
  }

  /// Listen to connectivity changes
  void _listenToConnectivityChanges() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        _handleConnectivityChange(results);
      },
      onError: (error) {
        if (kDebugMode) {
          dev.log('❌ Connectivity stream error: $error');
        }
      },
    );

    if (kDebugMode) {
      dev.log('👂 Listening to connectivity changes');
    }
  }

  /// Handle connectivity change
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _connectionType.value = 'none';
      _isOnline.value = false;
      _updateConnectionState(ConnectionState.disconnected);

      if (kDebugMode) {
        dev.log('📶 No internet connection');
      }
    } else {
      // Determine connection type
      if (results.contains(ConnectivityResult.wifi)) {
        _connectionType.value = 'wifi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        _connectionType.value = 'mobile';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        _connectionType.value = 'ethernet';
      } else {
        _connectionType.value = 'other';
      }

      _isOnline.value = true;
      _updateConnectionState(ConnectionState.connected);

      if (kDebugMode) {
        dev.log('📶 Connected via ${_connectionType.value}');
      }

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
    }
  }

  /// Monitor Firebase Realtime Database connection
  void _monitorFirebaseConnection() {
    try {
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');

      _firebaseSubscription = connectedRef.onValue.listen(
        (event) {
          final connected = event.snapshot.value as bool? ?? false;

          if (connected) {
            if (kDebugMode) {
              dev.log('🔥 Firebase connected');
            }
            _updateConnectionState(ConnectionState.connected);
          } else {
            if (kDebugMode) {
              dev.log('🔥 Firebase disconnected');
            }
            _updateConnectionState(ConnectionState.disconnected);
            _attemptReconnect();
          }
        },
        onError: (error) {
          if (kDebugMode) {
            dev.log('❌ Firebase connection monitor error: $error');
          }
          _updateConnectionState(ConnectionState.error);
        },
      );

      if (kDebugMode) {
        dev.log('🔥 Monitoring Firebase connection');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error setting up Firebase monitoring: $e');
      }
    }
  }

  /// Update connection state
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState.value != newState) {
      final oldState = _connectionState.value;
      _connectionState.value = newState;

      if (kDebugMode) {
        dev.log('🔄 Connection state: $oldState → $newState');
      }

      // Trigger callbacks or events here
      _onConnectionStateChanged(oldState, newState);
    }
  }

  /// Handle connection state changes
  void _onConnectionStateChanged(
    ConnectionState oldState,
    ConnectionState newState,
  ) {
    switch (newState) {
      case ConnectionState.connected:
        _reconnectTimer?.cancel();
        _reconnectAttempts = 0;
        break;

      case ConnectionState.disconnected:
        // Will attempt reconnect
        break;

      case ConnectionState.connecting:
        // Attempting to connect
        break;

      case ConnectionState.error:
        // Connection error
        break;
    }
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        dev.log('⚠️ Max reconnection attempts reached');
      }
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff: 2^attempts seconds
    final delay = Duration(seconds: 1 << _reconnectAttempts.clamp(0, 5));
    _reconnectAttempts++;

    if (kDebugMode) {
      dev.log('🔄 Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    }

    _updateConnectionState(ConnectionState.connecting);

    _reconnectTimer = Timer(delay, () async {
      await _checkInitialConnectivity();
    });
  }

  /// Manually trigger reconnect
  Future<void> reconnect() async {
    if (kDebugMode) {
      dev.log('🔄 Manual reconnect triggered');
    }

    _reconnectAttempts = 0;
    await _checkInitialConnectivity();
  }

  /// Ping to check connection
  Future<bool> ping() async {
    try {
      if (!_isOnline.value) return false;

      // Simple ping to Firebase
      final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      final snapshot = await connectedRef.get();
      final connected = snapshot.value as bool? ?? false;

      return connected;
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Ping failed: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _firebaseSubscription?.cancel();
    _reconnectTimer?.cancel();

    if (kDebugMode) {
      dev.log('🗑️ Connection state manager disposed');
    }
  }

  /// Get detailed connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'state': _connectionState.value.toString(),
      'isOnline': _isOnline.value,
      'connectionType': _connectionType.value,
      'reconnectAttempts': _reconnectAttempts,
    };
  }
}

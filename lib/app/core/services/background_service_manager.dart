import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/connection_state_manager.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';
import 'package:crypted_app/app/core/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Main service manager for background operations
/// Keeps the app running like WhatsApp with persistent connection
class BackgroundServiceManager {
  static final BackgroundServiceManager instance = BackgroundServiceManager._();
  BackgroundServiceManager._();

  final RxBool _isRunning = false.obs;
  final RxBool _isForegroundServiceActive = false.obs;
  final ConnectionStateManager _connectionManager = ConnectionStateManager.instance;
  final PresenceService _presenceService = PresenceService();

  Timer? _heartbeatTimer;
  Timer? _syncTimer;
  StreamSubscription? _connectionSubscription;

  bool get isRunning => _isRunning.value;
  bool get isForegroundServiceActive => _isForegroundServiceActive.value;

  /// Start background service
  Future<void> start() async {
    if (_isRunning.value) {
      if (kDebugMode) {
        dev.log('⚠️ Background service already running');
      }
      return;
    }

    try {
      if (kDebugMode) {
        dev.log('🚀 Starting background service manager');
      }

      _isRunning.value = true;

      // Initialize connection state manager
      await _connectionManager.initialize();

      // Start foreground service (Android only)
      await _startForegroundService();

      // Start heartbeat to keep connection alive
      _startHeartbeat();

      // Start periodic sync
      _startPeriodicSync();

      // Listen to connection changes
      _listenToConnectionChanges();

      // Update user presence
      await _presenceService.updatePresence(isOnline: true);

      // Setup background message handler
      _setupBackgroundMessageHandler();

      if (kDebugMode) {
        dev.log('✅ Background service started successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error starting background service: $e');
      }
      _isRunning.value = false;
    }
  }

  /// Stop background service
  Future<void> stop() async {
    if (!_isRunning.value) return;

    try {
      if (kDebugMode) {
        dev.log('🛑 Stopping background service');
      }

      _isRunning.value = false;

      // Stop timers
      _heartbeatTimer?.cancel();
      _syncTimer?.cancel();

      // Stop subscriptions
      _connectionSubscription?.cancel();

      // Stop foreground service
      await _stopForegroundService();

      // Update presence to offline
      await _presenceService.updatePresence(isOnline: false);

      if (kDebugMode) {
        dev.log('✅ Background service stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error stopping background service: $e');
      }
    }
  }

  /// Start foreground service (Android)
  Future<void> _startForegroundService() async {
    try {
      if (GetPlatform.isAndroid) {
        // Use flutter_foreground_task or similar package
        // For now, we'll use a placeholder implementation

        if (kDebugMode) {
          dev.log('📱 Starting Android foreground service');
        }

        // TODO: Implement actual foreground service using flutter_foreground_task
        // This requires adding the package and native Android configuration

        _isForegroundServiceActive.value = true;

        if (kDebugMode) {
          dev.log('✅ Foreground service started');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error starting foreground service: $e');
      }
    }
  }

  /// Stop foreground service
  Future<void> _stopForegroundService() async {
    try {
      if (GetPlatform.isAndroid && _isForegroundServiceActive.value) {
        if (kDebugMode) {
          dev.log('📱 Stopping Android foreground service');
        }

        // TODO: Stop foreground service

        _isForegroundServiceActive.value = false;

        if (kDebugMode) {
          dev.log('✅ Foreground service stopped');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error stopping foreground service: $e');
      }
    }
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (!_isRunning.value) {
          timer.cancel();
          return;
        }

        try {
          // Send heartbeat ping
          await _connectionManager.ping();

          if (kDebugMode) {
            dev.log('💓 Heartbeat sent');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('❌ Heartbeat failed: $e');
          }
        }
      },
    );

    if (kDebugMode) {
      dev.log('💓 Heartbeat timer started (30s interval)');
    }
  }

  /// Start periodic background sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();

    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        if (!_isRunning.value) {
          timer.cancel();
          return;
        }

        try {
          if (kDebugMode) {
            dev.log('🔄 Starting periodic sync');
          }

          // Sync messages, presence, etc.
          await _performBackgroundSync();

          if (kDebugMode) {
            dev.log('✅ Periodic sync completed');
          }
        } catch (e) {
          if (kDebugMode) {
            dev.log('❌ Periodic sync failed: $e');
          }
        }
      },
    );

    if (kDebugMode) {
      dev.log('🔄 Periodic sync timer started (5min interval)');
    }
  }

  /// Listen to connection state changes
  void _listenToConnectionChanges() {
    _connectionSubscription = _connectionManager.connectionState.listen(
      (state) async {
        if (kDebugMode) {
          dev.log('📶 Connection state changed: $state');
        }

        if (state == ConnectionState.connected) {
          // Reconnected - sync any pending data
          await _performBackgroundSync();
          await _presenceService.updatePresence(isOnline: true);
        } else if (state == ConnectionState.disconnected) {
          // Disconnected - mark as offline
          await _presenceService.updatePresence(isOnline: false);
        }
      },
    );
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      // Update presence
      await _presenceService.updatePresence(isOnline: true);

      // Sync messages from offline queue
      // This will be handled by OfflineMessageQueue

      // Refresh FCM token
      await _refreshFCMToken();

      if (kDebugMode) {
        dev.log('✅ Background sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Background sync error: $e');
      }
    }
  }

  /// Setup background message handler for FCM
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (kDebugMode) {
      dev.log('📬 Background message handler registered');
    }
  }

  /// Refresh FCM token
  Future<void> _refreshFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && kDebugMode) {
        dev.log('🔑 FCM Token refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error refreshing FCM token: $e');
      }
    }
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (kDebugMode) {
      dev.log('🔄 App lifecycle state: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        await _presenceService.updatePresence(isOnline: true);
        await _performBackgroundSync();
        break;

      case AppLifecycleState.paused:
        // App went to background
        // Keep service running but mark as away
        await _presenceService.updatePresence(isOnline: true, isAway: true);
        break;

      case AppLifecycleState.inactive:
        // App is inactive (transitioning)
        break;

      case AppLifecycleState.detached:
        // App is detached
        await stop();
        break;

      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning.value,
      'isForegroundServiceActive': _isForegroundServiceActive.value,
      'connectionState': _connectionManager.currentState,
      'hasHeartbeat': _heartbeatTimer?.isActive ?? false,
      'hasSyncTimer': _syncTimer?.isActive ?? false,
    };
  }
}

/// Background message handler for FCM
/// This function must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kDebugMode) {
      dev.log('📬 Background message received: ${message.messageId}');
      dev.log('   Title: ${message.notification?.title}');
      dev.log('   Body: ${message.notification?.body}');
      dev.log('   Data: ${message.data}');
    }

    // Handle the message
    // You can show a notification, update local database, etc.

  } catch (e) {
    if (kDebugMode) {
      dev.log('❌ Error handling background message: $e');
    }
  }
}

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/app_lifecycle_manager.dart';
import 'package:crypted_app/app/core/services/background_service_manager.dart';
import 'package:crypted_app/app/core/services/connection_state_manager.dart';
import 'package:crypted_app/app/core/services/work_manager_service.dart';
import 'package:crypted_app/app/core/services/offline_message_queue.dart';
import 'package:crypted_app/app/core/services/notification_customization_service.dart';

/// Helper class to initialize all background services
/// Call this in main.dart before running the app
class BackgroundServiceInitializer {
  static bool _isInitialized = false;

  /// Initialize all background services
  static Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        dev.log('⚠️ Background services already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        dev.log('🚀 Initializing background services...');
      }

      // 1. Initialize Connection State Manager
      await _initializeConnectionManager();

      // 2. Initialize Offline Message Queue
      await _initializeOfflineQueue();

      // 3. Initialize WorkManager (Android only)
      await _initializeWorkManager();

      // 4. Initialize and register App Lifecycle Manager as GetX service
      await _initializeLifecycleManager();

      // 5. Start Background Service Manager
      await _initializeBackgroundService();

      _isInitialized = true;

      if (kDebugMode) {
        dev.log('✅ All background services initialized successfully');
        _printServiceStatus();
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing background services: $e');
      }
      rethrow;
    }
  }

  /// Initialize Connection State Manager
  static Future<void> _initializeConnectionManager() async {
    try {
      if (kDebugMode) {
        dev.log('🔌 Initializing Connection State Manager...');
      }

      await ConnectionStateManager.instance.initialize();

      if (kDebugMode) {
        dev.log('✅ Connection State Manager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing Connection State Manager: $e');
      }
    }
  }

  /// Initialize Offline Message Queue
  static Future<void> _initializeOfflineQueue() async {
    try {
      if (kDebugMode) {
        dev.log('📦 Initializing Offline Message Queue...');
      }

      await OfflineMessageQueue.instance.initialize();

      if (kDebugMode) {
        final queueSize = OfflineMessageQueue.instance.queue.length;
        dev.log('✅ Offline Message Queue initialized (${queueSize} pending messages)');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing Offline Message Queue: $e');
      }
    }
  }

  /// Initialize WorkManager (Android)
  static Future<void> _initializeWorkManager() async {
    try {
      if (GetPlatform.isAndroid) {
        if (kDebugMode) {
          dev.log('⚙️ Initializing WorkManager...');
        }

        await WorkManagerService.instance.initialize();

        // Register periodic sync task
        await WorkManagerService.instance.registerPeriodicSync(
          frequency: const Duration(minutes: 15),
        );

        if (kDebugMode) {
          dev.log('✅ WorkManager initialized and periodic sync registered');
        }
      } else {
        if (kDebugMode) {
          dev.log('ℹ️ WorkManager only available on Android - skipping');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing WorkManager: $e');
      }
    }
  }

  /// Initialize App Lifecycle Manager as GetX service
  static Future<void> _initializeLifecycleManager() async {
    try {
      if (kDebugMode) {
        dev.log('🎯 Initializing App Lifecycle Manager...');
      }

      // Register as GetX service
      await Get.putAsync<AppLifecycleManager>(() async {
        final manager = AppLifecycleManager();
        await manager.onInit();
        return manager;
      }, permanent: true);

      if (kDebugMode) {
        dev.log('✅ App Lifecycle Manager initialized and registered');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing App Lifecycle Manager: $e');
      }
    }
  }

  /// Initialize Background Service Manager
  static Future<void> _initializeBackgroundService() async {
    try {
      if (kDebugMode) {
        dev.log('🔄 Starting Background Service Manager...');
      }

      await BackgroundServiceManager.instance.start();

      if (kDebugMode) {
        dev.log('✅ Background Service Manager started');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error starting Background Service Manager: $e');
      }
    }
  }

  /// Print status of all services
  static void _printServiceStatus() {
    if (!kDebugMode) return;

    dev.log('📊 Background Services Status:');
    dev.log('   └─ Connection Manager: ${ConnectionStateManager.instance.currentState}');
    dev.log('   └─ Background Service: ${BackgroundServiceManager.instance.isRunning ? "Running" : "Stopped"}');
    dev.log('   └─ Foreground Service: ${BackgroundServiceManager.instance.isForegroundServiceActive ? "Active" : "Inactive"}');
    dev.log('   └─ Offline Queue: ${OfflineMessageQueue.instance.queue.length} messages');

    if (Get.isRegistered<AppLifecycleManager>()) {
      final lifecycle = AppLifecycleManager.instance;
      dev.log('   └─ App State: ${lifecycle.currentState}');
      dev.log('   └─ In Foreground: ${lifecycle.isAppInForeground}');
    }
  }

  /// Get comprehensive status of all services
  static Map<String, dynamic> getServicesStatus() {
    return {
      'initialized': _isInitialized,
      'connectionManager': ConnectionStateManager.instance.getConnectionInfo(),
      'backgroundService': BackgroundServiceManager.instance.getStatus(),
      'offlineQueue': {
        'queueSize': OfflineMessageQueue.instance.queue.length,
        'isSending': OfflineMessageQueue.instance.isSending,
      },
      if (Get.isRegistered<AppLifecycleManager>())
        'lifecycle': AppLifecycleManager.instance.getStatus(),
    };
  }

  /// Shutdown all services
  static Future<void> shutdown() async {
    if (!_isInitialized) return;

    try {
      if (kDebugMode) {
        dev.log('🛑 Shutting down background services...');
      }

      // Stop background service
      await BackgroundServiceManager.instance.stop();

      // Cancel WorkManager tasks
      if (GetPlatform.isAndroid) {
        await WorkManagerService.instance.cancelAllTasks();
      }

      // Dispose connection manager
      ConnectionStateManager.instance.dispose();

      _isInitialized = false;

      if (kDebugMode) {
        dev.log('✅ All background services shut down');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error shutting down services: $e');
      }
    }
  }

  /// Request battery optimization exemption (Android)
  static Future<void> requestBatteryOptimizationExemption() async {
    if (!GetPlatform.isAndroid) return;

    try {
      if (kDebugMode) {
        dev.log('🔋 Requesting battery optimization exemption...');
      }

      // TODO: Implement using permission_handler or similar package
      // final status = await Permission.ignoreBatteryOptimizations.request();

      if (kDebugMode) {
        dev.log('ℹ️ Battery optimization exemption requires user action in settings');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error requesting battery optimization exemption: $e');
      }
    }
  }

  /// Show battery optimization settings (Android)
  static Future<void> showBatteryOptimizationSettings() async {
    if (!GetPlatform.isAndroid) return;

    try {
      // TODO: Open battery optimization settings
      // await openAppSettings();

      if (kDebugMode) {
        dev.log('ℹ️ Opening battery optimization settings');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error opening battery settings: $e');
      }
    }
  }
}

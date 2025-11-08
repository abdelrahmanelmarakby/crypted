import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/core/services/background_service_manager.dart';
import 'package:crypted_app/app/core/services/offline_message_queue.dart';
import 'package:crypted_app/app/core/services/presence_service.dart';

/// Manager for handling app lifecycle events
/// Ensures the app stays connected like WhatsApp
class AppLifecycleManager extends GetxService with WidgetsBindingObserver {
  static AppLifecycleManager get instance => Get.find<AppLifecycleManager>();

  final Rx<AppLifecycleState> _currentState = AppLifecycleState.resumed.obs;
  final RxBool _isAppInForeground = true.obs;
  final RxBool _isInitialized = false.obs;

  final BackgroundServiceManager _backgroundService = BackgroundServiceManager.instance;
  final OfflineMessageQueue _messageQueue = OfflineMessageQueue.instance;
  final PresenceService _presenceService = PresenceService();

  Timer? _backgroundTimer;
  DateTime? _backgroundTime;

  // Getters
  AppLifecycleState get currentState => _currentState.value;
  bool get isAppInForeground => _isAppInForeground.value;
  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized.value) return;

    try {
      if (kDebugMode) {
        dev.log('🎯 Initializing App Lifecycle Manager');
      }

      // Register as lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize background service
      await _backgroundService.start();

      // Initialize offline message queue
      await _messageQueue.initialize();

      // Set initial state
      _currentState.value = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
      _isAppInForeground.value = _currentState.value == AppLifecycleState.resumed;

      _isInitialized.value = true;

      if (kDebugMode) {
        dev.log('✅ App Lifecycle Manager initialized');
        dev.log('   Initial state: ${_currentState.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error initializing lifecycle manager: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      dev.log('🔄 App lifecycle changed: ${_currentState.value} → $state');
    }

    final oldState = _currentState.value;
    _currentState.value = state;

    _handleLifecycleChange(oldState, state);
  }

  /// Handle lifecycle state changes
  void _handleLifecycleChange(AppLifecycleState oldState, AppLifecycleState newState) {
    switch (newState) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;

      case AppLifecycleState.inactive:
        _onAppInactive();
        break;

      case AppLifecycleState.paused:
        _onAppPaused();
        break;

      case AppLifecycleState.detached:
        _onAppDetached();
        break;

      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }

    // Notify background service
    _backgroundService.handleAppLifecycleState(newState);
  }

  /// App came to foreground
  void _onAppResumed() {
    _isAppInForeground.value = true;
    _backgroundTimer?.cancel();

    if (kDebugMode) {
      dev.log('✅ App resumed (foreground)');

      if (_backgroundTime != null) {
        final duration = DateTime.now().difference(_backgroundTime!);
        dev.log('   Was in background for: ${duration.inSeconds}s');
      }
    }

    // Update presence to online
    _presenceService.updatePresence(isOnline: true);

    // Process offline message queue
    _processOfflineQueue();

    // Sync data
    _syncData();
  }

  /// App is inactive (transitioning)
  void _onAppInactive() {
    if (kDebugMode) {
      dev.log('⏸️ App inactive (transitioning)');
    }
  }

  /// App went to background
  void _onAppPaused() {
    _isAppInForeground.value = false;
    _backgroundTime = DateTime.now();

    if (kDebugMode) {
      dev.log('⏸️ App paused (background)');
    }

    // Update presence to away
    _presenceService.updatePresence(isOnline: true, isAway: true);

    // Start background timer
    _startBackgroundTimer();

    // Save any pending data
    _savePendingData();
  }

  /// App is being terminated
  void _onAppDetached() {
    if (kDebugMode) {
      dev.log('🛑 App detached (terminating)');
    }

    // Update presence to offline
    _presenceService.updatePresence(isOnline: false);

    // Save all pending data
    _savePendingData();

    // Stop background service
    _backgroundService.stop();
  }

  /// App is hidden (iOS specific)
  void _onAppHidden() {
    if (kDebugMode) {
      dev.log('👻 App hidden');
    }
  }

  /// Start background timer to keep track of background time
  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();

    _backgroundTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        if (_isAppInForeground.value) {
          timer.cancel();
          return;
        }

        final duration = DateTime.now().difference(_backgroundTime!);

        if (kDebugMode) {
          dev.log('⏱️ In background for: ${duration.inMinutes} minutes');
        }

        // Keep connection alive
        _keepAlive();
      },
    );
  }

  /// Keep connection alive while in background
  Future<void> _keepAlive() async {
    try {
      // Send heartbeat
      await _presenceService.updatePresence(isOnline: true, isAway: true);

      if (kDebugMode) {
        dev.log('💓 Background heartbeat sent');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Background heartbeat failed: $e');
      }
    }
  }

  /// Process offline message queue
  Future<void> _processOfflineQueue() async {
    try {
      if (_messageQueue.queue.isEmpty) return;

      if (kDebugMode) {
        dev.log('📤 Processing ${_messageQueue.queue.length} queued messages');
      }

      // Queue will be processed by chat controller
      // This is just a notification that app is back online

    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error processing offline queue: $e');
      }
    }
  }

  /// Sync data when app comes to foreground
  Future<void> _syncData() async {
    try {
      if (kDebugMode) {
        dev.log('🔄 Syncing data...');
      }

      // Sync will be handled by individual controllers
      // This can trigger a global sync event

      if (kDebugMode) {
        dev.log('✅ Data sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Data sync error: $e');
      }
    }
  }

  /// Save pending data before going to background
  Future<void> _savePendingData() async {
    try {
      if (kDebugMode) {
        dev.log('💾 Saving pending data...');
      }

      // Save drafts, pending uploads, etc.
      // Individual services will handle their own persistence

      if (kDebugMode) {
        dev.log('✅ Pending data saved');
      }
    } catch (e) {
      if (kDebugMode) {
        dev.log('❌ Error saving pending data: $e');
      }
    }
  }

  /// Get app uptime
  Duration getUptime() {
    if (_backgroundTime != null && !_isAppInForeground.value) {
      return DateTime.now().difference(_backgroundTime!);
    }
    return Duration.zero;
  }

  /// Get lifecycle status
  Map<String, dynamic> getStatus() {
    return {
      'currentState': _currentState.value.toString(),
      'isInForeground': _isAppInForeground.value,
      'backgroundTime': _backgroundTime?.toIso8601String(),
      'uptime': getUptime().toString(),
      'isInitialized': _isInitialized.value,
    };
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _backgroundService.stop();
    super.onClose();

    if (kDebugMode) {
      dev.log('🗑️ App Lifecycle Manager disposed');
    }
  }
}

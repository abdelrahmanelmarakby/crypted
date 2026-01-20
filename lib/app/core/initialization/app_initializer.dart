// App Initialization Service
// Handles startup tasks including migrations, service initialization, etc.

import 'package:crypted_app/app/core/di/service_locator.dart';
import 'package:crypted_app/app/core/error_handling/error_handler.dart';
import 'package:crypted_app/app/core/events/event_bus.dart';
import 'package:crypted_app/app/core/migration/chat_migration_service.dart';
import 'package:crypted_app/app/core/migration/hive_migration_service.dart';
import 'package:crypted_app/app/core/offline/offline_queue.dart';
import 'package:crypted_app/app/core/services/offline_queue_service.dart';
import 'package:crypted_app/app/core/services/local_database_service.dart';
import 'package:crypted_app/app/core/sync/sync_service.dart';
import 'package:crypted_app/app/core/repositories/chat_repository.dart';
import 'package:crypted_app/app/core/repositories/offline_chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App initialization result
class InitializationResult {
  final bool success;
  final List<String> completedSteps;
  final List<String> errors;
  final Duration duration;

  InitializationResult({
    required this.success,
    required this.completedSteps,
    required this.errors,
    required this.duration,
  });

  @override
  String toString() {
    return '''
InitializationResult:
  Success: $success
  Duration: ${duration.inMilliseconds}ms
  Completed Steps: ${completedSteps.length}
  Errors: ${errors.length}
''';
  }
}

/// Main app initializer
/// Call AppInitializer.initialize() in main.dart before runApp
class AppInitializer {
  static bool _isInitialized = false;

  /// Check if app is already initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize the app with all required services
  static Future<InitializationResult> initialize({
    void Function(String step)? onProgress,
    bool runMigrations = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final completedSteps = <String>[];
    final errors = <String>[];

    try {
      // Step 1: Initialize core services
      onProgress?.call('Initializing core services...');
      await _initializeCoreServices();
      completedSteps.add('Core services');

      // Step 2: Initialize local database (Hive)
      onProgress?.call('Initializing local database...');
      await _initializeLocalDatabase();
      completedSteps.add('Local database (Hive)');

      // Step 3: Initialize offline support
      onProgress?.call('Setting up offline support...');
      await _initializeOfflineSupport();
      completedSteps.add('Offline support');

      // Step 4: Initialize event bus
      onProgress?.call('Setting up event bus...');
      _initializeEventBus();
      completedSteps.add('Event bus');

      // Step 5: Run Firestore migrations if needed
      if (runMigrations) {
        onProgress?.call('Checking for migrations...');
        final migrationResult = await _runMigrations(onProgress);
        if (migrationResult != null) {
          completedSteps.add('Firestore migrations: $migrationResult');
        }
      }

      // Step 6: Run Hive migration for existing users
      onProgress?.call('Checking for Hive migration...');
      final hiveMigrationResult = await _runHiveMigration(onProgress);
      if (hiveMigrationResult != null) {
        completedSteps.add('Hive migration: $hiveMigrationResult');
      }

      // Step 7: Initialize repositories
      onProgress?.call('Initializing repositories...');
      await _initializeRepositories();
      completedSteps.add('Repositories');

      _isInitialized = true;
      stopwatch.stop();

      if (kDebugMode) {
        print('[AppInitializer] Initialization completed in ${stopwatch.elapsedMilliseconds}ms');
        for (final step in completedSteps) {
          print('  ✓ $step');
        }
      }

      return InitializationResult(
        success: true,
        completedSteps: completedSteps,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      errors.add(e.toString());

      if (kDebugMode) {
        print('[AppInitializer] Initialization failed: $e');
      }

      return InitializationResult(
        success: false,
        completedSteps: completedSteps,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Initialize core services (error handler, logger, etc.)
  static Future<void> _initializeCoreServices() async {
    // Initialize ServiceLocator
    if (!Get.isRegistered<ServiceLocator>()) {
      Get.put(ServiceLocator(), permanent: true);
    }

    // Initialize ErrorHandler
    if (!Get.isRegistered<ErrorHandler>()) {
      Get.put(ErrorHandler(), permanent: true);
    }
  }

  /// Initialize local database (Hive) for offline-first architecture
  static Future<void> _initializeLocalDatabase() async {
    final localDb = LocalDatabaseService();
    await localDb.initialize();

    if (kDebugMode) {
      final stats = localDb.getStats();
      print('[AppInitializer] Local database stats: $stats');
    }
  }

  /// Initialize offline support
  static Future<void> _initializeOfflineSupport() async {
    // Initialize the offline queue service with all handlers registered
    await OfflineQueueService().initialize();

    // Start connectivity monitoring
    final monitor = ConnectivityMonitor(OfflineQueueService().queue);
    monitor.start();
  }

  /// Initialize event bus
  static void _initializeEventBus() {
    // EventBus is a singleton, just access it to ensure it's created
    final _ = EventBus();
  }

  /// Run database migrations
  static Future<String?> _runMigrations(
    void Function(String step)? onProgress,
  ) async {
    try {
      final migrationService = ChatMigrationService();
      final needsMigration = await migrationService.isMigrationNeeded();

      if (!needsMigration) {
        if (kDebugMode) {
          print('[AppInitializer] No migrations needed');
        }
        return null;
      }

      if (kDebugMode) {
        print('[AppInitializer] Running chat migration...');
      }

      final result = await migrationService.runMigration(
        onProgress: (progress, message) {
          onProgress?.call('Migration: $message');
        },
      );

      if (result.hasErrors) {
        if (kDebugMode) {
          print('[AppInitializer] Migration completed with errors:');
          for (final error in result.errors) {
            print('  - $error');
          }
        }
        return 'Completed with ${result.errors.length} errors';
      }

      return 'Migrated ${result.migratedRooms} rooms, ${result.migratedMessages} messages';
    } catch (e) {
      if (kDebugMode) {
        print('[AppInitializer] Migration error: $e');
      }
      return 'Error: $e';
    }
  }

  /// Run Hive migration for existing users
  static Future<String?> _runHiveMigration(
    void Function(String step)? onProgress,
  ) async {
    try {
      final hiveMigrationService = HiveMigrationService();
      final needsMigration = await hiveMigrationService.isMigrationNeeded();

      if (!needsMigration) {
        if (kDebugMode) {
          print('[AppInitializer] No Hive migration needed');
        }
        return null;
      }

      if (kDebugMode) {
        print('[AppInitializer] Running Hive migration...');
      }

      final result = await hiveMigrationService.runMigration(
        onProgress: (progress, message) {
          onProgress?.call('Hive migration: $message');
        },
      );

      if (result.hasErrors) {
        if (kDebugMode) {
          print('[AppInitializer] Hive migration completed with errors:');
          for (final error in result.errors) {
            print('  - $error');
          }
        }
        return 'Completed with ${result.errors.length} errors';
      }

      return 'Migrated ${result.migratedRooms} rooms, ${result.migratedMessages} messages';
    } catch (e) {
      if (kDebugMode) {
        print('[AppInitializer] Hive migration error: $e');
      }
      return 'Error: $e';
    }
  }

  /// Initialize repositories
  static Future<void> _initializeRepositories() async {
    // Register chat repository if not already registered
    // Using OfflineChatRepository for offline-first architecture
    if (!Get.isRegistered<IChatRepository>()) {
      Get.put<IChatRepository>(
        OfflineChatRepository(),
        permanent: true,
      );

      if (kDebugMode) {
        print('[AppInitializer] Registered OfflineChatRepository');
      }
    }

    // Register SyncService
    if (!Get.isRegistered<SyncService>()) {
      Get.put(SyncService(), permanent: true);
    }
  }

  /// Cleanup and dispose resources
  static void dispose() {
    EventBus().dispose();
    OfflineQueueService().dispose();
    LocalDatabaseService().dispose();
    SyncService().dispose();
    _isInitialized = false;
  }
}

/// Extension to integrate with main.dart
extension AppInitializerExtension on GetMaterialApp {
  /// Initialize app before building
  static Future<void> initializeBeforeRun() async {
    final result = await AppInitializer.initialize(
      onProgress: (step) {
        if (kDebugMode) {
          print('[Init] $step');
        }
      },
    );

    if (!result.success) {
      if (kDebugMode) {
        print('[Init] Warning: App initialization had issues:');
        for (final error in result.errors) {
          print('  - $error');
        }
      }
    }
  }
}

/// Splash screen that shows initialization progress
/// Can be used as initial route if needed
class InitializationSplashScreen extends StatefulWidget {
  final Widget Function() onComplete;
  final Widget? logo;
  final Color? backgroundColor;

  const InitializationSplashScreen({
    super.key,
    required this.onComplete,
    this.logo,
    this.backgroundColor,
  });

  @override
  State<InitializationSplashScreen> createState() =>
      _InitializationSplashScreenState();
}

class _InitializationSplashScreenState
    extends State<InitializationSplashScreen> {
  String _currentStep = 'Initializing...';
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    await AppInitializer.initialize(
      onProgress: (step) {
        if (mounted) {
          setState(() {
            _currentStep = step;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isComplete = true;
      });

      // Navigate to main app after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.onComplete()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            if (widget.logo != null)
              widget.logo!
            else
              Icon(
                Icons.chat_bubble_rounded,
                size: 80,
                color: Colors.white.withAlpha(230),
              ),

            const SizedBox(height: 48),

            // Progress indicator
            if (!_isComplete)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withAlpha(230),
                  ),
                ),
              )
            else
              Icon(
                Icons.check_circle,
                size: 24,
                color: Colors.white.withAlpha(230),
              ),

            const SizedBox(height: 24),

            // Status text
            Text(
              _currentStep,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

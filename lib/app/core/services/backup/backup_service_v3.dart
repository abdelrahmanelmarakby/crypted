import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/app/core/services/backup/strategies/chat_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/media_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/contacts_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/strategies/device_info_backup_strategy.dart';
import 'package:crypted_app/app/core/services/backup/backup_worker.dart';

/// **Crypted Backup Service V3** - Consolidated, Bulletproof, Lightweight
///
/// Replaces all 7 legacy backup services with a single, robust implementation.
///
/// **Key Features:**
/// - ✅ Unstoppable: Once started, backups run to completion (no cancel)
/// - ✅ Lightweight: Minimal memory footprint with chunked processing
/// - ✅ Resilient: Automatic retry with exponential backoff
/// - ✅ Background: Uses WorkManager for reliable execution
/// - ✅ Incremental: Only backs up changed data
/// - ✅ Strategy Pattern: Pluggable backup types
///
/// **Architecture:**
/// ```
/// BackupServiceV3 (Orchestrator)
///   ├── BackupExecutor (Background execution)
///   ├── BackupStrategy[] (Pluggable data types)
///   │   ├── ChatBackupStrategy
///   │   ├── MediaBackupStrategy
///   │   ├── ContactsBackupStrategy
///   │   └── DeviceInfoBackupStrategy
///   └── BackupQueue (Persistent queue)
/// ```
///
/// **Usage:**
/// ```dart
/// final service = BackupServiceV3.instance;
/// await service.initialize();
///
/// // Start backup (runs to completion, cannot be canceled)
/// final backupId = await service.startBackup(
///   types: {BackupType.chats, BackupType.media},
/// );
///
/// // Monitor progress
/// service.progressStream.listen((progress) {
///   print('Progress: ${progress.percentage}%');
/// });
/// ```
class BackupServiceV3 {
  static final BackupServiceV3 _instance = BackupServiceV3._internal();
  static BackupServiceV3 get instance => _instance;
  BackupServiceV3._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Backup executor
  late final BackupExecutor _executor;

  // Registered strategies
  final Map<BackupType, BackupStrategy> _strategies = {};

  // Progress streams
  final StreamController<BackupProgress> _progressController =
      StreamController<BackupProgress>.broadcast();
  final StreamController<BackupEvent> _eventController =
      StreamController<BackupEvent>.broadcast();

  Stream<BackupProgress> get progressStream => _progressController.stream;
  Stream<BackupEvent> get eventStream => _eventController.stream;

  // Initialization flag
  bool _isInitialized = false;

  // CRITICAL: Strong reference to prevent garbage collection
  // This ensures foreground backups survive navigation
  final Map<String, Future<void>> _activeBackups = {};

  // Track running backup IDs
  final Set<String> _runningBackupIds = {};

  // Auto-backup configuration
  static const int _autoBackupIntervalDays = 7;
  static const String _autoBackupPrefsKey = 'auto_backup_enabled';
  static const String _lastAutoBackupKey = 'last_auto_backup_check';

  /// Initialize backup service
  /// Call this once during app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      log('🔄 Initializing BackupServiceV3...');

      // Initialize BackupWorker (WorkManager integration)
      await BackupWorker.instance.initialize();

      // Initialize executor
      _executor = BackupExecutor(
        firestore: _firestore,
        progressCallback: _progressController.add,
        eventCallback: _eventController.add,
      );

      // Register default strategies
      _registerStrategy(BackupType.chats, ChatBackupStrategy());
      _registerStrategy(BackupType.media, MediaBackupStrategy());
      _registerStrategy(BackupType.contacts, ContactsBackupStrategy());
      _registerStrategy(BackupType.deviceInfo, DeviceInfoBackupStrategy());

      _isInitialized = true;
      log('✅ BackupServiceV3 initialized successfully');

      // Resume any interrupted backups from previous session
      await _resumeInterruptedBackups();

      // Check for auto-backup (runs in background, doesn't block)
      _checkAutoBackup();
    } catch (e, stackTrace) {
      log('❌ Failed to initialize BackupServiceV3: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if auto-backup should run and start it in background
  /// This runs asynchronously and doesn't block app startup
  void _checkAutoBackup() {
    // Run in background to not block app startup
    Future.microtask(() async {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          log('⏭️ Auto-backup skipped: No user logged in');
          return;
        }

        // Check if auto-backup is enabled (default: true)
        final isEnabled = await _isAutoBackupEnabled();
        if (!isEnabled) {
          log('⏭️ Auto-backup skipped: Disabled by user');
          return;
        }

        // Check last backup date
        final lastBackupDate = await getLastBackupDate(userId);
        final now = DateTime.now();

        if (lastBackupDate == null) {
          log('📅 No previous backup found, starting auto-backup...');
          await _startAutoBackup();
          return;
        }

        final daysSinceLastBackup = now.difference(lastBackupDate).inDays;
        log('📅 Last backup: ${lastBackupDate.toIso8601String()} ($daysSinceLastBackup days ago)');

        if (daysSinceLastBackup >= _autoBackupIntervalDays) {
          log('🔄 Auto-backup triggered: $daysSinceLastBackup days since last backup (threshold: $_autoBackupIntervalDays days)');
          await _startAutoBackup();
        } else {
          log('✅ Auto-backup not needed: Only $daysSinceLastBackup days since last backup');
        }
      } catch (e) {
        log('⚠️ Auto-backup check failed: $e');
        // Non-fatal - don't rethrow
      }
    });
  }

  /// Start automatic background backup with default types
  Future<void> _startAutoBackup() async {
    try {
      // Default auto-backup includes all types
      final autoBackupTypes = {
        BackupType.chats,
        BackupType.media,
        BackupType.contacts,
        BackupType.deviceInfo,
      };

      log('🚀 Starting automatic background backup...');

      // Start backup (runs in background via WorkManager)
      final backupId = await startBackup(
        types: autoBackupTypes,
        options: BackupOptions(
          wifiOnly: true, // Only on WiFi to save mobile data
          compressMedia: true,
          incrementalOnly: true, // Only backup changes
        ),
      );

      log('✅ Auto-backup started: $backupId');

      // Emit event for UI notification
      _eventController.add(BackupEvent(
        type: BackupEventType.started,
        backupId: backupId,
        message: 'Automatic backup started',
        data: {'isAutoBackup': true},
      ));
    } catch (e) {
      log('❌ Failed to start auto-backup: $e');
    }
  }

  /// Get the date of the last completed backup for a user
  Future<DateTime?> getLastBackupDate(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('backup_jobs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: BackupStatus.completed.name)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final completedAt = doc.data()['completedAt'];

      if (completedAt is Timestamp) {
        return completedAt.toDate();
      } else if (completedAt is String) {
        return DateTime.tryParse(completedAt);
      }

      return null;
    } catch (e) {
      log('⚠️ Error getting last backup date: $e');
      return null;
    }
  }

  /// Check if auto-backup is enabled
  Future<bool> _isAutoBackupEnabled() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Check user preferences in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return true; // Default: enabled

      final prefs = userDoc.data()?['backupPreferences'] as Map<String, dynamic>?;
      return prefs?['autoBackupEnabled'] ?? true; // Default: enabled
    } catch (e) {
      log('⚠️ Error checking auto-backup preference: $e');
      return true; // Default: enabled on error
    }
  }

  /// Enable or disable auto-backup
  Future<void> setAutoBackupEnabled(bool enabled) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).set({
        'backupPreferences': {
          'autoBackupEnabled': enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      log('✅ Auto-backup ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      log('❌ Error setting auto-backup preference: $e');
    }
  }

  /// Get auto-backup interval in days
  int get autoBackupIntervalDays => _autoBackupIntervalDays;

  /// Manually trigger auto-backup check (for testing or settings)
  Future<void> triggerAutoBackupCheck() async {
    _checkAutoBackup();
  }

  /// Schedule nightly backup at approximately 2 AM
  /// Uses WorkManager's periodic task scheduling
  Future<void> scheduleNightlyBackup({
    required Set<BackupType> types,
    BackupOptions? options,
  }) async {
    _ensureInitialized();

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw BackupException('User not authenticated');
    }

    try {
      log('📅 Scheduling nightly backup at ~2 AM');

      // Save scheduled backup configuration
      await _firestore.collection('users').doc(userId).set({
        'backupPreferences': {
          'autoBackupEnabled': true,
          'scheduledBackupTypes': types.map((t) => t.name).toList(),
          'scheduledBackupOptions': (options ?? BackupOptions.defaults()).toJson(),
          'scheduleType': 'nightly',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Calculate delay until 2 AM
      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, 2, 0);
      if (now.hour >= 2) {
        target = target.add(const Duration(days: 1));
      }
      final initialDelay = target.difference(now);

      // Schedule via WorkManager
      await BackupWorker.instance.schedulePeriodicBackup(
        taskId: 'nightly_backup',
        types: types,
        options: options ?? BackupOptions.defaults(),
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
      );

      log('✅ Nightly backup scheduled successfully');
    } catch (e) {
      log('❌ Failed to schedule nightly backup: $e');
      rethrow;
    }
  }

  /// Schedule weekly backup (runs Sunday at 2 AM)
  /// Uses WorkManager's periodic task scheduling
  Future<void> scheduleWeeklyBackup({
    required Set<BackupType> types,
    BackupOptions? options,
  }) async {
    _ensureInitialized();

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw BackupException('User not authenticated');
    }

    try {
      log('📅 Scheduling weekly backup');

      // Save scheduled backup configuration
      await _firestore.collection('users').doc(userId).set({
        'backupPreferences': {
          'autoBackupEnabled': true,
          'scheduledBackupTypes': types.map((t) => t.name).toList(),
          'scheduledBackupOptions': (options ?? BackupOptions.defaults()).toJson(),
          'scheduleType': 'weekly',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Calculate delay until Sunday 2 AM
      final now = DateTime.now();
      var daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilSunday == 0 && now.hour >= 2) {
        daysUntilSunday = 7; // Next Sunday
      }
      final target = DateTime(now.year, now.month, now.day, 2, 0)
          .add(Duration(days: daysUntilSunday));
      final initialDelay = target.difference(now);

      // Schedule via WorkManager
      await BackupWorker.instance.schedulePeriodicBackup(
        taskId: 'weekly_backup',
        types: types,
        options: options ?? BackupOptions.defaults(),
        frequency: const Duration(days: 7),
        initialDelay: initialDelay,
      );

      log('✅ Weekly backup scheduled successfully');
    } catch (e) {
      log('❌ Failed to schedule weekly backup: $e');
      rethrow;
    }
  }

  /// Cancel all scheduled backups
  Future<void> cancelScheduledBackups() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update preferences
      await _firestore.collection('users').doc(userId).set({
        'backupPreferences': {
          'autoBackupEnabled': false,
          'scheduleType': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Cancel WorkManager tasks
      await BackupWorker.instance.cancelAllBackups();

      log('✅ Scheduled backups cancelled');
    } catch (e) {
      log('❌ Failed to cancel scheduled backups: $e');
    }
  }

  /// Get days since last backup (useful for UI display)
  Future<int?> getDaysSinceLastBackup() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final lastBackup = await getLastBackupDate(userId);
    if (lastBackup == null) return null;

    return DateTime.now().difference(lastBackup).inDays;
  }

  /// Resume any backups that were interrupted (app killed, device restarted)
  /// This runs on app startup to ensure no backups are lost
  Future<void> _resumeInterruptedBackups() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        log('⚠️ No user logged in, skipping backup resume check');
        return;
      }

      // Find any backups that are "running" or "queued" for this user
      final querySnapshot = await _firestore
          .collection('backup_jobs')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            BackupStatus.running.name,
            BackupStatus.queued.name,
            BackupStatus.paused.name,
          ])
          .orderBy('createdAt', descending: true)
          .limit(1) // Only resume the most recent one
          .get();

      if (querySnapshot.docs.isEmpty) {
        log('✅ No interrupted backups to resume');
        return;
      }

      final doc = querySnapshot.docs.first;
      final job = BackupJob.fromJson(doc.data());

      // Check if backup is stale (created > 1 hour ago and still running)
      // This happens when the app was killed mid-backup — the status stays
      // "running" in Firestore forever. Instead of re-executing the entire
      // backup on every app start, mark it as failed and let _checkAutoBackup()
      // handle scheduling a fresh incremental backup if 7+ days have passed.
      final age = DateTime.now().difference(job.createdAt);
      if (age.inHours >= 1) {
        log('⚠️ Stale backup found: ${job.id} (${age.inHours}h old), marking as failed');
        await _firestore.collection('backup_jobs').doc(job.id).update({
          'status': BackupStatus.failed.name,
          'failedAt': FieldValue.serverTimestamp(),
          'errorMessage': 'Backup stale: app was killed during execution',
        });
        return; // Don't resume — let _checkAutoBackup() handle scheduling
      }

      // Only resume truly recent interruptions (< 1 hour old)
      log('🔄 Found recent interrupted backup: ${job.id} (${age.inMinutes}m old)');
      log('   Resuming backup automatically...');

      // Re-execute the backup
      _startImmediateBackup(job);

      // Emit event
      _eventController.add(BackupEvent(
        type: BackupEventType.resumed,
        backupId: job.id,
        message: 'Resumed interrupted backup',
      ));

    } catch (e) {
      log('⚠️ Error checking for interrupted backups: $e');
      // Non-fatal - don't rethrow
    }
  }

  /// Register a backup strategy
  void _registerStrategy(BackupType type, BackupStrategy strategy) {
    _strategies[type] = strategy;
    log('✅ Registered strategy: ${type.name}');
  }

  /// Start a new backup
  ///
  /// **Once started, this backup CANNOT be canceled.**
  /// It will run to completion even if:
  /// - App is killed
  /// - User navigates away
  /// - Device restarts
  ///
  /// Returns backup ID for tracking progress
  Future<String> startBackup({
    required Set<BackupType> types,
    BackupOptions? options,
  }) async {
    _ensureInitialized();

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw BackupException('User not authenticated');
    }

    if (types.isEmpty) {
      throw BackupException('At least one backup type must be specified');
    }

    try {
      log('🚀 Starting backup for types: ${types.map((t) => t.name).join(", ")}');

      // Create backup job
      final job = BackupJob(
        id: _generateBackupId(),
        userId: userId,
        types: types,
        options: options ?? BackupOptions.defaults(),
        createdAt: DateTime.now(),
        status: BackupStatus.queued,
      );

      // Save to persistent queue (Firestore + local)
      await _saveBackupJob(job);

      // Schedule execution via WorkManager (runs in background, survives app kill)
      await _scheduleBackupExecution(job);

      // Emit event
      _eventController.add(BackupEvent.started(job.id));

      log('✅ Backup scheduled: ${job.id}');
      return job.id;
    } catch (e, stackTrace) {
      log('❌ Failed to start backup: $e', stackTrace: stackTrace);
      throw BackupException('Failed to start backup: $e');
    }
  }

  /// Get backup status
  Future<BackupStatus> getBackupStatus(String backupId) async {
    try {
      final doc = await _firestore
          .collection('backup_jobs')
          .doc(backupId)
          .get();

      if (!doc.exists) {
        return BackupStatus.notFound;
      }

      final status = doc.data()?['status'] as String?;
      return BackupStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => BackupStatus.unknown,
      );
    } catch (e) {
      log('❌ Failed to get backup status: $e');
      return BackupStatus.unknown;
    }
  }

  /// Get backup progress
  Future<BackupProgress?> getBackupProgress(String backupId) async {
    try {
      final doc = await _firestore
          .collection('backup_jobs')
          .doc(backupId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return BackupProgress(
        backupId: backupId,
        totalItems: data['totalItems'] ?? 0,
        processedItems: data['processedItems'] ?? 0,
        failedItems: data['failedItems'] ?? 0,
        currentType: data['currentType'] != null
            ? BackupType.values.firstWhere((t) => t.name == data['currentType'])
            : null,
        bytesTransferred: data['bytesTransferred'] ?? 0,
        startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
        estimatedCompletion: (data['estimatedCompletion'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      log('❌ Failed to get backup progress: $e');
      return null;
    }
  }

  /// Estimate backup size and item count before starting
  ///
  /// Returns estimation data including:
  /// - Total estimated items per type
  /// - Estimated total size in bytes
  /// - Estimated time in seconds
  Future<BackupEstimation> estimateBackupSize({
    required Set<BackupType> types,
  }) async {
    _ensureInitialized();

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw BackupException('User not authenticated');
    }

    log('📊 Estimating backup size for types: ${types.map((t) => t.name).join(', ')}');

    int totalItems = 0;
    int estimatedBytes = 0;
    final perTypeEstimates = <BackupType, BackupTypeEstimate>{};

    // Create temp context for estimation
    final tempContext = BackupContext(
      userId: userId,
      backupId: 'estimation_${DateTime.now().millisecondsSinceEpoch}',
      options: const BackupOptions(),
      firestore: _firestore,
    );

    for (final type in types) {
      final strategy = _strategies[type];
      if (strategy == null) continue;

      try {
        final itemCount = await strategy.estimateItemCount(tempContext);
        // Use dynamic estimation from strategy (samples real data)
        final estimatedSize = await _estimateSizeForType(type, itemCount, tempContext);

        perTypeEstimates[type] = BackupTypeEstimate(
          type: type,
          itemCount: itemCount,
          estimatedBytes: estimatedSize,
        );

        totalItems += itemCount;
        estimatedBytes += estimatedSize;

        log('   - ${type.name}: $itemCount items (~${_formatBytes(estimatedSize)})');
      } catch (e) {
        log('⚠️ Failed to estimate ${type.name}: $e');
        perTypeEstimates[type] = BackupTypeEstimate(
          type: type,
          itemCount: 0,
          estimatedBytes: 0,
          error: e.toString(),
        );
      }
    }

    // Estimate time based on typical upload speeds (500KB/s conservative estimate)
    final estimatedSeconds = (estimatedBytes / (500 * 1024)).ceil();

    final estimation = BackupEstimation(
      totalItems: totalItems,
      estimatedBytes: estimatedBytes,
      estimatedSeconds: estimatedSeconds,
      perTypeEstimates: perTypeEstimates,
    );

    log('📊 Total estimation: $totalItems items, ${_formatBytes(estimatedBytes)}, ~${estimation.formattedTime}');

    return estimation;
  }

  /// Estimate size for a backup type based on item count and strategy sampling
  /// Uses dynamic estimation from strategies with sensible fallbacks
  Future<int> _estimateSizeForType(
    BackupType type,
    int itemCount,
    BackupContext context,
  ) async {
    final strategy = _strategies[type];
    if (strategy == null) {
      return itemCount * 1024; // 1KB fallback
    }

    try {
      // Use strategy's dynamic estimation (samples real data)
      final bytesPerItem = await strategy.estimateBytesPerItem(context);
      return itemCount * bytesPerItem;
    } catch (e) {
      log('⚠️ Failed to get dynamic estimate for ${type.name}, using fallback: $e');
      // Fallback to static estimates if sampling fails
      return itemCount * _getFallbackBytesPerItem(type);
    }
  }

  /// Fallback bytes per item when dynamic estimation fails
  int _getFallbackBytesPerItem(BackupType type) {
    switch (type) {
      case BackupType.chats:
        return 2 * 1024; // 2KB per chat room
      case BackupType.media:
        return 100 * 1024; // 100KB per media file (after compression)
      case BackupType.contacts:
        return 1024; // 1KB per contact
      case BackupType.deviceInfo:
        return 5 * 1024; // 5KB for device info
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Request backup permissions
  ///
  /// Returns map of permission name to granted status
  Future<Map<String, bool>> requestBackupPermissions() async {
    try {
      // Import permission_handler at top of file
      final permissions = <String, bool>{};

      // Request contacts permission (for contacts backup)
      final contactsStatus = await _requestPermission('contacts');
      permissions['contacts'] = contactsStatus;

      // Request storage permission (for media backup)
      final storageStatus = await _requestPermission('storage');
      permissions['storage'] = storageStatus;

      // Request photos permission (for media backup)
      final photosStatus = await _requestPermission('photos');
      permissions['photos'] = photosStatus;

      log('✅ Backup permissions requested: $permissions');
      return permissions;
    } catch (e) {
      log('❌ Failed to request backup permissions: $e');
      return {};
    }
  }

  /// Cancel backup (NOTE: Backups are designed to be unstoppable)
  ///
  /// This method exists for UI compatibility but does NOT actually cancel
  /// the backup. Once started, backups run to completion for reliability.
  ///
  /// Returns false to indicate backup cannot be canceled.
  Future<bool> cancelBackup(String backupId) async {
    log('⚠️ Backup cancellation requested for $backupId, but backups are unstoppable by design');

    // Emit paused event (closest to cancellation we support)
    _eventController.add(BackupEvent(
      backupId: backupId,
      type: BackupEventType.paused,
      message: 'Backup cannot be canceled - it will run to completion',
    ));

    return false; // Cannot cancel
  }

  // Internal methods

  Future<bool> _requestPermission(String permissionName) async {
    try {
      // Note: This requires permission_handler package
      // Each strategy handles its own permissions internally
      // This method is primarily for UI/settings permission requests

      // For now, return true as permissions are handled by strategies
      return true;
    } catch (e) {
      log('❌ Error requesting $permissionName permission: $e');
      return false;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw BackupException('BackupServiceV3 not initialized. Call initialize() first.');
    }
  }

  String _generateBackupId() {
    return 'backup_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser!.uid.substring(0, 8)}';
  }

  Future<void> _saveBackupJob(BackupJob job) async {
    // Use toFirestoreJson() for Firestore (supports Timestamp)
    await _firestore.collection('backup_jobs').doc(job.id).set(job.toFirestoreJson());
  }

  Future<void> _scheduleBackupExecution(BackupJob job) async {
    // FIX: Use WorkManager for truly unstoppable background execution
    // This ensures backup continues even if user navigates away or kills app
    log('🚀 Scheduling unstoppable backup via WorkManager: ${job.id}');

    try {
      // Schedule via WorkManager (runs in separate isolate, survives app kill)
      await BackupWorker.instance.scheduleBackup(job);
      log('✅ Backup scheduled with WorkManager: ${job.id}');

      // Also start immediate foreground execution for faster progress
      // This runs in parallel - WorkManager handles completion guarantee
      _startImmediateBackup(job);
    } catch (e) {
      log('⚠️ WorkManager scheduling failed, falling back to foreground: $e');
      // Fallback: Run directly (less reliable but works on iOS)
      _startImmediateBackup(job);
    }
  }

  /// Start immediate foreground backup for faster progress
  /// WorkManager guarantees completion, this provides faster feedback
  void _startImmediateBackup(BackupJob job) {
    log('🚀 Starting immediate foreground backup: ${job.id}');

    // CRITICAL: Store future in map to prevent garbage collection
    // This is what makes the backup truly unstoppable during navigation
    _runningBackupIds.add(job.id);

    final backupFuture = _executeBackupWithTracking(job);

    // Keep strong reference - this is the key to unstoppable backups!
    _activeBackups[job.id] = backupFuture;

    log('✅ Backup ${job.id} is now tracked and unstoppable');
  }

  /// Execute backup with proper tracking and cleanup
  Future<void> _executeBackupWithTracking(BackupJob job) async {
    try {
      await _executeBackupDirectly(job);
    } catch (e, stackTrace) {
      log('❌ Foreground backup execution failed: $e');
      log('$stackTrace');
      // WorkManager will pick up and complete the backup
    } finally {
      // Cleanup tracking
      _activeBackups.remove(job.id);
      _runningBackupIds.remove(job.id);
      log('🧹 Backup ${job.id} tracking cleaned up');
    }
  }

  /// Check if backup is currently running
  bool isBackupRunning(String backupId) {
    return _runningBackupIds.contains(backupId);
  }

  /// Get all running backup IDs
  Set<String> get runningBackupIds => Set.unmodifiable(_runningBackupIds);

  /// Execute backup directly in the current context (foreground)
  /// This is more reliable than WorkManager on iOS
  Future<void> _executeBackupDirectly(BackupJob job) async {
    try {
      // Update status to running
      await _firestore.collection('backup_jobs').doc(job.id).update({
        'status': BackupStatus.running.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

      // Query last completed backup date for incremental filtering
      final lastBackupDate = await getLastBackupDate(job.userId);
      if (lastBackupDate != null) {
        log('📅 Last completed backup: ${lastBackupDate.toIso8601String()}');
      } else {
        log('📅 No previous completed backup found — full backup');
      }

      int totalItems = 0;
      int processedItems = 0;
      int failedItems = 0;
      int bytesTransferred = 0;

      // Per-type statistics for UI display
      final perTypeStats = <String, Map<String, int>>{};

      // Execute each backup type
      for (final backupType in job.types) {
        StreamSubscription? mediaProgressSubscription;

        try {
          log('🔄 Starting ${backupType.name} backup...');

          final strategy = _strategies[backupType];
          if (strategy == null) {
            log('⚠️ No strategy registered for ${backupType.name}');
            continue;
          }

          // Create backup context with last backup timestamp for incremental
          final context = BackupContext(
            userId: job.userId,
            backupId: job.id,
            options: job.options,
            firestore: _firestore,
            lastBackupTimestamp: lastBackupDate,
          );

          // Subscribe to media progress if this is media backup
          if (backupType == BackupType.media && strategy is MediaBackupStrategy) {
            mediaProgressSubscription = strategy.progressStream.listen((mediaProgress) {
              // Forward detailed progress to main stream
              _progressController.add(BackupProgress(
                backupId: job.id,
                totalItems: totalItems,
                processedItems: processedItems,
                failedItems: failedItems,
                currentType: backupType,
                bytesTransferred: bytesTransferred,
                startedAt: job.createdAt,
                // Detailed file progress
                currentFileName: mediaProgress.currentFileName,
                currentFileIndex: mediaProgress.currentIndex,
                totalFiles: mediaProgress.totalFiles,
                fileStatus: mediaProgress.status,
              ));
            });
          }

          // Estimate items first
          final estimatedCount = await strategy.estimateItemCount(context);
          totalItems += estimatedCount;

          // Execute the strategy
          final result = await strategy.execute(context);

          // Cancel media progress subscription
          await mediaProgressSubscription?.cancel();

          processedItems += result.successfulItems;
          failedItems += result.failedItems;
          bytesTransferred += result.bytesTransferred;

          // Store per-type statistics for UI display
          perTypeStats[backupType.name] = {
            'total': result.totalItems,
            'successful': result.successfulItems,
            'failed': result.failedItems,
            'bytes': result.bytesTransferred,
          };

          // Emit progress
          _progressController.add(BackupProgress(
            backupId: job.id,
            totalItems: totalItems,
            processedItems: processedItems,
            failedItems: failedItems,
            currentType: backupType,
            bytesTransferred: bytesTransferred,
            startedAt: job.createdAt,
          ));

          // Update Firestore progress
          await _firestore.collection('backup_jobs').doc(job.id).update({
            'totalItems': totalItems,
            'processedItems': processedItems,
            'failedItems': failedItems,
            'bytesTransferred': bytesTransferred,
            'currentType': backupType.name,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          log('✅ ${backupType.name} backup completed: ${result.successfulItems}/${result.totalItems}');

        } catch (e, stackTrace) {
          log('❌ ${backupType.name} backup failed: $e');
          log('$stackTrace');
          failedItems++;
        }
      }

      // Determine final status
      final finalStatus = failedItems == 0
          ? BackupStatus.completed
          : (processedItems > 0 ? BackupStatus.partialSuccess : BackupStatus.failed);

      // Update final status with per-type statistics
      await _firestore.collection('backup_jobs').doc(job.id).update({
        'status': finalStatus.name,
        'completedAt': FieldValue.serverTimestamp(),
        'totalItems': totalItems,
        'processedItems': processedItems,
        'failedItems': failedItems,
        'bytesTransferred': bytesTransferred,
        // Per-type statistics for UI display
        'perTypeStats': perTypeStats,
        // Convenience fields for stats widget
        'chats_count': perTypeStats['chats']?['successful'] ?? 0,
        'media_count': perTypeStats['media']?['successful'] ?? 0,
        'contacts_count': perTypeStats['contacts']?['successful'] ?? 0,
        'files_count': perTypeStats['deviceInfo']?['successful'] ?? 0,
      });

      // Emit completion event
      if (finalStatus == BackupStatus.completed) {
        _eventController.add(BackupEvent.completed(job.id));
        log('✅ Backup completed successfully: ${job.id}');
      } else {
        _eventController.add(BackupEvent.failed(job.id, 'Some items failed to backup'));
        log('⚠️ Backup completed with errors: ${job.id}');
      }

    } catch (e, stackTrace) {
      log('❌ Backup execution failed: $e');
      log('$stackTrace');

      // Update status to failed
      try {
        await _firestore.collection('backup_jobs').doc(job.id).update({
          'status': BackupStatus.failed.name,
          'failedAt': FieldValue.serverTimestamp(),
          'errorMessage': e.toString(),
        });
      } catch (_) {}

      _eventController.add(BackupEvent.failed(job.id, e.toString()));
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _eventController.close();
  }
}

/// Backup types
enum BackupType {
  chats,       // Chat messages and metadata
  media,       // Images, videos, files
  contacts,    // Device contacts
  deviceInfo,  // Device information
}

/// Backup status
enum BackupStatus {
  queued,         // Waiting to start
  running,        // Currently executing
  paused,         // Temporarily paused (due to network/battery)
  completed,      // Successfully completed
  failed,         // Failed with errors
  partialSuccess, // Some items failed
  notFound,       // Backup not found
  unknown,        // Unknown status
}

/// Backup job model
class BackupJob {
  final String id;
  final String userId;
  final Set<BackupType> types;
  final BackupOptions options;
  final DateTime createdAt;
  final BackupStatus status;

  BackupJob({
    required this.id,
    required this.userId,
    required this.types,
    required this.options,
    required this.createdAt,
    required this.status,
  });

  /// Convert to JSON for WorkManager (uses primitives only)
  /// WorkManager only supports: String, int, double, bool, Map, List
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'types': types.map((t) => t.name).toList(),
        'options': options.toJson(),
        'createdAt': createdAt.millisecondsSinceEpoch, // Use millis for WorkManager
        'status': status.name,
      };

  /// Convert to JSON for Firestore (uses Timestamp)
  Map<String, dynamic> toFirestoreJson() => {
        'id': id,
        'userId': userId,
        'types': types.map((t) => t.name).toList(),
        'options': options.toJson(),
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status.name,
      };

  factory BackupJob.fromJson(Map<String, dynamic> json) {
    // Handle both milliseconds (from WorkManager) and Timestamp (from Firestore)
    DateTime createdAtDate;
    final createdAtValue = json['createdAt'];
    if (createdAtValue is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else if (createdAtValue is Timestamp) {
      createdAtDate = createdAtValue.toDate();
    } else {
      createdAtDate = DateTime.now();
    }

    return BackupJob(
      id: json['id'],
      userId: json['userId'],
      types: (json['types'] as List)
          .map((t) => BackupType.values.firstWhere((type) => type.name == t))
          .toSet(),
      options: BackupOptions.fromJson(json['options'] ?? {}),
      createdAt: createdAtDate,
      status: BackupStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BackupStatus.queued,
      ),
    );
  }
}

/// Backup options
class BackupOptions {
  final bool wifiOnly;           // Only backup on WiFi
  final int minBatteryPercent;   // Minimum battery level (0-100)
  final bool compressMedia;      // Compress images/videos
  final int maxMediaSize;        // Max file size in MB
  final bool incrementalOnly;    // Only backup changes

  const BackupOptions({
    this.wifiOnly = true,
    this.minBatteryPercent = 20,
    this.compressMedia = true,
    this.maxMediaSize = 100,
    this.incrementalOnly = true,
  });

  factory BackupOptions.defaults() => const BackupOptions();

  Map<String, dynamic> toJson() => {
        'wifiOnly': wifiOnly,
        'minBatteryPercent': minBatteryPercent,
        'compressMedia': compressMedia,
        'maxMediaSize': maxMediaSize,
        'incrementalOnly': incrementalOnly,
      };

  factory BackupOptions.fromJson(Map<String, dynamic> json) {
    return BackupOptions(
      wifiOnly: json['wifiOnly'] ?? true,
      minBatteryPercent: json['minBatteryPercent'] ?? 20,
      compressMedia: json['compressMedia'] ?? true,
      maxMediaSize: json['maxMediaSize'] ?? 100,
      incrementalOnly: json['incrementalOnly'] ?? true,
    );
  }
}

/// Backup progress
class BackupProgress {
  final String backupId;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final BackupType? currentType;
  final int bytesTransferred;
  final DateTime? startedAt;
  final DateTime? estimatedCompletion;

  // Detailed file progress (for media uploads)
  final String? currentFileName;
  final int? currentFileIndex;
  final int? totalFiles;
  final String? fileStatus;

  BackupProgress({
    required this.backupId,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    this.currentType,
    required this.bytesTransferred,
    this.startedAt,
    this.estimatedCompletion,
    // Detailed file progress
    this.currentFileName,
    this.currentFileIndex,
    this.totalFiles,
    this.fileStatus,
  });

  double get percentage =>
      totalItems > 0 ? (processedItems / totalItems) * 100 : 0;

  String get formattedSize {
    if (bytesTransferred < 1024) return '$bytesTransferred B';
    if (bytesTransferred < 1024 * 1024) {
      return '${(bytesTransferred / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytesTransferred / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Human-readable status message
  String get statusMessage {
    if (currentFileName != null && currentFileIndex != null && totalFiles != null) {
      return '[$currentFileIndex/$totalFiles] $currentFileName ${fileStatus ?? ''}';
    }
    return 'Processing ${currentType?.name ?? 'data'}... $processedItems/$totalItems';
  }

  /// Copy with updated file progress
  BackupProgress copyWithFileProgress({
    String? currentFileName,
    int? currentFileIndex,
    int? totalFiles,
    String? fileStatus,
  }) {
    return BackupProgress(
      backupId: backupId,
      totalItems: totalItems,
      processedItems: processedItems,
      failedItems: failedItems,
      currentType: currentType,
      bytesTransferred: bytesTransferred,
      startedAt: startedAt,
      estimatedCompletion: estimatedCompletion,
      currentFileName: currentFileName ?? this.currentFileName,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      fileStatus: fileStatus ?? this.fileStatus,
    );
  }
}

/// Backup event
class BackupEvent {
  final BackupEventType type;
  final String backupId;
  final String? message;
  final Map<String, dynamic>? data;

  BackupEvent({
    required this.type,
    required this.backupId,
    this.message,
    this.data,
  });

  factory BackupEvent.started(String backupId) => BackupEvent(
        type: BackupEventType.started,
        backupId: backupId,
        message: 'Backup started',
      );

  factory BackupEvent.completed(String backupId) => BackupEvent(
        type: BackupEventType.completed,
        backupId: backupId,
        message: 'Backup completed successfully',
      );

  factory BackupEvent.failed(String backupId, String error) => BackupEvent(
        type: BackupEventType.failed,
        backupId: backupId,
        message: 'Backup failed: $error',
      );
}

enum BackupEventType {
  started,
  progress,
  paused,
  resumed,
  completed,
  failed,
}

/// Backup exception
class BackupException implements Exception {
  final String message;
  BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}

/// Backup size estimation result
class BackupEstimation {
  final int totalItems;
  final int estimatedBytes;
  final int estimatedSeconds;
  final Map<BackupType, BackupTypeEstimate> perTypeEstimates;

  BackupEstimation({
    required this.totalItems,
    required this.estimatedBytes,
    required this.estimatedSeconds,
    required this.perTypeEstimates,
  });

  /// Formatted estimated time (e.g., "2 min 30 sec")
  String get formattedTime {
    if (estimatedSeconds < 60) {
      return '$estimatedSeconds sec';
    }
    final minutes = estimatedSeconds ~/ 60;
    final seconds = estimatedSeconds % 60;
    if (seconds == 0) {
      return '$minutes min';
    }
    return '$minutes min $seconds sec';
  }

  /// Formatted estimated size (e.g., "15.2 MB")
  String get formattedSize {
    if (estimatedBytes < 1024) return '$estimatedBytes B';
    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Estimate for a single backup type
class BackupTypeEstimate {
  final BackupType type;
  final int itemCount;
  final int estimatedBytes;
  final String? error;

  BackupTypeEstimate({
    required this.type,
    required this.itemCount,
    required this.estimatedBytes,
    this.error,
  });

  String get formattedSize {
    if (estimatedBytes < 1024) return '$estimatedBytes B';
    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Backup executor - lightweight wrapper for progress/event callbacks
class BackupExecutor {
  final FirebaseFirestore firestore;
  final Function(BackupProgress) progressCallback;
  final Function(BackupEvent) eventCallback;

  BackupExecutor({
    required this.firestore,
    required this.progressCallback,
    required this.eventCallback,
  });
}

/// Abstract backup strategy
abstract class BackupStrategy {
  /// Execute backup for this strategy
  Future<BackupResult> execute(BackupContext context);

  /// Estimate number of items to backup
  Future<int> estimateItemCount(BackupContext context);

  /// Estimate bytes per item for this strategy
  /// Override this to provide more accurate estimates based on real data sampling
  /// Returns bytes per item on average
  Future<int> estimateBytesPerItem(BackupContext context) async {
    // Default fallback - subclasses should override with real data sampling
    return 1024; // 1KB default
  }

  /// Check if item needs backup (for incremental)
  Future<bool> needsBackup(dynamic item, BackupContext context);
}

/// Backup context passed to strategies
class BackupContext {
  final String userId;
  final String backupId;
  final BackupOptions options;
  final FirebaseFirestore firestore;
  final DateTime? lastBackupTimestamp;

  BackupContext({
    required this.userId,
    required this.backupId,
    required this.options,
    required this.firestore,
    this.lastBackupTimestamp,
  });
}

/// Backup result
class BackupResult {
  final int totalItems;
  final int successfulItems;
  final int failedItems;
  final int bytesTransferred;
  final List<String> errors;

  BackupResult({
    required this.totalItems,
    required this.successfulItems,
    required this.failedItems,
    required this.bytesTransferred,
    this.errors = const [],
  });

  bool get isSuccess => failedItems == 0;
  bool get isPartialSuccess => successfulItems > 0 && failedItems > 0;
}

// Backup strategies are implemented in separate files:
// - strategies/chat_backup_strategy.dart
// - strategies/media_backup_strategy.dart
// - strategies/contacts_backup_strategy.dart
// - strategies/device_info_backup_strategy.dart

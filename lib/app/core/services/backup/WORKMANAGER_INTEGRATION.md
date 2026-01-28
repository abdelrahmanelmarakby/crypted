# WorkManager Integration for BackupServiceV3

This document explains how to integrate WorkManager to make backups truly unstoppable.

---

## Why WorkManager?

**WorkManager ensures backups run even when:**
- ✅ App is killed by user
- ✅ App is killed by system (low memory)
- ✅ Device restarts
- ✅ Network is temporarily unavailable
- ✅ Battery is low (can defer until charging)

---

## Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  workmanager: ^0.5.2
```

### Android Setup

**File:** `android/app/src/main/AndroidManifest.xml`

Add inside `<application>`:
```xml
<provider
    android:name="androidx.work.impl.WorkManagerInitializer"
    android:authorities="${applicationId}.workmanager-init"
    android:enabled="false"
    android:exported="false" />
```

### iOS Setup

**File:** `ios/Podfile`

```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Add this
  pod 'WorkmanagerPlugin', :path => '.symlinks/plugins/workmanager/ios'
end
```

Run: `cd ios && pod install`

---

## Implementation

### Step 1: Create Backup Worker

**File:** `lib/app/core/services/backup/backup_worker.dart`

```dart
import 'dart:async';
import 'dart:developer';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

/// Callback dispatcher for WorkManager background tasks
///
/// This function runs in a separate isolate, so it needs to:
/// 1. Initialize Firebase
/// 2. Execute the backup task
/// 3. Report completion/failure
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('🔧 WorkManager task started: $task');

      // Initialize Firebase (required in separate isolate)
      await Firebase.initializeApp();

      // Parse task data
      final backupId = inputData?['backupId'] as String?;
      final types = (inputData?['types'] as List?)
          ?.map((t) => BackupType.values.firstWhere((type) => type.name == t))
          .toSet();
      final optionsJson = inputData?['options'] as Map<String, dynamic>?;

      if (backupId == null || types == null || types.isEmpty) {
        log('❌ Invalid backup task data');
        return Future.value(false);
      }

      // Initialize backup service
      final backupService = BackupServiceV3.instance;
      await backupService.initialize();

      // Execute backup
      log('🚀 Starting backup: $backupId');
      await backupService.startBackup(
        types: types,
        options: optionsJson != null
            ? BackupOptions.fromJson(optionsJson)
            : BackupOptions.defaults(),
      );

      log('✅ WorkManager task completed: $task');
      return Future.value(true);

    } catch (e, stackTrace) {
      log('❌ WorkManager task failed: $e', stackTrace: stackTrace);
      return Future.value(false);
    }
  });
}

/// Initialize WorkManager in main app
Future<void> initializeWorkManager() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false in production
  );

  log('✅ WorkManager initialized');
}

/// Schedule a backup task with WorkManager
Future<void> scheduleBackupTask({
  required String backupId,
  required Set<BackupType> types,
  required BackupOptions options,
}) async {
  await Workmanager().registerOneOffTask(
    backupId, // Unique task ID
    'backup_task', // Task name
    inputData: {
      'backupId': backupId,
      'types': types.map((t) => t.name).toList(),
      'options': options.toJson(),
    },
    constraints: Constraints(
      networkType: options.wifiOnly
          ? NetworkType.unmetered // WiFi only
          : NetworkType.connected, // Any network
      requiresBatteryNotLow: options.minBatteryPercent > 20,
      requiresCharging: false,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: Duration(seconds: 30),
  );

  log('✅ Backup task scheduled: $backupId');
}
```

---

### Step 2: Update BackupServiceV3

**File:** `lib/app/core/services/backup/backup_service_v3.dart`

Update these methods:

```dart
// Add import at top
import 'package:crypted_app/app/core/services/backup/backup_worker.dart';

// Update _initializeWorkManager()
Future<void> _initializeWorkManager() async {
  await initializeWorkManager();
  log('✅ WorkManager initialized for backup tasks');
}

// Update _scheduleBackupExecution()
Future<void> _scheduleBackupExecution(BackupJob job) async {
  // Schedule via WorkManager
  await scheduleBackupTask(
    backupId: job.id,
    types: job.types,
    options: job.options,
  );

  log('✅ Backup scheduled via WorkManager: ${job.id}');
}
```

---

### Step 3: Initialize in main.dart

**File:** `lib/main.dart`

```dart
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize BackupServiceV3 (includes WorkManager)
  await BackupServiceV3.instance.initialize();

  runApp(const MyApp());
}
```

---

## Usage

### One-Time Backup

```dart
// User triggers backup manually
final backupId = await BackupServiceV3.instance.startBackup(
  types: {BackupType.chats, BackupType.media},
  options: BackupOptions(
    wifiOnly: true,
    minBatteryPercent: 20,
    compressMedia: true,
  ),
);

// WorkManager ensures it completes even if app is killed
print('Backup scheduled: $backupId');
```

### Periodic Backup (Nightly)

```dart
import 'package:workmanager/workmanager.dart';

Future<void> scheduleNightlyBackup() async {
  await Workmanager().registerPeriodicTask(
    'nightly-backup',
    'backup_task',
    frequency: Duration(hours: 24),
    initialDelay: Duration(hours: 2), // Run at 2 AM
    constraints: Constraints(
      networkType: NetworkType.unmetered, // WiFi only
      requiresBatteryNotLow: true,
      requiresCharging: false,
    ),
    inputData: {
      'backupId': 'nightly_${DateTime.now().millisecondsSinceEpoch}',
      'types': BackupType.values.map((t) => t.name).toList(),
      'options': BackupOptions.defaults().toJson(),
    },
  );

  print('Nightly backup scheduled');
}
```

---

## Testing WorkManager Integration

### Test 1: App Killed During Backup

1. Start a backup:
   ```dart
   await BackupServiceV3.instance.startBackup(
     types: {BackupType.chats},
   );
   ```

2. Immediately kill the app (swipe away or force stop)

3. Expected: Backup continues in background and completes

4. Verify: Check Firestore `backup_jobs/{backupId}` → status should be "completed"

### Test 2: Device Restart During Backup

1. Start a backup
2. Restart device (or airplane mode → restart)
3. Expected: Backup resumes after device boots up
4. Verify: Backup completes successfully

### Test 3: Network Offline During Backup

1. Start a backup
2. Turn off WiFi/data
3. Expected: Backup waits for network (queued state)
4. Turn network back on
5. Expected: Backup resumes and completes

### Test 4: Low Battery During Backup

1. Set device battery to < 20%
2. Start a backup with `minBatteryPercent: 20`
3. Expected: Backup deferred until battery > 20% or device charging
4. Charge device or set battery > 20%
5. Expected: Backup starts automatically

---

## Debugging

### View WorkManager Tasks

**Android:**
```bash
adb shell dumpsys jobscheduler | grep -A 10 workmanager
```

**iOS:**
```bash
# WorkManager uses BackgroundTasks API
# View logs in Xcode console
```

### Cancel All Tasks

```dart
await Workmanager().cancelAll();
print('All WorkManager tasks canceled');
```

### Cancel Specific Task

```dart
await Workmanager().cancelByUniqueName('backup_12345');
print('Backup task canceled');
```

---

## Production Checklist

- [ ] Set `isInDebugMode: false` in `Workmanager().initialize()`
- [ ] Test on physical devices (Android & iOS)
- [ ] Test all constraint scenarios (WiFi, battery, charging)
- [ ] Test app kill during backup
- [ ] Test device restart during backup
- [ ] Monitor Firestore for backup completion
- [ ] Monitor Firebase Storage for uploaded files
- [ ] Set up error alerting for failed backups

---

## Limitations

### Android
- ✅ Full WorkManager support
- ✅ Constraints work reliably
- ✅ Backups survive app kill and device restart

### iOS
- ⚠️ WorkManager uses BackgroundTasks API (iOS 13+)
- ⚠️ System decides when to run tasks (not guaranteed)
- ⚠️ Limited to ~30 seconds execution time in background
- 💡 For longer backups, use foreground service with user notification

### iOS Alternative: Background Fetch

For iOS, consider using `background_fetch` plugin:

```yaml
dependencies:
  background_fetch: ^1.3.6
```

```dart
BackgroundFetch.configure(
  BackgroundFetchConfig(
    minimumFetchInterval: 15, // 15 minutes
    stopOnTerminate: false,
    enableHeadless: true,
    requiresBatteryNotLow: true,
    requiresCharging: false,
    requiresStorageNotLow: false,
    requiresDeviceIdle: false,
    requiredNetworkType: NetworkType.ANY,
  ),
  (String taskId) async {
    // Backup logic here
    await BackupServiceV3.instance.startBackup(...);
    BackgroundFetch.finish(taskId);
  },
);
```

---

## Summary

✅ **WorkManager** ensures backups are unstoppable on Android
⚠️ **iOS** has limitations due to OS restrictions
💡 **Hybrid approach**: WorkManager + BackgroundFetch for best coverage
🔧 **Test thoroughly** on physical devices before production

**Next Steps:**
1. Add `workmanager` dependency
2. Implement `backup_worker.dart`
3. Update `BackupServiceV3._scheduleBackupExecution()`
4. Test on Android and iOS devices
5. Monitor production backups for reliability

---

**Version:** 1.0
**Last Updated:** January 28, 2026

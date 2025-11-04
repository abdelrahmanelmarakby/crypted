# Reliable Backup Service - Usage Guide

## Overview

The `ReliableBackupService` is a simple, robust backup service that uploads all device data to Firebase Storage and Firestore. It's designed to be unstoppable - it will retry failed uploads and continue until everything is backed up.

## Features

✅ **Automatic Retry Logic** - Failed uploads are retried up to 3 times with exponential backoff
✅ **Resume Support** - Updates existing backups instead of creating duplicates
✅ **Progress Tracking** - Real-time progress updates via streams
✅ **Organized Storage** - Clean structure: `username/data_type/files`
✅ **Complete Data Backup**:
  - Device info (brand, name, platform)
  - Location with geocoded address (lat, lng, full address)
  - All contacts with full details
  - All images (with low quality to save bandwidth)
  - All files (videos, audio, documents)

## Data Structure

### Firebase Storage Structure
```
username/
├── images/
│   ├── image_123.jpg
│   ├── image_456.jpg
│   └── ...
└── files/
    ├── file_789.mp4
    ├── file_012.pdf
    └── ...
```

### Firestore Structure
```
backups/
└── username/
    ├── device_info: {platform, brand, name, model, ...}
    ├── location: {latitude, longitude, address, ...}
    ├── contacts: [{id, displayName, phones, emails, ...}]
    ├── images: [{id, url, width, height, createDate, ...}]
    ├── files: [{id, url, type, size, createDate, ...}]
    ├── last_backup_completed_at: Timestamp
    └── backup_success: {device_info: true, location: true, ...}
```

## Usage

### 1. Import the Service

```dart
import 'package:crypted_app/app/core/services/reliable_backup_service.dart';
```

### 2. Get the Instance

```dart
final backupService = ReliableBackupService.instance;
```

### 3. Listen to Progress (Optional)

```dart
// Listen to progress percentage (0.0 to 1.0)
backupService.progressStream.listen((progress) {
  print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
});

// Listen to status messages
backupService.statusStream.listen((status) {
  print('Status: $status');
});
```

### 4. Run Full Backup

```dart
// Simple - just run the backup
final success = await backupService.runFullBackup();

if (success) {
  print('✅ Backup completed successfully!');
} else {
  print('❌ Backup failed or was cancelled');
}
```

### 5. Check Backup Status

```dart
final status = await backupService.getBackupStatus();

if (status != null) {
  print('Last backup: ${status['last_backup_completed_at']}');
  print('Images count: ${status['images_count']}');
  print('Contacts count: ${status['contacts_count']}');
  print('Files count: ${status['files_count']}');
}
```

### 6. Stop Backup (If Needed)

```dart
// To stop the backup process
backupService.stopBackup();
```

### 7. Check if Backup is Running

```dart
if (backupService.isBackupRunning) {
  print('Backup is currently running...');
}
```

## Complete Example with UI

```dart
import 'package:flutter/material.dart';
import 'package:crypted_app/app/core/services/reliable_backup_service.dart';

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final backupService = ReliableBackupService.instance;
  double _progress = 0.0;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();

    // Listen to progress
    backupService.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
    });

    // Listen to status
    backupService.statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });
  }

  Future<void> _startBackup() async {
    final success = await backupService.runFullBackup();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '✅ Backup completed!' : '❌ Backup failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress bar
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 16),

            // Status text
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 16),

            // Progress percentage
            Text(
              '${(_progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),

            // Start backup button
            ElevatedButton(
              onPressed: backupService.isBackupRunning ? null : _startBackup,
              child: Text('Start Backup'),
            ),
            SizedBox(height: 16),

            // Stop backup button
            if (backupService.isBackupRunning)
              ElevatedButton(
                onPressed: backupService.stopBackup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Stop Backup'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Background Execution

To ensure the backup continues even if the app is closed, you can use `WorkManager`:

```dart
import 'package:workmanager/workmanager.dart';

// Register background task
void registerBackupTask() {
  Workmanager().registerPeriodicTask(
    'backup-task',
    'backup',
    frequency: Duration(days: 1), // Run daily
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: true, // Optional: only when charging
    ),
  );
}

// Callback handler
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'backup') {
      final success = await ReliableBackupService.instance.runFullBackup();
      return success;
    }
    return false;
  });
}

// Initialize in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  registerBackupTask();
  runApp(MyApp());
}
```

## Important Notes

1. **Permissions**: The service will automatically request all necessary permissions (location, contacts, photos, storage)

2. **Network**: Large backups require good internet connection. The service will retry failed uploads automatically.

3. **Battery**: For large backups, ensure the device has sufficient battery or is charging

4. **Updates**: The service uses `SetOptions(merge: true)` in Firestore, so it updates existing backups instead of creating new ones

5. **File Quality**: Images are uploaded with low quality to save bandwidth and storage. Original quality is not preserved.

6. **Error Handling**: All operations have retry logic (3 attempts with exponential backoff). Failed items are logged but don't stop the backup.

## Troubleshooting

**Backup stops unexpectedly:**
- Check internet connection
- Ensure app has all required permissions
- Check device storage space

**Some files not uploaded:**
- Check logs for specific errors
- Some files may be inaccessible due to OS restrictions
- Failed uploads are logged but don't stop the overall backup

**Progress stuck:**
- Large files take time to upload
- Check network speed
- The service will timeout after 3 retry attempts and move to next file

## Differences from Old Service

| Feature | Old Service | New Service |
|---------|------------|-------------|
| Complexity | Over-engineered, many streams | Simple, 2 streams only |
| Timestamps | New backup each time | Updates existing backup |
| Structure | Complex nested paths | Clean: `username/data_type/` |
| Reliability | Can fail and stop | Retries 3x, never stops |
| Progress | Multiple progress streams | Single progress stream |
| Code lines | ~789 lines | ~550 lines |
| Maintainability | Hard to understand | Easy to read and modify |
| Compression | Complex encryption/compression | Raw files (no compression) |
| Image Quality | Full quality | Low quality (saves bandwidth) |

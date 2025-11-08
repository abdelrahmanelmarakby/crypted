# Background Services Setup Guide

This guide explains how to set up WhatsApp-like background functionality for the Crypted app.

## Overview

The background service implementation includes:

1. **Background Service Manager** - Coordinates all background operations
2. **Connection State Manager** - Monitors network connectivity
3. **App Lifecycle Manager** - Handles app state changes
4. **WorkManager Service** - Schedules periodic background tasks (Android)
5. **Offline Message Queue** - Queues messages when offline
6. **Foreground Service** - Keeps app running in background (Android)

## Quick Start

### Step 1: Add Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  # Background services (optional but recommended)
  workmanager: ^0.5.2

  # Connectivity monitoring
  connectivity_plus: ^5.0.2

  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  firebase_database: ^10.4.0

  # Notifications
  flutter_local_notifications: ^16.3.0

  # Permissions (for battery optimization)
  permission_handler: ^11.1.0
```

### Step 2: Update main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:crypted_app/app/core/services/background_service_initializer.dart';
import 'package:crypted_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize all background services
  await BackgroundServiceInitializer.initialize();

  // Request battery optimization exemption (important!)
  await BackgroundServiceInitializer.requestBatteryOptimizationExemption();

  runApp(MyApp());
}
```

### Step 3: Update Android Configuration

Follow the instructions in `android_manifest_configuration.md` to:

1. Add required permissions to AndroidManifest.xml
2. Add service declarations
3. Update build.gradle with dependencies
4. Create BootReceiver (optional)

### Step 4: iOS Configuration (Optional)

For iOS background capabilities, add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

## Features

### 1. Persistent Connection

The app maintains a persistent connection to Firebase even when in background:

- **Heartbeat**: Sends ping every 30 seconds to keep connection alive
- **Auto-reconnect**: Automatically reconnects on network changes
- **Exponential backoff**: Smart retry logic to avoid battery drain

### 2. Background Sync

Syncs data periodically while app is in background:

- **Interval**: Every 15 minutes (configurable)
- **Network constraint**: Only when connected to internet
- **Battery aware**: Respects battery optimization settings

### 3. Offline Queue

Messages sent while offline are queued and sent when connection is restored:

- **Persistent storage**: Survives app restarts
- **Auto-retry**: Up to 5 retry attempts with exponential backoff
- **Failure handling**: Removes messages after max retries

### 4. Presence Management

Automatically updates user presence based on app state:

- **Foreground**: Online and active
- **Background**: Online but away
- **Disconnected**: Offline with last seen timestamp

## Service Status Monitoring

Check service status programmatically:

```dart
final status = BackgroundServiceInitializer.getServicesStatus();
print(status);

// Output:
// {
//   'initialized': true,
//   'connectionManager': {
//     'state': 'ConnectionState.connected',
//     'isOnline': true,
//     'connectionType': 'wifi',
//     'reconnectAttempts': 0
//   },
//   'backgroundService': {
//     'isRunning': true,
//     'isForegroundServiceActive': true,
//     ...
//   },
//   'offlineQueue': {
//     'queueSize': 0,
//     'isSending': false
//   },
//   'lifecycle': {
//     'currentState': 'AppLifecycleState.resumed',
//     'isInForeground': true,
//     ...
//   }
// }
```

## Configuration

### Heartbeat Interval

Modify in `background_service_manager.dart`:

```dart
_heartbeatTimer = Timer.periodic(
  const Duration(seconds: 30), // Change this value
  (timer) async {
    await _connectionManager.ping();
  },
);
```

### Sync Interval

Modify in `background_service_manager.dart`:

```dart
_syncTimer = Timer.periodic(
  const Duration(minutes: 5), // Change this value
  (timer) async {
    await _performBackgroundSync();
  },
);
```

### WorkManager Frequency (Android)

Modify in `background_service_initializer.dart`:

```dart
await WorkManagerService.instance.registerPeriodicSync(
  frequency: const Duration(minutes: 15), // Change this value
);
```

## Battery Optimization

### Why it's Important

Android's battery optimization can kill background services to save battery. For WhatsApp-like functionality, the app should be exempted from battery optimization.

### Request Exemption

The app automatically requests battery optimization exemption on first launch. Users will see a system dialog.

### Manual Settings

If users deny the request, they can manually disable battery optimization:

1. Open device Settings
2. Go to Apps
3. Select Crypted
4. Tap Battery
5. Select "Unrestricted" or "Don't optimize"

### Show Settings Programmatically

```dart
await BackgroundServiceInitializer.showBatteryOptimizationSettings();
```

## Troubleshooting

### Service stops after a few minutes

**Solution**: Ensure battery optimization is disabled for the app.

```dart
// Check if battery optimization is disabled
final isExempted = await Permission.ignoreBatteryOptimizations.isGranted;
if (!isExempted) {
  await BackgroundServiceInitializer.requestBatteryOptimizationExemption();
}
```

### Messages not syncing in background

**Solution**: Check WorkManager registration and network connectivity.

```dart
// Re-register WorkManager tasks
await WorkManagerService.instance.cancelAllTasks();
await WorkManagerService.instance.registerPeriodicSync();
```

### App killed by system

**Solution**:
1. Ensure foreground service is running (shows persistent notification)
2. Disable battery optimization
3. Check manufacturer-specific battery saving modes (Xiaomi, Huawei, etc.)

### No background execution on iOS

**Solution**: iOS has strict background execution limits. The app relies primarily on:
1. Background App Refresh (limited to ~15 minutes per day)
2. Push notifications (unlimited)
3. Background fetch (system-scheduled)

## Platform Differences

### Android

- **Full background execution** with foreground service
- **WorkManager** for periodic tasks
- **Battery optimization** must be disabled
- **Doze mode** may still restrict after extended periods

### iOS

- **Limited background execution** (3-5 minutes when entering background)
- **Background App Refresh** (system-scheduled)
- **Push notifications** for real-time updates
- **No persistent background service** like Android

## Best Practices

1. **Always show foreground notification** (Android) - Required by system
2. **Monitor battery usage** - Don't drain battery excessively
3. **Respect user preferences** - Allow users to disable background sync
4. **Handle offline gracefully** - Queue messages and sync when online
5. **Test on real devices** - Emulators don't accurately simulate background behavior
6. **Test different Android versions** - Behavior varies across versions
7. **Test manufacturer ROMs** - Xiaomi, Huawei, Samsung have custom restrictions

## Performance Monitoring

Monitor background service performance:

```dart
// In a debug screen
final status = BackgroundServiceInitializer.getServicesStatus();

// Connection health
final connectionInfo = status['connectionManager'];
print('Connection: ${connectionInfo['state']}');
print('Type: ${connectionInfo['connectionType']}');
print('Reconnect attempts: ${connectionInfo['reconnectAttempts']}');

// Queue status
final queueInfo = status['offlineQueue'];
print('Pending messages: ${queueInfo['queueSize']}');
print('Currently sending: ${queueInfo['isSending']}');

// Lifecycle
final lifecycleInfo = status['lifecycle'];
print('App state: ${lifecycleInfo['currentState']}');
print('In foreground: ${lifecycleInfo['isInForeground']}');
```

## Testing

### Test Background Behavior

1. **Send message** while connected
2. **Turn off WiFi/Data** and send another message
3. **Put app in background** for 5 minutes
4. **Turn WiFi/Data back on**
5. **Bring app to foreground**
6. **Verify**: Offline message should send automatically

### Test Connection Recovery

1. **Disconnect from internet**
2. **Wait for disconnected state**
3. **Reconnect to internet**
4. **Verify**: App should reconnect automatically

### Test Presence Updates

1. **Open app** - Should show as "Online"
2. **Go to home screen** - Should show as "Away"
3. **Close app** - Should show as "Offline" with last seen

## Advanced Configuration

### Custom Foreground Notification (Android)

To customize the foreground service notification, you'll need to implement a proper foreground service using packages like `flutter_foreground_task`.

### Custom Background Tasks

Add custom background tasks in `work_manager_service.dart`:

```dart
await WorkManagerService.instance.registerOneTimeTask(
  taskName: 'custom-task',
  taskTag: 'customTask',
  delay: Duration(minutes: 5),
);
```

### Custom Heartbeat Logic

Modify `_startHeartbeat()` in `background_service_manager.dart` to add custom logic:

```dart
void _startHeartbeat() {
  _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 30),
    (timer) async {
      // Custom heartbeat logic
      await _connectionManager.ping();

      // Add your custom logic here
      await _customHeartbeatTask();
    },
  );
}
```

## Security Considerations

1. **Presence Privacy**: Users should be able to hide their online status
2. **Background Data**: Encrypt sensitive data in offline queue
3. **Battery Usage**: Inform users about battery impact
4. **Permissions**: Request only necessary permissions

## Future Enhancements

Potential improvements for future releases:

1. **Adaptive sync intervals** based on user activity
2. **Smart queue prioritization** for important messages
3. **Data compression** for background sync
4. **Analytics** for background service performance
5. **User controls** for background behavior
6. **WhatsApp-style "Connected" indicator** in chat header

## Support

For issues with background services:

1. Check logs in debug mode
2. Verify all permissions are granted
3. Test on different devices/Android versions
4. Review manufacturer-specific restrictions
5. Consult Firebase documentation for Firebase-specific issues

---

**Last Updated**: 2025-01-08
**Version**: 1.0

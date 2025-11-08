# Android Manifest Configuration for Background Services

This file contains the necessary configuration for Android to enable WhatsApp-like background functionality.

## Required Permissions

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet and Network State -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

    <!-- Foreground Service -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>

    <!-- Wake Lock (keep CPU awake) -->
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <!-- Receive Boot Completed (start service on boot) -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <!-- Post Notifications (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- Background Location (if using location features) -->
    <!-- <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/> -->

    <!-- Disable Battery Optimization (optional but recommended) -->
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

    <!-- Schedule Exact Alarms (Android 12+) -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

    <application
        android:name="${applicationName}"
        android:label="Crypted"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Foreground Service -->
        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="dataSync"
            android:exported="false">
        </service>

        <!-- WorkManager Worker -->
        <provider
            android:name="androidx.startup.InitializationProvider"
            android:authorities="${applicationId}.androidx-startup"
            android:exported="false"
            tools:node="merge">
            <meta-data
                android:name="androidx.work.WorkManagerInitializer"
                android:value="androidx.startup" />
        </provider>

        <!-- Firebase Cloud Messaging -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>

        <!-- Boot Receiver (restart service on device boot) -->
        <receiver
            android:name=".BootReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <!-- Default FCM notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />

        <!-- FCM notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- FCM notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />

    </application>
</manifest>
```

## Required Gradle Dependencies

Add these to `android/app/build.gradle`:

```gradle
dependencies {
    // WorkManager
    implementation 'androidx.work:work-runtime-ktx:2.8.1'

    // Foreground Service
    implementation 'androidx.core:core-ktx:1.12.0'

    // Connectivity
    implementation 'androidx.appcompat:appcompat:1.6.1'

    // Firebase (if not already added)
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-database'
}
```

## Flutter Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  # Background services
  workmanager: ^0.5.2

  # Connectivity monitoring
  connectivity_plus: ^5.0.2

  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  firebase_database: ^10.4.0

  # Notifications
  flutter_local_notifications: ^16.3.0

  # App lifecycle
  flutter_app_badger: ^1.5.0
```

## BootReceiver Implementation

Create `android/app/src/main/kotlin/com/yourpackage/crypted/BootReceiver.kt`:

```kotlin
package com.yourpackage.crypted

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted, starting background service")

            // Start your foreground service here if needed
            // val serviceIntent = Intent(context, YourForegroundService::class.java)
            // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            //     context.startForegroundService(serviceIntent)
            // } else {
            //     context.startService(serviceIntent)
            // }
        }
    }
}
```

## Battery Optimization Handling

Add this code to request battery optimization exemption:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBatteryOptimizationExemption() async {
  if (Platform.isAndroid) {
    // Request to ignore battery optimizations
    final status = await Permission.ignoreBatteryOptimizations.request();

    if (status.isGranted) {
      print('Battery optimization disabled');
    } else {
      print('Battery optimization still enabled');
    }
  }
}
```

## Notification Channel Setup

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> createNotificationChannels() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
```

## Usage in main.dart

```dart
import 'package:crypted_app/app/core/services/app_lifecycle_manager.dart';
import 'package:crypted_app/app/core/services/background_service_manager.dart';
import 'package:crypted_app/app/core/services/work_manager_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize WorkManager (Android only)
  if (Platform.isAndroid) {
    await WorkManagerService.instance.initialize();
    await WorkManagerService.instance.registerPeriodicSync(
      frequency: Duration(minutes: 15),
    );
  }

  // Initialize notification channels
  await createNotificationChannels();

  // Request battery optimization exemption
  await requestBatteryOptimizationExemption();

  // Initialize GetX services
  await Get.putAsync(() async {
    final lifecycle = AppLifecycleManager();
    await lifecycle.onInit();
    return lifecycle;
  });

  runApp(MyApp());
}
```

## Important Notes

1. **Battery Optimization**: Users must manually disable battery optimization for the app in device settings for best results

2. **Doze Mode**: Android's Doze mode will still restrict background activity. Use `SCHEDULE_EXACT_ALARM` permission for critical tasks

3. **Foreground Service**: Must show a persistent notification while running

4. **iOS Limitations**: iOS has stricter background execution limits. Use Background App Refresh and push notifications

5. **Testing**: Test on real devices with different Android versions (especially Android 12+)

6. **Play Store**: If publishing to Play Store, justify foreground service usage in the app declaration form

## Troubleshooting

### Service stops after a while
- Check if battery optimization is disabled
- Verify foreground service notification is showing
- Check Doze mode exemptions

### Background sync not working
- Ensure WorkManager is properly initialized
- Check network connectivity constraints
- Verify periodic task is registered

### App killed by system
- Increase foreground service priority
- Implement proper service restart logic
- Use AlarmManager for critical tasks

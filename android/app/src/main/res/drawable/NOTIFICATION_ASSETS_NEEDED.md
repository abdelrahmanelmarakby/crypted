# Notification Assets Required

## Icons (PNG format, white color on transparent background)

Place these icons in the `drawable` folders with appropriate sizes:

### Required Icons:

1. **ic_notification.png** - Default notification icon
   - Simple bell or app icon
   - 24x24dp baseline

2. **ic_reply.png** - Reply action button
   - Speech bubble or reply arrow icon
   - 24x24dp baseline

3. **ic_done_all.png** - Mark as read action button
   - Double checkmark icon
   - 24x24dp baseline

4. **ic_notifications_off.png** - Mute action button
   - Bell with slash icon
   - 24x24dp baseline

5. **ic_call_accept.png** - Accept call button
   - Phone icon (green)
   - 24x24dp baseline

6. **ic_call_decline.png** - Decline call button
   - Phone with X or declined phone icon (red)
   - 24x24dp baseline

### Size Requirements by Density:

- **mdpi**: 24x24 px
- **hdpi**: 36x36 px
- **xhdpi**: 48x48 px
- **xxhdpi**: 72x72 px
- **xxxhdpi**: 96x96 px

### Folder Structure:
```
drawable-mdpi/
drawable-hdpi/
drawable-xhdpi/
drawable-xxhdpi/
drawable-xxxhdpi/
```

### Quick Setup (Single Resolution):

For development, you can place single-resolution icons (48x48px) directly in the `drawable/` folder. Android will scale them automatically (though this is not recommended for production).

## Sounds (MP3 format)

Place these in `android/app/src/main/res/raw/`:

1. **notification_sound.mp3**
   - Short notification tone (1-2 seconds)
   - Pleasant sound for incoming messages

2. **call_ringtone.mp3**
   - Longer ringtone (15-30 seconds, loopable)
   - For incoming call notifications

### Sound Requirements:
- Format: MP3 (recommended) or OGG
- Sample rate: 44.1 kHz or 48 kHz
- Bit rate: 128-192 kbps
- Mono or Stereo

## iOS Assets

For iOS, ensure the following:

1. App icon is set in Assets.xcassets
2. Sounds should be placed in `ios/Runner/` as `.caf` files
3. Notification service extension (if needed) is configured

## Resources for Icons:

- Material Icons: https://fonts.google.com/icons
- Flaticon: https://www.flaticon.com/
- Icons8: https://icons8.com/
- Create your own using Figma, Sketch, or Adobe XD

## Resources for Sounds:

- Zapsplat: https://www.zapsplat.com/
- Freesound: https://freesound.org/
- Notification Sounds: https://notificationsounds.com/
- Create your own using Audacity or GarageBand

## Testing:

After adding assets:
1. Clean and rebuild: `flutter clean && flutter pub get`
2. Rebuild Android: `flutter build apk --debug`
3. Test notifications to verify assets display correctly

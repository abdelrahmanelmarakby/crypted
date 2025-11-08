# Contacts Privacy & Storage Documentation for App Review

## Overview

This document provides comprehensive information about how Crypted app handles contact data, explaining the purpose, storage mechanisms, and privacy measures in place for App Store review.

## Purpose of Contacts Access

Crypted is an encrypted messaging application that requires access to the user's contacts for the following legitimate purposes:

### 1. **User Discovery**
- Users can find and connect with friends who are already using Crypted
- Contacts are used to suggest potential connections within the app
- This improves user experience by making it easy to find existing contacts

### 2. **Backup & Restore Functionality**
- Users can securely backup their contacts to the cloud
- Contacts can be restored when reinstalling the app or switching devices
- This ensures users don't lose their contact information

### 3. **Quick Communication**
- Users can select contacts to initiate conversations quickly
- Contact names and phone numbers are used for initiating encrypted chats
- Improves messaging workflow and user experience

## How Contacts Are Stored

### Local Storage
- **Device Only**: Contacts are only accessed locally from the user's device
- **No Permanent Local Cache**: The app does not create a permanent copy of all contacts
- **On-Demand Access**: Contacts are accessed only when needed for specific features

### Cloud Backup (Optional)
When users explicitly opt-in to the backup feature:

1. **User Consent Required**: Users must explicitly tap "Start Backup" to backup contacts
2. **Firebase Cloud Storage**: Contacts are uploaded to the user's private Firebase storage
3. **Encrypted Transfer**: All data is encrypted during transfer using HTTPS/TLS
4. **User-Specific Storage**: Each user's contacts are stored in a separate, isolated database document

#### Data Structure
```
Firestore Collection: backups/{username}/
- contacts: Array of contact objects
  - id: Contact identifier
  - displayName: Contact name
  - firstName: First name
  - lastName: Last name
  - phones: Array of phone numbers with labels
  - emails: Array of email addresses with labels
- contacts_count: Number of contacts
- contacts_updated_at: Timestamp of last update
```

### Security Measures

1. **Permission Model**
   - App requests contacts permission with clear explanation
   - Users can deny permission and still use core messaging features
   - Permission can be revoked at any time from device settings

2. **Data Encryption**
   - Contacts are encrypted during transfer to Firebase
   - HTTPS/TLS encryption for all network communications
   - Firebase security rules prevent unauthorized access

3. **Privacy Controls**
   - Users control when backups happen (manual trigger required)
   - Users can delete all backed-up data at any time
   - No automatic background uploads without user consent

4. **Data Minimization**
   - Only essential contact fields are stored (name, phone, email)
   - Contact photos are NOT backed up
   - Sensitive metadata is excluded

## User Privacy Features

### Transparency
- Clear in-app messaging about what data is collected
- Backup settings screen shows exactly what gets backed up
- Real-time progress indicators during backup

### User Control
- **Manual Backups**: Users must manually trigger backups
- **Delete Anytime**: Users can delete all backed-up data with one tap
- **View Details**: Users can see exactly what was backed up and when
- **Opt-Out**: Users can disable backup feature entirely

### Platform-Specific Handling
- **iOS**: Auto-backup disabled due to platform limitations
- **Android**: Auto-backup available with explicit user consent
- Both platforms require manual user action to initiate backups

## Compliance

### iOS App Store Guidelines
- Complies with App Store Review Guidelines 5.1.1 (Data Collection and Storage)
- Complies with 5.1.2 (Data Use and Sharing)
- Clear privacy policy provided to users

### Data Retention
- Contacts are retained only as long as the user maintains their account
- When user deletes their account, all backed-up contacts are deleted
- Users can manually delete all backups at any time

### Third-Party Services
- **Firebase Firestore**: Used for secure cloud storage
- **Firebase Storage**: Used for media backup (not contacts)
- All Firebase services comply with GDPR and industry standards

## User-Facing Privacy Information

### Permission Request
When the app requests contacts permission, users see:
```
"Crypted would like to access your contacts to help you find friends and backup your contact list. You can change this in Settings anytime."
```

### Backup Settings Screen
Users are informed about:
- What gets backed up (Device Info, Location, Contacts, Images, Files)
- How backups work (cloud storage, encryption)
- When backups occur (manual or scheduled)
- How to delete all backups

### Important Information Displayed
- 🔒 Your data is encrypted during transfer
- ☁️ Backups are stored securely in the cloud
- ⏱️ Large backups may take several minutes
- 📶 Ensure stable internet connection
- 📱 Keep app open during backup

## Technical Implementation

### Contacts Access Code
```dart
// Request permission
final contactsGranted = await FlutterContacts.requestPermission();

// Access contacts only with permission
if (contactsGranted) {
  final contacts = await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: false, // Privacy: Don't access photos
  );
}
```

### Secure Backup Code
```dart
// User must explicitly call this method
Future<bool> _backupContacts() async {
  // Only backs up essential fields
  final contactsList = contacts.map((contact) {
    return {
      'id': contact.id,
      'displayName': contact.displayName,
      'firstName': contact.name.first,
      'lastName': contact.name.last,
      'phones': contact.phones.map((p) => {
        'number': p.number,
        'label': p.label.name,
      }).toList(),
      'emails': contact.emails.map((e) => {
        'address': e.address,
        'label': e.label.name,
      }).toList(),
    };
  }).toList();

  // Save with user-specific document ID
  await _firestore.collection('backups').doc(username).set({
    'contacts': contactsList,
    'contacts_count': contactsList.length,
    'contacts_updated_at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

## Support & Questions

For App Review Team:
- The app's primary function is encrypted messaging
- Contacts access enhances but is not required for core functionality
- Users maintain full control over their data
- All storage is secure, encrypted, and user-controlled

For any questions or clarifications, please contact:
- **Developer**: Crypted Development Team
- **App**: Crypted - Encrypted Messaging
- **Support**: via App Store Connect messaging

---

**Last Updated**: November 8, 2025
**Version**: 1.0
**Platform**: iOS & Android

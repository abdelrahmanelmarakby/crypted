import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:crypted_app/app/core/services/backup/backup_service_v3.dart';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Contacts backup strategy - backs up device contacts
///
/// **Features:**
/// - Permission handling (requests access if needed)
/// - Batch processing (100 contacts per batch)
/// - Lightweight (only essential contact data)
/// - Privacy-aware (only backs up what's needed)
class ContactsBackupStrategy extends BackupStrategy {
  final BackupDataSource _backupDataSource = BackupDataSource();

  static const int _contactBatchSize = 100;

  @override
  Future<BackupResult> execute(BackupContext context) async {
    try {
      log('📞 Starting contacts backup...');

      // Check permissions
      if (!await _checkPermissions()) {
        log('❌ Contacts permission denied');
        return BackupResult(
          totalItems: 0,
          successfulItems: 0,
          failedItems: 1,
          bytesTransferred: 0,
          errors: ['Contacts permission denied by user'],
        );
      }

      // Get all contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false, // Don't include photos to save space
      );

      if (contacts.isEmpty) {
        log('⚠️ No contacts found on device');
        return BackupResult(
          totalItems: 0,
          successfulItems: 0,
          failedItems: 0,
          bytesTransferred: 0,
        );
      }

      final totalItems = contacts.length;
      log('📊 Found $totalItems contacts to backup');

      // Convert contacts to JSON-serializable format
      final contactsData = contacts.map((contact) => _contactToMap(contact)).toList();

      // Create backup data structure
      final backupData = {
        'contacts': contactsData,
        'metadata': {
          'totalContacts': contacts.length,
          'backupDate': DateTime.now().toIso8601String(),
          'deviceInfo': {
            'platform': 'flutter',
            'backupVersion': '3.0',
          },
        },
      };

      // Upload as JSON with organized folder structure
      // Path: backups/{userId}/{backupId}/contacts/contacts_data.json
      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'contacts_data.json',
        data: backupData,
        folder: 'contacts',
        userId: context.userId,
      );

      // Estimate bytes transferred
      final bytesTransferred = _estimateDataSize(backupData);

      log('✅ Contacts backup completed: $totalItems contacts backed up');

      return BackupResult(
        totalItems: totalItems,
        successfulItems: totalItems,
        failedItems: 0,
        bytesTransferred: bytesTransferred,
      );

    } catch (e, stackTrace) {
      log('❌ Contacts backup failed: $e', stackTrace: stackTrace);
      return BackupResult(
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        bytesTransferred: 0,
        errors: ['Contacts backup failed: $e'],
      );
    }
  }

  @override
  Future<int> estimateItemCount(BackupContext context) async {
    try {
      // Check permission without requesting (for estimation only)
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        log('⚠️ Cannot estimate contacts: permission not granted');
        return 0;
      }

      final contacts = await FlutterContacts.getContacts();
      log('📊 Estimated contacts count: ${contacts.length}');
      return contacts.length;
    } catch (e) {
      log('❌ Error estimating contacts count: $e');
      return 0;
    }
  }

  /// Dynamic size estimation by sampling actual contacts
  /// Samples up to 10 contacts to calculate average data size
  @override
  Future<int> estimateBytesPerItem(BackupContext context) async {
    try {
      log('📊 Sampling contacts for size estimation...');

      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) return 1024; // 1KB fallback

      // Get contacts with full properties for accurate estimation
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (contacts.isEmpty) return 1024; // 1KB fallback

      // Sample up to 10 contacts
      final sampleContacts = contacts.take(10).toList();
      int totalSize = 0;

      for (final contact in sampleContacts) {
        final contactMap = _contactToMap(contact);
        final jsonSize = _estimateJsonSize(contactMap);
        totalSize += jsonSize;
      }

      final avgSize = totalSize ~/ sampleContacts.length;

      log('📊 Contacts estimation: ${sampleContacts.length} samples, avg ~${avgSize}B per contact');

      return avgSize;
    } catch (e) {
      log('⚠️ Contacts estimation failed, using fallback: $e');
      return 1024; // 1KB fallback
    }
  }

  /// Estimate JSON size of a map
  int _estimateJsonSize(Map<String, dynamic> map) {
    int size = 2; // {} brackets
    map.forEach((key, value) {
      size += key.length + 3; // "key":
      if (value is String) {
        size += value.length + 2; // "value"
      } else if (value is Map) {
        size += _estimateJsonSize(value.cast<String, dynamic>());
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            size += _estimateJsonSize(item.cast<String, dynamic>());
          } else {
            size += item.toString().length + 2;
          }
        }
      } else {
        size += value.toString().length;
      }
      size += 1; // comma
    });
    return size;
  }

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    // Contacts always need backup (can't do incremental easily)
    return true;
  }

  // Private helper methods

  Future<bool> _checkPermissions() async {
    try {
      // Use FlutterContacts' built-in permission handling
      // This is more reliable than permission_handler for contacts
      log('📱 Checking contacts permission via FlutterContacts...');

      // First check if already granted
      bool hasPermission = await FlutterContacts.requestPermission(readonly: true);

      if (hasPermission) {
        log('✅ Contacts permission granted');
        return true;
      }

      // Permission not granted
      log('⚠️ Contacts permission not granted');

      // On iOS, check if permanently denied
      if (Platform.isIOS) {
        log('ℹ️ iOS: User may need to enable contacts in Settings > Privacy > Contacts');
      } else if (Platform.isAndroid) {
        log('ℹ️ Android: User may need to enable contacts permission in app settings');
      }

      return false;
    } catch (e, stackTrace) {
      log('❌ Error checking contacts permission: $e');
      log('$stackTrace');
      return false;
    }
  }

  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'id': contact.id,
      'displayName': contact.displayName,
      'name': {
        'first': contact.name.first,
        'last': contact.name.last,
        'middle': contact.name.middle,
        'prefix': contact.name.prefix,
        'suffix': contact.name.suffix,
      },
      'phones': contact.phones.map((phone) => {
        'number': phone.number,
        'label': phone.label.name,
      }).toList(),
      'emails': contact.emails.map((email) => {
        'address': email.address,
        'label': email.label.name,
      }).toList(),
      'addresses': contact.addresses.map((address) => {
        'address': address.address,
        'street': address.street,
        'city': address.city,
        'state': address.state,
        'postalCode': address.postalCode,
        'country': address.country,
        'label': address.label.name,
      }).toList(),
      'organizations': contact.organizations.map((org) => {
        'company': org.company,
        'title': org.title,
        'department': org.department,
      }).toList(),
      'websites': contact.websites.map((website) => {
        'url': website.url,
        'label': website.label.name,
      }).toList(),
      'socialMedias': contact.socialMedias.map((social) => {
        'userName': social.userName,
        'label': social.label.name,
      }).toList(),
      'events': contact.events.map((event) => {
        'year': event.year,
        'month': event.month,
        'day': event.day,
        'label': event.label.name,
      }).toList(),
      'notes': contact.notes.map((note) => note.note).toList(),
    };
  }

  int _estimateDataSize(Map<String, dynamic> data) {
    // Estimate: ~2KB per contact average
    final totalContacts = (data['metadata']?['totalContacts'] ?? 0) as int;
    return totalContacts * 2048;
  }
}

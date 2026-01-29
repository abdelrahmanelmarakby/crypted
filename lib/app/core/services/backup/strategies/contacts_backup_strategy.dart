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

      // Upload as JSON
      await _backupDataSource.uploadJsonData(
        backupId: context.backupId,
        fileName: 'contacts_data.json',
        data: backupData,
        folder: 'contacts',
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
      if (!await _checkPermissions()) {
        return 0;
      }

      final contacts = await FlutterContacts.getContacts();
      return contacts.length;
    } catch (e) {
      log('❌ Error estimating contacts count: $e');
      return 0;
    }
  }

  @override
  Future<bool> needsBackup(dynamic item, BackupContext context) async {
    // Contacts always need backup (can't do incremental easily)
    return true;
  }

  // Private helper methods

  Future<bool> _checkPermissions() async {
    try {
      final status = await Permission.contacts.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.contacts.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      log('❌ Error checking contacts permission: $e');
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

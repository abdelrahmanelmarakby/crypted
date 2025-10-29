import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypted_app/app/data/data_source/backup_data_source.dart';
import 'package:crypted_app/app/data/models/backup_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contacts backup service
/// Handles collecting, processing, and uploading device contacts for backup
class ContactsBackupService {
  final BackupDataSource _backupDataSource = BackupDataSource();

  /// Get all device contacts
  Future<List<Contact>> getDeviceContacts() async {
    try {
      log('📞 Getting device contacts...');

      // Check permissions
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) {
        await Permission.contacts.request();
        final newPermission = await Permission.contacts.status;
        if (!newPermission.isGranted) {
          log('❌ Contacts permission denied');
          return [];
        }
      }

      // Get all contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      log('✅ Retrieved ${contacts.length} contacts');
      return contacts;
    } catch (e) {
      log('❌ Error getting device contacts: $e');
      return [];
    }
  }

  /// Get contacts with specific properties
  Future<List<Contact>> getContactsWithProperties({
    bool withProperties = true,
    bool withPhoto = false,
    bool withAccounts = false,
    bool withGroups = false,
  }) async {
    try {
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) {
        await Permission.contacts.request();
        final newPermission = await Permission.contacts.status;
        if (!newPermission.isGranted) {
          return [];
        }
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: withProperties,
        withPhoto: withPhoto,
        withAccounts: withAccounts,
        withGroups: withGroups,
      );

      return contacts;
    } catch (e) {
      log('❌ Error getting contacts with properties: $e');
      return [];
    }
  }

  /// Search contacts by name or phone number
  Future<List<Contact>> searchContacts(String query) async {
    try {
      final allContacts = await getDeviceContacts();

      final filteredContacts = allContacts.where((contact) {
        final displayName = contact.displayName.toLowerCase();
        final searchQuery = query.toLowerCase();

        // Search in display name
        if (displayName.contains(searchQuery)) {
          return true;
        }

        // Search in phone numbers
        if (contact.phones.isNotEmpty) {
          for (final phone in contact.phones) {
            if (phone.number.contains(searchQuery)) {
              return true;
            }
          }
        }

        // Search in emails
        if (contact.emails.isNotEmpty) {
          for (final email in contact.emails) {
            if (email.address.toLowerCase().contains(searchQuery)) {
              return true;
            }
          }
        }

        return false;
      }).toList();

      log('🔍 Found ${filteredContacts.length} contacts matching "$query"');
      return filteredContacts;
    } catch (e) {
      log('❌ Error searching contacts: $e');
      return [];
    }
  }

  /// Get contacts by group
  Future<List<Contact>> getContactsByGroup(String groupName) async {
    try {
      final contacts = await getContactsWithProperties(withGroups: true);

      return contacts.where((contact) {
        return contact.groups.any((group) => group.name == groupName);
      }).toList();
    } catch (e) {
      log('❌ Error getting contacts by group: $e');
      return [];
    }
  }

  /// Get favorite contacts
  Future<List<Contact>> getFavoriteContacts() async {
    try {
      // Note: flutter_contacts doesn't have isFavorite property
      // This is a placeholder for future implementation
      // You could implement this by checking a custom field or group

      log('⚠️ Favorite contacts detection not implemented in flutter_contacts');
      return [];
    } catch (e) {
      log('❌ Error getting favorite contacts: $e');
      return [];
    }
  }

  /// Create contacts backup
  Future<BackupProgress> createContactsBackup({
    required String userId,
    required String backupId,
    bool includePhotos = true,
    bool includeGroups = true,
    bool includeAccounts = true,
    Function(double)? onProgress,
  }) async {
    try {
      log('📞 Starting contacts backup process...');

      // Check permissions
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) {
        await Permission.contacts.request();
        final newPermission = await Permission.contacts.status;
        if (!newPermission.isGranted) {
          throw Exception('Contacts permission required for backup');
        }
      }

      // Initialize backup progress
      var progress = BackupProgress.initial(
        backupId: backupId,
        type: BackupType.contacts,
        totalItems: 0,
      );

      // Update progress to in-progress
      progress = progress.copyWith(status: BackupStatus.inProgress);
      await _backupDataSource.updateBackupProgress(progress);

      // Get contacts with required properties
      final contacts = await getContactsWithProperties(
        withProperties: true,
        withPhoto: includePhotos,
        withAccounts: includeAccounts,
        withGroups: includeGroups,
      );

      if (contacts.isEmpty) {
        log('⚠️ No contacts found on device');
        return progress.copyWith(
          status: BackupStatus.completed,
          progress: 1.0,
          completedItems: 0,
        );
      }

      progress = progress.copyWith(totalItems: contacts.length);
      await _backupDataSource.updateBackupProgress(progress);

      // Process and upload contacts in batches
      const batchSize = 10;
      final totalBatches = (contacts.length / batchSize).ceil();
      final uploadedUrls = <String>[];

      for (int batch = 0; batch < totalBatches; batch++) {
        final startIndex = batch * batchSize;
        final endIndex = (startIndex + batchSize) > contacts.length
            ? contacts.length
            : (startIndex + batchSize);

        final batchContacts = contacts.sublist(startIndex, endIndex);

        log('📦 Processing batch ${batch + 1}/$totalBatches (${batchContacts.length} contacts)');

        // Process contacts in this batch
        for (int i = 0; i < batchContacts.length; i++) {
          final contact = batchContacts[i];
          final globalIndex = startIndex + i + 1;

          try {
            // Convert contact to JSON
            final contactJson = contact.toJson();
            final fileName = 'contact_${contact.id}_$globalIndex.json';

            // Upload contact data
            final url = await _backupDataSource.uploadJsonData(
              backupId: backupId,
              fileName: fileName,
              data: contactJson,
              folder: 'contacts',
            );

            uploadedUrls.add(url);

            // Update progress
            progress = progress.copyWith(
              completedItems: globalIndex,
              progress: globalIndex / contacts.length,
              currentTask: 'Backing up ${contact.displayName}',
            );
            await _backupDataSource.updateBackupProgress(progress);

            // Add delay to avoid overwhelming the server
            await Future.delayed(const Duration(milliseconds: 100));

          } catch (e) {
            log('❌ Error backing up contact ${contact.displayName}: $e');
            // Continue with next contact
          }
        }

        // Report progress for this batch
        onProgress?.call((batch + 1) / totalBatches);
      }

      // Create contacts metadata
      await _createContactsMetadata(
        backupId: backupId,
        contacts: contacts,
        uploadedUrls: uploadedUrls,
        includePhotos: includePhotos,
        includeGroups: includeGroups,
        includeAccounts: includeAccounts,
      );

      // Complete backup
      progress = progress.copyWith(
        status: BackupStatus.completed,
        progress: 1.0,
        completedItems: contacts.length,
        currentTask: 'Backup completed',
      );
      await _backupDataSource.updateBackupProgress(progress);

      log('✅ Contacts backup completed successfully');
      return progress;

    } catch (e) {
      log('❌ Error in contacts backup: $e');

      // Update progress with error
      final errorProgress = BackupProgress(
        backupId: backupId,
        status: BackupStatus.failed,
        type: BackupType.contacts,
        errorMessage: e.toString(),
      );
      await _backupDataSource.updateBackupProgress(errorProgress);

      return errorProgress;
    }
  }

  /// Create metadata file for contacts backup
  Future<void> _createContactsMetadata({
    required String backupId,
    required List<Contact> contacts,
    required List<String> uploadedUrls,
    bool includePhotos = true,
    bool includeGroups = true,
    bool includeAccounts = true,
  }) async {
    try {
      final metadata = <String, dynamic>{
        'totalContacts': contacts.length,
        'uploadedUrls': uploadedUrls,
        'includePhotos': includePhotos,
        'includeGroups': includeGroups,
        'includeAccounts': includeAccounts,
        'backupDate': DateTime.now().toIso8601String(),
        'contacts': <Map<String, dynamic>>[],
      };

      // Create summary for each contact
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        final contactSummary = <String, dynamic>{
          'id': contact.id,
          'displayName': contact.displayName,
          'phoneCount': contact.phones.length,
          'emailCount': contact.emails.length,
          'addressCount': contact.addresses.length,
          'groupCount': contact.groups.length,
          // 'isFavorite': contact.isFavorite ?? false,
          'hasPhoto': contact.photo != null,
          'uploadedUrl': uploadedUrls[i],
          'backupIndex': i,
        };

        metadata['contacts'].add(contactSummary);
      }

      // Upload metadata as JSON
      await _backupDataSource.uploadJsonData(
        backupId: backupId,
        fileName: 'contacts_metadata.json',
        data: metadata,
        folder: 'contacts',
      );

      log('✅ Contacts metadata created and uploaded');
    } catch (e) {
      log('❌ Error creating contacts metadata: $e');
    }
  }

  /// Get contacts statistics
  Future<Map<String, dynamic>> getContactsStatistics() async {
    try {
      final contacts = await getDeviceContacts();
      final stats = <String, dynamic>{
        'totalContacts': contacts.length,
        'contactsWithPhotos': 0,
        'contactsWithEmails': 0,
        'contactsWithAddresses': 0,
        'favoriteContacts': 0, // Not available in flutter_contacts
        'totalPhoneNumbers': 0,
        'totalEmails': 0,
        'totalAddresses': 0,
      };

      for (final contact in contacts) {
        if (contact.photo != null) stats['contactsWithPhotos']++;
        if (contact.emails.isNotEmpty) stats['contactsWithEmails']++;
        if (contact.addresses.isNotEmpty) stats['contactsWithAddresses']++;
        // isFavorite not available in flutter_contacts

        stats['totalPhoneNumbers'] += contact.phones.length;
        stats['totalEmails'] += contact.emails.length;
        stats['totalAddresses'] += contact.addresses.length;
      }

      return stats;
    } catch (e) {
      log('❌ Error getting contacts statistics: $e');
      return {
        'totalContacts': 0,
        'contactsWithPhotos': 0,
        'contactsWithEmails': 0,
        'contactsWithAddresses': 0,
        'favoriteContacts': 0,
        'totalPhoneNumbers': 0,
        'totalEmails': 0,
        'totalAddresses': 0,
      };
    }
  }

  /// Get contacts by organization/company
  Future<List<Contact>> getContactsByOrganization(String organization) async {
    try {
      final contacts = await getDeviceContacts();

      return contacts.where((contact) {
        return contact.organizations.any((org) => org.company == organization);
      }).toList();
    } catch (e) {
      log('❌ Error getting contacts by organization: $e');
      return [];
    }
  }

  /// Export contacts to VCF format (placeholder)
  Future<String> exportContactsToVCF(List<Contact> contacts) async {
    try {
      // This is a placeholder for VCF export functionality
      // In a real implementation, you'd use a proper VCF library
      final vcfContent = StringBuffer();

      vcfContent.writeln('BEGIN:VCARD');
      vcfContent.writeln('VERSION:3.0');

      for (final contact in contacts) {
        vcfContent.writeln('BEGIN:VCARD');
        vcfContent.writeln('VERSION:3.0');
        vcfContent.writeln('FN:${contact.displayName}');

        for (final phone in contact.phones) {
          vcfContent.writeln('TEL:${phone.number}');
        }

        for (final email in contact.emails) {
          vcfContent.writeln('EMAIL:${email.address}');
        }

        vcfContent.writeln('END:VCARD');
      }

      vcfContent.writeln('END:VCARD');

      return vcfContent.toString();
    } catch (e) {
      log('❌ Error exporting contacts to VCF: $e');
      return '';
    }
  }

  /// Validate contacts backup integrity
  Future<bool> validateContactsBackup(String backupId) async {
    try {
      // Get backup metadata
      final backupFiles = await _backupDataSource.getBackupFiles(
        backupId: backupId,
        folder: 'contacts',
      );

      if (backupFiles.isEmpty) return false;

      // Check if metadata file exists
      final hasMetadata = backupFiles.any((file) => file.contains('metadata'));

      // Check if contact files exist
      final contactFiles = backupFiles.where((file) => file.contains('contact_')).toList();

      // Basic validation - should have metadata + contact files
      return hasMetadata && contactFiles.isNotEmpty;
    } catch (e) {
      log('❌ Error validating contacts backup: $e');
      return false;
    }
  }

  /// Delete contacts backup
  Future<bool> deleteContactsBackup(String backupId) async {
    try {
      // This will be handled by the main backup data source
      // but we can add specific contacts cleanup here if needed
      log('🗑️ Deleting contacts backup: $backupId');
      return true;
    } catch (e) {
      log('❌ Error deleting contacts backup: $e');
      return false;
    }
  }

  /// Merge duplicate contacts (placeholder)
  Future<List<Contact>> mergeDuplicateContacts(List<Contact> contacts) async {
    try {
      // This is a placeholder for duplicate merging functionality
      // In a real implementation, you'd implement sophisticated duplicate detection
      log('🔄 Merging duplicate contacts...');

      final uniqueContacts = <String, Contact>{};

      for (final contact in contacts) {
        final key = _getContactKey(contact);
        if (!uniqueContacts.containsKey(key)) {
          uniqueContacts[key] = contact;
        } else {
          // Merge contact data (simplified implementation)
          final existing = uniqueContacts[key]!;
          uniqueContacts[key] = _mergeContacts(existing, contact);
        }
      }

      return uniqueContacts.values.toList();
    } catch (e) {
      log('❌ Error merging duplicate contacts: $e');
      return contacts;
    }
  }

  /// Get contact key for duplicate detection
  String _getContactKey(Contact contact) {
    // Simple key based on display name and first phone number
    final name = contact.displayName.toLowerCase();
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    return '$name|$phone';
  }

  /// Merge two contacts (simplified implementation)
  Contact _mergeContacts(Contact contact1, Contact contact2) {
    // This is a simplified merge - in reality you'd want more sophisticated merging
    final mergedPhones = [...contact1.phones, ...contact2.phones];
    final mergedEmails = [...contact1.emails, ...contact2.emails];
    final mergedAddresses = [...contact1.addresses, ...contact2.addresses];

    return Contact(
      id: contact1.id,
      displayName: contact1.displayName,
      phones: mergedPhones.toSet().toList(),
      emails: mergedEmails.toSet().toList(),
      addresses: mergedAddresses.toSet().toList(),
      organizations: <Organization>{...contact1.organizations, ...contact2.organizations}.toList(),
      websites: <Website>{...contact1.websites, ...contact2.websites}.toList(),
      socialMedias: <SocialMedia>{...contact1.socialMedias, ...contact2.socialMedias}.toList(),
      events: <Event>{...contact1.events, ...contact2.events}.toList(),
      notes: <Note>{...contact1.notes, ...contact2.notes}.toList(),
      groups: <Group>{...contact1.groups, ...contact2.groups}.toList(),
      photo: contact1.photo ?? contact2.photo,
      thumbnail: contact1.thumbnail ?? contact2.thumbnail,
    );
  }

  /// Get backup size estimate for contacts
  Future<int> getBackupSizeEstimate(List<Contact> contacts) async {
    int totalSize = 0;

    for (final contact in contacts) {
      try {
        // Estimate size based on JSON representation
        final contactJson = contact.toJson();
        final jsonString = json.encode(contactJson);
        totalSize += jsonString.length;

        // Add photo size if exists
        if (contact.photo != null) {
          totalSize += contact.photo!.length;
        }
      } catch (e) {
        // Continue with other contacts
      }
    }

    return totalSize;
  }
}

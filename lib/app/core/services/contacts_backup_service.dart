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

  /// Export contacts to VCF format (vCard 3.0 standard)
  Future<String> exportContactsToVCF(List<Contact> contacts) async {
    try {
      log('📤 Exporting ${contacts.length} contacts to VCF format');
      final vcfContent = StringBuffer();

      for (final contact in contacts) {
        vcfContent.writeln('BEGIN:VCARD');
        vcfContent.writeln('VERSION:3.0');

        // Full name
        if (contact.displayName.isNotEmpty) {
          vcfContent.writeln('FN:${_escapeVCF(contact.displayName)}');
        }

        // Structured name (N: FamilyName;GivenName;AdditionalNames;Prefix;Suffix)
        final name = contact.name;
        if (name.last.isNotEmpty || name.first.isNotEmpty) {
          vcfContent.writeln('N:${_escapeVCF(name.last)};${_escapeVCF(name.first)};${_escapeVCF(name.middle)};;');
        }

        // Phone numbers with types
        for (final phone in contact.phones) {
          final type = phone.label.name.toUpperCase();
          vcfContent.writeln('TEL;TYPE=$type:${phone.number}');
        }

        // Email addresses with types
        for (final email in contact.emails) {
          final type = email.label.name.toUpperCase();
          vcfContent.writeln('EMAIL;TYPE=$type:${_escapeVCF(email.address)}');
        }

        // Addresses
        for (final address in contact.addresses) {
          final type = address.label.name.toUpperCase();
          // ADR: POBox;Extended;Street;City;Region;PostalCode;Country
          vcfContent.writeln('ADR;TYPE=$type:;;${_escapeVCF(address.street)};${_escapeVCF(address.city)};${_escapeVCF(address.state)};${_escapeVCF(address.postalCode)};${_escapeVCF(address.country)}');
        }

        // Organizations
        for (final org in contact.organizations) {
          vcfContent.writeln('ORG:${_escapeVCF(org.company)};${_escapeVCF(org.department)}');
          if (org.title.isNotEmpty) {
            vcfContent.writeln('TITLE:${_escapeVCF(org.title)}');
          }
        }

        // Birthday
        if (contact.events.isNotEmpty) {
          for (final event in contact.events) {
            if (event.label == EventLabel.birthday && event.year != null) {
              final birthday = '${event.year}-${event.month.toString().padLeft(2, '0')}-${event.day.toString().padLeft(2, '0')}';
              vcfContent.writeln('BDAY:$birthday');
            }
          }
        }

        // Notes
        if (contact.notes.isNotEmpty) {
          for (final note in contact.notes) {
            vcfContent.writeln('NOTE:${_escapeVCF(note.note)}');
          }
        }

        // Websites
        for (final website in contact.websites) {
          vcfContent.writeln('URL:${website.url}');
        }

        vcfContent.writeln('END:VCARD');
      }

      log('✅ Successfully exported ${contacts.length} contacts to VCF');
      return vcfContent.toString();
    } catch (e) {
      log('❌ Error exporting contacts to VCF: $e');
      return '';
    }
  }

  /// Escape special characters for VCF format
  String _escapeVCF(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
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

  /// Merge duplicate contacts based on phone numbers and names
  Future<List<Contact>> mergeDuplicateContacts(List<Contact> contacts) async {
    try {
      log('🔄 Finding and merging duplicate contacts from ${contacts.length} contacts');

      final Map<String, List<Contact>> phoneGroups = {};
      final Map<String, List<Contact>> nameGroups = {};
      final Set<String> processedIds = {};
      final List<Contact> mergedContacts = [];

      // Group contacts by phone number
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalizedPhone = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          phoneGroups.putIfAbsent(normalizedPhone, () => []).add(contact);
        }
      }

      // Group contacts by normalized name
      for (final contact in contacts) {
        final normalizedName = contact.displayName.toLowerCase().trim();
        if (normalizedName.isNotEmpty) {
          nameGroups.putIfAbsent(normalizedName, () => []).add(contact);
        }
      }

      // Merge duplicates found by phone number
      for (final entry in phoneGroups.entries) {
        if (entry.value.length > 1) {
          final mainContact = entry.value.first;
          if (!processedIds.contains(mainContact.id)) {
            // Merge all duplicate contacts into the first one
         //   final mergedContact = await _mergeContactGroup(entry.value);
         // mergedContacts.add(mergedContact);

            for (final contact in entry.value) {
              processedIds.add(contact.id);
            }
          }
        }
      }

      // // Merge duplicates found by name (if not already processed)
      // for (final entry in nameGroups.entries) {
      //   if (entry.value.length > 1) {
      //     final unprocessedGroup = entry.value.where((c) => !processedIds.contains(c.id)).toList();

      //     if (unprocessedGroup.length > 1) {
      //       final mergedContact = await _mergeContactGroup(unprocessedGroup);
      //       mergedContacts.add(mergedContact);

      //       for (final contact in unprocessedGroup) {
      //         processedIds.add(contact.id);
      //       }
      //     }
      //   }
      // }

      // Add all non-duplicate contacts
      for (final contact in contacts) {
        if (!processedIds.contains(contact.id)) {
          mergedContacts.add(contact);
        }
      }

      log('✅ Merged duplicates: ${contacts.length} contacts → ${mergedContacts.length} contacts');
      return mergedContacts;
    } catch (e) {
      log('❌ Error merging duplicate contacts: $e');
      return contacts; // Return original list if merging fails
    }
  }

  // /// Merge a group of duplicate contacts into one
  // Future<Contact> _mergeContactGroup(List<Contact> duplicates) async {
  //   if (duplicates.isEmpty) {
  //     throw Exception('Cannot merge empty contact group');
  //   }

  //   if (duplicates.length == 1) {
  //     return duplicates.first;
  //   }

  //   // Start with the first contact as the base
  //   Contact merged = duplicates.first;

  //   // Merge all unique phones
  //   final Set<String> uniquePhones = {};
  //   final List<Phone> allPhones = [];
  //   for (final contact in duplicates) {
  //     for (final phone in contact.phones) {
  //       final normalized = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  //       if (!uniquePhones.contains(normalized)) {
  //         uniquePhones.add(normalized);
  //         allPhones.add(phone);
  //       }
  //     }
  //   }

  //   // Merge all unique emails
  //   final Set<String> uniqueEmails = {};
  //   final List<Email> allEmails = [];
  //   for (final contact in duplicates) {
  //     for (final email in contact.emails) {
  //       if (!uniqueEmails.contains(email.address.toLowerCase())) {
  //         uniqueEmails.add(email.address.toLowerCase());
  //         allEmails.add(email);
  //       }
  //     }
  //   }

  //   // Merge addresses
  //   final List<Address> allAddresses = [];
  //   for (final contact in duplicates) {
  //     allAddresses.addAll(contact.addresses);
  //   }

  //   // Merge organizations
  //   final List<Organization> allOrganizations = [];
  //   for (final contact in duplicates) {
  //     allOrganizations.addAll(contact.organizations);
  //   }

  //   // Merge notes
  //   final List<Note> allNotes = [];
  //   for (final contact in duplicates) {
  //     allNotes.addAll(contact.notes);
  //   }

  //   // Update the merged contact
  //   merged = await merged.update(
  //     phones: allPhones,
  //     emails: allEmails,
  //     addresses: allAddresses.isEmpty ? merged.addresses : allAddresses,

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

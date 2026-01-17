import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Widget for editing privacy exception lists (included/excluded users)
/// Used in privacy settings when user selects "My Contacts Except..." or "Nobody Except..."
class PrivacyExceptionListEditor extends StatefulWidget {
  final VisibilityLevel level;
  final List<PrivacyException> currentExceptions;
  final String title;
  final String subtitle;
  final Function(List<PrivacyException>) onSave;

  const PrivacyExceptionListEditor({
    super.key,
    required this.level,
    required this.currentExceptions,
    required this.title,
    required this.subtitle,
    required this.onSave,
  });

  @override
  State<PrivacyExceptionListEditor> createState() =>
      _PrivacyExceptionListEditorState();
}

class _PrivacyExceptionListEditorState
    extends State<PrivacyExceptionListEditor> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<PrivacyException> _selectedUsers = <PrivacyException>[].obs;
  final RxList<ContactInfo> _contacts = <ContactInfo>[].obs;
  final RxList<ContactInfo> _filteredContacts = <ContactInfo>[].obs;
  final RxBool _isLoading = true.obs;
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _selectedUsers.addAll(widget.currentExceptions);
    _loadContacts();
    _setupSearch();
  }

  void _setupSearch() {
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
      _filterContacts();
    });
  }

  void _filterContacts() {
    if (_searchQuery.value.isEmpty) {
      _filteredContacts.value = _contacts;
    } else {
      _filteredContacts.value = _contacts
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery.value) ||
              (c.phone?.toLowerCase().contains(_searchQuery.value) ?? false))
          .toList();
    }
  }

  Future<void> _loadContacts() async {
    try {
      _isLoading.value = true;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load contacts from Firestore
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .limit(100)
          .get();

      final contacts = <ContactInfo>[];

      // Get user info for each contact
      for (final doc in contactsSnapshot.docs) {
        final contactUserId = doc.id;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(contactUserId)
            .get();

        if (userDoc.exists) {
          contacts.add(ContactInfo(
            userId: contactUserId,
            name: userDoc.data()?['fullName'] ?? 'Unknown',
            photoUrl: userDoc.data()?['imageUrl'],
            phone: userDoc.data()?['phone'],
          ));
        }
      }

      // Sort by name
      contacts.sort((a, b) => a.name.compareTo(b.name));

      _contacts.value = contacts;
      _filteredContacts.value = contacts;
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  bool _isSelected(String userId) {
    return _selectedUsers.any((u) => u.userId == userId);
  }

  void _toggleUser(ContactInfo contact) {
    if (_isSelected(contact.userId)) {
      _selectedUsers.removeWhere((u) => u.userId == contact.userId);
    } else {
      _selectedUsers.add(PrivacyException(
        userId: contact.userId,
        userName: contact.name,
        userPhotoUrl: contact.photoUrl,
        addedAt: DateTime.now(),
      ));
    }
  }

  void _save() {
    widget.onSave(_selectedUsers.toList());
    Get.back();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Obx(() => TextButton(
                onPressed: _selectedUsers.isEmpty ? null : _save,
                child: Text(
                  'Done (${_selectedUsers.length})',
                  style: TextStyle(
                    color: _selectedUsers.isEmpty
                        ? Colors.grey
                        : ColorsManager.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            width: double.infinity,
            child: Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Selected users chips
          Obx(() => _selectedUsers.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: user.userPhotoUrl != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(user.userPhotoUrl!),
                                )
                              : CircleAvatar(
                                  backgroundColor:
                                      ColorsManager.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    (user.userName ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColorsManager.primary,
                                    ),
                                  ),
                                ),
                          label: Text(user.userName ?? 'Unknown'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            _selectedUsers
                                .removeWhere((u) => u.userId == user.userId);
                          },
                        ),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink()),

          // Divider
          if (_selectedUsers.isNotEmpty) const Divider(),

          // Contact list
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_filteredContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.value.isEmpty
                            ? Icons.people_outline
                            : Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.value.isEmpty
                            ? 'No contacts found'
                            : 'No matching contacts',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return _buildContactTile(contact);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(ContactInfo contact) {
    return Obx(() {
      final isSelected = _isSelected(contact.userId);

      return ListTile(
        onTap: () => _toggleUser(contact),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
              backgroundImage: contact.photoUrl != null
                  ? NetworkImage(contact.photoUrl!)
                  : null,
              child: contact.photoUrl == null
                  ? Text(
                      contact.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorsManager.primary,
                      ),
                    )
                  : null,
            ),
            if (isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: contact.phone != null
            ? Text(
                contact.phone!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              )
            : null,
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: ColorsManager.primary,
              )
            : Icon(
                Icons.circle_outlined,
                color: Colors.grey.shade300,
              ),
      );
    });
  }
}

/// Contact info model
class ContactInfo {
  final String userId;
  final String name;
  final String? photoUrl;
  final String? phone;

  const ContactInfo({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.phone,
  });
}

// ============================================================================
// HELPER WIDGET FOR OPENING THE EDITOR
// ============================================================================

/// Opens the privacy exception list editor
Future<List<PrivacyException>?> showPrivacyExceptionEditor({
  required BuildContext context,
  required VisibilityLevel level,
  required List<PrivacyException> currentExceptions,
}) async {
  List<PrivacyException>? result;

  final String title;
  final String subtitle;

  switch (level) {
    case VisibilityLevel.contactsExcept:
      title = 'Exclude Contacts';
      subtitle =
          'Select contacts who will NOT be able to see this information.';
      break;
    case VisibilityLevel.nobodyExcept:
      title = 'Allow Contacts';
      subtitle = 'Select contacts who will be able to see this information.';
      break;
    default:
      title = 'Select Contacts';
      subtitle = 'Select contacts for this privacy setting.';
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PrivacyExceptionListEditor(
        level: level,
        currentExceptions: currentExceptions,
        title: title,
        subtitle: subtitle,
        onSave: (exceptions) {
          result = exceptions;
        },
      ),
    ),
  );

  return result;
}

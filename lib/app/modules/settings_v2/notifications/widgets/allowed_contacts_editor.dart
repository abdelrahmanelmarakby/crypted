import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Allowed Contacts Editor Widget
/// Allows users to select contacts who can reach them during DND
class AllowedContactsEditor extends StatefulWidget {
  final List<String> selectedContactIds;
  final Function(List<String>) onSave;

  const AllowedContactsEditor({
    super.key,
    required this.selectedContactIds,
    required this.onSave,
  });

  static Future<List<String>?> show({
    required BuildContext context,
    required List<String> selectedContactIds,
  }) async {
    List<String>? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AllowedContactsEditor(
        selectedContactIds: selectedContactIds,
        onSave: (contacts) {
          result = contacts;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  @override
  State<AllowedContactsEditor> createState() => _AllowedContactsEditorState();
}

class _AllowedContactsEditorState extends State<AllowedContactsEditor> {
  late Set<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<_ContactInfo> _contacts = [];

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedContactIds.toSet();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get user's contacts/chat rooms to find people they've chatted with
      final chatRoomsSnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('membersIds', arrayContains: currentUserId)
          .get();

      final userIds = <String>{};
      for (final doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        final memberIds = List<String>.from(data['membersIds'] ?? []);
        for (final id in memberIds) {
          if (id != currentUserId) {
            userIds.add(id);
          }
        }
      }

      // Fetch user details
      final contacts = <_ContactInfo>[];
      for (final userId in userIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          contacts.add(_ContactInfo(
            id: userId,
            name: data?['fullName'] ?? data?['name'] ?? 'Unknown',
            imageUrl: data?['imageUrl'],
            bio: data?['bio'],
          ));
        }
      }

      // Sort by name
      contacts.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  List<_ContactInfo> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    final query = _searchQuery.toLowerCase();
    return _contacts.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.bio?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _save() {
    widget.onSave(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Allowed Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'These people can reach you during DND',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIds.length}',
                      style: TextStyle(
                        color: ColorsManager.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade500),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Quick actions
          if (_selectedIds.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _QuickActionChip(
                    icon: Icons.clear_all,
                    label: 'Clear All',
                    onTap: () => setState(() => _selectedIds.clear()),
                  ),
                ],
              ),
            ),

          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactTile(contact);
                        },
                      ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting to add contacts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(_ContactInfo contact) {
    final isSelected = _selectedIds.contains(contact.id);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
        backgroundImage: contact.imageUrl != null
            ? NetworkImage(contact.imageUrl!)
            : null,
        child: contact.imageUrl == null
            ? Text(
                contact.name[0].toUpperCase(),
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(contact.name),
      subtitle: contact.bio != null
          ? Text(
              contact.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedIds.add(contact.id);
            } else {
              _selectedIds.remove(contact.id);
            }
          });
        },
        activeColor: ColorsManager.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(contact.id);
          } else {
            _selectedIds.add(contact.id);
          }
        });
      },
    );
  }
}

class _ContactInfo {
  final String id;
  final String name;
  final String? imageUrl;
  final String? bio;

  _ContactInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
  });
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Allowed Contacts Tile Widget
/// Shows a summary of allowed contacts in settings
class AllowedContactsTile extends StatelessWidget {
  final List<String> contactIds;
  final VoidCallback onTap;

  const AllowedContactsTile({
    super.key,
    required this.contactIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.indigo),
      ),
      title: const Text('Allowed Contacts'),
      subtitle: Text(
        contactIds.isEmpty
            ? 'No contacts can reach you during DND'
            : '${contactIds.length} contact${contactIds.length == 1 ? '' : 's'} can reach you',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

/// Starred Contacts Chip Row
/// Shows avatars of allowed contacts in a row
class AllowedContactsChipRow extends StatelessWidget {
  final List<String> contactIds;
  final int maxVisible;

  const AllowedContactsChipRow({
    super.key,
    required this.contactIds,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (contactIds.isEmpty) {
      return Text(
        'No contacts allowed',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      );
    }

    return FutureBuilder<List<_ContactInfo>>(
      future: _fetchContactInfos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final contacts = snapshot.data!;
        final visibleContacts = contacts.take(maxVisible).toList();
        final remaining = contacts.length - visibleContacts.length;

        return Row(
          children: [
            ...visibleContacts.map((contact) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                    backgroundImage: contact.imageUrl != null
                        ? NetworkImage(contact.imageUrl!)
                        : null,
                    child: contact.imageUrl == null
                        ? Text(
                            contact.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsManager.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                )),
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<_ContactInfo>> _fetchContactInfos() async {
    final contacts = <_ContactInfo>[];
    for (final id in contactIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (doc.exists) {
          final data = doc.data();
          contacts.add(_ContactInfo(
            id: id,
            name: data?['fullName'] ?? data?['name'] ?? 'Unknown',
            imageUrl: data?['imageUrl'],
          ));
        }
      } catch (e) {
        debugPrint('Error fetching contact $id: $e');
      }
    }
    return contacts;
  }
}

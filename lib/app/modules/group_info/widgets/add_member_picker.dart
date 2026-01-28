import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// Add Member Picker Widget
/// Allows group admins to select contacts to add to the group
class AddMemberPicker extends StatefulWidget {
  final List<String> existingMemberIds;
  final Function(List<SocialMediaUser>) onMembersSelected;

  const AddMemberPicker({
    super.key,
    required this.existingMemberIds,
    required this.onMembersSelected,
  });

  static Future<List<SocialMediaUser>?> show({
    required BuildContext context,
    required List<String> existingMemberIds,
  }) async {
    List<SocialMediaUser>? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMemberPicker(
        existingMemberIds: existingMemberIds,
        onMembersSelected: (members) {
          result = members;
          Navigator.pop(context);
        },
      ),
    );
    return result;
  }

  @override
  State<AddMemberPicker> createState() => _AddMemberPickerState();
}

class _AddMemberPickerState extends State<AddMemberPicker> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<SocialMediaUser> _contacts = [];
  final Map<String, SocialMediaUser> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
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
          // Exclude current user and existing group members
          if (id != currentUserId && !widget.existingMemberIds.contains(id)) {
            userIds.add(id);
          }
        }
      }

      // Fetch user details
      final contacts = <SocialMediaUser>[];
      for (final userId in userIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          contacts.add(SocialMediaUser.fromQuery(userDoc));
        }
      }

      // Sort by name
      contacts.sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  List<SocialMediaUser> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    final query = _searchQuery.toLowerCase();
    return _contacts.where((c) {
      return (c.fullName?.toLowerCase().contains(query) ?? false) ||
          (c.bio?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _save() {
    widget.onMembersSelected(_selectedUsers.values.toList());
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
                Icon(Icons.person_add_rounded, color: ColorsManager.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Members',
                        style: StylesManager.semiBold(fontSize: FontSize.large),
                      ),
                      Text(
                        'Select contacts to add to the group',
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

          // Selected members chips
          if (_selectedUsers.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers.values.elementAt(index);
                  return _SelectedMemberChip(
                    user: user,
                    onRemove: () {
                      setState(() {
                        _selectedIds.remove(user.uid);
                        _selectedUsers.remove(user.uid);
                      });
                    },
                  );
                },
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
                    onPressed: _selectedIds.isEmpty ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Add Members'
                          : 'Add ${_selectedIds.length} Member${_selectedIds.length == 1 ? '' : 's'}',
                    ),
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
            'No contacts to add',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your contacts are already in this group',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(SocialMediaUser contact) {
    final isSelected = _selectedIds.contains(contact.uid);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
        backgroundImage: contact.imageUrl != null && contact.imageUrl!.isNotEmpty
            ? NetworkImage(contact.imageUrl!)
            : null,
        child: contact.imageUrl == null || contact.imageUrl!.isEmpty
            ? Text(
                (contact.fullName ?? '?')[0].toUpperCase(),
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(contact.fullName ?? 'Unknown'),
      subtitle: contact.bio != null && contact.bio!.isNotEmpty
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
              _selectedIds.add(contact.uid!);
              _selectedUsers[contact.uid!] = contact;
            } else {
              _selectedIds.remove(contact.uid);
              _selectedUsers.remove(contact.uid);
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
            _selectedIds.remove(contact.uid);
            _selectedUsers.remove(contact.uid);
          } else {
            _selectedIds.add(contact.uid!);
            _selectedUsers[contact.uid!] = contact;
          }
        });
      },
    );
  }
}

class _SelectedMemberChip extends StatelessWidget {
  final SocialMediaUser user;
  final VoidCallback onRemove;

  const _SelectedMemberChip({
    required this.user,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
                    ? NetworkImage(user.imageUrl!)
                    : null,
                child: user.imageUrl == null || user.imageUrl!.isEmpty
                    ? Text(
                        (user.fullName ?? '?')[0].toUpperCase(),
                        style: TextStyle(
                          color: ColorsManager.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: Text(
              (user.fullName ?? 'Unknown').split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

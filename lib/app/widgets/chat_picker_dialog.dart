import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Chat room item for display in picker
class ChatRoomPickerItem {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isGroup;

  ChatRoomPickerItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isGroup = false,
  });
}

/// Chat Picker Dialog
/// Allows users to select one or more chat rooms to forward messages to
class ChatPickerDialog extends StatefulWidget {
  final bool multiSelect;
  final String title;
  final String? subtitle;

  const ChatPickerDialog({
    super.key,
    this.multiSelect = false,
    this.title = 'Forward to',
    this.subtitle,
  });

  /// Show dialog and return selected chat room(s)
  static Future<List<ChatRoomPickerItem>?> show({
    required BuildContext context,
    bool multiSelect = false,
    String title = 'Forward to',
    String? subtitle,
  }) async {
    return showModalBottomSheet<List<ChatRoomPickerItem>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChatPickerDialog(
        multiSelect: multiSelect,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<ChatPickerDialog> createState() => _ChatPickerDialogState();
}

class _ChatPickerDialogState extends State<ChatPickerDialog> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<ChatRoomPickerItem> _chatRooms = [];

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('membersIds', arrayContains: userId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();

      final rooms = <ChatRoomPickerItem>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isGroup = data['isGroupChat'] == true;

        String name;
        String? imageUrl;

        if (isGroup) {
          name = data['name'] as String? ?? 'Group Chat';
          imageUrl = data['groupImageUrl'] as String?;
        } else {
          // For private chats, get the other user's name
          final nameData = _getOtherUserData(data, userId);
          name = nameData['name'] ?? 'Chat';
          imageUrl = nameData['imageUrl'];
        }

        rooms.add(ChatRoomPickerItem(
          id: doc.id,
          name: name,
          imageUrl: imageUrl,
          isGroup: isGroup,
        ));
      }

      setState(() {
        _chatRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, String?> _getOtherUserData(
    Map<String, dynamic> roomData,
    String currentUserId,
  ) {
    final members = roomData['members'] as List<dynamic>?;
    if (members == null) return {'name': 'Chat', 'imageUrl': null};

    for (final member in members) {
      if (member is Map<String, dynamic>) {
        final uid = member['uid'] as String?;
        if (uid != null && uid != currentUserId) {
          return {
            'name': member['fullName'] as String? ?? 'Chat',
            'imageUrl': member['photoUrl'] as String?,
          };
        }
      }
    }
    return {'name': 'Chat', 'imageUrl': null};
  }

  List<ChatRoomPickerItem> get _filteredRooms {
    if (_searchQuery.isEmpty) return _chatRooms;
    return _chatRooms.where((room) {
      return room.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _onRoomTap(ChatRoomPickerItem room) {
    if (widget.multiSelect) {
      setState(() {
        if (_selectedIds.contains(room.id)) {
          _selectedIds.remove(room.id);
        } else {
          _selectedIds.add(room.id);
        }
      });
    } else {
      Navigator.pop(context, [room]);
    }
  }

  void _confirmSelection() {
    final selected = _chatRooms.where((r) => _selectedIds.contains(r.id)).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorsManager.veryLightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorsManager.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.multiSelect && _selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: _confirmSelection,
                    child: Text(
                      'Send (${_selectedIds.length})',
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
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ColorsManager.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Chat list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredRooms.length,
                        itemBuilder: (context, index) {
                          final room = _filteredRooms[index];
                          return _buildRoomTile(room);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ChatRoomPickerItem room) {
    final isSelected = _selectedIds.contains(room.id);

    return ListTile(
      onTap: () => _onRoomTap(room),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: room.imageUrl != null
            ? CachedNetworkImageProvider(room.imageUrl!)
            : null,
        backgroundColor: ColorsManager.veryLightGrey,
        child: room.imageUrl == null
            ? Icon(
                room.isGroup ? Icons.group : Icons.person,
                color: ColorsManager.textSecondary,
              )
            : null,
      ),
      title: Text(
        room.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        room.isGroup ? 'Group' : 'Private chat',
        style: TextStyle(
          fontSize: 12,
          color: ColorsManager.textSecondary,
        ),
      ),
      trailing: widget.multiSelect
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => _onRoomTap(room),
              activeColor: ColorsManager.primary,
            )
          : const Icon(Icons.chevron_right),
      selected: isSelected,
      selectedTileColor: ColorsManager.primary.withValues(alpha: 0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: ColorsManager.lightGrey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No chats found' : 'No chats available',
            style: TextStyle(
              color: ColorsManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

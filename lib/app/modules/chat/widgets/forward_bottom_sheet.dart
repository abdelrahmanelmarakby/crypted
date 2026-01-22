import 'package:crypted_app/app/data/models/messages/message_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Target type for forwarding
enum ForwardTargetType { chat, user }

/// Forward target model
class ForwardTarget {
  final String id;
  final String name;
  final String? imageUrl;
  final ForwardTargetType type;
  final bool isGroup;
  final int? memberCount;
  final DateTime? lastActive;

  const ForwardTarget({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.type,
    this.isGroup = false,
    this.memberCount,
    this.lastActive,
  });
}

/// Clean bottom sheet for message forwarding
///
/// Features:
/// - Search bar for filtering targets
/// - Recent chats section
/// - All contacts section
/// - Multi-select support for forwarding to multiple targets
/// - Clean visual design
class ForwardBottomSheet extends StatefulWidget {
  const ForwardBottomSheet({
    super.key,
    required this.message,
    required this.recentChats,
    required this.allContacts,
    required this.onForward,
    required this.onForwardMultiple,
    this.maxTargets = 5,
    this.isLoading = false,
  });

  final Message message;
  final List<ForwardTarget> recentChats;
  final List<ForwardTarget> allContacts;
  final void Function(ForwardTarget target) onForward;
  final void Function(List<ForwardTarget> targets) onForwardMultiple;
  final int maxTargets;
  final bool isLoading;

  /// Show the forward bottom sheet
  static Future<void> show(
    BuildContext context, {
    required Message message,
    required List<ForwardTarget> recentChats,
    required List<ForwardTarget> allContacts,
    required void Function(ForwardTarget target) onForward,
    required void Function(List<ForwardTarget> targets) onForwardMultiple,
    int maxTargets = 5,
    bool isLoading = false,
  }) {
    HapticFeedback.mediumImpact();

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ForwardBottomSheet(
          message: message,
          recentChats: recentChats,
          allContacts: allContacts,
          onForward: onForward,
          onForwardMultiple: onForwardMultiple,
          maxTargets: maxTargets,
          isLoading: isLoading,
        ),
      ),
    );
  }

  @override
  State<ForwardBottomSheet> createState() => _ForwardBottomSheetState();
}

class _ForwardBottomSheetState extends State<ForwardBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTargets = {};
  String _searchQuery = '';
  bool _isMultiSelectMode = false;

  List<ForwardTarget> get _filteredRecentChats {
    if (_searchQuery.isEmpty) return widget.recentChats;
    return widget.recentChats
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<ForwardTarget> get _filteredContacts {
    if (_searchQuery.isEmpty) return widget.allContacts;
    return widget.allContacts
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleSelection(ForwardTarget target) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTargets.contains(target.id)) {
        _selectedTargets.remove(target.id);
        if (_selectedTargets.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        if (_selectedTargets.length < widget.maxTargets) {
          _selectedTargets.add(target.id);
          _isMultiSelectMode = true;
        }
      }
    });
  }

  void _handleForward(ForwardTarget target) {
    if (_isMultiSelectMode) {
      _toggleSelection(target);
    } else {
      Navigator.pop(context);
      widget.onForward(target);
    }
  }

  void _handleForwardMultiple() {
    if (_selectedTargets.isEmpty) return;

    final targets = [
      ...widget.recentChats,
      ...widget.allContacts,
    ].where((t) => _selectedTargets.contains(t.id)).toList();

    Navigator.pop(context);
    widget.onForwardMultiple(targets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          _buildHandleBar(),

          // Header
          _buildHeader(),

          // Search bar
          _buildSearchBar(),

          // Content
          Expanded(
            child: widget.isLoading
                ? _buildLoadingState()
                : _buildContent(),
          ),

          // Multi-select action bar
          if (_isMultiSelectMode) _buildMultiSelectBar(),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: ColorsManager.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forward Message',
                style: TextStyle(
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.black,
                ),
              ),
              if (_isMultiSelectMode)
                Text(
                  '${_selectedTargets.length}/${widget.maxTargets} selected',
                  style: TextStyle(
                    fontSize: FontSize.small,
                    color: ColorsManager.primary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (!_isMultiSelectMode)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isMultiSelectMode = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.checklist,
                      size: 16,
                      color: ColorsManager.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Select Multiple',
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: ColorsManager.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: ColorsManager.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search chats or contacts...',
          hintStyle: TextStyle(
            color: ColorsManager.grey,
            fontSize: FontSize.medium,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: ColorsManager.grey,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.clear,
                    color: ColorsManager.grey,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ColorsManager.primary,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading chats...',
            style: TextStyle(
              color: ColorsManager.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent chats section
          if (_filteredRecentChats.isNotEmpty) ...[
            _buildSectionHeader('Recent Chats'),
            ..._filteredRecentChats.map((target) => _buildTargetItem(target)),
            const SizedBox(height: 16),
          ],

          // All contacts section
          if (_filteredContacts.isNotEmpty) ...[
            _buildSectionHeader('All Contacts'),
            ..._filteredContacts.map((target) => _buildTargetItem(target)),
          ],

          // Empty state
          if (_filteredRecentChats.isEmpty && _filteredContacts.isEmpty)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: FontSize.small,
          fontWeight: FontWeight.w600,
          color: ColorsManager.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTargetItem(ForwardTarget target) {
    final isSelected = _selectedTargets.contains(target.id);

    return GestureDetector(
      onTap: () => _handleForward(target),
      onLongPress: () {
        if (!_isMultiSelectMode) {
          HapticFeedback.mediumImpact();
          _toggleSelection(target);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(target),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          target.name,
                          style: TextStyle(
                            fontSize: FontSize.medium,
                            fontWeight: FontWeight.w500,
                            color: ColorsManager.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (target.isGroup)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorsManager.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Group',
                            style: TextStyle(
                              fontSize: FontSize.xXSmall,
                              color: ColorsManager.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (target.memberCount != null)
                    Text(
                      '${target.memberCount} members',
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                ],
              ),
            ),

            // Selection indicator
            if (_isMultiSelectMode)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? ColorsManager.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? ColorsManager.primary
                        : ColorsManager.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ColorsManager.grey.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ForwardTarget target) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.grey.withValues(alpha: 0.1),
      ),
      child: target.imageUrl != null && target.imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: target.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildAvatarPlaceholder(target),
                errorWidget: (context, url, error) =>
                    _buildAvatarPlaceholder(target),
              ),
            )
          : _buildAvatarPlaceholder(target),
    );
  }

  Widget _buildAvatarPlaceholder(ForwardTarget target) {
    return Center(
      child: Text(
        target.name.isNotEmpty ? target.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: FontSize.large,
          fontWeight: FontWeight.w600,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: ColorsManager.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: FontSize.medium,
              fontWeight: FontWeight.w500,
              color: ColorsManager.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: FontSize.small,
              color: ColorsManager.grey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedTargets.clear();
                _isMultiSelectMode = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ColorsManager.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: FontSize.medium,
                  fontWeight: FontWeight.w500,
                  color: ColorsManager.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Forward button
          Expanded(
            child: GestureDetector(
              onTap: _selectedTargets.isNotEmpty ? _handleForwardMultiple : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTargets.isNotEmpty
                      ? ColorsManager.primary
                      : ColorsManager.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      size: 18,
                      color: _selectedTargets.isNotEmpty
                          ? Colors.white
                          : ColorsManager.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Forward${_selectedTargets.isNotEmpty ? ' (${_selectedTargets.length})' : ''}',
                      style: TextStyle(
                        fontSize: FontSize.medium,
                        fontWeight: FontWeight.w600,
                        color: _selectedTargets.isNotEmpty
                            ? Colors.white
                            : ColorsManager.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

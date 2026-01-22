import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Bottom sheet for group management operations
///
/// Features:
/// - View and edit group info (name, description, image)
/// - Manage group permissions
/// - Leave group or transfer ownership
/// - Clean visual design with clear action items
class GroupManagementBottomSheet extends StatefulWidget {
  const GroupManagementBottomSheet({
    super.key,
    required this.groupInfo,
    required this.isAdmin,
    required this.isCreator,
    required this.onEditName,
    required this.onEditDescription,
    required this.onEditImage,
    required this.onEditPermissions,
    required this.onLeaveGroup,
    required this.onTransferOwnership,
    required this.onViewMembers,
    required this.onAddMembers,
    this.isLoading = false,
  });

  final GroupInfo groupInfo;
  final bool isAdmin;
  final bool isCreator;
  final void Function(String newName) onEditName;
  final void Function(String newDescription) onEditDescription;
  final VoidCallback onEditImage;
  final VoidCallback onEditPermissions;
  final VoidCallback onLeaveGroup;
  final VoidCallback onTransferOwnership;
  final VoidCallback onViewMembers;
  final VoidCallback onAddMembers;
  final bool isLoading;

  /// Show the group management bottom sheet
  static void show(
    BuildContext context, {
    required GroupInfo groupInfo,
    required bool isAdmin,
    required bool isCreator,
    required void Function(String newName) onEditName,
    required void Function(String newDescription) onEditDescription,
    required VoidCallback onEditImage,
    required VoidCallback onEditPermissions,
    required VoidCallback onLeaveGroup,
    required VoidCallback onTransferOwnership,
    required VoidCallback onViewMembers,
    required VoidCallback onAddMembers,
    bool isLoading = false,
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GroupManagementBottomSheet(
          groupInfo: groupInfo,
          isAdmin: isAdmin,
          isCreator: isCreator,
          onEditName: onEditName,
          onEditDescription: onEditDescription,
          onEditImage: onEditImage,
          onEditPermissions: onEditPermissions,
          onLeaveGroup: onLeaveGroup,
          onTransferOwnership: onTransferOwnership,
          onViewMembers: onViewMembers,
          onAddMembers: onAddMembers,
          isLoading: isLoading,
        ),
      ),
    );
  }

  @override
  State<GroupManagementBottomSheet> createState() =>
      _GroupManagementBottomSheetState();
}

class _GroupManagementBottomSheetState
    extends State<GroupManagementBottomSheet> {
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

          // Header with group info
          _buildHeader(),

          // Content
          Expanded(
            child: widget.isLoading
                ? _buildLoadingState()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildContent(),
                  ),
          ),

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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Group image
          GestureDetector(
            onTap: widget.isAdmin ? widget.onEditImage : null,
            child: Stack(
              children: [
                _buildGroupAvatar(),
                if (widget.isAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupInfo.name,
                  style: TextStyle(
                    fontSize: FontSize.large,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.groupInfo.memberCount} members',
                  style: TextStyle(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),

          // Close button
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

  Widget _buildGroupAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.grey.withValues(alpha: 0.1),
      ),
      child: widget.groupInfo.imageUrl != null &&
              widget.groupInfo.imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.groupInfo.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildAvatarPlaceholder(),
                errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
              ),
            )
          : _buildAvatarPlaceholder(),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Icon(
        Icons.group,
        size: 32,
        color: ColorsManager.primary.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: ColorsManager.primary,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description section
        if (widget.groupInfo.description != null &&
            widget.groupInfo.description!.isNotEmpty)
          _buildDescriptionSection(),

        const SizedBox(height: 8),

        // Members section
        _buildSectionHeader('Members'),
        _buildActionItem(
          icon: Icons.people,
          title: 'View All Members',
          subtitle: '${widget.groupInfo.memberCount} members',
          onTap: () {
            Navigator.pop(context);
            widget.onViewMembers();
          },
        ),
        if (widget.isAdmin)
          _buildActionItem(
            icon: Icons.person_add,
            title: 'Add Members',
            onTap: () {
              Navigator.pop(context);
              widget.onAddMembers();
            },
            iconColor: ColorsManager.primary,
          ),

        const SizedBox(height: 16),

        // Group settings section (admin only)
        if (widget.isAdmin) ...[
          _buildSectionHeader('Group Settings'),
          _buildActionItem(
            icon: Icons.edit,
            title: 'Edit Group Name',
            subtitle: widget.groupInfo.name,
            onTap: () => _showEditNameSheet(),
          ),
          _buildActionItem(
            icon: Icons.description,
            title: 'Edit Description',
            subtitle: widget.groupInfo.description?.isNotEmpty == true
                ? widget.groupInfo.description!
                : 'Add a description',
            onTap: () => _showEditDescriptionSheet(),
          ),
          _buildActionItem(
            icon: Icons.tune,
            title: 'Group Permissions',
            subtitle: 'Manage who can send messages, add members, etc.',
            onTap: () {
              Navigator.pop(context);
              widget.onEditPermissions();
            },
          ),
          const SizedBox(height: 16),
        ],

        // Danger zone
        _buildSectionHeader(''),
        if (widget.isCreator)
          _buildActionItem(
            icon: Icons.swap_horiz,
            title: 'Transfer Ownership',
            subtitle: 'Make another member the group owner',
            onTap: () {
              Navigator.pop(context);
              widget.onTransferOwnership();
            },
            iconColor: ColorsManager.warning,
          ),
        _buildActionItem(
          icon: Icons.exit_to_app,
          title: 'Leave Group',
          subtitle: widget.isCreator
              ? 'Transfer ownership before leaving'
              : 'You will no longer receive messages',
          onTap: () => _showLeaveConfirmation(),
          iconColor: ColorsManager.error2,
          isDestructive: true,
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: ColorsManager.grey.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.groupInfo.description!,
              style: TextStyle(
                fontSize: FontSize.small,
                color: ColorsManager.black.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (title.isEmpty) return const SizedBox.shrink();
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

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? ColorsManager.error2.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? ColorsManager.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? ColorsManager.grey,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FontSize.medium,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? ColorsManager.error2
                          : ColorsManager.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
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

  void _showEditNameSheet() {
    final controller = TextEditingController(text: widget.groupInfo.name);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Group Name',
                style: TextStyle(
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: kMaxGroupNameLength,
                decoration: InputDecoration(
                  hintText: 'Group name',
                  filled: true,
                  fillColor: ColorsManager.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: TextStyle(
                    fontSize: FontSize.xXSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorsManager.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty &&
                            newName != widget.groupInfo.name) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          widget.onEditName(newName);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: FontSize.medium,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDescriptionSheet() {
    final controller =
        TextEditingController(text: widget.groupInfo.description ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Description',
                style: TextStyle(
                  fontSize: FontSize.large,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: kMaxGroupDescriptionLength,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add a group description...',
                  filled: true,
                  fillColor: ColorsManager.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: TextStyle(
                    fontSize: FontSize.xXSmall,
                    color: ColorsManager.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorsManager.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final newDesc = controller.text.trim();
                        Navigator.pop(context);
                        Navigator.pop(context);
                        widget.onEditDescription(newDesc);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: ColorsManager.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: FontSize.medium,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ColorsManager.error2.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.exit_to_app,
                size: 28,
                color: ColorsManager.error2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave Group?',
              style: TextStyle(
                fontSize: FontSize.xLarge,
                fontWeight: FontWeight.w600,
                color: ColorsManager.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will no longer receive messages from this group. You can rejoin if invited again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: ColorsManager.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      widget.onLeaveGroup();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: ColorsManager.error2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Leave',
                          style: TextStyle(
                            fontSize: FontSize.medium,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

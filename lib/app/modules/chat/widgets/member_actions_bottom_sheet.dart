import 'package:crypted_app/app/domain/repositories/i_group_repository.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Bottom sheet for member-specific actions
///
/// Features:
/// - View member profile
/// - Send direct message
/// - Make/remove admin (if authorized)
/// - Remove from group (if authorized)
/// - Transfer ownership (if creator)
/// - Clean visual design
class MemberActionsBottomSheet extends StatelessWidget {
  const MemberActionsBottomSheet({
    super.key,
    required this.member,
    required this.isCurrentUserAdmin,
    required this.isCurrentUserCreator,
    required this.isSelf,
    required this.onViewProfile,
    required this.onSendMessage,
    this.onMakeAdmin,
    this.onRemoveAdmin,
    this.onRemoveMember,
    this.onTransferOwnership,
    this.isLoading = false,
  });

  final GroupMember member;
  final bool isCurrentUserAdmin;
  final bool isCurrentUserCreator;
  final bool isSelf;
  final VoidCallback onViewProfile;
  final VoidCallback onSendMessage;
  final VoidCallback? onMakeAdmin;
  final VoidCallback? onRemoveAdmin;
  final VoidCallback? onRemoveMember;
  final VoidCallback? onTransferOwnership;
  final bool isLoading;

  /// Show the member actions bottom sheet
  static void show(
    BuildContext context, {
    required GroupMember member,
    required bool isCurrentUserAdmin,
    required bool isCurrentUserCreator,
    required bool isSelf,
    required VoidCallback onViewProfile,
    required VoidCallback onSendMessage,
    VoidCallback? onMakeAdmin,
    VoidCallback? onRemoveAdmin,
    VoidCallback? onRemoveMember,
    VoidCallback? onTransferOwnership,
    bool isLoading = false,
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MemberActionsBottomSheet(
        member: member,
        isCurrentUserAdmin: isCurrentUserAdmin,
        isCurrentUserCreator: isCurrentUserCreator,
        isSelf: isSelf,
        onViewProfile: onViewProfile,
        onSendMessage: onSendMessage,
        onMakeAdmin: onMakeAdmin,
        onRemoveAdmin: onRemoveAdmin,
        onRemoveMember: onRemoveMember,
        onTransferOwnership: onTransferOwnership,
        isLoading: isLoading,
      ),
    );
  }

  /// Determine what admin actions are available
  bool get canMakeAdmin =>
      isCurrentUserAdmin && !member.isAdmin && onMakeAdmin != null;

  bool get canRemoveAdmin =>
      isCurrentUserCreator && member.isAdmin && !member.isCreator && onRemoveAdmin != null;

  bool get canRemoveMember =>
      isCurrentUserAdmin && !member.isCreator && !isSelf && onRemoveMember != null;

  bool get canTransferOwnership =>
      isCurrentUserCreator && !isSelf && onTransferOwnership != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandleBar(),

          // Member header
          _buildMemberHeader(context),

          // Divider
          Divider(
            height: 1,
            color: ColorsManager.grey.withValues(alpha: 0.1),
          ),

          // Actions
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: ColorsManager.primary,
                strokeWidth: 2,
              ),
            )
          else
            Column(
              children: [
                // Basic actions
                _buildActionItem(
                  context: context,
                  icon: Icons.person,
                  title: 'View Profile',
                  onTap: () {
                    Navigator.pop(context);
                    onViewProfile();
                  },
                ),
                if (!isSelf)
                  _buildActionItem(
                    context: context,
                    icon: Icons.message,
                    title: 'Send Message',
                    onTap: () {
                      Navigator.pop(context);
                      onSendMessage();
                    },
                  ),

                // Admin actions
                if (canMakeAdmin)
                  _buildActionItem(
                    context: context,
                    icon: Icons.admin_panel_settings,
                    title: 'Make Admin',
                    subtitle: 'Give admin privileges',
                    onTap: () => _showMakeAdminConfirmation(context),
                    iconColor: ColorsManager.primary,
                  ),

                if (canRemoveAdmin)
                  _buildActionItem(
                    context: context,
                    icon: Icons.remove_moderator,
                    title: 'Remove Admin',
                    subtitle: 'Remove admin privileges',
                    onTap: () => _showRemoveAdminConfirmation(context),
                    iconColor: ColorsManager.warning,
                  ),

                if (canTransferOwnership)
                  _buildActionItem(
                    context: context,
                    icon: Icons.swap_horiz,
                    title: 'Transfer Ownership',
                    subtitle: 'Make this member the group owner',
                    onTap: () => _showTransferOwnershipConfirmation(context),
                    iconColor: ColorsManager.warning,
                  ),

                // Destructive actions
                if (canRemoveMember)
                  _buildActionItem(
                    context: context,
                    icon: Icons.person_remove,
                    title: 'Remove from Group',
                    subtitle: 'This member will be removed',
                    onTap: () => _showRemoveMemberConfirmation(context),
                    iconColor: ColorsManager.error2,
                    isDestructive: true,
                  ),
              ],
            ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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

  Widget _buildMemberHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: TextStyle(
                          fontSize: FontSize.large,
                          fontWeight: FontWeight.w600,
                          color: ColorsManager.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorsManager.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: FontSize.xXSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildRoleBadge(),
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

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.grey.withValues(alpha: 0.1),
      ),
      child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: member.avatarUrl!,
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
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: FontSize.xLarge,
          fontWeight: FontWeight.w600,
          color: ColorsManager.primary,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color badgeColor;
    String roleText;
    IconData roleIcon;

    switch (member.role) {
      case GroupRole.creator:
        badgeColor = ColorsManager.primary;
        roleText = 'Owner';
        roleIcon = Icons.star;
        break;
      case GroupRole.admin:
        badgeColor = ColorsManager.success;
        roleText = 'Admin';
        roleIcon = Icons.admin_panel_settings;
        break;
      case GroupRole.member:
        badgeColor = ColorsManager.grey;
        roleText = 'Member';
        roleIcon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleIcon,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: TextStyle(
              fontSize: FontSize.xXSmall,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
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

  void _showMakeAdminConfirmation(BuildContext context) {
    _showConfirmationSheet(
      context: context,
      icon: Icons.admin_panel_settings,
      iconColor: ColorsManager.primary,
      title: 'Make Admin?',
      message:
          '${member.name} will be able to add or remove members and edit group settings.',
      confirmText: 'Make Admin',
      confirmColor: ColorsManager.primary,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
        onMakeAdmin?.call();
      },
    );
  }

  void _showRemoveAdminConfirmation(BuildContext context) {
    _showConfirmationSheet(
      context: context,
      icon: Icons.remove_moderator,
      iconColor: ColorsManager.warning,
      title: 'Remove Admin?',
      message:
          '${member.name} will no longer be able to manage the group.',
      confirmText: 'Remove Admin',
      confirmColor: ColorsManager.warning,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
        onRemoveAdmin?.call();
      },
    );
  }

  void _showRemoveMemberConfirmation(BuildContext context) {
    _showConfirmationSheet(
      context: context,
      icon: Icons.person_remove,
      iconColor: ColorsManager.error2,
      title: 'Remove Member?',
      message:
          '${member.name} will be removed from this group. They can rejoin if invited again.',
      confirmText: 'Remove',
      confirmColor: ColorsManager.error2,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
        onRemoveMember?.call();
      },
    );
  }

  void _showTransferOwnershipConfirmation(BuildContext context) {
    _showConfirmationSheet(
      context: context,
      icon: Icons.swap_horiz,
      iconColor: ColorsManager.warning,
      title: 'Transfer Ownership?',
      message:
          '${member.name} will become the group owner. You will become an admin.',
      confirmText: 'Transfer',
      confirmColor: ColorsManager.warning,
      onConfirm: () {
        Navigator.pop(context);
        Navigator.pop(context);
        onTransferOwnership?.call();
      },
    );
  }

  void _showConfirmationSheet({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
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
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.xLarge,
                fontWeight: FontWeight.w600,
                color: ColorsManager.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: confirmColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          confirmText,
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

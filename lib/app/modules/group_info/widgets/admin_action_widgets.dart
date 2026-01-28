import 'package:flutter/material.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Admin badge displayed next to admin usernames
class AdminBadge extends StatelessWidget {
  final bool isCreator;
  final bool compact;

  const AdminBadge({
    super.key,
    this.isCreator = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isCreator
              ? ColorsManager.primary.withValues(alpha: 0.15)
              : Colors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isCreator ? 'Creator' : 'Admin',
          style: TextStyle(
            color: isCreator ? ColorsManager.primary : Colors.blue.shade700,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCreator
            ? ColorsManager.primary.withValues(alpha: 0.15)
            : Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCreator
              ? ColorsManager.primary.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCreator ? Icons.star : Icons.admin_panel_settings,
            size: 12,
            color: isCreator ? ColorsManager.primary : Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isCreator ? 'Creator' : 'Admin',
            style: TextStyle(
              color: isCreator ? ColorsManager.primary : Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Member tile with admin actions
class AdminMemberTile extends StatelessWidget {
  final SocialMediaUser member;
  final bool isAdmin;
  final bool isCreator;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback? onTap;
  final VoidCallback? onMakeAdmin;
  final VoidCallback? onRemoveAdmin;
  final VoidCallback? onRemoveMember;
  final VoidCallback? onViewProfile;

  const AdminMemberTile({
    super.key,
    required this.member,
    this.isAdmin = false,
    this.isCreator = false,
    this.isCurrentUser = false,
    this.canManage = false,
    this.onTap,
    this.onMakeAdmin,
    this.onRemoveAdmin,
    this.onRemoveMember,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () => _showMemberActions(context),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
            backgroundImage: member.imageUrl != null && member.imageUrl!.isNotEmpty
                ? NetworkImage(member.imageUrl!)
                : null,
            child: member.imageUrl == null || member.imageUrl!.isEmpty
                ? Text(
                    (member.fullName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorsManager.primary,
                    ),
                  )
                : null,
          ),
          if (isAdmin)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCreator ? ColorsManager.primary : Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  isCreator ? Icons.star : Icons.shield,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isCurrentUser ? '${member.fullName ?? 'You'} (You)' : (member.fullName ?? 'Unknown'),
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAdmin || isCreator) ...[
            const SizedBox(width: 8),
            AdminBadge(isCreator: isCreator, compact: true),
          ],
        ],
      ),
      subtitle: member.bio != null && member.bio!.isNotEmpty
          ? Text(
              member.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            )
          : null,
      trailing: canManage && !isCurrentUser
          ? IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMemberActions(context),
            )
          : null,
    );
  }

  void _showMemberActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MemberActionsSheet(
        member: member,
        isAdmin: isAdmin,
        isCreator: isCreator,
        isCurrentUser: isCurrentUser,
        canManage: canManage,
        onViewProfile: onViewProfile,
        onMakeAdmin: onMakeAdmin,
        onRemoveAdmin: onRemoveAdmin,
        onRemoveMember: onRemoveMember,
      ),
    );
  }
}

/// Bottom sheet with member action options
class MemberActionsSheet extends StatelessWidget {
  final SocialMediaUser member;
  final bool isAdmin;
  final bool isCreator;
  final bool isCurrentUser;
  final bool canManage;
  final VoidCallback? onViewProfile;
  final VoidCallback? onMakeAdmin;
  final VoidCallback? onRemoveAdmin;
  final VoidCallback? onRemoveMember;

  const MemberActionsSheet({
    super.key,
    required this.member,
    this.isAdmin = false,
    this.isCreator = false,
    this.isCurrentUser = false,
    this.canManage = false,
    this.onViewProfile,
    this.onMakeAdmin,
    this.onRemoveAdmin,
    this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                  backgroundImage:
                      member.imageUrl != null && member.imageUrl!.isNotEmpty
                          ? NetworkImage(member.imageUrl!)
                          : null,
                  child: member.imageUrl == null || member.imageUrl!.isEmpty
                      ? Text(
                          (member.fullName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorsManager.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (isAdmin || isCreator)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AdminBadge(isCreator: isCreator),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          if (onViewProfile != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                onViewProfile?.call();
              },
            ),

          if (canManage && !isCurrentUser && !isCreator) ...[
            if (!isAdmin && onMakeAdmin != null)
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.blue.shade700),
                title: const Text('Make Group Admin'),
                subtitle: const Text('Allow this member to manage the group'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAction(
                    context,
                    title: 'Make Admin?',
                    message: 'Make ${member.fullName} a group admin?',
                    confirmText: 'Make Admin',
                    confirmColor: Colors.blue,
                    onConfirm: onMakeAdmin!,
                  );
                },
              ),

            if (isAdmin && onRemoveAdmin != null)
              ListTile(
                leading: Icon(Icons.remove_moderator, color: Colors.orange.shade700),
                title: const Text('Remove as Admin'),
                subtitle: const Text('Remove admin privileges'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAction(
                    context,
                    title: 'Remove Admin?',
                    message: 'Remove ${member.fullName} as group admin?',
                    confirmText: 'Remove Admin',
                    confirmColor: Colors.orange,
                    onConfirm: onRemoveAdmin!,
                  );
                },
              ),

            if (onRemoveMember != null)
              ListTile(
                leading: Icon(Icons.person_remove, color: Colors.red.shade700),
                title: Text(
                  'Remove from Group',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAction(
                    context,
                    title: 'Remove Member?',
                    message: 'Remove ${member.fullName} from this group?',
                    confirmText: 'Remove',
                    confirmColor: Colors.red,
                    onConfirm: onRemoveMember!,
                  );
                },
              ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Admin-only section wrapper
class AdminOnlySection extends StatelessWidget {
  final bool isAdmin;
  final String title;
  final Widget child;

  const AdminOnlySection({
    super.key,
    required this.isAdmin,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: ColorsManager.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Admin action button
class AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool destructive;

  const AdminActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? (destructive ? Colors.red : ColorsManager.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: buttonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: buttonColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

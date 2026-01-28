import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Action tile for user info screens
class UserInfoActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isLoading;

  const UserInfoActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? ColorsManager.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? ColorsManager.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }
}

/// Switch tile for user info screens
class UserInfoSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;
  final bool isLoading;

  const UserInfoSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.value,
    this.onChanged,
    this.showDivider = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return UserInfoActionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      iconColor: iconColor,
      showDivider: showDivider,
      isLoading: isLoading,
      trailing: Switch(
        value: value,
        onChanged: isLoading ? null : onChanged,
        activeThumbColor: ColorsManager.primary,
      ),
      onTap: isLoading ? null : () => onChanged?.call(!value),
    );
  }
}

/// Member tile for group info
class GroupMemberTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final bool isAdmin;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showDivider;

  const GroupMemberTile({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
    this.isAdmin = false,
    this.isCurrentUser = false,
    this.onTap,
    this.onRemove,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? NetworkImage(imageUrl!)
                      : null,
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isCurrentUser ? 'You' : name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorsManager.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onRemove != null && !isCurrentUser && !isAdmin)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }
}

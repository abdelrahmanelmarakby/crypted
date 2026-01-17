import 'package:flutter/material.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Header widget for user/group info screens
class UserInfoHeader extends StatelessWidget {
  final String name;
  final String? status;
  final String? imageUrl;
  final bool isOnline;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final VoidCallback? onImageTap;

  const UserInfoHeader({
    super.key,
    required this.name,
    this.status,
    this.imageUrl,
    this.isOnline = false,
    this.onBackPressed,
    this.actions,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),

            // Profile section
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Profile image
                  GestureDetector(
                    onTap: onImageTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                                ? NetworkImage(imageUrl!)
                                : null,
                            child: imageUrl == null || imageUrl!.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Online indicator
                        if (isOnline)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Status
                  if (status != null && status!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      status!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header widget for group info with member count
class GroupInfoHeader extends StatelessWidget {
  final String name;
  final String? description;
  final String? imageUrl;
  final int memberCount;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final VoidCallback? onImageTap;
  final VoidCallback? onEditTap;
  final bool canEdit;

  const GroupInfoHeader({
    super.key,
    required this.name,
    this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.onBackPressed,
    this.actions,
    this.onImageTap,
    this.onEditTap,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: onEditTap,
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),

            // Profile section
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Group image
                  GestureDetector(
                    onTap: onImageTap,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                            ? NetworkImage(imageUrl!)
                            : null,
                        child: imageUrl == null || imageUrl!.isEmpty
                            ? const Icon(
                                Icons.group,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  // Member count
                  Text(
                    '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Description
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

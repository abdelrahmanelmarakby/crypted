import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/user_info/controllers/enhanced_group_info_controller.dart';
import 'package:crypted_app/app/modules/user_info/models/group_info_state.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_header.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_section.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_action_tile.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

/// Modern group info view with comprehensive features
class GroupInfoView extends GetView<EnhancedGroupInfoController> {
  const GroupInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final state = controller.state.value;

        if (state.isLoading && state.group == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.group == null) {
          return _buildErrorState(state.errorMessage!);
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(context, state),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Group Header
                    GroupInfoHeader(
                      name: state.name,
                      imageUrl: state.imageUrl,
                      memberCount: state.members.length,
                      description: state.description,
                      canEdit: controller.isCurrentUserAdmin,
                      onEditTap: controller.isCurrentUserAdmin
                          ? controller.showEditGroupDialog
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Quick Actions
                    _buildQuickActions(state),

                    const SizedBox(height: 16),

                    // Description Section (if exists)
                    if (state.description.isNotEmpty)
                      _buildDescriptionSection(state),

                    // Media Section
                    _buildMediaSection(state),

                    const SizedBox(height: 8),

                    // Members Section
                    _buildMembersSection(state),

                    const SizedBox(height: 8),

                    // Group Options
                    _buildGroupOptions(state),

                    const SizedBox(height: 8),

                    // Danger Zone
                    _buildDangerZone(state),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAppBar(BuildContext context, GroupInfoState state) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Text(
        state.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (controller.isCurrentUserAdmin)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: controller.showEditGroupDialog,
            tooltip: 'Edit Group',
          ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, state),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Search in chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: ListTile(
                leading: Icon(
                  state.isMuted
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                ),
                title: Text(state.isMuted ? 'Unmute' : 'Mute'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.flag, color: Colors.orange),
                title: Text('Report Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(GroupInfoState state) {
    final isTogglingMute = state.pendingAction == GroupInfoAction.togglingMute;
    final isTogglingFavorite =
        state.pendingAction == GroupInfoAction.togglingFavorite;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            icon: state.isMuted ? Icons.notifications_off : Icons.notifications,
            label: state.isMuted ? 'Unmute' : 'Mute',
            onTap: controller.toggleMute,
            isLoading: isTogglingMute,
            isActive: state.isMuted,
          ),
          _buildQuickActionButton(
            icon: state.isFavorite ? Icons.star : Icons.star_border,
            label: 'Favorite',
            onTap: controller.toggleFavorite,
            isLoading: isTogglingFavorite,
            isActive: state.isFavorite,
          ),
          _buildQuickActionButton(
            icon: Icons.search,
            label: 'Search',
            onTap: () => _openSearchInChat(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? ColorsManager.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      icon,
                      color:
                          isActive ? ColorsManager.primary : Colors.grey.shade700,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? ColorsManager.primary : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(GroupInfoState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(GroupInfoState state) {
    return UserInfoSection(
      title: 'Shared Media',
      children: [
        UserInfoActionTile(
          icon: Icons.photo_library,
          title: 'Photos',
          subtitle: '${state.mediaCounts.photos} photos',
          onTap: controller.viewMedia,
        ),
        UserInfoActionTile(
          icon: Icons.videocam,
          title: 'Videos',
          subtitle: '${state.mediaCounts.videos} videos',
          onTap: controller.viewMedia,
        ),
        UserInfoActionTile(
          icon: Icons.insert_drive_file,
          title: 'Files',
          subtitle: '${state.mediaCounts.files} files',
          onTap: controller.viewMedia,
        ),
        UserInfoActionTile(
          icon: Icons.link,
          title: 'Links',
          subtitle: '${state.mediaCounts.links} links',
          onTap: controller.viewMedia,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildMembersSection(GroupInfoState state) {
    final currentUserId = controller.currentUser?.uid;

    return UserInfoSection(
      title: '${state.members.length} Members',
      trailing: controller.isCurrentUserAdmin
          ? TextButton.icon(
              onPressed: controller.navigateToAddMembers,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.primary,
              ),
            )
          : null,
      children: [
        // Add member button at top for admins
        if (controller.isCurrentUserAdmin)
          UserInfoActionTile(
            icon: Icons.person_add,
            title: 'Add Member',
            iconColor: ColorsManager.primary,
            titleColor: ColorsManager.primary,
            onTap: controller.navigateToAddMembers,
          ),

        // Members list
        ...state.members.map((member) {
          final isAdmin = state.admins.any((a) => a == member.uid);
          final isCurrentUser = member.uid == currentUserId;

          return GroupMemberTile(
            name: member.fullName ?? 'Unknown',
            imageUrl: member.photoUrl,
            subtitle: member.phoneNumber,
            isAdmin: isAdmin,
            isCurrentUser: isCurrentUser,
            onTap: isCurrentUser
                ? null
                : () => controller.viewMemberProfile(member),
            onRemove: controller.isCurrentUserAdmin && !isCurrentUser && !isAdmin
                ? () => controller.removeMember(member.uid!)
                : null,
            showDivider: member != state.members.last,
          );
        }),
      ],
    );
  }

  Widget _buildGroupOptions(GroupInfoState state) {
    return UserInfoSection(
      title: 'Chat Options',
      children: [
        UserInfoSwitchTile(
          icon: Icons.notifications_off,
          title: 'Mute Notifications',
          subtitle: state.isMuted ? 'Muted' : 'Unmuted',
          value: state.isMuted,
          onChanged: (_) => controller.toggleMute(),
          isLoading: state.pendingAction == GroupInfoAction.togglingMute,
        ),
        UserInfoSwitchTile(
          icon: Icons.star,
          title: 'Add to Favorites',
          subtitle: state.isFavorite ? 'In favorites' : 'Not in favorites',
          value: state.isFavorite,
          onChanged: (_) => controller.toggleFavorite(),
          isLoading: state.pendingAction == GroupInfoAction.togglingFavorite,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildDangerZone(GroupInfoState state) {
    final isLeaving = state.pendingAction == GroupInfoAction.leaving;
    final isReporting = state.pendingAction == GroupInfoAction.reporting;

    return UserInfoSection(
      title: 'Danger Zone',
      children: [
        UserInfoActionTile(
          icon: Icons.flag,
          title: 'Report Group',
          subtitle: 'Report inappropriate content',
          iconColor: Colors.orange,
          onTap: controller.reportGroup,
          isLoading: isReporting,
        ),
        UserInfoActionTile(
          icon: Icons.exit_to_app,
          title: 'Leave Group',
          subtitle: 'Exit this group',
          iconColor: Colors.red,
          titleColor: Colors.red,
          onTap: controller.leaveGroup,
          isLoading: isLeaving,
          showDivider: false,
        ),
      ],
    );
  }

  void _handleMenuAction(String action, GroupInfoState state) {
    switch (action) {
      case 'search':
        _openSearchInChat();
        break;
      case 'mute':
        controller.toggleMute();
        break;
      case 'report':
        controller.reportGroup();
        break;
    }
  }

  /// Navigate back to chat and open search mode
  void _openSearchInChat() {
    // Pop back to chat screen and trigger search mode
    Get.back(result: {'openSearch': true});
  }
}

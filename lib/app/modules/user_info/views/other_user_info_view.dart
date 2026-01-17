import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:crypted_app/app/modules/user_info/controllers/other_user_info_controller.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_header.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_section.dart';
import 'package:crypted_app/app/modules/user_info/widgets/user_info_action_tile.dart';
import 'package:crypted_app/app/modules/settings_v2/core/models/privacy_settings_model.dart';
import 'package:crypted_app/app/modules/settings_v2/privacy/widgets/disappearing_messages_settings.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

class OtherUserInfoView extends GetView<OtherUserInfoController> {
  const OtherUserInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Obx(() {
        final state = controller.state.value;

        if (state.isLoading && state.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null && state.user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.warning_2, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              // Header with user profile
              SliverToBoxAdapter(
                child: UserInfoHeader(
                  name: state.displayName,
                  status: state.statusText,
                  imageUrl: state.imageUrl,
                  isOnline: state.isOnline,
                  onBackPressed: () => Get.back(),
                  actions: [
                    IconButton(
                      icon: const Icon(Iconsax.call, color: Colors.white),
                      onPressed: () => controller.startCall(isVideo: false),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.video, color: Colors.white),
                      onPressed: () => controller.startCall(isVideo: true),
                    ),
                  ],
                ),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        icon: Iconsax.message,
                        label: 'Message',
                        onTap: controller.openChat,
                      ),
                      _buildQuickAction(
                        icon: Iconsax.call,
                        label: 'Call',
                        onTap: () => controller.startCall(isVideo: false),
                      ),
                      _buildQuickAction(
                        icon: Iconsax.video,
                        label: 'Video',
                        onTap: () => controller.startCall(isVideo: true),
                      ),
                      _buildQuickAction(
                        icon: state.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                        label: 'Favorite',
                        isActive: state.isFavorite,
                        onTap: controller.toggleFavorite,
                      ),
                    ],
                  ),
                ),
              ),

              // Bio section
              if (state.bio.isNotEmpty)
                SliverToBoxAdapter(
                  child: UserInfoSection(
                    title: 'About',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.bio,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contact info section
              if (state.hasContactInfo)
                SliverToBoxAdapter(
                  child: UserInfoSection(
                    title: 'Contact Info',
                    children: [
                      if (state.email.isNotEmpty)
                        UserInfoActionTile(
                          icon: Iconsax.sms,
                          title: 'Email',
                          subtitle: state.email,
                          onTap: () {
                            // TODO: Open email
                          },
                        ),
                      if (state.phone.isNotEmpty)
                        UserInfoActionTile(
                          icon: Iconsax.call,
                          title: 'Phone',
                          subtitle: state.phone,
                          onTap: () {
                            // TODO: Open phone
                          },
                        ),
                    ],
                  ),
                ),

              // Media section
              SliverToBoxAdapter(
                child: UserInfoSection(
                  title: 'Media, Links and Documents',
                  trailing: TextButton(
                    onPressed: controller.viewMedia,
                    child: Text(
                      'See All (${state.mediaCounts.total})',
                      style: TextStyle(color: ColorsManager.primary),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildMediaCount(
                            icon: Iconsax.image,
                            count: state.mediaCounts.photos,
                            label: 'Photos',
                          ),
                          _buildMediaCount(
                            icon: Iconsax.video,
                            count: state.mediaCounts.videos,
                            label: 'Videos',
                          ),
                          _buildMediaCount(
                            icon: Iconsax.document,
                            count: state.mediaCounts.files,
                            label: 'Files',
                          ),
                          _buildMediaCount(
                            icon: Iconsax.link,
                            count: state.mediaCounts.links,
                            label: 'Links',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mutual contacts section
              if (state.mutualContacts.isNotEmpty)
                SliverToBoxAdapter(
                  child: UserInfoSection(
                    title: 'Mutual Contacts (${state.mutualContacts.length})',
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: state.mutualContacts.length,
                          itemBuilder: (context, index) {
                            final contact = state.mutualContacts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: contact.imageUrl != null
                                        ? NetworkImage(contact.imageUrl!)
                                        : null,
                                    child: contact.imageUrl == null
                                        ? Text(contact.fullName?.substring(0, 1) ?? '?')
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      contact.fullName ?? 'Unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Chat options section
              SliverToBoxAdapter(
                child: UserInfoSection(
                  title: 'Chat Options',
                  children: [
                    UserInfoActionTile(
                      icon: Iconsax.star,
                      title: 'Starred Messages',
                      onTap: controller.viewStarredMessages,
                    ),
                    UserInfoActionTile(
                      icon: Iconsax.timer,
                      title: 'Disappearing Messages',
                      subtitle: state.disappearingDuration != DisappearingDuration.off
                          ? state.disappearingDuration.displayName
                          : 'Off',
                      onTap: () async {
                        final result = await DisappearingMessagesSheet.show(
                          context,
                          chatId: state.chatId ?? '',
                          chatName: state.displayName,
                          isGroup: false,
                          currentDuration: state.disappearingDuration,
                        );
                        if (result != null) {
                          controller.updateDisappearingMessages(result);
                        }
                      },
                    ),
                    UserInfoActionTile(
                      icon: state.isMuted ? Iconsax.notification_bing : Iconsax.notification,
                      title: state.isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                      onTap: controller.toggleMute,
                    ),
                    UserInfoActionTile(
                      icon: Iconsax.setting_4,
                      title: 'Custom Notifications',
                      subtitle: state.hasCustomNotifications ? 'Custom' : 'Default',
                      onTap: () => controller.openCustomNotificationSettings(context),
                    ),
                    UserInfoActionTile(
                      icon: state.isArchived ? Iconsax.archive_tick : Iconsax.archive,
                      title: state.isArchived ? 'Unarchive Chat' : 'Archive Chat',
                      onTap: controller.toggleArchive,
                    ),
                  ],
                ),
              ),

              // Danger zone section
              SliverToBoxAdapter(
                child: UserInfoSection(
                  title: '',
                  children: [
                    UserInfoActionTile(
                      icon: Iconsax.trash,
                      title: 'Clear Chat',
                      titleColor: Colors.red,
                      onTap: controller.clearChat,
                    ),
                    UserInfoActionTile(
                      icon: state.isBlocked ? Iconsax.unlock : Iconsax.lock,
                      title: state.isBlocked ? 'Unblock ${state.displayName}' : 'Block ${state.displayName}',
                      titleColor: state.isBlocked ? ColorsManager.primary : Colors.red,
                      onTap: controller.toggleBlock,
                    ),
                    UserInfoActionTile(
                      icon: Iconsax.flag,
                      title: 'Report ${state.displayName}',
                      titleColor: Colors.red,
                      onTap: controller.reportUser,
                    ),
                  ],
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : ColorsManager.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCount({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: ColorsManager.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:avatar_stack/animated_avatar_stack.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

class UserSelectionWidget extends StatelessWidget {
  final SocialMediaUser user;
  final VoidCallback onTap;
  final bool isSelected;

  const UserSelectionWidget({
    super.key,
    required this.user,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color:
            isSelected ? ColorsManager.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? ColorsManager.primary : ColorsManager.lightGrey,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // صورة المستخدم
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: ColorsManager.lightGrey,
                      child: ClipOval(
                        child: AppCachedNetworkImage(
                          imageUrl: user.imageUrl ?? '',
                          height: 48,
                          width: 48,
                        ),
                      ),
                    ),
                    // مؤشر الاختيار
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: ColorsManager.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // معلومات المستخدم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'Unknown User',
                        style: StylesManager.medium(
                          fontSize: FontSize.medium,
                          color:
                              isSelected ? ColorsManager.primary : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email != null && user.email!.isNotEmpty)
                        Text(
                          user.email!,
                          style: StylesManager.regular(
                            fontSize: FontSize.small,
                            color: ColorsManager.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // أيقونة بدء الشات
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorsManager.primary
                        : ColorsManager.offWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.message_2,
                    color: isSelected ? Colors.white : ColorsManager.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class UserSelectionBottomSheet extends GetView<HomeController> {
  const UserSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar - more subtle and Apple-like
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: ColorsManager.lightGrey.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header section with improved spacing
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                // Title with better typography
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorsManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people,
                        color: ColorsManager.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.kSelectUser.tr,
                            style: StylesManager.bold(
                              fontSize: 22,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Obx(() {
                            final selectedCount = controller.selectedUsers.length;
                            return Text(
                              selectedCount > 1 
                                ? '$selectedCount users selected for group chat'
                                : selectedCount == 1 
                                  ? '1 user selected for private chat'
                                  : Constants.kSelectUserToStartChat.tr,
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search field with Apple-style design
                Container(
                  decoration: BoxDecoration(
                    color: ColorsManager.lightGrey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      controller.searchQuery.value = value;
                    },
                    style: StylesManager.regular(
                      fontSize: FontSize.medium,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      fillColor: ColorsManager.offWhite,
                      hintText: 'Search users...',
                      hintStyle: StylesManager.regular(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey.withOpacity(0.8),

                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search,
                          color: ColorsManager.grey.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                      suffixIcon: Obx(() {
                        return controller.searchQuery.value.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: IconButton(
                                  onPressed: () {
                                    controller.searchQuery.value = '';
                                  },
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: ColorsManager.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: ColorsManager.grey,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected users preview and group creation form (when multiple selected)
          Obx(() {
            
            if (controller.selectedUsers.isEmpty) return const SizedBox.shrink();
            
            final isGroupChat = controller.selectedUsers.length > 1;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Selected users avatars
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isGroupChat ? 30 : 20,
                    child: AnimatedAvatarStack(
                      height: isGroupChat ? 30 : 20,
                      avatars: [
                        for (var user in controller.selectedUsers)
                          if (user.imageUrl?.isNotEmpty == true)
                            CachedNetworkImageProvider(user.imageUrl!)
                          else
                            // Fallback for users without images
                            const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ]
                    ),
                  ),
                  
                  // Header text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isGroupChat ? 'Create Group Chat' : 'Selected User',
                      key: ValueKey<bool>(isGroupChat),
                      style: StylesManager.medium(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Group creation form (only for group chats)
                  if (isGroupChat) ...[
                    // Group name input with staggered animation
                    AnimatedOpacity(
                      opacity: isGroupChat ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSlide(
                        offset: isGroupChat ? Offset.zero : const Offset(0, -0.1),
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: ColorsManager.offWhite,
                            borderRadius: BorderRadius.circular(12),
                          
                          ),
                          child: TextField(
                            onChanged: (value) {
                              controller.groupName.value = value;
                            },
                            style: StylesManager.medium(
                              fontSize: FontSize.medium,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter group name...',
                              hintStyle: StylesManager.regular(
                                fontSize: FontSize.medium,
                                color: ColorsManager.grey.withOpacity(0.6),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 12),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    controller.groupName.value.isNotEmpty ? Icons.group : Icons.group_outlined,
                                    color: controller.groupName.value.isNotEmpty
                                        ? ColorsManager.primary
                                        : ColorsManager.primary.withOpacity(0.7),
                                    size: 20,
                                    key: ValueKey<bool>(controller.groupName.value.isNotEmpty),
                                  ),
                                ),
                              ),
                              fillColor: ColorsManager.offWhite,
                              suffixIcon: Obx(() {
                                return controller.groupName.value.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: IconButton(
                                          onPressed: () {
                                            controller.groupName.value = '';
                                          },
                                          icon: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(4),

                                            decoration: BoxDecoration(
                                              
                                              color: ColorsManager.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }),
                             
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Group photo selection with staggered animation
                    AnimatedOpacity(
                      opacity: isGroupChat ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSlide(
                        offset: isGroupChat ? Offset.zero : const Offset(0, -0.1),
                        duration: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            // Photo preview/upload area
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  controller.pickGroupPhoto();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: ColorsManager.lightGrey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: controller.groupPhotoUrl.value.isNotEmpty
                                          ? ColorsManager.primary.withOpacity(0.4)
                                          : ColorsManager.primary.withOpacity(0.2),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Obx(() {
                                    final photoUrl = controller.groupPhotoUrl.value;

                                    // Show loading state
                                    if (controller.isLoadingGroupPhoto.value) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: ColorsManager.lightGrey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Row(
                                      children: [
                                        const SizedBox(width: 16),
                                        // Photo or placeholder
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: photoUrl.isNotEmpty
                                                  ? ColorsManager.primary.withOpacity(0.5)
                                                  : ColorsManager.primary.withOpacity(0.3),
                                              width: photoUrl.isNotEmpty ? 2 : 2,
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: photoUrl.isNotEmpty ? () {
                                              // Show full screen preview on tap when photo is selected
                                              _showPhotoPreview(context, photoUrl);
                                            } : () {
                                              controller.pickGroupPhoto();
                                            },
                                            onLongPress: photoUrl.isNotEmpty ? () {
                                              // Show remove confirmation on long press
                                              _showRemovePhotoDialog(context);
                                            } : null,
                                            child: Stack(
                                              children: [
                                                photoUrl.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: photoUrl.startsWith('http')
                                                            ? AppCachedNetworkImage(
                                                                imageUrl: photoUrl,
                                                                height: 56,
                                                                width: 56,
                                                                fit: BoxFit.cover,
                                                              )
                                                            : Image.file(
                                                                File(photoUrl),
                                                                height: 56,
                                                                width: 56,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Container(
                                                                    color: ColorsManager.lightGrey.withOpacity(0.1),
                                                                    child: Icon(
                                                                      Icons.broken_image,
                                                                      color: ColorsManager.grey,
                                                                      size: 24,
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                      )
                                                    : Center(
                                                      child: Icon(
                                                              Iconsax.image_copy,
                                                              color: ColorsManager.primary.withOpacity(0.7),
                                                              size: 24,
                                                            ),
                                                    ),

                                                // Remove button overlay (only when photo is selected)
                                                if (photoUrl.isNotEmpty)
                                                  Positioned(
                                                    top: 2,
                                                    right: 2,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _showRemovePhotoDialog(context);
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withOpacity(0.8),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                // Selected indicator
                                                if (photoUrl.isNotEmpty)
                                                  Positioned(
                                                    bottom: 2,
                                                    right: 2,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        color: ColorsManager.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 10,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // Group photo info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Group Photo',
                                                style: StylesManager.medium(
                                                  fontSize: FontSize.small,
                                                  color: ColorsManager.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                photoUrl.isNotEmpty
                                                    ? 'Photo selected • Tap to preview'
                                                    : 'Tap to select group photo',
                                                style: StylesManager.regular(
                                                  fontSize: FontSize.small,
                                                  color: photoUrl.isNotEmpty
                                                      ? ColorsManager.primary.withOpacity(0.8)
                                                      : ColorsManager.grey.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                  
                
                ],
              ),
            );
          }),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(
              color: ColorsManager.lightGrey.withOpacity(0.3),
              height: 1,
            ),
          ),


          // Users list
          Expanded(
            child: Obx(() {
              // Use the reactive displayUsers instead of FutureBuilder
              final users = controller.displayUsers;

              if (controller.isLoadingUsers.value) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorsManager.lightGrey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CircularProgressIndicator(
                      color: ColorsManager.primary,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              if (users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorsManager.lightGrey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.people_outline,
                            color: ColorsManager.grey,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          Constants.kNousersfound.tr,
                          style: StylesManager.medium(
                            fontSize: FontSize.medium,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final filteredUsers = users.where((user) {
                final query = controller.searchQuery.value.toLowerCase();
                final name = user.fullName?.toLowerCase() ?? '';
                final email = user.email?.toLowerCase() ?? '';
                return name.contains(query) || email.contains(query);
              }).toList();

              if (filteredUsers.isEmpty && controller.searchQuery.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorsManager.lightGrey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.search_off,
                            color: ColorsManager.grey,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'لا توجد نتائج للبحث',
                          style: StylesManager.medium(
                            fontSize: FontSize.medium,
                            color: ColorsManager.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرب البحث بكلمات مختلفة',
                          style: StylesManager.regular(
                            fontSize: FontSize.small,
                            color: ColorsManager.grey.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return 
              
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Obx(() {
                    final isSelected = controller.isUserSelected(user);
                    print("isSelected: $isSelected");
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorsManager.primary.withOpacity(0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: ColorsManager.primary.withOpacity(0.2),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            controller.toggleUserSelection(user);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Selection indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
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
                                          : ColorsManager.lightGrey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                // User avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: ColorsManager.primary.withValues(alpha: 0.1),
                                  child: user.imageUrl?.isNotEmpty == true ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: AppCachedNetworkImage(
                                      imageUrl: user.imageUrl!,
                                      fit: BoxFit.cover,
                                      height: Sizes.size48,
                                      width: Sizes.size48,
                                      isCircular: true,
                                    ),
                                  ) : Text(
                                    (user.fullName?.isNotEmpty == true
                                        ? user.fullName!.substring(0, 1)
                                        : '?').toUpperCase(),
                                    style: StylesManager.bold(
                                      fontSize: FontSize.medium,
                                      color: ColorsManager.primary,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // User info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName ?? 'Unknown User',
                                        style: StylesManager.medium(
                                          fontSize: FontSize.medium,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (user.email?.isNotEmpty == true)
                                        Text(
                                          user.email!,
                                          style: StylesManager.regular(
                                            fontSize: FontSize.small,
                                            color: ColorsManager.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Arrow indicator
                                Icon(
                                  Icons.chevron_right,
                                  color: ColorsManager.lightGrey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // Action button
          Obx(() {
            final selectedUsers = controller.selectedUsers;
            if (selectedUsers.isEmpty) return const SizedBox.shrink();

            final isGroupChat = selectedUsers.length > 1;
            final hasValidGroupName = !isGroupChat || (controller.groupName.value.trim().isNotEmpty);

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: hasValidGroupName ? ColorsManager.primary : ColorsManager.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasValidGroupName ? [
                    BoxShadow(
                      color: ColorsManager.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: hasValidGroupName ? () {
                      if (selectedUsers.length == 1) {
                        // Start private chat
                        print("👤 Starting private chat with: ${selectedUsers.first.fullName} (${selectedUsers.first.uid})");
                        controller.createNewPrivateChatRoom(selectedUsers.first);
                      } else {
                        // Validate group name before creating
                        if (controller.groupName.value.trim().isEmpty) {
                          BotToast.showText(text: 'Please enter a group name');
                          return;
                        }
                        // Start group chat
                        print("👥 Starting group chat with ${selectedUsers.length} users");
                        controller.createNewGroupChatRoom(selectedUsers);
                      }
                      Get.back();
                    } : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selectedUsers.length > 1 ? Icons.group_add : Icons.chat,
                              color: hasValidGroupName ? Colors.white : Colors.white.withOpacity(0.7),
                              size: 20,
                              key: ValueKey<bool>(hasValidGroupName),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          Text(
                            isGroupChat
                                ? (hasValidGroupName
                                    ? 'Create Group Chat (${selectedUsers.length})'
                                    : 'Enter group name to continue')
                                : 'Start Private Chat',
                            style: StylesManager.bold(
                              fontSize: FontSize.medium,
                              color: hasValidGroupName ? Colors.white : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Photo preview functionality
  void _showPhotoPreview(BuildContext context, String photoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: photoUrl.startsWith('http')
                  ? AppCachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.contain,
                    )
                  : Image.file(
                      File(photoUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 100,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Remove photo confirmation dialog
  void _showRemovePhotoDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Remove Photo',
          style: StylesManager.bold(fontSize: FontSize.large, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to remove this group photo?',
          style: StylesManager.regular(fontSize: FontSize.medium, color: ColorsManager.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: StylesManager.medium(fontSize: FontSize.medium, color: ColorsManager.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.groupPhotoUrl.value = '';
              Get.back();
              BotToast.showText(text: 'Group photo removed');
            },
            child: Text(
              'Remove',
              style: StylesManager.medium(fontSize: FontSize.medium, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorsManager.primary.withOpacity(0.15),
                            ColorsManager.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: ColorsManager.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: ColorsManager.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Chat',
                            style: StylesManager.bold(
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Obx(() {
                            final selectedCount = controller.selectedUsers.length;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                selectedCount > 1
                                  ? '$selectedCount members selected'
                                  : selectedCount == 1
                                    ? 'Start private conversation'
                                    : 'Select people to chat with',
                                key: ValueKey<int>(selectedCount),
                                style: StylesManager.regular(
                                  fontSize: FontSize.small,
                                  color: selectedCount > 0
                                    ? ColorsManager.primary.withOpacity(0.8)
                                    : ColorsManager.grey,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search field with enhanced design
                Container(
                  decoration: BoxDecoration(
                    color: ColorsManager.offWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ColorsManager.lightGrey.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      controller.searchQuery.value = value;
                    },
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: StylesManager.regular(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey.withOpacity(0.6),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Icon(
                          Icons.search_rounded,
                          color: ColorsManager.grey.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                      suffixIcon: Obx(() {
                        return controller.searchQuery.value.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: IconButton(
                                  onPressed: () {
                                    controller.searchQuery.value = '';
                                  },
                                  icon: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorsManager.grey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: ColorsManager.grey,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
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

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary.withOpacity(0.03),
                    ColorsManager.primary.withOpacity(0.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ColorsManager.primary.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Selected users avatars - Custom stack implementation
                      if (controller.selectedUsers.isNotEmpty)
                        SizedBox(
                          height: 35,
                          width: controller.selectedUsers.length > 1
                            ? (20 + (controller.selectedUsers.length.clamp(1, 4) - 1) * 16).toDouble()
                            : 35,
                          child: Stack(
                            children: List.generate(
                              controller.selectedUsers.length.clamp(1, 4),
                              (index) {
                                final user = controller.selectedUsers[index];
                                return Positioned(
                                  left: (index * 16).toDouble(),
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: user.imageUrl?.isNotEmpty == true
                                        ? AppCachedNetworkImage(
                                            imageUrl: user.imageUrl!,
                                            width: 35,
                                            height: 35,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: ColorsManager.primary.withOpacity(0.1),
                                            child: Center(
                                              child: Text(
                                                (user.fullName?.isNotEmpty == true
                                                  ? user.fullName!.substring(0, 1)
                                                  : '?').toUpperCase(),
                                                style: StylesManager.bold(
                                                  fontSize: FontSize.small,
                                                  color: ColorsManager.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Header text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: StylesManager.semiBold(
                                fontSize: FontSize.medium,
                                color: Colors.black87,
                              ),
                              child: Text(
                                isGroupChat ? 'Group Chat Setup' : 'Private Chat',
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey.withOpacity(0.8),
                              ),
                              child: Text(
                                isGroupChat
                                  ? 'Customize your group'
                                  : 'Ready to start chatting',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Group creation form (only for group chats)
                  if (isGroupChat) ...[
                    // Group name input with enhanced design
                    AnimatedOpacity(
                      opacity: isGroupChat ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSlide(
                        offset: isGroupChat ? Offset.zero : const Offset(0, -0.1),
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ColorsManager.lightGrey.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: controller.groupNameController,
                            onChanged: (value) {
                              controller.groupName.value = value;
                            },
                            style: StylesManager.medium(
                              fontSize: FontSize.medium,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Group name (required)',
                              hintStyle: StylesManager.regular(
                                fontSize: FontSize.medium,
                                color: ColorsManager.grey.withOpacity(0.5),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 10),
                                child: Obx(() => AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    controller.groupName.value.isNotEmpty
                                      ? Icons.group_rounded
                                      : Icons.group_outlined,
                                    color: controller.groupName.value.isNotEmpty
                                        ? ColorsManager.primary
                                        : ColorsManager.grey.withOpacity(0.6),
                                    size: 22,
                                    key: ValueKey<bool>(controller.groupName.value.isNotEmpty),
                                  ),
                                )),
                              ),
                              suffixIcon: Obx(() {
                                return controller.groupName.value.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: IconButton(
                                          onPressed: () {
                                            controller.groupNameController.clear();
                                            controller.groupName.value = '';
                                          },
                                          icon: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: ColorsManager.grey.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: ColorsManager.grey,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    
                    // Group photo selection with enhanced design
                    AnimatedOpacity(
                      opacity: isGroupChat ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSlide(
                        offset: isGroupChat ? Offset.zero : const Offset(0, -0.1),
                        duration: const Duration(milliseconds: 400),
                        child: GestureDetector(
                          onTap: () {
                            controller.pickGroupPhoto();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: controller.groupPhotoUrl.value.isNotEmpty
                                    ? ColorsManager.primary.withOpacity(0.3)
                                    : ColorsManager.lightGrey.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Obx(() {
                              final photoUrl = controller.groupPhotoUrl.value;

                              // Show loading state
                              if (controller.isLoadingGroupPhoto.value) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            ColorsManager.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Loading...',
                                        style: StylesManager.regular(
                                          fontSize: FontSize.small,
                                          color: ColorsManager.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Photo or placeholder
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: photoUrl.isNotEmpty
                                          ? Colors.transparent
                                          : ColorsManager.primary.withOpacity(0.05),
                                        border: Border.all(
                                          color: photoUrl.isNotEmpty
                                              ? ColorsManager.primary.withOpacity(0.2)
                                              : ColorsManager.lightGrey.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: photoUrl.isNotEmpty
                                          ? (photoUrl.startsWith('http')
                                              ? AppCachedNetworkImage(
                                                  imageUrl: photoUrl,
                                                  height: 62,
                                                  width: 62,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(photoUrl),
                                                  height: 62,
                                                  width: 62,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: ColorsManager.lightGrey.withOpacity(0.1),
                                                      child: Icon(
                                                        Icons.broken_image_rounded,
                                                        color: ColorsManager.grey,
                                                        size: 28,
                                                      ),
                                                    );
                                                  },
                                                ))
                                          : Center(
                                              child: Icon(
                                                Icons.add_photo_alternate_outlined,
                                                color: ColorsManager.primary.withOpacity(0.6),
                                                size: 30,
                                              ),
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
                                            style: StylesManager.semiBold(
                                              fontSize: FontSize.medium,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            photoUrl.isNotEmpty
                                                ? 'Tap to change or remove'
                                                : 'Optional • Tap to add',
                                            style: StylesManager.regular(
                                              fontSize: FontSize.small,
                                              color: ColorsManager.grey.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action button
                                    if (photoUrl.isNotEmpty)
                                      IconButton(
                                        onPressed: () {
                                          _showRemovePhotoDialog(context);
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red.shade400,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: ColorsManager.grey.withOpacity(0.4),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.8),
                    Colors.white,
                  ],
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: hasValidGroupName
                    ? LinearGradient(
                        colors: [
                          ColorsManager.primary,
                          ColorsManager.primary.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          ColorsManager.grey.withOpacity(0.3),
                          ColorsManager.grey.withOpacity(0.25),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasValidGroupName ? [
                    BoxShadow(
                      color: ColorsManager.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              selectedUsers.length > 1
                                ? Icons.group_add_rounded
                                : Icons.chat_bubble_rounded,
                              color: hasValidGroupName
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                              size: 22,
                              key: ValueKey<bool>(hasValidGroupName),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              isGroupChat
                                  ? (hasValidGroupName
                                      ? 'Create Group (${selectedUsers.length} members)'
                                      : 'Enter group name to continue')
                                  : 'Start Private Chat',
                              key: ValueKey<String>(
                                isGroupChat
                                  ? (hasValidGroupName ? 'valid' : 'invalid')
                                  : 'private',
                              ),
                              style: StylesManager.bold(
                                fontSize: FontSize.medium,
                                color: hasValidGroupName
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                              ),
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
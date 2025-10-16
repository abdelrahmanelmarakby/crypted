import 'package:avatar_stack/animated_avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
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

          // Selected users preview (when multiple selected)
          Obx(() {
            
            if (controller.selectedUsers.isEmpty) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.selectedUsers.length > 1 ? 'Group Members' : 'Selected User',
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: ColorsManager.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedAvatarStack(
                    height: 60,
                    avatars: [for (var user in controller.selectedUsers) CachedNetworkImageProvider(user.imageUrl!)]
                  ),
                  
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
            child: FutureBuilder<List<SocialMediaUser>>(
              future: controller.futureUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorsManager.lightGrey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: ColorsManager.grey,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'حدث خطأ في تحميل المستخدمين',
                            style: StylesManager.medium(
                              fontSize: FontSize.medium,
                              color: ColorsManager.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: ColorsManager.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  controller.fetchUsers();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'إعادة المحاولة',
                                    style: StylesManager.medium(
                                      fontSize: FontSize.medium,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

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

                return Obx(() {
                  final searchQuery = controller.searchQuery.value.toLowerCase();
                  final filteredUsers = users.where((user) {
                    final name = user.fullName?.toLowerCase() ?? '';
                    final email = user.email?.toLowerCase() ?? '';
                    return name.contains(searchQuery) || email.contains(searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
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

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Obx(() {
                        final isSelected = controller.selectedUsers.contains(user);
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
                });
              },
            ),
          ),

          // Action button
          Obx(() {
            final selectedUsers = controller.selectedUsers;
            if (selectedUsers.isEmpty) return const SizedBox.shrink();
            
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ColorsManager.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (selectedUsers.length == 1) {
                        // Start private chat
                        print("👤 Starting private chat with: ${selectedUsers.first.fullName} (${selectedUsers.first.uid})");
                        controller.creatNewChatRoom(selectedUsers.first);
                      } else {
                        // Start group chat
                        print("👥 Starting group chat with ${selectedUsers.length} users");
                        // controller.createGroupChatRoom(selectedUsers);
                      }
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedUsers.length > 1 ? Icons.group_add : Icons.chat,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedUsers.length > 1 
                                ? 'Start Group Chat (${selectedUsers.length})'
                                : 'Start Private Chat',
                            style: StylesManager.bold(
                              fontSize: FontSize.medium,
                              color: Colors.white,
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
}
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/app/modules/home/controllers/home_controller.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/app/widgets/network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                        : ColorsManager.lightGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
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
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // مؤشر السحب
          Container(
            width: Sizes.size38,
            height: Sizes.size4,
            margin: const EdgeInsets.only(bottom: Paddings.xLarge),
            decoration: BoxDecoration(
              color: ColorsManager.lightGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // العنوان
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: ColorsManager.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  Constants.kSelectUser.tr,
                  style: StylesManager.bold(
                    fontSize: FontSize.large,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            Constants.kSelectUserToStartChat.tr,
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),

          const SizedBox(height: 16),

          // حقل البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorsManager.lightGrey,
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                decoration: InputDecoration(
                  hintText: 'User search...',
                  hintStyle: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: ColorsManager.grey,
                    size: 20,
                  ),
                  suffixIcon: Obx(() {
                    return controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              controller.searchQuery.value = '';
                            },
                            icon: Icon(
                              Icons.clear,
                              color: ColorsManager.grey,
                              size: 20,
                            ),
                          )
                        : const SizedBox.shrink();
                  }),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // قائمة المستخدمين
          Expanded(
            child: FutureBuilder<List<SocialMediaUser>>(
              future: controller.futureUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorsManager.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: ColorsManager.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل المستخدمين',
                          style: StylesManager.medium(
                            fontSize: FontSize.medium,
                            color: ColorsManager.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            controller.fetchUsers();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: ColorsManager.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Constants.kNousersfound.tr,
                          style: StylesManager.medium(
                            fontSize: FontSize.medium,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Obx(() {
                  final searchQuery =
                      controller.searchQuery.value.toLowerCase();
                  final filteredUsers = users.where((user) {
                    final name = user.fullName?.toLowerCase() ?? '';
                    final email = user.email?.toLowerCase() ?? '';
                    return name.contains(searchQuery) ||
                        email.contains(searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: ColorsManager.grey,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
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
                              color: ColorsManager.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return UserSelectionWidget(
                        user: user,
                        onTap: () {
                          print(
                              "👤 Selected user: ${user.fullName} (${user.uid})");
                          controller.creatNewChatRoom(user);
                          Get.back();
                        },
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

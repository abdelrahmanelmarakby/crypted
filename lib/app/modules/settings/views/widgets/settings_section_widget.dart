import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/app/routes/app_pages.dart';

/// Settings section with clean list
class SettingsSectionWidget extends StatelessWidget {
  const SettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final MyLocaleController myLocaleController = Get.find<MyLocaleController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size16),
          SettingsGroupWidget([
            SettingTileWidget(
              title: Constants.kProfile.tr,
              icon: Icons.person_outline,
              onTap: () => Get.toNamed(Routes.PROFILE),
            ),
            SettingTileWidget(
              title: Constants.kPrivacy.tr,
              icon: Icons.lock_outline,
              onTap: () => Get.toNamed(Routes.PRIVACY),
            ),
            SettingTileWidget(
              title: Constants.kNotifications.tr,
              icon: Icons.notifications_outlined,
              onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
            ),
          ]),
          SizedBox(height: Sizes.size24),
          Text(
            'Support',
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size16),
          SettingsGroupWidget([
            SettingTileWidget(
              title: Constants.kHelp.tr,
              icon: Icons.help_outline,
              onTap: () => Get.toNamed(Routes.HELP),
            ),
            SettingTileWidget(
              title: Constants.kInviteFriend.tr,
              icon: Icons.person_add_outlined,
              onTap: () => Get.toNamed(Routes.INVITE_FRIEND),
            ),
          ]),
          SizedBox(height: Sizes.size24),
          Text(
            'Language',
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size16),
          SettingsGroupWidget([
            LanguageTileWidget(
              title: Constants.kArabic.tr,
              isSelected: myLocaleController.locale.value.languageCode == 'ar',
              onTap: () {
                myLocaleController.changeLocale('ar');
                _showFeedbackSnackBar('Language changed to Arabic', ColorsManager.success);
              },
            ),
            LanguageTileWidget(
              title: Constants.kEnglish.tr,
              isSelected: myLocaleController.locale.value.languageCode == 'en',
              onTap: () {
                myLocaleController.changeLocale('en');
                _showFeedbackSnackBar('Language changed to English', ColorsManager.success);
              },
            ),
          ]),
          SizedBox(height: Sizes.size24),
          Text(
            'Account',
            style: StylesManager.bold(
              fontSize: FontSize.xLarge,
              color: ColorsManager.black,
            ),
          ),
          SizedBox(height: Sizes.size16),
          SettingsGroupWidget([
            const LogoutTileWidget(),
            const DeleteAccountTileWidget(),
          ]),
        ],
      ),
    );
  }

  void _showFeedbackSnackBar(String message, Color color) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        snackPosition: SnackPosition.BOTTOM,
        icon: Icon(
          color == ColorsManager.success ? Icons.check_circle : Icons.info,
          color: ColorsManager.white,
        ),
      ),
    );
  }
}

/// Settings group with spacing
class SettingsGroupWidget extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroupWidget(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children
          .expand((widget) => [widget, SizedBox(height: Sizes.size8)])
          .toList()
        ..removeLast(),
    );
  }
}

/// Modern setting tile
class SettingTileWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SettingTileWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ColorsManager.primary,
                size: 20,
              ),
            ),
            SizedBox(width: Sizes.size16),
            Expanded(
              child: Text(
                title,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: ColorsManager.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorsManager.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Language tile with selection indicator
class LanguageTileWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageTileWidget({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? ColorsManager.primary.withOpacity(0.1) : ColorsManager.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ColorsManager.primary : ColorsManager.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorsManager.primary.withOpacity(0.2)
                    : ColorsManager.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language,
                color: isSelected ? ColorsManager.primary : ColorsManager.grey,
                size: 20,
              ),
            ),
            SizedBox(width: Sizes.size16),
            Expanded(
              child: Text(
                title,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: isSelected ? ColorsManager.primary : ColorsManager.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: ColorsManager.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Logout tile with warning style
class LogoutTileWidget extends StatelessWidget {
  const LogoutTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.find<SettingsController>().showLogoutConfirmationDialog();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorsManager.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.error,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.error.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout,
                color: ColorsManager.error,
                size: 20,
              ),
            ),
            SizedBox(width: Sizes.size16),
            Expanded(
              child: Text(
                Constants.kLogout.tr,
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: ColorsManager.error,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorsManager.error,
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete account tile with warning style
class DeleteAccountTileWidget extends StatelessWidget {
  const DeleteAccountTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.find<SettingsController>().showDeleteAccountConfirmationDialog();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorsManager.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorsManager.error,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.error.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_forever,
                color: ColorsManager.error,
                size: 20,
              ),
            ),
            SizedBox(width: Sizes.size16),
            Expanded(
              child: Text(
                'Delete Account',
                style: StylesManager.semiBold(
                  fontSize: FontSize.medium,
                  color: ColorsManager.error,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorsManager.error,
            ),
          ],
        ),
      ),
    );
  }
}

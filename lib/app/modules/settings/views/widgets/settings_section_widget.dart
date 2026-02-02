import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/app/modules/about/views/about_view.dart';
import 'package:crypted_app/app/core/services/premium_service.dart';
import 'package:crypted_app/core/locale/my_locale_controller.dart';
import 'package:crypted_app/core/themes/theme_controller.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/app/routes/app_pages.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings section — iOS-style grouped layout
///
/// Each section has a subtle grey header label and a shared white card
/// containing multiple tiles separated by thin dividers.
class SettingsSectionWidget extends StatelessWidget {
  const SettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final MyLocaleController myLocaleController =
        Get.find<MyLocaleController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Paddings.xXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Account Section ──
          _SectionHeader('ACCOUNT'),
          const SizedBox(height: Spacing.xs),
          SettingsGroupCard(
            children: [
              SettingTileWidget(
                title: Constants.kProfile.tr,
                icon: Iconsax.user_edit_copy,
                onTap: () => Get.toNamed(Routes.PROFILE),
              ),
              SettingTileWidget(
                title: Constants.kPrivacy.tr,
                icon: Iconsax.eye_copy,
                onTap: () => Get.toNamed(Routes.PRIVACY),
              ),
              SettingTileWidget(
                title: Constants.kNotifications.tr,
                icon: Iconsax.notification_circle,
                onTap: () => Get.toNamed(Routes.NOTIFICATIONS),
              ),
              SettingTileWidget(
                title: 'Backup & Restore',
                icon: Iconsax.cloud_add_copy,
                onTap: () => Get.toNamed(Routes.BACKUP),
              ),
            ],
          ),

          const SizedBox(height: Spacing.xl),

          // ── Subscription Section ──
          _SectionHeader('SUBSCRIPTION'),
          const SizedBox(height: Spacing.xs),
          const CryptedProSectionWidget(),

          const SizedBox(height: Spacing.xl),

          // ── Support Section ──
          _SectionHeader('SUPPORT'),
          const SizedBox(height: Spacing.xs),
          SettingsGroupCard(
            children: [
              SettingTileWidget(
                title: Constants.kHelp.tr,
                icon: Iconsax.quote_down,
                onTap: () => Get.toNamed(Routes.HELP),
              ),
              const PaidSupportTileWidget(),
              SettingTileWidget(
                title: 'About',
                icon: Iconsax.info_circle,
                onTap: () => Get.to(() => const AboutView()),
              ),
              SettingTileWidget(
                title: Constants.kInviteFriend.tr,
                icon: Iconsax.user_cirlce_add,
                onTap: () => Get.toNamed(Routes.INVITE_FRIEND),
              ),
            ],
          ),

          const SizedBox(height: Spacing.xl),

          // ── Analytics Privacy Section ──
          _SectionHeader('ANALYTICS PRIVACY'),
          const SizedBox(height: Spacing.xs),
          SettingsGroupCard(
            children: [
              const AnalyticsDeviceTrackingTileWidget(),
              const AnalyticsLocationTrackingTileWidget(),
              SettingTileWidget(
                title: 'View Collected Data',
                icon: Iconsax.document_text,
                onTap: () =>
                    Get.find<SettingsController>().showCollectedDataInfo(),
              ),
            ],
          ),

          const SizedBox(height: Spacing.xl),

          // ── Language Section ──
          _SectionHeader('LANGUAGE'),
          const SizedBox(height: Spacing.xs),
          SettingsGroupCard(
            children: [
              Obx(() => LanguageTileWidget(
                    title: Constants.kArabic.tr,
                    isSelected:
                        myLocaleController.locale.value.languageCode == 'ar',
                    onTap: () {
                      myLocaleController.changeLocale('ar');
                      _showFeedbackSnackBar(
                          'Language changed to Arabic', ColorsManager.success);
                    },
                  )),
              Obx(() => LanguageTileWidget(
                    title: Constants.kEnglish.tr,
                    isSelected:
                        myLocaleController.locale.value.languageCode == 'en',
                    onTap: () {
                      myLocaleController.changeLocale('en');
                      _showFeedbackSnackBar(
                          'Language changed to English', ColorsManager.success);
                    },
                  )),
              Obx(() => LanguageTileWidget(
                    title: Constants.kFrench.tr,
                    isSelected:
                        myLocaleController.locale.value.languageCode == 'fr',
                    onTap: () {
                      myLocaleController.changeLocale('fr');
                      _showFeedbackSnackBar(
                          'Langue changee en francais', ColorsManager.success);
                    },
                  )),
            ],
          ),

          const SizedBox(height: Spacing.xl),

          // ── Appearance Section ──
          _SectionHeader('APPEARANCE'),
          const SizedBox(height: Spacing.xs),
          const AppearanceSectionWidget(),

          const SizedBox(height: Spacing.xl),

          // ── Danger Zone Section ──
          _SectionHeader('ACCOUNT'),
          const SizedBox(height: Spacing.xs),
          SettingsGroupCard(
            children: const [
              LogoutTileWidget(),
              DeleteAccountTileWidget(),
            ],
          ),
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

// ─────────────────────────────────────────────────
// Section Header — subtle grey uppercase label
// ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: Spacing.xxs),
      child: Text(
        text,
        style: StylesManager.medium(
          fontSize: FontSize.xSmall,
          color: isDark ? ColorsManager.darkTextSecondary : ColorsManager.grey,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Group Card — shared white card with internal dividers
// ─────────────────────────────────────────────────

class SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroupCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.darkCard : ColorsManager.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: _buildChildrenWithDividers(isDark),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(bool isDark) {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        // Thin divider indented to align with text (past the icon)
        result.add(Divider(
          height: 0.5,
          thickness: 0.5,
          indent: 60,
          color: isDark ? ColorsManager.darkDivider : ColorsManager.border,
        ));
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────────
// Setting Tile — flat tile inside group card
// ─────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: ColorsManager.primary,
                  size: IconSizes.sm,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: StylesManager.regular(
                    fontSize: FontSize.medium,
                    color: isDark
                        ? ColorsManager.darkTextPrimary
                        : ColorsManager.black,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark
                    ? ColorsManager.darkTextTertiary
                    : ColorsManager.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Language Tile — flat with selection indicator
// ─────────────────────────────────────────────────

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
    return Material(
      color: isSelected
          ? ColorsManager.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorsManager.primary.withValues(alpha: 0.15)
                      : ColorsManager.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.language,
                  color:
                      isSelected ? ColorsManager.primary : ColorsManager.grey,
                  size: IconSizes.sm,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Builder(builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    title,
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color: isSelected
                          ? ColorsManager.primary
                          : isDark
                              ? ColorsManager.darkTextPrimary
                              : ColorsManager.black,
                    ),
                  );
                }),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: IconSizes.sm,
                  color: ColorsManager.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Logout Tile — destructive flat tile
// ─────────────────────────────────────────────────

class LogoutTileWidget extends StatelessWidget {
  const LogoutTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.find<SettingsController>().showLogoutConfirmationDialog();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.logout,
                  color: ColorsManager.error,
                  size: IconSizes.sm,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  Constants.kLogout.tr,
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: ColorsManager.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Delete Account Tile — destructive flat tile
// ─────────────────────────────────────────────────

class DeleteAccountTileWidget extends StatelessWidget {
  const DeleteAccountTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.find<SettingsController>().showDeleteAccountConfirmationDialog();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorsManager.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: ColorsManager.error,
                  size: IconSizes.sm,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: ColorsManager.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Crypted Pro Subscription Section
// ─────────────────────────────────────────────────

class CryptedProSectionWidget extends StatelessWidget {
  const CryptedProSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Everything is free now — no need to show Pro upsell
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────
// Paid Support Tile — opens support page (gated)
// ─────────────────────────────────────────────────

class PaidSupportTileWidget extends StatelessWidget {
  const PaidSupportTileWidget({super.key});

  static const String _supportUrl = 'https://abwabdigital.com';

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PremiumService>()) {
      return const SizedBox.shrink();
    }
    final premium = Get.find<PremiumService>();

    return Obx(() {
      final hasPrioritySupport =
          premium.hasFeature(PremiumFeature.prioritySupport);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (hasPrioritySupport) {
              // Pro users get direct support access
              final uri = Uri.parse(_supportUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } else {
              // Free users see the paywall first
              await premium.presentPaywallIfNeeded();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasPrioritySupport
                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                        : ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Iconsax.headphone,
                    color: hasPrioritySupport
                        ? const Color(0xFFD4A017)
                        : ColorsManager.primary,
                    size: IconSizes.sm,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        return Text(
                          'Priority Support',
                          style: StylesManager.regular(
                            fontSize: FontSize.medium,
                            color: ColorsManager.textPrimaryAdaptive(context),
                          ),
                        );
                      }),
                      if (!hasPrioritySupport) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Pro feature • Upgrade to access',
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!hasPrioritySupport)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PRO',
                      style: StylesManager.semiBold(
                        fontSize: FontSize.xXSmall,
                        color: ColorsManager.primary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: ColorsManager.lightGrey,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────
// Analytics Device Tracking Toggle Tile
// ─────────────────────────────────────────────────

class AnalyticsDeviceTrackingTileWidget extends StatelessWidget {
  const AnalyticsDeviceTrackingTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Obx(() => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.toggleAnalyticsDeviceTracking(
                !controller.analyticsDeviceTrackingEnabled.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Iconsax.mobile,
                      color: ColorsManager.primary,
                      size: IconSizes.sm,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          return Text(
                            'Device Tracking',
                            style: StylesManager.regular(
                              fontSize: FontSize.medium,
                              color: ColorsManager.textPrimaryAdaptive(context),
                            ),
                          );
                        }),
                        const SizedBox(height: 2),
                        Text(
                          'Collect device info for analytics',
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: controller.analyticsDeviceTrackingEnabled.value,
                      onChanged: (value) =>
                          controller.toggleAnalyticsDeviceTracking(value),
                      activeTrackColor:
                          ColorsManager.primary.withValues(alpha: 0.5),
                      activeThumbColor: ColorsManager.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────
// Analytics Location Tracking Toggle Tile
// ─────────────────────────────────────────────────

class AnalyticsLocationTrackingTileWidget extends StatelessWidget {
  const AnalyticsLocationTrackingTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Obx(() => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.toggleAnalyticsLocationTracking(
                !controller.analyticsLocationTrackingEnabled.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: controller.analyticsLocationTrackingEnabled.value
                          ? ColorsManager.warning.withValues(alpha: 0.1)
                          : ColorsManager.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Iconsax.location,
                      color: controller.analyticsLocationTrackingEnabled.value
                          ? ColorsManager.warning
                          : ColorsManager.grey,
                      size: IconSizes.sm,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          return Text(
                            'Location Tracking',
                            style: StylesManager.regular(
                              fontSize: FontSize.medium,
                              color: ColorsManager.textPrimaryAdaptive(context),
                            ),
                          );
                        }),
                        const SizedBox(height: 2),
                        Text(
                          'Collect location for stories & sessions',
                          style: StylesManager.regular(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: controller.analyticsLocationTrackingEnabled.value,
                      onChanged: (value) =>
                          controller.toggleAnalyticsLocationTracking(value),
                      activeTrackColor:
                          ColorsManager.warning.withValues(alpha: 0.5),
                      activeThumbColor: ColorsManager.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────
// Appearance Section — Light / Dark / System toggle
// ─────────────────────────────────────────────────

class AppearanceSectionWidget extends StatelessWidget {
  const AppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // Check if premium is registered for gating
    final bool hasPremium = Get.isRegistered<PremiumService>();
    final premium = hasPremium ? Get.find<PremiumService>() : null;

    return Obx(() {
      final currentMode = themeController.themeMode.value;

      // Free users can only use System theme — Dark/Light require Pro
      final bool canChangeTheme =
          premium == null || premium.hasFeature(PremiumFeature.customThemes);

      return SettingsGroupCard(
        children: [
          _ThemeOptionTile(
            title: 'Light',
            icon: Iconsax.sun_1_copy,
            isSelected: currentMode == ThemeMode.light,
            onTap: () {
              if (canChangeTheme) {
                themeController.setThemeMode(ThemeMode.light);
              } else {
                premium.presentPaywall();
              }
            },
            isPro: !canChangeTheme,
          ),
          _ThemeOptionTile(
            title: 'Dark',
            icon: Iconsax.moon_copy,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () {
              if (canChangeTheme) {
                themeController.setThemeMode(ThemeMode.dark);
              } else {
                premium.presentPaywall();
              }
            },
            isPro: !canChangeTheme,
          ),
          _ThemeOptionTile(
            title: 'System',
            icon: Iconsax.mobile_copy,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => themeController.setThemeMode(ThemeMode.system),
            isPro: false, // System is always free
          ),
        ],
      );
    });
  }
}

/// A single theme option tile matching the [LanguageTileWidget] style.
class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPro;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? ColorsManager.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorsManager.primary.withValues(alpha: 0.15)
                      : ColorsManager.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color:
                      isSelected ? ColorsManager.primary : ColorsManager.grey,
                  size: IconSizes.sm,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: StylesManager.medium(
                    fontSize: FontSize.medium,
                    color: isSelected
                        ? ColorsManager.primary
                        : ColorsManager.black,
                  ),
                ),
              ),
              if (isPro)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PRO',
                    style: StylesManager.semiBold(
                      fontSize: FontSize.xXSmall,
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
              if (isSelected && !isPro)
                Icon(
                  Icons.check_circle,
                  size: IconSizes.sm,
                  color: ColorsManager.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

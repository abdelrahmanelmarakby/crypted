import 'package:crypted_app/app/core/services/premium_service.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable dialog that blocks access to premium features and prompts upgrade.
///
/// Usage:
/// ```dart
/// // Quick check + gate in one call:
/// if (!PremiumGate.check(PremiumFeature.scheduledMessages)) return;
///
/// // Or show a detailed dialog:
/// PremiumGate.showDialog(
///   context: context,
///   feature: PremiumFeature.scheduledMessages,
///   title: 'Scheduled Messages',
///   description: 'Schedule messages to be sent later.',
/// );
/// ```
class PremiumGate {
  PremiumGate._();

  /// Human-readable labels for each premium feature.
  static const Map<PremiumFeature, String> _featureLabels = {
    PremiumFeature.largeFileUpload: 'Large File Uploads',
    PremiumFeature.extendedBackupStorage: 'Extended Backup Storage',
    PremiumFeature.customThemes: 'Custom Themes',
    PremiumFeature.prioritySupport: 'Priority Support',
    PremiumFeature.noAds: 'Ad-Free Experience',
    PremiumFeature.extendedStoryDuration: 'Extended Story Duration',
    PremiumFeature.advancedPrivacy: 'Advanced Privacy',
    PremiumFeature.scheduledMessages: 'Scheduled Messages',
    PremiumFeature.messageTranslation: 'Message Translation',
    PremiumFeature.exclusiveReactions: 'Exclusive Reactions',
  };

  /// Short descriptions for each feature.
  static const Map<PremiumFeature, String> _featureDescriptions = {
    PremiumFeature.largeFileUpload: 'Send files up to 4GB with Crypted Pro.',
    PremiumFeature.extendedBackupStorage:
        'Get up to 50GB of backup storage with Crypted Pro.',
    PremiumFeature.customThemes:
        'Personalize your chat with custom themes and wallpapers.',
    PremiumFeature.prioritySupport:
        'Get priority customer support with faster response times.',
    PremiumFeature.noAds: 'Enjoy a completely ad-free messaging experience.',
    PremiumFeature.extendedStoryDuration:
        'Create stories up to 60 seconds long.',
    PremiumFeature.advancedPrivacy:
        'Hide read receipts and typing indicators per chat.',
    PremiumFeature.scheduledMessages:
        'Schedule messages to be sent at a specific time.',
    PremiumFeature.messageTranslation:
        'Translate messages instantly in any conversation.',
    PremiumFeature.exclusiveReactions:
        'Access exclusive emoji reactions and sticker packs.',
  };

  /// Icons for each feature.
  static const Map<PremiumFeature, IconData> _featureIcons = {
    PremiumFeature.largeFileUpload: Icons.cloud_upload_outlined,
    PremiumFeature.extendedBackupStorage: Icons.backup_outlined,
    PremiumFeature.customThemes: Icons.palette_outlined,
    PremiumFeature.prioritySupport: Icons.support_agent,
    PremiumFeature.noAds: Icons.block_outlined,
    PremiumFeature.extendedStoryDuration: Icons.timer_outlined,
    PremiumFeature.advancedPrivacy: Icons.visibility_off_outlined,
    PremiumFeature.scheduledMessages: Icons.schedule_send_outlined,
    PremiumFeature.messageTranslation: Icons.translate_outlined,
    PremiumFeature.exclusiveReactions: Icons.emoji_emotions_outlined,
  };

  /// Quick check: returns true if user has access, false + shows paywall if not.
  ///
  /// Use this as a guard clause:
  /// ```dart
  /// if (!PremiumGate.check(PremiumFeature.scheduledMessages)) return;
  /// ```
  static bool check(PremiumFeature feature) {
    final premium = PremiumService.instance;
    if (premium.hasFeature(feature)) return true;

    // Show the RevenueCat paywall
    premium.presentPaywall();
    return false;
  }

  /// Quick check with a custom dialog instead of RevenueCat paywall.
  static bool checkWithDialog(
    BuildContext context,
    PremiumFeature feature,
  ) {
    final premium = PremiumService.instance;
    if (premium.hasFeature(feature)) return true;

    showFeatureGateDialog(context: context, feature: feature);
    return false;
  }

  /// Show a branded dialog explaining the locked feature and offering upgrade.
  static Future<bool> showFeatureGateDialog({
    required BuildContext context,
    required PremiumFeature feature,
    String? title,
    String? description,
  }) async {
    final featureTitle = title ?? _featureLabels[feature] ?? 'Premium Feature';
    final featureDescription = description ??
        _featureDescriptions[feature] ??
        'Upgrade to unlock this feature.';
    final featureIcon = _featureIcons[feature] ?? Icons.star_outlined;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PremiumGateSheet(
        title: featureTitle,
        description: featureDescription,
        icon: featureIcon,
      ),
    );

    return result ?? false;
  }

  /// Show file size limit dialog with current and premium limits.
  static Future<bool> showFileSizeLimitDialog({
    required BuildContext context,
    required int fileSizeMB,
    required int currentLimitMB,
    required int premiumLimitMB,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FileSizeLimitSheet(
        fileSizeMB: fileSizeMB,
        currentLimitMB: currentLimitMB,
        premiumLimitMB: premiumLimitMB,
      ),
    );

    return result ?? false;
  }
}

/// Branded bottom sheet for premium feature gating.
class _PremiumGateSheet extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _PremiumGateSheet({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Pro badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ColorsManager.primary, Color(0xFF1B7A3A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'CRYPTED PRO',
                  style: StylesManager.bold(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feature icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 32),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: StylesManager.bold(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: StylesManager.regular(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                await PremiumService.instance.presentPaywall();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Upgrade to Pro',
                style: StylesManager.semiBold(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not Now',
              style: StylesManager.regular(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Specific bottom sheet for file size limit gating.
class _FileSizeLimitSheet extends StatelessWidget {
  final int fileSizeMB;
  final int currentLimitMB;
  final int premiumLimitMB;

  const _FileSizeLimitSheet({
    required this.fileSizeMB,
    required this.currentLimitMB,
    required this.premiumLimitMB,
  });

  String _formatSize(int mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(0)}GB';
    return '${mb}MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorsManager.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: Colors.red, size: 32),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'File Too Large',
            style: StylesManager.bold(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Size comparison
          Text(
            'Your file is ${_formatSize(fileSizeMB)} but your current plan allows up to ${_formatSize(currentLimitMB)}.',
            style: StylesManager.regular(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Premium comparison row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Current',
                        style: StylesManager.regular(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSize(currentLimitMB),
                        style: StylesManager.bold(
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward,
                    color: ColorsManager.primary, size: 20),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: ColorsManager.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Pro',
                            style: StylesManager.regular(
                              fontSize: 12,
                              color: ColorsManager.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSize(premiumLimitMB),
                        style: StylesManager.bold(
                          fontSize: 18,
                          color: ColorsManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                await PremiumService.instance.presentPaywall();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Upgrade to Pro',
                style: StylesManager.semiBold(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not Now',
              style: StylesManager.regular(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:crypted_app/core/constant.dart';
import 'package:crypted_app/app/data/data_source/user_services.dart';

/// Subscription tiers available in Crypted.
enum PremiumTier {
  free,
  basic,
  premium;

  static PremiumTier fromString(String? value) {
    switch (value) {
      case 'basic':
        return PremiumTier.basic;
      case 'premium':
        return PremiumTier.premium;
      default:
        return PremiumTier.free;
    }
  }
}

/// Features that can be gated behind premium tiers.
enum PremiumFeature {
  /// Max file upload size (all tiers: 4GB)
  largeFileUpload,

  /// Extended backup storage (all tiers: 50GB)
  extendedBackupStorage,

  /// Custom chat themes and wallpapers
  customThemes,

  /// Priority customer support
  prioritySupport,

  /// No ads
  noAds,

  /// Extended story duration (all tiers: 60s)
  extendedStoryDuration,

  /// Advanced privacy: hide read receipts per-chat
  advancedPrivacy,

  /// Scheduled messages
  scheduledMessages,

  /// Message translation
  messageTranslation,

  /// Exclusive emoji/reactions
  exclusiveReactions,
}

/// Centralized premium entitlement service powered by RevenueCat.
///
/// Manages subscription state, feature gating, and tier-based limits.
/// Uses RevenueCat SDK for purchase management, entitlement checking,
/// paywall presentation, and Customer Center.
class PremiumService extends GetxService {
  static PremiumService get instance => Get.find<PremiumService>();

  // Reactive state
  final Rx<PremiumTier> currentTier = PremiumTier.free.obs;
  final Rxn<DateTime> expiresAt = Rxn<DateTime>();
  final RxBool isLoading = false.obs;
  final Rxn<CustomerInfo> customerInfo = Rxn<CustomerInfo>();

  // Feature entitlements per tier
  // NOTE: All features are now FREE to attract users and build community.
  // Every tier gets full access to all features.
  static const Map<PremiumTier, Set<PremiumFeature>> _tierEntitlements = {
    PremiumTier.free: {
      // All features are free — build community first
      PremiumFeature.largeFileUpload,
      PremiumFeature.extendedBackupStorage,
      PremiumFeature.customThemes,
      PremiumFeature.prioritySupport,
      PremiumFeature.noAds,
      PremiumFeature.extendedStoryDuration,
      PremiumFeature.advancedPrivacy,
      PremiumFeature.scheduledMessages,
      PremiumFeature.messageTranslation,
      PremiumFeature.exclusiveReactions,
    },
    PremiumTier.basic: {
      PremiumFeature.largeFileUpload,
      PremiumFeature.extendedBackupStorage,
      PremiumFeature.customThemes,
      PremiumFeature.prioritySupport,
      PremiumFeature.noAds,
      PremiumFeature.extendedStoryDuration,
      PremiumFeature.advancedPrivacy,
      PremiumFeature.scheduledMessages,
      PremiumFeature.messageTranslation,
      PremiumFeature.exclusiveReactions,
    },
    PremiumTier.premium: {
      // Premium gets everything
      PremiumFeature.largeFileUpload,
      PremiumFeature.extendedBackupStorage,
      PremiumFeature.customThemes,
      PremiumFeature.prioritySupport,
      PremiumFeature.noAds,
      PremiumFeature.extendedStoryDuration,
      PremiumFeature.advancedPrivacy,
      PremiumFeature.scheduledMessages,
      PremiumFeature.messageTranslation,
      PremiumFeature.exclusiveReactions,
    },
  };

  // Tier-based limits — all tiers get max limits (everything is free)
  static const Map<PremiumTier, int> maxFileUploadMB = {
    PremiumTier.free: 4096, // 4GB — free for everyone
    PremiumTier.basic: 4096, // 4GB
    PremiumTier.premium: 4096, // 4GB
  };

  static const Map<PremiumTier, int> maxBackupStorageMB = {
    PremiumTier.free: 51200, // 50GB — free for everyone
    PremiumTier.basic: 51200, // 50GB
    PremiumTier.premium: 51200, // 50GB
  };

  static const Map<PremiumTier, int> maxStoryDurationSeconds = {
    PremiumTier.free: 60, // 60s — free for everyone
    PremiumTier.basic: 60,
    PremiumTier.premium: 60,
  };

  /// Whether the user has an active paid subscription.
  bool get isPremium => currentTier.value != PremiumTier.free;

  /// Effective tier — directly reflects RevenueCat entitlement state.
  PremiumTier get effectiveTier => currentTier.value;

  /// Check if the user has access to a specific feature.
  bool hasFeature(PremiumFeature feature) {
    final tier = effectiveTier;
    return _tierEntitlements[tier]?.contains(feature) ?? false;
  }

  /// Get the file upload limit for the current tier (in MB).
  int get fileUploadLimitMB => maxFileUploadMB[effectiveTier] ?? 100;

  /// Get the backup storage limit for the current tier (in MB).
  int get backupStorageLimitMB => maxBackupStorageMB[effectiveTier] ?? 1024;

  /// Get the story duration limit for the current tier (in seconds).
  int get storyDurationLimitSeconds =>
      maxStoryDurationSeconds[effectiveTier] ?? 30;

  // ── RevenueCat Initialization ─────────────────────────────

  /// Configure RevenueCat SDK. Call once at app startup.
  Future<void> configureRevenueCat() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final configuration = PurchasesConfiguration(
        AppConstants.revenueCatApiKey,
      );

      await Purchases.configure(configuration);

      // Listen for customer info updates (e.g. subscription renewal/expiry)
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      log('[PremiumService] RevenueCat configured successfully');
    } catch (e) {
      log('[PremiumService] Error configuring RevenueCat: $e');
    }
  }

  /// Log in the current user to RevenueCat (call after Firebase auth).
  Future<void> loginUser() async {
    final userId = UserService.currentUserValue?.uid;
    if (userId == null) return;

    try {
      final result = await Purchases.logIn(userId);
      _updateFromCustomerInfo(result.customerInfo);
      log('[PremiumService] RevenueCat user logged in: $userId');
    } catch (e) {
      log('[PremiumService] Error logging in to RevenueCat: $e');
    }
  }

  // ── Subscription Loading ──────────────────────────────────

  /// Load subscription state from RevenueCat.
  Future<void> loadSubscription() async {
    isLoading.value = true;
    try {
      final info = await Purchases.getCustomerInfo();
      _updateFromCustomerInfo(info);
    } on PlatformException catch (e) {
      log('[PremiumService] Error loading subscription: ${e.message}');
      _resetToFree();
    } finally {
      isLoading.value = false;
    }
  }

  /// Called automatically when RevenueCat detects subscription changes.
  void _onCustomerInfoUpdated(CustomerInfo info) {
    log('[PremiumService] Customer info updated');
    _updateFromCustomerInfo(info);
  }

  /// Map RevenueCat entitlements to PremiumTier.
  void _updateFromCustomerInfo(CustomerInfo info) {
    customerInfo.value = info;

    final entitlement = info.entitlements.active[AppConstants.entitlementId];

    if (entitlement != null && entitlement.isActive) {
      currentTier.value = PremiumTier.premium;
      expiresAt.value = entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null; // null expiry = lifetime
    } else {
      _resetToFree();
    }

    log('[PremiumService] Tier: ${currentTier.value.name}, '
        'expires: ${expiresAt.value}, isPremium: $isPremium');
  }

  /// Reset subscription to free tier.
  void _resetToFree() {
    currentTier.value = PremiumTier.free;
    expiresAt.value = null;
  }

  // ── Paywall Presentation ──────────────────────────────────

  /// Present the RevenueCat paywall.
  ///
  /// Returns the result of the paywall interaction.
  Future<PaywallResult> presentPaywall() async {
    try {
      final result = await RevenueCatUI.presentPaywall();
      // Refresh subscription state after paywall closes
      await loadSubscription();
      return result;
    } catch (e) {
      log('[PremiumService] Error presenting paywall: $e');
      return PaywallResult.error;
    }
  }

  /// Present paywall only if user doesn't have the "Crypted Pro" entitlement.
  Future<PaywallResult> presentPaywallIfNeeded() async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        AppConstants.entitlementId,
      );
      await loadSubscription();
      return result;
    } catch (e) {
      log('[PremiumService] Error presenting paywall: $e');
      return PaywallResult.error;
    }
  }

  // ── Customer Center ───────────────────────────────────────

  /// Present RevenueCat Customer Center for subscription management.
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      log('[PremiumService] Error presenting customer center: $e');
    }
  }

  // ── Restore Purchases ─────────────────────────────────────

  /// Restore previously made purchases.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updateFromCustomerInfo(info);
      return isPremium;
    } on PlatformException catch (e) {
      log('[PremiumService] Error restoring purchases: ${e.message}');
      return false;
    }
  }

  // ── Offerings ─────────────────────────────────────────────

  /// Get current offerings from RevenueCat.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      log('[PremiumService] Error fetching offerings: ${e.message}');
      return null;
    }
  }

  // ── Logout ────────────────────────────────────────────────

  /// Clear subscription state and log out from RevenueCat.
  Future<void> onLogout() async {
    _resetToFree();
    customerInfo.value = null;
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      }
    } catch (e) {
      log('[PremiumService] Error logging out from RevenueCat: $e');
    }
  }

  @override
  void onClose() {
    _resetToFree();
    super.onClose();
  }
}

import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom bottom sheet base widget with beautiful animations
class CustomBottomSheet {
  /// Show confirmation bottom sheet
  static Future<bool?> showConfirmation({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
  }) {
    return Get.bottomSheet<bool>(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        padding: const EdgeInsets.all(Paddings.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Sizes.size24),

            // Icon
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? ColorsManager.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor ?? ColorsManager.primary,
                ),
              ),

            SizedBox(height: Sizes.size20),

            // Title
            Text(
              title,
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size12),

            // Message
            Text(
              message,
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      cancelText ?? Constants.kCancel.tr,
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Sizes.size12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm?.call();
                      Get.back(result: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? ColorsManager.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText ?? 'Confirm',
                      style: StylesManager.semiBold(
                        fontSize: FontSize.medium,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizes.size16),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Show info bottom sheet
  static Future<void> showInfo({
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
    Color? iconColor,
  }) {
    return Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        padding: const EdgeInsets.all(Paddings.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Sizes.size24),

            // Icon
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? ColorsManager.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor ?? ColorsManager.primary,
                ),
              ),

            SizedBox(height: Sizes.size20),

            // Title
            Text(
              title,
              style: StylesManager.bold(
                fontSize: FontSize.xLarge,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size12),

            // Message
            Text(
              message,
              style: StylesManager.regular(
                fontSize: FontSize.medium,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Sizes.size32),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText ?? Constants.kOK.tr,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: Sizes.size16),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Show options bottom sheet (list of choices)
  static Future<T?> showOptions<T>({
    required String title,
    required List<BottomSheetOption<T>> options,
    String? subtitle,
  }) {
    return Get.bottomSheet<T>(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: Sizes.size16),

                  // Title
                  Text(
                    title,
                    style: StylesManager.bold(
                      fontSize: FontSize.large,
                      color: Colors.black87,
                    ),
                  ),

                  if (subtitle != null) ...[
                    SizedBox(height: Sizes.size8),
                    Text(
                      subtitle,
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Options
            Divider(height: 1),
            ...options.map((option) => _buildOptionTile(option)),
            SizedBox(height: Sizes.size8),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  static Widget _buildOptionTile<T>(BottomSheetOption<T> option) {
    return InkWell(
      onTap: () => Get.back(result: option.value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Paddings.large,
          vertical: Paddings.normal,
        ),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (option.iconColor ?? ColorsManager.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  size: 24,
                  color: option.iconColor ?? ColorsManager.primary,
                ),
              ),
              SizedBox(width: Sizes.size12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: StylesManager.medium(
                      fontSize: FontSize.medium,
                      color: option.textColor ?? Colors.black87,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    SizedBox(height: Sizes.size4),
                    Text(
                      option.subtitle!,
                      style: StylesManager.regular(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (option.trailing != null) option.trailing!,
          ],
        ),
      ),
    );
  }

  /// Show loading bottom sheet
  static void showLoading({String? message}) {
    Get.bottomSheet(
      WillPopScope(
        onWillPop: () async => false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Radiuss.xLarge),
            ),
          ),
          padding: const EdgeInsets.all(Paddings.xXLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
              ),
              SizedBox(height: Sizes.size20),
              Text(
                message ?? 'Loading...',
                style: StylesManager.medium(
                  fontSize: FontSize.medium,
                  color: ColorsManager.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
    );
  }
}

/// Bottom sheet option model
class BottomSheetOption<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final T value;
  final Widget? trailing;

  BottomSheetOption({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.textColor,
    required this.value,
    this.trailing,
  });
}

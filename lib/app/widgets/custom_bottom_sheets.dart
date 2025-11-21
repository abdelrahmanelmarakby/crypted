import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom Sheet Action Item Model
class BottomSheetAction {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;
  final bool isDestructive;

  BottomSheetAction({
    required this.title,
    this.icon,
    this.iconColor,
    this.textColor,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Custom Bottom Sheets - Reusable bottom sheet widgets
class CustomBottomSheets {
  /// Show confirmation bottom sheet with custom message
  static Future<bool?> showConfirmation({
    required String title,
    required String message,
    String? subtitle,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? titleColor,
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) async {
    return await Get.bottomSheet<bool>(
      Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(Paddings.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorsManager.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: Paddings.large),

            // Icon (optional)
            if (icon != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (iconColor ?? (isDanger ? ColorsManager.red : ColorsManager.primary))
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? (isDanger ? ColorsManager.red : ColorsManager.primary),
                  size: 30,
                ),
              ),
            if (icon != null) SizedBox(height: Paddings.medium),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.large,
                fontWeight: FontWeights.bold,
                color: titleColor ?? (isDanger ? ColorsManager.red : ColorsManager.black),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Paddings.small),

            // Subtitle (optional)
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: FontSize.small,
                  fontWeight: FontWeights.bold,
                  color: isDanger ? ColorsManager.red : ColorsManager.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Paddings.small),
            ],

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Paddings.xLarge),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: Paddings.medium),
                      side: BorderSide(color: ColorsManager.lightGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey,
                        fontWeight: FontWeights.medium,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Paddings.medium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: Paddings.medium),
                      backgroundColor: confirmColor ??
                          (isDanger ? ColorsManager.red : ColorsManager.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: FontSize.medium,
                        color: ColorsManager.white,
                        fontWeight: FontWeights.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
    );
  }

  /// Show action sheet with multiple options
  static Future<void> showActionSheet({
    required String title,
    String? subtitle,
    required List<BottomSheetAction> actions,
    bool showCancelButton = true,
  }) async {
    await Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.only(top: Paddings.medium),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsManager.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: Paddings.medium),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.large),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FontSize.large,
                      fontWeight: FontWeights.bold,
                      color: ColorsManager.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: Paddings.xSmall),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: Paddings.medium),

            Divider(height: 1, color: ColorsManager.lightGrey),

            // Actions
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: ColorsManager.lightGrey.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return InkWell(
                  onTap: () {
                    Get.back();
                    action.onTap();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Paddings.large,
                      vertical: Paddings.medium,
                    ),
                    child: Row(
                      children: [
                        if (action.icon != null) ...[
                          Icon(
                            action.icon,
                            color: action.iconColor ??
                                (action.isDestructive
                                    ? ColorsManager.red
                                    : ColorsManager.primary),
                            size: 24,
                          ),
                          SizedBox(width: Paddings.medium),
                        ],
                        Expanded(
                          child: Text(
                            action.title,
                            style: TextStyle(
                              fontSize: FontSize.medium,
                              color: action.textColor ??
                                  (action.isDestructive
                                      ? ColorsManager.red
                                      : ColorsManager.black),
                              fontWeight: FontWeights.medium,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: ColorsManager.lightGrey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (showCancelButton) ...[
              Divider(height: 1, color: ColorsManager.lightGrey),
              InkWell(
                onTap: () => Get.back(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Paddings.large,
                    vertical: Paddings.medium,
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: FontSize.medium,
                        color: ColorsManager.grey,
                        fontWeight: FontWeights.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: Paddings.medium),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
    );
  }

  /// Show selection bottom sheet (for choosing between options)
  static Future<T?> showSelection<T>({
    required String title,
    String? subtitle,
    required List<SelectionOption<T>> options,
  }) async {
    return await Get.bottomSheet<T>(
      Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.only(top: Paddings.medium),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorsManager.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: Paddings.medium),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Paddings.large),
              child: Column(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FontSize.large,
                      fontWeight: FontWeights.bold,
                      color: ColorsManager.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: Paddings.xSmall),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSize.small,
                        color: ColorsManager.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: Paddings.medium),

            Divider(height: 1, color: ColorsManager.lightGrey),

            // Options
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: ColorsManager.lightGrey.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                return InkWell(
                  onTap: () => Get.back(result: option.value),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Paddings.large,
                      vertical: Paddings.large,
                    ),
                    child: Row(
                      children: [
                        if (option.icon != null) ...[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (option.iconColor ?? ColorsManager.primary)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option.icon,
                              color: option.iconColor ?? ColorsManager.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: Paddings.medium),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: TextStyle(
                                  fontSize: FontSize.medium,
                                  fontWeight: FontWeights.medium,
                                  color: ColorsManager.black,
                                ),
                              ),
                              if (option.subtitle != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  option.subtitle!,
                                  style: TextStyle(
                                    fontSize: FontSize.small,
                                    color: ColorsManager.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: Paddings.medium),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
    );
  }

  /// Show loading bottom sheet
  static void showLoading({
    required String message,
  }) {
    Get.bottomSheet(
      WillPopScope(
        onWillPop: () async => false,
        child: Container(
          decoration: BoxDecoration(
            color: ColorsManager.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(Paddings.xLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
              ),
              SizedBox(height: Paddings.medium),
              Text(
                message,
                style: TextStyle(
                  fontSize: FontSize.medium,
                  color: ColorsManager.black,
                  fontWeight: FontWeights.medium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  /// Close loading bottom sheet
  static void closeLoading() {
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }
}

/// Selection Option Model
class SelectionOption<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final T value;

  SelectionOption({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
  });
}

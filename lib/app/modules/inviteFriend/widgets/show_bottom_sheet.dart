import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void showMyBottomSheet(BuildContext context) {
  final String appLink = 'https://crypted.app/download'; // رابط التطبيق
  final String shareText =
      'Join me on Crypted! Download the app now: $appLink'; // نص المشاركة

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Radiuss.xXLarge40),
      ),
    ),
    isScrollControlled: true, // جعل الـ bottom sheet قابل للتمرير
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radiuss.xXLarge40),
          ),
        ),
        width: double.infinity,
        padding: EdgeInsets.all(Paddings.xLarge),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          // جعل المحتوى قابل للتمرير
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // جعل الـ Column يأخذ أقل مساحة ممكنة
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  Expanded(child: SizedBox()),
                  Text(
                    Constants.ksharelink.tr,
                    style: StylesManager.regular(fontSize: FontSize.xLarge),
                  ),
                  Expanded(child: SizedBox()),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: SvgPicture.asset('assets/icons/close-circle.svg'),
                  ),
                ],
              ),
              SizedBox(height: Sizes.size20),
              Text(
                Constants.kcopylink.tr,
                style: StylesManager.medium(fontSize: FontSize.small),
              ),
              SizedBox(height: Sizes.size20),
              GestureDetector(
                onTap: () {
                  // نسخ الرابط إلى الحافظة
                  Clipboard.setData(ClipboardData(text: appLink));
                  Get.snackbar(
                    'Success',
                    'Link copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: ColorsManager.primary,
                    colorText: ColorsManager.white,
                    duration: Duration(seconds: 2),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: ColorsManager.navbarColor,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appLink,
                          style: StylesManager.medium(
                            fontSize: FontSize.xSmall,
                            color: ColorsManager.lightGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SvgPicture.asset('assets/icons/copy.svg'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Sizes.size20),
              Text(
                'Share via',
                style: StylesManager.medium(fontSize: FontSize.small),
              ),
              SizedBox(height: Sizes.size20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  build_media(
                    image: 'assets/icons/Group 597.svg',
                    text: Constants.klinkedIn.tr,
                    onTap: () => _shareToLinkedIn(shareText),
                  ),
                  build_media(
                    image: 'assets/icons/Group 596.svg',
                    text: Constants.kfacebook.tr,
                    onTap: () => _shareToFacebook(shareText),
                  ),
                  build_media(
                    image: 'assets/icons/Group 595.svg',
                    text: Constants.kwhatsApp.tr,
                    onTap: () => _shareToWhatsApp(shareText),
                  ),
                  build_media(
                    image: 'assets/icons/Telegram.svg',
                    text: Constants.kTelegram.tr,
                    onTap: () => _shareToTelegram(shareText),
                  ),
                ],
              ),
              SizedBox(height: Sizes.size20),
              // زر مشاركة عامة
              GestureDetector(
                onTap: () => _shareGeneral(shareText),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share,
                        color: ColorsManager.white,
                        size: Sizes.size20,
                      ),
                      SizedBox(width: Sizes.size8),
                      Text(
                        'Share via other apps',
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: ColorsManager.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Sizes.size20),
            ],
          ),
        ),
      );
    },
  );
}

Widget build_media(
    {required String image,
    required String text,
    required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          height: Sizes.size70,
          width: Sizes.size70,
          padding: const EdgeInsets.all(Paddings.normal),
          decoration: BoxDecoration(
            color: ColorsManager.navbarColor,
            borderRadius: BorderRadius.circular(Radiuss.normal),
          ),
          child: SvgPicture.asset(image),
        ),
        SizedBox(height: Sizes.size10),
        Text(
          text,
          style: StylesManager.medium(
            fontSize: FontSize.small,
            color: ColorsManager.grey,
          ),
        ),
      ],
    ),
  );
}

// دوال المشاركة على وسائل التواصل الاجتماعي
void _shareToLinkedIn(String text) async {
  final url = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent('https://crypted.app/download')}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar('Error', 'Could not open LinkedIn');
  }
}

void _shareToFacebook(String text) async {
  final url = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://crypted.app/download')}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar('Error', 'Could not open Facebook');
  }
}

void _shareToWhatsApp(String text) async {
  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar('Error', 'Could not open WhatsApp');
  }
}

void _shareToTelegram(String text) async {
  final url = Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent('https://crypted.app/download')}&text=${Uri.encodeComponent('Join me on Crypted!')}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar('Error', 'Could not open Telegram');
  }
}

void _shareGeneral(String text) async {
  try {
    // استخدام share_plus للمشاركة العامة
    final shareText =
        'Join me on Crypted! Download the app now: https://crypted.app/download';

    await Share.share(
      shareText,
      subject: 'Join me on Crypted!',
    );

    Get.snackbar(
      'Success',
      'Share menu opened',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorsManager.primary,
      colorText: ColorsManager.white,
    );
  } catch (e) {
    print('Error sharing: $e');
    // في حالة الفشل، انسخ الرابط إلى الحافظة
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Info',
      'Link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ColorsManager.primary,
      colorText: ColorsManager.white,
    );
  }
}

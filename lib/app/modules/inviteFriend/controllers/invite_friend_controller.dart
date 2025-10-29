import 'package:crypted_app/app/data/models/item_out_side_chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

class InviteFriendController extends GetxController {
  // Search functionality
  var searchQuery = ''.obs;
  var isSearching = false.obs;

  // TextEditingController for search field
  late TextEditingController searchController;

  // Contacts list
  RxList<ItemOutSideChatModel> allContacts = <ItemOutSideChatModel>[].obs;
  RxList<ItemOutSideChatModel> filteredContacts = <ItemOutSideChatModel>[].obs;

  // Loading state
  RxBool isLoadingContacts = false.obs;
  RxBool hasPermission = false.obs;

  // Initialize contacts data
  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    _requestPermissionAndLoadContacts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // طلب الإذن وتحميل جهات الاتصال
  Future<void> _requestPermissionAndLoadContacts() async {
    try {
      isLoadingContacts.value = true;

      // طلب إذن الوصول لجهات الاتصال
      final permission = await Permission.contacts.request();

      if (permission.isGranted) {
        hasPermission.value = true;
        await _loadContacts();
      } else {
        hasPermission.value = false;
        Get.snackbar(
          'Permission Required',
          'Please grant contacts permission to invite friends',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error requesting permission: $e');
      hasPermission.value = false;
    } finally {
      isLoadingContacts.value = false;
    }
  }

  // تحميل جهات الاتصال الحقيقية
  Future<void> _loadContacts() async {
    try {
      print('📱 Loading real contacts...');

      // التحقق من أن flutter_contacts متاح
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        print('❌ Contacts permission denied');
        hasPermission.value = false;
        return;
      }

      // جلب جميع جهات الاتصال
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      print('📱 Found ${contacts.length} contacts');

      // تحويل جهات الاتصال إلى ItemOutSideChatModel
      final contactModels = contacts
          .map((contact) {
            String name = contact.displayName;
            String phoneNumber = '';

            // الحصول على رقم الهاتف الأول
            if (contact.phones.isNotEmpty) {
              phoneNumber = contact.phones.first.number;
            }

            // تجاهل جهات الاتصال بدون أرقام هواتف
            if (phoneNumber.isEmpty) {
              return null;
            }

            return ItemOutSideChatModel(
              activeNow: false,
              unread: false,
              numberOfMessages: '0',
              timeRead: '',
              timeUnread: '',
              imageUser: 'assets/images/Profile Image111.png', // صورة افتراضية
              message: '',
              nameUser: name,
              phoneNumber: phoneNumber,
            );
          })
          .where((contact) => contact != null)
          .cast<ItemOutSideChatModel>()
          .toList();

      // ترتيب جهات الاتصال حسب الاسم
      contactModels.sort((a, b) => a.nameUser.compareTo(b.nameUser));

      allContacts.value = contactModels;
      filteredContacts.value = contactModels;

      print('📱 Loaded ${contactModels.length} valid contacts');
    } catch (e) {
      print('❌ Error loading contacts: $e');
      Get.snackbar(
        'Error',
        'Failed to load contacts: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // إعادة تحميل جهات الاتصال
  Future<void> refreshContacts() async {
    await _requestPermissionAndLoadContacts();
  }

  // إرسال دعوة لجهة اتصال
  Future<void> inviteContact(ItemOutSideChatModel contact) async {
    try {
      final message =
          'Join me on Crypted! Download the app now: https://crypted.app/download';

      // تنظيف رقم الهاتف وإضافة رمز البلد إذا لم يكن موجود
      String phoneNumber = _formatPhoneNumber(contact.phoneNumber);

      // عرض خيارات المشاركة
      Get.bottomSheet(
        Container(
          decoration: BoxDecoration(
            color: ColorsManager.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Radiuss.xLarge)),
          ),
          padding: EdgeInsets.all(Paddings.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invite ${contact.nameUser}',
                style: StylesManager.medium(fontSize: FontSize.large),
              ),
              SizedBox(height: Sizes.size20),

              // خيار WhatsApp
              GestureDetector(
                onTap: () async {
                  Get.back();
                  await _shareViaWhatsApp(
                      phoneNumber, message, contact.nameUser);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.message,
                          color: Colors.white, size: Sizes.size20),
                      SizedBox(width: Sizes.size10),
                      Text(
                        'Share via WhatsApp',
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Sizes.size10),

              // خيار SMS
              GestureDetector(
                onTap: () async {
                  Get.back();
                  await _shareViaSMS(phoneNumber, message, contact.nameUser);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sms, color: Colors.white, size: Sizes.size20),
                      SizedBox(width: Sizes.size10),
                      Text(
                        'Share via SMS',
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Sizes.size10),

              // خيار نسخ الرقم والرسالة
              GestureDetector(
                onTap: () {
                  Get.back();
                  Clipboard.setData(
                      ClipboardData(text: '$phoneNumber\n$message'));
                  Get.snackbar(
                    'Copied',
                    'Phone number and message copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: ColorsManager.primary,
                    colorText: Colors.white,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: ColorsManager.grey,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.copy, color: Colors.white, size: Sizes.size20),
                      SizedBox(width: Sizes.size10),
                      Text(
                        'Copy number & message',
                        style: StylesManager.medium(
                          fontSize: FontSize.small,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Sizes.size20),

              // زر إلغاء
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Paddings.normal),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(Radiuss.normal),
                  ),
                  child: Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: StylesManager.medium(
                      fontSize: FontSize.small,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error inviting contact: $e');
      Get.snackbar(
        'Error',
        'Failed to invite contact',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // تنسيق رقم الهاتف
  String _formatPhoneNumber(String phoneNumber) {
    // إزالة المسافات والرموز
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // إذا كان الرقم يبدأ بـ 0، استبدله بـ +966 (رمز السعودية)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '+966${cleanNumber.substring(1)}';
    }

    // إذا كان الرقم يبدأ بـ 966، أضف +
    if (cleanNumber.startsWith('966')) {
      cleanNumber = '+$cleanNumber';
    }

    // إذا كان الرقم يبدأ بـ 966، أضف +
    if (cleanNumber.startsWith('966')) {
      cleanNumber = '+$cleanNumber';
    }

    // إذا كان الرقم 10 أرقام، أضف +966
    if (cleanNumber.length == 10 && !cleanNumber.startsWith('+')) {
      cleanNumber = '+966$cleanNumber';
    }

    // إذا كان الرقم 9 أرقام، أضف +966
    if (cleanNumber.length == 9 && !cleanNumber.startsWith('+')) {
      cleanNumber = '+966$cleanNumber';
    }

    return cleanNumber;
  }

  // مشاركة عبر WhatsApp
  Future<void> _shareViaWhatsApp(
      String phoneNumber, String message, String contactName) async {
    try {
      final whatsappUrl = Uri.parse(
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        Get.snackbar(
          'Success',
          'Opening WhatsApp to invite $contactName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'WhatsApp not found on device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
      Get.snackbar(
        'Error',
        'Failed to open WhatsApp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // مشاركة عبر SMS
  Future<void> _shareViaSMS(
      String phoneNumber, String message, String contactName) async {
    try {
      final smsUrl =
          Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl, mode: LaunchMode.externalApplication);
        Get.snackbar(
          'Success',
          'Opening SMS app to invite $contactName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'SMS app not found on device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error sharing via SMS: $e');
      Get.snackbar(
        'Error',
        'Failed to open SMS app',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Search functionality
  void onSearchChanged(String query) {
    print('Search query: $query');
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;

    if (query.isEmpty) {
      // Show all contacts when search is empty
      filteredContacts.value = allContacts;
    } else {
      // Filter contacts based on search query
      filteredContacts.value = allContacts.where((contact) {
        final name = contact.nameUser.toLowerCase();
        final phone = contact.phoneNumber.toLowerCase();
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) || phone.contains(searchLower);
      }).toList();
    }

    print('Filtered contacts: ${filteredContacts.length}');
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    isSearching.value = false;
    filteredContacts.value = allContacts;
  }

  // Get current contacts to display
  List<ItemOutSideChatModel> get contactsToDisplay => filteredContacts;

  // Check if search is active
  bool get isSearchActive => isSearching.value;

  // Get search query
  String get currentSearchQuery => searchQuery.value;
}

import 'package:get/get.dart';

class ContactInfoController extends GetxController {
  var isLockContactInfoEnabled = false.obs;

  void toggleShowNotification(bool value) {
    isLockContactInfoEnabled.value = value;
  }
}

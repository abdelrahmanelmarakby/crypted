import 'package:get/get.dart';

class OtpController extends GetxController {
  // VerificationArgu? argu;
  bool canResend = false;
  String? otp;

  void onChangeResendAvailability(bool val) {
    canResend = val;
    update();
  }

  void onChangeOtp(String val) {
    otp = val;
    update();
  }

  // @override
  // void onInit() {
  //   argu = Get.arguments as VerificationArgu?;
  //   super.onInit();
  // }

  // Future<void> verifyPhone() async {
  //   if (argu?.type == VerificationTypes.register) {
  //     _verifyRegister();
  //   } else {
  //     _verfyForgetPassword();
  //   }
  // }

  // Future<void> resendOtp() async {
  //   showLoading();
  //   MainModel res = await AuthApis.resendOtp(
  //     ForgetPasswordParams(phone: argu?.phone ?? ""),
  //   );
  //   if (res.success == true) {
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //   } else {
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //   }
  // }

  // Future<void> _verifyRegister() async {
  //   showLoading();
  //   LoginModel res = await AuthApis.verifyOtpForRegister(
  //     VerifyOtpParams(phone: argu?.phone ?? "", otp: otp ?? ""),
  //   );
  //   if (res.success == true) {
  //     await CacheHelper.cacheToken(token: res.data?.token ?? "");
  //     await CacheHelper.cacheUserId(id: res.data?.user?.id ?? 0);
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //     //Get.offAllNamed(Routes.NAV_SCREEN);
  //   } else {
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //   }
  // }

  // Future<void> _verfyForgetPassword() async {
  //   showLoading();
  //   MainModel res = await AuthApis.verifyOtpForForgetPass(
  //     VerifyOtpParams(phone: argu?.phone ?? "", otp: otp ?? ""),
  //   );
  //   if (res.success == true) {
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //     Get.toNamed(
  //       Routes.RESET_PASSWORD,
  //       arguments: {"phone": argu?.phone ?? ''},
  //     );
  //   } else {
  //     BotToast.closeAllLoading();
  //     BotToast.showText(text: res.message ?? "");
  //   }
  // }
}

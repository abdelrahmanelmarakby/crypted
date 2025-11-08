import 'package:get/get_navigation/src/routes/get_route.dart';

import '../modules/callfriend/bindings/callfriend_binding.dart';
import '../modules/callfriend/views/callfriend_view.dart';
import '../modules/calls/bindings/calls_binding.dart';
import '../modules/calls/views/calls_view.dart';
import '../modules/calls/views/call_screen.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_screen.dart';
import '../modules/contactInfo/bindings/contact_info_binding.dart';
import '../modules/contactInfo/views/contact_info_view.dart';
import '../modules/forgetPassword/bindings/forget_password_binding.dart';
import '../modules/forgetPassword/views/forget_password_view.dart';
import '../modules/group_info/bindings/group_info_binding.dart';
import '../modules/group_info/views/group_info_view.dart';
import '../modules/help/bindings/help_binding.dart';
import '../modules/help/views/help_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/inviteFriend/bindings/invite_friend_binding.dart';
import '../modules/inviteFriend/views/invite_friend_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/navbar/bindings/navbar_binding.dart';
import '../modules/navbar/views/navbar_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/otp/bindings/otp_binding.dart';
import '../modules/otp/views/otp_view.dart';
import '../modules/privacy/bindings/privacy_binding.dart';
import '../modules/privacy/views/privacy_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/resetPassword/bindings/reset_password_binding.dart';
import '../modules/resetPassword/views/reset_password_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/stories/bindings/stories_binding.dart';
import '../modules/stories/views/stories_view.dart';
import '../modules/backup/bindings/backup_binding.dart';
import '../modules/backup/views/backup_view.dart';
import '../modules/backup/views/backup_settings_view.dart';

//import 'package:crypted_app/app/modules/templates/stories2/bindings/stories2_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.FORGET_PASSWORD,
      page: () => const ForgetPasswordView(),
      binding: ForgetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.OTP,
      page: () => const OtpView(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: _Paths.RESET_PASSWORD,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.CALLS,
      page: () => const CallsView(),
      binding: CallsBinding(),
    ),
    GetPage(
      name: _Paths.STORIES,
      page: () => const StoriesView(),
      binding: StoriesBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.NAVBAR,
      page: () =>  NavbarView(),
      binding: NavbarBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.PRIVACY,
      page: () => const PrivacyView(),
      binding: PrivacyBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: _Paths.HELP,
      page: () => const HelpView(),
      binding: HelpBinding(),
    ),
    GetPage(
      name: _Paths.INVITE_FRIEND,
      page: () => const InviteFriendView(),
      binding: InviteFriendBinding(),
    ),
    GetPage(
      name: _Paths.CONTACT_INFO,
      page: () => const ContactInfoView(),
      binding: ContactInfoBinding(),
    ),
    GetPage(
      name: _Paths.CALLFRIEND,
      page: () => const CallfriendView(),
      binding: CallfriendBinding(),
    ),
    GetPage(
      name: _Paths.GROUP_INFO,
      page: () => GroupInfoView(),
      binding: GroupInfoBinding(),
    ),
    // GetPage(
    //   name: _Paths.STORIES2,
    //   page: () => const StoriesView(),
    //   binding: Stories2Binding(),
    // ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const PrivateChatScreen(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.CALL,
      page: () => const CallScreen(),
      binding: CallsBinding(),
    ),
    GetPage(
      name: _Paths.BACKUP,
      page: () => const BackupView(),
      binding: BackupBinding(),
    ),
    GetPage(
      name: _Paths.BACKUP_SETTINGS,
      page: () => const BackupSettingsView(),
      binding: BackupBinding(),
    ),
  ];
}

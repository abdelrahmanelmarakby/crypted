import 'package:crypted/app/modules/Environment/bindings/environment_binding.dart';
import 'package:crypted/app/modules/Environment/controllers/environment_controller.dart';
import 'package:crypted/app/modules/Environment/views/internet_connection_view.dart';
import 'package:get/get.dart';

import '../modules/allchats/bindings/allchats_binding.dart';
import '../modules/allchats/views/allchats_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.ALLCHATS,
      page: () => const AllchatsView(),
      binding: AllchatsBinding(),
    ),
    GetPage(
      name: _Paths.ENVIROMENT,
      page: () => InternetConnectionView(),
      binding: EnvironmentBinding(),
    ),
  ];
}

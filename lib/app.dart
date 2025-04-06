// ignore_for_file: public_member_api_docs, sort_constructors_first, depend_on_referenced_packages
import 'package:bot_toast/bot_toast.dart';
import 'package:crypted/app/routes/app_pages.dart';
import 'package:crypted/core/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crypted/l10n/messages.dart' as common_messages;
import 'package:responsive_framework/responsive_framework.dart';

import 'app/modules/Environment/controllers/environment_controller.dart';
import 'app/modules/Environment/views/internet_connection_view.dart';
import 'app/modules/others/error_screen.dart';
import 'core/services/bindings.dart';
import 'core/services/theme.dart';
import 'l10n/messages.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final botToastBuilder = BotToastInit();
    return GetBuilder<EnvironmentController>(
      builder: (controller) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return GetMaterialApp(
              navigatorObservers: [BotToastNavigatorObserver()],
              initialRoute: controller.isConnected
                  ? AppPages.INITIAL
                  : Routes.ENVIROMENT,
              onGenerateTitle: (context) => context.translate.appName,
              debugShowCheckedModeBanner: false,
              initialBinding: InitialBindings(),
              getPages: AppPages.routes,
              darkTheme: Themes.dark,
              theme: Themes.light,
              themeMode: ThemeService().theme,
              locale: Locale("ar"),
              localizationsDelegates: const [
                ...S.localizationsDelegates,
                common_messages.S.delegate,
              ],
              supportedLocales: S.supportedLocales,
              defaultTransition: Transition.fadeIn,
              builder: (context, child) {
                handelErrorScreen(context);
                child = botToastBuilder(context, child!);
                return ResponsiveBreakpoints.builder(
                  child: controller.isConnected
                      ? child
                      : const InternetConnectionView(),
                  breakpoints: [
                    const Breakpoint(start: 0, end: 450, name: MOBILE),
                    const Breakpoint(start: 451, end: 800, name: TABLET),
                    const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                    const Breakpoint(
                      start: 1921,
                      end: double.infinity,
                      name: '4K',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/header_section_widget.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/settings_section_widget.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/progress_widgets.dart';
import 'package:crypted_app/core/themes/color_manager.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColorsManager.scaffoldBg(context),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section
              const SliverToBoxAdapter(
                child: HeaderSectionWidget(),
              ),
              // Settings Section
              const SliverToBoxAdapter(
                child: SettingsSectionWidget(),
              ),
              // Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
        // Floating backup progress indicator
        floatingActionButton: Obx(() {
          if (controller.isBackupInProgress.value) {
            return const FloatingProgressButtonWidget();
          }
          return const SizedBox.shrink();
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

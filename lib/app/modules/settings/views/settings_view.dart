import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crypted_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/header_section_widget.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/simple_backup_switch_widget.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/settings_section_widget.dart';
import 'package:crypted_app/app/modules/settings/views/widgets/progress_widgets.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Container(
                  // padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HeaderSectionWidget(),
                    ],
                  ),
                ),
              ),
              // // Auto-backup switch with bottom sheet configuration
              // SliverToBoxAdapter(
              //   child: const SimpleBackupSwitchWidget(),
              // ),
              // Settings Section
              SliverToBoxAdapter(
                child: const SettingsSectionWidget(),
              ),
              // Bottom Spacing
              SliverToBoxAdapter(
                child: const SizedBox(height: 32),
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

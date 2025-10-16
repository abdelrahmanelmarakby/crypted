import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/calls/widgets/item_out_side_call.dart';
import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/calls_controller.dart';

class TabBarCallBody extends StatelessWidget {
  final CallStatus callStatus;
  const TabBarCallBody({super.key, required this.callStatus});

  CallsController get controller => Get.find<CallsController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallsController>(
      builder: (controller) => StreamBuilder<List<CallModel>>(
        stream: controller.getFilteredCalls(callStatus),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoading();
          }

          if (snapshot.hasError) {
            print('❌ TabBarCallBody Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading calls',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_end, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    Constants.kNoCallsFound.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          print('📞 TabBarCallBody: Received ${data.length} calls');
          print('📞 Call status filter: $callStatus');
          print('📞 Search query: "${controller.searchQuery.value}"');

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call_end,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    Constants.kNoCallsFound.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemBuilder: (context, index) {
              return ItemOutSideCall(callModel: data[index]);
            },
            separatorBuilder: (context, index) => Divider(
              indent: 0,
              endIndent: 0,
              color: ColorsManager.navbarColor,
              thickness: 1,
            ),
            itemCount: data.length,
          );
        },
      ),
    );
  }
}

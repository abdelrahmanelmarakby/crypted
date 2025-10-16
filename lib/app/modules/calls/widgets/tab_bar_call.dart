import 'package:crypted_app/app/data/models/call_model.dart';
import 'package:crypted_app/app/modules/calls/widgets/tab_bar_call_body.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabBarCall extends StatelessWidget {
  const TabBarCall({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // 4 tabs بدلاً من 3
      child: Scaffold(
        // extendBody: true,
        backgroundColor: Colors.white,

        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Paddings.xXLarge),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Paddings.normal,
                    ),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: ColorsManager.navbarColor,
                        borderRadius: BorderRadius.circular(Radiuss.xSmall),
                      ),
                      child: TabBar(
                        isScrollable: false,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: ColorsManager.primary,
                            width: 2,
                          ),
                          insets: EdgeInsets.symmetric(horizontal: 1),
                        ),
                        labelPadding: EdgeInsets.zero,
                        labelColor: ColorsManager.primary,
                        labelStyle: TextStyle(fontSize: FontSize.large),
                        unselectedLabelColor: Colors.black,
                        unselectedLabelStyle: TextStyle(
                          fontSize: FontSize.large,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          buildTab(Constants.kAll.tr, true),
                          buildTab(Constants.kInComing.tr, true),
                          buildTab(Constants.kUpComing.tr, true),
                          buildTab(
                              Constants.kMissedCall.tr, false), // لا يحتاج border
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                TabBarCallBody(
                    callStatus: CallStatus.uknown), // All - يعرض جميع المكالمات
                TabBarCallBody(callStatus: CallStatus.incoming),
                TabBarCallBody(callStatus: CallStatus.outgoing),
                TabBarCallBody(callStatus: CallStatus.missed), // Missed calls
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTab(String text, bool hasRightBorder) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: hasRightBorder
            ? Border(right: BorderSide(color: Colors.white, width: 1))
            : null,
      ),
      child: Tab(text: text),
    );
  }
}

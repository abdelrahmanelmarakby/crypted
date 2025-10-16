import 'package:crypted_app/app/modules/home/widgets/item_search.dart';
import 'package:crypted_app/app/widgets/custom_text_field.dart';
import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class Search extends StatelessWidget {
  Search({super.key});

  final List<Map<String, String>> searchItems = [
    {'image': 'assets/icons/Icon (7).svg', 'name': 'Photos'},
    {'image': 'assets/icons/Icon (1).svg', 'name': 'GIFs'},
    {'image': 'assets/icons/Icon (2).svg', 'name': 'Links'},
    {'image': 'assets/icons/Icon (3).svg', 'name': 'Videos'},
    {'image': 'assets/icons/Icon (4).svg', 'name': 'Documents'},
    {'image': 'assets/icons/Icon (5).svg', 'name': 'Audio'},
    {'image': 'assets/icons/Icon (6).svg', 'name': 'Polls'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.white,
      body: Column(
        children: [
          Container(
            color: ColorsManager.navbarColor,
            padding: const EdgeInsets.only(
              top: Paddings.xXLarge50,
              left: Paddings.large,
              right: Paddings.large,
              bottom: Paddings.large,
            ),
            child: Row(
              children: [
                // Search box
                Expanded(
                  child: CustomTextField(
                    borderRadius: Radiuss.large,
                    contentPadding: false,
                    height: Sizes.size34,
                    prefixIcon: Icon(Icons.search, size: FontSize.xLarge),
                    hint: Constants.kSearch.tr,
                    //  borderColor: ColorsManager.navbarColor,
                    fillColor: ColorsManager.white,
                  ),
                ),
                const SizedBox(width: Sizes.size8),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: Sizes.size10),
                    Text(
                      Constants.kCancel.tr,
                      style: StylesManager.medium(fontSize: FontSize.small),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchItems.length,
              itemBuilder: (context, index) {
                //  final item = searchItems[index];
                return ItemSearch(
                  image: searchItems[index]['image']!,
                  iconName: searchItems[index]['name']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

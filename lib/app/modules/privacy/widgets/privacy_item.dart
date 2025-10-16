import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyItem extends StatelessWidget {
  const PrivacyItem({
    super.key,
    required this.title,
    this.type,
    this.onTypeChanged,
    this.showDropdown = false,
    this.dropdownItems,
  });

  final String title;
  final String? type;
  final Function(String)? onTypeChanged;
  final bool showDropdown;
  final List<DropdownItem>? dropdownItems;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: StylesManager.regular(fontSize: FontSize.small),
          ),
        ),
        if (type != null) ...[
          Text(
            type!,
            style: StylesManager.medium(
              fontSize: FontSize.xSmall,
              color: ColorsManager.grey,
            ),
          ),
          SizedBox(width: Sizes.size4),
        ],
        if (showDropdown && onTypeChanged != null)
          _buildDropdownButton(context)
        else
          Icon(Icons.keyboard_arrow_right, color: ColorsManager.grey),
      ],
    );
  }

  Widget _buildDropdownButton(BuildContext context) {
    // إذا تم تمرير قائمة مخصصة، استخدمها
    if (dropdownItems != null && dropdownItems!.isNotEmpty) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.keyboard_arrow_down, color: ColorsManager.grey),
        onSelected: onTypeChanged,
        itemBuilder: (BuildContext context) => dropdownItems!
            .map((item) => PopupMenuItem<String>(
                  value: item.value,
                  child: Text(
                    item.label,
                    style: StylesManager.medium(fontSize: FontSize.small),
                  ),
                ))
            .toList(),
      );
    }

    // القائمة الافتراضية - تستخدم نفس قيم الـ enums
    return PopupMenuButton<String>(
      icon: Icon(Icons.keyboard_arrow_down, color: ColorsManager.grey),
      onSelected: onTypeChanged,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'Nobody',
          child: Text(
            'Nobody',
            style: StylesManager.medium(fontSize: FontSize.small),
          ),
        ),
        PopupMenuItem<String>(
          value: 'My Contacts',
          child: Text(
            'My Contacts',
            style: StylesManager.medium(fontSize: FontSize.small),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Everyone',
          child: Text(
            'Everyone',
            style: StylesManager.medium(fontSize: FontSize.small),
          ),
        ),
      ],
    );
  }
}

class DropdownItem {
  final String value;
  final String label;

  DropdownItem({required this.value, required this.label});
}

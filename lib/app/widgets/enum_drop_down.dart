import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'required_text_widget.dart';

class MainEnumDropDown<T> extends StatefulWidget {
  const MainEnumDropDown({
    super.key,
    this.label,
    required this.onChanged,
    required this.enumValues,
    required this.enumLabels,
    this.defaultValue, // New parameter for default value
    this.height = 25,
    this.width = 150,
    this.borderRadius = 10,
  });

  final String? label;
  final Function(T) onChanged;
  final double height;
  final double width;
  final double borderRadius;
  final List<T> enumValues;
  final Map<T, String> enumLabels; // Map to associate enum values with strings
  final T? defaultValue; // Default selected value

  @override
  State<MainEnumDropDown<T>> createState() => _MainEnumDropDownState<T>();
}

class _MainEnumDropDownState<T> extends State<MainEnumDropDown<T>> {
  T? value;

  @override
  void initState() {
    super.initState();
    value = widget.defaultValue; // Initialize with default value if provided
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          RequiredTextWidget(
            text: widget.label ?? "",
            isRequired: false,
          ),
        if (widget.label != null) SizedBox(height: 8.h),
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more,
                color: Colors.grey,
              ),
              value: value,
              hint: Text(
                widget.label ?? "",
                maxLines: 1,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: (val) {
                setState(() => value = val);
                widget.onChanged(val as T);
              },
              items: widget.enumValues
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(widget.enumLabels[e]!),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

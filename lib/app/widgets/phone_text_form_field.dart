import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../core/constants/const/app_constants.dart';
import '../../core/constants/theme/colors_manager.dart';
import '../../core/constants/theme/styles_manager.dart';
import '../../core/global/validator.dart';
import '../../core/services/get_storage_helper.dart';
import 'required_text_widget.dart';

class PhoneTextFormField extends StatelessWidget {
  const PhoneTextFormField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCountryChanged,
    this.initialValue = AppConstants.appPhoneKey,
    this.initialCountryCode = AppConstants.appCountryKey,
    required this.hintText,
    this.name,
    this.isRequired = false,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final void Function(PhoneNumber)? onChanged;
  final void Function(Country)? onCountryChanged;
  final String initialValue;
  final String initialCountryCode;
  final String hintText;
  final String? name;
  final bool isRequired;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => Validator.validatePhone(controller.text),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name != null)
              RequiredTextWidget(
                text: name ?? "",
                isRequired: isRequired,
              ),
            if (name != null) SizedBox(height: 8.h),
            AbsorbPointer(
              absorbing: readOnly,
              child: IgnorePointer(
                ignoring: readOnly,
                child: IntlPhoneField(
                  readOnly: readOnly,
                  disableLengthCheck: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  languageCode: CacheHelper.getLocale,
                  dropdownTextStyle: StylesManager.medium(
                    fontSize: 14,
                    color: ColorsManager.darkGrey,
                  ),
                  dropdownIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: ColorsManager.darkGrey,
                  ),
                  style: StylesManager.medium(
                    fontSize: 14,
                    color: ColorsManager.darkGrey,
                  ),
                  cursorColor: ColorsManager.darkGrey,
                  autofocus: false,
                  keyboardType: const TextInputType.numberWithOptions(),
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: hintText,
                    filled: false,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    alignLabelWithHint: true,
                    hintStyle: StylesManager.regular(
                      fontSize: 14,
                      color: ColorsManager.darkGrey,
                    ),
                    errorStyle:
                        const TextStyle(color: Colors.red, fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 12.h, horizontal: 16.w),
                    disabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide:
                          BorderSide(color: ColorsManager.error, width: 0.5),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide:
                          BorderSide(color: ColorsManager.error, width: 0.5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(
                          color: ColorsManager.primary1000, width: 0.5),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  controller: controller,
                  initialCountryCode: initialCountryCode,
                  initialValue: initialValue,
                  pickerDialogStyle: PickerDialogStyle(
                    width: context.width,
                    searchFieldInputDecoration: InputDecoration(
                      hintText: "Search",
                      hintTextDirection:
                          CacheHelper.getLocale == AppConstants.en
                              ? TextDirection.ltr
                              : TextDirection.rtl,
                      filled: false,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      alignLabelWithHint: true,
                      hintStyle: StylesManager.regular(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      errorStyle:
                          const TextStyle(color: Colors.red, fontSize: 12),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 16.w),
                      disabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                            color: ColorsManager.error, width: 0.5),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide:
                            BorderSide(color: Colors.grey, width: 0.5),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                            color: ColorsManager.error, width: 0.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                            color: ColorsManager.primary1000, width: 0.5),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide:
                            BorderSide(color: Colors.grey, width: 0.5),
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide:
                            BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                  ),
                  onChanged: (phone) {
                    field.didChange(phone.number); // Update field value
                    if (onChanged != null) onChanged!(phone);
                  },
                  onCountryChanged: onCountryChanged,
                ),
              ),
            ),
            if (field.hasError)
              Text(
                field.errorText ?? '',
                style: const TextStyle(color: ColorsManager.red),
              ),
          ],
        );
      },
    );
  }
}

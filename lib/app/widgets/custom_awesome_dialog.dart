import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypted_app/core/locale/constant.dart';

void showCustomDialog({
  required BuildContext context,
  required bool isSuccess,
  required void Function()? onPressed,
  required String errMessage,
}) {
  AwesomeDialog(
    context: context,
    dialogType: isSuccess ? DialogType.success : DialogType.error,
    animType: AnimType.bottomSlide,
    title: isSuccess ? Constants.kSuccess.tr : Constants.kError.tr,
    desc: isSuccess ? 'The operation was successful' : errMessage,

    //'An error occurred during execution',
    btnOk: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text(
        'Ok',
        style: TextStyle(
          color: ColorsManager.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ).show();
}

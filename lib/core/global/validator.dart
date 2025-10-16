class Validator {
  static String? validateUsername(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.username_empty;
    // }
    // if (value.length < 2) {
    //   return Get.context!.translate.username_short;
    // }
    // return null;
  }

  static String? validateEmail(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.email_empty;
    // }
    // final emailRegExp = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    // if (!emailRegExp.hasMatch(value)) {
    //   return Get.context!.translate.email_invalid;
    // }
    // return null;
  }

  static String? validateComplexPassword(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.password_empty;
    // }
    // if (value.length < 8) {
    //   return Get.context!.translate.password_short;
    // }
    // final passwordRegExp = RegExp(
    //   r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    // );
    // if (!passwordRegExp.hasMatch(value)) {
    //   return Get.context!.translate.password_complexity;
    // }
    // return null;
  }

  static String? validatePassword(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.password_empty;
    // }
    // if (value.length < 8) {
    //   return Get.context!.translate.password_short;
    // }
    // return null;
  }

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    confirmPassword = confirmPassword?.trim();
    return null;
    // if (confirmPassword == null || confirmPassword.isEmpty) {
    //   return Get.context!.translate.confirmPassword_empty;
    // }
    // if (password != confirmPassword) {
    //   return Get.context!.translate.confirmPassword_mismatch;
    // }
    // return null;
  }

  static String? validatePhone(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.phone_empty;
    // }

    // // Clean the phone number by removing non-digit characters
    // String cleanedValue = value.replaceAll(RegExp(r'\D'), '');

    // // Validate phone number length (arbitrary range, adjust as needed)
    // if (cleanedValue.length < 8 || cleanedValue.length > 15) {
    //   return Get.context!.translate.phone_invalid;
    // }

    // // Ensure the phone number only contains digits
    // final phoneRegExp = RegExp(r'^[0-9]+$');
    // if (!phoneRegExp.hasMatch(cleanedValue)) {
    //   return Get.context!.translate.phone_invalid;
    // }

    // return null;
  }

  static String? validateNormalPhone(String? value) {
    return null;

    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.phone_empty;
    // }
    // final phoneRegExp = RegExp(r'^[0-9]{10,15}$');
    // if (!phoneRegExp.hasMatch(value)) {
    //   return Get.context!.translate.phone_invalid;
    // }
    // return null;
  }

  static String? validateAddress(String? value) {
    return null;

    // value = value?.trim();
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.address_empty;
    // }
    // return null;
  }

  static String? validateFirstName(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.firstName_empty;
    // }
    // return null;
  }

  static String? validateLastName(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.lastName_empty;
    // }
    // return null;
  }

  static String? validateNotEmpty(String? value) {
    value = value?.trim();
    return null;
    // if (value == null || value.isEmpty) {
    //   return Get.context!.translate.notEmpty_required;
    // }
    // return null;
  }

  static String? validateOtp(String? otp) {
    if (otp == null || otp.isEmpty) {
      return 'OTP code is required';
    } else if (otp.length != 4) {
      return 'OTP code must be exactly 4 digits';
    } else if (!RegExp(r'^\d{4}$').hasMatch(otp)) {
      return 'OTP code must contain only numbers';
    }
    return null; // Valid OTP
  }
}

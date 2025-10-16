enum PasswordStrength { notValid, weak, medium, strong }

String decryptNumbersToText(int encryptedNumber) {
  String encryptedText = encryptedNumber.toString();
  StringBuffer decryptedText = StringBuffer();

  for (int i = 0; i < encryptedText.length; i += 2) {
    String digit = encryptedText.substring(
      i,
      i + 2,
    ); // Read two digits at a time
    int charCode = int.parse(digit);
    decryptedText.writeCharCode(charCode);
  }

  return decryptedText.toString();
}

String removeParentheses(String input) {
  return input.replaceAll('(', '').replaceAll(')', '');
}

extension GetStringUtils on String {
  int encryptTextToNumbers() {
    int encryptedNumber = 0;

    for (int i = 0; i < length; i++) {
      int charCode = codeUnitAt(i);
      encryptedNumber = encryptedNumber * 10 + charCode;
    }

    return encryptedNumber.abs();
  }
}

import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

import 'docavia_utills.dart';

enum PasswordStrength {
  notValid,
  weak,
  medium,
  strong,
}

extension GetStringUtils on String {
  /// Discover if the String is a valid number
  bool get isNum => DocaviaUtils.isNum(this);

  /// Discover if the String is numeric only
  bool get isNumericOnly => DocaviaUtils.isNumericOnly(this);

  String numericOnly({bool firstWordOnly = false}) =>
      DocaviaUtils.numericOnly(this, firstWordOnly: firstWordOnly);

  ///Method that that takes a[String] password and returns it's strength from 0 to 8 as 8 is the highest
  int measurePasswordStrength() {
    // Define the criteria for each strength level
    final hasLowercase = RegExp(r'[a-z]').hasMatch(this);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(this);
    final hasDigits = RegExp(r'\d').hasMatch(this);
    final hasSpecialChars = RegExp(r'[!@#\$%\^&\*]').hasMatch(this);

    int points = 0;

    if (length < 8) {
      points += 1;
    } else if (length < 12) {
      points += 3;
    } else {
      points += 4;
    }

    if (hasLowercase) {
      points += 1;
    }
    if (hasUppercase) {
      points += 1;
    }
    if (hasDigits) {
      points += 1;
    }
    if (hasSpecialChars) {
      points += 1;
    }

    return points;
  }

  /// Discover if the String is alphanumeric only
  bool get isAlphabetOnly => DocaviaUtils.isAlphabetOnly(this);

  /// Discover if the String is a boolean
  bool get isBool => DocaviaUtils.isBool(this);

  /// Discover if the String is a vector
  bool get isVectorFileName => DocaviaUtils.isVector(this);

  /// Discover if the String is a ImageFileName
  bool get isImageFileName => DocaviaUtils.isImage(this);

  /// Discover if the String is a AudioFileName
  bool get isAudioFileName => DocaviaUtils.isAudio(this);

  /// Discover if the String is a VideoFileName
  bool get isVideoFileName => DocaviaUtils.isVideo(this);

  /// Discover if the String is a TxtFileName
  bool get isTxtFileName => DocaviaUtils.isTxt(this);

  /// Discover if the String is a Document Word
  bool get isDocumentFileName => DocaviaUtils.isWord(this);

  /// Discover if the String is a Document Excel
  bool get isExcelFileName => DocaviaUtils.isExcel(this);

  /// Discover if the String is a Document Powerpoint
  bool get isPPTFileName => DocaviaUtils.isPPT(this);

  /// Discover if the String is a APK File
  bool get isAPKFileName => DocaviaUtils.isAPK(this);

  /// Discover if the String is a PDF file
  bool get isPDFFileName => DocaviaUtils.isPDF(this);

  /// Discover if the String is a HTML file
  bool get isHTMLFileName => DocaviaUtils.isHTML(this);

  /// Discover if the String is a URL file
  bool get isURL => DocaviaUtils.isURL(this);

  /// Discover if the String is a Email
  bool get isEmail => DocaviaUtils.isEmail(this);

  /// Discover if the String is a Phone Number
  bool get isPhoneNumber => DocaviaUtils.isPhoneNumber(this);

  /// Discover if the String is a DateTime
  bool get isDateTime => DocaviaUtils.isDateTime(this);

  /// Discover if the String is a MD5 Hash
  bool get isMD5 => DocaviaUtils.isMD5(this);

  /// Discover if the String is a SHA1 Hash
  bool get isSHA1 => DocaviaUtils.isSHA1(this);

  /// Discover if the String is a SHA256 Hash
  bool get isSHA256 => DocaviaUtils.isSHA256(this);

  /// Discover if the String is a bynary value
  bool get isBinary => DocaviaUtils.isBinary(this);

  /// Discover if the String is a ipv4
  bool get isIPv4 => DocaviaUtils.isIPv4(this);

  bool get isIPv6 => DocaviaUtils.isIPv6(this);

  /// Discover if the String is a Hexadecimal
  bool get isHexadecimal => DocaviaUtils.isHexadecimal(this);

  /// Discover if the String is a palindrom
  bool get isPalindrom => DocaviaUtils.isPalindrom(this);

  /// Discover if the String is a passport number
  bool get isPassport => DocaviaUtils.isPassport(this);

  /// Discover if the String is a currency
  bool get isCurrency => DocaviaUtils.isCurrency(this);

  /// Discover if the String is a CPF number
  bool get isCpf => DocaviaUtils.isCpf(this);

  /// Discover if the String is a CNPJ number
  bool get isCnpj => DocaviaUtils.isCnpj(this);

  /// Discover if the String is a case insensitive
  bool isCaseInsensitiveContains(String b) =>
      DocaviaUtils.isCaseInsensitiveContains(this, b);

  /// Discover if the String is a case sensitive and contains any value
  bool isCaseInsensitiveContainsAny(String b) =>
      DocaviaUtils.isCaseInsensitiveContainsAny(this, b);

  /// capitalize the String
  String? get capitalize => DocaviaUtils.capitalize(this);

  /// Capitalize the first letter of the String
  String? get capitalizeFirst => DocaviaUtils.capitalizeFirst(this);

  /// remove all whitespace from the String
  String get removeAllWhitespace => DocaviaUtils.removeAllWhitespace(this);

  /// converter the String
  String? get camelCase => DocaviaUtils.camelCase(this);

  /// Discover if the String is a valid URL
  String? get paramCase => DocaviaUtils.paramCase(this);

  /// add segments to the String
  String createPath([Iterable? segments]) {
    final path = startsWith('/') ? this : '/$this';
    return DocaviaUtils.createPath(path, segments);
  }

  /// capitalize only first letter in String words to upper case
  String capitalizeAllWordsFirstLetter() =>
      DocaviaUtils.capitalizeAllWordsFirstLetter(this);
}

extension StringExtension on String {
  String get capitalize =>
      isNotEmpty ? this[0].toUpperCase() + substring(1) : this;
}

extension HexString on String {
  int toHex() => int.parse(replaceAll('#', '0xff'));
}

extension DurationExtensions on Duration {
  String toHoursMinutes() {
    String twoDigitMinutes = _toTwoDigits(inMinutes.remainder(60));
    return "${_toTwoDigits(inHours)}:$twoDigitMinutes";
  }

  String toHoursMinutesSeconds() {
    String twoDigitMinutes = _toTwoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = _toTwoDigits(inSeconds.remainder(60));
    return "${_toTwoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _toTwoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}

///Get timing duration
String getTimer(DateTime from, DateTime to) {
  final duration = to.difference(from);
  String twoDigits(int n) => n.toString().padLeft(2, '');
  final hours = "${twoDigits(duration.inHours)}hr";
  final minutes = "${twoDigits(duration.inMinutes.remainder(60))}min";
  final seconds = "${twoDigits(duration.inSeconds.remainder(60))}sec";
  return [if (duration.inHours > 0) hours, minutes, seconds].join(' ');
}

//Capitalize first letter of a word
String cfl(String str) {
  if (str.isEmpty) return str;
  if (str.length == 1) return str.toUpperCase();
  return str[0].toUpperCase() + str.substring(1).toLowerCase();
}

String generateRandomUsername() {
  final random = Random();
  final suffix = random.nextInt(10000);
  const letters = 'abcdefghijklmnopqrstuvwxyz';
  final username =
      '${letters[random.nextInt(26)]}${letters[random.nextInt(26)]}$suffix';
  return username;
}

void openGmailApp() async {
  const url = "https://mail.google.com/mail/u/0/#inbox";

  // Check if the Gmail app is installed
  if (await canLaunchUrl(Uri.parse(url))) {
    // Launch the Gmail app
    await launchUrl(Uri.parse(url));
  } else {
    // Gmail app is not installed, handle the error
    throw 'Gmail app is not installed.';
  }
}

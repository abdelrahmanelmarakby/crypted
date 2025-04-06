import '../services/get_storage_helper.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateFormats {
  static String timeUntil(String date) {
    DateTime formattedDate = DateTime.tryParse(date) ?? DateTime.now();
    return timeago.format(formattedDate, allowFromNow: true, locale: "en");
  }

  /// (e.g., "Oct 11, 2022 4:27:23 PM").
  static String formatDateDayAndTime(String stringDate) =>
      DateFormat.yMMMd().add_jms().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "Tuesday, October 11, 2022").
  static String formatDateyMMMMEEEEdTime(String stringDate) =>
      DateFormat.yMMMMEEEEd().format(DateTime.parse(stringDate).toLocal());
  static String formatDatejmTime(String stringDate) =>
      DateFormat.jm().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "Wednesday, October 12").
  static String formatDateEEEEMMMdd(String stringDate) => DateFormat.EEEE()
      .add_MMMM()
      .add_d()
      .format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "October Wednesday 12").
  static String formatDateMMMMEEEEd(String stringDate) =>
      DateFormat.MMMMEEEEd().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "10/12/2022").
  static String formatDateMdyyyy(String stringDate) =>
      DateFormat.Md().add_y().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "16:27").
  static String formatDateHHmm(String stringDate) =>
      DateFormat.Hm().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "04:27:23").
  static String formatDatehhmmss(String stringDate) =>
      DateFormat.Hms().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "Oct 2022").
  static String formatDateMMMyy(String stringDate) =>
      DateFormat.MMM().add_y().format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "24/11/20 11:30 am")
  static String formatDateYearMonthDayHoursMinAmOrPm(String stringDate) =>
      DateFormat('yyyy/MM/dd hh:mm a', CacheHelper.getLocale)
          .format(DateTime.parse(stringDate).toLocal());

  ///(e.g., "11:30 am")
  static String formatDateHoursMinAmOrPm(String stringDate) =>
      DateFormat('h:mm a', CacheHelper.getLocale)
          .format(DateTime.parse(stringDate).toLocal());

  /// Formats the date and time using a custom format string.
  static String formatCustom(String stringDate, String format) =>
      DateFormat(format).format(DateTime.parse(stringDate).toLocal());
  static String messagerFormated(String stringDate) =>
      DateFormat('MMMM d').format(DateTime.parse(stringDate).toLocal());

  //  gives the full name of the day
  static String getDayName(DateTime date, String locale) =>
      DateFormat('EEEE', locale).format(date);

  //ex=> 25-7-2024
  static String formatDateDayMonthYear(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Checks if the provided string is a valid date.
  static bool isDateValid(String str) {
    try {
      DateTime.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}

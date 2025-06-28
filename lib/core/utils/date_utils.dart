import 'package:intl/intl.dart';

class AppDateUtils {
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultTimeFormat = 'HH:mm:ss';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'h:mm a';
  static const String displayDateTimeFormat = 'MMM dd, yyyy h:mm a';

  static String formatDate(DateTime date, [String? format]) {
    final formatter = DateFormat(format ?? defaultDateFormat);
    return formatter.format(date);
  }

  static String formatTime(DateTime time, [String? format]) {
    final formatter = DateFormat(format ?? defaultTimeFormat);
    return formatter.format(time);
  }

  static String formatDateTime(DateTime dateTime, [String? format]) {
    final formatter = DateFormat(format ?? defaultDateTimeFormat);
    return formatter.format(dateTime);
  }

  static String formatForDisplay(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(dateTime, displayDateFormat);
    }
  }

  static DateTime? parseDateTime(String dateTimeString, [String? format]) {
    try {
      final formatter = DateFormat(format ?? defaultDateTimeFormat);
      return formatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  static String toIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static DateTime fromIsoString(String isoString) {
    return DateTime.parse(isoString);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
}
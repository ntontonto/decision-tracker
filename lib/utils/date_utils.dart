import 'package:intl/intl.dart';

class AppDateUtils {
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference == 2) {
      return '一昨日';
    } else if (difference < 7) {
      return '$difference日前';
    } else if (difference < 14) {
      return '1週間前';
    } else if (difference < 21) {
      return '2週間前';
    } else if (difference < 31) {
      final weeks = (difference / 7).floor();
      return '$weeks週間前';
    } else {
      return DateFormat('M/d').format(date);
    }
  }
}

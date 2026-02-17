import 'package:flutter/material.dart';

abstract class Reviewable {
  String get id;
  String get title;
  String get description;
  DateTime get targetDate;
  IconData get icon;
  bool get isReviewableNow;
  dynamic get originalData;
}

extension ReviewableExtension on Reviewable {
  bool get isWithinReviewWindow {
    final now = DateTime.now();
    final scheduledDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Start: Either the scheduled time or 18:00 of that day (whichever is earlier)
    // This ensures "Now" (e.g. 10am) is included, but "Tonight" (21:00) starts appearing at 18:00
    final startOfDefaultWindow = scheduledDay.add(const Duration(hours: 18));
    final startTime = targetDate.isBefore(startOfDefaultWindow) ? targetDate : startOfDefaultWindow;
    
    // End: 18:00 of the next day
    final endTime = scheduledDay.add(const Duration(days: 1, hours: 18));
    
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}

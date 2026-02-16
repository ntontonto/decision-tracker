import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/decision_repository.dart';
import '../../data/local/database.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Don't request on init
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<bool> requestPermission() async {
    // Request permission explicitly (called after first decision save)
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // For Android, permissions are granted at install time
    return result ?? true;
  }

  Future<void> scheduleDailyNotification({
    required DateTime date,
    required TimeOfDay time,
    required DecisionRepository repository,
  }) async {
    // Get all pending decisions for this date
    final allDecisions = await repository.getPendingDecisions();
    final decisionsForDate = allDecisions.where((d) {
      final retroDate = DateTime(d.retroAt.year, d.retroAt.month, d.retroAt.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return retroDate == targetDate;
    }).toList();

    if (decisionsForDate.isEmpty) {
      // No decisions for this date, cancel any existing notification
      // Note: cancel() doesn't take parameters in this version
      await cancelAll(); // We'll cancel all and reschedule others if needed
      return;
    }

    // Sort by creation date (oldest first)
    decisionsForDate.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Generate notification content based on oldest decision
    final content = _generateNotificationContent(decisionsForDate);
    
    // Schedule notification at specified time on the date
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    // Don't schedule notifications in the past
    if (scheduledDateTime.isBefore(DateTime.now())) {
      return;
    }
    
    final scheduledTzDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final notificationId = _getNotificationId(date);

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: content['title'] as String,
      body: content['body'] as String,
      scheduledDate: scheduledTzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'retro_reminders',
          'Retro Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Map<String, String> _generateNotificationContent(List<Decision> decisions) {
    final oldest = decisions.first;
    final count = decisions.length;
    
    // Calculate time period from creation to retro
    final daysDiff = oldest.retroAt.difference(oldest.createdAt).inDays;
    final period = _getPeriodText(daysDiff);
    
    String title;
    String body;
    
    if (count == 1) {
      title = '$period決めた実践を振り返りませんか？';
      body = '「${oldest.textContent}」';
    } else {
      title = '$period決めた実践を振り返りませんか？';
      body = '「${oldest.textContent}」他${count - 1}件の振り返りがあります';
    }
    
    return {'title': title, 'body': body};
  }

  String _getPeriodText(int days) {
    if (days >= 365) {
      final years = (days / 365).floor();
      return '${years}年前に';
    } else if (days >= 30) {
      final months = (days / 30).floor();
      return '${months}ヶ月前に';
    } else if (days >= 7) {
      final weeks = (days / 7).floor();
      return '${weeks}週間前に';
    } else if (days >= 1) {
      return '${days}日前に';
    } else {
      return '今日';
    }
  }

  int _getNotificationId(DateTime date) {
    // Generate unique ID based on date (YYYYMMDD format as int)
    return int.parse('${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}');
  }

  Future<void> rescheduleAllNotifications(
    DecisionRepository repository,
    TimeOfDay time,
  ) async {
    // Get all pending decisions
    final decisions = await repository.getPendingDecisions();
    
    // Group by date
    final Map<DateTime, List<Decision>> decisionsByDate = {};
    for (final decision in decisions) {
      final date = DateTime(
        decision.retroAt.year,
        decision.retroAt.month,
        decision.retroAt.day,
      );
      decisionsByDate.putIfAbsent(date, () => []).add(decision);
    }
    
    // Schedule notification for each date
    for (final date in decisionsByDate.keys) {
      await scheduleDailyNotification(
        date: date,
        time: time,
        repository: repository,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    // Note: In this version, cancel() doesn't take ID parameter
    // We'll need to cancel all and reschedule
    await cancelAll();
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}


import 'package:flutter/material.dart';

class AppSettings {
  final TimeOfDay notificationTime;
  final bool notificationsEnabled;
  final bool hasRequestedPermission;

  const AppSettings({
    required this.notificationTime,
    required this.notificationsEnabled,
    required this.hasRequestedPermission,
  });

  // Default settings
  factory AppSettings.defaults() {
    return const AppSettings(
      notificationTime: TimeOfDay(hour: 21, minute: 0), // 21:00 (9 PM)
      notificationsEnabled: true,
      hasRequestedPermission: false,
    );
  }

  AppSettings copyWith({
    TimeOfDay? notificationTime,
    bool? notificationsEnabled,
    bool? hasRequestedPermission,
  }) {
    return AppSettings(
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasRequestedPermission: hasRequestedPermission ?? this.hasRequestedPermission,
    );
  }

  // Serialization for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'notificationHour': notificationTime.hour,
      'notificationMinute': notificationTime.minute,
      'notificationsEnabled': notificationsEnabled,
      'hasRequestedPermission': hasRequestedPermission,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationTime: TimeOfDay(
        hour: json['notificationHour'] as int? ?? 21,
        minute: json['notificationMinute'] as int? ?? 0,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      hasRequestedPermission: json['hasRequestedPermission'] as bool? ?? false,
    );
  }
}

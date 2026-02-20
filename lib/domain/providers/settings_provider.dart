import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../../core/services/notification_service.dart';
import 'app_providers.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  final Ref ref;

  SettingsNotifier(this.ref) : super(AppSettings.defaults()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson != null) {
      try {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      } catch (e) {
        debugPrint('Error loading settings: $e');
        // Keep default settings if loading fails
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(state.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  Future<void> updateNotificationTime(TimeOfDay time) async {
    state = state.copyWith(notificationTime: time);
    await _saveSettings();
    
    // Reschedule all notifications with new time
    if (state.notificationsEnabled) {
      await NotificationService().rescheduleAllNotifications(
        ref.read(decisionRepositoryProvider),
        time,
      );
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
    
    if (enabled) {
      // Reschedule all notifications
      await NotificationService().rescheduleAllNotifications(
        ref.read(decisionRepositoryProvider),
        state.notificationTime,
      );
    } else {
      // Cancel all notifications
      await NotificationService().cancelAll();
    }
  }

  Future<void> markPermissionRequested() async {
    state = state.copyWith(hasRequestedPermission: true);
    await _saveSettings();
  }

  Future<void> setOnboardingSeen(bool seen) async {
    state = state.copyWith(hasSeenOnboarding: seen);
    await _saveSettings();
  }

  Future<void> updateOnboardingStep(int step) async {
    state = state.copyWith(onboardingStep: step);
    await _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

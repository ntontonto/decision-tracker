import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/settings_provider.dart';
import '../theme/app_design.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('設定', style: AppDesign.titleStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection(
                title: '通知設定',
                children: [
                  _buildGlassCard(
                    child: SwitchListTile(
                      title: const Text(
                        '通知を有効にする',
                        style: TextStyle(color: AppDesign.textPrimary, fontSize: 16),
                      ),
                      subtitle: const Text(
                        '振り返りの時間になったら通知します',
                        style: TextStyle(color: AppDesign.textSecondary, fontSize: 13),
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
                      },
                      activeColor: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: ListTile(
                      title: const Text(
                        '通知時刻',
                        style: TextStyle(color: AppDesign.textPrimary, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${settings.notificationTime.hour.toString().padLeft(2, '0')}:${settings.notificationTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppDesign.textSecondary, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.access_time, color: AppDesign.textSecondary),
                      enabled: settings.notificationsEnabled,
                      onTap: settings.notificationsEnabled
                          ? () => _showTimePicker(context, ref, settings.notificationTime)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'アプリ情報',
                children: [
                  _buildGlassCard(
                    child: const ListTile(
                      title: Text(
                        'バージョン',
                        style: TextStyle(color: AppDesign.textPrimary, fontSize: 16),
                      ),
                      subtitle: Text(
                        'v 0.1.0',
                        style: TextStyle(color: AppDesign.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppDesign.subtitleStyle.copyWith(fontSize: 14, letterSpacing: 1.2),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.glassBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppDesign.glassBorderColor,
          width: AppDesign.glassBorderWidth,
        ),
      ),
      child: child,
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.purpleAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      await ref.read(settingsProvider.notifier).updateNotificationTime(picked);
    }
  }
}

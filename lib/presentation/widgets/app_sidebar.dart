import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_design.dart';
import '../pages/decision_list_page.dart';
import '../pages/action_goal_list_page.dart';
import '../pages/constellation_page.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap in Theme to ensure Material 3 Drawer doesn't force a background
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        // Disable surface tint and other overlays that could block transparency
        colorScheme: Theme.of(context).colorScheme.copyWith(
              surfaceTint: Colors.transparent,
              surface: Colors.transparent,
            ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppDesign.glassBlur, sigmaY: AppDesign.glassBlur),
          child: Container(
            decoration: BoxDecoration(
              color: AppDesign.glassBackgroundColor,
              border: Border(
                right: BorderSide(
                  color: AppDesign.glassBorderColor,
                  width: AppDesign.glassBorderWidth,
                ),
              ),
            ),
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Decision Tracker',
                      style: AppDesign.titleStyle,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.list, color: AppDesign.textSecondary),
                  title: const Text(
                    '過去の判断一覧 (List)',
                    style: TextStyle(color: AppDesign.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DecisionListPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppDesign.textSecondary),
                  title: const Text(
                    '行動目標 (Goals)',
                    style: TextStyle(color: AppDesign.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ActionGoalListPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: AppDesign.textSecondary),
                  title: const Text(
                    '学びの星座 (Map)',
                    style: TextStyle(color: AppDesign.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ConstellationPage()),
                    );
                  },
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'v 0.1.0',
                    style: AppDesign.subtitleStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database.dart';
import '../theme/app_design.dart';

class ActionGoalCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback? onTap;

  const ActionGoalCard({
    super.key,
    required this.declaration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = declaration.reviewAt.isBefore(DateTime.now());
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppDesign.glassBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOverdue ? Colors.orangeAccent.withValues(alpha: 0.3) : AppDesign.glassBorderColor,
          width: AppDesign.glassBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isOverdue ? Colors.orangeAccent : Colors.white38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '見直し予定: ${dateFormat.format(declaration.reviewAt)}',
                          style: TextStyle(
                            color: isOverdue ? Colors.orangeAccent : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '要振り返り',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Declaration Text
                Text(
                  declaration.declarationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Snapshot Reference (Context)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildContextRow('元ログ', declaration.originalText),
                      const SizedBox(height: 4),
                      _buildContextRow('後悔理由', declaration.reasonLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';
import '../theme/app_design.dart';

class DecisionListCard extends StatelessWidget {
  final Decision decision;
  final VoidCallback? onTap;

  const DecisionListCard({
    super.key,
    required this.decision,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final isPending = decision.status == DecisionStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppDesign.glassBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppDesign.glassBorderColor,
          width: AppDesign.glassBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date and Driver
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(decision.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          decision.driver.label,
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blueAccent,
                        ),
                      ],
                    ),
                    if (isPending)
                      _buildBadge(
                        '未レビュー',
                        Colors.orange.withValues(alpha: 0.1),
                        Colors.orangeAccent,
                      )
                    else
                      const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 12),
                // Decision Text
                Text(
                  decision.textContent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

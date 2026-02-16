import 'package:flutter/material.dart';
import '../../domain/models/reviewable.dart';
import '../theme/app_design.dart';

class ReviewProposalCard extends StatelessWidget {
  final Reviewable item;
  final VoidCallback onTap;

  const ReviewProposalCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: AppDesign.glassDecoration(
          borderRadius: 40,
          showBorder: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  item.icon,
                  size: 14,
                  color: AppDesign.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  item.title,
                  style: AppDesign.subtitleStyle,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: AppDesign.bodyStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

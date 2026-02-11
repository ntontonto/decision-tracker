import 'package:flutter/material.dart';
import '../theme/app_design.dart';

class WizardSelectionStep<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> items;
  final T? selected;
  final Function(T?) onSelect;
  final String Function(T) labelBuilder;
  final ScrollController scrollController;

  const WizardSelectionStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.selected,
    required this.onSelect,
    required this.labelBuilder,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          if (subtitle != null) ...[
            Text(subtitle!, style: AppDesign.subtitleStyle.copyWith(fontSize: 14)),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final isSelected = selected == item;
              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    onSelect(null);
                  } else {
                    onSelect(item);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: AppDesign.actionButtonDecoration(selected: isSelected),
                  child: Text(
                    labelBuilder(item),
                    style: AppDesign.actionButtonTextStyle(selected: isSelected),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 200), // Extra space to ensure scrollability
        ],
      ),
    );
  }
}

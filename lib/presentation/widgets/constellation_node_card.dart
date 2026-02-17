import 'package:flutter/material.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/data/local/database.dart';
import 'package:decision_tracker/domain/models/enums.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/providers/retro_providers.dart';

class ConstellationNodeCard extends ConsumerWidget {
  final ConstellationNode node;
  final bool isExpanded;

  const ConstellationNodeCard({
    super.key,
    required this.node,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = HSVColor.fromAHSV(1.0, node.hue, 0.7, 0.9).toColor();
    final bool isDecision = node.type == ConstellationNodeType.decision;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      clipBehavior: Clip.antiAlias, // Prevent sub-pixel overflow artifacts during animation
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: isExpanded ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allow the Column to shrink
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildHeader(color),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 16),
            if (isDecision) _buildDecisionDetails(color) else _buildDeclarationDetails(color),
            if (isExpanded) ...[
              const SizedBox(height: 24),
              _buildExtendedContent(color, ref),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Icon(Icons.keyboard_arrow_up, color: color.withValues(alpha: 0.3), size: 20),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (node.type == ConstellationNodeType.decision) {
      final decision = node.originalData as Decision;
      if (decision.status == DecisionStatus.reviewed) {
        statusText = '振り返り済 (${node.score}pt)';
        statusColor = color;
        statusIcon = Icons.check_circle_outline;
      } else if (decision.status == DecisionStatus.skipped) {
        statusText = 'スキップ';
        statusColor = Colors.white38;
        statusIcon = Icons.skip_next_outlined;
      } else {
        statusText = '未振り返り';
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.pending_outlined;
      }
    } else {
      final decl = node.originalData as Declaration;
      if (decl.completedAt != null) {
        statusText = '完了 (${node.score}pt)';
        statusColor = color;
        statusIcon = Icons.task_alt;
      } else if (decl.status == DeclarationStatus.skipped) {
        statusText = 'スキップ';
        statusColor = Colors.white38;
        statusIcon = Icons.block;
      } else {
        statusText = '進行中';
        statusColor = Colors.cyanAccent;
        statusIcon = Icons.bolt;
      }
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            node.type.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Icon(statusIcon, size: 14, color: statusColor.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(color: statusColor.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '${node.date.month}/${node.date.day}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      node.label,
      maxLines: isExpanded ? 5 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: isExpanded ? 18 : 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }

  Widget _buildDecisionDetails(Color color) {
    final decision = node.originalData as Decision;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          icon: decision.driver.icon,
          label: decision.driver.label,
          color: color,
        ),
        if (decision.gain != null)
          _buildInfoChip(
            icon: decision.gain!.icon,
            label: decision.gain!.label,
            color: Colors.greenAccent,
            isGain: true,
          ),
        if (decision.lose != null)
          _buildInfoChip(
            icon: decision.lose!.icon,
            label: decision.lose!.label,
            color: Colors.redAccent,
            isLose: true,
          ),
      ],
    );
  }

  Widget _buildDeclarationDetails(Color color) {
    final decl = node.originalData as Declaration;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          icon: Icons.lightbulb,
          label: decl.reasonLabel,
          color: color,
        ),
      ],
    );
  }

  Widget _buildExtendedContent(Color color, WidgetRef ref) {
    if (node.type == ConstellationNodeType.decision) {
      final decision = node.originalData as Decision;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (decision.note?.isNotEmpty ?? false) ...[
            _buildSectionTitle('メモ', color),
            const SizedBox(height: 8),
            Text(
              decision.note!,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
          if (decision.status == DecisionStatus.reviewed) ...[
            _buildSectionTitle('振り返り', color),
            const SizedBox(height: 12),
            if (decision.successFactor?.isNotEmpty ?? false)
              _buildDetailItem(Icons.auto_awesome, '成功要因', decision.successFactor!, Colors.amberAccent),
            if (decision.reasonKey != null)
              _buildDetailItem(Icons.error_outline, '反省点', _getReasonLabel(decision.reasonKey!, ref), Colors.orangeAccent),
            if (decision.solution?.isNotEmpty ?? false)
              _buildDetailItem(Icons.lightbulb_outline, '今後の対策', decision.solution!, Colors.cyanAccent),
            if (decision.memo?.isNotEmpty ?? false)
              _buildDetailItem(Icons.notes, '振り返りメモ', decision.memo!, Colors.white60),
          ],
        ],
      );
    } else {
      final decl = node.originalData as Declaration;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('宣言内容', color),
          const SizedBox(height: 8),
          Text(
            decl.declarationText,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('目的・背景', color),
          const SizedBox(height: 8),
          Text(
            decl.solutionText,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      );
    }
  }

  String _getReasonLabel(String key, WidgetRef ref) {
    final metadata = ref.watch(retroWizardProvider).metadata;
    if (metadata == null) return key;
    
    try {
      return metadata.reasons.firstWhere((r) => r.key == key).label;
    } catch (_) {
      return key;
    }
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: color.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String content, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isGain = false,
    bool isLose = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGain ? Icons.add : (isLose ? Icons.remove : icon),
            size: 14,
            color: color,
          ),
          if (isGain || isLose) ...[
            const SizedBox(width: 2),
            Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          ],
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/data/local/database.dart';
import 'package:decision_tracker/domain/models/enums.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/providers/retro_providers.dart';
import 'package:decision_tracker/presentation/widgets/retro_wizard_sheet.dart';
import 'package:decision_tracker/presentation/widgets/action_review_wizard_sheet.dart';

class ConstellationNodeCard extends ConsumerWidget {
  final ConstellationNode node;
  final bool isExpanded;
  final VoidCallback? onDelete;

  const ConstellationNodeCard({
    super.key,
    required this.node,
    this.isExpanded = false,
    this.onDelete,
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
            _buildHeader(context, color, ref),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 16),
            if (isDecision) _buildDecisionDetails(color) else _buildDeclarationDetails(color),
            if (isExpanded) ...[
              const SizedBox(height: 24),
              _buildExtendedContent(context, color, ref),
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

  Widget _buildHeader(BuildContext context, Color color, WidgetRef ref) {
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
        statusText = '振り返り未実施';
        statusColor = Colors.orangeAccent.withValues(alpha: 0.8);
        statusIcon = Icons.pending_outlined;
      } else {
        statusText = '振り返り未実施';
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
        statusText = '振り返り未実施';
        statusColor = Colors.orangeAccent.withValues(alpha: 0.8);
        statusIcon = Icons.pending_outlined;
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
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showDeleteConfirmation(context, ref),
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final bool? result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                contentPadding: EdgeInsets.zero,
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 32),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '削除しますか？',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            node.type == ConstellationNodeType.decision 
                              ? 'この出来事と、それに関連するすべての行動宣言が削除されます。'
                              : 'この行動宣言と、その先につながるすべての宣言が削除されます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6), 
                              fontSize: 14, 
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('キャンセル', style: TextStyle(fontSize: 15)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: Colors.redAccent.withValues(alpha: 0.4),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      '削除', 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == true && onDelete != null) {
      onDelete!();
    }
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

  Widget _buildExtendedContent(BuildContext context, Color color, WidgetRef ref) {
    if (node.type == ConstellationNodeType.decision) {
      final decision = node.originalData as Decision;
      final bool needsRetro = decision.status != DecisionStatus.reviewed;

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
          ] else if (needsRetro) ...[
            const SizedBox(height: 8),
            _buildReflectionPrompt(
              context, 
              'この出来事をふりかえりますか？', 
              color,
              () => _showRetroWizard(context, decision),
            ),
          ],
        ],
      );
    } else {
      final decl = node.originalData as Declaration;
      final bool needsReview = decl.completedAt == null;

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
          if (needsReview) ...[
            const SizedBox(height: 24),
            _buildReflectionPrompt(
              context, 
              'この宣言をふりかえりますか？', 
              color,
              () => _showActionReviewWizard(context, decl),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildReflectionPrompt(BuildContext context, String message, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 18),
                SizedBox(width: 8),
                Text('ふりかえる', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRetroWizard(BuildContext context, Decision decision) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RetroWizardSheet(decision: decision),
    );
  }

  void _showActionReviewWizard(BuildContext context, Declaration decl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActionReviewWizardSheet(declaration: decl),
    );
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


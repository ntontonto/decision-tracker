import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';
import '../theme/app_design.dart';

class RetroPage extends ConsumerWidget {
  const RetroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDecisionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('今日の振り返り')),
      body: pendingAsync.when(
        data: (decisions) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final todayItems = decisions.where((d) => 
            d.retroAt.year == today.year && 
            d.retroAt.month == today.month && 
            d.retroAt.day == today.day
          ).take(3).toList();

          final overdueItems = decisions.where((d) => 
            d.retroAt.isBefore(today)
          ).toList();

          if (todayItems.isEmpty && overdueItems.isEmpty) {
            return const Center(child: Text('今日の振り返りはありません。ゆっくり休みましょう。'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (todayItems.isNotEmpty) ...[
                Text('今日の振り返り', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...todayItems.map((d) => _buildDecisionCard(context, ref, d)),
                const SizedBox(height: 16),
              ],
              if (overdueItems.isNotEmpty) ...[
                ExpansionTile(
                  title: Text('少し前の振り返り (${overdueItems.length}件)', 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  children: overdueItems.map((d) => _buildDecisionCard(context, ref, d)).toList(),
                ),
              ],
              const SizedBox(height: 24),
              if (decisions.isNotEmpty)
                Center(
                  child: TextButton(
                    onPressed: () => _showSnoozeDialog(context, ref, decisions.map((e) => e.id).toList()),
                    child: const Text('まとめて1週間後に延期'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDecisionCard(BuildContext context, WidgetRef ref, Decision decision) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(decision.textContent),
        subtitle: Text('設定日: ${decision.retroAt.year}/${decision.retroAt.month}/${decision.retroAt.day}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _startReviewFlow(context, decision),
      ),
    );
  }

  void _startReviewFlow(BuildContext context, Decision decision) {
    // Navigate to Review flow (simplifying for MVP as a full-screen wizard)
    // For now, placeholders - in real implementation this would be ReviewWizardPage
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReviewWizardSheet(decision: decision),
    );
  }

  void _showSnoozeDialog(BuildContext context, WidgetRef ref, List<String> ids) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スヌーズ'),
        content: const Text('未解決の振り返りをすべて1週間後に延期しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(repositoryProvider).snoozeReviews(ids);
              ref.invalidate(pendingDecisionsProvider);
              ref.invalidate(allDecisionsProvider);
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text('延期する'),
          ),
        ],
      ),
    );
  }
}

class ReviewWizardSheet extends ConsumerStatefulWidget {
  final Decision decision;
  const ReviewWizardSheet({super.key, required this.decision});

  @override
  ConsumerState<ReviewWizardSheet> createState() => _ReviewWizardSheetState();
}

class _ReviewWizardSheetState extends ConsumerState<ReviewWizardSheet> {
  int _step = 0;
  ExecutionStatus? _execution;
  double _conviction = 5;
  bool? _wouldRepeat;
  AdjustmentType? _adjustment;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: AppDesign.glassBlur, sigmaY: AppDesign.glassBlur),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppDesign.glassBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppDesign.glassBorderColor, width: AppDesign.glassBorderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decision Text Content
              Text(
                widget.decision.textContent,
                style: const TextStyle(
                  color: AppDesign.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Context Info Area (Frosted Glass Style)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppDesign.glassBorderColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('動機', widget.decision.driver.label),
                    if (widget.decision.gain != null) _buildInfoRow('得たもの', widget.decision.gain!.label),
                    if (widget.decision.lose != null) _buildInfoRow('失ったもの', widget.decision.lose!.label),
                    if (widget.decision.note != null && widget.decision.note!.isNotEmpty)
                      _buildInfoRow('メモ', widget.decision.note!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              
              // Wizard Steps
              Expanded(
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: AppDesign.textPrimary, fontSize: 18),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'あとで',
                      style: TextStyle(color: AppDesign.textMuted, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isNextEnabled() ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _step == (_wouldRepeat == false ? 3 : 2) ? '完了' : '次へ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  bool _isNextEnabled() {
    if (_step == 0) return _execution != null;
    if (_step == 2) return _wouldRepeat != null;
    if (_step == 3) return _adjustment != null;
    return true;
  }

  void _next() async {
    if (_step == 2 && _wouldRepeat == true) {
      await _save();
    } else if (_step == 3) {
      await _save();
    } else {
      setState(() => _step++);
    }
  }

  Future<void> _save() async {
    await ref.read(repositoryProvider).createReview(
      logId: widget.decision.id,
      execution: _execution!,
      convictionScore: _conviction.toInt(),
      wouldRepeat: _wouldRepeat!,
      adjustment: _adjustment,
    );
    ref.invalidate(pendingDecisionsProvider);
    ref.invalidate(allDecisionsProvider);
    ref.invalidate(reviewForLogProvider(widget.decision.id));
    if (mounted) {
      Navigator.pop(context);
      if (_adjustment != null && _adjustment != AdjustmentType.hold) {
        _showNewDecisionGuide();
      }
    }
  }

  void _showNewDecisionGuide() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('新しい判断を追加しましょう'),
        action: SnackBarAction(label: '追加', onPressed: () {
          // Trigger Log Wizard with prev text
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildSelectionStep<ExecutionStatus>(
          'R1: 実行できましたか？',
          ExecutionStatus.values,
          _execution,
          (v) => setState(() => _execution = v),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('R2: 納得度は？ (0-10)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Slider(
              value: _conviction,
              min: 0,
              max: 10,
              divisions: 10,
              label: _conviction.toInt().toString(),
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) => setState(() => _conviction = v),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('R3: 今の自分なら同じ判断をする？', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildChoiceChip('Yes', _wouldRepeat == true, () {
                  setState(() => _wouldRepeat = true);
                  _next();
                }),
                const SizedBox(width: 16),
                _buildChoiceChip('No', _wouldRepeat == false, () {
                  setState(() => _wouldRepeat = false);
                  _next();
                }),
              ],
            ),
          ],
        );
      case 3:
        return _buildSelectionStep<AdjustmentType>(
          'R4: 次はどう変えますか？',
          AdjustmentType.values,
          _adjustment,
          (v) => setState(() => _adjustment = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep<T extends Enum>(String title, List<T> items, T? selected, Function(T) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => _buildChoiceChip(
            (item as dynamic).label,
            selected == item,
            () {
              onSelect(item);
              // Small delay for visual feedback before auto-advance
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: AppDesign.actionButtonDecoration(selected: isSelected),
        child: Text(
          label,
          style: AppDesign.actionButtonTextStyle(selected: isSelected),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

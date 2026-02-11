import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/local/database.dart';
import '../widgets/retro_wizard_sheet.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RetroWizardSheet(decision: decision),
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

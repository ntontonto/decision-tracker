import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';

class DecisionListPage extends ConsumerStatefulWidget {
  const DecisionListPage({super.key});

  @override
  ConsumerState<DecisionListPage> createState() => _DecisionListPageState();
}

class _DecisionListPageState extends ConsumerState<DecisionListPage> {
  String _searchQuery = '';
  DecisionStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final allDecisionsAsync = ref.watch(allDecisionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('判断一覧'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '判断文で検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: allDecisionsAsync.when(
              data: (decisions) {
                final filtered = decisions.where((d) {
                  final matchQuery = d.textContent.contains(_searchQuery);
                  final matchStatus = _filterStatus == null || d.status == _filterStatus;
                  return matchQuery && matchStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('該当するデータがありません'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    return _buildDecisionListTile(context, d);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: _filterStatus == null,
            onSelected: (s) => setState(() => _filterStatus = null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('未レビュー'),
            selected: _filterStatus == DecisionStatus.pending,
            onSelected: (s) => setState(() => _filterStatus = DecisionStatus.pending),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('完了'),
            selected: _filterStatus == DecisionStatus.reviewed,
            onSelected: (s) => setState(() => _filterStatus = DecisionStatus.reviewed),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionListTile(BuildContext context, Decision d) {
    return ListTile(
      title: Text(d.textContent),
      subtitle: Text('${d.driver.label} · ${d.status == DecisionStatus.reviewed ? "完了" : "未レビュー"}'),
      trailing: Text('${d.createdAt.month}/${d.createdAt.day}'),
      onTap: () => _showDetail(context, d),
    );
  }

  void _showDetail(BuildContext context, Decision d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DecisionDetailSheet(decision: d),
    );
  }
}

class _DecisionDetailSheet extends ConsumerWidget {
  final Decision decision;
  const _DecisionDetailSheet({required this.decision});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(reviewForLogProvider(decision.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('詳細', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _detailRow('判断文', decision.textContent),
                _detailRow('Driver', decision.driver.label),
                if (decision.gain != null) _detailRow('Gain', decision.gain!.label),
                if (decision.lose != null) _detailRow('Lose', decision.lose!.label),
                if (decision.note != null && decision.note!.isNotEmpty) _detailRow('一言', decision.note!),
                _detailRow('作成日', decision.createdAt.toString()),
                _detailRow('振り返り予定', decision.retroAt.toString()),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('復習結果', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                reviewAsync.when(
                  data: (review) {
                    if (review == null) return const Text('まだレビューされていません');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('実行状況', review.execution.label),
                        _detailRow('納得度', '${review.convictionScore} / 10'),
                        _detailRow('再判断の意思', review.wouldRepeat ? 'あり' : 'なし'),
                        if (review.adjustment != null) _detailRow('次の一歩', review.adjustment!.label),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

// No longer needed: generic futureProvider and local reviewFutureProvider

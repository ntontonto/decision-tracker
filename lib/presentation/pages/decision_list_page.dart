import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/local/database.dart';
import '../widgets/decision_list_card.dart';
import '../../domain/models/learning_thread.dart';

class DecisionListPage extends ConsumerStatefulWidget {
  const DecisionListPage({super.key});

  @override
  ConsumerState<DecisionListPage> createState() => _DecisionListPageState();
}

class _DecisionListPageState extends ConsumerState<DecisionListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allDecisionsAsync = ref.watch(allDecisionsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 160,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    '判断履歴',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 60),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'キーワードで検索...',
                              hintStyle: TextStyle(color: Colors.white24),
                              prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              allDecisionsAsync.when(
                data: (decisions) {
                  final filtered = decisions.where((d) {
                    return d.textContent.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '該当するデータがありません',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }

                  // Grouping by Month
                  final Map<String, List<Decision>> grouped = {};
                  for (final d in filtered) {
                    final monthKey = DateFormat('yyyy年 MM月').format(d.createdAt);
                    grouped.putIfAbsent(monthKey, () => []).add(d);
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        for (final monthKey in grouped.keys) ...[
                          _buildSectionTitle(monthKey),
                          ...grouped[monthKey]!.map(
                            (d) => DecisionListCard(
                              decision: d,
                              onTap: () => _showDetail(context, d),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (e, s) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Decision d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DecisionDetailSheet(decision: d),
    );
  }
}

class _DecisionDetailSheet extends ConsumerStatefulWidget {
  final Decision decision;
  const _DecisionDetailSheet({required this.decision});

  @override
  ConsumerState<_DecisionDetailSheet> createState() => _DecisionDetailSheetState();
}

class _DecisionDetailSheetState extends ConsumerState<_DecisionDetailSheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(learningThreadProvider(widget.decision.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Evolution Timeline
            threadAsync.when(
              data: (nodes) => _buildTimeline(nodes),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.white10))),
              error: (e, s) => const SizedBox.shrink(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: Colors.white10, height: 1),
            ),

            Expanded(
              child: threadAsync.when(
                data: (nodes) {
                  if (nodes.isEmpty) return const Center(child: Text('No data found'));
                  final activeNode = nodes[_selectedIndex.clamp(0, nodes.length - 1)];
                  return _buildNodeDetail(context, activeNode, controller);
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<LearningThreadNode> nodes) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: nodes.length,
        separatorBuilder: (context, index) => _buildConnector(),
        itemBuilder: (context, index) {
          final node = nodes[index];
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white38 : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ] : [],
                  ),
                  child: Icon(
                    _getNodeIcon(node.type),
                    size: 18,
                    color: isSelected ? Colors.white : Colors.white38,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gen ${node.generation}',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.white24,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 30,
      height: 48,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 22),
      child: Container(
        width: 15,
        height: 1,
        color: Colors.white10,
      ),
    );
  }

  IconData _getNodeIcon(LearningNodeType type) {
    switch (type) {
      case LearningNodeType.decision: return Icons.psychology;
      case LearningNodeType.retro: return Icons.search;
      case LearningNodeType.declaration: return Icons.flag;
      case LearningNodeType.check: return Icons.check_circle;
    }
  }

  Widget _buildNodeDetail(BuildContext context, LearningThreadNode node, ScrollController controller) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getNodeTypeName(node.type),
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(node.date),
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          node.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        
        ..._buildTypeSpecificDetails(node),
        
        const SizedBox(height: 60),
      ],
    );
  }

  String _getNodeTypeName(LearningNodeType type) {
    switch (type) {
      case LearningNodeType.decision: return 'DECISION';
      case LearningNodeType.retro: return 'RETRO';
      case LearningNodeType.declaration: return 'ACTION';
      case LearningNodeType.check: return 'CHECK';
    }
  }

  List<Widget> _buildTypeSpecificDetails(LearningThreadNode node) {
    if (node.type == LearningNodeType.decision) {
      final d = node.originalData as Decision;
      return [
        _buildDetailRow('動機 (Driver)', d.driver.label),
        if (d.gain != null) _buildDetailRow('得たいもの (Gain)', d.gain!.label),
        if (d.lose != null) _buildDetailRow('許容した損失 (Lose)', d.lose!.label),
        if (d.note != null && d.note!.isNotEmpty) _buildDetailRow('一言メモ', d.note!),
      ];
    } else if (node.type == LearningNodeType.retro) {
      final r = node.originalData as Review;
      return [
        _buildDetailRow('実行状況', r.execution.label),
        _buildDetailRow('納得度', '${r.convictionScore} / 10'),
        _buildDetailRow('再構成の意思', r.wouldRepeat ? 'あり' : 'なし'),
        if (r.adjustment != null) _buildDetailRow('調整方針', r.adjustment!.label),
        if (r.memo != null && r.memo!.isNotEmpty) _buildDetailRow('振り返りメモ', r.memo!),
      ];
    } else if (node.type == LearningNodeType.declaration) {
      final d = node.originalData as Declaration;
      return [
        _buildDetailRow('阻害要因', d.reasonLabel),
        _buildDetailRow('解決策', d.solutionText),
        _buildDetailRow('振り返り予定', DateFormat('MM/dd').format(d.reviewAt)),
      ];
    } else if (node.type == LearningNodeType.check) {
      final d = node.originalData as Declaration;
      return [
        _buildDetailRow('成果の確認', d.lastReviewStatus?.name ?? '完了'),
        if (d.completedAt != null) _buildDetailRow('完了日時', DateFormat('yyyy/MM/dd HH:mm').format(d.completedAt!)),
      ];
    }
    return [];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/declaration_providers.dart';
import '../widgets/action_goal_card.dart';

class ActionGoalListPage extends ConsumerWidget {
  const ActionGoalListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(actionGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
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
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    '行動目標',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'まだ目標がありません。\nRetroの後に宣言してみましょう！',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }

                  final overdueGoals = goals.where((g) => g.reviewAt.isBefore(DateTime.now())).toList();
                  final upcomingGoals = goals.where((g) => !g.reviewAt.isBefore(DateTime.now())).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (overdueGoals.isNotEmpty) ...[
                          _buildSectionTitle('振り返りが必要'),
                          ...overdueGoals.map((g) => ActionGoalCard(declaration: g)),
                          const SizedBox(height: 24),
                        ],
                        if (upcomingGoals.isNotEmpty) ...[
                          _buildSectionTitle('これからの行動'),
                          ...upcomingGoals.map((g) => ActionGoalCard(declaration: g)),
                        ],
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('エラーが発生しました: $err', style: const TextStyle(color: Colors.red))),
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
}

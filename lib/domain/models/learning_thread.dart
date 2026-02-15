import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';
import '../providers/app_providers.dart';
import '../providers/declaration_providers.dart';

enum LearningNodeType {
  decision,
  retro,
  declaration,
  check, // Action Review of a declaration
}

class LearningThreadNode {
  final String id;
  final LearningNodeType type;
  final DateTime date;
  final String title;
  final String description;
  final dynamic originalData; // Decision, Review, or Declaration
  final int generation;

  LearningThreadNode({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.description,
    required this.originalData,
    required this.generation,
  });
}

final learningThreadProvider = FutureProvider.family<List<LearningThreadNode>, String>((ref, logId) async {
  // 1. Fetch the original Decision
  final allDecisions = await ref.watch(allDecisionsProvider.future);
  final decision = allDecisions.firstWhere((d) => d.id == logId);
  
  final List<LearningThreadNode> thread = [];
  int gen = 0;

  // Node 0: Decision
  thread.add(LearningThreadNode(
    id: 'decision_$logId',
    type: LearningNodeType.decision,
    date: decision.createdAt,
    title: '判断の記録',
    description: decision.textContent,
    originalData: decision,
    generation: gen++,
  ));

  // 2. Fetch the Review for this Decision (Reviews are now integrated into Decisions)
  if (decision.reviewedAt != null) {
    thread.add(LearningThreadNode(
      id: 'retro_$logId',
      type: LearningNodeType.retro,
      date: decision.reviewedAt!,
      title: '振り返り',
      description: decision.memo ?? '振り返りを実施しました',
      originalData: decision,
      generation: gen++,
    ));
  }

  // 3. Fetch all Declarations for this logId
  // Since parentId is now Int, we can iteratively build the chain
  final allDeclarations = await ref.watch(actionGoalsProvider.future);
  final logDeclarations = allDeclarations.where((d) => d.logId == logId).toList();
  
  // Start with the one that has no parentId (first gen)
  Declaration? current = logDeclarations.where((d) => d.parentId == null).firstOrNull;
  
  while (current != null) {
    // Add Declaration Node
    thread.add(LearningThreadNode(
      id: 'decl_${current.id}',
      type: LearningNodeType.declaration,
      date: current.createdAt,
      title: '行動宣言',
      description: current.declarationText,
      originalData: current,
      generation: gen++,
    ));

    // If completed (has Check), add Check Node
    if (current.completedAt != null) {
      thread.add(LearningThreadNode(
        id: 'check_${current.id}',
        type: LearningNodeType.check,
        date: current.completedAt!,
        title: '実践の確認',
        description: current.regretLevel == RegretLevel.none 
            ? '目標を達成しました！' 
            : '課題が見つかりました',
        originalData: current,
        generation: gen++,
      ));
    }

    // Move to next in chain
    final nextId = current.id;
    current = logDeclarations.where((d) => d.parentId == nextId).firstOrNull;
  }

  return thread;
});

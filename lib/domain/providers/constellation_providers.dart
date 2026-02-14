import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/domain/providers/app_providers.dart';
import 'package:decision_tracker/domain/providers/declaration_providers.dart';
import 'package:decision_tracker/data/local/database.dart';

final constellationProvider = FutureProvider<LearningGraph>((ref) async {
  final decisions = await ref.watch(allDecisionsProvider.future);
  final allDeclarations = await ref.watch(actionGoalsProvider.future);
  final allReviews = await ref.watch(allReviewsProvider.future);
  
  debugPrint('ConstellationProvider: decisions=${decisions.length}, declarations=${allDeclarations.length}, reviews=${allReviews.length}');
  
  final List<ConstellationNode> nodes = [];
  final List<ConstellationEdge> edges = [];

  if (decisions.isEmpty) {
    return LearningGraph(nodes: [], edges: [], totalSize: Size.zero);
  }

  // Layout Constants for World Boundary
  const double worldWidth = 2000;
  const double worldHeight = 2000;

  for (int i = 0; i < decisions.length; i++) {
    final decision = decisions[i];
    final String chainId = decision.id;
    
    // Seeded random for organic "Cloud" placement
    final random = math.Random(decision.id.hashCode);
    
    // Initial position in a central cloud
    final double initialX = worldWidth / 2 + (random.nextDouble() - 0.5) * 400;
    final double initialY = worldHeight / 2 + (random.nextDouble() - 0.5) * 400;
    
    // Initial drift velocity
    final initialVel = Offset(
      (random.nextDouble() - 0.5) * 20, // Initial drift speed
      (random.nextDouble() - 0.5) * 20,
    );

    final String decisionNodeId = 'dec_${decision.id}';
    
    nodes.add(ConstellationNode(
      id: decisionNodeId,
      type: ConstellationNodeType.decision,
      position: Offset(initialX, initialY),
      velocity: initialVel,
      date: decision.createdAt,
      label: decision.textContent,
      originalData: decision,
      generation: 0,
      chainId: chainId,
    ));

    // 1. Review
    final review = allReviews.where((r) => r.logId == decision.id).firstOrNull;
    String lastNodeId = decisionNodeId;
    Offset lastPos = Offset(initialX, initialY);
    int currentGen = 1;

    if (review != null) {
      final String retroId = 'retro_${decision.id}';
      // Branch out slightly
      final branchAngle = random.nextDouble() * math.pi * 2;
      final branchDist = 80.0 + random.nextDouble() * 40.0;
      final posRetro = lastPos + Offset(math.cos(branchAngle) * branchDist, math.sin(branchAngle) * branchDist);
      
      nodes.add(ConstellationNode(
        id: retroId,
        type: ConstellationNodeType.retro,
        position: posRetro,
        velocity: initialVel * 0.9, // Follow root but slightly slower
        date: review.reviewedAt,
        label: review.memo ?? '振り返り',
        originalData: review,
        generation: currentGen++,
        chainId: chainId,
      ));
      
      edges.add(ConstellationEdge(lastNodeId, retroId));
      lastNodeId = retroId;
      lastPos = posRetro;
    }

    // 2. Declarations
    final logDeclarations = allDeclarations.where((d) => d.logId == decision.id).toList();
    Declaration? currentDecl = logDeclarations.where((d) => d.parentId == null).firstOrNull;

    while (currentDecl != null) {
      final String declId = 'decl_${currentDecl.id}';
      final branchAngle = random.nextDouble() * math.pi * 2;
      final branchDist = 80.0 + random.nextDouble() * 40.0;
      final posDecl = lastPos + Offset(math.cos(branchAngle) * branchDist, math.sin(branchAngle) * branchDist);
      
      nodes.add(ConstellationNode(
        id: declId,
        type: ConstellationNodeType.declaration,
        position: posDecl,
        velocity: initialVel * 0.8,
        date: currentDecl.createdAt,
        label: currentDecl.declarationText,
        originalData: currentDecl,
        generation: currentGen++,
        chainId: chainId,
      ));
      
      edges.add(ConstellationEdge(lastNodeId, declId));
      lastNodeId = declId;
      lastPos = posDecl;

      if (currentDecl.completedAt != null) {
        final String checkId = 'check_${currentDecl.id}';
        final checkAngle = random.nextDouble() * math.pi * 2;
        final checkDist = 60.0;
        final posCheck = lastPos + Offset(math.cos(checkAngle) * checkDist, math.sin(checkAngle) * checkDist);
        
        nodes.add(ConstellationNode(
          id: checkId,
          type: ConstellationNodeType.check,
          position: posCheck,
          velocity: initialVel * 0.7,
          date: currentDecl.completedAt!,
          label: '実践確認',
          originalData: currentDecl,
          generation: currentGen++,
          chainId: chainId,
        ));
        
        edges.add(ConstellationEdge(lastNodeId, checkId));
        lastNodeId = checkId;
        lastPos = posCheck;
      }

      final int nextParentId = currentDecl.id;
      currentDecl = logDeclarations.where((d) => d.parentId == nextParentId).firstOrNull;
    }
  }

  return LearningGraph(
    nodes: nodes,
    edges: edges,
    totalSize: const Size(worldWidth, worldHeight),
  );
});

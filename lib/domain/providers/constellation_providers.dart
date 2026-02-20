import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoshi_log/domain/models/constellation_models.dart';
import 'package:hoshi_log/domain/providers/app_providers.dart';
import 'package:hoshi_log/domain/providers/declaration_providers.dart';
import 'package:hoshi_log/domain/models/enums.dart';
import 'package:hoshi_log/data/local/database.dart';

final constellationProvider = FutureProvider<LearningGraph>((ref) async {
  final decisions = await ref.watch(allDecisionsProvider.future);
  final allDeclarations = await ref.watch(actionGoalsProvider.future);
  
  debugPrint('ConstellationProvider: decisions=${decisions.length}, declarations=${allDeclarations.length}');
  
  double getBaseHue(DriverType driver) {
    switch (driver) {
      case DriverType.pleasure: return 320;   // Vivid Pink
      case DriverType.curiosity: return 180;  // Cyan (Electric)
      case DriverType.expression: return 270; // Vivid Violet
      case DriverType.investment: return 45;  // Bright Gold
      case DriverType.habit: return 140;      // Candy Green
      case DriverType.requested: return 20;   // Bright Red-Orange
      case DriverType.reputation: return 210; // Azure Blue
      case DriverType.guilt: return 0;        // Pure Red
    }
  }

  double getJitter(String id, double range) {
    final random = math.Random(id.hashCode);
    return (random.nextDouble() - 0.5) * range;
  }
  
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
    final bool isReviewed = decision.status == DecisionStatus.reviewed;
    
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
      isReviewed: isReviewed,
      score: decision.score ?? 0,
      reflectionDate: decision.reviewedAt,
      scheduledReflectionDate: decision.retroAt,
      hue: (getBaseHue(decision.driver) + getJitter(decision.id, 40)) % 360,
    ));

    final double parentHue = nodes.last.hue;

    String lastNodeId = decisionNodeId;
    Offset lastPos = Offset(initialX, initialY);
    int currentGen = 1;

    // 2. Declarations
    final logDeclarations = allDeclarations.where((d) => d.logId == decision.id).toList();
    Declaration? currentDecl = logDeclarations.where((d) => d.parentId == null).firstOrNull;

    while (currentDecl != null) {
      final String declId = 'decl_${currentDecl.id}';
      final branchAngle = random.nextDouble() * math.pi * 2;
      final branchDist = 100.0 + random.nextDouble() * 50.0;
      final posDecl = lastPos + Offset(math.cos(branchAngle) * branchDist, math.sin(branchAngle) * branchDist);
      
      final bool isDeclCompleted = currentDecl.completedAt != null;

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
        isReviewed: isDeclCompleted,
        score: currentDecl.score ?? 0,
        reflectionDate: currentDecl.completedAt,
        scheduledReflectionDate: currentDecl.reviewAt,
        // Significant shift from parent (120 degrees + larger jitter)
        hue: (parentHue + 120 + getJitter(currentDecl.id.toString(), 100)) % 360,
      ));
      
      edges.add(ConstellationEdge(lastNodeId, declId));
      lastNodeId = declId;
      lastPos = posDecl;

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

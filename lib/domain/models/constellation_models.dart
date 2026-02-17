import 'dart:ui';
import 'package:flutter/material.dart';

enum ConstellationNodeType {
  decision,
  declaration,
}

enum ConstellationSortMode {
  none,
  unreviewedFirst,
  decisionDate,
  latestActionDate;

  String get label {
    switch (this) {
      case ConstellationSortMode.none: return 'なし';
      case ConstellationSortMode.unreviewedFirst: return '未振り返りが上';
      case ConstellationSortMode.decisionDate: return '判断日順';
      case ConstellationSortMode.latestActionDate: return '最新行動日順';
    }
  }
}

enum ConstellationFilterMode {
  all,
  unreviewedOnly;

  String get label {
    switch (this) {
      case ConstellationFilterMode.all: return 'すべて';
      case ConstellationFilterMode.unreviewedOnly: return '未振り返りのみ';
    }
  }
}

class ConstellationNode {
  final String id;
  final ConstellationNodeType type;
  final Offset position;
  final Offset velocity; // Physical velocity for drift and drag
  final DateTime date;
  final String label;
  final dynamic originalData;
  final int generation;
  final String chainId; 
  final bool isReviewed;
  final int score; // 1, 3, 5 or 0 if not reviewed
  final double hue; // Deterministic color hue

  ConstellationNode({
    required this.id,
    required this.type,
    required this.position,
    this.velocity = Offset.zero,
    required this.date,
    required this.label,
    required this.originalData,
    required this.generation,
    required this.chainId,
    this.isReviewed = false,
    this.score = 0,
    required this.hue,
  });

  ConstellationNode copy({
    Offset? position,
    Offset? velocity,
    bool? isReviewed,
    int? score,
  }) {
    return ConstellationNode(
      id: id,
      type: type,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      date: date,
      label: label,
      originalData: originalData,
      generation: generation,
      chainId: chainId,
      isReviewed: isReviewed ?? this.isReviewed,
      score: score ?? this.score,
      hue: hue,
    );
  }
}

class ConstellationEdge {
  final String fromId;
  final String toId;

  ConstellationEdge(this.fromId, this.toId);
}

class LearningGraph {
  final List<ConstellationNode> nodes;
  final List<ConstellationEdge> edges;
  final Size totalSize;

  LearningGraph({
    required this.nodes,
    required this.edges,
    required this.totalSize,
  });
}

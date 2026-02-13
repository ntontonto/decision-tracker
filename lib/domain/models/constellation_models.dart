import 'dart:ui';
import 'package:flutter/material.dart';

enum ConstellationNodeType {
  decision,
  retro,
  declaration,
  check, // Action Review
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
  });

  ConstellationNode copy({
    Offset? position,
    Offset? velocity,
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

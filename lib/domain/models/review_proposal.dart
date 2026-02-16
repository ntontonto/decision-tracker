import 'package:flutter/material.dart';
import 'reviewable.dart';

enum ProposalType {
  decisionRetro,
  actionReview,
}

class ReviewProposal implements Reviewable {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final DateTime targetDate;
  final ProposalType type;
  @override
  final dynamic originalData; // Decision or Declaration

  ReviewProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.type,
    required this.originalData,
  });

  @override
  IconData get icon => type == ProposalType.decisionRetro 
      ? Icons.history 
      : Icons.check_circle_outline;

  @override
  bool get isReviewableNow => isWithinReviewWindow;
}

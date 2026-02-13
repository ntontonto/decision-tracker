enum ProposalType {
  decisionRetro,
  actionReview,
}

class ReviewProposal {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final ProposalType type;
  final dynamic originalData; // Decision or Declaration

  ReviewProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.type,
    required this.originalData,
  });
}

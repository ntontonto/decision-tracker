class ActionBlocker {
  final String key;
  final String label;
  final List<ActionSolution> solutions;

  ActionBlocker({
    required this.key,
    required this.label,
    required this.solutions,
  });

  factory ActionBlocker.fromJson(Map<String, dynamic> json) {
    return ActionBlocker(
      key: json['key'] as String,
      label: json['label'] as String,
      solutions: (json['solutions'] as List<dynamic>)
          .map((s) => ActionSolution.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ActionSolution {
  final String key;
  final String label;

  ActionSolution({
    required this.key,
    required this.label,
  });

  factory ActionSolution.fromJson(Map<String, dynamic> json) {
    return ActionSolution(
      key: json['key'] as String,
      label: json['label'] as String,
    );
  }
}

class ActionReviewMap {
  final List<ActionBlocker> blockers;

  ActionReviewMap({required this.blockers});

  factory ActionReviewMap.fromJson(Map<String, dynamic> json) {
    return ActionReviewMap(
      blockers: (json['blockers'] as List<dynamic>)
          .map((b) => ActionBlocker.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

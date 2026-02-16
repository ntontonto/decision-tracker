import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import 'app_providers.dart';

/// Metrics calculated from user's reflection data
class ReflectionMetrics {
  /// Review completion rate (0.0 to 1.0)
  /// Among items scheduled for review in the last 7 days, what percentage were actually reviewed?
  final double reviewCompletionRate;
  
  /// Intrinsic motivation ratio (0.0 to 1.0)
  /// Among decisions in the last 30 days, what percentage had intrinsic drivers?
  final double intrinsicMotivationRatio;
  
  /// Input frequency (0 to 7)
  /// Out of the last 7 days, how many days had at least one decision or action declaration input?
  final int inputFrequency;
  
  /// Satisfaction score average (1.0 to 5.0)
  /// Average score of all reviewed decisions and declarations in the last 30 days
  final double satisfactionScoreAverage;

  const ReflectionMetrics({
    required this.reviewCompletionRate,
    required this.intrinsicMotivationRatio,
    required this.inputFrequency,
    required this.satisfactionScoreAverage,
  });

  /// Default metrics when no data is available
  static const ReflectionMetrics empty = ReflectionMetrics(
    reviewCompletionRate: 0.0,
    intrinsicMotivationRatio: 0.0,
    inputFrequency: 0,
    satisfactionScoreAverage: 3.0, // Neutral score
  );
}

/// Provider that calculates reflection metrics from the database
final reflectionMetricsProvider = FutureProvider<ReflectionMetrics>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  
  // Calculate date ranges
  final last7Days = now.subtract(const Duration(days: 7));
  final last30Days = now.subtract(const Duration(days: 30));
  
  // Fetch all decisions and declarations
  final allDecisions = await (db.select(db.decisions)).get();
  final allDeclarations = await (db.select(db.declarations)).get();
  
  // 1. Review Completion Rate (last 7 days)
  final decisionsScheduledLast7Days = allDecisions.where((d) {
    return d.retroAt.isAfter(last7Days) && d.retroAt.isBefore(now);
  }).toList();
  
  final declarationsScheduledLast7Days = allDeclarations.where((d) {
    return d.reviewAt.isAfter(last7Days) && d.reviewAt.isBefore(now);
  }).toList();
  
  final totalScheduled = decisionsScheduledLast7Days.length + declarationsScheduledLast7Days.length;
  final totalReviewed = decisionsScheduledLast7Days.where((d) => d.status == DecisionStatus.reviewed).length +
                        declarationsScheduledLast7Days.where((d) => d.status == DeclarationStatus.completed).length;
  
  final reviewCompletionRate = totalScheduled > 0 ? totalReviewed / totalScheduled : 0.0;
  
  // 2. Intrinsic Motivation Ratio (last 30 days)
  final decisionsLast30Days = allDecisions.where((d) {
    return d.createdAt.isAfter(last30Days);
  }).toList();
  
  final intrinsicDrivers = {
    DriverType.pleasure,
    DriverType.curiosity,
    DriverType.expression,
    DriverType.investment,
  };
  
  final intrinsicCount = decisionsLast30Days.where((d) => intrinsicDrivers.contains(d.driver)).length;
  final intrinsicMotivationRatio = decisionsLast30Days.isNotEmpty 
      ? intrinsicCount / decisionsLast30Days.length 
      : 0.0;
  
  // 3. Input Frequency (last 7 days)
  // Count how many unique days had at least one input
  final inputDates = <DateTime>{};
  
  for (var d in allDecisions) {
    if (d.createdAt.isAfter(last7Days)) {
      final dateOnly = DateTime(d.createdAt.year, d.createdAt.month, d.createdAt.day);
      inputDates.add(dateOnly);
    }
  }
  
  for (var d in allDeclarations) {
    if (d.createdAt.isAfter(last7Days)) {
      final dateOnly = DateTime(d.createdAt.year, d.createdAt.month, d.createdAt.day);
      inputDates.add(dateOnly);
    }
  }
  
  final inputFrequency = inputDates.length;
  
  // 4. Satisfaction Score Average (last 30 days)
  final reviewedDecisionsLast30Days = allDecisions.where((d) {
    return d.reviewedAt != null && d.reviewedAt!.isAfter(last30Days) && d.score != null;
  }).toList();
  
  final reviewedDeclarationsLast30Days = allDeclarations.where((d) {
    return d.completedAt != null && d.completedAt!.isAfter(last30Days) && d.score != null;
  }).toList();
  
  final allScores = [
    ...reviewedDecisionsLast30Days.map((d) => d.score!),
    ...reviewedDeclarationsLast30Days.map((d) => d.score!),
  ];
  
  final satisfactionScoreAverage = allScores.isNotEmpty
      ? allScores.reduce((a, b) => a + b) / allScores.length
      : 3.0; // Default to neutral score
  
  return ReflectionMetrics(
    reviewCompletionRate: reviewCompletionRate.clamp(0.0, 1.0),
    intrinsicMotivationRatio: intrinsicMotivationRatio.clamp(0.0, 1.0),
    inputFrequency: inputFrequency.clamp(0, 7),
    satisfactionScoreAverage: satisfactionScoreAverage.clamp(1.0, 5.0),
  );
});

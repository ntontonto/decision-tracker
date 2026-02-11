import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';
import '../../domain/models/enums.dart';

class DecisionRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  DecisionRepository(this.db);

  // --- Decisions ---

  Future<List<Decision>> getAllDecisions() {
    return (db.select(db.decisions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<List<Decision>> getPendingDecisions() {
    return (db.select(db.decisions)
          ..where((t) => t.status.equals(DecisionStatus.pending.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.retroAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<List<Decision>> searchDecisions(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return Future.value([]);
    return (db.select(db.decisions)
          ..where((t) => t.textContent.contains(cleanQuery))
          ..orderBy([
            (t) => OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc)
          ])
          ..limit(8))
        .get();
  }

  Future<String> createDecision({
    required String text,
    required DriverType driver,
    GainType? gain,
    LoseType? lose,
    String? note,
    required RetroOffsetType retroOffset,
    required DateTime retroAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await db.into(db.decisions).insert(
          DecisionsCompanion.insert(
            id: id,
            textContent: text,
            createdAt: now,
            driver: driver,
            gain: Value(gain),
            lose: Value(lose),
            note: Value(note),
            retroOffsetType: retroOffset,
            retroAt: retroAt,
            status: DecisionStatus.pending,
            lastUsedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateDecision({
    required String id,
    required String text,
    required DriverType driver,
    GainType? gain,
    LoseType? lose,
    String? note,
    required RetroOffsetType retroOffset,
    required DateTime retroAt,
  }) async {
    await (db.update(db.decisions)..where((t) => t.id.equals(id))).write(
      DecisionsCompanion(
        textContent: Value(text),
        driver: Value(driver),
        gain: Value(gain),
        lose: Value(lose),
        note: Value(note),
        retroOffsetType: Value(retroOffset),
        retroAt: Value(retroAt),
        lastUsedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateLastUsed(String id) async {
    await (db.update(db.decisions)..where((t) => t.id.equals(id))).write(
      DecisionsCompanion(lastUsedAt: Value(DateTime.now())),
    );
  }

  // --- Reviews ---

  Future<void> createReview({
    required String logId,
    required ExecutionStatus execution,
    required int convictionScore,
    required bool wouldRepeat,
    AdjustmentType? adjustment,
  }) async {
    await db.transaction(() async {
      await db.into(db.reviews).insert(
            ReviewsCompanion.insert(
              logId: logId,
              reviewedAt: DateTime.now(),
              execution: execution,
              convictionScore: convictionScore,
              wouldRepeat: wouldRepeat,
              adjustment: Value(adjustment),
            ),
          );

      await (db.update(db.decisions)..where((t) => t.id.equals(logId))).write(
        const DecisionsCompanion(status: Value(DecisionStatus.reviewed)),
      );
    });
  }

  Future<Review?> getReviewForLog(String logId) {
    return (db.select(db.reviews)..where((t) => t.logId.equals(logId)))
        .getSingleOrNull();
  }

  // --- Retro Logic ---

  Future<void> snoozeReviews(List<String> logIds) async {
    final snoozeTo = DateTime.now().add(const Duration(days: 7));
    await (db.update(db.decisions)..where((t) => t.id.isIn(logIds))).write(
      DecisionsCompanion(retroAt: Value(snoozeTo)),
    );
  }
}

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
    ValueItem? gain,
    ValueItem? lose,
    String? note,
    required RetroOffsetType retroOffset,
    required DateTime retroAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    print('DEBUG: Database insert starting for id: $id');
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
    print('DEBUG: Database insert completed for id: $id');
    return id;
  }

  Future<void> updateDecision({
    required String id,
    required String text,
    required DriverType driver,
    ValueItem? gain,
    ValueItem? lose,
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

  // --- Reviews (Integrated into Decisions) ---

  Future<void> createReview({
    required String logId,
    required RegretLevel regretLevel,
    String? reasonKey,
    String? solution,
    String? successFactor,
    String? reproductionStrategy,
    String? memo,
  }) async {
    await (db.update(db.decisions)..where((t) => t.id.equals(logId))).write(
      DecisionsCompanion(
        status: const Value(DecisionStatus.reviewed),
        reviewedAt: Value(DateTime.now()),
        regretLevel: Value(regretLevel),
        score: Value(regretLevel.score),
        reasonKey: Value(reasonKey),
        solution: Value(solution),
        successFactor: Value(successFactor),
        reproductionStrategy: Value(reproductionStrategy),
        memo: Value(memo),
        lastUsedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Retro Logic ---

  Future<void> snoozeReviews(List<String> logIds) async {
    final snoozeTo = DateTime.now().add(const Duration(days: 7));
    await (db.update(db.decisions)..where((t) => t.id.isIn(logIds))).write(
      DecisionsCompanion(retroAt: Value(snoozeTo)),
    );
  }

  // --- Declarations ---

  Future<void> createDeclaration({
    required String logId,
    required String originalText,
    required String reasonLabel,
    required String solutionText,
    required String declarationText,
    required DateTime reviewAt,
    int? parentId,
  }) async {
    await db.into(db.declarations).insert(
          DeclarationsCompanion.insert(
            logId: logId,
            originalText: originalText,
            reasonLabel: reasonLabel,
            solutionText: solutionText,
            declarationText: declarationText,
            reviewAt: reviewAt,
            createdAt: DateTime.now(),
            parentId: Value(parentId),
            status: const Value(DeclarationStatus.active),
          ),
        );
  }

  Future<List<Declaration>> getPendingDeclarations() {
    final now = DateTime.now();
    return (db.select(db.declarations)
          ..where((t) => t.status.equals(DeclarationStatus.active.index))
          ..where((t) => t.reviewAt.isSmallerOrEqualValue(now))
          ..orderBy([
            (t) => OrderingTerm(expression: t.reviewAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<void> completeDeclaration({
    required int id,
    required RegretLevel regretLevel,
    DeclarationStatus nextStatus = DeclarationStatus.completed,
  }) async {
    await (db.update(db.declarations)..where((t) => t.id.equals(id))).write(
      DeclarationsCompanion(
        completedAt: Value(DateTime.now()),
        status: Value(nextStatus),
        regretLevel: Value(regretLevel),
        score: Value(regretLevel.score),
      ),
    );
  }

  Stream<List<Declaration>> watchDeclarations() {
    return (db.select(db.declarations)
          ..where((t) => t.status.isNotValue(DeclarationStatus.superseded.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.reviewAt, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Stream<List<Decision>> watchDecisions() {
    return (db.select(db.decisions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }
}

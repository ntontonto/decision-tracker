import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';
import '../../domain/models/enums.dart';
import '../../core/services/notification_service.dart';

class DecisionRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();
  final TimeOfDay Function() getNotificationTime;
  final bool Function() areNotificationsEnabled;

  DecisionRepository(this.db, {
    required this.getNotificationTime,
    required this.areNotificationsEnabled,
  });

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
    
    // Schedule notification for this retro date
    if (areNotificationsEnabled()) {
      await _rescheduleNotificationForDate(retroAt);
    }
    
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
    // Get old retro date before update
    final oldDecision = await (db.select(db.decisions)..where((t) => t.id.equals(id))).getSingleOrNull();
    final oldRetroAt = oldDecision?.retroAt;
    
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
    
    // Reschedule notifications if date changed
    if (areNotificationsEnabled() && oldRetroAt != null) {
      final oldDate = DateTime(oldRetroAt.year, oldRetroAt.month, oldRetroAt.day);
      final newDate = DateTime(retroAt.year, retroAt.month, retroAt.day);
      
      if (oldDate != newDate) {
        await _rescheduleNotificationForDate(oldRetroAt);
        await _rescheduleNotificationForDate(retroAt);
      } else {
        await _rescheduleNotificationForDate(retroAt);
      }
    }
  }

  Future<void> updateLastUsed(String id) async {
    await (db.update(db.decisions)..where((t) => t.id.equals(id))).write(
      DecisionsCompanion(lastUsedAt: Value(DateTime.now())),
    );
  }

  Future<void> skipDecision(String id) async {
    // Get retro date before skipping
    final decision = await (db.select(db.decisions)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    await (db.update(db.decisions)..where((t) => t.id.equals(id))).write(
      const DecisionsCompanion(
        status: Value(DecisionStatus.skipped),
      ),
    );
    
    // Reschedule notification for this date (to reflect remaining items)
    if (areNotificationsEnabled() && decision != null) {
      await _rescheduleNotificationForDate(decision.retroAt);
    }
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
    // Get retro date before review
    final decision = await (db.select(db.decisions)..where((t) => t.id.equals(logId))).getSingleOrNull();
    
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
    
    // Reschedule notification for this date (to reflect remaining items)
    if (areNotificationsEnabled() && decision != null) {
      await _rescheduleNotificationForDate(decision.retroAt);
    }
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
    return (db.select(db.declarations)
          ..where((t) => t.status.equals(DeclarationStatus.active.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.reviewAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<void> completeDeclaration({
    required int id,
    required RegretLevel regretLevel,
    String? blockerKey,
    String? solutionKey,
    DeclarationStatus nextStatus = DeclarationStatus.completed,
  }) async {
    await (db.update(db.declarations)..where((t) => t.id.equals(id))).write(
      DeclarationsCompanion(
        completedAt: Value(DateTime.now()),
        status: Value(nextStatus),
        regretLevel: Value(regretLevel),
        score: Value(regretLevel.score),
        blockerKey: Value(blockerKey),
        solutionKey: Value(solutionKey),
      ),
    );
  }

  Future<void> skipDeclaration(int id) async {
    await (db.update(db.declarations)..where((t) => t.id.equals(id))).write(
      const DeclarationsCompanion(
        status: Value(DeclarationStatus.skipped),
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
  
  // --- Deletion ---

  Future<void> deleteDecision(String id) async {
    // Get retro date before deletion
    final decision = await (db.select(db.decisions)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    await db.transaction(() async {
      await (db.delete(db.declarations)..where((t) => t.logId.equals(id))).go();
      await (db.delete(db.decisions)..where((t) => t.id.equals(id))).go();
    });
    
    if (areNotificationsEnabled() && decision != null) {
      await _rescheduleNotificationForDate(decision.retroAt);
    }
  }

  Future<void> deleteDeclaration(int id) async {
    // Get retro date before deletion
    final decl = await (db.select(db.declarations)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    await db.transaction(() async {
      final descendants = await _getDescendantIds(id);
      final allIdsToDelete = [id, ...descendants];
      await (db.delete(db.declarations)..where((t) => t.id.isIn(allIdsToDelete))).go();
    });
    
    if (areNotificationsEnabled() && decl != null) {
      await _rescheduleNotificationForDate(decl.reviewAt);
    }
  }

  Future<List<int>> _getDescendantIds(int parentId) async {
    final List<int> ids = [];
    final children = await (db.select(db.declarations)..where((t) => t.parentId.equals(parentId))).get();
    
    for (final child in children) {
      ids.add(child.id);
      ids.addAll(await _getDescendantIds(child.id));
    }
    return ids;
  }

  // Helper method to reschedule notification for a specific date
  Future<void> _rescheduleNotificationForDate(DateTime retroAt) async {
    final date = DateTime(retroAt.year, retroAt.month, retroAt.day);
    await NotificationService().scheduleDailyNotification(
      date: date,
      time: getNotificationTime(),
      repository: this,
    );
  }
}

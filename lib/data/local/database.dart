import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/enums.dart';

part 'database.g.dart';

class Decisions extends Table {
  TextColumn get id => text()();
  TextColumn get textContent => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get driver => intEnum<DriverType>()();
  IntColumn get gain => intEnum<GainType>().nullable()();
  IntColumn get lose => intEnum<LoseType>().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get retroOffsetType => intEnum<RetroOffsetType>()();
  DateTimeColumn get retroAt => dateTime()();
  IntColumn get status => intEnum<DecisionStatus>()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reviews extends Table {
  TextColumn get logId => text().references(Decisions, #id)();
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get execution => intEnum<ExecutionStatus>()();
  IntColumn get convictionScore => integer()(); // 0..10
  BoolColumn get wouldRepeat => boolean()();
  IntColumn get adjustment => intEnum<AdjustmentType>().nullable()();

  // New learning loop columns
  IntColumn get regretLevel => intEnum<RegretLevel>().nullable()();
  TextColumn get reasonKey => text().nullable()();
  TextColumn get solution => text().nullable()();
  TextColumn get successFactor => text().nullable()();
  TextColumn get reproductionStrategy => text().nullable()();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {logId};
}

class Declarations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get logId => text().references(Decisions, #id)();
  
  // Snapshots for display (to preserve context if log is deleted/changed)
  TextColumn get originalText => text()();
  TextColumn get reasonLabel => text()();
  TextColumn get solutionText => text()();
  
  // Declaration content
  TextColumn get declarationText => text()();
  DateTimeColumn get reviewAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  // Execution & Chaining (Version 4)
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get status => intEnum<DeclarationStatus>().withDefault(Constant(DeclarationStatus.active.index))();
  TextColumn get parentId => text().nullable()();
  IntColumn get lastReviewStatus => intEnum<ActionReviewStatus>().nullable()();
}

@DriftDatabase(tables: [Decisions, Reviews, Declarations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add new columns to Reviews
          await m.addColumn(reviews, reviews.regretLevel);
          await m.addColumn(reviews, reviews.reasonKey);
          await m.addColumn(reviews, reviews.solution);
          await m.addColumn(reviews, reviews.successFactor);
          await m.addColumn(reviews, reviews.reproductionStrategy);
          await m.addColumn(reviews, reviews.memo);
        }
        if (from < 3) {
          // Create Declarations table
          await m.createTable(declarations);
        }
        if (from < 4) {
          // Update Declarations table for review flow
          await m.addColumn(declarations, declarations.completedAt);
          await m.addColumn(declarations, declarations.status);
          await m.addColumn(declarations, declarations.parentId);
          await m.addColumn(declarations, declarations.lastReviewStatus);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

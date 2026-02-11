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

@DriftDatabase(tables: [Decisions, Reviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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

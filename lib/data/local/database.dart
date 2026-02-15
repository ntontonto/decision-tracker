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
  IntColumn get gain => intEnum<ValueItem>().nullable()();
  IntColumn get lose => intEnum<ValueItem>().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get retroOffsetType => intEnum<RetroOffsetType>()();
  DateTimeColumn get retroAt => dateTime()();
  IntColumn get status => intEnum<DecisionStatus>()();
  DateTimeColumn get lastUsedAt => dateTime()();

  // Integrated Retro Data
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  IntColumn get regretLevel => intEnum<RegretLevel>().nullable()();
  IntColumn get score => integer().nullable()(); // 1, 3, 5
  TextColumn get reasonKey => text().nullable()();
  TextColumn get solution => text().nullable()();
  TextColumn get successFactor => text().nullable()();
  TextColumn get reproductionStrategy => text().nullable()();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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

  // Execution & Chaining
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get status => intEnum<DeclarationStatus>().withDefault(Constant(DeclarationStatus.active.index))();
  IntColumn get parentId => integer().nullable()();
  
  // Unified Retro for Declarations
  IntColumn get regretLevel => intEnum<RegretLevel>().nullable()();
  IntColumn get score => integer().nullable()(); // 1, 3, 5
}

@DriftDatabase(tables: [Decisions, Declarations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Fresh start: drop and recreate everything
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
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

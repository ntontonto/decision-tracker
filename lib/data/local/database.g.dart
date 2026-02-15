// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DecisionsTable extends Decisions
    with TableInfo<$DecisionsTable, Decision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DriverType, int> driver =
      GeneratedColumn<int>(
        'driver',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DriverType>($DecisionsTable.$converterdriver);
  @override
  late final GeneratedColumnWithTypeConverter<ValueItem?, int> gain =
      GeneratedColumn<int>(
        'gain',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ValueItem?>($DecisionsTable.$convertergainn);
  @override
  late final GeneratedColumnWithTypeConverter<ValueItem?, int> lose =
      GeneratedColumn<int>(
        'lose',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ValueItem?>($DecisionsTable.$converterlosen);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RetroOffsetType, int>
  retroOffsetType = GeneratedColumn<int>(
    'retro_offset_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<RetroOffsetType>($DecisionsTable.$converterretroOffsetType);
  static const VerificationMeta _retroAtMeta = const VerificationMeta(
    'retroAt',
  );
  @override
  late final GeneratedColumn<DateTime> retroAt = GeneratedColumn<DateTime>(
    'retro_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DecisionStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DecisionStatus>($DecisionsTable.$converterstatus);
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    textContent,
    createdAt,
    driver,
    gain,
    lose,
    note,
    retroOffsetType,
    retroAt,
    status,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Decision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_textContentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('retro_at')) {
      context.handle(
        _retroAtMeta,
        retroAt.isAcceptableOrUnknown(data['retro_at']!, _retroAtMeta),
      );
    } else if (isInserting) {
      context.missing(_retroAtMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Decision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Decision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      driver: $DecisionsTable.$converterdriver.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}driver'],
        )!,
      ),
      gain: $DecisionsTable.$convertergainn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}gain'],
        ),
      ),
      lose: $DecisionsTable.$converterlosen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}lose'],
        ),
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      retroOffsetType: $DecisionsTable.$converterretroOffsetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}retro_offset_type'],
        )!,
      ),
      retroAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retro_at'],
      )!,
      status: $DecisionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $DecisionsTable createAlias(String alias) {
    return $DecisionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DriverType, int, int> $converterdriver =
      const EnumIndexConverter<DriverType>(DriverType.values);
  static JsonTypeConverter2<ValueItem, int, int> $convertergain =
      const EnumIndexConverter<ValueItem>(ValueItem.values);
  static JsonTypeConverter2<ValueItem?, int?, int?> $convertergainn =
      JsonTypeConverter2.asNullable($convertergain);
  static JsonTypeConverter2<ValueItem, int, int> $converterlose =
      const EnumIndexConverter<ValueItem>(ValueItem.values);
  static JsonTypeConverter2<ValueItem?, int?, int?> $converterlosen =
      JsonTypeConverter2.asNullable($converterlose);
  static JsonTypeConverter2<RetroOffsetType, int, int>
  $converterretroOffsetType = const EnumIndexConverter<RetroOffsetType>(
    RetroOffsetType.values,
  );
  static JsonTypeConverter2<DecisionStatus, int, int> $converterstatus =
      const EnumIndexConverter<DecisionStatus>(DecisionStatus.values);
}

class Decision extends DataClass implements Insertable<Decision> {
  final String id;
  final String textContent;
  final DateTime createdAt;
  final DriverType driver;
  final ValueItem? gain;
  final ValueItem? lose;
  final String? note;
  final RetroOffsetType retroOffsetType;
  final DateTime retroAt;
  final DecisionStatus status;
  final DateTime lastUsedAt;
  const Decision({
    required this.id,
    required this.textContent,
    required this.createdAt,
    required this.driver,
    this.gain,
    this.lose,
    this.note,
    required this.retroOffsetType,
    required this.retroAt,
    required this.status,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_content'] = Variable<String>(textContent);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['driver'] = Variable<int>(
        $DecisionsTable.$converterdriver.toSql(driver),
      );
    }
    if (!nullToAbsent || gain != null) {
      map['gain'] = Variable<int>($DecisionsTable.$convertergainn.toSql(gain));
    }
    if (!nullToAbsent || lose != null) {
      map['lose'] = Variable<int>($DecisionsTable.$converterlosen.toSql(lose));
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['retro_offset_type'] = Variable<int>(
        $DecisionsTable.$converterretroOffsetType.toSql(retroOffsetType),
      );
    }
    map['retro_at'] = Variable<DateTime>(retroAt);
    {
      map['status'] = Variable<int>(
        $DecisionsTable.$converterstatus.toSql(status),
      );
    }
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  DecisionsCompanion toCompanion(bool nullToAbsent) {
    return DecisionsCompanion(
      id: Value(id),
      textContent: Value(textContent),
      createdAt: Value(createdAt),
      driver: Value(driver),
      gain: gain == null && nullToAbsent ? const Value.absent() : Value(gain),
      lose: lose == null && nullToAbsent ? const Value.absent() : Value(lose),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      retroOffsetType: Value(retroOffsetType),
      retroAt: Value(retroAt),
      status: Value(status),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory Decision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Decision(
      id: serializer.fromJson<String>(json['id']),
      textContent: serializer.fromJson<String>(json['textContent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      driver: $DecisionsTable.$converterdriver.fromJson(
        serializer.fromJson<int>(json['driver']),
      ),
      gain: $DecisionsTable.$convertergainn.fromJson(
        serializer.fromJson<int?>(json['gain']),
      ),
      lose: $DecisionsTable.$converterlosen.fromJson(
        serializer.fromJson<int?>(json['lose']),
      ),
      note: serializer.fromJson<String?>(json['note']),
      retroOffsetType: $DecisionsTable.$converterretroOffsetType.fromJson(
        serializer.fromJson<int>(json['retroOffsetType']),
      ),
      retroAt: serializer.fromJson<DateTime>(json['retroAt']),
      status: $DecisionsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textContent': serializer.toJson<String>(textContent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'driver': serializer.toJson<int>(
        $DecisionsTable.$converterdriver.toJson(driver),
      ),
      'gain': serializer.toJson<int?>(
        $DecisionsTable.$convertergainn.toJson(gain),
      ),
      'lose': serializer.toJson<int?>(
        $DecisionsTable.$converterlosen.toJson(lose),
      ),
      'note': serializer.toJson<String?>(note),
      'retroOffsetType': serializer.toJson<int>(
        $DecisionsTable.$converterretroOffsetType.toJson(retroOffsetType),
      ),
      'retroAt': serializer.toJson<DateTime>(retroAt),
      'status': serializer.toJson<int>(
        $DecisionsTable.$converterstatus.toJson(status),
      ),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  Decision copyWith({
    String? id,
    String? textContent,
    DateTime? createdAt,
    DriverType? driver,
    Value<ValueItem?> gain = const Value.absent(),
    Value<ValueItem?> lose = const Value.absent(),
    Value<String?> note = const Value.absent(),
    RetroOffsetType? retroOffsetType,
    DateTime? retroAt,
    DecisionStatus? status,
    DateTime? lastUsedAt,
  }) => Decision(
    id: id ?? this.id,
    textContent: textContent ?? this.textContent,
    createdAt: createdAt ?? this.createdAt,
    driver: driver ?? this.driver,
    gain: gain.present ? gain.value : this.gain,
    lose: lose.present ? lose.value : this.lose,
    note: note.present ? note.value : this.note,
    retroOffsetType: retroOffsetType ?? this.retroOffsetType,
    retroAt: retroAt ?? this.retroAt,
    status: status ?? this.status,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  Decision copyWithCompanion(DecisionsCompanion data) {
    return Decision(
      id: data.id.present ? data.id.value : this.id,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      driver: data.driver.present ? data.driver.value : this.driver,
      gain: data.gain.present ? data.gain.value : this.gain,
      lose: data.lose.present ? data.lose.value : this.lose,
      note: data.note.present ? data.note.value : this.note,
      retroOffsetType: data.retroOffsetType.present
          ? data.retroOffsetType.value
          : this.retroOffsetType,
      retroAt: data.retroAt.present ? data.retroAt.value : this.retroAt,
      status: data.status.present ? data.status.value : this.status,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Decision(')
          ..write('id: $id, ')
          ..write('textContent: $textContent, ')
          ..write('createdAt: $createdAt, ')
          ..write('driver: $driver, ')
          ..write('gain: $gain, ')
          ..write('lose: $lose, ')
          ..write('note: $note, ')
          ..write('retroOffsetType: $retroOffsetType, ')
          ..write('retroAt: $retroAt, ')
          ..write('status: $status, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    textContent,
    createdAt,
    driver,
    gain,
    lose,
    note,
    retroOffsetType,
    retroAt,
    status,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Decision &&
          other.id == this.id &&
          other.textContent == this.textContent &&
          other.createdAt == this.createdAt &&
          other.driver == this.driver &&
          other.gain == this.gain &&
          other.lose == this.lose &&
          other.note == this.note &&
          other.retroOffsetType == this.retroOffsetType &&
          other.retroAt == this.retroAt &&
          other.status == this.status &&
          other.lastUsedAt == this.lastUsedAt);
}

class DecisionsCompanion extends UpdateCompanion<Decision> {
  final Value<String> id;
  final Value<String> textContent;
  final Value<DateTime> createdAt;
  final Value<DriverType> driver;
  final Value<ValueItem?> gain;
  final Value<ValueItem?> lose;
  final Value<String?> note;
  final Value<RetroOffsetType> retroOffsetType;
  final Value<DateTime> retroAt;
  final Value<DecisionStatus> status;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const DecisionsCompanion({
    this.id = const Value.absent(),
    this.textContent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.driver = const Value.absent(),
    this.gain = const Value.absent(),
    this.lose = const Value.absent(),
    this.note = const Value.absent(),
    this.retroOffsetType = const Value.absent(),
    this.retroAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecisionsCompanion.insert({
    required String id,
    required String textContent,
    required DateTime createdAt,
    required DriverType driver,
    this.gain = const Value.absent(),
    this.lose = const Value.absent(),
    this.note = const Value.absent(),
    required RetroOffsetType retroOffsetType,
    required DateTime retroAt,
    required DecisionStatus status,
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textContent = Value(textContent),
       createdAt = Value(createdAt),
       driver = Value(driver),
       retroOffsetType = Value(retroOffsetType),
       retroAt = Value(retroAt),
       status = Value(status),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<Decision> custom({
    Expression<String>? id,
    Expression<String>? textContent,
    Expression<DateTime>? createdAt,
    Expression<int>? driver,
    Expression<int>? gain,
    Expression<int>? lose,
    Expression<String>? note,
    Expression<int>? retroOffsetType,
    Expression<DateTime>? retroAt,
    Expression<int>? status,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textContent != null) 'text_content': textContent,
      if (createdAt != null) 'created_at': createdAt,
      if (driver != null) 'driver': driver,
      if (gain != null) 'gain': gain,
      if (lose != null) 'lose': lose,
      if (note != null) 'note': note,
      if (retroOffsetType != null) 'retro_offset_type': retroOffsetType,
      if (retroAt != null) 'retro_at': retroAt,
      if (status != null) 'status': status,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? textContent,
    Value<DateTime>? createdAt,
    Value<DriverType>? driver,
    Value<ValueItem?>? gain,
    Value<ValueItem?>? lose,
    Value<String?>? note,
    Value<RetroOffsetType>? retroOffsetType,
    Value<DateTime>? retroAt,
    Value<DecisionStatus>? status,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return DecisionsCompanion(
      id: id ?? this.id,
      textContent: textContent ?? this.textContent,
      createdAt: createdAt ?? this.createdAt,
      driver: driver ?? this.driver,
      gain: gain ?? this.gain,
      lose: lose ?? this.lose,
      note: note ?? this.note,
      retroOffsetType: retroOffsetType ?? this.retroOffsetType,
      retroAt: retroAt ?? this.retroAt,
      status: status ?? this.status,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (driver.present) {
      map['driver'] = Variable<int>(
        $DecisionsTable.$converterdriver.toSql(driver.value),
      );
    }
    if (gain.present) {
      map['gain'] = Variable<int>(
        $DecisionsTable.$convertergainn.toSql(gain.value),
      );
    }
    if (lose.present) {
      map['lose'] = Variable<int>(
        $DecisionsTable.$converterlosen.toSql(lose.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (retroOffsetType.present) {
      map['retro_offset_type'] = Variable<int>(
        $DecisionsTable.$converterretroOffsetType.toSql(retroOffsetType.value),
      );
    }
    if (retroAt.present) {
      map['retro_at'] = Variable<DateTime>(retroAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $DecisionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecisionsCompanion(')
          ..write('id: $id, ')
          ..write('textContent: $textContent, ')
          ..write('createdAt: $createdAt, ')
          ..write('driver: $driver, ')
          ..write('gain: $gain, ')
          ..write('lose: $lose, ')
          ..write('note: $note, ')
          ..write('retroOffsetType: $retroOffsetType, ')
          ..write('retroAt: $retroAt, ')
          ..write('status: $status, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, Review> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<String> logId = GeneratedColumn<String>(
    'log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decisions (id)',
    ),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExecutionStatus, int> execution =
      GeneratedColumn<int>(
        'execution',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ExecutionStatus>($ReviewsTable.$converterexecution);
  static const VerificationMeta _convictionScoreMeta = const VerificationMeta(
    'convictionScore',
  );
  @override
  late final GeneratedColumn<int> convictionScore = GeneratedColumn<int>(
    'conviction_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wouldRepeatMeta = const VerificationMeta(
    'wouldRepeat',
  );
  @override
  late final GeneratedColumn<bool> wouldRepeat = GeneratedColumn<bool>(
    'would_repeat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("would_repeat" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AdjustmentType?, int> adjustment =
      GeneratedColumn<int>(
        'adjustment',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<AdjustmentType?>($ReviewsTable.$converteradjustmentn);
  @override
  late final GeneratedColumnWithTypeConverter<RegretLevel?, int> regretLevel =
      GeneratedColumn<int>(
        'regret_level',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<RegretLevel?>($ReviewsTable.$converterregretLeveln);
  static const VerificationMeta _reasonKeyMeta = const VerificationMeta(
    'reasonKey',
  );
  @override
  late final GeneratedColumn<String> reasonKey = GeneratedColumn<String>(
    'reason_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solutionMeta = const VerificationMeta(
    'solution',
  );
  @override
  late final GeneratedColumn<String> solution = GeneratedColumn<String>(
    'solution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successFactorMeta = const VerificationMeta(
    'successFactor',
  );
  @override
  late final GeneratedColumn<String> successFactor = GeneratedColumn<String>(
    'success_factor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reproductionStrategyMeta =
      const VerificationMeta('reproductionStrategy');
  @override
  late final GeneratedColumn<String> reproductionStrategy =
      GeneratedColumn<String>(
        'reproduction_strategy',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    logId,
    reviewedAt,
    execution,
    convictionScore,
    wouldRepeat,
    adjustment,
    regretLevel,
    reasonKey,
    solution,
    successFactor,
    reproductionStrategy,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<Review> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('log_id')) {
      context.handle(
        _logIdMeta,
        logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta),
      );
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('conviction_score')) {
      context.handle(
        _convictionScoreMeta,
        convictionScore.isAcceptableOrUnknown(
          data['conviction_score']!,
          _convictionScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_convictionScoreMeta);
    }
    if (data.containsKey('would_repeat')) {
      context.handle(
        _wouldRepeatMeta,
        wouldRepeat.isAcceptableOrUnknown(
          data['would_repeat']!,
          _wouldRepeatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wouldRepeatMeta);
    }
    if (data.containsKey('reason_key')) {
      context.handle(
        _reasonKeyMeta,
        reasonKey.isAcceptableOrUnknown(data['reason_key']!, _reasonKeyMeta),
      );
    }
    if (data.containsKey('solution')) {
      context.handle(
        _solutionMeta,
        solution.isAcceptableOrUnknown(data['solution']!, _solutionMeta),
      );
    }
    if (data.containsKey('success_factor')) {
      context.handle(
        _successFactorMeta,
        successFactor.isAcceptableOrUnknown(
          data['success_factor']!,
          _successFactorMeta,
        ),
      );
    }
    if (data.containsKey('reproduction_strategy')) {
      context.handle(
        _reproductionStrategyMeta,
        reproductionStrategy.isAcceptableOrUnknown(
          data['reproduction_strategy']!,
          _reproductionStrategyMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {logId};
  @override
  Review map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Review(
      logId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_id'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      execution: $ReviewsTable.$converterexecution.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}execution'],
        )!,
      ),
      convictionScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conviction_score'],
      )!,
      wouldRepeat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}would_repeat'],
      )!,
      adjustment: $ReviewsTable.$converteradjustmentn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}adjustment'],
        ),
      ),
      regretLevel: $ReviewsTable.$converterregretLeveln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}regret_level'],
        ),
      ),
      reasonKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_key'],
      ),
      solution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution'],
      ),
      successFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}success_factor'],
      ),
      reproductionStrategy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reproduction_strategy'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExecutionStatus, int, int> $converterexecution =
      const EnumIndexConverter<ExecutionStatus>(ExecutionStatus.values);
  static JsonTypeConverter2<AdjustmentType, int, int> $converteradjustment =
      const EnumIndexConverter<AdjustmentType>(AdjustmentType.values);
  static JsonTypeConverter2<AdjustmentType?, int?, int?> $converteradjustmentn =
      JsonTypeConverter2.asNullable($converteradjustment);
  static JsonTypeConverter2<RegretLevel, int, int> $converterregretLevel =
      const EnumIndexConverter<RegretLevel>(RegretLevel.values);
  static JsonTypeConverter2<RegretLevel?, int?, int?> $converterregretLeveln =
      JsonTypeConverter2.asNullable($converterregretLevel);
}

class Review extends DataClass implements Insertable<Review> {
  final String logId;
  final DateTime reviewedAt;
  final ExecutionStatus execution;
  final int convictionScore;
  final bool wouldRepeat;
  final AdjustmentType? adjustment;
  final RegretLevel? regretLevel;
  final String? reasonKey;
  final String? solution;
  final String? successFactor;
  final String? reproductionStrategy;
  final String? memo;
  const Review({
    required this.logId,
    required this.reviewedAt,
    required this.execution,
    required this.convictionScore,
    required this.wouldRepeat,
    this.adjustment,
    this.regretLevel,
    this.reasonKey,
    this.solution,
    this.successFactor,
    this.reproductionStrategy,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['log_id'] = Variable<String>(logId);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    {
      map['execution'] = Variable<int>(
        $ReviewsTable.$converterexecution.toSql(execution),
      );
    }
    map['conviction_score'] = Variable<int>(convictionScore);
    map['would_repeat'] = Variable<bool>(wouldRepeat);
    if (!nullToAbsent || adjustment != null) {
      map['adjustment'] = Variable<int>(
        $ReviewsTable.$converteradjustmentn.toSql(adjustment),
      );
    }
    if (!nullToAbsent || regretLevel != null) {
      map['regret_level'] = Variable<int>(
        $ReviewsTable.$converterregretLeveln.toSql(regretLevel),
      );
    }
    if (!nullToAbsent || reasonKey != null) {
      map['reason_key'] = Variable<String>(reasonKey);
    }
    if (!nullToAbsent || solution != null) {
      map['solution'] = Variable<String>(solution);
    }
    if (!nullToAbsent || successFactor != null) {
      map['success_factor'] = Variable<String>(successFactor);
    }
    if (!nullToAbsent || reproductionStrategy != null) {
      map['reproduction_strategy'] = Variable<String>(reproductionStrategy);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      logId: Value(logId),
      reviewedAt: Value(reviewedAt),
      execution: Value(execution),
      convictionScore: Value(convictionScore),
      wouldRepeat: Value(wouldRepeat),
      adjustment: adjustment == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustment),
      regretLevel: regretLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(regretLevel),
      reasonKey: reasonKey == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonKey),
      solution: solution == null && nullToAbsent
          ? const Value.absent()
          : Value(solution),
      successFactor: successFactor == null && nullToAbsent
          ? const Value.absent()
          : Value(successFactor),
      reproductionStrategy: reproductionStrategy == null && nullToAbsent
          ? const Value.absent()
          : Value(reproductionStrategy),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory Review.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Review(
      logId: serializer.fromJson<String>(json['logId']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      execution: $ReviewsTable.$converterexecution.fromJson(
        serializer.fromJson<int>(json['execution']),
      ),
      convictionScore: serializer.fromJson<int>(json['convictionScore']),
      wouldRepeat: serializer.fromJson<bool>(json['wouldRepeat']),
      adjustment: $ReviewsTable.$converteradjustmentn.fromJson(
        serializer.fromJson<int?>(json['adjustment']),
      ),
      regretLevel: $ReviewsTable.$converterregretLeveln.fromJson(
        serializer.fromJson<int?>(json['regretLevel']),
      ),
      reasonKey: serializer.fromJson<String?>(json['reasonKey']),
      solution: serializer.fromJson<String?>(json['solution']),
      successFactor: serializer.fromJson<String?>(json['successFactor']),
      reproductionStrategy: serializer.fromJson<String?>(
        json['reproductionStrategy'],
      ),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'logId': serializer.toJson<String>(logId),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'execution': serializer.toJson<int>(
        $ReviewsTable.$converterexecution.toJson(execution),
      ),
      'convictionScore': serializer.toJson<int>(convictionScore),
      'wouldRepeat': serializer.toJson<bool>(wouldRepeat),
      'adjustment': serializer.toJson<int?>(
        $ReviewsTable.$converteradjustmentn.toJson(adjustment),
      ),
      'regretLevel': serializer.toJson<int?>(
        $ReviewsTable.$converterregretLeveln.toJson(regretLevel),
      ),
      'reasonKey': serializer.toJson<String?>(reasonKey),
      'solution': serializer.toJson<String?>(solution),
      'successFactor': serializer.toJson<String?>(successFactor),
      'reproductionStrategy': serializer.toJson<String?>(reproductionStrategy),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  Review copyWith({
    String? logId,
    DateTime? reviewedAt,
    ExecutionStatus? execution,
    int? convictionScore,
    bool? wouldRepeat,
    Value<AdjustmentType?> adjustment = const Value.absent(),
    Value<RegretLevel?> regretLevel = const Value.absent(),
    Value<String?> reasonKey = const Value.absent(),
    Value<String?> solution = const Value.absent(),
    Value<String?> successFactor = const Value.absent(),
    Value<String?> reproductionStrategy = const Value.absent(),
    Value<String?> memo = const Value.absent(),
  }) => Review(
    logId: logId ?? this.logId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    execution: execution ?? this.execution,
    convictionScore: convictionScore ?? this.convictionScore,
    wouldRepeat: wouldRepeat ?? this.wouldRepeat,
    adjustment: adjustment.present ? adjustment.value : this.adjustment,
    regretLevel: regretLevel.present ? regretLevel.value : this.regretLevel,
    reasonKey: reasonKey.present ? reasonKey.value : this.reasonKey,
    solution: solution.present ? solution.value : this.solution,
    successFactor: successFactor.present
        ? successFactor.value
        : this.successFactor,
    reproductionStrategy: reproductionStrategy.present
        ? reproductionStrategy.value
        : this.reproductionStrategy,
    memo: memo.present ? memo.value : this.memo,
  );
  Review copyWithCompanion(ReviewsCompanion data) {
    return Review(
      logId: data.logId.present ? data.logId.value : this.logId,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      execution: data.execution.present ? data.execution.value : this.execution,
      convictionScore: data.convictionScore.present
          ? data.convictionScore.value
          : this.convictionScore,
      wouldRepeat: data.wouldRepeat.present
          ? data.wouldRepeat.value
          : this.wouldRepeat,
      adjustment: data.adjustment.present
          ? data.adjustment.value
          : this.adjustment,
      regretLevel: data.regretLevel.present
          ? data.regretLevel.value
          : this.regretLevel,
      reasonKey: data.reasonKey.present ? data.reasonKey.value : this.reasonKey,
      solution: data.solution.present ? data.solution.value : this.solution,
      successFactor: data.successFactor.present
          ? data.successFactor.value
          : this.successFactor,
      reproductionStrategy: data.reproductionStrategy.present
          ? data.reproductionStrategy.value
          : this.reproductionStrategy,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Review(')
          ..write('logId: $logId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('execution: $execution, ')
          ..write('convictionScore: $convictionScore, ')
          ..write('wouldRepeat: $wouldRepeat, ')
          ..write('adjustment: $adjustment, ')
          ..write('regretLevel: $regretLevel, ')
          ..write('reasonKey: $reasonKey, ')
          ..write('solution: $solution, ')
          ..write('successFactor: $successFactor, ')
          ..write('reproductionStrategy: $reproductionStrategy, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    logId,
    reviewedAt,
    execution,
    convictionScore,
    wouldRepeat,
    adjustment,
    regretLevel,
    reasonKey,
    solution,
    successFactor,
    reproductionStrategy,
    memo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Review &&
          other.logId == this.logId &&
          other.reviewedAt == this.reviewedAt &&
          other.execution == this.execution &&
          other.convictionScore == this.convictionScore &&
          other.wouldRepeat == this.wouldRepeat &&
          other.adjustment == this.adjustment &&
          other.regretLevel == this.regretLevel &&
          other.reasonKey == this.reasonKey &&
          other.solution == this.solution &&
          other.successFactor == this.successFactor &&
          other.reproductionStrategy == this.reproductionStrategy &&
          other.memo == this.memo);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<String> logId;
  final Value<DateTime> reviewedAt;
  final Value<ExecutionStatus> execution;
  final Value<int> convictionScore;
  final Value<bool> wouldRepeat;
  final Value<AdjustmentType?> adjustment;
  final Value<RegretLevel?> regretLevel;
  final Value<String?> reasonKey;
  final Value<String?> solution;
  final Value<String?> successFactor;
  final Value<String?> reproductionStrategy;
  final Value<String?> memo;
  final Value<int> rowid;
  const ReviewsCompanion({
    this.logId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.execution = const Value.absent(),
    this.convictionScore = const Value.absent(),
    this.wouldRepeat = const Value.absent(),
    this.adjustment = const Value.absent(),
    this.regretLevel = const Value.absent(),
    this.reasonKey = const Value.absent(),
    this.solution = const Value.absent(),
    this.successFactor = const Value.absent(),
    this.reproductionStrategy = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewsCompanion.insert({
    required String logId,
    required DateTime reviewedAt,
    required ExecutionStatus execution,
    required int convictionScore,
    required bool wouldRepeat,
    this.adjustment = const Value.absent(),
    this.regretLevel = const Value.absent(),
    this.reasonKey = const Value.absent(),
    this.solution = const Value.absent(),
    this.successFactor = const Value.absent(),
    this.reproductionStrategy = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : logId = Value(logId),
       reviewedAt = Value(reviewedAt),
       execution = Value(execution),
       convictionScore = Value(convictionScore),
       wouldRepeat = Value(wouldRepeat);
  static Insertable<Review> custom({
    Expression<String>? logId,
    Expression<DateTime>? reviewedAt,
    Expression<int>? execution,
    Expression<int>? convictionScore,
    Expression<bool>? wouldRepeat,
    Expression<int>? adjustment,
    Expression<int>? regretLevel,
    Expression<String>? reasonKey,
    Expression<String>? solution,
    Expression<String>? successFactor,
    Expression<String>? reproductionStrategy,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (logId != null) 'log_id': logId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (execution != null) 'execution': execution,
      if (convictionScore != null) 'conviction_score': convictionScore,
      if (wouldRepeat != null) 'would_repeat': wouldRepeat,
      if (adjustment != null) 'adjustment': adjustment,
      if (regretLevel != null) 'regret_level': regretLevel,
      if (reasonKey != null) 'reason_key': reasonKey,
      if (solution != null) 'solution': solution,
      if (successFactor != null) 'success_factor': successFactor,
      if (reproductionStrategy != null)
        'reproduction_strategy': reproductionStrategy,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewsCompanion copyWith({
    Value<String>? logId,
    Value<DateTime>? reviewedAt,
    Value<ExecutionStatus>? execution,
    Value<int>? convictionScore,
    Value<bool>? wouldRepeat,
    Value<AdjustmentType?>? adjustment,
    Value<RegretLevel?>? regretLevel,
    Value<String?>? reasonKey,
    Value<String?>? solution,
    Value<String?>? successFactor,
    Value<String?>? reproductionStrategy,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return ReviewsCompanion(
      logId: logId ?? this.logId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      execution: execution ?? this.execution,
      convictionScore: convictionScore ?? this.convictionScore,
      wouldRepeat: wouldRepeat ?? this.wouldRepeat,
      adjustment: adjustment ?? this.adjustment,
      regretLevel: regretLevel ?? this.regretLevel,
      reasonKey: reasonKey ?? this.reasonKey,
      solution: solution ?? this.solution,
      successFactor: successFactor ?? this.successFactor,
      reproductionStrategy: reproductionStrategy ?? this.reproductionStrategy,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (logId.present) {
      map['log_id'] = Variable<String>(logId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (execution.present) {
      map['execution'] = Variable<int>(
        $ReviewsTable.$converterexecution.toSql(execution.value),
      );
    }
    if (convictionScore.present) {
      map['conviction_score'] = Variable<int>(convictionScore.value);
    }
    if (wouldRepeat.present) {
      map['would_repeat'] = Variable<bool>(wouldRepeat.value);
    }
    if (adjustment.present) {
      map['adjustment'] = Variable<int>(
        $ReviewsTable.$converteradjustmentn.toSql(adjustment.value),
      );
    }
    if (regretLevel.present) {
      map['regret_level'] = Variable<int>(
        $ReviewsTable.$converterregretLeveln.toSql(regretLevel.value),
      );
    }
    if (reasonKey.present) {
      map['reason_key'] = Variable<String>(reasonKey.value);
    }
    if (solution.present) {
      map['solution'] = Variable<String>(solution.value);
    }
    if (successFactor.present) {
      map['success_factor'] = Variable<String>(successFactor.value);
    }
    if (reproductionStrategy.present) {
      map['reproduction_strategy'] = Variable<String>(
        reproductionStrategy.value,
      );
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('logId: $logId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('execution: $execution, ')
          ..write('convictionScore: $convictionScore, ')
          ..write('wouldRepeat: $wouldRepeat, ')
          ..write('adjustment: $adjustment, ')
          ..write('regretLevel: $regretLevel, ')
          ..write('reasonKey: $reasonKey, ')
          ..write('solution: $solution, ')
          ..write('successFactor: $successFactor, ')
          ..write('reproductionStrategy: $reproductionStrategy, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeclarationsTable extends Declarations
    with TableInfo<$DeclarationsTable, Declaration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeclarationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<String> logId = GeneratedColumn<String>(
    'log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decisions (id)',
    ),
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonLabelMeta = const VerificationMeta(
    'reasonLabel',
  );
  @override
  late final GeneratedColumn<String> reasonLabel = GeneratedColumn<String>(
    'reason_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solutionTextMeta = const VerificationMeta(
    'solutionText',
  );
  @override
  late final GeneratedColumn<String> solutionText = GeneratedColumn<String>(
    'solution_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _declarationTextMeta = const VerificationMeta(
    'declarationText',
  );
  @override
  late final GeneratedColumn<String> declarationText = GeneratedColumn<String>(
    'declaration_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewAtMeta = const VerificationMeta(
    'reviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewAt = GeneratedColumn<DateTime>(
    'review_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeclarationStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(DeclarationStatus.active.index),
      ).withConverter<DeclarationStatus>($DeclarationsTable.$converterstatus);
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActionReviewStatus?, int>
  lastReviewStatus =
      GeneratedColumn<int>(
        'last_review_status',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ActionReviewStatus?>(
        $DeclarationsTable.$converterlastReviewStatusn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    logId,
    originalText,
    reasonLabel,
    solutionText,
    declarationText,
    reviewAt,
    createdAt,
    completedAt,
    status,
    parentId,
    lastReviewStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'declarations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Declaration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('log_id')) {
      context.handle(
        _logIdMeta,
        logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta),
      );
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalTextMeta);
    }
    if (data.containsKey('reason_label')) {
      context.handle(
        _reasonLabelMeta,
        reasonLabel.isAcceptableOrUnknown(
          data['reason_label']!,
          _reasonLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reasonLabelMeta);
    }
    if (data.containsKey('solution_text')) {
      context.handle(
        _solutionTextMeta,
        solutionText.isAcceptableOrUnknown(
          data['solution_text']!,
          _solutionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_solutionTextMeta);
    }
    if (data.containsKey('declaration_text')) {
      context.handle(
        _declarationTextMeta,
        declarationText.isAcceptableOrUnknown(
          data['declaration_text']!,
          _declarationTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_declarationTextMeta);
    }
    if (data.containsKey('review_at')) {
      context.handle(
        _reviewAtMeta,
        reviewAt.isAcceptableOrUnknown(data['review_at']!, _reviewAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Declaration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Declaration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      logId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_id'],
      )!,
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      )!,
      reasonLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_label'],
      )!,
      solutionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution_text'],
      )!,
      declarationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}declaration_text'],
      )!,
      reviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      status: $DeclarationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      lastReviewStatus: $DeclarationsTable.$converterlastReviewStatusn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_review_status'],
        ),
      ),
    );
  }

  @override
  $DeclarationsTable createAlias(String alias) {
    return $DeclarationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeclarationStatus, int, int> $converterstatus =
      const EnumIndexConverter<DeclarationStatus>(DeclarationStatus.values);
  static JsonTypeConverter2<ActionReviewStatus, int, int>
  $converterlastReviewStatus = const EnumIndexConverter<ActionReviewStatus>(
    ActionReviewStatus.values,
  );
  static JsonTypeConverter2<ActionReviewStatus?, int?, int?>
  $converterlastReviewStatusn = JsonTypeConverter2.asNullable(
    $converterlastReviewStatus,
  );
}

class Declaration extends DataClass implements Insertable<Declaration> {
  final int id;
  final String logId;
  final String originalText;
  final String reasonLabel;
  final String solutionText;
  final String declarationText;
  final DateTime reviewAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DeclarationStatus status;
  final int? parentId;
  final ActionReviewStatus? lastReviewStatus;
  const Declaration({
    required this.id,
    required this.logId,
    required this.originalText,
    required this.reasonLabel,
    required this.solutionText,
    required this.declarationText,
    required this.reviewAt,
    required this.createdAt,
    this.completedAt,
    required this.status,
    this.parentId,
    this.lastReviewStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['log_id'] = Variable<String>(logId);
    map['original_text'] = Variable<String>(originalText);
    map['reason_label'] = Variable<String>(reasonLabel);
    map['solution_text'] = Variable<String>(solutionText);
    map['declaration_text'] = Variable<String>(declarationText);
    map['review_at'] = Variable<DateTime>(reviewAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    {
      map['status'] = Variable<int>(
        $DeclarationsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || lastReviewStatus != null) {
      map['last_review_status'] = Variable<int>(
        $DeclarationsTable.$converterlastReviewStatusn.toSql(lastReviewStatus),
      );
    }
    return map;
  }

  DeclarationsCompanion toCompanion(bool nullToAbsent) {
    return DeclarationsCompanion(
      id: Value(id),
      logId: Value(logId),
      originalText: Value(originalText),
      reasonLabel: Value(reasonLabel),
      solutionText: Value(solutionText),
      declarationText: Value(declarationText),
      reviewAt: Value(reviewAt),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      lastReviewStatus: lastReviewStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewStatus),
    );
  }

  factory Declaration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Declaration(
      id: serializer.fromJson<int>(json['id']),
      logId: serializer.fromJson<String>(json['logId']),
      originalText: serializer.fromJson<String>(json['originalText']),
      reasonLabel: serializer.fromJson<String>(json['reasonLabel']),
      solutionText: serializer.fromJson<String>(json['solutionText']),
      declarationText: serializer.fromJson<String>(json['declarationText']),
      reviewAt: serializer.fromJson<DateTime>(json['reviewAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      status: $DeclarationsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      parentId: serializer.fromJson<int?>(json['parentId']),
      lastReviewStatus: $DeclarationsTable.$converterlastReviewStatusn.fromJson(
        serializer.fromJson<int?>(json['lastReviewStatus']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'logId': serializer.toJson<String>(logId),
      'originalText': serializer.toJson<String>(originalText),
      'reasonLabel': serializer.toJson<String>(reasonLabel),
      'solutionText': serializer.toJson<String>(solutionText),
      'declarationText': serializer.toJson<String>(declarationText),
      'reviewAt': serializer.toJson<DateTime>(reviewAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'status': serializer.toJson<int>(
        $DeclarationsTable.$converterstatus.toJson(status),
      ),
      'parentId': serializer.toJson<int?>(parentId),
      'lastReviewStatus': serializer.toJson<int?>(
        $DeclarationsTable.$converterlastReviewStatusn.toJson(lastReviewStatus),
      ),
    };
  }

  Declaration copyWith({
    int? id,
    String? logId,
    String? originalText,
    String? reasonLabel,
    String? solutionText,
    String? declarationText,
    DateTime? reviewAt,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    DeclarationStatus? status,
    Value<int?> parentId = const Value.absent(),
    Value<ActionReviewStatus?> lastReviewStatus = const Value.absent(),
  }) => Declaration(
    id: id ?? this.id,
    logId: logId ?? this.logId,
    originalText: originalText ?? this.originalText,
    reasonLabel: reasonLabel ?? this.reasonLabel,
    solutionText: solutionText ?? this.solutionText,
    declarationText: declarationText ?? this.declarationText,
    reviewAt: reviewAt ?? this.reviewAt,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    status: status ?? this.status,
    parentId: parentId.present ? parentId.value : this.parentId,
    lastReviewStatus: lastReviewStatus.present
        ? lastReviewStatus.value
        : this.lastReviewStatus,
  );
  Declaration copyWithCompanion(DeclarationsCompanion data) {
    return Declaration(
      id: data.id.present ? data.id.value : this.id,
      logId: data.logId.present ? data.logId.value : this.logId,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      reasonLabel: data.reasonLabel.present
          ? data.reasonLabel.value
          : this.reasonLabel,
      solutionText: data.solutionText.present
          ? data.solutionText.value
          : this.solutionText,
      declarationText: data.declarationText.present
          ? data.declarationText.value
          : this.declarationText,
      reviewAt: data.reviewAt.present ? data.reviewAt.value : this.reviewAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      status: data.status.present ? data.status.value : this.status,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      lastReviewStatus: data.lastReviewStatus.present
          ? data.lastReviewStatus.value
          : this.lastReviewStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Declaration(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('originalText: $originalText, ')
          ..write('reasonLabel: $reasonLabel, ')
          ..write('solutionText: $solutionText, ')
          ..write('declarationText: $declarationText, ')
          ..write('reviewAt: $reviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('parentId: $parentId, ')
          ..write('lastReviewStatus: $lastReviewStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    logId,
    originalText,
    reasonLabel,
    solutionText,
    declarationText,
    reviewAt,
    createdAt,
    completedAt,
    status,
    parentId,
    lastReviewStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Declaration &&
          other.id == this.id &&
          other.logId == this.logId &&
          other.originalText == this.originalText &&
          other.reasonLabel == this.reasonLabel &&
          other.solutionText == this.solutionText &&
          other.declarationText == this.declarationText &&
          other.reviewAt == this.reviewAt &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.status == this.status &&
          other.parentId == this.parentId &&
          other.lastReviewStatus == this.lastReviewStatus);
}

class DeclarationsCompanion extends UpdateCompanion<Declaration> {
  final Value<int> id;
  final Value<String> logId;
  final Value<String> originalText;
  final Value<String> reasonLabel;
  final Value<String> solutionText;
  final Value<String> declarationText;
  final Value<DateTime> reviewAt;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<DeclarationStatus> status;
  final Value<int?> parentId;
  final Value<ActionReviewStatus?> lastReviewStatus;
  const DeclarationsCompanion({
    this.id = const Value.absent(),
    this.logId = const Value.absent(),
    this.originalText = const Value.absent(),
    this.reasonLabel = const Value.absent(),
    this.solutionText = const Value.absent(),
    this.declarationText = const Value.absent(),
    this.reviewAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.parentId = const Value.absent(),
    this.lastReviewStatus = const Value.absent(),
  });
  DeclarationsCompanion.insert({
    this.id = const Value.absent(),
    required String logId,
    required String originalText,
    required String reasonLabel,
    required String solutionText,
    required String declarationText,
    required DateTime reviewAt,
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.parentId = const Value.absent(),
    this.lastReviewStatus = const Value.absent(),
  }) : logId = Value(logId),
       originalText = Value(originalText),
       reasonLabel = Value(reasonLabel),
       solutionText = Value(solutionText),
       declarationText = Value(declarationText),
       reviewAt = Value(reviewAt),
       createdAt = Value(createdAt);
  static Insertable<Declaration> custom({
    Expression<int>? id,
    Expression<String>? logId,
    Expression<String>? originalText,
    Expression<String>? reasonLabel,
    Expression<String>? solutionText,
    Expression<String>? declarationText,
    Expression<DateTime>? reviewAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? status,
    Expression<int>? parentId,
    Expression<int>? lastReviewStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (logId != null) 'log_id': logId,
      if (originalText != null) 'original_text': originalText,
      if (reasonLabel != null) 'reason_label': reasonLabel,
      if (solutionText != null) 'solution_text': solutionText,
      if (declarationText != null) 'declaration_text': declarationText,
      if (reviewAt != null) 'review_at': reviewAt,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (status != null) 'status': status,
      if (parentId != null) 'parent_id': parentId,
      if (lastReviewStatus != null) 'last_review_status': lastReviewStatus,
    });
  }

  DeclarationsCompanion copyWith({
    Value<int>? id,
    Value<String>? logId,
    Value<String>? originalText,
    Value<String>? reasonLabel,
    Value<String>? solutionText,
    Value<String>? declarationText,
    Value<DateTime>? reviewAt,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<DeclarationStatus>? status,
    Value<int?>? parentId,
    Value<ActionReviewStatus?>? lastReviewStatus,
  }) {
    return DeclarationsCompanion(
      id: id ?? this.id,
      logId: logId ?? this.logId,
      originalText: originalText ?? this.originalText,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      solutionText: solutionText ?? this.solutionText,
      declarationText: declarationText ?? this.declarationText,
      reviewAt: reviewAt ?? this.reviewAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      parentId: parentId ?? this.parentId,
      lastReviewStatus: lastReviewStatus ?? this.lastReviewStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (logId.present) {
      map['log_id'] = Variable<String>(logId.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (reasonLabel.present) {
      map['reason_label'] = Variable<String>(reasonLabel.value);
    }
    if (solutionText.present) {
      map['solution_text'] = Variable<String>(solutionText.value);
    }
    if (declarationText.present) {
      map['declaration_text'] = Variable<String>(declarationText.value);
    }
    if (reviewAt.present) {
      map['review_at'] = Variable<DateTime>(reviewAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $DeclarationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (lastReviewStatus.present) {
      map['last_review_status'] = Variable<int>(
        $DeclarationsTable.$converterlastReviewStatusn.toSql(
          lastReviewStatus.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeclarationsCompanion(')
          ..write('id: $id, ')
          ..write('logId: $logId, ')
          ..write('originalText: $originalText, ')
          ..write('reasonLabel: $reasonLabel, ')
          ..write('solutionText: $solutionText, ')
          ..write('declarationText: $declarationText, ')
          ..write('reviewAt: $reviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('parentId: $parentId, ')
          ..write('lastReviewStatus: $lastReviewStatus')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecisionsTable decisions = $DecisionsTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $DeclarationsTable declarations = $DeclarationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    decisions,
    reviews,
    declarations,
  ];
}

typedef $$DecisionsTableCreateCompanionBuilder =
    DecisionsCompanion Function({
      required String id,
      required String textContent,
      required DateTime createdAt,
      required DriverType driver,
      Value<ValueItem?> gain,
      Value<ValueItem?> lose,
      Value<String?> note,
      required RetroOffsetType retroOffsetType,
      required DateTime retroAt,
      required DecisionStatus status,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$DecisionsTableUpdateCompanionBuilder =
    DecisionsCompanion Function({
      Value<String> id,
      Value<String> textContent,
      Value<DateTime> createdAt,
      Value<DriverType> driver,
      Value<ValueItem?> gain,
      Value<ValueItem?> lose,
      Value<String?> note,
      Value<RetroOffsetType> retroOffsetType,
      Value<DateTime> retroAt,
      Value<DecisionStatus> status,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

final class $$DecisionsTableReferences
    extends BaseReferences<_$AppDatabase, $DecisionsTable, Decision> {
  $$DecisionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReviewsTable, List<Review>> _reviewsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.reviews,
    aliasName: $_aliasNameGenerator(db.decisions.id, db.reviews.logId),
  );

  $$ReviewsTableProcessedTableManager get reviewsRefs {
    final manager = $$ReviewsTableTableManager(
      $_db,
      $_db.reviews,
    ).filter((f) => f.logId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeclarationsTable, List<Declaration>>
  _declarationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.declarations,
    aliasName: $_aliasNameGenerator(db.decisions.id, db.declarations.logId),
  );

  $$DeclarationsTableProcessedTableManager get declarationsRefs {
    final manager = $$DeclarationsTableTableManager(
      $_db,
      $_db.declarations,
    ).filter((f) => f.logId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_declarationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecisionsTableFilterComposer
    extends Composer<_$AppDatabase, $DecisionsTable> {
  $$DecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DriverType, DriverType, int> get driver =>
      $composableBuilder(
        column: $table.driver,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ValueItem?, ValueItem, int> get gain =>
      $composableBuilder(
        column: $table.gain,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ValueItem?, ValueItem, int> get lose =>
      $composableBuilder(
        column: $table.lose,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetroOffsetType, RetroOffsetType, int>
  get retroOffsetType => $composableBuilder(
    column: $table.retroOffsetType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get retroAt => $composableBuilder(
    column: $table.retroAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DecisionStatus, DecisionStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reviewsRefs(
    Expression<bool> Function($$ReviewsTableFilterComposer f) f,
  ) {
    final $$ReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableFilterComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> declarationsRefs(
    Expression<bool> Function($$DeclarationsTableFilterComposer f) f,
  ) {
    final $$DeclarationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.declarations,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeclarationsTableFilterComposer(
            $db: $db,
            $table: $db.declarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DecisionsTable> {
  $$DecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get driver => $composableBuilder(
    column: $table.driver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gain => $composableBuilder(
    column: $table.gain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lose => $composableBuilder(
    column: $table.lose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retroOffsetType => $composableBuilder(
    column: $table.retroOffsetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retroAt => $composableBuilder(
    column: $table.retroAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecisionsTable> {
  $$DecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DriverType, int> get driver =>
      $composableBuilder(column: $table.driver, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ValueItem?, int> get gain =>
      $composableBuilder(column: $table.gain, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ValueItem?, int> get lose =>
      $composableBuilder(column: $table.lose, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RetroOffsetType, int> get retroOffsetType =>
      $composableBuilder(
        column: $table.retroOffsetType,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get retroAt =>
      $composableBuilder(column: $table.retroAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DecisionStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  Expression<T> reviewsRefs<T extends Object>(
    Expression<T> Function($$ReviewsTableAnnotationComposer a) f,
  ) {
    final $$ReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> declarationsRefs<T extends Object>(
    Expression<T> Function($$DeclarationsTableAnnotationComposer a) f,
  ) {
    final $$DeclarationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.declarations,
      getReferencedColumn: (t) => t.logId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeclarationsTableAnnotationComposer(
            $db: $db,
            $table: $db.declarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecisionsTable,
          Decision,
          $$DecisionsTableFilterComposer,
          $$DecisionsTableOrderingComposer,
          $$DecisionsTableAnnotationComposer,
          $$DecisionsTableCreateCompanionBuilder,
          $$DecisionsTableUpdateCompanionBuilder,
          (Decision, $$DecisionsTableReferences),
          Decision,
          PrefetchHooks Function({bool reviewsRefs, bool declarationsRefs})
        > {
  $$DecisionsTableTableManager(_$AppDatabase db, $DecisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> textContent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DriverType> driver = const Value.absent(),
                Value<ValueItem?> gain = const Value.absent(),
                Value<ValueItem?> lose = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<RetroOffsetType> retroOffsetType = const Value.absent(),
                Value<DateTime> retroAt = const Value.absent(),
                Value<DecisionStatus> status = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecisionsCompanion(
                id: id,
                textContent: textContent,
                createdAt: createdAt,
                driver: driver,
                gain: gain,
                lose: lose,
                note: note,
                retroOffsetType: retroOffsetType,
                retroAt: retroAt,
                status: status,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String textContent,
                required DateTime createdAt,
                required DriverType driver,
                Value<ValueItem?> gain = const Value.absent(),
                Value<ValueItem?> lose = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required RetroOffsetType retroOffsetType,
                required DateTime retroAt,
                required DecisionStatus status,
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => DecisionsCompanion.insert(
                id: id,
                textContent: textContent,
                createdAt: createdAt,
                driver: driver,
                gain: gain,
                lose: lose,
                note: note,
                retroOffsetType: retroOffsetType,
                retroAt: retroAt,
                status: status,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DecisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({reviewsRefs = false, declarationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewsRefs) db.reviews,
                    if (declarationsRefs) db.declarations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewsRefs)
                        await $_getPrefetchedData<
                          Decision,
                          $DecisionsTable,
                          Review
                        >(
                          currentTable: table,
                          referencedTable: $$DecisionsTableReferences
                              ._reviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecisionsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.logId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (declarationsRefs)
                        await $_getPrefetchedData<
                          Decision,
                          $DecisionsTable,
                          Declaration
                        >(
                          currentTable: table,
                          referencedTable: $$DecisionsTableReferences
                              ._declarationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DecisionsTableReferences(
                                db,
                                table,
                                p0,
                              ).declarationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.logId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecisionsTable,
      Decision,
      $$DecisionsTableFilterComposer,
      $$DecisionsTableOrderingComposer,
      $$DecisionsTableAnnotationComposer,
      $$DecisionsTableCreateCompanionBuilder,
      $$DecisionsTableUpdateCompanionBuilder,
      (Decision, $$DecisionsTableReferences),
      Decision,
      PrefetchHooks Function({bool reviewsRefs, bool declarationsRefs})
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      required String logId,
      required DateTime reviewedAt,
      required ExecutionStatus execution,
      required int convictionScore,
      required bool wouldRepeat,
      Value<AdjustmentType?> adjustment,
      Value<RegretLevel?> regretLevel,
      Value<String?> reasonKey,
      Value<String?> solution,
      Value<String?> successFactor,
      Value<String?> reproductionStrategy,
      Value<String?> memo,
      Value<int> rowid,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<String> logId,
      Value<DateTime> reviewedAt,
      Value<ExecutionStatus> execution,
      Value<int> convictionScore,
      Value<bool> wouldRepeat,
      Value<AdjustmentType?> adjustment,
      Value<RegretLevel?> regretLevel,
      Value<String?> reasonKey,
      Value<String?> solution,
      Value<String?> successFactor,
      Value<String?> reproductionStrategy,
      Value<String?> memo,
      Value<int> rowid,
    });

final class $$ReviewsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewsTable, Review> {
  $$ReviewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecisionsTable _logIdTable(_$AppDatabase db) => db.decisions
      .createAlias($_aliasNameGenerator(db.reviews.logId, db.decisions.id));

  $$DecisionsTableProcessedTableManager get logId {
    final $_column = $_itemColumn<String>('log_id')!;

    final manager = $$DecisionsTableTableManager(
      $_db,
      $_db.decisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_logIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExecutionStatus, ExecutionStatus, int>
  get execution => $composableBuilder(
    column: $table.execution,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get convictionScore => $composableBuilder(
    column: $table.convictionScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AdjustmentType?, AdjustmentType, int>
  get adjustment => $composableBuilder(
    column: $table.adjustment,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RegretLevel?, RegretLevel, int>
  get regretLevel => $composableBuilder(
    column: $table.regretLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reasonKey => $composableBuilder(
    column: $table.reasonKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get successFactor => $composableBuilder(
    column: $table.successFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reproductionStrategy => $composableBuilder(
    column: $table.reproductionStrategy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  $$DecisionsTableFilterComposer get logId {
    final $$DecisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableFilterComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get execution => $composableBuilder(
    column: $table.execution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get convictionScore => $composableBuilder(
    column: $table.convictionScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustment => $composableBuilder(
    column: $table.adjustment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get regretLevel => $composableBuilder(
    column: $table.regretLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonKey => $composableBuilder(
    column: $table.reasonKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get successFactor => $composableBuilder(
    column: $table.successFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reproductionStrategy => $composableBuilder(
    column: $table.reproductionStrategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecisionsTableOrderingComposer get logId {
    final $$DecisionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableOrderingComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExecutionStatus, int> get execution =>
      $composableBuilder(column: $table.execution, builder: (column) => column);

  GeneratedColumn<int> get convictionScore => $composableBuilder(
    column: $table.convictionScore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wouldRepeat => $composableBuilder(
    column: $table.wouldRepeat,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AdjustmentType?, int> get adjustment =>
      $composableBuilder(
        column: $table.adjustment,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<RegretLevel?, int> get regretLevel =>
      $composableBuilder(
        column: $table.regretLevel,
        builder: (column) => column,
      );

  GeneratedColumn<String> get reasonKey =>
      $composableBuilder(column: $table.reasonKey, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumn<String> get successFactor => $composableBuilder(
    column: $table.successFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reproductionStrategy => $composableBuilder(
    column: $table.reproductionStrategy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  $$DecisionsTableAnnotationComposer get logId {
    final $$DecisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewsTable,
          Review,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (Review, $$ReviewsTableReferences),
          Review,
          PrefetchHooks Function({bool logId})
        > {
  $$ReviewsTableTableManager(_$AppDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> logId = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<ExecutionStatus> execution = const Value.absent(),
                Value<int> convictionScore = const Value.absent(),
                Value<bool> wouldRepeat = const Value.absent(),
                Value<AdjustmentType?> adjustment = const Value.absent(),
                Value<RegretLevel?> regretLevel = const Value.absent(),
                Value<String?> reasonKey = const Value.absent(),
                Value<String?> solution = const Value.absent(),
                Value<String?> successFactor = const Value.absent(),
                Value<String?> reproductionStrategy = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion(
                logId: logId,
                reviewedAt: reviewedAt,
                execution: execution,
                convictionScore: convictionScore,
                wouldRepeat: wouldRepeat,
                adjustment: adjustment,
                regretLevel: regretLevel,
                reasonKey: reasonKey,
                solution: solution,
                successFactor: successFactor,
                reproductionStrategy: reproductionStrategy,
                memo: memo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String logId,
                required DateTime reviewedAt,
                required ExecutionStatus execution,
                required int convictionScore,
                required bool wouldRepeat,
                Value<AdjustmentType?> adjustment = const Value.absent(),
                Value<RegretLevel?> regretLevel = const Value.absent(),
                Value<String?> reasonKey = const Value.absent(),
                Value<String?> solution = const Value.absent(),
                Value<String?> successFactor = const Value.absent(),
                Value<String?> reproductionStrategy = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion.insert(
                logId: logId,
                reviewedAt: reviewedAt,
                execution: execution,
                convictionScore: convictionScore,
                wouldRepeat: wouldRepeat,
                adjustment: adjustment,
                regretLevel: regretLevel,
                reasonKey: reasonKey,
                solution: solution,
                successFactor: successFactor,
                reproductionStrategy: reproductionStrategy,
                memo: memo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({logId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (logId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.logId,
                                referencedTable: $$ReviewsTableReferences
                                    ._logIdTable(db),
                                referencedColumn: $$ReviewsTableReferences
                                    ._logIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewsTable,
      Review,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (Review, $$ReviewsTableReferences),
      Review,
      PrefetchHooks Function({bool logId})
    >;
typedef $$DeclarationsTableCreateCompanionBuilder =
    DeclarationsCompanion Function({
      Value<int> id,
      required String logId,
      required String originalText,
      required String reasonLabel,
      required String solutionText,
      required String declarationText,
      required DateTime reviewAt,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<DeclarationStatus> status,
      Value<int?> parentId,
      Value<ActionReviewStatus?> lastReviewStatus,
    });
typedef $$DeclarationsTableUpdateCompanionBuilder =
    DeclarationsCompanion Function({
      Value<int> id,
      Value<String> logId,
      Value<String> originalText,
      Value<String> reasonLabel,
      Value<String> solutionText,
      Value<String> declarationText,
      Value<DateTime> reviewAt,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<DeclarationStatus> status,
      Value<int?> parentId,
      Value<ActionReviewStatus?> lastReviewStatus,
    });

final class $$DeclarationsTableReferences
    extends BaseReferences<_$AppDatabase, $DeclarationsTable, Declaration> {
  $$DeclarationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecisionsTable _logIdTable(_$AppDatabase db) =>
      db.decisions.createAlias(
        $_aliasNameGenerator(db.declarations.logId, db.decisions.id),
      );

  $$DecisionsTableProcessedTableManager get logId {
    final $_column = $_itemColumn<String>('log_id')!;

    final manager = $$DecisionsTableTableManager(
      $_db,
      $_db.decisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_logIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeclarationsTableFilterComposer
    extends Composer<_$AppDatabase, $DeclarationsTable> {
  $$DeclarationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonLabel => $composableBuilder(
    column: $table.reasonLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solutionText => $composableBuilder(
    column: $table.solutionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get declarationText => $composableBuilder(
    column: $table.declarationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewAt => $composableBuilder(
    column: $table.reviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeclarationStatus, DeclarationStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActionReviewStatus?, ActionReviewStatus, int>
  get lastReviewStatus => $composableBuilder(
    column: $table.lastReviewStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$DecisionsTableFilterComposer get logId {
    final $$DecisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableFilterComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeclarationsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeclarationsTable> {
  $$DeclarationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonLabel => $composableBuilder(
    column: $table.reasonLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solutionText => $composableBuilder(
    column: $table.solutionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get declarationText => $composableBuilder(
    column: $table.declarationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewAt => $composableBuilder(
    column: $table.reviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewStatus => $composableBuilder(
    column: $table.lastReviewStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecisionsTableOrderingComposer get logId {
    final $$DecisionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableOrderingComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeclarationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeclarationsTable> {
  $$DeclarationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonLabel => $composableBuilder(
    column: $table.reasonLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get solutionText => $composableBuilder(
    column: $table.solutionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get declarationText => $composableBuilder(
    column: $table.declarationText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewAt =>
      $composableBuilder(column: $table.reviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DeclarationStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActionReviewStatus?, int>
  get lastReviewStatus => $composableBuilder(
    column: $table.lastReviewStatus,
    builder: (column) => column,
  );

  $$DecisionsTableAnnotationComposer get logId {
    final $$DecisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.logId,
      referencedTable: $db.decisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.decisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeclarationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeclarationsTable,
          Declaration,
          $$DeclarationsTableFilterComposer,
          $$DeclarationsTableOrderingComposer,
          $$DeclarationsTableAnnotationComposer,
          $$DeclarationsTableCreateCompanionBuilder,
          $$DeclarationsTableUpdateCompanionBuilder,
          (Declaration, $$DeclarationsTableReferences),
          Declaration,
          PrefetchHooks Function({bool logId})
        > {
  $$DeclarationsTableTableManager(_$AppDatabase db, $DeclarationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeclarationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeclarationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeclarationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> logId = const Value.absent(),
                Value<String> originalText = const Value.absent(),
                Value<String> reasonLabel = const Value.absent(),
                Value<String> solutionText = const Value.absent(),
                Value<String> declarationText = const Value.absent(),
                Value<DateTime> reviewAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DeclarationStatus> status = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<ActionReviewStatus?> lastReviewStatus =
                    const Value.absent(),
              }) => DeclarationsCompanion(
                id: id,
                logId: logId,
                originalText: originalText,
                reasonLabel: reasonLabel,
                solutionText: solutionText,
                declarationText: declarationText,
                reviewAt: reviewAt,
                createdAt: createdAt,
                completedAt: completedAt,
                status: status,
                parentId: parentId,
                lastReviewStatus: lastReviewStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String logId,
                required String originalText,
                required String reasonLabel,
                required String solutionText,
                required String declarationText,
                required DateTime reviewAt,
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DeclarationStatus> status = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<ActionReviewStatus?> lastReviewStatus =
                    const Value.absent(),
              }) => DeclarationsCompanion.insert(
                id: id,
                logId: logId,
                originalText: originalText,
                reasonLabel: reasonLabel,
                solutionText: solutionText,
                declarationText: declarationText,
                reviewAt: reviewAt,
                createdAt: createdAt,
                completedAt: completedAt,
                status: status,
                parentId: parentId,
                lastReviewStatus: lastReviewStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeclarationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({logId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (logId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.logId,
                                referencedTable: $$DeclarationsTableReferences
                                    ._logIdTable(db),
                                referencedColumn: $$DeclarationsTableReferences
                                    ._logIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeclarationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeclarationsTable,
      Declaration,
      $$DeclarationsTableFilterComposer,
      $$DeclarationsTableOrderingComposer,
      $$DeclarationsTableAnnotationComposer,
      $$DeclarationsTableCreateCompanionBuilder,
      $$DeclarationsTableUpdateCompanionBuilder,
      (Declaration, $$DeclarationsTableReferences),
      Declaration,
      PrefetchHooks Function({bool logId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecisionsTableTableManager get decisions =>
      $$DecisionsTableTableManager(_db, _db.decisions);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
  $$DeclarationsTableTableManager get declarations =>
      $$DeclarationsTableTableManager(_db, _db.declarations);
}

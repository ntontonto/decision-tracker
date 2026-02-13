enum DriverType {
  pleasure,
  curiosity,
  expression,
  investment,
  habit,
  requested,
  reputation,
  guilt;

  String get label {
    switch (this) {
      case DriverType.pleasure: return '快楽';
      case DriverType.curiosity: return '好奇心';
      case DriverType.expression: return '自分らしさ表現';
      case DriverType.investment: return '自己投資';
      case DriverType.habit: return 'いつもの流れで';
      case DriverType.requested: return '周囲に命令やお願いされたから';
      case DriverType.reputation: return '周囲の評価を気にして';
      case DriverType.guilt: return '罪悪感を減らすため';
    }
  }
}

enum GainType {
  skills,
  money,
  time,
  relationships,
  reputation,
  fun,
  rest,
  peace,
  mentalMargine;

  String get label {
    switch (this) {
      case GainType.skills: return '知識・スキル';
      case GainType.money: return 'お金';
      case GainType.time: return '時間';
      case GainType.relationships: return '人間関係';
      case GainType.reputation: return '評判・信用';
      case GainType.fun: return '楽しさ';
      case GainType.rest: return '休息';
      case GainType.peace: return '安心';
      case GainType.mentalMargine: return '精神的余裕';
    }
  }
}

enum LoseType {
  time,
  money,
  freedom,
  energy,
  health,
  relationships,
  mentalMargine;

  String get label {
    switch (this) {
      case LoseType.time: return '時間';
      case LoseType.money: return 'お金';
      case LoseType.freedom: return '自由';
      case LoseType.energy: return '体力';
      case LoseType.health: return '健康';
      case LoseType.relationships: return '人間関係';
      case LoseType.mentalMargine: return '精神的余裕';
    }
  }
}

enum RetroOffsetType {
  now,
  tonight,
  tomorrow,
  plus3days,
  plus1week,
  plus2weeks,
  plus1month,
  plus3monthsPlus; // Pro

  String get label {
    switch (this) {
      case RetroOffsetType.now: return '今';
      case RetroOffsetType.tonight: return '今日の夜';
      case RetroOffsetType.tomorrow: return '明日';
      case RetroOffsetType.plus3days: return '3日後';
      case RetroOffsetType.plus1week: return '1週間後';
      case RetroOffsetType.plus2weeks: return '2週間後';
      case RetroOffsetType.plus1month: return '1ヶ月後';
      case RetroOffsetType.plus3monthsPlus: return '3ヶ月以上';
    }
  }
}

enum DecisionStatus {
  pending,
  reviewed;
}

enum ExecutionStatus {
  yes,
  partial,
  no;

  String get label {
    switch (this) {
      case ExecutionStatus.yes: return 'Yes';
      case ExecutionStatus.partial: return '部分的';
      case ExecutionStatus.no: return 'No';
    }
  }
}

enum AdjustmentType {
  lowerGoal,
  breakDown,
  changeEnvironment,
  hold;

  String get label {
    switch (this) {
      case AdjustmentType.lowerGoal: return '目標を下げる';
      case AdjustmentType.breakDown: return '分解する';
      case AdjustmentType.changeEnvironment: return '環境を変える';
      case AdjustmentType.hold: return '保留（今は決めない）';
    }
  }
}

enum RegretLevel {
  none,
  aLittle,
  much;

  String get label {
    switch (this) {
      case RegretLevel.none: return 'ない';
      case RegretLevel.aLittle: return '少しある';
      case RegretLevel.much: return 'ある';
    }
  }
}

enum DeclarationStatus {
  active,
  completed,
  superseded;
}

enum ActionReviewStatus {
  success,
  failed,
  dropped;

  String get label {
    switch (this) {
      case ActionReviewStatus.success: return '実践できた';
      case ActionReviewStatus.failed: return '実践できなかった';
      case ActionReviewStatus.dropped: return '中断した';
    }
  }
}

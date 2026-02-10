enum DriverType {
  intrinsic,
  extrinsic,
  avoidance,
  maintenance,
  exploration;

  String get label {
    switch (this) {
      case DriverType.intrinsic: return '内発';
      case DriverType.extrinsic: return '外発';
      case DriverType.avoidance: return '回避';
      case DriverType.maintenance: return '維持';
      case DriverType.exploration: return '探索';
    }
  }
}

enum GainType {
  growth,
  progress,
  money,
  reputation,
  peaceOfMind,
  fun,
  rest,
  relationship;

  String get label {
    switch (this) {
      case GainType.growth: return '成長';
      case GainType.progress: return '進捗';
      case GainType.money: return 'お金';
      case GainType.reputation: return '評判';
      case GainType.peaceOfMind: return '安心';
      case GainType.fun: return '楽しさ';
      case GainType.rest: return '休息';
      case GainType.relationship: return '関係性';
    }
  }
}

enum LoseType {
  time,
  focus,
  energy,
  freedom,
  certainty,
  money,
  reputation,
  relationship;

  String get label {
    switch (this) {
      case LoseType.time: return '時間';
      case LoseType.focus: return '集中';
      case LoseType.energy: return '体力';
      case LoseType.freedom: return '自由';
      case LoseType.certainty: return '確実性';
      case LoseType.money: return 'お金';
      case LoseType.reputation: return '評判';
      case LoseType.relationship: return '関係性';
    }
  }
}

enum RetroOffsetType {
  today,
  tomorrow,
  plus3days,
  plus1week,
  plus2weeks,
  plus1month,
  custom, // Pro
  plus3monthsPlus; // Pro

  String get label {
    switch (this) {
      case RetroOffsetType.today: return '今日';
      case RetroOffsetType.tomorrow: return '明日';
      case RetroOffsetType.plus3days: return '3日後';
      case RetroOffsetType.plus1week: return '1週間後';
      case RetroOffsetType.plus2weeks: return '2週間後';
      case RetroOffsetType.plus1month: return '1ヶ月後';
      case RetroOffsetType.custom: return 'カスタム日付';
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

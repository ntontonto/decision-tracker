import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case DriverType.pleasure: return Icons.sentiment_satisfied;
      case DriverType.curiosity: return Icons.lightbulb_outline;
      case DriverType.expression: return Icons.palette;
      case DriverType.investment: return Icons.trending_up;
      case DriverType.habit: return Icons.repeat;
      case DriverType.requested: return Icons.person_outline;
      case DriverType.reputation: return Icons.visibility;
      case DriverType.guilt: return Icons.psychology_alt;
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

  int get score {
    switch (this) {
      case RegretLevel.none: return 5;
      case RegretLevel.aLittle: return 3;
      case RegretLevel.much: return 1;
    }
  }
}

enum DeclarationStatus {
  active,
  completed,
  superseded;
}

// ActionReviewStatus removed in favor of RegretLevel

enum ValueItem {
  skills,
  money,
  time,
  relationships,
  reputation,
  fun,
  rest,
  peace,
  mentalMargine,
  freedom,
  energy,
  health;

  String get label {
    switch (this) {
      case ValueItem.skills: return '知識・スキル';
      case ValueItem.money: return 'お金';
      case ValueItem.time: return '時間';
      case ValueItem.relationships: return '人間関係';
      case ValueItem.reputation: return '評判・信用';
      case ValueItem.fun: return '楽しさ';
      case ValueItem.rest: return '休息';
      case ValueItem.peace: return '安心';
      case ValueItem.mentalMargine: return '精神的余裕';
      case ValueItem.freedom: return '自由';
      case ValueItem.energy: return '体力';
      case ValueItem.health: return '健康';
    }
  }

  IconData get icon {
    switch (this) {
      case ValueItem.skills: return Icons.psychology;
      case ValueItem.money: return Icons.payments;
      case ValueItem.time: return Icons.history;
      case ValueItem.relationships: return Icons.groups;
      case ValueItem.reputation: return Icons.verified;
      case ValueItem.fun: return Icons.celebration;
      case ValueItem.rest: return Icons.bedtime;
      case ValueItem.peace: return Icons.vaping_rooms;
      case ValueItem.mentalMargine: return Icons.self_improvement;
      case ValueItem.freedom: return Icons.lock;
      case ValueItem.energy: return Icons.battery_alert;
      case ValueItem.health: return Icons.favorite_border;
    }
  }
}

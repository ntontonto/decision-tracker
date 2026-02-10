import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../data/repositories/decision_repository.dart';
import '../../domain/models/enums.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final repositoryProvider = Provider<DecisionRepository>((ref) {
  return DecisionRepository(ref.watch(databaseProvider));
});

// --- Wizard State ---

class LogWizardState {
  final String text;
  final DriverType? driver;
  final GainType? gain;
  final LoseType? lose;
  final String? note;
  final RetroOffsetType? retroOffset;
  final Decision? previousDecision;

  LogWizardState({
    this.text = '',
    this.driver,
    this.gain,
    this.lose,
    this.note,
    this.retroOffset,
    this.previousDecision,
  });

  LogWizardState copyWith({
    String? text,
    DriverType? Function()? driver,
    GainType? Function()? gain,
    LoseType? Function()? lose,
    String? Function()? note,
    RetroOffsetType? Function()? retroOffset,
    Decision? Function()? previousDecision,
  }) {
    return LogWizardState(
      text: text ?? this.text,
      driver: driver != null ? driver() : this.driver,
      gain: gain != null ? gain() : this.gain,
      lose: lose != null ? lose() : this.lose,
      note: note != null ? note() : this.note,
      retroOffset: retroOffset != null ? retroOffset() : this.retroOffset,
      previousDecision: previousDecision != null ? previousDecision() : this.previousDecision,
    );
  }
}

class LogWizardNotifier extends StateNotifier<LogWizardState> {
  final DecisionRepository repository;
  final Ref ref;

  LogWizardNotifier(this.repository, this.ref) : super(LogWizardState());

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  void selectSuggestion(Decision decision) {
    state = state.copyWith(
      text: decision.textContent,
      driver: () => decision.driver,
      gain: () => decision.gain,
      lose: () => decision.lose,
      note: () => decision.note,
      retroOffset: () => decision.retroOffsetType,
      previousDecision: () => decision,
    );
  }

  void updateDriver(DriverType? driver) => state = state.copyWith(driver: () => driver);
  void updateGain(GainType? gain) => state = state.copyWith(gain: () => gain);
  void updateLose(LoseType? lose) => state = state.copyWith(lose: () => lose);
  void updateNote(String? note) => state = state.copyWith(note: () => note);
  void updateRetroOffset(RetroOffsetType? offset) => state = state.copyWith(retroOffset: () => offset);

  Future<void> save() async {
    if (state.text.isEmpty || state.driver == null || state.retroOffset == null) return;

    final retroAt = _calculateRetroAt(state.retroOffset!);
    
    await repository.createDecision(
      text: state.text,
      driver: state.driver!,
      gain: state.gain,
      lose: state.lose,
      note: state.note,
      retroOffset: state.retroOffset!,
      retroAt: retroAt,
    );
    
    // Invalidate providers to refresh other screens
    ref.invalidate(allDecisionsProvider);
    ref.invalidate(pendingDecisionsProvider);
    
    reset();
  }

  void reset() {
    state = LogWizardState();
  }

  DateTime _calculateRetroAt(RetroOffsetType type) {
    final now = DateTime.now();
    // Normalize to 21:00 as per requirement
    final today21 = DateTime(now.year, now.month, now.day, 21);
    
    switch (type) {
      case RetroOffsetType.today:
        return today21;
      case RetroOffsetType.tomorrow:
        return today21.add(const Duration(days: 1));
      case RetroOffsetType.plus3days:
        return today21.add(const Duration(days: 3));
      case RetroOffsetType.plus1week:
        return today21.add(const Duration(days: 7));
      case RetroOffsetType.plus2weeks:
        return today21.add(const Duration(days: 14));
      case RetroOffsetType.plus1month:
        return DateTime(today21.year, today21.month + 1, today21.day, 21);
      default:
        return today21;
    }
  }
}

final logWizardProvider = StateNotifierProvider<LogWizardNotifier, LogWizardState>((ref) {
  return LogWizardNotifier(ref.watch(repositoryProvider), ref);
});

// --- Suggestions ---

final searchSuggestionsProvider = FutureProvider.family<List<Decision>, String>((ref, query) {
  return ref.watch(repositoryProvider).searchDecisions(query);
});

// --- Retro Providers ---

final pendingDecisionsProvider = FutureProvider<List<Decision>>((ref) {
  return ref.watch(repositoryProvider).getPendingDecisions();
});

final allDecisionsProvider = FutureProvider<List<Decision>>((ref) {
  return ref.watch(repositoryProvider).getAllDecisions();
});

final reviewForLogProvider = FutureProvider.family<Review?, String>((ref, id) {
  return ref.watch(repositoryProvider).getReviewForLog(id);
});

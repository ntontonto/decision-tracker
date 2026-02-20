import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/date_utils.dart';
import '../../data/local/database.dart';
import '../../data/repositories/decision_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/review_proposal.dart';
import 'reaction_providers.dart';
import 'settings_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final decisionRepositoryProvider = Provider<DecisionRepository>((ref) {
  return DecisionRepository(
    ref.watch(databaseProvider),
    getNotificationTime: () => ref.read(settingsProvider).notificationTime,
    areNotificationsEnabled: () => ref.read(settingsProvider).notificationsEnabled,
  );
});

// --- Wizard State ---

class LogWizardState {
  final String text;
  final DriverType? driver;
  final ValueItem? gain;
  final ValueItem? lose;
  final String? note;
  final RetroOffsetType? retroOffset;
  final Decision? previousDecision;
  final String? editingId;

  LogWizardState({
    this.text = '',
    this.driver,
    this.gain,
    this.lose,
    this.note,
    this.retroOffset,
    this.previousDecision,
    this.editingId,
  });

  LogWizardState copyWith({
    String? text,
    DriverType? Function()? driver,
    ValueItem? Function()? gain,
    ValueItem? Function()? lose,
    String? Function()? note,
    RetroOffsetType? Function()? retroOffset,
    Decision? Function()? previousDecision,
    String? Function()? editingId,
  }) {
    return LogWizardState(
      text: text ?? this.text,
      driver: driver != null ? driver() : this.driver,
      gain: gain != null ? gain() : this.gain,
      lose: lose != null ? lose() : this.lose,
      note: note != null ? note() : this.note,
      retroOffset: retroOffset != null ? retroOffset() : this.retroOffset,
      previousDecision: previousDecision != null ? previousDecision() : this.previousDecision,
      editingId: editingId != null ? editingId() : this.editingId,
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
  void updateGain(ValueItem? gain) => state = state.copyWith(gain: () => gain);
  void updateLose(ValueItem? lose) => state = state.copyWith(lose: () => lose);
  void updateNote(String? note) => state = state.copyWith(note: () => note);
  void updateRetroOffset(RetroOffsetType? offset) => state = state.copyWith(retroOffset: () => offset);

  Future<String?> save() async {
    if (state.text.isEmpty || state.driver == null || state.retroOffset == null) return null;

    final retroAt = _calculateRetroAt(state.retroOffset!);
    String? id;

    try {
      if (state.editingId != null) {
        debugPrint('DEBUG: Calling repository.updateDecision for id: ${state.editingId}');
        await repository.updateDecision(
          id: state.editingId!,
          text: state.text,
          driver: state.driver!,
          gain: state.gain,
          lose: state.lose,
          note: state.note,
          retroOffset: state.retroOffset!,
          retroAt: retroAt,
        );
        id = state.editingId;
        debugPrint('DEBUG: repository.updateDecision completed for id: $id');
      } else {
        debugPrint('DEBUG: Calling repository.createDecision with text: ${state.text}');
        id = await repository.createDecision(
          text: state.text,
          driver: state.driver!,
          gain: state.gain,
          lose: state.lose,
          note: state.note,
          retroOffset: state.retroOffset!,
          retroAt: retroAt,
        );
        debugPrint('DEBUG: repository.createDecision returned id: $id');
      }
      
      debugPrint('DEBUG: Invalidating providers...');
      // Invalidate providers to refresh other screens
      ref.invalidate(allDecisionsProvider);
      ref.invalidate(pendingDecisionsProvider);
      
      debugPrint('DEBUG: Resetting wizard state...');
      reset();
      debugPrint('DEBUG: Save process complete. Returning id: $id');
      return id;
    } catch (e, stack) {
      debugPrint('DEBUG: ERROR DURING SAVE: $e');
      debugPrint('DEBUG: STACK TRACE: $stack');
      rethrow;
    }
  }

  void restore(LogWizardState status) {
    state = status;
  }

  void reset() {
    state = LogWizardState();
  }

  DateTime _calculateRetroAt(RetroOffsetType type) {
    final now = DateTime.now();
    // Normalize to 21:00 as per requirement
    final today21 = DateTime(now.year, now.month, now.day, 21);
    
    switch (type) {
      case RetroOffsetType.now:
        return now;
      case RetroOffsetType.tonight:
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
      case RetroOffsetType.plus3monthsPlus:
        return DateTime(today21.year, today21.month + 3, today21.day, 21);
    }
  }
}

final logWizardProvider = StateNotifierProvider<LogWizardNotifier, LogWizardState>((ref) {
  return LogWizardNotifier(ref.watch(decisionRepositoryProvider), ref);
});

// --- Suggestions ---

final searchSuggestionsProvider = FutureProvider.family<List<Decision>, String>((ref, query) {
  return ref.watch(decisionRepositoryProvider).searchDecisions(query);
});

// --- Retro Providers ---

final pendingDecisionsProvider = FutureProvider<List<Decision>>((ref) {
  return ref.watch(decisionRepositoryProvider).getPendingDecisions();
});

final pendingDeclarationsProvider = FutureProvider<List<Declaration>>((ref) {
  return ref.watch(decisionRepositoryProvider).getPendingDeclarations();
});

final unifiedProposalsProvider = FutureProvider<List<ReviewProposal>>((ref) async {
  final decisions = await ref.watch(pendingDecisionsProvider.future);
  final declarations = await ref.watch(pendingDeclarationsProvider.future);
  
  final List<ReviewProposal> allProposals = [
    ...decisions.map((d) {
      final relativeDate = AppDateUtils.getRelativeDateString(d.createdAt);
      return ReviewProposal(
        id: d.id,
        title: '$relativeDateの出来事を振り返る？',
        description: d.textContent,
        targetDate: d.retroAt,
        type: ProposalType.decisionRetro,
        originalData: d,
      );
    }),
    ...declarations.map((d) {
      final relativeDate = AppDateUtils.getRelativeDateString(d.createdAt);
      return ReviewProposal(
        id: d.id.toString(),
        title: '$relativeDateに決めた実践を振り返る？',
        description: d.declarationText,
        targetDate: d.reviewAt,
        type: ProposalType.actionReview,
        originalData: d,
      );
    }),
  ];

  // Filter by unified time window
  final proposals = allProposals.where((p) => p.isReviewableNow).toList();

  // Sort by targetDate (oldest first to ensure they get reviewed)
  proposals.sort((a, b) => a.targetDate.compareTo(b.targetDate));
  
  return proposals;
});

final allDecisionsProvider = FutureProvider<List<Decision>>((ref) {
  return ref.watch(decisionRepositoryProvider).getAllDecisions();
});

final allDecisionsStreamProvider = StreamProvider<List<Decision>>((ref) {
  return ref.watch(decisionRepositoryProvider).watchDecisions();
});

// Obsolete: reviewForLogProvider and allReviewsProvider removed as reviews are integrated into decisions

// --- Success Notification ---

class SuccessNotificationState {
  final bool isVisible;
  final String message;
  final IconData? icon;
  final void Function(BuildContext, WidgetRef)? onFix;

  SuccessNotificationState({
    this.isVisible = false,
    this.message = '',
    this.icon,
    this.onFix,
  });
}

class SuccessNotificationNotifier extends StateNotifier<SuccessNotificationState> {
  final Ref ref;
  Timer? _timer;

  SuccessNotificationNotifier(this.ref) : super(SuccessNotificationState());

  void show({
    required String message, 
    IconData? icon,
    ParticleReaction reaction = ParticleReaction.celebrate,
    void Function(BuildContext, WidgetRef)? onFix,
  }) {
    _timer?.cancel();
    state = SuccessNotificationState(
      isVisible: true, 
      message: message, 
      icon: icon,
      onFix: onFix,
    );
    
    // Trigger specified reaction
    ref.read(reactionProvider.notifier).trigger(reaction);
    
    _timer = Timer(const Duration(seconds: 5), () {
      hide();
    });
  }

  void hide() {
    _timer?.cancel();
    state = SuccessNotificationState(isVisible: false);
  }
}

final successNotificationProvider = StateNotifierProvider<SuccessNotificationNotifier, SuccessNotificationState>((ref) {
  return SuccessNotificationNotifier(ref);
});

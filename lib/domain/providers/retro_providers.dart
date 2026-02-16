import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../models/enums.dart';
import 'app_providers.dart';

// --- JSON Models ---

class RetroReason {
  final String key;
  final String label;
  final String feedback;
  final List<String> solutions;

  RetroReason({
    required this.key,
    required this.label,
    required this.feedback,
    required this.solutions,
  });

  factory RetroReason.fromJson(Map<String, dynamic> json) {
    return RetroReason(
      key: json['key'],
      label: json['label'],
      feedback: json['feedback'],
      solutions: List<String>.from(json['solutions']),
    );
  }
}

class RetroMetadata {
  final List<RetroReason> reasons;

  RetroMetadata({required this.reasons});

  factory RetroMetadata.fromJson(Map<String, dynamic> json) {
    return RetroMetadata(
      reasons: (json['reasons'] as List)
          .map((r) => RetroReason.fromJson(r))
          .toList(),
    );
  }
}

// --- State ---

class RetroWizardState {
  final Decision? decision;
  final int currentStep;
  final RegretLevel? regretLevel;
  final String? reasonKey; // reason key
  final String? solution; // chosen solution
  final String? successFactor; // for no regret
  final String? reproductionStrategy; // for no regret
  final bool registerNextAction;
  final RetroMetadata? metadata;
  final bool isLoading;

  RetroWizardState({
    this.decision,
    this.currentStep = 0,
    this.regretLevel,
    this.reasonKey,
    this.solution,
    this.successFactor,
    this.reproductionStrategy,
    this.registerNextAction = false,
    this.metadata,
    this.isLoading = true,
  });

  RetroWizardState copyWith({
    Decision? decision,
    int? currentStep,
    RegretLevel? regretLevel,
    String? reasonKey,
    String? solution,
    String? successFactor,
    String? reproductionStrategy,
    bool? registerNextAction,
    RetroMetadata? metadata,
    bool? isLoading,
  }) {
    return RetroWizardState(
      decision: decision ?? this.decision,
      currentStep: currentStep ?? this.currentStep,
      regretLevel: regretLevel ?? this.regretLevel,
      reasonKey: reasonKey ?? this.reasonKey,
      solution: solution ?? this.solution,
      successFactor: successFactor ?? this.successFactor,
      reproductionStrategy: reproductionStrategy ?? this.reproductionStrategy,
      registerNextAction: registerNextAction ?? this.registerNextAction,
      metadata: metadata ?? this.metadata,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  RetroReason? get selectedReason {
    if (metadata == null || reasonKey == null) return null;
    return metadata!.reasons.firstWhere((r) => r.key == reasonKey);
  }
}

// --- Notifier ---

class RetroWizardNotifier extends StateNotifier<RetroWizardState> {
  final Ref ref;

  RetroWizardNotifier(this.ref) : super(RetroWizardState()) {
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final String response = await rootBundle.loadString('assets/retro_reason_map.json');
      final data = await json.decode(response);
      state = state.copyWith(metadata: RetroMetadata.fromJson(data), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void init(Decision decision) {
    state = RetroWizardState(decision: decision, metadata: state.metadata, isLoading: state.isLoading);
  }

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: (state.currentStep - 1).clamp(0, 10));

  void setRegretLevel(RegretLevel? level) {
    state = state.copyWith(regretLevel: level);
  }

  void setReasonKey(String? key) {
    state = state.copyWith(reasonKey: key);
  }

  void setSolution(String? sol) {
    state = state.copyWith(solution: sol);
    // Don't auto-advance on the last step
  }

  void setSuccessFactor(String? factor) {
    state = state.copyWith(successFactor: factor);
  }

  void setReproductionStrategy(String? strategy) {
    state = state.copyWith(reproductionStrategy: strategy);
    // Don't auto-advance on the last step
  }

  void setRegisterNextAction(bool val) {
    state = state.copyWith(registerNextAction: val);
  }

  Future<void> save() async {
    if (state.decision == null || state.regretLevel == null) return;

    await ref.read(decisionRepositoryProvider).createReview(
      logId: state.decision!.id,
      regretLevel: state.regretLevel!,
      reasonKey: state.reasonKey,
      solution: state.solution,
      successFactor: state.successFactor,
      reproductionStrategy: state.reproductionStrategy,
      memo: null, // Removed from UI
    );

    // Refresh providers
    ref.invalidate(pendingDecisionsProvider);
    ref.invalidate(allDecisionsProvider);
  }

  Future<void> skip() async {
    if (state.decision == null) return;
    await ref.read(decisionRepositoryProvider).skipDecision(state.decision!.id);
    ref.invalidate(pendingDecisionsProvider);
    ref.invalidate(allDecisionsProvider);
  }

  void reset() {
    state = RetroWizardState(metadata: state.metadata, isLoading: false);
  }
}

final retroWizardProvider = StateNotifierProvider<RetroWizardNotifier, RetroWizardState>((ref) {
  return RetroWizardNotifier(ref);
});

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
  final String? memo;
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
    this.memo,
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
    String? memo,
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
      memo: memo ?? this.memo,
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
    nextStep();
  }

  void setReasonKey(String? key) {
    state = state.copyWith(reasonKey: key);
    nextStep();
  }

  void setSolution(String? sol) {
    state = state.copyWith(solution: sol);
    nextStep();
  }

  void setSuccessFactor(String? factor) {
    state = state.copyWith(successFactor: factor);
    nextStep();
  }

  void setReproductionStrategy(String? strategy) {
    state = state.copyWith(reproductionStrategy: strategy);
    nextStep();
  }

  void updateMemo(String val) => state = state.copyWith(memo: val);

  void setRegisterNextAction(bool val) {
    state = state.copyWith(registerNextAction: val);
    // Don't auto-advance, save is triggered by the button in UI
  }

  Future<void> save() async {
    if (state.decision == null) return;

    await ref.read(repositoryProvider).createReview(
      logId: state.decision!.id,
      execution: ExecutionStatus.yes, // Default for new flow
      convictionScore: 10,           // Default for new flow
      wouldRepeat: state.regretLevel == RegretLevel.none,
      regretLevel: state.regretLevel,
      reasonKey: state.reasonKey,
      solution: state.solution,
      successFactor: state.successFactor,
      reproductionStrategy: state.reproductionStrategy,
      memo: state.memo,
    );

    // Refresh providers
    ref.invalidate(pendingDecisionsProvider);
    ref.invalidate(allDecisionsProvider);
    ref.invalidate(reviewForLogProvider(state.decision!.id));
  }
}

final retroWizardProvider = StateNotifierProvider<RetroWizardNotifier, RetroWizardState>((ref) {
  return RetroWizardNotifier(ref);
});

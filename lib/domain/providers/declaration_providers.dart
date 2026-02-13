import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';
import 'app_providers.dart';

class DeclarationWizardState {
  final Decision? decision;
  final String? reasonLabel;
  final String? solutionText;
  
  final int currentStep;
  final String declarationText;
  final String? selectedIntervalKey;
  final DateTime? reviewAt;

  DeclarationWizardState({
    this.decision,
    this.reasonLabel,
    this.solutionText,
    this.currentStep = 0,
    this.declarationText = '',
    this.selectedIntervalKey,
    this.reviewAt,
  });

  DeclarationWizardState copyWith({
    Decision? decision,
    String? reasonLabel,
    String? solutionText,
    int? currentStep,
    String? declarationText,
    String? selectedIntervalKey,
    DateTime? reviewAt,
  }) {
    return DeclarationWizardState(
      decision: decision ?? this.decision,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      solutionText: solutionText ?? this.solutionText,
      currentStep: currentStep ?? this.currentStep,
      declarationText: declarationText ?? this.declarationText,
      selectedIntervalKey: selectedIntervalKey ?? this.selectedIntervalKey,
      reviewAt: reviewAt ?? this.reviewAt,
    );
  }
}

class ActionReviewState {
  final Declaration? declaration;
  final int currentStep;
  final ActionReviewStatus? reviewStatus;
  final String? failureReason;
  
  // For re-declaration flow
  final String nextDeclarationText;
  final DateTime? nextReviewAt;
  final String? nextReviewIntervalKey;

  ActionReviewState({
    this.declaration,
    this.currentStep = 0,
    this.reviewStatus,
    this.failureReason,
    this.nextDeclarationText = '',
    this.nextReviewAt,
    this.nextReviewIntervalKey,
  });

  ActionReviewState copyWith({
    Declaration? declaration,
    int? currentStep,
    ActionReviewStatus? reviewStatus,
    String? failureReason,
    String? nextDeclarationText,
    DateTime? nextReviewAt,
    String? nextReviewIntervalKey,
  }) {
    return ActionReviewState(
      declaration: declaration ?? this.declaration,
      currentStep: currentStep ?? this.currentStep,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      failureReason: failureReason ?? this.failureReason,
      nextDeclarationText: nextDeclarationText ?? this.nextDeclarationText,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      nextReviewIntervalKey: nextReviewIntervalKey ?? this.nextReviewIntervalKey,
    );
  }
}

class DeclarationWizardNotifier extends StateNotifier<DeclarationWizardState> {
  final Ref ref;

  DeclarationWizardNotifier(this.ref) : super(DeclarationWizardState());

  void init({
    required Decision decision,
    required String reasonLabel,
    required String solutionText,
  }) {
    state = DeclarationWizardState(
      decision: decision,
      reasonLabel: reasonLabel,
      solutionText: solutionText,
    );
  }

  void updateDeclarationText(String text) {
    state = state.copyWith(declarationText: text);
  }

  void updateReviewConfig(String key, DateTime reviewAt) {
    state = state.copyWith(
      selectedIntervalKey: key,
      reviewAt: reviewAt,
    );
  }

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: (state.currentStep - 1).clamp(0, 1));
  void updateCurrentStep(int step) => state = state.copyWith(currentStep: step);

  Future<void> save() async {
    final decision = state.decision;
    if (decision == null || state.reviewAt == null) return;

    await ref.read(repositoryProvider).createDeclaration(
      logId: decision.id,
      originalText: decision.textContent,
      reasonLabel: state.reasonLabel ?? '',
      solutionText: state.solutionText ?? '',
      declarationText: state.declarationText,
      reviewAt: state.reviewAt!,
    );
    
    // Invalidate to refresh the home screen proposals
    ref.invalidate(pendingDeclarationsProvider);
    reset();
  }

  void reset() {
    state = DeclarationWizardState();
  }
}

class ActionReviewNotifier extends StateNotifier<ActionReviewState> {
  final Ref ref;

  ActionReviewNotifier(this.ref) : super(ActionReviewState());

  void init(Declaration declaration) {
    state = ActionReviewState(
      declaration: declaration,
      nextDeclarationText: declaration.declarationText,
    );
  }

  void updateReviewStatus(ActionReviewStatus status) {
    state = state.copyWith(reviewStatus: status);
  }

  void updateFailureReason(String reason) {
    state = state.copyWith(failureReason: reason);
  }

  void updateNextDeclarationText(String text) {
    state = state.copyWith(nextDeclarationText: text);
  }

  void updateNextReviewConfig(String key, DateTime reviewAt) {
    state = state.copyWith(
      nextReviewIntervalKey: key,
      nextReviewAt: reviewAt,
    );
  }

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: (state.currentStep - 1).clamp(0, 3));
  void updateCurrentStep(int step) => state = state.copyWith(currentStep: step);

  Future<void> complete({bool shouldReDeclare = false}) async {
    final declaration = state.declaration;
    if (declaration == null || state.reviewStatus == null) return;

    final repo = ref.read(repositoryProvider);
    
    if (shouldReDeclare && state.nextReviewAt != null) {
      // 1. Mark current as superseded
      await repo.completeDeclaration(
        id: declaration.id,
        reviewStatus: state.reviewStatus!,
        nextStatus: DeclarationStatus.superseded,
      );

      // 2. Create new declaration linked via parentId
      await repo.createDeclaration(
        logId: declaration.logId,
        originalText: declaration.originalText,
        reasonLabel: declaration.reasonLabel,
        solutionText: declaration.solutionText,
        declarationText: state.nextDeclarationText,
        reviewAt: state.nextReviewAt!,
        parentId: declaration.id.toString(),
      );
    } else {
      // Normal completion
      await repo.completeDeclaration(
        id: declaration.id,
        reviewStatus: state.reviewStatus!,
        nextStatus: DeclarationStatus.completed,
      );
    }

    // Invalidate to refresh UI
    ref.invalidate(pendingDeclarationsProvider);
    reset();
  }

  void reset() {
    state = ActionReviewState();
  }
}

final actionReviewProvider = StateNotifierProvider<ActionReviewNotifier, ActionReviewState>((ref) {
  return ActionReviewNotifier(ref);
});

final declarationWizardProvider = StateNotifierProvider<DeclarationWizardNotifier, DeclarationWizardState>((ref) {
  return DeclarationWizardNotifier(ref);
});

final actionGoalsProvider = StreamProvider<List<Declaration>>((ref) {
  return ref.watch(repositoryProvider).watchDeclarations();
});

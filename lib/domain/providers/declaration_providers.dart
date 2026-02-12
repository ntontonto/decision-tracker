import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
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
    
    reset();
  }

  void reset() {
    state = DeclarationWizardState();
  }
}

final declarationWizardProvider = StateNotifierProvider<DeclarationWizardNotifier, DeclarationWizardState>((ref) {
  return DeclarationWizardNotifier(ref);
});

final actionGoalsProvider = StreamProvider<List<Declaration>>((ref) {
  return ref.watch(repositoryProvider).watchDeclarations();
});

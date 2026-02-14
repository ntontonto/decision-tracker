import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/providers/declaration_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/practice_review_model.dart';
import '../theme/app_design.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';
import 'declaration_wizard_sheet.dart';

class ActionReviewWizardSheet extends ConsumerStatefulWidget {
  final Declaration declaration;

  const ActionReviewWizardSheet({
    super.key,
    required this.declaration,
  });

  @override
  ConsumerState<ActionReviewWizardSheet> createState() => _ActionReviewWizardSheetState();
}

class _ActionReviewWizardSheetState extends ConsumerState<ActionReviewWizardSheet> {
  late PageController _pageController;
  late TextEditingController _textController;
  bool _showErrorGlow = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textController = TextEditingController(text: widget.declaration.declarationText);
    
    // Initialize state
    Future.microtask(() {
      ref.read(actionReviewProvider.notifier).init(widget.declaration);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _next() {
    final state = ref.read(actionReviewProvider);
    FocusScope.of(context).unfocus();

    if (!_isStepValid(state)) {
      _triggerErrorGlow();
      return;
    }

    if (state.currentStep < _getTotalSteps(state) - 1) {
      ref.read(actionReviewProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _back() {
    final state = ref.read(actionReviewProvider);
    FocusScope.of(context).unfocus();

    if (state.currentStep > 0) {
      ref.read(actionReviewProvider.notifier).prevStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  int _getTotalSteps(ActionReviewState state) {
    if (state.reviewStatus == ActionReviewStatus.success) return 1;
    return 3; // Q1 + Q2 (Blocker) + Q3 (Solution)
  }

  bool _isStepValid(ActionReviewState state) {
    if (state.currentStep == 0) return state.reviewStatus != null;
    if (state.currentStep == 1) return state.blockerKey != null;
    if (state.currentStep == 2) return state.solutionKey != null;
    return true;
  }

  void _triggerErrorGlow() {
    setState(() => _showErrorGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showErrorGlow = false);
    });
  }

  Future<void> _complete() async {
    final state = ref.read(actionReviewProvider);
    final isSuccess = state.reviewStatus == ActionReviewStatus.success;
    
    // Save the review
    await ref.read(actionReviewProvider.notifier).complete(
      shouldReDeclare: false // We handle re-declaration branching via Q4
    );

    if (mounted) {
      Navigator.pop(context);
      
      if (!isSuccess && state.shouldDeclareNextAction) {
        // Trigger existing declaration flow
        _showDeclarationWizard();
      } else {
        ref.read(successNotificationProvider.notifier).show(
          message: isSuccess ? '素晴らしい！その調子です 🎉' : 'お疲れ様でした！',
        );
      }
    }
  }

  void _showDeclarationWizard() {
    final declaration = widget.declaration;
    // We need to fetch the original decision to pass it to the wizard
    // For now, we use a simplified approach since we don't have the full Decision object here easily
    // In a real app, you might want to fetch it from repo or pass it through
    
    // Re-using the logic from RetroWizardSheet bridge
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DeclarationWizardSheet(),
    );
    
    // Initialize the wizard state (note: this requires the decision object)
    // Looking at declaration, it has logId.
    ref.read(declarationWizardProvider.notifier).init(
      decision: Decision(
        id: declaration.logId,
        textContent: declaration.originalText,
        createdAt: DateTime.now(), // dummy
        driver: DriverType.habit, // dummy
        retroOffsetType: RetroOffsetType.plus1week, // dummy
        retroAt: DateTime.now(), // dummy
        status: DecisionStatus.reviewed,
        lastUsedAt: DateTime.now(),
      ),
      reasonLabel: declaration.reasonLabel,
      solutionText: declaration.solutionText,
      parentId: declaration.id,
    );
  }

  void _skip() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(actionReviewProvider);
    final reviewMapAsync = ref.watch(practiceReviewMapProvider);

    return WizardScaffold(
      totalSteps: _getTotalSteps(state),
      currentStep: state.currentStep,
      onBack: state.currentStep > 0 ? _back : null,
      onNext: _next,
      onClose: _skip,
      pageController: _pageController,
      showErrorGlow: _showErrorGlow,
      scrollController: ScrollController(),
      onPageChanged: (page) {
        ref.read(actionReviewProvider.notifier).updateCurrentStep(page);
      },
      bottomNavigationBar: _buildBottomNavigation(state),
      children: [
        _buildStep1(state),
        if (state.reviewStatus != ActionReviewStatus.success) ...[
          reviewMapAsync.when(
            data: (map) => _buildStep2(state, map),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error context: $e')),
          ),
          reviewMapAsync.when(
            data: (map) => _buildStep3(state, map),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error context: $e')),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1(ActionReviewState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            '目標の実践を確認します',
            style: AppDesign.titleStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            '『${widget.declaration.declarationText}』',
            style: AppDesign.subtitleStyle.copyWith(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 32),
          const Text(
            '実践できましたか？',
            style: AppDesign.bodyStyle,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildLargeSelectButton(
                  'はい',
                  Icons.check_circle_outline,
                  state.reviewStatus == ActionReviewStatus.success,
                  () {
                    ref.read(actionReviewProvider.notifier).updateReviewStatus(ActionReviewStatus.success);
                    _complete(); // Fast completion
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLargeSelectButton(
                  'いいえ',
                  Icons.highlight_off,
                  state.reviewStatus == ActionReviewStatus.failed,
                  () {
                    ref.read(actionReviewProvider.notifier).updateReviewStatus(ActionReviewStatus.failed);
                    _next();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeSelectButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: AppDesign.actionButtonDecoration(selected: isSelected),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white54, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppDesign.actionButtonTextStyle(selected: isSelected).copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(ActionReviewState state, ActionReviewMap map) {
    return WizardSelectionStep<ActionBlocker>(
      title: '何が妨げになりましたか？',
      subtitle: '原因を特定して、次へつなげましょう',
      items: map.blockers,
      selected: state.blockerKey != null
          ? map.blockers.firstWhere((b) => b.key == state.blockerKey)
          : null,
      onSelect: (blocker) {
        if (blocker != null) {
          ref.read(actionReviewProvider.notifier).updateBlockerKey(blocker.key);
          _next();
        }
      },
      labelBuilder: (b) => b.label,
      scrollController: ScrollController(),
    );
  }

  Widget _buildStep3(ActionReviewState state, ActionReviewMap map) {
    final selectedBlocker = state.blockerKey != null
        ? map.blockers.where((b) => b.key == state.blockerKey).firstOrNull
        : null;
    final solutions = selectedBlocker?.solutions ?? [];

    return WizardSelectionStep<ActionSolution>(
      title: '今後に向けて何ができそう？',
      subtitle: '対応する解決方針を提示しています',
      items: solutions,
      selected: state.solutionKey != null
          ? solutions.where((s) => s.key == state.solutionKey).firstOrNull
          : null,
      onSelect: (solution) {
        if (solution != null) {
          ref.read(actionReviewProvider.notifier).updateSolutionKey(solution.key);
        }
      },
      labelBuilder: (s) => s.label,
      scrollController: ScrollController(),
    );
  }

  Widget _buildBottomNavigation(ActionReviewState state) {
    // Hidden on almost all steps as they auto-advance or auto-complete
    if (state.currentStep < 2) return const SizedBox.shrink();

    final isEnabled = _isStepValid(state);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action: Declare
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () {
                      ref.read(actionReviewProvider.notifier).updateShouldDeclareNextAction(true);
                      _complete();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? Colors.white : Colors.white10,
                foregroundColor: isEnabled ? Colors.black : Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                '次の行動宣言を入力する',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Secondary Action: Simple Done (Text Link)
          GestureDetector(
            onTap: isEnabled
                ? () {
                    ref.read(actionReviewProvider.notifier).updateShouldDeclareNextAction(false);
                    _complete();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isEnabled ? Colors.white70 : Colors.white10,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'もしくは　'),
                    TextSpan(
                      text: 'このまま完了',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isEnabled ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

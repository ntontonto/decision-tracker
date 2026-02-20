import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/providers/declaration_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/providers/reaction_providers.dart';
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
    if (state.regretLevel == RegretLevel.none) return 1;
    return 3; // Q1 + Q2 (Blocker) + Q3 (Solution)
  }

  bool _isStepValid(ActionReviewState state) {
    if (state.currentStep == 0) return state.regretLevel != null;
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
    final isNoRegret = state.regretLevel == RegretLevel.none;
    
    // Resolve labels BEFORE complete() resets the state
    String? resolvedReason;
    String? resolvedSolution;
    final map = ref.read(practiceReviewMapProvider).value;
    if (map != null && state.blockerKey != null && state.solutionKey != null) {
      try {
        final blocker = map.blockers.firstWhere((b) => b.key == state.blockerKey);
        final solution = blocker.solutions.firstWhere((s) => s.key == state.solutionKey);
        resolvedReason = blocker.label;
        resolvedSolution = solution.label;
      } catch (_) {}
    }

    // Save the review (this will reset state)
    await ref.read(actionReviewProvider.notifier).complete(
      shouldReDeclare: false 
    );

    if (mounted) {
      Navigator.pop(context);
      
      if (!isNoRegret && state.shouldDeclareNextAction) {
        // Use resolved labels for the next action's context
        _showDeclarationWizard(
          reasonLabel: resolvedReason,
          solutionText: resolvedSolution,
        );
      } else {
        ref.read(successNotificationProvider.notifier).show(
          message: isNoRegret ? '素晴らしい！その調子です 🎉' : 'お疲れ様でした！',
        );
      }
    }
  }

  void _showDeclarationWizard({String? reasonLabel, String? solutionText}) {
    final declaration = widget.declaration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DeclarationWizardSheet(),
    );

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
      reasonLabel: reasonLabel ?? declaration.reasonLabel,
      solutionText: solutionText ?? declaration.solutionText,
      parentId: declaration.id,
    );
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOver),
            child: AlertDialog(
              backgroundColor: AppDesign.glassBackgroundColor,
              title: const Text('破棄しますか？', style: TextStyle(color: Colors.white)),
              content: const Text('入力内容は保存されません。', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('入力に戻る', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('破棄する'),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  void _skip() async {
    final confirmed = await _confirmDiscard();
    if (confirmed && mounted) {
      ref.read(actionReviewProvider.notifier).reset();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(actionReviewProvider);
    final reviewMapAsync = ref.watch(practiceReviewMapProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _confirmDiscard();
        if (confirmed && context.mounted) {
          ref.read(actionReviewProvider.notifier).reset();
          Navigator.of(context).pop();
        }
      },
      child: WizardScaffold(
        totalSteps: _getTotalSteps(state),
        currentStep: state.currentStep,
        onBack: () async {
          if (state.currentStep > 0) {
            _back();
          } else {
            final confirmed = await _confirmDiscard();
            if (confirmed && context.mounted) {
              ref.read(actionReviewProvider.notifier).reset();
              Navigator.pop(context);
            }
          }
        },
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
        if (state.regretLevel != RegretLevel.none) ...[
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
    ),
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
            '目標の振り返り',
            style: AppDesign.titleStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            '『${widget.declaration.declarationText}』',
            style: AppDesign.subtitleStyle.copyWith(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 32),
          const Text(
            'この行動に対して、後悔はありますか？',
            style: AppDesign.bodyStyle,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildRegretOption(
                'ない',
                Icons.sentiment_very_satisfied,
                RegretLevel.none,
                state.regretLevel == RegretLevel.none,
                () {
                  ref.read(actionReviewProvider.notifier).updateRegretLevel(RegretLevel.none);
                  _complete(); // Fast completion for no regret
                },
              ),
              const SizedBox(height: 12),
              _buildRegretOption(
                '少しある',
                Icons.sentiment_neutral,
                RegretLevel.aLittle,
                state.regretLevel == RegretLevel.aLittle,
                () {
                  ref.read(actionReviewProvider.notifier).updateRegretLevel(RegretLevel.aLittle);
                  _next();
                },
              ),
              const SizedBox(height: 12),
              _buildRegretOption(
                'ある',
                Icons.sentiment_very_dissatisfied,
                RegretLevel.much,
                state.regretLevel == RegretLevel.much,
                () {
                  ref.read(actionReviewProvider.notifier).updateRegretLevel(RegretLevel.much);
                  _next();
                },
              ),
            ],
          ),
          const SizedBox(height: 60),
          // Skip button
          Center(
            child: TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => BackdropFilter(
                    filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOver),
                    child: AlertDialog(
                      backgroundColor: AppDesign.glassBackgroundColor,
                      title: const Text('振り返らずに終わりますか？', style: TextStyle(color: Colors.white)),
                      content: const Text('この実践はホーム画面に表示されなくなります（星座には残ります）。', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('終わる'),
                        ),
                      ],
                    ),
                  ),
                ) ?? false;

                if (confirmed && mounted) {
                  await ref.read(actionReviewProvider.notifier).skip();
                  if (mounted) {
                    Navigator.pop(context);
                    ref.read(successNotificationProvider.notifier).show(
                      message: '次回は振り返りしてくれると嬉しいな',
                      icon: Icons.sentiment_neutral,
                      reaction: ParticleReaction.jitter,
                    );
                  }
                }
              },
              child: Text(
                '振り返りせず終わる',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRegretOption(String label, IconData icon, RegretLevel level, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: AppDesign.actionButtonDecoration(selected: isSelected),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white54, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppDesign.actionButtonTextStyle(selected: isSelected).copyWith(fontSize: 18),
                  ),
                  Text(
                    '${level.score}pt',
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: Colors.black),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/providers/declaration_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/models/enums.dart';
import '../theme/app_design.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';

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
    } else {
      _complete();
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
    return 3;
  }

  bool _isStepValid(ActionReviewState state) {
    if (state.currentStep == 0) return state.reviewStatus != null;
    if (state.currentStep == 1) return state.failureReason != null;
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
    
    await ref.read(actionReviewProvider.notifier).complete(
      shouldReDeclare: !isSuccess // Temporary simplified logic
    );

    if (mounted) {
      Navigator.pop(context);
      ref.read(successNotificationProvider.notifier).show(
        message: isSuccess ? '素晴らしい！その調子です 🎉' : '次に活かしましょう！',
      );
    }
  }

  void _skip() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(actionReviewProvider);

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
          _buildStep2(state),
          _buildStep3(state),
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

  Widget _buildStep2(ActionReviewState state) {
    final reasons = [
      '忘れていた（意識にのぼらなかった）',
      '設定したタイミングが来なかった',
      'ハードルが高くて動けなかった',
      '今の自分には合わなかった',
      'その他',
    ];

    return WizardSelectionStep<String>(
      title: '何が妨げになりましたか？',
      subtitle: '原因を特定して、次へつなげましょう',
      items: reasons,
      selected: state.failureReason,
      onSelect: (reason) {
        if (reason != null) {
          ref.read(actionReviewProvider.notifier).updateFailureReason(reason);
          _next();
        }
      },
      labelBuilder: (v) => v,
      scrollController: ScrollController(),
    );
  }

  Widget _buildStep3(ActionReviewState state) {
    final intervals = {
      '今すぐ再挑戦': Duration.zero,
      'もう一度挑戦（1週間後）': const Duration(days: 7),
      'もう少し先にする（1ヶ月後）': const Duration(days: 30),
      '今回はおわりにする': null,
    };

    return WizardSelectionStep<String>(
      title: '次はどうしますか？',
      subtitle: '無理のない範囲で調整しましょう',
      items: intervals.keys.toList(),
      selected: state.nextReviewIntervalKey,
      onSelect: (key) {
        if (key != null) {
          final duration = intervals[key];
          if (duration != null) {
            final reviewDate = DateTime.now().add(duration);
            ref.read(actionReviewProvider.notifier).updateNextReviewConfig(key, reviewDate);
            ref.read(actionReviewProvider.notifier).complete(shouldReDeclare: true);
          } else {
            ref.read(actionReviewProvider.notifier).complete(shouldReDeclare: false);
          }
          
          if (mounted) {
            Navigator.pop(context);
            ref.read(successNotificationProvider.notifier).show(
              message: duration != null ? '目標を更新しました' : 'お疲れ様でした！',
            );
          }
        }
      },
      labelBuilder: (v) => v,
      scrollController: ScrollController(),
    );
  }

  Widget _buildBottomNavigation(ActionReviewState state) {
    // Hidden on first step for fast completion, and second step for auto-advance
    if (state.currentStep < 2) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _skip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'あとで',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

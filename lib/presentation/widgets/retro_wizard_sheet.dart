import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/retro_providers.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';
import 'log_wizard_sheet.dart';

class RetroWizardSheet extends ConsumerStatefulWidget {
  final dynamic decision; // Can be cast to Decision inside
  const RetroWizardSheet({super.key, required this.decision});

  @override
  ConsumerState<RetroWizardSheet> createState() => _RetroWizardSheetState();
}

class _RetroWizardSheetState extends ConsumerState<RetroWizardSheet> {
  late PageController _pageController;
  bool _showErrorGlow = false;
  final GlobalKey<WizardScaffoldState> _scaffoldKey = GlobalKey<WizardScaffoldState>();
  
  Timer? _peekTimer;
  static const Duration _idleDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(retroWizardProvider.notifier).init(widget.decision);
      _startPeekTimer();
    });
  }

  @override
  void dispose() {
    _stopPeekTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startPeekTimer() {
    _stopPeekTimer();
    // Only peek if we are not at the last step
    final state = ref.read(retroWizardProvider);
    if (state.currentStep < 3) {
      _peekTimer = Timer(_idleDuration, () {
        _scaffoldKey.currentState?.peekNextPage();
        _startPeekTimer(); // Re-arm for next peek if still idle
      });
    }
  }

  void _stopPeekTimer() {
    _peekTimer?.cancel();
    _peekTimer = null;
  }

  void _onInteraction() {
    _startPeekTimer(); // Reset idle timer on any interaction
  }

  void _next() {
    _onInteraction();
    final state = ref.read(retroWizardProvider);
    if (!_isNextEnabled(state)) {
      _triggerErrorGlow();
      return;
    }
    
    ref.read(retroWizardProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _triggerErrorGlow() {
    setState(() => _showErrorGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showErrorGlow = false);
    });
  }

  void _back() {
    _onInteraction();
    ref.read(retroWizardProvider.notifier).prevStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _complete() async {
    _stopPeekTimer();
    final notifier = ref.read(retroWizardProvider.notifier);
    final state = ref.read(retroWizardProvider);
    
    await notifier.save();
    
    if (mounted) {
      Navigator.pop(context); // Close Retro Wizard
      
      if (state.registerNextAction) {
        // Bridge to Log Wizard
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const LogWizardSheet(
            initialHint: '次はどんな行動を意識する？',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retroWizardProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSteps = 4; // 0 to 3

    return WizardScaffold(
      key: _scaffoldKey,
      totalSteps: totalSteps,
      currentStep: state.currentStep,
      onBack: _back,
      onNext: _next,
      onClose: () => Navigator.pop(context),
      pageController: _pageController,
      showErrorGlow: _showErrorGlow,
      scrollController: ScrollController(),
      onPageChanged: (page) {
        _onInteraction();
      },
      bottomNavigationBar: _buildBottomNavigation(state),
      children: [
        _buildStep0(state),
        _buildStep1(state),
        _buildStep2(state),
        _buildStep3(state),
      ],
    );
  }

  Widget _buildBottomNavigation(RetroWizardState state) {
    // Only show the action buttons on the final step.
    // Navigation on previous steps is handled by gestures & taps.
    if (state.currentStep < 3) return const SizedBox.shrink();

    final isEnabled = _isNextEnabled(state);

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
                  ? () async {
                      ref.read(retroWizardProvider.notifier).setRegisterNextAction(true);
                      await _complete();
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
                '将来の行動を宣言する',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Secondary Action: Simple Done (Text Link)
          GestureDetector(
            onTap: isEnabled
                ? () async {
                    ref.read(retroWizardProvider.notifier).setRegisterNextAction(false);
                    await _complete();
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

  bool _isNextEnabled(RetroWizardState state) {
    switch (state.currentStep) {
      case 0: return true;
      case 1: return state.regretLevel != null;
      case 2:
        if (state.regretLevel == RegretLevel.none) return state.successFactor != null;
        return state.reasonKey != null;
      case 3:
        if (state.regretLevel == RegretLevel.none) return state.reproductionStrategy != null;
        return state.solution != null;
      default: return true;
    }
  }

  Widget _buildStep0(RetroWizardState state) {
    if (state.decision == null) return const SizedBox.shrink();
    final d = state.decision!;
    final dateStr = '${d.retroAt.year}/${d.retroAt.month}/${d.retroAt.day}';
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem('設定日時', dateStr),
          _buildInfoItem('Q1: 今日は何をした？', d.textContent),
          _buildInfoItem('Q2: なぜそれをした？', d.driver.label),
          if (d.gain != null)
            _buildInfoItem('Q3: 得たものは？', d.gain!.label),
          if (d.lose != null)
            _buildInfoItem('Q4: 失ったものは？', d.lose!.label),
          if (d.note != null && d.note!.isNotEmpty)
            _buildInfoItem('Q6: 将来の自分への一言', d.note!),
          const SizedBox(height: 24),
          const Text('これらを振り返ってみましょう。', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStep1(RetroWizardState state) {
    return WizardSelectionStep<RegretLevel>(
      title: '1. 後悔はある？',
      items: RegretLevel.values,
      selected: state.regretLevel,
      onSelect: (val) {
        ref.read(retroWizardProvider.notifier).setRegretLevel(val);
        if (val != null) _next();
      },
      labelBuilder: (v) => v.label,
      scrollController: ScrollController(),
    );
  }

  Widget _buildStep2(RetroWizardState state) {
    if (state.regretLevel == RegretLevel.none) {
      final factors = [
        '目的が明確だった', '情報が十分だった', '見積もりが適切だった', '自分の価値観に合っていた',
        '人との関係が良かった', 'コンディションが良かった', '期待値が適切だった', 'タイミングが良かった'
      ];
      return WizardSelectionStep<String>(
        title: '2B. 何が良かった？',
        items: factors,
        selected: state.successFactor,
        onSelect: (val) {
          ref.read(retroWizardProvider.notifier).setSuccessFactor(val);
          if (val != null) _next();
        },
        labelBuilder: (v) => v,
        scrollController: ScrollController(),
      );
    }
    
    return WizardSelectionStep(
      title: '2A. 後悔の原因はどれ？',
      items: state.metadata?.reasons ?? [], // List<RetroReason>
      selected: state.selectedReason,
      onSelect: (val) {
        ref.read(retroWizardProvider.notifier).setReasonKey(val?.key);
        if (val != null) _next();
      },
      labelBuilder: (v) => (v as dynamic).label,
      scrollController: ScrollController(),
    );
  }

  Widget _buildStep3(RetroWizardState state) {
    if (state.regretLevel == RegretLevel.none) {
      final strategies = [
        '次も同じ条件を揃える（場所/時間/相手など）',
        '成功条件を1行で残す',
        '次回も同じ手順でやる'
      ];
      return WizardSelectionStep<String>(
        title: '再現するには？',
        subtitle: 'うまくいった要因を言語化できると、次も再現しやすくなる。',
        items: strategies,
        selected: state.reproductionStrategy,
        onSelect: (val) {
          ref.read(retroWizardProvider.notifier).setReproductionStrategy(val);
          _onInteraction();
        },
        labelBuilder: (v) => v,
        scrollController: ScrollController(),
      );
    }

    return WizardSelectionStep<String>(
      title: '後悔を避けるにはどうする？',
      subtitle: state.selectedReason?.feedback,
      items: state.selectedReason?.solutions ?? [],
      selected: state.solution,
      onSelect: (val) {
        ref.read(retroWizardProvider.notifier).setSolution(val);
        _onInteraction();
      },
      labelBuilder: (v) => v,
      scrollController: ScrollController(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

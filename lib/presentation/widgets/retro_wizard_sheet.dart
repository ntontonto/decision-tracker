import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/retro_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../theme/app_design.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';
import 'declaration_wizard_sheet.dart';
import '../../domain/providers/declaration_providers.dart';

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
      
      if (state.regretLevel == RegretLevel.none) {
        // Show the unique success message for no-regret flow
        ref.read(successNotificationProvider.notifier).show(
          message: 'いいね！その調子！',
        );
      } else if (state.registerNextAction) {
        // Bridge to Declaration Wizard
        ref.read(successNotificationProvider.notifier).show(
          message: '記録しました',
        );

        // Initialize the declaration provider with current context
        ref.read(declarationWizardProvider.notifier).init(
          decision: state.decision!,
          reasonLabel: state.selectedReason?.label ?? '',
          solutionText: state.solution ?? '',
        );

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const DeclarationWizardSheet(),
        );
      } else {
        ref.read(successNotificationProvider.notifier).show(
          message: '記録しました',
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retroWizardProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSteps = 4; // 0 to 3

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _confirmDiscard();
        if (confirmed && context.mounted) {
          ref.read(retroWizardProvider.notifier).reset();
          Navigator.of(context).pop();
        }
      },
      child: WizardScaffold(
        key: _scaffoldKey,
        totalSteps: totalSteps,
        currentStep: state.currentStep,
        onBack: () async {
          if (state.currentStep > 0) {
            _back();
          } else {
            final confirmed = await _confirmDiscard();
            if (confirmed && mounted) {
              ref.read(retroWizardProvider.notifier).reset();
              Navigator.pop(context);
            }
          }
        },
        onNext: _next,
        onClose: () async {
          final confirmed = await _confirmDiscard();
          if (confirmed && mounted) {
            ref.read(retroWizardProvider.notifier).reset();
            Navigator.pop(context);
          }
        },
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
    ),
  );
}

  Widget _buildBottomNavigation(RetroWizardState state) {
    // Only show the action buttons on the final step.
    // Navigation on previous steps is handled by gestures & taps.
    if (state.currentStep < 3) return const SizedBox.shrink();

    // Hide buttons for No-Regret route at the final step as reproduction strategy 
    // selection triggers auto-complete.
    if (state.regretLevel == RegretLevel.none) return const SizedBox.shrink();

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
    
    // Format date as "YYYY年MM月DD日"
    final dateStr = '${d.retroAt.year}年${d.retroAt.month}月${d.retroAt.day}日';
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Date-based heading
          Text(
            '$dateStrの出来事を振り返りましょう',
            style: AppDesign.titleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 24),
          
          // Main content card
          _buildMainContentCard(d),
          const SizedBox(height: 24),
          
          // Value trade-off section
          _buildValueTradeOffSection(d),
          const SizedBox(height: 24),
          
          // Expandable note section (if exists)
          if (d.note != null && d.note!.isNotEmpty)
            _buildExpandableNote(d.note!),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMainContentCard(dynamic decision) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            decision.textContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          
          // Motivation with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  decision.driver.icon,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '動機',
                    style: AppDesign.sectionTitleStyle.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    decision.driver.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueTradeOffSection(dynamic decision) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '価値のトレードオフ',
          style: AppDesign.sectionTitleStyle,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildValueSocket(
                title: '失ったもの',
                value: decision.lose,
                isLose: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildValueSocket(
                title: '得たもの',
                value: decision.gain,
                isLose: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueSocket({
    required String title,
    required dynamic value,
    required bool isLose,
  }) {
    final color = isLose ? Colors.redAccent : Colors.greenAccent;
    final hasValue = value != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasValue 
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasValue ? color.withValues(alpha: 0.5) : Colors.white12,
          width: hasValue ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Icon and label
          if (hasValue) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                value.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.label,
              style: AppDesign.valueLabelStyle,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Icon(
                isLose ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: Colors.white24,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'なし',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableNote(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_outlined,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '将来の自分への一言',
                style: AppDesign.sectionTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
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
      labelBuilder: (v) => '${v.label} (${v.score}pt)',
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
        onSelect: (val) async {
          ref.read(retroWizardProvider.notifier).setReproductionStrategy(val);
          _onInteraction();
          if (val != null) {
            await _complete();
          }
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

}

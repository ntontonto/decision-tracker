import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/retro_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/providers/reaction_providers.dart';
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
    
    final currentContext = context;
    if (!currentContext.mounted) return;
    Navigator.pop(currentContext); // Close Retro Wizard
    
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
        context: currentContext,
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
            final currentContext = context;
            final confirmed = await _confirmDiscard();
            if (confirmed) {
              ref.read(retroWizardProvider.notifier).reset();
              if (currentContext.mounted) Navigator.pop(currentContext);
            }
          }
        },
        onNext: _next,
        onClose: () async {
          final currentContext = context;
          final confirmed = await _confirmDiscard();
          if (confirmed) {
            ref.read(retroWizardProvider.notifier).reset();
            if (currentContext.mounted) Navigator.pop(currentContext);
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
    final dateStr = '${d.createdAt.year}年${d.createdAt.month}月${d.createdAt.day}日';
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // Date chip-style heading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '出来事を振り返りましょう',
            style: AppDesign.titleStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          
          // Main content card
          _buildMainContentCard(d),
          const SizedBox(height: 24),
          
          // Value trade-off section
          _buildValueFlowSection(d),
          const SizedBox(height: 24),
          
          // Expandable note section (if exists)
          if (d.note != null && d.note!.isNotEmpty)
            _buildExpandableNote(d.note!),
          
          const SizedBox(height: 24),
          
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
                      content: const Text('この判断はホーム画面に表示されなくなります（星座には残ります）。', style: TextStyle(color: Colors.white70)),
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

                if (confirmed) {
                  final currentContext = context;
                  await ref.read(retroWizardProvider.notifier).skip();
                  if (currentContext.mounted) {
                    Navigator.pop(currentContext);
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

  Widget _buildMainContentCard(dynamic decision) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            decision.textContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          // Divider
          Container(
            height: 1,
            width: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white38, Colors.white10],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Motivation with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(
                  decision.driver.icon,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '動機',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    decision.driver.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  Widget _buildValueFlowSection(dynamic decision) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // Loss
              Expanded(
                child: _buildFlowItem(
                  label: '失ったもの',
                  value: decision.lose,
                  color: Colors.redAccent,
                  isLoss: true,
                ),
              ),
              
              // Animated Connector
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white24,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withValues(alpha: 0.3),
                            Colors.greenAccent.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Gain
              Expanded(
                child: _buildFlowItem(
                  label: '得たもの',
                  value: decision.gain,
                  color: Colors.greenAccent,
                  isLoss: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowItem({
    required String label,
    required dynamic value,
    required Color color,
    required bool isLoss,
  }) {
    final hasValue = value != null;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasValue 
                ? color.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: hasValue ? color.withValues(alpha: 0.4) : Colors.white12,
              width: 1.5,
            ),
            boxShadow: hasValue ? [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Center(
            child: Icon(
              hasValue ? value.icon : (isLoss ? Icons.remove : Icons.add),
              color: hasValue ? Colors.white : Colors.white10,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasValue ? value.label : 'なし',
          style: TextStyle(
            color: hasValue ? Colors.white : Colors.white24,
            fontSize: 12,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

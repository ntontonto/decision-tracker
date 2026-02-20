import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/declaration_providers.dart';
import '../../domain/providers/app_providers.dart';
import '../theme/app_design.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';

class DeclarationWizardSheet extends ConsumerStatefulWidget {
  const DeclarationWizardSheet({super.key});

  @override
  ConsumerState<DeclarationWizardSheet> createState() => _DeclarationWizardSheetState();
}

class _DeclarationWizardSheetState extends ConsumerState<DeclarationWizardSheet> {
  late PageController _pageController;
  late TextEditingController _textController;
  bool _showErrorGlow = false;
  
  // Rotating placeholder logic
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;
  final List<String> _placeholders = [
    '次にラーメンを食べたくなったら、別の店を1つ探す',
    '次に買い替えたくなったら、比較を3分だけする',
    '次に会う前に、目的を一言だけ書く',
    '次に迷ったら、一旦保留して条件を1つ確認する',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textController = TextEditingController();
    _startPlaceholderRotation();
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startPlaceholderRotation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });
  }

  void _next() {
    final state = ref.read(declarationWizardProvider);
    FocusScope.of(context).unfocus();
    
    if (!_isStepValid(state.currentStep, state)) {
      _triggerErrorGlow();
      return;
    }
    
    if (state.currentStep < 1) {
      ref.read(declarationWizardProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _back() {
    final state = ref.read(declarationWizardProvider);
    FocusScope.of(context).unfocus();
    
    if (state.currentStep > 0) {
      ref.read(declarationWizardProvider.notifier).prevStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _isStepValid(int step, DeclarationWizardState state) {
    if (step == 0) return state.declarationText.isNotEmpty;
    if (step == 1) return state.reviewAt != null;
    return true;
  }

  void _triggerErrorGlow() {
    setState(() => _showErrorGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showErrorGlow = false);
    });
  }

  Future<void> _complete() async {
    final currentContext = context;
    await ref.read(declarationWizardProvider.notifier).save();
    if (!currentContext.mounted) return;
    Navigator.pop(currentContext);
    ref.read(successNotificationProvider.notifier).show(
      message: '宣言を保存しました',
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

  Future<void> _skip() async {
    final currentContext = context;
    final confirmed = await _confirmDiscard();
    if (confirmed) {
      ref.read(declarationWizardProvider.notifier).reset();
      if (!currentContext.mounted) return;
      Navigator.pop(currentContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(declarationWizardProvider);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _confirmDiscard();
        if (confirmed && context.mounted) {
          ref.read(declarationWizardProvider.notifier).reset();
          Navigator.of(context).pop();
        }
      },
      child: WizardScaffold(
        totalSteps: 2,
        currentStep: state.currentStep,
        onBack: () async {
          if (state.currentStep > 0) {
            _back();
          } else {
            final currentContext = context;
            final confirmed = await _confirmDiscard();
            if (confirmed) {
              ref.read(declarationWizardProvider.notifier).reset();
              if (currentContext.mounted) {
                Navigator.pop(currentContext);
              }
            }
          }
        },
        onNext: _next,
        onClose: _skip,
        pageController: _pageController,
        showErrorGlow: _showErrorGlow,
        scrollController: ScrollController(),
        onPageChanged: (page) {
          ref.read(declarationWizardProvider.notifier).updateCurrentStep(page);
          FocusScope.of(context).unfocus();
        },
        bottomNavigationBar: _buildBottomNavigation(state),
        children: [
        _buildStep1(state),
        _buildStep2(state),
      ],
    ),
  );
}

  Widget _buildStep1(DeclarationWizardState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            '同じ状況が来たとき、どうやって後悔を避ける？',
            style: AppDesign.titleStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 16),
          
          // Reference Summary Box
          _buildSummaryBox(state),
          
          const SizedBox(height: 24),
          
          TextField(
            controller: _textController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: AppDesign.inputDecoration(
              hintText: _placeholders[_placeholderIndex],
              isLarge: true,
            ),
            onChanged: (val) => ref.read(declarationWizardProvider.notifier).updateDeclarationText(val),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(DeclarationWizardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow('やったこと', state.decision?.textContent ?? ''),
          const Divider(color: Colors.white10),
          _buildSummaryRow('後悔理由', state.reasonLabel ?? ''),
          const Divider(color: Colors.white10),
          _buildSummaryRow('解決策', state.solutionText ?? ''),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(DeclarationWizardState state) {
    final intervals = {
      '今': Duration.zero,
      '1週間後': const Duration(days: 7),
      '2週間後': const Duration(days: 14),
      '1ヶ月後': const Duration(days: 30),
      '3ヶ月後': const Duration(days: 90),
      '6ヶ月後': const Duration(days: 180),
    };

    return WizardSelectionStep<String>(
      title: 'いつ見直す？',
      subtitle: '設定した日時に振り返りを行います',
      items: intervals.keys.toList(),
      selected: state.selectedIntervalKey,
      onSelect: (key) {
        if (key != null) {
          final reviewDate = DateTime.now().add(intervals[key]!);
          ref.read(declarationWizardProvider.notifier).updateReviewConfig(key, reviewDate);
          _next();
        }
      },
      labelBuilder: (v) => v,
      scrollController: ScrollController(),
    );
  }

  Widget _buildBottomNavigation(DeclarationWizardState state) {
    final isEnabled = _isStepValid(state.currentStep, state);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? Colors.white : Colors.white10,
                foregroundColor: isEnabled ? Colors.black : Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                state.currentStep == 1 ? '保存して終了' : '次へ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _skip,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'スキップ',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

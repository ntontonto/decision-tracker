import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/retro_providers.dart';
import '../theme/app_design.dart';
import 'wizard_step_indicator.dart';
import 'log_wizard_sheet.dart';

class RetroWizardSheet extends ConsumerStatefulWidget {
  final dynamic decision; // Can be cast to Decision inside
  const RetroWizardSheet({super.key, required this.decision});

  @override
  ConsumerState<RetroWizardSheet> createState() => _RetroWizardSheetState();
}

class _RetroWizardSheetState extends ConsumerState<RetroWizardSheet> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(retroWizardProvider.notifier).init(widget.decision);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    ref.read(retroWizardProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    ref.read(retroWizardProvider.notifier).prevStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: AppDesign.glassBlur, sigmaY: AppDesign.glassBlur),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppDesign.glassBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppDesign.glassBorderColor, width: AppDesign.glassBorderWidth),
          ),
          child: Column(
            children: [
              // Indicator
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: WizardStepIndicator(
                  currentStep: state.currentStep,
                  totalSteps: totalSteps,
                ),
              ),
              
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep0(state),
                    _buildStep1(state),
                    _buildStep2(state),
                    _buildStep3(state), // Final step with dual buttons
                  ],
                ),
              ),

              // Bottom Navigation
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                child: Row(
                  children: [
                    // Left: Back button
                    SizedBox(
                      width: 60,
                      child: state.currentStep > 0
                          ? TextButton(
                              onPressed: _back,
                              child: const Text('戻る', style: TextStyle(color: Colors.white70)),
                            )
                          : const SizedBox.shrink(),
                    ),
                    
                    // Center: Done button (only at final step)
                    Expanded(
                      child: Center(
                        child: state.currentStep == 3
                            ? TextButton(
                                onPressed: _isNextEnabled(state)
                                    ? () async {
                                        ref.read(retroWizardProvider.notifier).setRegisterNextAction(false);
                                        await _complete();
                                      }
                                    : null,
                                child: Text(
                                  '完了',
                                  style: TextStyle(
                                    color: _isNextEnabled(state) ? Colors.white70 : Colors.white24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    
                    // Right: Next or Highlighted Action
                    SizedBox(
                      width: 180,
                      child: state.currentStep < 3
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _isNextEnabled(state) ? _next : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('次へ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isNextEnabled(state)
                                  ? () async {
                                      ref.read(retroWizardProvider.notifier).setRegisterNextAction(true);
                                      await _complete();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isNextEnabled(state) ? Colors.white : Colors.white10,
                                foregroundColor: _isNextEnabled(state) ? Colors.black : Colors.white24,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text(
                                '今すぐ将来の行動を宣言する',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    
    return _buildScrollableContent(
      title: d.textContent,
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
        ],
      ),
    );
  }

  Widget _buildStep1(RetroWizardState state) {
    return _buildSelectionStep(
      title: '1. 後悔はある？',
      items: RegretLevel.values,
      selected: state.regretLevel,
      onSelect: (val) => ref.read(retroWizardProvider.notifier).setRegretLevel(val),
      labelBuilder: (v) => v.label,
    );
  }

  Widget _buildStep2(RetroWizardState state) {
    if (state.regretLevel == RegretLevel.none) {
      final factors = [
        '目的が明確だった', '情報が十分だった', '見積もりが適切だった', '自分の価値観に合っていた',
        '人との関係が良かった', 'コンディションが良かった', '期待値が適切だった', 'タイミングが良かった'
      ];
      return _buildSelectionStep(
        title: '2B. 何が良かった？',
        items: factors,
        selected: state.successFactor,
        onSelect: (val) => ref.read(retroWizardProvider.notifier).setSuccessFactor(val),
        labelBuilder: (v) => v,
      );
    }
    
    return _buildSelectionStep(
      title: '2A. 後悔の原因はどれ？',
      items: state.metadata?.reasons ?? [],
      selected: state.selectedReason,
      onSelect: (val) => ref.read(retroWizardProvider.notifier).setReasonKey(val.key),
      labelBuilder: (v) => v.label,
    );
  }

  Widget _buildStep3(RetroWizardState state) {
    if (state.regretLevel == RegretLevel.none) {
      final strategies = [
        '次も同じ条件を揃える（場所/時間/相手など）',
        '成功条件を1行で残す',
        '次回も同じ手順でやる'
      ];
      return _buildSelectionStep(
        title: '再現するには？',
        bodyText: 'うまくいった要因を言語化できると、次も再現しやすくなる。',
        items: strategies,
        selected: state.reproductionStrategy,
        onSelect: (val) => ref.read(retroWizardProvider.notifier).setReproductionStrategy(val),
        labelBuilder: (v) => v,
        autoAdvance: false, // Last step
      );
    }

    return _buildSelectionStep(
      title: '後悔を避けるにはどうする？',
      bodyText: state.selectedReason?.feedback,
      items: state.selectedReason?.solutions ?? [],
      selected: state.solution,
      onSelect: (val) => ref.read(retroWizardProvider.notifier).setSolution(val),
      labelBuilder: (v) => v,
      autoAdvance: false, // Last step
    );
  }

  Widget _buildScrollableContent({required String title, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectionStep<T>({
    required String title,
    String? bodyText,
    required List<T> items,
    required T? selected,
    required Function(T) onSelect,
    required String Function(T) labelBuilder,
    bool autoAdvance = true,
  }) {
    return _buildScrollableContent(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bodyText != null) ...[
            Text(
              bodyText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final isSelected = item == selected;
              return GestureDetector(
                onTap: () {
                  onSelect(item);
                  if (autoAdvance) _next();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: AppDesign.actionButtonDecoration(selected: isSelected),
                  child: Text(
                    labelBuilder(item),
                    style: AppDesign.actionButtonTextStyle(selected: isSelected),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/app_providers.dart';
import '../theme/app_design.dart';
import 'wizard_step_indicator.dart';

class LogWizardSheet extends ConsumerStatefulWidget {
  const LogWizardSheet({super.key});

  @override
  ConsumerState<LogWizardSheet> createState() => _LogWizardSheetState();
}

class _LogWizardSheetState extends ConsumerState<LogWizardSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _currentStep = 0;
  bool _showErrorGlow = false;
  bool _isSaving = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(logWizardProvider);
      _textController.text = state.text;
      _noteController.text = state.note ?? '';
      _startIdleTimer();
    });
  }

  @override
  void dispose() {
    _stopIdleTimer();
    _pageController.dispose();
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startIdleTimer() {
    _stopIdleTimer();
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final state = ref.read(logWizardProvider);
      if (_isStepValid(_currentStep, state) && _currentStep < 5) {
        _peekNextPage();
      } else {
        _startIdleTimer();
      }
    });
  }

  void _stopIdleTimer() {
    _idleTimer?.cancel();
  }

  void _peekNextPage() async {
    if (!_pageController.hasClients) return;
    const double peekDistance = 40.0;
    final currentOffset = _pageController.offset;
    
    await _pageController.animateTo(
      currentOffset + peekDistance,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    await _pageController.animateTo(
      currentOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeIn,
    );
    _startIdleTimer();
  }

  void _nextStep() {
    final state = ref.read(logWizardProvider);
    if (_currentStep == 4 && state.retroOffset == RetroOffsetType.now) {
      _saveDecision();
    } else if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveDecision();
    }
  }

  void _prevStep() async {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final confirmed = await _confirmDiscard();
      if (confirmed && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  bool _isStepValid(int step, LogWizardState state) {
    if (step == 0) return state.text.trim().isNotEmpty;
    if (step == 1) return state.driver != null;
    if (step == 2) return true; // Q3: Gain (Optional)
    if (step == 3) return true; // Q4: Lose (Optional)
    if (step == 4) return state.retroOffset != null;
    return true;
  }

  void _triggerErrorGlow() {
    setState(() => _showErrorGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showErrorGlow = false);
    });
  }

  Future<bool> _confirmDiscard() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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

  Future<void> _saveDecision() async {
    if (_isSaving) return; // Prevent double trigger
    
    // Keep snapshot for "Fix" feature
    final snapshot = ref.read(logWizardProvider);
    
    setState(() => _isSaving = true);
    final savedId = await ref.read(logWizardProvider.notifier).save();
    
    if (mounted) {
      // With canPop: _isSaving, this will pop without triggering confirmation
      Navigator.of(context).pop();
      
      // Show Home Toast
      ref.read(successNotificationProvider.notifier).show(
        message: '入力が完了しました。',
        onFix: (BuildContext shellContext, WidgetRef activeRef) {
          // Restore state using the activeRef (which is still alive)
          if (savedId != null) {
            activeRef.read(logWizardProvider.notifier).restore(snapshot.copyWith(editingId: () => savedId));
          }
          
          showModalBottomSheet(
            context: shellContext, // Use MainPage's context instead of popped sheet's context
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const LogWizardSheet(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logWizardProvider);

    return PopScope(
      canPop: _isSaving, // Allow pop if we are in saving process
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) return;
        final confirmed = await _confirmDiscard();
        if (confirmed && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.85, 1.0],
      builder: (context, scrollController) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppDesign.glassBlur, sigmaY: AppDesign.glassBlur),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                color: AppDesign.glassBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: AppDesign.glassBorderColor, width: AppDesign.glassBorderWidth),
              ),
              child: Column(
                children: [
                  // Top Bar / Handle (Wrap in scrollable to enable sheet drag from top)
                  SizedBox(
                    height: 32,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  WizardStepIndicator(currentStep: _currentStep, totalSteps: 6),
                  
                  Expanded(
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            _startIdleTimer();
                            final x = details.localPosition.dx;
                            final width = MediaQuery.of(context).size.width;
                            if (x < width * 0.15) {
                              _prevStep();
                            } else if (x > width * 0.85) {
                              if (_isStepValid(_currentStep, state)) {
                                _nextStep();
                              } else {
                                _triggerErrorGlow();
                              }
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            _startIdleTimer();
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -500) {
                              if (_isStepValid(_currentStep, state)) {
                                _nextStep();
                              } else {
                                _triggerErrorGlow();
                              }
                            } else if (velocity > 500) {
                              _prevStep();
                            }
                          },
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (page) {
                              _startIdleTimer();
                              FocusScope.of(context).unfocus();
                              setState(() => _currentStep = page);
                            },
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildQ1Content(state, scrollController), 
                              _buildSelectionStep<DriverType>(
                                'Q2: なぜそれをした？',
                                '動機を選択してください',
                                DriverType.values,
                                state.driver,
                                (val) => ref.read(logWizardProvider.notifier).updateDriver(val),
                                scrollController,
                              ),
                              _buildSelectionStep<GainType>(
                                'Q3: 得たものは？',
                                'ポジティブな変化を選択してください',
                                GainType.values,
                                state.gain,
                                (val) => ref.read(logWizardProvider.notifier).updateGain(val),
                                scrollController,
                              ),
                              _buildSelectionStep<LoseType>(
                                'Q4: 失ったものは？',
                                'ネガティブな変化を選択してください',
                                LoseType.values,
                                state.lose,
                                (val) => ref.read(logWizardProvider.notifier).updateLose(val),
                                scrollController,
                              ),
                              _buildSelectionStep<RetroOffsetType>(
                                'Q5: 効果が感じられるのは？',
                                '振り返るタイミングを選択してください',
                                RetroOffsetType.values,
                                state.retroOffset,
                                (val) {
                                  ref.read(logWizardProvider.notifier).updateRetroOffset(val);
                                  // Simplified: Just update state. _nextStep handles the save logic.
                                },
                                scrollController,
                              ),
                              _buildQ6Content(state, scrollController),
                            ],
                          ),
                        ),
                        if (_showErrorGlow)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 15,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [AppDesign.errorGlowColor, Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    ),
    ),
    );
  }

  Widget _buildQ1Content(LogWizardState state, ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      physics: const AlwaysScrollableScrollPhysics(), // Enable expansion even if content is short
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Q1: 今日は何をした？', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: AppDesign.inputDecoration(hintText: '例: 30分読書する、新しい靴を買う...'),
            onChanged: (val) => ref.read(logWizardProvider.notifier).updateText(val),
            onSubmitted: (_) {
              if (_isStepValid(0, state)) {
                _nextStep();
              } else {
                _triggerErrorGlow();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildSuggestions(state.text),
          const SizedBox(height: 200), // Extra space to ensure we can scroll/expand
        ],
      ),
    );
  }

  Widget _buildSuggestions(String query) {
    if (query.trim().isEmpty) return const SizedBox.shrink();
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
    
    return suggestionsAsync.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: list.map((item) => ListTile(
              dense: true,
              title: Text(item.textContent, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              subtitle: Text(item.driver.label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.history, size: 16, color: Colors.white24),
              onTap: () {
                _textController.text = item.textContent;
                _noteController.text = item.note ?? '';
                ref.read(logWizardProvider.notifier).selectSuggestion(item);
                _nextStep();
              },
            )).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildSelectionStep<T extends Enum>(String title, String subtitle, List<T> items, T? selected, Function(T?) onSelect, ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      physics: const AlwaysScrollableScrollPhysics(), // Enable expansion
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          Text(subtitle, style: AppDesign.subtitleStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final label = (item as dynamic).label;
              final isSelected = selected == item;
              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    onSelect(null);
                  } else {
                    onSelect(item);
                    _nextStep();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: AppDesign.actionButtonDecoration(selected: isSelected),
                  child: Text(label, style: AppDesign.actionButtonTextStyle(selected: isSelected)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 200), // Extra space
        ],
      ),
    );
  }

  Widget _buildQ6Content(LogWizardState state, ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      physics: const AlwaysScrollableScrollPhysics(), // Enable expansion
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('Q6: 将来の自分への一言 (任意)', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: AppDesign.inputDecoration(hintText: '振り返る時の自分にメッセージを...', isLarge: true),
                onChanged: (val) => ref.read(logWizardProvider.notifier).updateNote(val),
                onSubmitted: (_) => _saveDecision(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: _saveDecision,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('完了', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
          const SizedBox(height: 200), // Extra space
          const SizedBox(height: 200), // Extra space
        ],
      ),
    );
  }
}

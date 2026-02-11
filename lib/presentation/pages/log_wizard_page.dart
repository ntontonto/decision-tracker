import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/models/enums.dart';
import '../../domain/providers/app_providers.dart';
import '../widgets/wizard_step_indicator.dart';

class LogWizardPage extends ConsumerStatefulWidget {
  const LogWizardPage({super.key});

  @override
  ConsumerState<LogWizardPage> createState() => _LogWizardPageState();
}

class _LogWizardPageState extends ConsumerState<LogWizardPage> {
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _currentStep = 0;
  bool _showErrorGlow = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
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
        _startIdleTimer(); // Re-schedule if not valid yet
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
      // If Q5 is "Now", save directly (effectively skipping Q6)
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
    if (step == 2) return state.gain != null;
    if (step == 3) return state.lose != null;
    if (step == 4) return state.retroOffset != null;
    return true; // Q6 is optional
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
          builder: (context) => AlertDialog(
            title: const Text('破棄しますか？'),
            content: const Text('これまでの入力内容は保存されません。中断してもよろしいですか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('続ける'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('破棄する'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveDecision() async {
    await ref.read(logWizardProvider.notifier).save();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logWizardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Decision'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final confirmed = await _confirmDiscard();
            if (confirmed && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Listener(
          onPointerDown: (_) => _startIdleTimer(),
          onPointerMove: (_) => _startIdleTimer(),
          child: Column(
            children: [
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
                          // Tap Left -> Back
                          _prevStep();
                        } else if (x > width * 0.85) {
                          // Tap Right -> Next
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
                          // Swipe Left -> Next
                          if (_isStepValid(_currentStep, state)) {
                            _nextStep();
                          } else {
                            _triggerErrorGlow();
                          }
                        } else if (velocity > 500) {
                          // Swipe Right -> Back
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
                          _buildQ1Content(state),
                          _buildQ2Content(state),
                          _buildQ3Content(state),
                          _buildQ4Content(state),
                          _buildQ5Content(state),
                          _buildQ6Content(state),
                        ],
                      ),
                    ),
                    if (_showErrorGlow)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 20,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.red.withValues(alpha: 0.4),
                                  Colors.red.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Bottom spacing instead of buttons
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQ1Content(LogWizardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Q1: 今日は何をした？', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '例: 30分読書する、新しい靴を買う...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      ref.read(logWizardProvider.notifier).updateText(val);
                    },
                  ),
                  const SizedBox(height: 2),
                  Consumer(
                    builder: (context, ref, child) {
                      final query = ref.watch(logWizardProvider).text;
                      if (query.trim().isEmpty) return const SizedBox.shrink();
                      final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
                      return suggestionsAsync.when(
                        data: (list) {
                          if (list.isEmpty) return const SizedBox.shrink();
                          return Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              children: [
                                const Divider(height: 1),
                                ...list.map((item) => ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.textContent,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                            ),
                                            child: Text(
                                              '${item.driver.label} / ${item.retroOffsetType.label}',
                                              style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.normal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(Icons.history, size: 14, color: Colors.grey),
                                      onTap: () {
                                        _textController.text = item.textContent;
                                        _noteController.text = item.note ?? '';
                                        ref.read(logWizardProvider.notifier).selectSuggestion(item);
                                        _nextStep();
                                      },
                                    )),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQ2Content(LogWizardState state) {
    return _buildSelectionContent<DriverType>(
      title: 'Q2: なぜそれをした？',
      subtitle: '動機を選択してください',
      items: DriverType.values,
      selectedItem: state.driver,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateDriver(val),
    );
  }

  Widget _buildQ3Content(LogWizardState state) {
    return _buildSelectionContent<GainType>(
      title: 'Q3: 得たものは？',
      subtitle: 'ポジティブな変化を選択してください',
      items: GainType.values,
      selectedItem: state.gain,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateGain(val),
    );
  }

  Widget _buildQ4Content(LogWizardState state) {
    return _buildSelectionContent<LoseType>(
      title: 'Q4: 失ったものは？',
      subtitle: 'ネガティブな変化を選択してください',
      items: LoseType.values,
      selectedItem: state.lose,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateLose(val),
    );
  }

  Widget _buildQ5Content(LogWizardState state) {
    return _buildSelectionContent<RetroOffsetType>(
      title: 'Q5: 行動の効果が感じられるのはいつごろ？',
      subtitle: '振り返るタイミングを選択してください',
      items: RetroOffsetType.values,
      selectedItem: state.retroOffset,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateRetroOffset(val),
    );
  }


  Widget _buildQ6Content(LogWizardState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q6: 将来の自分への一言 (任意)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '振り返る時の自分にメッセージを...',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => ref.read(logWizardProvider.notifier).updateNote(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionContent<T extends Enum>({
    required String title,
    required String subtitle,
    required List<T> items,
    required T? selectedItem,
    required Function(T?) onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final label = (item as dynamic).label;
              final isPro = item is RetroOffsetType && item == RetroOffsetType.plus3monthsPlus;
              
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    if (isPro) const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(Icons.lock, size: 14),
                    ),
                  ],
                ),
                selected: selectedItem == item,
                onSelected: (selected) {
                  _startIdleTimer();
                  if (isPro && selected) {
                    _showProUnlockDialog();
                    return;
                  }
                  if (selected) {
                    onSelect(item);
                    _nextStep();
                  } else {
                    onSelect(null);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  void _showProUnlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro機能'),
        content: const Text('カスタム日付や長期のリマインドはProプランで利用可能です。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Proの詳細を見る')),
        ],
      ),
    );
  }
}

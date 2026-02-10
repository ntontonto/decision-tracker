import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveDecision();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          WizardStepIndicator(currentStep: _currentStep, totalSteps: 6),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
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
          _buildNavigationButtons(),
        ],
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
                  Text('Q1: 何を決めましたか？', style: Theme.of(context).textTheme.titleLarge),
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
      title: 'Q2: Driver (必須)',
      subtitle: 'この判断の動機は何ですか？',
      items: DriverType.values,
      selectedItem: state.driver,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateDriver(val),
    );
  }

  Widget _buildQ3Content(LogWizardState state) {
    return _buildSelectionContent<GainType>(
      title: 'Q3: Gain (任意)',
      subtitle: '何が得られると期待していますか？',
      items: GainType.values,
      selectedItem: state.gain,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateGain(val),
      canSkip: true,
    );
  }

  Widget _buildQ4Content(LogWizardState state) {
    return _buildSelectionContent<LoseType>(
      title: 'Q4: Lose (任意)',
      subtitle: '何を失う（またはコストを払う）リスクがありますか？',
      items: LoseType.values,
      selectedItem: state.lose,
      onSelect: (val) => ref.read(logWizardProvider.notifier).updateLose(val),
      canSkip: true,
    );
  }

  Widget _buildQ5Content(LogWizardState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q5: 将来の自分への一言 (任意)', style: Theme.of(context).textTheme.titleLarge),
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

  Widget _buildQ6Content(LogWizardState state) {
    return _buildSelectionContent<RetroOffsetType>(
      title: 'Q6: Retro Day (必須)',
      subtitle: 'いつ振り返りますか？',
      items: RetroOffsetType.values,
      selectedItem: state.retroOffset,
      onSelect: (val) {
        if (val == RetroOffsetType.custom || val == RetroOffsetType.plus3monthsPlus) {
          _showProUnlockDialog();
        } else {
          ref.read(logWizardProvider.notifier).updateRetroOffset(val);
        }
      },
    );
  }

  Widget _buildSelectionContent<T extends Enum>({
    required String title,
    required String subtitle,
    required List<T> items,
    required T? selectedItem,
    required Function(T) onSelect,
    bool canSkip = false,
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
              final isPro = item.name == 'custom' || item.name == 'plus3monthsPlus';
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
                  if (selected) {
                    onSelect(item);
                    // Only auto-advance if it's not a Pro feature (Q6 case)
                    final isPro = item.name == 'custom' || item.name == 'plus3monthsPlus';
                    if (!isPro) {
                      _nextStep();
                    }
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final state = ref.watch(logWizardProvider);
    bool canGoNext = false;
    if (_currentStep == 0) {
      canGoNext = state.text.isNotEmpty;
    } else if (_currentStep == 1) {
      canGoNext = state.driver != null;
    } else if (_currentStep == 2 || _currentStep == 3 || _currentStep == 4) {
      canGoNext = true;
    } else if (_currentStep == 5) {
      canGoNext = state.retroOffset != null;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _prevStep,
            child: Text(_currentStep == 0 ? 'キャンセル' : '戻る'),
          ),
          ElevatedButton(
            onPressed: canGoNext ? _nextStep : null,
            child: Text(_currentStep == 5 ? '完了' : '次へ'),
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

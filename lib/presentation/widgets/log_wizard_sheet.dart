import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/providers/settings_provider.dart';
import '../../core/services/notification_service.dart';
import '../theme/app_design.dart';
import 'wizard_scaffold.dart';
import 'wizard_selection_step.dart';
import 'wizard_reflection_step.dart';

class LogWizardSheet extends ConsumerStatefulWidget {
  final String? initialText;
  final String? initialHint;
  const LogWizardSheet({super.key, this.initialText, this.initialHint});

  @override
  ConsumerState<LogWizardSheet> createState() => _LogWizardSheetState();
}

class _LogWizardSheetState extends ConsumerState<LogWizardSheet> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TextEditingController _textController;
  late TextEditingController _noteController;
  int _currentStep = 0;
  bool _showErrorGlow = false;
  bool _isSaving = false;
  Timer? _idleTimer;
  late FocusNode _q1FocusNode;
  late FocusNode _q6FocusNode;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textController = TextEditingController(); // Don't auto-fill
    _noteController = TextEditingController();
    _q1FocusNode = FocusNode();
    _q6FocusNode = FocusNode();
    
    // Initialize controllers with current state if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Still update text in provider if passed, but not in controller if we want empty input
      // However user says 'オートフィルは行わない', so we skip that too
      final state = ref.read(logWizardProvider);
      _textController.text = state.text;
      _noteController.text = state.note ?? '';
      
      // Explicitly request focus for Q1 if we are starting there
      if (_currentStep == 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _q1FocusNode.requestFocus();
        });
      }
      
      _startIdleTimer();
    });
  }

  @override
  void dispose() {
    _stopIdleTimer();
    _pageController.dispose();
    _textController.dispose();
    _noteController.dispose();
    _q1FocusNode.dispose();
    _q6FocusNode.dispose();
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
    if (_currentStep < 4) {
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
        ref.read(logWizardProvider.notifier).reset();
        Navigator.of(context).pop();
      }
    }
  }

  bool _isStepValid(int step, LogWizardState state) {
    if (step == 0) return state.text.trim().isNotEmpty;
    if (step == 1) return state.driver != null;
    if (step == 2) return true; // Reflection (Optional)
    if (step == 3) return state.retroOffset != null;
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
    
    // Request notification permission on first save
    final settings = ref.read(settingsProvider);
    if (!settings.hasRequestedPermission) {
      await NotificationService().requestPermission();
      await ref.read(settingsProvider.notifier).markPermissionRequested();
    }
    
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
      canPop: _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) return;
        final confirmed = await _confirmDiscard();
        if (confirmed && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: WizardScaffold(
        totalSteps: 5,
        currentStep: _currentStep,
        onBack: _prevStep,
        onNext: () {
          if (_isStepValid(_currentStep, state)) {
            _nextStep();
          } else {
            _triggerErrorGlow();
          }
        },
        onClose: () async {
          final confirmed = await _confirmDiscard();
          if (confirmed && mounted) {
            ref.read(logWizardProvider.notifier).reset();
            Navigator.pop(context);
          }
        },
        pageController: _pageController,
        showErrorGlow: _showErrorGlow,
        scrollController: ScrollController(), // We manage individual scroll controllers in steps if needed, or pass one
        onPageChanged: (page) {
          _startIdleTimer();
          setState(() => _currentStep = page);
          
          if (page == 0) {
            _q1FocusNode.requestFocus();
          } else if (page == 4) {
            _q6FocusNode.requestFocus();
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        children: [
          _buildQ1Content(state),
          _buildEnumStep<DriverType>(
            '動機は？',
            'なぜそれをしたのか、動機を選択してください',
            DriverType.values,
            state.driver,
            (val) => ref.read(logWizardProvider.notifier).updateDriver(val),
          ),
          WizardReflectionStep(
            selectedGain: state.gain,
            selectedLose: state.lose,
            onGainSelect: (val) => ref.read(logWizardProvider.notifier).updateGain(val),
            onLoseSelect: (val) => ref.read(logWizardProvider.notifier).updateLose(val),
            onComplete: _nextStep,
          ),
          _buildEnumStep<RetroOffsetType>(
            'いつ頃振り返る？',
            '振り返るタイミングを選択してください',
            RetroOffsetType.values,
            state.retroOffset,
            (val) => ref.read(logWizardProvider.notifier).updateRetroOffset(val),
          ),
          _buildQ6Content(state),
        ],
      ),
    );
  }

  // Wrapper for WizardSelectionStep
  Widget _buildEnumStep<T extends Enum>(String title, String subtitle, List<T> items, T? selected, Function(T?) onSelect) {
    return WizardSelectionStep<T>(
      title: title,
      subtitle: subtitle,
      items: items,
      selected: selected,
      onSelect: (val) {
        onSelect(val);
        if (val != null) _nextStep();
      },
      labelBuilder: (item) => (item as dynamic).label,
      scrollController: ScrollController(),
    );
  }

  Widget _buildQ1Content(LogWizardState state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Enable expansion even if content is short
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('記録したい出来事は？', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            focusNode: _q1FocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: AppDesign.inputDecoration(
              hintText: widget.initialHint ?? '例: 30分読書する、新しい靴を買う...',
            ),
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
          _buildSuggestions(state),
          const SizedBox(height: 200),
        ],
      ),
    );
  }


  Widget _buildQ6Content(LogWizardState state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                focusNode: _q6FocusNode,
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
          const SizedBox(height: 150),
          _buildSuggestions(state),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildSuggestions(LogWizardState state) {
    if (state.text.isEmpty) return const SizedBox.shrink();
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(state.text));
    
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
}

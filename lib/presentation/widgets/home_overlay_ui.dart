import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/models/review_proposal.dart';
import 'log_wizard_sheet.dart';
import '../widgets/retro_wizard_sheet.dart';
import '../widgets/action_review_wizard_sheet.dart';
import '../widgets/review_proposal_card.dart';

class HomeOverlayUI extends ConsumerStatefulWidget {
  final VoidCallback? onConstellationTap;
  final GlobalKey? addButtonKey;
  final GlobalKey? constellationButtonKey;
  
  const HomeOverlayUI({
    super.key, 
    this.onConstellationTap,
    this.addButtonKey,
    this.constellationButtonKey,
  });

  @override
  ConsumerState<HomeOverlayUI> createState() => _HomeOverlayUIState();
}

class _HomeOverlayUIState extends ConsumerState<HomeOverlayUI> {
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRotation() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(unifiedProposalsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            proposalsAsync.when(
              data: (proposals) {
                if (proposals.isEmpty) {
                  return _buildFABOnly();
                }

                // Ensure index is within bounds
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (proposals.isNotEmpty) 
                      Expanded(
                        child: ReviewProposalCard(
                          item: proposals[_currentIndex % proposals.length],
                          refreshTrigger: _currentIndex,
                          onTap: () => _startReviewFlow(context, proposals[_currentIndex % proposals.length]),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildConstellationButton(),
                        const SizedBox(height: 12),
                        _buildAddButton(),
                      ],
                    ),
                  ],
                );
              },
              loading: () => _buildFABOnly(),
              error: (e, s) => _buildFABOnly(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFABOnly() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConstellationButton(),
          const SizedBox(height: 12),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      key: widget.addButtonKey,
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () => _showLogWizard(context),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildConstellationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: widget.constellationButtonKey,
        onTap: () {
          final settings = ref.read(settingsProvider);
          if (!settings.hasSeenOnboarding && settings.onboardingStep == 4) {
            ref.read(settingsProvider.notifier).updateOnboardingStep(5);
          }
          widget.onConstellationTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showLogWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LogWizardSheet(),
    );
  }

  void _startReviewFlow(BuildContext context, ReviewProposal proposal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        if (proposal.type == ProposalType.decisionRetro) {
          return RetroWizardSheet(decision: proposal.originalData);
        } else {
          return ActionReviewWizardSheet(declaration: proposal.originalData);
        }
      },
    );
  }
}

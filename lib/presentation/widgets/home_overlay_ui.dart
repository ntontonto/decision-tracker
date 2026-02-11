import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../theme/app_design.dart';
import '../pages/log_wizard_page.dart';
import '../pages/retro_page.dart';

class HomeOverlayUI extends ConsumerStatefulWidget {
  const HomeOverlayUI({super.key});

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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingDecisionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            pendingAsync.when(
              data: (decisions) {
                if (decisions.isEmpty) {
                  return _buildFABOnly();
                }

                // Ensure index is within bounds
                final index = _currentIndex % decisions.length;
                final decision = decisions[index];
                final dateStr = '${decision.retroAt.month}/${decision.retroAt.day}';

                return Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _startReviewFlow(context, decision),
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: AppDesign.glassDecoration(
                            borderRadius: 40,
                            showBorder: false, // User requested removing outer borders
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$dateStr を振り返りませんか？',
                                style: AppDesign.subtitleStyle,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                decision.textContent,
                                style: AppDesign.bodyStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildAddButton(),
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
      child: _buildAddButton(),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () => _showLogWizard(context),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // Ensure perfect circle
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  void _showLogWizard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LogWizardPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _startReviewFlow(BuildContext context, dynamic decision) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewWizardSheet(decision: decision),
    );
  }
}

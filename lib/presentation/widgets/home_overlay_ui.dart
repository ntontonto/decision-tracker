import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../pages/log_wizard_page.dart';
import '../pages/retro_page.dart';

class HomeOverlayUI extends ConsumerWidget {
  const HomeOverlayUI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDecisionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: pendingAsync.when(
                    data: (decisions) {
                      if (decisions.isEmpty) {
                        return _buildEmptyProposal(context);
                      }
                      final decision = decisions.first;
                      final dateStr = '${decision.retroAt.month}/${decision.retroAt.day}';
                      return InkWell(
                        onTap: () => _startReviewFlow(context, decision),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$dateStr を振り返りませんか？',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                decision.textContent,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => _showLogWizard(context),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.add, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProposal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        '振り返る項目はありません。',
        style: TextStyle(color: Colors.white38, fontSize: 14),
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

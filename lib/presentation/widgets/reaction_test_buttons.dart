import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/reaction_providers.dart';

class ReactionTestButtons extends ConsumerWidget {
  const ReactionTestButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.celebration, color: Colors.white70),
          onPressed: () => ref.read(reactionProvider.notifier).trigger(ParticleReaction.celebrate),
        ),
        IconButton(
          icon: const Icon(Icons.vibration, color: Colors.white70),
          onPressed: () => ref.read(reactionProvider.notifier).trigger(ParticleReaction.jitter),
        ),
      ],
    );
  }
}

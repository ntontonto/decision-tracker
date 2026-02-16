import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ParticleReaction {
  none,
  celebrate,
  jitter,
}

class ReactionState {
  final ParticleReaction type;
  ReactionState({required this.type});
}

class ReactionNotifier extends StateNotifier<ReactionState> {
  ReactionNotifier() : super(ReactionState(type: ParticleReaction.none));

  void trigger(ParticleReaction type) {
    state = ReactionState(type: type);
    // Reset after a short delay so it can be re-triggered
    Future.delayed(const Duration(milliseconds: 100), () {
      state = ReactionState(type: ParticleReaction.none);
    });
  }
}

final reactionProvider = StateNotifierProvider<ReactionNotifier, ReactionState>((ref) {
  return ReactionNotifier();
});

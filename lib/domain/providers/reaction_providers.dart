import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ParticleReaction {
  none,
  celebrate,
  jitter,
}

enum WarpType {
  none,
  entering,
  holding,
  exiting,
}

class WarpState {
  final WarpType type;
  final double factor; // 0.0 to 1.0
  
  WarpState({
    this.type = WarpType.none,
    this.factor = 0.0,
  });

  WarpState copyWith({WarpType? type, double? factor}) {
    return WarpState(
      type: type ?? this.type,
      factor: factor ?? this.factor,
    );
  }
}

class WarpNotifier extends StateNotifier<WarpState> {
  WarpNotifier() : super(WarpState());

  void setWarp(WarpType type, double factor) {
    state = state.copyWith(type: type, factor: factor);
  }

  void reset() {
    state = WarpState();
  }
}

final warpProvider = StateNotifierProvider<WarpNotifier, WarpState>((ref) {
  return WarpNotifier();
});

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

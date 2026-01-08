import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class BannerState {
  final bool isVisible;
  final bool isAnimating;

  const BannerState({
    required this.isVisible,
    required this.isAnimating,
  });

  BannerState copyWith({
    bool? isVisible,
    bool? isAnimating,
  }) {
    return BannerState(
      isVisible: isVisible ?? this.isVisible,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

class BannerNotifier extends StateNotifier<BannerState> {
  Timer? _visibilityTimer;
  
  BannerNotifier() : super(const BannerState(isVisible: true, isAnimating: false)) {
    _startVisibilityTimer();
  }

  void _startVisibilityTimer() {
    _visibilityTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      _toggleVisibility();
    });
  }

  void _toggleVisibility() {
    state = state.copyWith(isAnimating: true);
    
    Timer(const Duration(milliseconds: 100), () {
      state = state.copyWith(
        isVisible: !state.isVisible,
        isAnimating: false,
      );
    });
  }

  void show() {
    if (!state.isVisible) {
      state = state.copyWith(isVisible: true, isAnimating: true);
      Timer(const Duration(milliseconds: 100), () {
        state = state.copyWith(isAnimating: false);
      });
    }
  }

  void hide() {
    if (state.isVisible) {
      state = state.copyWith(isVisible: false, isAnimating: true);
      Timer(const Duration(milliseconds: 100), () {
        state = state.copyWith(isAnimating: false);
      });
    }
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }
}

final bannerProvider = StateNotifierProvider<BannerNotifier, BannerState>((ref) {
  return BannerNotifier();
});
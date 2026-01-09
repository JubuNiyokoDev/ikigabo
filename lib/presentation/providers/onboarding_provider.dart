import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preferences_provider.dart' as prefs;

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefsService = await ref.watch(prefs.preferencesServiceProvider.future);
  return prefsService.isOnboardingCompleted();
});

final onboardingNotifierProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(false);

  Future<void> completeOnboarding() async {
    final prefsService = await _ref.read(prefs.preferencesServiceProvider.future);
    await prefsService.setOnboardingCompleted(true);
    state = true;
    _ref.invalidate(onboardingCompleteProvider);
  }
}
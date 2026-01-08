import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';
import 'theme_provider.dart';

final pinProvider = StateNotifierProvider<PinNotifier, PinState>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider).value;
  return PinNotifier(prefsService);
});

class PinNotifier extends StateNotifier<PinState> {
  final PreferencesService? _prefsService;

  PinNotifier(this._prefsService) : super(PinState.loading) {
    _checkPinStatus();
  }

  void _checkPinStatus() {
    if (_prefsService != null) {
      final isEnabled = _prefsService.isPinEnabled();
      final savedPin = _prefsService.getSavedPin();
      
      if (isEnabled && savedPin != null) {
        state = PinState.required;
      } else {
        state = PinState.notSet;
      }
    }
  }

  Future<bool> setPin(String pin) async {
    if (_prefsService != null) {
      final success = await _prefsService.savePin(pin);
      if (success) {
        state = PinState.authenticated;
        return true;
      }
    }
    return false;
  }

  Future<bool> verifyPin(String pin) async {
    if (_prefsService != null) {
      final savedPin = _prefsService.getSavedPin();
      if (savedPin == pin) {
        state = PinState.authenticated;
        return true;
      }
    }
    return false;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (_prefsService != null) {
      final savedPin = _prefsService.getSavedPin();
      if (savedPin == oldPin) {
        return await _prefsService.savePin(newPin);
      }
    }
    return false;
  }

  Future<void> disablePin() async {
    if (_prefsService != null) {
      await _prefsService.disablePin();
      // Marquer comme authentifié pour éviter de redemander un PIN
      state = PinState.authenticated;
    }
  }

  void logout() {
    if (_prefsService?.isPinEnabled() == true) {
      state = PinState.required;
    }
  }

  void skipPinSetup() {
    // Marquer comme skipé temporairement sans sauvegarder de PIN
    state = PinState.authenticated;
  }

  void markAsAuthenticated() {
    state = PinState.authenticated;
  }
}

enum PinState {
  loading,
  notSet,
  required,
  authenticated,
}
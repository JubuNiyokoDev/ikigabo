import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/biometric_service.dart';
import 'theme_provider.dart';

final biometricProvider = StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider).value;
  return BiometricNotifier(prefsService);
});

class BiometricNotifier extends StateNotifier<BiometricState> {
  final PreferencesService? _prefsService;

  BiometricNotifier(this._prefsService) : super(BiometricState.loading) {
    _checkBiometricStatus();
  }

  void _checkBiometricStatus() async {
    final isAvailable = await BiometricService.isAvailable();
    final isEnabled = _prefsService?.isBiometricEnabled() ?? false;
    
    if (!isAvailable) {
      state = BiometricState.unavailable;
    } else if (isEnabled) {
      state = BiometricState.enabled;
    } else {
      state = BiometricState.disabled;
    }
  }

  Future<bool> enableBiometric() async {
    print('Checking biometric availability...');
    final isAvailable = await BiometricService.isAvailable();
    print('Biometric available: $isAvailable');
    if (!isAvailable) return false;

    print('Attempting biometric authentication...');
    final authenticated = await BiometricService.authenticate();
    print('Authentication result: $authenticated');
    if (authenticated && _prefsService != null) {
      print('Saving biometric preference...');
      final success = await _prefsService.setBiometricEnabled(true);
      print('Save result: $success');
      if (success) {
        state = BiometricState.enabled;
        return true;
      }
    }
    return false;
  }

  Future<bool> disableBiometric() async {
    if (_prefsService != null) {
      final success = await _prefsService.setBiometricEnabled(false);
      if (success) {
        state = BiometricState.disabled;
        return true;
      }
    }
    return false;
  }

  Future<bool> authenticateWithBiometric() async {
    if (state == BiometricState.enabled) {
      return await BiometricService.authenticate();
    }
    return false;
  }
}

enum BiometricState {
  loading,
  unavailable,
  disabled,
  enabled,
}
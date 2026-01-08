import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';

// Provider pour le service de préférences
final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  return await PreferencesService.init();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider).value;
  return ThemeNotifier(prefsService);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final PreferencesService? _prefsService;

  ThemeNotifier(this._prefsService) : super(ThemeMode.dark) {
    _loadSavedTheme();
  }

  /// Charger le thème sauvegardé au démarrage
  void _loadSavedTheme() {
    if (_prefsService != null) {
      state = _prefsService.getSavedThemeMode();
    }
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    _prefsService?.saveThemeMode(newMode);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _prefsService?.saveThemeMode(mode);
  }
}

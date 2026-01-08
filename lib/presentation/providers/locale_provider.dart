import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/presentation/providers/theme_provider.dart';
import '../../core/services/preferences_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider).value;
  return LocaleNotifier(prefsService);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final PreferencesService? _prefsService;

  LocaleNotifier(this._prefsService) : super(const Locale('fr')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    if (_prefsService != null) {
      final savedLanguage = _prefsService.getSavedLanguage();
      if (savedLanguage != null) {
        state = Locale(savedLanguage);
      }
    }
  }

  void setLocale(String languageCode) {
    state = Locale(languageCode);
    _prefsService?.saveLanguage(languageCode);
  }

  void setFrench() => setLocale('fr');
  void setEnglish() => setLocale('en');
  void setKirundi() => setLocale('rn');
  void setSwahili() => setLocale('sw');

  String get currentLanguageName {
    switch (state.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'rn':
        return 'Kirundi';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'Français';
    }
  }

  List<Map<String, String>> get availableLanguages => [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'rn', 'name': 'Kirundi', 'flag': '🇧🇮'},
    {'code': 'sw', 'name': 'Kiswahili', 'flag': '🇹🇿'},
  ];
}

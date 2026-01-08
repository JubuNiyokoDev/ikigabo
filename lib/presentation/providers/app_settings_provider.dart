import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppTheme { light, dark, system }

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final FlutterSecureStorage _storage;

  AppSettingsNotifier(this._storage) : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeString = await _storage.read(key: 'app_theme');
    final locale = await _storage.read(key: 'app_locale');

    state = state.copyWith(
      theme: AppTheme.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => AppTheme.system,
      ),
      locale: locale != null ? Locale(locale) : const Locale('fr'),
    );
  }

  Future<void> setTheme(AppTheme theme) async {
    await _storage.write(key: 'app_theme', value: theme.name);
    state = state.copyWith(theme: theme);
  }

  Future<void> setLocale(Locale locale) async {
    await _storage.write(key: 'app_locale', value: locale.languageCode);
    state = state.copyWith(locale: locale);
  }
}

class AppSettings {
  final AppTheme theme;
  final Locale locale;

  AppSettings({
    this.theme = AppTheme.system,
    this.locale = const Locale('fr'),
  });

  AppSettings copyWith({
    AppTheme? theme,
    Locale? locale,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(const FlutterSecureStorage());
});
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service pour gérer les préférences de l'application
class PreferencesService {
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'default_currency';
  static const String _pinKey = 'user_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _notificationDebtRemindersKey = 'notification_debt_reminders';
  static const String _notificationBankFeesKey = 'notification_bank_fees';
  static const String _notificationWealthKey = 'notification_wealth';
  static const String _notificationBackupKey = 'notification_backup';
  static const String _notificationOverdueKey = 'notification_overdue';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _lastBackupDateKey = 'last_backup_date';
  static const String _lowBalanceThresholdKey = 'low_balance_threshold';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Initialiser le service
  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // === LANGUE ===

  /// Récupérer la langue sauvegardée
  String? getSavedLanguage() {
    return _prefs.getString(_languageKey);
  }

  /// Sauvegarder la langue
  Future<bool> saveLanguage(String languageCode) async {
    return await _prefs.setString(_languageKey, languageCode);
  }

  // === THÈME ===

  /// Récupérer le thème sauvegardé
  ThemeMode getSavedThemeMode() {
    final themeModeString = _prefs.getString(_themeKey);
    if (themeModeString == null) {
      return ThemeMode.dark; // Défaut: dark
    }

    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  /// Sauvegarder le thème
  Future<bool> saveThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    return await _prefs.setString(_themeKey, modeString);
  }

  // === DEVISE ===

  /// Récupérer la devise sauvegardée
  String getSavedCurrency() {
    return _prefs.getString(_currencyKey) ?? 'BIF'; // Défaut: BIF
  }

  /// Sauvegarder la devise
  Future<bool> saveCurrency(String currencyCode) async {
    return await _prefs.setString(_currencyKey, currencyCode);
  }

  // === PIN ===

  /// Vérifier si le PIN est activé
  bool isPinEnabled() {
    return _prefs.getBool(_pinEnabledKey) ?? false;
  }

  /// Récupérer le PIN sauvegardé
  String? getSavedPin() {
    return _prefs.getString(_pinKey);
  }

  /// Sauvegarder le PIN
  Future<bool> savePin(String pin) async {
    final success = await _prefs.setString(_pinKey, pin);
    if (success) {
      await _prefs.setBool(_pinEnabledKey, true);
    }
    return success;
  }

  /// Désactiver le PIN
  Future<bool> disablePin() async {
    await _prefs.remove(_pinKey);
    return await _prefs.setBool(_pinEnabledKey, false);
  }

  // === BIOMÉTRIE ===

  /// Vérifier si la biométrie est activée
  bool isBiometricEnabled() {
    return _prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Activer/désactiver la biométrie
  Future<bool> setBiometricEnabled(bool enabled) async {
    return await _prefs.setBool(_biometricEnabledKey, enabled);
  }

  // === NOTIFICATIONS ===

  /// Récupérer les préférences de notifications
  bool getDebtRemindersEnabled() => _prefs.getBool(_notificationDebtRemindersKey) ?? true;
  bool getBankFeesEnabled() => _prefs.getBool(_notificationBankFeesKey) ?? true;
  bool getWealthMilestonesEnabled() => _prefs.getBool(_notificationWealthKey) ?? true;
  bool getBackupRemindersEnabled() => _prefs.getBool(_notificationBackupKey) ?? true;
  bool getOverdueAlertsEnabled() => _prefs.getBool(_notificationOverdueKey) ?? true;

  /// Sauvegarder les préférences de notifications
  Future<bool> setDebtRemindersEnabled(bool enabled) => _prefs.setBool(_notificationDebtRemindersKey, enabled);
  Future<bool> setBankFeesEnabled(bool enabled) => _prefs.setBool(_notificationBankFeesKey, enabled);
  Future<bool> setWealthMilestonesEnabled(bool enabled) => _prefs.setBool(_notificationWealthKey, enabled);
  Future<bool> setBackupRemindersEnabled(bool enabled) => _prefs.setBool(_notificationBackupKey, enabled);
  Future<bool> setOverdueAlertsEnabled(bool enabled) => _prefs.setBool(_notificationOverdueKey, enabled);

  // === BACKUP ===

  /// Vérifier si la sauvegarde automatique est activée
  bool isAutoBackupEnabled() => _prefs.getBool(_autoBackupEnabledKey) ?? true;

  /// Activer/désactiver la sauvegarde automatique
  Future<bool> setAutoBackupEnabled(bool enabled) => _prefs.setBool(_autoBackupEnabledKey, enabled);

  /// Récupérer la date de dernière sauvegarde
  DateTime? getLastBackupDate() {
    final timestamp = _prefs.getInt(_lastBackupDateKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Sauvegarder la date de dernière sauvegarde
  Future<bool> setLastBackupDate(DateTime date) => _prefs.setInt(_lastBackupDateKey, date.millisecondsSinceEpoch);

  // === SEUILS ===

  /// Récupérer le seuil de solde faible
  double getLowBalanceThreshold() => _prefs.getDouble(_lowBalanceThresholdKey) ?? 10000.0;

  /// Sauvegarder le seuil de solde faible
  Future<bool> setLowBalanceThreshold(double threshold) => _prefs.setDouble(_lowBalanceThresholdKey, threshold);

  // === ONBOARDING ===

  /// Vérifier si l'onboarding est terminé
  bool isOnboardingCompleted() => _prefs.getBool(_onboardingCompletedKey) ?? false;

  /// Marquer l'onboarding comme terminé
  Future<bool> setOnboardingCompleted(bool completed) => _prefs.setBool(_onboardingCompletedKey, completed);

  /// Méthodes génériques pour bool
  bool getBool(String key) => _prefs.getBool(key) ?? false;
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  /// Effacer toutes les préférences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Effacer toutes les données sauf langue et thème
  Future<bool> clearAllData() async {
    // Sauvegarder langue et thème
    final language = getSavedLanguage();
    final theme = getSavedThemeMode();
    
    // Effacer tout
    await _prefs.clear();
    
    // Restaurer langue et thème
    if (language != null) {
      await saveLanguage(language);
    }
    await saveThemeMode(theme);
    
    return true;
  }

  /// Méthodes pour compatibilité avec les providers
  Future<bool> setLanguage(String languageCode) => saveLanguage(languageCode);
  Future<bool> setThemeMode(ThemeMode mode) => saveThemeMode(mode);
}

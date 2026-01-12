import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/services/auto_backup_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/ad_manager.dart';
import 'backup_provider.dart';

final autoBackupProvider =
    StateNotifierProvider<AutoBackupNotifier, AutoBackupState>((ref) {
      return AutoBackupNotifier(ref);
    });

class AutoBackupState {
  final bool isEnabled;
  final DateTime? lastBackupDate;
  final bool isBackingUp;
  final String? error;

  const AutoBackupState({
    this.isEnabled = true,
    this.lastBackupDate,
    this.isBackingUp = false,
    this.error,
  });

  AutoBackupState copyWith({
    bool? isEnabled,
    DateTime? lastBackupDate,
    bool? isBackingUp,
    String? error,
  }) {
    return AutoBackupState(
      isEnabled: isEnabled ?? this.isEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      error: error,
    );
  }
}

class AutoBackupNotifier extends StateNotifier<AutoBackupState> {
  final Ref _ref;

  AutoBackupNotifier(this._ref) : super(const AutoBackupState()) {
    _loadSettings();
    _initializeAutoBackup();
  }

  Future<void> _initializeAutoBackup() async {
    await AutoBackupService.initialize(
      onBackupNeeded: () => _performAutoBackupInternal(),
    );
  }

  Future<void> _performAutoBackupInternal() async {
    try {
      final backupService = _ref.read(backupServiceProvider);
      final backupData = await backupService.exportData();
      await AutoBackupService.saveAutoBackup(backupData);
      
      final prefs = await PreferencesService.init();
      final lastBackup = prefs.getLastBackupDate();
      state = state.copyWith(lastBackupDate: lastBackup);
    } catch (e) {
      print('Erreur auto-backup interne: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await PreferencesService.init();
    state = state.copyWith(
      isEnabled: prefs.isAutoBackupEnabled(),
      lastBackupDate: prefs.getLastBackupDate(),
    );
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    state = state.copyWith(isBackingUp: true);

    try {
      final prefs = await PreferencesService.init();
      await prefs.setAutoBackupEnabled(enabled);

      state = state.copyWith(isEnabled: enabled, isBackingUp: false);

      if (enabled) {
        await _initializeAutoBackup();
      } else {
        AutoBackupService.dispose();
      }
    } catch (e) {
      state = state.copyWith(isBackingUp: false, error: e.toString());
    }
  }

  Future<void> performManualBackup() async {
    if (state.isBackingUp) return;

    state = state.copyWith(isBackingUp: true, error: null);

    try {
      final canProceed = await AdManager.showRewardedForAutoBackup();
      if (!canProceed) {
        state = state.copyWith(isBackingUp: false);
        return;
      }

      final backupService = _ref.read(backupServiceProvider);
      final backupData = await backupService.exportData();
      await AutoBackupService.saveAutoBackup(backupData);

      final prefs = await PreferencesService.init();
      final lastBackup = prefs.getLastBackupDate();
      
      state = state.copyWith(isBackingUp: false, lastBackupDate: lastBackup);
    } catch (e) {
      state = state.copyWith(isBackingUp: false, error: e.toString());
    }
  }

  Future<void> importBackup() async {
    // Import manuel seulement - pas d'auto-import
    state = state.copyWith(error: 'Utilisez le menu Sauvegarde pour importer');
  }
}

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auto_backup_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/ad_manager.dart';
import '../../core/services/google_drive_service.dart';
import 'backup_provider.dart';
import 'isar_provider.dart';

final autoBackupProvider =
    StateNotifierProvider<AutoBackupNotifier, AutoBackupState>((ref) {
      return AutoBackupNotifier(ref);
    });

class AutoBackupState {
  final bool isEnabled;
  final DateTime? lastBackupDate;
  final bool isBackingUp;
  final String? error;

  // Google Drive
  final bool isDriveConnected;
  final String? driveUserEmail;

  const AutoBackupState({
    this.isEnabled = true,
    this.lastBackupDate,
    this.isBackingUp = false,
    this.error,
    this.isDriveConnected = false,
    this.driveUserEmail,
  });

  AutoBackupState copyWith({
    bool? isEnabled,
    DateTime? lastBackupDate,
    bool? isBackingUp,
    String? error,
    bool? isDriveConnected,
    String? driveUserEmail,
  }) {
    return AutoBackupState(
      isEnabled: isEnabled ?? this.isEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      error: error,
      isDriveConnected: isDriveConnected ?? this.isDriveConnected,
      driveUserEmail: driveUserEmail ?? this.driveUserEmail,
    );
  }
}

class AutoBackupNotifier extends StateNotifier<AutoBackupState> {
  final Ref _ref;

  AutoBackupNotifier(this._ref) : super(const AutoBackupState()) {
    _loadSettings();
    _initializeAutoBackup();
    _checkDriveStatus();
  }

  void _checkDriveStatus() {
    final connected = GoogleDriveService.isSignedIn;
    state = state.copyWith(
      isDriveConnected: connected,
      driveUserEmail: GoogleDriveService.userEmail,
    );
  }

  Future<void> _initializeAutoBackup() async {
    await _ref.read(isarProvider.future);
    await AutoBackupService.initialize(
      onBackupNeeded: _performAutoBackupInternal,
    );
  }

  /// Retourne les données du backup pour upload Drive
  Future<String> _performAutoBackupInternal() async {
    await _ref.read(isarProvider.future);
    final backupService = _ref.read(backupServiceProvider);
    final backupData = await backupService.exportData();
    await AutoBackupService.saveAutoBackup(backupData);

    final prefs = await PreferencesService.init();
    final lastBackup = prefs.getLastBackupDate();
    state = state.copyWith(lastBackupDate: lastBackup);

    return backupData;
  }

  Future<void> _loadSettings() async {
    final prefs = await PreferencesService.init();
    state = state.copyWith(
      isEnabled: prefs.isAutoBackupEnabled(),
      lastBackupDate: prefs.getLastBackupDate(),
      isDriveConnected: GoogleDriveService.isSignedIn,
      driveUserEmail: GoogleDriveService.userEmail,
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
      await _ref.read(isarProvider.future);
      final canProceed = await AdManager.showRewardedForAutoBackup();
      if (!canProceed) {
        state = state.copyWith(isBackingUp: false);
        return;
      }

      final backupData = await _performAutoBackupInternal();

      // Upload Drive si connecté
      if (GoogleDriveService.isSignedIn) {
        await GoogleDriveService.uploadBackup(backupData);
      }

      final prefs = await PreferencesService.init();
      final lastBackup = prefs.getLastBackupDate();

      state = state.copyWith(isBackingUp: false, lastBackupDate: lastBackup);
    } catch (e) {
      state = state.copyWith(isBackingUp: false, error: e.toString());
    }
  }

  // === Google Drive ===

  Future<void> connectDrive() async {
    state = state.copyWith(isBackingUp: true, error: null);
    try {
      final success = await GoogleDriveService.signIn();
      state = state.copyWith(
        isBackingUp: false,
        isDriveConnected: success,
        driveUserEmail: success ? GoogleDriveService.userEmail : null,
        error: success ? null : 'Connexion Google échouée',
      );
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        error: 'Erreur connexion: $e',
      );
    }
  }

  Future<void> disconnectDrive() async {
    await GoogleDriveService.signOut();
    state = state.copyWith(
      isDriveConnected: false,
      driveUserEmail: null,
    );
  }

  Future<void> importBackup() async {
    state = state.copyWith(error: 'Utilisez le menu Sauvegarde pour importer');
  }
}

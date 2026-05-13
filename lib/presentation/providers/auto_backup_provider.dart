import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/bank_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/source_model.dart';
import '../../data/models/transaction_model.dart';
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
  static const Object _unset = Object();

  final bool isEnabled;
  final DateTime? lastBackupDate;
  final bool isBackingUp;
  final String? error;

  // Google Drive
  final bool isDriveConnected;
  final String? driveUserEmail;
  final bool isDriveBusy;

  // Taille du backup en MB (calculée en background)
  final double? pendingSyncMB;
  final String? pendingBackupData;

  const AutoBackupState({
    this.isEnabled = false,
    this.lastBackupDate,
    this.isBackingUp = false,
    this.error,
    this.isDriveConnected = false,
    this.driveUserEmail,
    this.isDriveBusy = false,
    this.pendingSyncMB,
    this.pendingBackupData,
  });

  AutoBackupState copyWith({
    bool? isEnabled,
    DateTime? lastBackupDate,
    bool? isBackingUp,
    Object? error = _unset,
    bool? isDriveConnected,
    Object? driveUserEmail = _unset,
    bool? isDriveBusy,
    Object? pendingSyncMB = _unset,
    Object? pendingBackupData = _unset,
  }) {
    return AutoBackupState(
      isEnabled: isEnabled ?? this.isEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      error: identical(error, _unset) ? this.error : error as String?,
      isDriveConnected: isDriveConnected ?? this.isDriveConnected,
      driveUserEmail: identical(driveUserEmail, _unset)
          ? this.driveUserEmail
          : driveUserEmail as String?,
      isDriveBusy: isDriveBusy ?? this.isDriveBusy,
      pendingSyncMB: identical(pendingSyncMB, _unset)
          ? this.pendingSyncMB
          : pendingSyncMB as double?,
      pendingBackupData: identical(pendingBackupData, _unset)
          ? this.pendingBackupData
          : pendingBackupData as String?,
    );
  }
}

class AutoBackupNotifier extends StateNotifier<AutoBackupState> {
  final Ref _ref;

  AutoBackupNotifier(this._ref) : super(const AutoBackupState()) {
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _loadSettings();
    await refreshDriveStatus();

    if (state.isEnabled) {
      await _initializeAutoBackup();
    } else {
      AutoBackupService.dispose();
    }

    // Pré-calculer la taille si Drive connecté et données modifiées depuis dernier sync
    if (state.isDriveConnected) {
      final prefs = await PreferencesService.init();
      final lastSync = prefs.getLastDriveSyncDate();
      final lastChange = await _getLastDataChangeDate();
      if (lastSync == null ||
          lastChange == null ||
          lastChange.isAfter(lastSync)) {
        unawaited(computePendingSyncSize());
      }
    }
  }

  Future<DateTime?> _getLastDataChangeDate() async {
    final isar = await _ref.read(isarProvider.future);
    DateTime? latest;
    void check(DateTime? d) {
      if (d != null && (latest == null || d.isAfter(latest!))) latest = d;
    }

    final txList = await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false).sortByCreatedAtDesc()
        .findAll();
    for (final e in txList) {
      check(e.updatedAt ?? e.createdAt);
    }

    final srcList = await isar.sourceModels.filter().isDeletedEqualTo(false).sortByCreatedAtDesc().findAll();
    for (final e in srcList) {
      check(e.updatedAt ?? e.createdAt);
    }

    final bankList = await isar.bankModels.filter().isDeletedEqualTo(false).sortByCreatedAtDesc().findAll();
    for (final e in bankList) {
      check(e.updatedAt ?? e.createdAt);
    }

    final debtList = await isar.debtModels.filter().isDeletedEqualTo(false).sortByCreatedAtDesc().findAll();
    for (final e in debtList) {
      check(e.updatedAt ?? e.createdAt);
    }

    final assetList = await isar.assetModels
        .filter()
        .isDeletedEqualTo(false).sortByCreatedAtDesc()
        .findAll();
    for (final e in assetList) {
      check(e.updatedAt ?? e.createdAt);
    }

    return latest;
  }

  Future<void> computePendingSyncSize() async {
    try {
      await _ref.read(isarProvider.future);
      final backupService = _ref.read(backupServiceProvider);
      final data = await backupService.exportData();
      final mb = GoogleDriveService.calculateBackupSizeMB(data);
      state = state.copyWith(pendingSyncMB: mb, pendingBackupData: data);
    } catch (_) {}
  }

  Future<void> refreshDriveStatus() async {
    final connected = await GoogleDriveService.isUserSignedIn();
    state = state.copyWith(
      isDriveConnected: connected,
      driveUserEmail: connected ? GoogleDriveService.userEmail : null,
    );
  }

  Future<void> _initializeAutoBackup({bool runImmediately = false}) async {
    await _ref.read(isarProvider.future);

    final prefs = await PreferencesService.init();
    if (!prefs.isAutoBackupEnabled()) {
      AutoBackupService.dispose();
      return;
    }

    await AutoBackupService.initialize(
      onBackupNeeded: _performAutoBackupInternal,
      runImmediately: runImmediately,
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
      error: null,
    );
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    state = state.copyWith(isBackingUp: true);

    try {
      final prefs = await PreferencesService.init();
      await prefs.setAutoBackupEnabled(enabled);

      state = state.copyWith(isEnabled: enabled, isBackingUp: false);

      if (enabled) {
        await _initializeAutoBackup(runImmediately: true);
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

  Future<bool> connectDrive() async {
    if (state.isDriveBusy) return false;

    state = state.copyWith(isDriveBusy: true, error: null);
    try {
      final success = await GoogleDriveService.signIn();
      state = state.copyWith(
        isDriveBusy: false,
        isDriveConnected: success,
        driveUserEmail: success ? GoogleDriveService.userEmail : null,
        error: success ? null : 'Connexion Google échouée',
      );
      if (success) unawaited(computePendingSyncSize());
      return success;
    } catch (e) {
      state = state.copyWith(isDriveBusy: false, error: 'Erreur connexion: $e');
      return false;
    }
  }

  Future<void> disconnectDrive() async {
    state = state.copyWith(isDriveBusy: true, error: null);
    await GoogleDriveService.signOut();
    state = state.copyWith(
      isDriveBusy: false,
      isDriveConnected: false,
      driveUserEmail: null,
      pendingSyncMB: null,
      pendingBackupData: null,
    );
  }

  Future<bool> performDriveSync({
    void Function(double uploadedMB, double totalMB, double percent)?
    onProgress,
  }) async {
    if (state.isBackingUp) return false;

    state = state.copyWith(isBackingUp: true, error: null);
    try {
      final connected = await GoogleDriveService.isUserSignedIn();
      if (!connected) {
        state = state.copyWith(
          isBackingUp: false,
          isDriveConnected: false,
          driveUserEmail: null,
          error: 'Connectez Google Drive avant de synchroniser',
        );
        return false;
      }

      final backupData =
          state.pendingBackupData ?? await _performAutoBackupInternal();
      final uploaded = await GoogleDriveService.uploadBackup(
        backupData,
        onProgress: onProgress,
      );
      final prefs = await PreferencesService.init();
      final lastBackup = prefs.getLastBackupDate();
      if (uploaded) await prefs.setLastDriveSyncDate(DateTime.now());

      state = state.copyWith(
        isBackingUp: false,
        lastBackupDate: lastBackup,
        isDriveConnected: true,
        driveUserEmail: GoogleDriveService.userEmail,
        error: uploaded ? null : 'Upload Google Drive échoué',
        pendingSyncMB: uploaded ? 0.0 : state.pendingSyncMB,
        pendingBackupData: uploaded ? null : state.pendingBackupData,
      );

      return uploaded;
    } catch (e) {
      state = state.copyWith(
        isBackingUp: false,
        error: 'Erreur synchronisation Drive: $e',
      );
      return false;
    }
  }

  Future<void> importBackup() async {
    state = state.copyWith(error: 'Utilisez le menu Sauvegarde pour importer');
  }
}

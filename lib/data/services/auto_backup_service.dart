import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/ad_manager.dart';

class AutoBackupService {
  static Timer? _timer;
  static const Duration _checkInterval = Duration(hours: 1);
  static Function()? _backupCallback;

  static Future<void> initialize({Function()? onBackupNeeded}) async {
    _backupCallback = onBackupNeeded;
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) => _checkAndBackup());
    
    // Vérifier immédiatement au démarrage
    await _checkAndBackup();
  }

  static Future<void> _checkAndBackup() async {
    final prefs = await PreferencesService.init();
    
    if (!prefs.isAutoBackupEnabled()) return;

    final lastBackup = prefs.getLastBackupDate();
    final now = DateTime.now();
    
    // Vérifier si 24h se sont écoulées
    if (lastBackup == null || now.difference(lastBackup).inHours >= 24) {
      await _performAutoBackup(prefs);
    }
  }

  static Future<void> _performAutoBackup(PreferencesService prefs) async {
    try {
      // Vérifier les ads si nécessaire
      final canProceed = await AdManager.showRewardedForImportExport();
      if (!canProceed) return;

      // Déclencher le callback pour que le provider fasse le backup
      if (_backupCallback != null) {
        _backupCallback!();
      }
      
      print('Auto-backup déclenché avec succès');
    } catch (e) {
      print('Erreur auto-backup: $e');
    }
  }

  static Future<void> saveAutoBackup(String backupData) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${documentsDir.path}/Ikigabo/AutoBackups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = DateTime.now();
    final dateFormat = DateFormat('dd-MMM-yyyy_HH\'h\'mm');
    final filename = 'auto_backup_${dateFormat.format(now)}.json';
    
    final file = File('${backupDir.path}/$filename');
    await file.writeAsString(backupData);
    
    // Nettoyer les anciens backups (garder seulement les 7 derniers)
    await _cleanOldBackups(backupDir);
    
    // Mettre à jour la date de dernière sauvegarde
    final prefs = await PreferencesService.init();
    await prefs.setLastBackupDate(DateTime.now());
  }

  static Future<void> _cleanOldBackups(Directory backupDir) async {
    final files = await backupDir.list().where((f) => f is File).cast<File>().toList();
    
    if (files.length > 7) {
      // Trier par date de modification
      files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      
      // Supprimer les plus anciens
      for (int i = 0; i < files.length - 7; i++) {
        await files[i].delete();
      }
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
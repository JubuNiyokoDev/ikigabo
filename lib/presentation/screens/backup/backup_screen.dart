import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ikigabo/data/services/backup_service.dart';
import 'dart:io';
import 'package:ikigabo/presentation/screens/security/pin_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../../core/services/ad_manager.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  void _loadLastBackupDate() async {
    final prefs = ref.read(preferencesServiceProvider).value;
    prefs?.getLastBackupDate();
    // Utiliser lastBackup pour afficher la dernière sauvegarde
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final backupState = ref.watch(backupControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            AppIcons.back,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        title: Text(
          l10n.backupRestore,
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Export Section
          _buildSection(l10n.backup, isDark),
          _buildActionCard(
            icon: AppIcons.export,
            title: l10n.createBackup,
            subtitle: l10n.exportAllData,
            onTap: () => _showExportDialog(context, l10n, isDark),
            isDark: isDark,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // Import Section
          _buildSection(l10n.restoreBackup, isDark),
          _buildActionCard(
            icon: AppIcons.import,
            title: l10n.restoreBackup,
            subtitle: l10n.importFromFile,
            onTap: () => _showImportDialog(context, l10n, isDark),
            isDark: isDark,
          ).animate().fadeIn(delay: 200.ms),

          if (backupState.isLoading || _isAuthenticating) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.back,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    // D'abord authentifier l'utilisateur
    _authenticateUser(context, l10n, () {
      // Puis montrer le dialogue d'export
      _showExportOptionsDialog(context, l10n, isDark);
    });
  }

  void _authenticateUser(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onSuccess,
  ) async {
    setState(() => _isAuthenticating = true);

    try {
      // Vérifier biométrie d'abord
      final biometricState = ref.read(biometricProvider);
      if (biometricState == BiometricState.enabled) {
        final success = await ref
            .read(biometricProvider.notifier)
            .authenticateWithBiometric();
        if (success) {
          onSuccess();
          return;
        }
      }

      // Sinon vérifier PIN
      final prefsService = ref.read(preferencesServiceProvider).value;
      if (prefsService?.isPinEnabled() == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              mode: PinMode.verify,
              onSuccess: () {
                Navigator.pop(context);
                onSuccess();
              },
            ),
          ),
        );
        return;
      }

      // Aucune sécurité configurée
      onSuccess();
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  void _showExportOptionsDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text(l10n.protectWithPassword),
              value: _usePassword,
              onChanged: (value) {
                setState(() => _usePassword = value ?? false);
                Navigator.pop(dialogContext);
                _showExportDialog(context, l10n, isDark);
              },
            ),
            if (_usePassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _exportData();
            },
            child: Text(l10n.export),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.restoreBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.selectBackupFile),
            const SizedBox(height: 16),
            Text(
              l10n.backupLocationHint,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _authenticateUser(context, l10n, () {
                _selectAndImportFile(context, l10n);
              });
            },
            child: Text(l10n.selectFile),
          ),
        ],
      ),
    );
  }

  void _selectAndImportFile(BuildContext context, AppLocalizations l10n) async {
    try {
      // Utiliser FilePicker sans initialDirectory pour éviter les restrictions
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: l10n.selectBackupFile,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        _processImport(content, l10n);
      }
    } catch (e) {
      _showErrorDialog('${l10n.error}: $e');
    }
  }

  void _processImport(String content, AppLocalizations l10n) async {
    setState(() => _isAuthenticating = true);

    try {
      // Essayer d'importer sans mot de passe d'abord
      final importResult = await ref
          .read(backupControllerProvider.notifier)
          .importData(content);

      if (!importResult.success) {
        // Si échec, demander mot de passe
        _showPasswordDialog(content, l10n);
        return;
      }

      if (importResult.conflicts.isNotEmpty) {
        _showConflictDialog(importResult, l10n);
      } else {
        await ref
            .read(backupControllerProvider.notifier)
            .applyImport(importResult.data!);
        // Montrer rewarded pour import réussi
        await AdManager.showRewardedForImportExport();
        _showSuccessDialog(l10n.dataImportedSuccess);
      }
    } catch (e) {
      _showErrorDialog('${l10n.error}: $e');
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  void _showPasswordDialog(String content, AppLocalizations l10n) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.password),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: l10n.password,
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final importResult = await ref
                    .read(backupControllerProvider.notifier)
                    .importData(content, password: passwordController.text);

                if (importResult.success) {
                  if (importResult.conflicts.isNotEmpty) {
                    _showConflictDialog(importResult, l10n);
                  } else {
                    await ref
                        .read(backupControllerProvider.notifier)
                        .applyImport(importResult.data!);
                    _showSuccessDialog(l10n.dataImportedSuccess);
                  }
                } else {
                  _showErrorDialog(importResult.error ?? l10n.unknownError);
                }
              } catch (e) {
                _showErrorDialog('${l10n.error}: $e');
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog(ImportResult importResult, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.conflictsDetected),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.existingDataMessage),
            const SizedBox(height: 8),
            ...importResult.conflicts.map((conflict) => Text('• $conflict')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(backupControllerProvider.notifier)
                  .applyImport(importResult.data!, overwriteConflicts: false);
              _showSuccessDialog(l10n.dataImportedIgnored);
            },
            child: Text(l10n.ignore),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(backupControllerProvider.notifier)
                  .applyImport(importResult.data!, overwriteConflicts: true);
              _showSuccessDialog(l10n.dataImportedOverwritten);
            },
            child: Text(l10n.overwrite),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isAuthenticating = true);

    try {
      final password = _usePassword ? _passwordController.text : null;
      final backupData = await ref
          .read(backupControllerProvider.notifier)
          .exportData(password: password);

      // Sauvegarder la date de dernière sauvegarde
      final prefs = ref.read(preferencesServiceProvider).value;
      await prefs?.setLastBackupDate(DateTime.now());

      // Sauvegarder dans le stockage interne
      await ref
          .read(backupControllerProvider.notifier)
          .saveBackupToStorage(backupData);

      if (mounted) {
        // Montrer rewarded pour export réussi
        await AdManager.showRewardedForImportExport();
        _showSuccessDialog(
          '${l10n.backupCreatedSuccess}\n\n${l10n.fileSavedIn}\n${l10n.downloadsIkigaboPath}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('${l10n.error}: $e');
      }
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  void _showSuccessDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(l10n.success),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}

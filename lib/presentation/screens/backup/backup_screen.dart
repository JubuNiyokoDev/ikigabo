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
import '../../providers/auto_backup_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../../core/services/ad_manager.dart';
import '../../../core/services/google_drive_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  bool _isAuthenticating = false;
  String? _operationLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(preferencesServiceProvider).value;
      prefs?.getLastBackupDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final backupState = ref.watch(backupControllerProvider);
    final isBusy =
        backupState.isLoading || _isAuthenticating || _operationLabel != null;

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
          if (_operationLabel != null) ...[
            _buildOperationBanner(
              _operationLabel!,
              isDark,
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 20),
          ],

          _buildSection(l10n.backup, isDark),
          _buildActionCard(
            icon: AppIcons.export,
            title: l10n.createBackup,
            subtitle: l10n.exportAllData,
            onTap: isBusy
                ? null
                : () => _showExportDialog(context, l10n, isDark),
            isDark: isDark,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          _buildSection(l10n.restoreBackup, isDark),
          _buildActionCard(
            icon: AppIcons.import,
            title: l10n.restoreBackup,
            subtitle: l10n.importFromFile,
            onTap: isBusy
                ? null
                : () => _showImportDialog(context, l10n, isDark),
            isDark: isDark,
          ).animate().fadeIn(delay: 200.ms),
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
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.58 : 1,
      child: Container(
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
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.black54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationBanner(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    _authenticateUser(context, l10n, () {
      _showExportOptionsDialog(context, l10n, isDark);
    });
  }

  void _authenticateUser(
    BuildContext context,
    AppLocalizations l10n,
    VoidCallback onSuccess,
  ) async {
    setState(() {
      _isAuthenticating = true;
      _operationLabel = 'Vérification sécurisée';
    });

    try {
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

      onSuccess();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _operationLabel = null;
        });
      }
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
    setState(() {
      _isAuthenticating = true;
      _operationLabel = 'Restauration de la sauvegarde';
    });

    try {
      final importResult = await ref
          .read(backupControllerProvider.notifier)
          .importData(content);

      if (!importResult.success) {
        _showPasswordDialog(content, l10n);
        return;
      }

      await ref
          .read(backupControllerProvider.notifier)
          .applyImport(
            importResult.data!,
            strategy: ImportConflictStrategy.smartMerge,
          );
      await AdManager.showRewardedForImportExport();
      await _syncDriveAfterChange();
      _showSuccessDialog(l10n.dataImportedSuccess);
    } catch (e) {
      _showErrorDialog('${l10n.error}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _operationLabel = null;
        });
      }
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
              if (mounted) {
                setState(() {
                  _isAuthenticating = true;
                  _operationLabel = 'Déchiffrement de la sauvegarde';
                });
              }
              try {
                final importResult = await ref
                    .read(backupControllerProvider.notifier)
                    .importData(content, password: passwordController.text);

                if (importResult.success) {
                  await ref
                      .read(backupControllerProvider.notifier)
                      .applyImport(
                        importResult.data!,
                        strategy: ImportConflictStrategy.smartMerge,
                      );
                  await _syncDriveAfterChange();
                  _showSuccessDialog(l10n.dataImportedSuccess);
                } else {
                  _showErrorDialog(importResult.error ?? l10n.unknownError);
                }
              } catch (e) {
                _showErrorDialog('${l10n.error}: $e');
              } finally {
                if (mounted) {
                  setState(() {
                    _isAuthenticating = false;
                    _operationLabel = null;
                  });
                }
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

    setState(() {
      _isAuthenticating = true;
      _operationLabel = 'Création de la sauvegarde';
    });

    try {
      final password = _usePassword ? _passwordController.text : null;
      final backupData = await ref
          .read(backupControllerProvider.notifier)
          .exportData(password: password);

      final prefs = ref.read(preferencesServiceProvider).value;
      await prefs?.setLastBackupDate(DateTime.now());

      await ref
          .read(backupControllerProvider.notifier)
          .saveBackupToStorage(backupData);
      await _syncDriveAfterChange();

      if (mounted) {
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
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _operationLabel = null;
        });
      }
    }
  }

  Future<void> _syncDriveAfterChange() async {
    if (!await GoogleDriveService.isUserSignedIn()) return;
    if (!mounted) return;
    setState(() => _operationLabel = 'Synchronisation Google Drive');
    await ref.read(autoBackupProvider.notifier).performDriveSync();
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

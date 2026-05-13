import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/auto_backup_provider.dart';
import '../../providers/theme_provider.dart';

class DriveBackupScreen extends ConsumerWidget {
  const DriveBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final state = ref.watch(autoBackupProvider);
    final isDark = themeMode == ThemeMode.dark;

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
          'Google Drive',
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Compte Google', isDark),
          _buildStatusTile(state, isDark).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          _buildSection('Sauvegarde', isDark),
          _buildAutoBackupTile(ref, state, isDark).animate().fadeIn(delay: 160.ms),

          if (state.error != null) ...[
            const SizedBox(height: 12),
            _buildErrorTile(state.error!, isDark).animate().fadeIn(delay: 180.ms),
          ],

          const SizedBox(height: 20),

          _buildSection('Actions', isDark),
          if (state.isDriveConnected) ...[
            _buildSyncTile(context, ref, state, isDark).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Déconnecter Google Drive',
              subtitle: 'Retirer ce compte de la synchronisation',
              color: AppColors.error,
              isLoading: state.isDriveBusy,
              isDark: isDark,
              onTap: state.isDriveBusy ? null : () => _disconnect(context, ref),
            ).animate().fadeIn(delay: 260.ms),
          ] else
            _buildActionTile(
              icon: Icons.login,
              title: 'Connecter Google Drive',
              subtitle: 'Choisir un compte Google pour la sauvegarde',
              isLoading: state.isDriveBusy,
              isDark: isDark,
              onTap: state.isDriveBusy ? null : () => _connect(context, ref),
            ).animate().fadeIn(delay: 220.ms),
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

  Widget _buildStatusTile(AutoBackupState state, bool isDark) {
    final lastBackup = state.lastBackupDate == null
        ? 'Aucune sauvegarde récente'
        : DateFormat('dd/MM/yyyy HH:mm').format(state.lastBackupDate!);

    return _TileShell(
      isDark: isDark,
      child: Row(
        children: [
          _TileIcon(
            icon: state.isDriveConnected ? Icons.cloud_done : Icons.cloud_queue,
            color: state.isDriveConnected ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isDriveConnected ? 'Drive connecté' : 'Drive non connecté',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.isDriveConnected
                      ? (state.driveUserEmail ?? 'Compte Google actif')
                      : 'Connectez un compte avant de synchroniser',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dernière sauvegarde: $lastBackup',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            state.isDriveConnected ? AppIcons.success : AppIcons.info,
            color: state.isDriveConnected ? AppColors.success : AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncTile(
    BuildContext context,
    WidgetRef ref,
    AutoBackupState state,
    bool isDark,
  ) {
    final sizeMB = state.pendingSyncMB;
    final hasData = sizeMB != null && sizeMB > 0;

    return _TileShell(
      isDark: isDark,
      onTap: (state.isBackingUp || !hasData)
          ? null
          : () => _syncNow(context, ref, state),
      child: Row(
        children: [
          _TileIcon(
            icon: AppIcons.refresh,
            color: hasData ? AppColors.primary : AppColors.textSecondaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synchroniser maintenant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créer une sauvegarde et l\'envoyer sur Drive',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Badge MB — visible uniquement si > 0, sans spinner
          if (hasData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${sizeMB.toStringAsFixed(2)} MB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2200.ms,
                color: Colors.white.withValues(alpha: 0.35),
              )
          else if (state.isBackingUp)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAutoBackupTile(WidgetRef ref, AutoBackupState state, bool isDark) {
    return _TileShell(
      isDark: isDark,
      child: Row(
        children: [
          const _TileIcon(icon: AppIcons.backup, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sauvegarde automatique',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.isEnabled
                      ? 'Activée pour les sauvegardes périodiques'
                      : 'Désactivée',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: state.isEnabled,
            onChanged: state.isBackingUp
                ? null
                : (value) =>
                    ref.read(autoBackupProvider.notifier).toggleAutoBackup(value),
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTile(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warning, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback? onTap,
    Color color = AppColors.primary,
    bool isLoading = false,
  }) {
    return _TileShell(
      isDark: isDark,
      onTap: onTap,
      child: Row(
        children: [
          _TileIcon(icon: icon, color: color),
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
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              size: 20,
            ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(autoBackupProvider.notifier).connectDrive();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Google Drive connecté' : 'Connexion Google Drive échouée',
        ),
      ),
    );
  }

  void _syncNow(BuildContext context, WidgetRef ref, AutoBackupState state) {
    final totalMB = state.pendingSyncMB!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DriveProgressSheet(
        totalMB: totalMB,
        isDark: isDark,
        onStart: (onProgress) =>
            ref.read(autoBackupProvider.notifier).performDriveSync(
              onProgress: onProgress,
            ),
      ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(autoBackupProvider.notifier).disconnectDrive();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Drive déconnecté')),
    );
  }
}

// ─── BottomSheet progression Drive ───────────────────────────────────────────

class _DriveProgressSheet extends StatefulWidget {
  final double totalMB;
  final bool isDark;
  final Future<bool> Function(
    void Function(double uploadedMB, double totalMB, double percent),
  ) onStart;

  const _DriveProgressSheet({
    required this.totalMB,
    required this.isDark,
    required this.onStart,
  });

  @override
  State<_DriveProgressSheet> createState() => _DriveProgressSheetState();
}

class _DriveProgressSheetState extends State<_DriveProgressSheet>
    with SingleTickerProviderStateMixin {
  double _uploadedMB = 0;
  double _percent = 0;
  bool _done = false;
  bool _success = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startUpload());
  }

  void _startUpload() async {
    final result = await widget.onStart((uploadedMB, totalMB, percent) {
      if (mounted) {
        setState(() {
          _uploadedMB = uploadedMB;
          _percent = percent;
        });
      }
    });
    if (mounted) {
      setState(() {
        _done = true;
        _success = result;
        _percent = result ? 100 : _percent;
        _uploadedMB = result ? widget.totalMB : _uploadedMB;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final totalMB = widget.totalMB;
    final progress = (_percent / 100).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: 28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Icône animée
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = _done ? 1.0 : 0.92 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _done
                            ? (_success
                                  ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
                                  : [AppColors.error, AppColors.error.withValues(alpha: 0.7)])
                            : [const Color(0xFF4285F4), AppColors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_done
                                  ? (_success ? AppColors.success : AppColors.error)
                                  : const Color(0xFF4285F4))
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _done
                          ? (_success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded)
                          : Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              _done
                  ? (_success ? 'Sync réussi !' : 'Erreur de sync')
                  : 'Sync Google Drive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              _done
                  ? (_success
                        ? '${totalMB.toStringAsFixed(2)} MB synchronisés'
                        : 'Vérifiez votre connexion')
                  : '${_uploadedMB.toStringAsFixed(2)} / ${totalMB.toStringAsFixed(2)} MB',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            if (!_done) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? AppColors.borderDark
                      : Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.5 ? const Color(0xFF4285F4) : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('${_percent.toStringAsFixed(0)}%', Icons.percent_rounded, isDark),
                  _statChip('${_uploadedMB.toStringAsFixed(2)} MB', Icons.upload_rounded, isDark),
                  _statChip(
                    '${(totalMB - _uploadedMB).clamp(0, totalMB).toStringAsFixed(2)} MB',
                    Icons.hourglass_bottom_rounded,
                    isDark,
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (_success ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _success
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: _success ? AppColors.success : AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _success ? 'Sauvegardé dans IkigaboBackups' : 'Upload échoué',
                      style: TextStyle(
                        fontSize: 12,
                        color: _success ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success ? AppColors.primary : AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _statChip(String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared tile widgets ──────────────────────────────────────────────────────

class _TileShell extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final VoidCallback? onTap;

  const _TileShell({
    required this.isDark,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

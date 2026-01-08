import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final settings = ref.watch(notificationSettingsProvider);

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
            size: 20.sp,
          ),
        ),
        title: Text(
          'Paramètres notifications',
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSection('Dettes', isDark),
          _buildNotificationTile(
            icon: AppIcons.debt,
            title: 'Rappels de dettes',
            subtitle: 'Notifications pour les échéances',
            value: settings.debtReminders,
            onChanged: (value) => ref
                .read(notificationSettingsProvider.notifier)
                .toggleDebtReminders(),
            isDark: isDark,
          ),
          _buildNotificationTile(
            icon: AppIcons.warning,
            title: 'Alertes retard',
            subtitle: 'Dettes en retard de paiement',
            value: settings.overdueAlerts,
            onChanged: (value) => ref
                .read(notificationSettingsProvider.notifier)
                .toggleOverdueAlerts(),
            isDark: isDark,
          ),

          SizedBox(height: 8.h),

          _buildSection('Banques', isDark),
          _buildNotificationTile(
            icon: AppIcons.bank,
            title: 'Frais bancaires',
            subtitle: 'Prélèvements à venir',
            value: settings.bankFeeReminders,
            onChanged: (value) => ref
                .read(notificationSettingsProvider.notifier)
                .toggleBankFeeReminders(),
            isDark: isDark,
          ),

          SizedBox(height: 8.h),

          _buildSection('Patrimoine', isDark),
          _buildNotificationTile(
            icon: AppIcons.trendingUp,
            title: 'Objectifs atteints',
            subtitle: 'Seuils de patrimoine franchis',
            value: settings.wealthMilestones,
            onChanged: (value) => ref
                .read(notificationSettingsProvider.notifier)
                .toggleWealthMilestones(),
            isDark: isDark,
          ),

          SizedBox(height: 8.h),

          _buildSection('Maintenance', isDark),
          _buildNotificationTile(
            icon: AppIcons.backup,
            title: 'Rappels sauvegarde',
            subtitle: 'Sauvegarder vos données',
            value: settings.backupReminders,
            onChanged: (value) => ref
                .read(notificationSettingsProvider.notifier)
                .toggleBackupReminders(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? AppColors.textSecondaryDark : Colors.black54,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}

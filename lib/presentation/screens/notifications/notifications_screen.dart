import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/services/notification_service.dart';
import '../../providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'notification_detail_bottom_sheet.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            AppIcons.back,
            color: isDark ? AppColors.textDark : Colors.black87,
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
            icon: Icon(
              AppIcons.settings,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          if (notificationService.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notificationService.markAllAsRead();
              },
              child: Text(
                'Tout lire',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: notificationService.notificationCount,
        builder: (context, count, child) {
          // Toujours afficher toutes les notifications (lues et non lues)
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.notification,
                    size: 64.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                isDark: isDark,
                onTap: () {
                  // Marquer comme lue quand on clique
                  if (!notification.isRead) {
                    notificationService.markNotificationAsRead(notification.id);
                  }
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => NotificationDetailBottomSheet(
                      notification: notification,
                      isDark: isDark,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? (isDark ? AppColors.surfaceDark : Colors.white)
            : (isDark ? AppColors.primary.withOpacity(0.1) : AppColors.primary.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: notification.isRead 
              ? (isDark ? AppColors.borderDark : Colors.grey.shade200)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: isDark ? AppColors.textDark : Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _formatDate(notification.scheduledDate),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.debtReminder:
        return AppIcons.money;
      case NotificationType.debtOverdue:
        return AppIcons.warning;
      case NotificationType.bankFee:
        return AppIcons.bank;
      case NotificationType.wealthMilestone:
        return AppIcons.stats;
      case NotificationType.backupReminder:
        return AppIcons.settings;
      case NotificationType.budgetWarning:
        return AppIcons.warning;
      case NotificationType.budgetExceeded:
        return AppIcons.warning;
      case NotificationType.lowBalance:
        return AppIcons.warning;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.debtReminder:
        return AppColors.primary;
      case NotificationType.debtOverdue:
        return AppColors.error;
      case NotificationType.bankFee:
        return AppColors.warning;
      case NotificationType.wealthMilestone:
        return AppColors.success;
      case NotificationType.backupReminder:
        return AppColors.info;
      case NotificationType.budgetWarning:
        return AppColors.warning;
      case NotificationType.budgetExceeded:
        return AppColors.error;
      case NotificationType.lowBalance:
        return AppColors.warning;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
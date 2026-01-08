import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/services/notification_service.dart';

class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;

  const NotificationDetailBottomSheet({
    super.key,
    required this.notification,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - safeAreaTop - 80;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 32.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Icon et titre
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: _getTypeColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDark : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatDate(notification.scheduledDate),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Message
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? AppColors.textDark : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
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
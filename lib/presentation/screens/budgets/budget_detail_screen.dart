import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/budget_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_budget_screen.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final BudgetModel budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final progress = budget.progressPercentage;

    Color getStatusColor() {
      switch (budget.status) {
        case BudgetStatus.active:
          return budget.isOverBudget ? AppColors.error : AppColors.primary;
        case BudgetStatus.completed:
          return AppColors.success;
        case BudgetStatus.exceeded:
          return AppColors.error;
        case BudgetStatus.paused:
          return AppColors.warning;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? AppColors.textDark : Colors.black87,
        elevation: 0,
        title: Text(budget.name),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddBudgetScreen(budget: budget),
              ),
            ),
            icon: const Icon(AppIcons.edit),
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(context, ref),
            icon: const Icon(AppIcons.delete, color: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildProgressCard(isDark, getStatusColor(), progress),
            SizedBox(height: 16.h),
            _buildAmountCards(isDark),
            SizedBox(height: 16.h),
            _buildDetailsCard(isDark, l10n),
            SizedBox(height: 16.h),
            _buildStatusCard(isDark, getStatusColor(), l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(bool isDark, Color statusColor, double progress) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getBudgetTypeIcon(budget.type),
                  color: statusColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textDark : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getBudgetTypeLabel(budget.type),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12.h,
              backgroundColor: isDark ? AppColors.borderDark : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '${budget.daysRemaining} jours restants',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actuel',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                ),
                SizedBox(height: 8.h),
                CurrencyAmountWidget(
                  amount: budget.currentAmount,
                  originalCurrency: budget.currency,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectif',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                ),
                SizedBox(height: 8.h),
                CurrencyAmountWidget(
                  amount: budget.targetAmount,
                  originalCurrency: budget.currency,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('Période', _getPeriodLabel(budget.period), isDark),
          _buildDetailRow('Date début', _formatDate(budget.startDate), isDark),
          _buildDetailRow('Date fin', _formatDate(budget.endDate), isDark),
          if (budget.description?.isNotEmpty == true)
            _buildDetailRow('Description', budget.description!, isDark),
          _buildDetailRow('Notifications', budget.notificationsEnabled ? 'Activées' : 'Désactivées', isDark),
          if (budget.warningThreshold != null)
            _buildDetailRow('Seuil d\'alerte', '${budget.warningThreshold!.toInt()}%', isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, Color statusColor, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(budget.status),
            color: statusColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(budget.status),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getStatusDescription(budget.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBudgetTypeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.expense: return AppIcons.expense;
      case BudgetType.income: return AppIcons.income;
      case BudgetType.saving: return AppIcons.money;
    }
  }

  String _getBudgetTypeLabel(BudgetType type) {
    switch (type) {
      case BudgetType.expense: return 'Budget Dépenses';
      case BudgetType.income: return 'Objectif Revenus';
      case BudgetType.saving: return 'Objectif Épargne';
    }
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly: return 'Hebdomadaire';
      case BudgetPeriod.monthly: return 'Mensuel';
      case BudgetPeriod.quarterly: return 'Trimestriel';
      case BudgetPeriod.yearly: return 'Annuel';
    }
  }

  IconData _getStatusIcon(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.active: return AppIcons.chart;
      case BudgetStatus.completed: return AppIcons.success;
      case BudgetStatus.exceeded: return AppIcons.warning;
      case BudgetStatus.paused: return AppIcons.settings;
    }
  }

  String _getStatusLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.active: return 'Actif';
      case BudgetStatus.completed: return 'Terminé';
      case BudgetStatus.exceeded: return 'Dépassé';
      case BudgetStatus.paused: return 'En pause';
    }
  }

  String _getStatusDescription(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.active: return 'Ce budget est en cours';
      case BudgetStatus.completed: return 'Objectif atteint avec succès';
      case BudgetStatus.exceeded: return 'Budget dépassé';
      case BudgetStatus.paused: return 'Budget mis en pause';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${budget.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(budgetControllerProvider.notifier).deleteBudget(budget.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
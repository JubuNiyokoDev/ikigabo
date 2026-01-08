import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/bank_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/bank_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_bank_screen.dart';

class BankDetailScreen extends ConsumerWidget {
  final BankModel bank;

  const BankDetailScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, l10n),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppSizes.spacing12),
                children: [
                  _buildBalanceCard(isDark, l10n),
                  SizedBox(height: AppSizes.spacing12),
                  _buildInfoSection(isDark, l10n),
                  SizedBox(height: AppSizes.spacing12),
                  if (bank.bankType == BankType.paid) ...[
                    _buildInterestSection(isDark, l10n),
                    SizedBox(height: AppSizes.spacing12),
                  ],
                  _buildActionsSection(context, ref, isDark, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.back, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBankScreen(bank: bank),
                    ),
                  );
                },
                icon: const Icon(AppIcons.edit, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacing12),
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              AppIcons.bank,
              size: 16.sp,
              color: Colors.white,
            ),
          ).animate().scale(delay: 100.ms),
          SizedBox(height: AppSizes.spacing12),
          Text(
            bank.name,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 2.h),
          if (bank.accountNumber != null)
            Text(
              bank.accountNumber!,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            l10n.currentBalanceLabel,
            style: TextStyle(
              fontSize: AppSizes.textSmall,
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
            ),
          ),
          SizedBox(height: AppSizes.spacing12),
          CurrencyAmountWidget(
            amount: bank.balance,
            originalCurrency: bank.currency,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSizes.spacing12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: bank.isActive
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              bank.isActive ? l10n.activeAccount : l10n.inactiveAccount,
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: bank.isActive ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildInfoSection(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.info, color: AppColors.primary, size: 24.sp),
              SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.informations,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacing12),
          _InfoRow(
            label: l10n.bankTypeLabel,
            value: bank.bankType == BankType.free ? l10n.freeBank : l10n.paidBank,
            icon: bank.bankType == BankType.free ? AppIcons.success : AppIcons.warning,
            valueColor: bank.bankType == BankType.free
                ? AppColors.success
                : AppColors.warning,
            isDark: isDark,
          ),
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.currencyLabel,
            value: bank.currency,
            icon: AppIcons.money,
            isDark: isDark,
          ),
          if (bank.description != null) ...[
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.descriptionLabel,
              value: bank.description!,
              icon: AppIcons.note,
              isDark: isDark,
            ),
          ],
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.createdOn,
            value: '${bank.createdAt.day}/${bank.createdAt.month}/${bank.createdAt.year}',
            icon: AppIcons.calendar,
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInterestSection(bool isDark, AppLocalizations l10n) {
    if (bank.interestValue == null) return const SizedBox();

    final interest = bank.calculateInterest();
    final nextDeduction = bank.nextDeductionDate;

    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.warning, color: AppColors.warning, size: 24.sp),
              SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.bankFeesLabel,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spacing12),
          _InfoRow(
            label: l10n.feeAmountLabel,
            value: bank.interestCalculation == InterestCalculation.fixedAmount
                ? '${bank.interestValue} ${bank.currency}'
                : '${bank.interestValue}%',
            icon: AppIcons.money,
            valueColor: AppColors.warning,
            isDark: isDark,
          ),
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.calculatedFees,
            value: '${interest.toStringAsFixed(2)} ${bank.currency}',
            icon: AppIcons.money,
            valueColor: AppColors.error,
            isDark: isDark,
          ),
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          _InfoRow(
            label: l10n.frequencyLabel,
            value: bank.interestType == InterestType.monthly ? l10n.monthlyFreq : l10n.annualFreq,
            icon: AppIcons.calendar,
            isDark: isDark,
          ),
          if (nextDeduction != null) ...[
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.nextDeduction,
              value: '${nextDeduction.day}/${nextDeduction.month}/${nextDeduction.year}',
              icon: AppIcons.calendar,
              valueColor: AppColors.warning,
              isDark: isDark,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actionsLabel,
            style: TextStyle(
              fontSize: AppSizes.textMedium,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: AppSizes.spacing12),
          _ActionButton(
            label: l10n.editBank,
            icon: AppIcons.edit,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddBankScreen(bank: bank),
                ),
              );
            },
          ),
          SizedBox(height: AppSizes.spacing12),
          _ActionButton(
            label: l10n.deleteBank,
            icon: AppIcons.delete,
            color: AppColors.error,
            onTap: () {
              _showDeleteDialog(context, ref, isDark, l10n);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, bool isDark, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.deleteBankTitle,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: Text(
          '${l10n.deleteBankConfirmation} "${bank.name}"${l10n.thisActionIsIrreversible}',
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(bankControllerProvider.notifier).deleteBank(bank.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.bankDeletedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? AppColors.textDark : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(AppSizes.spacing12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(AppIcons.back, color: color, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

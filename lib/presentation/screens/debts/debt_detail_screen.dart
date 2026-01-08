import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ikigabo/presentation/widgets/currency_amount_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/source_model.dart';
import '../../../data/models/transaction_model.dart' as tx;
import '../../../l10n/app_localizations.dart';
import '../../providers/debt_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/theme_provider.dart';
import 'add_debt_screen.dart';

class DebtDetailScreen extends ConsumerWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final isGiven = debt.type == DebtType.given;
    final progress = debt.paymentProgress;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isGiven, isDark, l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                children: [
                  _buildAmountCard(context, isGiven, progress, isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildProgressSection(context, progress, isGiven, isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildInfoSection(context, isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  if (debt.hasInterest) ...[
                    _buildInterestSection(context, isDark, l10n),
                    const SizedBox(height: AppSizes.spacing12),
                  ],
                  _buildPaymentHistory(context, isDark, l10n),
                  const SizedBox(height: AppSizes.spacing12),
                  _buildActionsSection(context, ref, isDark, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isGiven, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGiven
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
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
                      builder: (_) => AddDebtScreen(debt: debt),
                    ),
                  );
                },
                icon: const Icon(AppIcons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isGiven ? AppIcons.debtGiven : AppIcons.debtReceived,
              size: 16.sp,
              color: Colors.white,
            ),
          ).animate().scale(delay: 100.ms),
          const SizedBox(height: AppSizes.spacing12),
          Text(
            debt.personName,
            style: const TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 2.h),
          Text(
            isGiven ? l10n.lentTo : l10n.borrowedFrom,
            style: const TextStyle(
              fontSize: AppSizes.textSmall,
              color: Colors.white70,
            ),
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context, bool isGiven, double progress, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isGiven
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.remainingAmount,
            style: TextStyle(
              fontSize: AppSizes.textSmall,
              color: isDark ? AppColors.textSecondaryDark : Colors.black54,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          CurrencyAmountWidget(
            amount: debt.remainingAmount,
            originalCurrency: debt.currency,
            style: TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: isGiven ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getStatusColor(debt.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _getStatusLabel(debt.status, l10n),
              style: TextStyle(
                fontSize: AppSizes.textSmall,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(debt.status),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildProgressSection(BuildContext context, double progress, bool isGiven, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.chart, color: AppColors.primary, size: 24.sp),
              const SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.progression,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12.h,
              backgroundColor: isDark ? AppColors.borderDark : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGiven ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paidLabel,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  CurrencyAmountWidget(
                    amount: debt.paidAmount,
                    originalCurrency: debt.currency,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDark : Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.totalLabel,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  CurrencyAmountWidget(
                    amount: debt.totalAmount,
                    originalCurrency: debt.currency,
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDark : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildInfoSection(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
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
              const SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.informationsLabel,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          if (debt.personContact != null) ...[
            _InfoRow(
              label: l10n.contactLabel,
              value: debt.personContact!,
              icon: AppIcons.phone,
              isDark: isDark,
            ),
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          ],
          _InfoRow(
            label: l10n.dateLabel,
            value: '${debt.date.day}/${debt.date.month}/${debt.date.year}',
            icon: AppIcons.calendar,
            isDark: isDark,
          ),
          if (debt.dueDate != null) ...[
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.dueDateLabel,
              value:
                  '${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}',
              icon: AppIcons.calendar,
              valueColor: debt.isOverdue ? AppColors.error : null,
              isDark: isDark,
            ),
            if (debt.isOverdue) ...[
              const SizedBox(height: AppSizes.spacing12),
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.warning, color: AppColors.error, size: 24.sp),
                    const SizedBox(width: AppSizes.spacing12),
                    Text(
                      l10n.debtOverdueWarning,
                      style: const TextStyle(
                        fontSize: AppSizes.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (debt.collateral != null) ...[
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.collateralLabel,
              value: debt.collateral!,
              icon: AppIcons.asset,
              isDark: isDark,
            ),
          ],
          if (debt.description != null) ...[
            Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            _InfoRow(
              label: l10n.descriptionLabel,
              value: debt.description!,
              icon: AppIcons.note,
              isDark: isDark,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildInterestSection(BuildContext context, bool isDark, AppLocalizations l10n) {
    final totalWithInterest = debt.totalWithInterest;
    final interestAmount = totalWithInterest - debt.totalAmount;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
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
              const SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.interestLabel,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          _InfoRow(
            label: l10n.interestRateLabel,
            value: '${debt.interestRate}%',
            icon: AppIcons.money,
            valueColor: AppColors.warning,
            isDark: isDark,
          ),
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          Row(
            children: [
              Icon(AppIcons.money, color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.interestAmountLabel,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall,
                        color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    CurrencyAmountWidget(
                      amount: interestAmount,
                      originalCurrency: debt.currency,
                      style: const TextStyle(
                        fontSize: AppSizes.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: isDark ? AppColors.borderDark : Colors.grey.shade300),
          Row(
            children: [
              Icon(AppIcons.money, color: AppColors.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalWithInterestLabel,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall,
                        color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    CurrencyAmountWidget(
                      amount: totalWithInterest,
                      originalCurrency: debt.currency,
                      style: const TextStyle(
                        fontSize: AppSizes.textSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildPaymentHistory(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.money, color: AppColors.primary, size: 24.sp),
              const SizedBox(width: AppSizes.spacing12),
              Text(
                l10n.paymentHistoryLabel,
                style: TextStyle(
                  fontSize: AppSizes.textMedium,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          if (debt.paidAmount > 0) ...[
            _PaymentHistoryItem(
              amount: debt.paidAmount,
              date: debt.updatedAt ?? debt.createdAt,
              debt: debt,
              isInitial: true,
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing12),
                child: Text(
                  l10n.noPaymentsRecorded,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    fontSize: AppSizes.textMedium,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 650.ms);
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
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
          const SizedBox(height: AppSizes.spacing12),
          if (debt.status != DebtStatus.fullyPaid) ...[
            _ActionButton(
              label: l10n.recordPayment,
              icon: AppIcons.money,
              color: AppColors.success,
              onTap: () {
                _showPaymentDialog(context, ref);
              },
            ),
            const SizedBox(height: AppSizes.spacing12),
          ],
          _ActionButton(
            label: l10n.editDebt,
            icon: AppIcons.edit,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddDebtScreen(debt: debt)),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacing12),
          _ActionButton(
            label: l10n.deleteDebt,
            icon: AppIcons.delete,
            color: AppColors.error,
            onTap: () {
              _showDeleteDialog(context, ref, isDark, l10n);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(debt: debt),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, bool isDark, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.deleteDebt,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: Text(
          '${l10n.deleteDebtConfirmation} "${debt.personName}" ? ${l10n.thisActionIsIrreversible}',
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
                await ref
                    .read(debtControllerProvider.notifier)
                    .deleteDebt(debt.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.debtDeletedSuccess),
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

  String _getStatusLabel(DebtStatus status, AppLocalizations l10n) {
    switch (status) {
      case DebtStatus.pending:
        return l10n.overdue;
      case DebtStatus.partiallyPaid:
        return l10n.borrowed;
      case DebtStatus.fullyPaid:
        return l10n.lent;
      case DebtStatus.cancelled:
        return l10n.cancel;
    }
  }

  Color _getStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.pending:
        return AppColors.warning;
      case DebtStatus.partiallyPaid:
        return AppColors.info;
      case DebtStatus.fullyPaid:
        return AppColors.success;
      case DebtStatus.cancelled:
        return AppColors.error;
    }
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
        padding: const EdgeInsets.all(AppSizes.spacing12),
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

class _PaymentBottomSheet extends ConsumerStatefulWidget {
  final DebtModel debt;

  const _PaymentBottomSheet({required this.debt});

  @override
  ConsumerState<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<_PaymentBottomSheet> {
  final _amountController = TextEditingController();
  int? _selectedSourceId;
  String? _selectedSourceName;
  String _selectedSourceType = 'source';
  bool _isExternalMoney = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.recordPaymentTitle,
              style: const TextStyle(
                fontSize: AppSizes.textMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing12),
            Text(
              '${l10n.remainingAmountLabel}: ${widget.debt.remainingAmount} ${widget.debt.currency}',
              style: const TextStyle(color: AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                labelText: l10n.paymentAmount,
                hintText: '0.00',
                suffixText: widget.debt.currency,
                prefixIcon: const Icon(AppIcons.money, color: AppColors.success),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.spacing12),
            if (double.tryParse(_amountController.text) != null && double.parse(_amountController.text) > 0) ...[
              Text(
                widget.debt.type == DebtType.given ? l10n.whereToReceiveMoney : l10n.whereToTakeMoney,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: AppSizes.spacing8),
              GestureDetector(
                onTap: () => setState(() {
                  _isExternalMoney = true;
                  _selectedSourceId = null;
                  _selectedSourceName = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacing12),
                  decoration: BoxDecoration(
                    color: _isExternalMoney ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _isExternalMoney ? AppColors.primary : AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.money, color: _isExternalMoney ? AppColors.primary : AppColors.textSecondaryDark),
                      const SizedBox(width: AppSizes.spacing8),
                      Text(
                        l10n.externalMoneyLabel,
                        style: TextStyle(color: _isExternalMoney ? AppColors.primary : AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Consumer(
                builder: (context, ref, child) {
                  final sourcesAsync = ref.watch(originalUnifiedSourcesProvider);
                  return sourcesAsync.when(
                    data: (sources) {
                      // Filtrer les sources compatibles avec la devise de la dette
                      final compatibleSources = sources.where((source) => 
                        source.currency == widget.debt.currency
                      ).toList();
                      
                      if (compatibleSources.isEmpty) {
                        return SizedBox(
                          height: 100,
                          child: Center(
                            child: Text(
                              '${l10n.noCurrencySourceAvailable} ${widget.debt.currency}',
                              style: const TextStyle(color: AppColors.textSecondaryDark),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: compatibleSources.length,
                          itemBuilder: (context, index) {
                            final source = compatibleSources[index];
                            final realId = source.id > 0 ? source.id : -source.id;
                            final sourceKey = '${realId}_${source.iconName ?? 'source'}';
                            final selectedKey = _selectedSourceId != null && _selectedSourceName != null
                                ? '${_selectedSourceId}_$_selectedSourceType'
                                : null;
                            final isSelected = !_isExternalMoney && selectedKey == sourceKey;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _isExternalMoney = false;
                                _selectedSourceId = realId;
                                _selectedSourceName = source.name;
                                _selectedSourceType = source.iconName ?? 'source';
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
                                padding: const EdgeInsets.all(AppSizes.spacing12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderDark),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      source.iconName == 'bank' ? AppIcons.bank : AppIcons.wallet,
                                      color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                                    ),
                                    const SizedBox(width: AppSizes.spacing12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            source.name,
                                            style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text('${source.amount.toStringAsFixed(0)} ${source.currency}', style: const TextStyle(fontSize: AppSizes.textSmall, color: AppColors.textSecondaryDark)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('${AppLocalizations.of(context)!.error}: $e'),
                  );
                },
              ),
            ],
            const SizedBox(height: AppSizes.spacing12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePayment,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || amount > widget.debt.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmount), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!_isExternalMoney && (_selectedSourceId == null || _selectedSourceName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectSource), backgroundColor: AppColors.error),
      );
      return;
    }

    // Vérifier la compatibilité des devises si source sélectionnée
    if (!_isExternalMoney) {
      final sourcesAsync = ref.read(originalUnifiedSourcesProvider);
      final sources = await sourcesAsync.when(
        data: (data) => Future.value(data),
        loading: () => Future.value(<SourceModel>[]),
        error: (_, __) => Future.value(<SourceModel>[]),
      );
      
      final selectedSource = sources.firstWhere(
        (s) => (s.id > 0 ? s.id : -s.id) == _selectedSourceId,
        orElse: () => throw Exception('Source introuvable'),
      );
      
      // Vérifier la devise
      if (selectedSource.currency != widget.debt.currency) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.currencyMismatch}: ${selectedSource.currency} ≠ ${widget.debt.currency}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      // Vérifier le solde suffisant pour dette empruntée (remboursement)
      if (widget.debt.type == DebtType.received && selectedSource.amount < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.insufficientBalance} ${selectedSource.name}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    try {
      if (_isExternalMoney) {
        await ref.read(debtControllerProvider.notifier).addPayment(widget.debt, amount);
      } else {
        await ref.read(debtControllerProvider.notifier).addPaymentWithSource(
          debt: widget.debt,
          amount: amount,
          sourceId: _selectedSourceId!,
          sourceName: _selectedSourceName!,
          sourceType: _selectedSourceType == 'bank' ? tx.SourceType.bank : tx.SourceType.source,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentRecorded), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _PaymentHistoryItem extends ConsumerWidget {
  final double amount;
  final DateTime date;
  final bool isInitial;
  final DebtModel debt;

  const _PaymentHistoryItem({
    required this.amount,
    required this.date,
    required this.debt,
    this.isInitial = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(displayCurrencyProvider);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing12),
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              AppIcons.money,
              color: AppColors.success,
              size: 24.sp,
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInitial ? l10n.cumulativePayments : l10n.payment,
                  style: const TextStyle(
                    fontSize: AppSizes.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    fontSize: AppSizes.textMedium,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          CurrencyAmountWidget(
            amount: amount,
            originalCurrency: debt.currency,
            style: const TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
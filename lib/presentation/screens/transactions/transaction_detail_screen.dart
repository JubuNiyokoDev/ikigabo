import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;

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
          l10n.transactionDetail,
          style: TextStyle(
            color: isDark ? AppColors.textDark : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.textLarge,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAmountCard(isDark, l10n).animate().fadeIn(delay: 100.ms),
              SizedBox(height: AppSizes.spacing16),
              _buildDetailsCard(isDark, l10n).animate().fadeIn(delay: 200.ms),
              SizedBox(height: AppSizes.spacing16),
              _buildSourceCard(isDark, l10n).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, AppLocalizations l10n) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final icon = _getTransactionIcon();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: AppSizes.spacing16),
          CurrencyAmountWidget(
            amount: transaction.amount,
            originalCurrency: transaction.currency,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppSizes.spacing8),
          Text(
            isIncome ? l10n.entry : l10n.exit,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.informations,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: AppSizes.spacing16),
          _buildDetailRow(
            l10n.description,
            transaction.displayDescription,
            AppIcons.note,
            isDark,
          ),
          _buildDetailRow(
            l10n.category,
            transaction.categoryName,
            AppIcons.filter,
            isDark,
          ),
          _buildDetailRow(
            l10n.date,
            _formatDate(transaction.date),
            AppIcons.calendar,
            isDark,
          ),
          _buildDetailRow(
            l10n.currency,
            transaction.currency,
            AppIcons.money,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppSizes.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sourceAndDestination,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          SizedBox(height: AppSizes.spacing16),
          if (transaction.sourceName != null)
            _buildDetailRow(
              l10n.source,
              transaction.sourceName!,
              _getSourceIcon(transaction.sourceType),
              isDark,
            ),
          if (transaction.targetSourceName != null)
            _buildDetailRow(
              l10n.destination,
              transaction.targetSourceName!,
              _getSourceIcon(transaction.targetSourceType ?? transaction.sourceType),
              isDark,
            ),
          if (transaction.note != null)
            _buildDetailRow(
              l10n.note,
              transaction.note!,
              AppIcons.note,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case TransactionType.income:
        return AppIcons.income;
      case TransactionType.expense:
        return AppIcons.expense;
      case TransactionType.transfer:
        return AppIcons.refresh;
    }
  }

  IconData _getSourceIcon(SourceType sourceType) {
    switch (sourceType) {
      case SourceType.bank:
        return AppIcons.bank;
      case SourceType.source:
        return AppIcons.money;
      case SourceType.asset:
        return AppIcons.assets;
      case SourceType.debt:
        return AppIcons.debt;
      case SourceType.external:
        return AppIcons.refresh;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
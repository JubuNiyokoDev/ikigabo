import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ikigabo/core/constants/currencies.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/bank_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/bank_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_bank_screen.dart';
import 'bank_detail_screen.dart';

class BanksListScreen extends ConsumerWidget {
  const BanksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);
    final banksAsync = ref.watch(banksStreamProvider);
    final totalBalanceAsync = ref.watch(totalBankBalanceProvider);
    final pendingFeesAsync = ref.watch(totalPendingFeesProvider);
    final banksWithFeesAsync = ref.watch(banksWithPendingFeesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
              totalBalanceAsync,
              ref,
              l10n,
              displayCurrencyAsync,
            ),
            const SizedBox(height: 16),
            _buildPendingFeesAlert(
              pendingFeesAsync,
              banksWithFeesAsync,
              ref,
              l10n,
              displayCurrencyAsync,
            ),
            Expanded(
              child: banksAsync.when(
                data: (banks) => banks.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildBanksList(context, banks),
                loading: () => _buildLoadingState(),
                error: (error, stack) =>
                    _buildErrorState(error.toString(), l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBankScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(AppIcons.add, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<double> totalBalanceAsync,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<Currency> displayCurrencyAsync,
  ) {
    return Container(
      margin: EdgeInsets.all(14.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.banks,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      l10n.bankBalance,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _processAllFees(ref),
                icon: const Icon(AppIcons.money, color: Colors.white),
                tooltip: l10n.bankFees,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.totalAmount,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          totalBalanceAsync.when(
            data: (balance) => DisplayCurrencyAmountWidget(
              amount: balance,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (e, s) => DisplayCurrencyAmountWidget(
              amount: 0,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildBanksList(BuildContext context, List<BankModel> banks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: banks.length,
      itemBuilder: (context, index) {
        final bank = banks[index];
        return _BankCard(bank: bank).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context)!;
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  AppIcons.bank,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noBanks,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addFirstBank,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(String error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 24, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            l10n.error,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingFeesAlert(
    AsyncValue<double> pendingFeesAsync,
    AsyncValue<List<BankModel>> banksWithFeesAsync,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<Currency> displayCurrencyAsync,
  ) {
    return pendingFeesAsync.when(
      data: (totalFees) {
        if (totalFees <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.warning,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bankFees,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      displayCurrencyAsync.when(
                        data: (currency) =>
                            '${currency.symbol} ${totalFees.toStringAsFixed(0)} ${l10n.feesToDeduct}',
                        loading: () =>
                            'FBu ${totalFees.toStringAsFixed(0)} ${l10n.feesToDeduct}',
                        error: (_, __) =>
                            'FBu ${totalFees.toStringAsFixed(0)} ${l10n.feesToDeduct}',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _processAllFees(ref),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideY(delay: 200.ms);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Future<void> _processAllFees(WidgetRef ref) async {
    final controller = ref.read(bankControllerProvider.notifier);
    await controller.processInterestDeductions();
  }
}

class _BankCard extends ConsumerWidget {
  final BankModel bank;

  const _BankCard({required this.bank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return Dismissible(
      key: ValueKey('bank_${bank.id}_${bank.updatedAt?.millisecondsSinceEpoch ?? bank.createdAt.millisecondsSinceEpoch}'),
      background: _buildSwipeBackground(false),
      secondaryBackground: _buildSwipeBackground(true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final shouldDelete = await _showDeleteDialog(context, ref);
          if (shouldDelete) {
            await ref.read(bankControllerProvider.notifier).deleteBank(bank.id);
          }
          return shouldDelete;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddBankScreen(bank: bank)),
          );
          return false;
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Ne pas faire l'action ici car elle est déjà faite dans confirmDismiss
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BankDetailScreen(bank: bank)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bank.isActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bank.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textDark : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bank.bankType == BankType.free
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bank.bankType == BankType.free
                                ? l10n.free
                                : l10n.paid,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: bank.bankType == BankType.free
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (bank.accountNumber != null) ...[
                      Text(
                        bank.accountNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    CurrencyAmountWidget(
                      amount: bank.balance,
                      originalCurrency: bank.currency,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (bank.bankType == BankType.paid &&
                        bank.interestValue != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${l10n.fees}: ${bank.interestCalculation == InterestCalculation.fixedAmount ? "${bank.interestValue} ${bank.currency}" : "${bank.interestValue}%"} / ${bank.interestType == InterestType.monthly ? l10n.month : l10n.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                          if (bank.shouldDeductInterest()) ...[
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.toDeduct,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                AppIcons.back, 
                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600, 
                size: 24
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDelete ? AppColors.error : Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        isDelete ? AppIcons.delete : AppIcons.edit,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            title: Text(
              l10n.delete,
              style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
            ),
            content: Text(
              '${l10n.confirmDeleteAsset} "${bank.name}" ?',
              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(AppIcons.bank, color: AppColors.primary, size: 20),
    );
  }
}

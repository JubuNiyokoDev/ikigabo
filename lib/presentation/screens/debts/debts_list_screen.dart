import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ikigabo/presentation/widgets/shimmer_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/debt_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/debt_provider.dart' hide filteredDebtsProvider;
import '../../providers/search_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import '../../widgets/search_bar.dart' as custom;
import '../../widgets/page_with_banner.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';
import '../../../core/services/ad_manager.dart';

class DebtsListScreen extends ConsumerStatefulWidget {
  const DebtsListScreen({super.key});

  @override
  ConsumerState<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends ConsumerState<DebtsListScreen> {
  int _selectedTab = 0; // 0: All, 1: Given, 2: Received

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final debtsAsync = ref.watch(filteredDebtsProvider);
    final totalGivenAsync = ref.watch(totalGivenProvider);
    final totalReceivedAsync = ref.watch(totalReceivedProvider);
    final overdueDebtsAsync = ref.watch(overdueDebtsProvider);
    final dueSoonDebtsAsync = ref.watch(debtsDueSoonProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 16),
            _buildAlertsSection(overdueDebtsAsync, dueSoonDebtsAsync, l10n),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: custom.SearchBar(hintText: l10n.searchDebt),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(totalGivenAsync, totalReceivedAsync, l10n),
            const SizedBox(height: 16),
            _buildTabSelector(l10n),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: debtsAsync.when(
                  data: (debts) {
                    final filteredDebts = _filterDebts(debts);
                    return filteredDebts.isEmpty
                        ? _buildEmptyState(l10n)
                        : _buildDebtsList(filteredDebts, l10n);
                  },
                  loading: () => _buildLoadingState(),
                  error: (error, stack) =>
                      _buildErrorState(error.toString(), l10n),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AdManager.showDebtAd();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(AppIcons.add, color: Colors.white, size: 20),
      ),
    );
  }

  List<DebtModel> _filterDebts(List<DebtModel> debts) {
    switch (_selectedTab) {
      case 1:
        return debts.where((d) => d.type == DebtType.given).toList();
      case 2:
        return debts.where((d) => d.type == DebtType.received).toList();
      default:
        return debts;
    }
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myDebts,
                      style: TextStyle(
                        fontSize: AppSizes.textLarge,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textDark : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.loansAndBorrows,
                      style: TextStyle(
                        fontSize: AppSizes.textSmall,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Filter/Sort
                },
                icon: Icon(
                  AppIcons.filter,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
        );
      },
    );
  }

  Widget _buildAlertsSection(
    AsyncValue<List<DebtModel>> overdueAsync,
    AsyncValue<List<DebtModel>> dueSoonAsync,
    AppLocalizations l10n,
  ) {
    return overdueAsync.when(
      data: (overdueDebts) => dueSoonAsync.when(
        data: (dueSoonDebts) {
          if (overdueDebts.isEmpty && dueSoonDebts.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              if (overdueDebts.isNotEmpty)
                _AlertCard(
                  title: l10n.overdueDebts,
                  count: overdueDebts.length,
                  color: AppColors.error,
                  icon: AppIcons.warning,
                  debts: overdueDebts,
                ).animate().fadeIn(delay: 150.ms),
              if (overdueDebts.isNotEmpty && dueSoonDebts.isNotEmpty)
                const SizedBox(height: 16),
              if (dueSoonDebts.isNotEmpty)
                _AlertCard(
                  title: l10n.upcomingDue,
                  count: dueSoonDebts.length,
                  color: AppColors.warning,
                  icon: AppIcons.calendar,
                  debts: dueSoonDebts,
                ).animate().fadeIn(delay: 200.ms),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, s) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCards(
    AsyncValue<double> totalGivenAsync,
    AsyncValue<double> totalReceivedAsync,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: l10n.lent,
              icon: AppIcons.debtGiven,
              color: AppColors.success,
              amountAsync: totalGivenAsync,
            ).animate().fadeIn(delay: 200.ms),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _SummaryCard(
              title: l10n.borrowed,
              icon: AppIcons.debtReceived,
              color: AppColors.error,
              amountAsync: totalReceivedAsync,
            ).animate().fadeIn(delay: 300.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(AppLocalizations l10n) {
    final tabs = [l10n.all, l10n.lent, l10n.borrowed];
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = _selectedTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: AppSizes.textSmall,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.black54),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate().slideX(delay: 400.ms),
        );
      },
    );
  }

  Widget _buildDebtsList(List<DebtModel> debts, AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
        final items = debts
            .map(
              (debt) => _DebtCard(
                debt: debt,
                l10n: l10n,
              ).animate().fadeIn(delay: (500 + debts.indexOf(debt) * 50).ms),
            )
            .toList();

        final itemsWithBanner = BannerInjector.injectBanner(
          items,
          ref,
          position: 1,
        );

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemsWithBanner.length,
          itemBuilder: (context, index) => itemsWithBanner[index],
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, child) {
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
                  AppIcons.money,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noDebts,
                style: TextStyle(
                  fontSize: AppSizes.textLarge,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.addFirstDebt,
                style: TextStyle(
                  fontSize: AppSizes.textSmall,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: ShimmerList(itemCount: 5));
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
            style: const TextStyle(
              fontSize: AppSizes.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppSizes.textMedium,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final AsyncValue<double> amountAsync;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.amountAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              amountAsync.when(
                data: (amount) => DisplayCurrencyAmountWidget(
                  amount: amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 18,
                  child: ShimmerWidget(width: 80, height: 18),
                ),
                error: (e, s) => const DisplayCurrencyAmountWidget(
                  amount: 0,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtModel debt;
  final AppLocalizations l10n;

  const _DebtCard({required this.debt, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGiven = debt.type == DebtType.given;
    final progress = debt.paymentProgress;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Dismissible(
      key: Key(debt.id.toString()),
      background: _buildSwipeBackground(false),
      secondaryBackground: _buildSwipeBackground(true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final shouldDelete = await _showDeleteDialog(context, ref);
          if (shouldDelete) {
            await ref.read(debtControllerProvider.notifier).deleteDebt(debt.id);
          }
          return shouldDelete;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDebtScreen(debt: debt)),
          );
          return false;
        }
      },
      onDismissed: (direction) async {
        // Ne pas faire l'action ici car elle est déjà faite dans confirmDismiss
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGiven
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isGiven
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isGiven ? AppIcons.debtGiven : AppIcons.debtReceived,
                      color: isGiven ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: TextStyle(
                            fontSize: AppSizes.textMedium,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDark : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGiven ? l10n.lentTo : l10n.borrowedFrom,
                          style: TextStyle(
                            fontSize: AppSizes.textSmall,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CurrencyAmountWidget(
                        amount: debt.remainingAmount,
                        originalCurrency: debt.currency,
                        style: TextStyle(
                          fontSize: AppSizes.textMedium,
                          fontWeight: FontWeight.bold,
                          color: isGiven ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (debt.dueDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          debt.isOverdue
                              ? l10n.overdue
                              : '${debt.daysUntilDue}${l10n.daysRemaining}',
                          style: TextStyle(
                            fontSize: AppSizes.textSmall,
                            color: debt.isOverdue
                                ? AppColors.error
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.borderDark
                      : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGiven ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.toStringAsFixed(0)}% ${l10n.paid}',
                    style: TextStyle(
                      fontSize: AppSizes.textSmall,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CurrencyAmountWidget(
                        amount: debt.paidAmount,
                        originalCurrency: debt.currency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                      CurrencyAmountWidget(
                        amount: debt.totalAmount,
                        originalCurrency: debt.currency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            title: Text(
              'Supprimer la dette',
              style: TextStyle(
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer cette dette avec "${debt.personName}" ?',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : Colors.grey.shade600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final List<DebtModel> debts;

  const _AlertCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.debts,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count dette${count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.back, color: color, size: 16),
            ],
          ),
        );
      },
    );
  }
}

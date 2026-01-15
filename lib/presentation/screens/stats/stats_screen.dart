import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/transaction_provider.dart'
    hide thisMonthIncomeProvider, thisMonthExpenseProvider;
import '../../providers/asset_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/bank_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/stats_provider.dart'
    hide totalIncomeProvider, totalExpenseProvider;
import '../../providers/theme_provider.dart';
import '../../providers/pdf_export_provider.dart';
import '../../widgets/currency_amount_widget.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedPeriod = 1; // 0: Week, 1: Month, 2: Year, 3: All

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamic data based on selected period
    final incomeAsync = _getIncomeForPeriod();
    final expenseAsync = _getExpenseForPeriod();
    final weeklyActivityAsync = ref.watch(weeklyActivityProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 16),
            _buildPeriodSelector(l10n),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSummaryCards(incomeAsync, expenseAsync, l10n),
                  const SizedBox(height: 16),
                  _buildPieChart(incomeAsync, expenseAsync, l10n),
                  const SizedBox(height: 16),
                  _buildTrendChart(weeklyActivityAsync, l10n),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(categoryStatsAsync, l10n),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AsyncValue<double> _getIncomeForPeriod() {
    switch (_selectedPeriod) {
      case 0:
        return ref.watch(thisWeekIncomeProvider);
      case 1:
        return ref.watch(thisMonthIncomeProvider);
      case 2:
        return ref.watch(thisYearIncomeProvider);
      default:
        return ref.watch(totalIncomeProvider);
    }
  }

  AsyncValue<double> _getExpenseForPeriod() {
    switch (_selectedPeriod) {
      case 0:
        return ref.watch(thisWeekExpenseProvider);
      case 1:
        return ref.watch(thisMonthExpenseProvider);
      case 2:
        return ref.watch(thisYearExpenseProvider);
      default:
        return ref.watch(totalExpenseProvider);
    }
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
                  l10n.statistics,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.analyzeYourFinances,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _refreshData(),
            icon: Icon(
              AppIcons.refresh,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => _showExportDialog(context),
            icon: Icon(
              AppIcons.export,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final periods = [l10n.week, l10n.month, l10n.year, l10n.all];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
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
      ).animate().slideX(delay: 200.ms),
    );
  }

  Widget _buildSummaryCards(
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    AppLocalizations l10n,
  ) {
    return incomeAsync.when(
      data: (income) => expenseAsync.when(
        data: (expense) {
          final balance = income - expense;
          return Column(
            children: [
              _SummaryCard(
                title: l10n.balance,
                amount: balance,
                color: balance >= 0 ? AppColors.success : AppColors.error,
                icon: balance >= 0
                    ? AppIcons.trendingUp
                    : AppIcons.trendingDown,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: l10n.entries,
                      amount: income,
                      color: AppColors.success,
                      icon: AppIcons.income,
                    ).animate().fadeIn(delay: 400.ms),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SummaryCard(
                      title: l10n.exits,
                      amount: expense,
                      color: AppColors.error,
                      icon: AppIcons.expense,
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => _buildLoadingCards(),
        error: (e, s) => _buildErrorCard(e.toString()),
      ),
      loading: () => _buildLoadingCards(),
      error: (e, s) => _buildErrorCard(e.toString()),
    );
  }

  Widget _buildPieChart(
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    AppLocalizations l10n,
  ) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.pieChart, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Text(
                l10n.distribution,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          incomeAsync.when(
            data: (income) => expenseAsync.when(
              data: (expense) {
                if (income == 0 && expense == 0) {
                  return _buildNoDataWidget(l10n);
                }
                final total = income + expense;
                return SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        if (income > 0)
                          PieChartSectionData(
                            value: income,
                            title:
                                '${((income / total) * 100).toStringAsFixed(0)}%',
                            color: AppColors.success,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (expense > 0)
                          PieChartSectionData(
                            value: expense,
                            title:
                                '${((expense / total) * 100).toStringAsFixed(0)}%',
                            color: AppColors.error,
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => _buildChartLoading(),
              error: (e, s) => _buildNoDataWidget(l10n),
            ),
            loading: () => _buildChartLoading(),
            error: (e, s) => _buildNoDataWidget(l10n),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.success, label: l10n.entries),
              const SizedBox(width: 14),
              _LegendItem(color: AppColors.error, label: l10n.exits),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildTrendChart(
    AsyncValue<List<double>> weeklyActivityAsync,
    AppLocalizations l10n,
  ) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.chart, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Text(
                l10n.weeklyActivity,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          weeklyActivityAsync.when(
            data: (weekData) {
              if (weekData.isEmpty) return _buildNoDataWidget(l10n);

              final maxValue = weekData
                  .map((e) => e.abs())
                  .reduce((a, b) => a > b ? a : b);
              return SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                    minY: -maxValue * 1.2,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                            if (value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 15,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: weekData.asMap().entries.map((entry) {
                      final value = entry.value;
                      final color = value >= 0
                          ? AppColors.success
                          : AppColors.error;
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: value.abs(),
                            color: color,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
            loading: () => _buildChartLoading(),
            error: (e, s) => _buildNoDataWidget(l10n),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildCategoryBreakdown(
    AsyncValue<Map<String, double>> categoryStatsAsync,
    AppLocalizations l10n,
  ) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.filter, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Text(
                l10n.byCategory,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          categoryStatsAsync.when(
            data: (categories) {
              if (categories.isEmpty) return _buildNoDataWidget(l10n);

              final sortedCategories = categories.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: sortedCategories.take(5).map((entry) {
                  final categoryName = entry.key;
                  final amount = entry.value;
                  final color = _getCategoryColor(categoryName);
                  final icon = _getCategoryIcon(categoryName);

                  return _CategoryItem(
                    name: categoryName,
                    icon: icon,
                    amount: amount,
                    color: color,
                  ).animate().fadeIn(delay: 800.ms);
                }).toList(),
              );
            },
            loading: () => _buildCategoryLoading(),
            error: (e, s) => _buildNoDataWidget(l10n),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'nourriture':
        return AppColors.error;
      case 'transport':
        return AppColors.warning;
      case 'health':
      case 'santé':
        return AppColors.info;
      case 'entertainment':
      case 'divertissement':
        return AppColors.accent;
      case 'shopping':
      case 'achat':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'nourriture':
        return AppIcons.food;
      case 'transport':
        return AppIcons.transport;
      case 'health':
      case 'santé':
        return AppIcons.health;
      case 'entertainment':
      case 'divertissement':
        return AppIcons.entertainment;
      case 'shopping':
      case 'achat':
        return AppIcons.shopping;
      default:
        return AppIcons.money;
    }
  }

  Widget _buildLoadingCards() {
    return Column(
      children: [
        _buildLoadingCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 14),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Erreur: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          l10n.noData,
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }

  Widget _buildChartLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildCategoryLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundDark,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(thisMonthIncomeProvider);
    ref.invalidate(thisMonthExpenseProvider);
    ref.invalidate(weeklyActivityProvider);
    ref.invalidate(categoryStatsProvider);
  }

  void _showExportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.read(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l10n.exportPdf,
          style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.chart, color: AppColors.primary),
              title: Text(
                l10n.fullReport,
                style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
              ),
              subtitle: Text(
                l10n.allFinancialData,
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.black54),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportFullReport();
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.assets, color: AppColors.success),
              title: Text(
                l10n.assetReport,
                style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportAssetReport();
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.debt, color: AppColors.warning),
              title: Text(
                l10n.debtReport,
                style: TextStyle(color: isDark ? AppColors.textDark : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportDebtReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportFullReport() async {
    final l10n = AppLocalizations.of(context)!;
    final periods = ['Semaine', 'Mois', 'Année', 'Tout'];
    final period = periods[_selectedPeriod];
    
    // Récupérer les vraies données depuis les streams
    final transactionsAsync = ref.read(transactionsStreamProvider);
    final assetsAsync = ref.read(assetsStreamProvider);
    final debtsAsync = ref.read(debtsStreamProvider);
    final banksAsync = ref.read(banksStreamProvider);
    final sourcesAsync = ref.read(sourcesStreamProvider);
    final totalWealthAsync = ref.read(totalWealthProvider);
    
    final transactions = transactionsAsync.value ?? [];
    final assets = assetsAsync.value ?? [];
    final debts = debtsAsync.value ?? [];
    final banks = banksAsync.value ?? [];
    final sources = sourcesAsync.value ?? [];
    final totalWealth = totalWealthAsync.value ?? 0;
    final totalIncome = _getIncomeForPeriod().value ?? 0;
    final totalExpense = _getExpenseForPeriod().value ?? 0;
    
    ref.read(pdfExportProvider.notifier).exportFinancialReport(
      transactions: transactions,
      assets: assets,
      debts: debts,
      banks: banks,
      sources: sources,
      totalWealth: totalWealth,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      period: period,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.exportInProgress),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _exportAssetReport() async {
    final l10n = AppLocalizations.of(context)!;
    final assetsAsync = ref.read(assetsStreamProvider);
    final assets = assetsAsync.value ?? [];
    
    ref.read(pdfExportProvider.notifier).exportAssetReport(assets);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.assetExportInProgress),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportDebtReport() async {
    final l10n = AppLocalizations.of(context)!;
    final debtsAsync = ref.read(debtsStreamProvider);
    final debts = debtsAsync.value ?? [];
    
    ref.read(pdfExportProvider.notifier).exportDebtReport(debts);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.debtExportInProgress),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DisplayCurrencyAmountWidget(
                      amount: amount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final double amount;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
              ),
              DisplayCurrencyAmountWidget(
                amount: amount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

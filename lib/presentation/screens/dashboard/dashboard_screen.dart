import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/transaction_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart' hide thisMonthIncomeProvider, thisMonthExpenseProvider;
import '../../providers/debt_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/animations.dart';
import '../../widgets/physics_animations.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/currency_amount_widget.dart';
import '../banks/banks_list_screen.dart';
import '../assets/assets_list_screen.dart';
import '../debts/debts_list_screen.dart';
import '../transactions/transactions_list_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);
    final totalWealthAsync = ref.watch(totalWealthProvider);
    final thisMonthIncomeAsync = ref.watch(thisMonthIncomeProvider);
    final thisMonthExpenseAsync = ref.watch(thisMonthExpenseProvider);
    final weeklyActivityAsync = ref.watch(weeklyActivityProvider);
    final monthlyGrowthAsync = ref.watch(monthlyGrowthProvider);
    final assetsVsLiabilitiesAsync = ref.watch(assetsVsLiabilitiesProvider);
    final recentTransactionsAsync = ref.watch(transactionsStreamProvider);
    final debtStatsAsync = ref.watch(debtStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n, isDark, context).slideInFromLeft(),
              const SizedBox(height: 16),
              _buildBalanceCard(
                totalWealthAsync,
                monthlyGrowthAsync,
                displayCurrencyAsync,
                l10n,
              ).bounceIn(delay: 200.ms),
              const SizedBox(height: 16),
              _buildQuickActions(
                context,
                isDark,
                l10n,
              ).slideInFromBottom(delay: 400.ms),
              const SizedBox(height: 16),
              _buildQuickStats(
                thisMonthIncomeAsync,
                thisMonthExpenseAsync,
                isDark,
                l10n,
              ),
              const SizedBox(height: 16),
              _buildAssetsVsLiabilities(assetsVsLiabilitiesAsync, isDark, l10n),
              const SizedBox(height: 16),
              _buildWeeklyChart(weeklyActivityAsync, isDark, l10n),
              const SizedBox(height: 16),
              _buildDebtsSummary(debtStatsAsync, context, isDark, l10n),
              const SizedBox(height: 16),
              _buildTransactionsList(recentTransactionsAsync, isDark, l10n, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isDark, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboard,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: 4.h),
            Text(
              l10n.personalWealth,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
        NotificationBadge(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ).animate().scale(delay: 200.ms),
      ],
    );
  }

  Widget _buildBalanceCard(
    AsyncValue<double> totalWealthAsync,
    AsyncValue<double> monthlyGrowthAsync,
    AsyncValue displayCurrencyAsync,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalWealth,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: displayCurrencyAsync.when(
                  data: (currency) => Text(
                    currency.code,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  loading: () => Text(
                    'BIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  error: (_, __) => Text(
                    'BIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          totalWealthAsync.when(
            data: (wealth) => DisplayCurrencyAmountWidget(
              amount: wealth,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (e, s) => DisplayCurrencyAmountWidget(
              amount: 0,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              monthlyGrowthAsync.when(
                data: (growth) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: (growth >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        growth >= 0
                            ? AppIcons.trendingUp
                            : AppIcons.trendingDown,
                        size: 10.sp,
                        color: growth >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: growth >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => Container(
                  width: 45.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                error: (e, s) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    '0.0%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.monthlyGrowth,
                style: TextStyle(fontSize: 10.sp, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, delay: 300.ms, duration: 400.ms);
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: SpringButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BanksListScreen()),
            ),
            child: _QuickActionCard(
              title: l10n.banks,
              icon: AppIcons.bank,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BanksListScreen()),
              ),
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SpringButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssetsListScreen()),
            ),
            child: _QuickActionCard(
              title: l10n.goods,
              icon: AppIcons.assets,
              color: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AssetsListScreen()),
              ),
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SpringButton(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebtsListScreen()),
            ),
            child: _QuickActionCard(
              title: l10n.debts,
              icon: AppIcons.debt,
              color: AppColors.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebtsListScreen()),
              ),
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: incomeAsync
              .when(
                data: (income) => _StatCard(
                  icon: AppIcons.income,
                  title: l10n.income,
                  amount: income,
                  color: AppColors.success,
                  iconBg: AppColors.success.withValues(alpha: 0.2),
                  isDark: isDark,
                ),
                loading: () => _StatCardLoading(
                  title: l10n.income,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                error: (e, s) => _StatCard(
                  icon: AppIcons.income,
                  title: l10n.income,
                  amount: 0,
                  color: AppColors.success,
                  iconBg: AppColors.success.withValues(alpha: 0.2),
                  isDark: isDark,
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: expenseAsync
              .when(
                data: (expense) => _StatCard(
                  icon: AppIcons.expense,
                  title: l10n.expense,
                  amount: expense,
                  color: AppColors.error,
                  iconBg: AppColors.error.withValues(alpha: 0.2),
                  isDark: isDark,
                ),
                loading: () => _StatCardLoading(
                  title: l10n.expense,
                  color: AppColors.error,
                  isDark: isDark,
                ),
                error: (e, s) => _StatCard(
                  icon: AppIcons.expense,
                  title: l10n.expense,
                  amount: 0,
                  color: AppColors.error,
                  iconBg: AppColors.error.withValues(alpha: 0.2),
                  isDark: isDark,
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    AsyncValue<List<double>> weeklyActivityAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weeklyActivity,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : Colors.black87,
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardBackgroundDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    l10n.thisWeek,
                    style: TextStyle(
                      fontSize: AppSizes.textTiny,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: weeklyActivityAsync.when(
              data: (weekData) {
                final maxValue = weekData
                    .map((e) => e.abs())
                    .reduce((a, b) => a > b ? a : b);
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                    minY: -maxValue * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final days = [l10n.mondayShort, l10n.tuesdayShort, l10n.wednesdayShort, l10n.thursdayShort, l10n.fridayShort, l10n.saturdayShort, l10n.sundayShort];
                            if (value.toInt() < days.length) {
                              return Text(
                                days[value.toInt()],
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                                  fontSize: 12.sp,
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
                      return _barGroup(entry.key, value.abs(), color);
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = [l10n.mondayShort, l10n.tuesdayShort, l10n.wednesdayShort, l10n.thursdayShort, l10n.fridayShort, l10n.saturdayShort, l10n.sundayShort];
                          if (value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                                fontSize: 10.sp,
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
                  barGroups: [
                    _barGroup(0, 60, AppColors.primary),
                    _barGroup(1, 80, AppColors.primary),
                    _barGroup(2, 45, AppColors.primary),
                    _barGroup(3, 90, AppColors.success),
                    _barGroup(4, 70, AppColors.primary),
                    _barGroup(5, 85, AppColors.primary),
                    _barGroup(6, 65, AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildAssetsVsLiabilities(
    AsyncValue<Map<String, double>> assetsVsLiabilitiesAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.assetDistribution,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          assetsVsLiabilitiesAsync.when(
            data: (data) {
              final assets = data['assets'] ?? 0;
              final liabilities = data['liabilities'] ?? 0;

              return SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 48,
                    sections: [
                      PieChartSectionData(
                        value: assets,
                        color: AppColors.success,
                        title: '${l10n.assets}\n${_formatAmountCompact(assets)}',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (liabilities > 0)
                        PieChartSectionData(
                          value: liabilities,
                          color: AppColors.error,
                          title: '${l10n.liabilities}\n${_formatAmountCompact(liabilities)}',
                          radius: 40,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  l10n.loadingError,
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildDebtsSummary(
    AsyncValue<Map<String, dynamic>> debtStatsAsync,
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return debtStatsAsync
        .when(
          data: (stats) {
            final totalGiven = stats['totalGiven'] as double;
            final totalReceived = stats['totalReceived'] as double;
            final overdueCount = stats['overdueCount'] as int;
            final dueSoonCount = stats['dueSoonCount'] as int;

            if (totalGiven == 0 && totalReceived == 0) {
              return const SizedBox.shrink();
            }

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.debtsLoans,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDark : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DebtsListScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.seeAll,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DebtSummaryCard(
                          title: l10n.lent,
                          amount: totalGiven,
                          color: AppColors.success,
                          icon: AppIcons.debtGiven,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _DebtSummaryCard(
                          title: l10n.borrowed,
                          amount: totalReceived,
                          color: AppColors.error,
                          icon: AppIcons.debtReceived,
                        ),
                      ),
                    ],
                  ),
                  if (overdueCount > 0 || dueSoonCount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.warning,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              overdueCount > 0
                                  ? l10n.debtsOverdue(overdueCount)
                                  : l10n.debtsDueSoon(dueSoonCount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        )
        .animate()
        .fadeIn(delay: 550.ms);
  }

  static String _formatAmountCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(
    AsyncValue<List<TransactionModel>> recentTransactionsAsync,
    bool isDark,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentTransactions,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionsListScreen(),
                  ),
                );
              },
              child: Text(
                l10n.seeAll,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentTransactionsAsync.when(
          data: (transactions) {
            final recentTransactions = transactions.take(5).toList();
            if (recentTransactions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    l10n.noRecentTransactions,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: recentTransactions
                  .asMap()
                  .entries
                  .map(
                    (e) => _TransactionItem(
                      transaction: e.value,
                    ).animate().fadeIn(delay: (700 + e.key * 100).ms),
                  )
                  .toList(),
            );
          },
          loading: () => const ShimmerList(itemCount: 3),
          error: (e, s) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                l10n.loadingError,
                style: TextStyle(color: isDark ? AppColors.error : AppColors.error, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final Color color;
  final Color iconBg;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
    required this.iconBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, color: color, size: 14.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 3.h),
          DisplayCurrencyAmountWidget(
            amount: amount,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardLoading extends StatelessWidget {
  final String title;
  final Color color;
  final bool isDark;

  const _StatCardLoading({
    required this.title,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(
            height: 14,
            width: 54,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final iconBg = color.withValues(alpha: 0.2);
    final icon = _getTransactionIcon(transaction.categoryName);

    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : transaction.categoryName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date, AppLocalizations.of(context)!),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          CurrencyAmountWidget(
            amount: transaction.amount,
            originalCurrency: transaction.currency,
            style: TextStyle(
              fontSize: 15,
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

  IconData _getTransactionIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'salary':
        return AppIcons.salary;
      case 'sale':
        return AppIcons.sale;
      case 'purchase':
      case 'shopping':
      case 'achat':
        return AppIcons.shopping;
      case 'food':
      case 'nourriture':
      case 'restaurant':
        return AppIcons.food;
      case 'transport':
        return AppIcons.transport;
      case 'gift':
      case 'giftgiven':
      case 'don':
        return AppIcons.gift;
      default:
        return AppIcons.money;
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return '${l10n.today}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate == yesterday) {
      return '${l10n.yesterday}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _DebtSummaryCard({
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
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          DisplayCurrencyAmountWidget(
            amount: amount,
            style: TextStyle(
              fontSize: 20,
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
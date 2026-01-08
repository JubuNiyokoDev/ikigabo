import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/budget_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/currency_amount_widget.dart';
import 'add_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final statsAsync = ref.watch(budgetStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, statsAsync, isDark, l10n),
            const SizedBox(height: 16),
            Expanded(
              child: budgetsAsync.when(
                data: (budgets) {
                  if (budgets.isEmpty) {
                    return _buildEmptyState(context, isDark, l10n);
                  }
                  
                  final activeBudgets = budgets.where((b) => b.status == BudgetStatus.active).toList();
                  final completedBudgets = budgets.where((b) => b.status == BudgetStatus.completed).toList();
                  final exceededBudgets = budgets.where((b) => b.status == BudgetStatus.exceeded).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (activeBudgets.isNotEmpty) ...[
                        _buildSectionHeader(l10n.active, activeBudgets.length, AppColors.primary, isDark),
                        ...activeBudgets.map((budget) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BudgetDetailScreen(budget: budget),
                            ),
                          ),
                          child: _BudgetCard(budget: budget),
                        )),
                        const SizedBox(height: 24),
                      ],
                      if (exceededBudgets.isNotEmpty) ...[
                        _buildSectionHeader('${l10n.expense} Dépassés', exceededBudgets.length, AppColors.error, isDark),
                        ...exceededBudgets.map((budget) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BudgetDetailScreen(budget: budget),
                            ),
                          ),
                          child: _BudgetCard(budget: budget),
                        )),
                        const SizedBox(height: 24),
                      ],
                      if (completedBudgets.isNotEmpty) ...[
                        _buildSectionHeader('Terminés', completedBudgets.length, AppColors.success, isDark),
                        ...completedBudgets.map((budget) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BudgetDetailScreen(budget: budget),
                            ),
                          ),
                          child: _BudgetCard(budget: budget),
                        )),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('${l10n.error}: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(AppIcons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> statsAsync,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                      l10n.management,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gérez vos objectifs financiers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.chart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '${stats['activeBudgets']}',
                    l10n.active,
                    AppIcons.chart,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${stats['completedBudgets']}',
                    'Terminés',
                    AppIcons.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${(stats['overallProgress'] as double).toStringAsFixed(0)}%',
                    l10n.progression,
                    AppIcons.trendingUp,
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              AppIcons.chart,
              size: 40,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noData,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier budget\npour atteindre vos objectifs',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetModel budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final progress = budget.progressPercentage;
    final isOverBudget = budget.isOverBudget;
    final isCompleted = budget.status == BudgetStatus.completed;

    Color getStatusColor() {
      switch (budget.status) {
        case BudgetStatus.active:
          return isOverBudget ? AppColors.error : AppColors.primary;
        case BudgetStatus.completed:
          return AppColors.success;
        case BudgetStatus.exceeded:
          return AppColors.error;
        case BudgetStatus.paused:
          return AppColors.warning;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getStatusColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getBudgetTypeIcon(budget.type),
                  color: getStatusColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDark : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBudgetTypeLabel(budget.type, context),
                      style: TextStyle(
                        fontSize: 12,
                        color: getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(),
                    ),
                  ),
                  Text(
                    '${budget.daysRemaining}j restants',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.borderDark : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actuel',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                  CurrencyAmountWidget(
                    amount: budget.currentAmount,
                    originalCurrency: budget.currency,
                    style: TextStyle(
                      fontSize: 14,
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
                    'Objectif',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                    ),
                  ),
                  CurrencyAmountWidget(
                    amount: budget.targetAmount,
                    originalCurrency: budget.currency,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  IconData _getBudgetTypeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.expense:
        return AppIcons.expense;
      case BudgetType.income:
        return AppIcons.income;
      case BudgetType.saving:
        return AppIcons.money;
    }
  }

  String _getBudgetTypeLabel(BudgetType type, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case BudgetType.expense:
        return 'Budget ${l10n.expense}';
      case BudgetType.income:
        return 'Objectif ${l10n.income}';
      case BudgetType.saving:
        return 'Objectif Épargne';
    }
  }
}
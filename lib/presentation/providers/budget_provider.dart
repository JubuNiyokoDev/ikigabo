import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';
import 'isar_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return BudgetRepository(isarService);
});

final budgetsStreamProvider = StreamProvider<List<BudgetModel>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.watchBudgets();
});

final activeBudgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.watchActiveBudgets();
});

final currentPeriodBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getCurrentPeriodBudgets();
});

final budgetsByTypeProvider = FutureProvider.family<List<BudgetModel>, BudgetType>((ref, type) {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgetsByType(type);
});

final budgetStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final repository = ref.watch(budgetRepositoryProvider);
  await for (final budgets in repository.watchBudgets()) {
    final activeBudgets = budgets.where((b) => b.status == BudgetStatus.active).length;
    final completedBudgets = budgets.where((b) => b.status == BudgetStatus.completed).length;
    final exceededBudgets = budgets.where((b) => b.status == BudgetStatus.exceeded).length;
    
    final totalTargetAmount = budgets.fold(0.0, (sum, b) => sum + b.targetAmount);
    final totalCurrentAmount = budgets.fold(0.0, (sum, b) => sum + b.currentAmount);
    
    yield {
      'totalBudgets': budgets.length,
      'activeBudgets': activeBudgets,
      'completedBudgets': completedBudgets,
      'exceededBudgets': exceededBudgets,
      'totalTargetAmount': totalTargetAmount,
      'totalCurrentAmount': totalCurrentAmount,
      'overallProgress': totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0.0,
    };
  }
});

final budgetControllerProvider = StateNotifierProvider<BudgetController, AsyncValue<void>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetController(repository);
});

class BudgetController extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;

  BudgetController(this._repository) : super(const AsyncValue.data(null));

  Future<void> createBudget(BudgetModel budget) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createBudget(budget);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBudget(budget);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBudgetAmount(int budgetId, double newAmount) async {
    try {
      await _repository.updateBudgetAmount(budgetId, newAmount);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteBudget(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBudget(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateExpiredBudgets() async {
    try {
      await _repository.updateExpiredBudgets();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
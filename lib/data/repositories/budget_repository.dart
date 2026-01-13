import 'package:isar_community/isar.dart';
import '../models/budget_model.dart';
import '../services/isar_service.dart';

class BudgetRepository {
  final IsarService _isarService;

  BudgetRepository(this._isarService);

  Future<List<BudgetModel>> getAllBudgets() async {
    final isar = await _isarService.isar;
    return await isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<BudgetModel>> getActiveBudgets() async {
    final isar = await _isarService.isar;
    return await isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo(BudgetStatus.active)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<BudgetModel>> getBudgetsByType(BudgetType type) async {
    final isar = await _isarService.isar;
    return await isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .typeEqualTo(type)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<List<BudgetModel>> getCurrentPeriodBudgets() async {
    final now = DateTime.now();
    final isar = await _isarService.isar;
    
    return await isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .startDateLessThan(now)
        .and()
        .endDateGreaterThan(now)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<BudgetModel?> getBudgetById(int id) async {
    final isar = await _isarService.isar;
    return await isar.budgetModels.get(id);
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      await isar.budgetModels.put(budget);
    });
    return budget;
  }

  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    final isar = await _isarService.isar;
    budget.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.budgetModels.put(budget);
    });
    return budget;
  }

  Future<void> updateBudgetAmount(int budgetId, double newAmount) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      final budget = await isar.budgetModels.get(budgetId);
      if (budget != null) {
        budget.currentAmount = newAmount;
        budget.updatedAt = DateTime.now();
        
        // Mettre à jour le statut automatiquement
        if (budget.currentAmount >= budget.targetAmount) {
          if (budget.type == BudgetType.saving) {
            budget.status = BudgetStatus.completed;
          } else {
            budget.status = BudgetStatus.exceeded;
          }
        }
        
        await isar.budgetModels.put(budget);
      }
    });
  }

  Future<void> deleteBudget(int id) async {
    final isar = await _isarService.isar;
    await isar.writeTxn(() async {
      final budget = await isar.budgetModels.get(id);
      if (budget != null) {
        budget.isDeleted = true;
        budget.updatedAt = DateTime.now();
        await isar.budgetModels.put(budget);
      }
    });
  }

  Future<void> updateExpiredBudgets() async {
    final now = DateTime.now();
    final isar = await _isarService.isar;
    
    final expiredBudgets = await isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo(BudgetStatus.active)
        .and()
        .endDateLessThan(now)
        .findAll();

    if (expiredBudgets.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final budget in expiredBudgets) {
          if (budget.type == BudgetType.saving && budget.currentAmount >= budget.targetAmount) {
            budget.status = BudgetStatus.completed;
          } else {
            budget.status = BudgetStatus.paused;
          }
          budget.updatedAt = DateTime.now();
          await isar.budgetModels.put(budget);
        }
      });
    }
  }

  Stream<List<BudgetModel>> watchBudgets() async* {
    final isar = await _isarService.isar;
    yield* isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Stream<List<BudgetModel>> watchActiveBudgets() async* {
    final isar = await _isarService.isar;
    yield* isar.budgetModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo(BudgetStatus.active)
        .watch(fireImmediately: true);
  }
}
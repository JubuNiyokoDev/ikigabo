import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/models/source_model.dart';
import '../../data/models/bank_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'isar_provider.dart';
import 'source_provider.dart';
import 'bank_provider.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';
import 'dashboard_provider.dart' as dashboard;

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar is not initialized');
  }
  return TransactionRepository(isar);
});

// All Transactions Stream
final transactionsStreamProvider = StreamProvider<List<tx.TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions();
});

// Income/Expense Totals for This Month
final thisMonthIncomeProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return await repository.getTotalIncome(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final thisMonthExpenseProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return await repository.getTotalExpense(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

// All-time Totals
final totalIncomeProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTotalIncome();
});

final totalExpenseProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTotalExpense();
});

// Transaction CRUD Controller
class TransactionController extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addTransaction(tx.TransactionModel transaction) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(isarProvider.future).then((isar) async {
        await isar.writeTxn(() async {
          // Créer la transaction
          await _repository.putTransaction(transaction);
          
          // Mettre à jour la balance de la source
          if (transaction.type == tx.TransactionType.income) {
            // ENTRÉE: Augmenter la balance de la destination
            await _updateSourceBalance(
              isar,
              transaction.targetSourceId!,
              transaction.targetSourceType!,
              transaction.amount,
              isIncrease: true,
            );
          } else {
            // SORTIE: Réduire la balance de la source
            await _updateSourceBalance(
              isar,
              transaction.sourceId,
              transaction.sourceType,
              transaction.amount,
              isIncrease: false,
            );
          }
        });
      });
      
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTransaction(tx.TransactionModel transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTransaction(transaction);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTransaction(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _invalidateAll() {
    _ref.invalidate(transactionsStreamProvider);
    _ref.invalidate(thisMonthIncomeProvider);
    _ref.invalidate(thisMonthExpenseProvider);
    _ref.invalidate(totalIncomeProvider);
    _ref.invalidate(totalExpenseProvider);
    // Dashboard
    _ref.invalidate(dashboard.totalWealthProvider);
    _ref.invalidate(dashboard.thisMonthIncomeProvider);
    _ref.invalidate(dashboard.thisMonthExpenseProvider);
    _ref.invalidate(dashboard.weeklyActivityProvider);
    _ref.invalidate(dashboard.monthlyGrowthProvider);
    // Sources, Banks, Assets, Debts (unified)
    _ref.invalidate(unifiedSourcesProvider);
    _ref.invalidate(totalBankBalanceProvider);
    _ref.invalidate(totalAssetValueProvider);
    _ref.invalidate(totalGivenProvider);
    _ref.invalidate(totalReceivedProvider);
  }

  Future<void> _updateSourceBalance(
    Isar isar,
    int sourceId,
    tx.SourceType sourceType,
    double amount,
    {required bool isIncrease}
  ) async {
    switch (sourceType) {
      case tx.SourceType.source:
        final source = await isar.sourceModels.get(sourceId);
        if (source != null) {
          source.amount = isIncrease 
              ? source.amount + amount 
              : source.amount - amount;
          source.updatedAt = DateTime.now();
          await isar.sourceModels.put(source);
        }
        break;
      case tx.SourceType.bank:
        final bank = await isar.bankModels.get(sourceId);
        if (bank != null) {
          bank.balance = isIncrease 
              ? bank.balance + amount 
              : bank.balance - amount;
          bank.updatedAt = DateTime.now();
          await isar.bankModels.put(bank);
        }
        break;
      case tx.SourceType.asset:
        // Les assets ne changent pas de valeur avec les transactions
        break;
      case tx.SourceType.debt:
        // Les dettes sont gérées séparément
        break;
      case tx.SourceType.external:
        // Pas de mise à jour pour les sources externes
        break;
    }
  }
}

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionController(repository, ref);
});

import 'package:isar/isar.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final Isar isar;

  TransactionRepository(this.isar);

  // Create without transaction (for use within existing transactions)
  Future<int> putTransaction(TransactionModel transaction) async {
    return await isar.transactionModels.put(transaction);
  }

  // Create
  Future<int> addTransaction(TransactionModel transaction) async {
    return await isar.writeTxn(() async {
      return await isar.transactionModels.put(transaction);
    });
  }

  // Read All (toutes les transactions visibles)
  Future<List<TransactionModel>> getAllTransactions() async {
    return await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .findAll();
  }

  // Get by Type
  Future<List<TransactionModel>> getTransactionsByType(
      TransactionType type) async {
    return await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .typeEqualTo(type)
        .sortByDateDesc()
        .findAll();
  }

  // Get by Source
  Future<List<TransactionModel>> getTransactionsBySource(int sourceId) async {
    return await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .sourceIdEqualTo(sourceId)
        .sortByDateDesc()
        .findAll();
  }

  // Get by Date Range (toutes les transactions visibles)
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .dateBetween(startDate, endDate)
        .sortByDateDesc()
        .findAll();
  }

  // Watch All (toutes les transactions visibles)
  Stream<List<TransactionModel>> watchTransactions() {
    return isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // Update
  Future<void> updateTransaction(TransactionModel transaction) async {
    await isar.writeTxn(() async {
      transaction.updatedAt = DateTime.now();
      await isar.transactionModels.put(transaction);
    });
  }

  // Delete
  Future<void> deleteTransaction(int id) async {
    await isar.writeTxn(() async {
      final transaction = await isar.transactionModels.get(id);
      if (transaction != null) {
        transaction.isDeleted = true;
        transaction.updatedAt = DateTime.now();
        await isar.transactionModels.put(transaction);
      }
    });
  }

  // Get Total Income
  Future<double> getTotalIncome({DateTime? startDate, DateTime? endDate}) async {
    var query = isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo(TransactionStatus.active)
        .and()
        .typeEqualTo(TransactionType.income);

    if (startDate != null && endDate != null) {
      query = query.dateBetween(startDate, endDate);
    }

    final transactions = await query.findAll();
    return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // Get Total Expense
  Future<double> getTotalExpense({DateTime? startDate, DateTime? endDate}) async {
    var query = isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo(TransactionStatus.active)
        .and()
        .typeEqualTo(TransactionType.expense);

    if (startDate != null && endDate != null) {
      query = query.dateBetween(startDate, endDate);
    }

    final transactions = await query.findAll();
    return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // Get This Month Transactions
  Future<List<TransactionModel>> getThisMonthTransactions() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // Get This Year Transactions
  Future<List<TransactionModel>> getThisYearTransactions() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return await getTransactionsByDateRange(startOfYear, endOfYear);
  }

  // Cancel transactions related to a source/bank/asset
  Future<void> cancelTransactionsForEntity({
    required int entityId,
    required SourceType entityType,
  }) async {
    await isar.writeTxn(() async {
      // Annuler les transactions où l'entité est source
      final sourceTransactions = await isar.transactionModels
          .filter()
          .sourceIdEqualTo(entityId)
          .and()
          .sourceTypeEqualTo(entityType)
          .and()
          .statusEqualTo(TransactionStatus.active)
          .findAll();
      
      for (final transaction in sourceTransactions) {
        transaction.status = TransactionStatus.cancelled;
        transaction.updatedAt = DateTime.now();
        await isar.transactionModels.put(transaction);
      }
      
      // Annuler les transactions où l'entité est target
      final targetTransactions = await isar.transactionModels
          .filter()
          .targetSourceIdEqualTo(entityId)
          .and()
          .targetSourceTypeEqualTo(entityType)
          .and()
          .statusEqualTo(TransactionStatus.active)
          .findAll();
      
      for (final transaction in targetTransactions) {
        transaction.status = TransactionStatus.cancelled;
        transaction.updatedAt = DateTime.now();
        await isar.transactionModels.put(transaction);
      }
    });
  }
}

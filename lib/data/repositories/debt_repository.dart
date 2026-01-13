import 'package:isar_community/isar.dart';
import '../models/debt_model.dart';
import '../models/source_model.dart';
import '../models/bank_model.dart';
import '../models/transaction_model.dart' as tx;
import 'transaction_repository.dart';

class DebtRepository {
  final Isar isar;
  final TransactionRepository _transactionRepo;

  DebtRepository(this.isar) : _transactionRepo = TransactionRepository(isar);

  // Create debt given (lending money from source)
  Future<DebtModel> addDebtGiven({
    required DebtModel debt,
    required int sourceId,
    required tx.SourceType sourceType,
    required String sourceName,
  }) async {
    return await isar.writeTxn(() async {
      final debtId = await isar.debtModels.put(debt);
      debt.id = debtId;
      
      // TRANSACTION: Prêt (source → dette)
      final transaction = tx.TransactionModel(
        type: tx.TransactionType.expense,
        expenseCategory: tx.ExpenseCategory.debtGiven,
        amount: debt.totalAmount,
        currency: debt.currency,
        sourceId: sourceId,
        sourceName: sourceName,
        sourceType: sourceType,
        targetSourceId: debtId,
        targetSourceName: 'Dette ${debt.personName}',
        targetSourceType: tx.SourceType.debt,
        relatedDebtId: debtId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Prêt à ${debt.personName}',
      );
      await _transactionRepo.putTransaction(transaction);
      
      // RÉDUIRE le solde de la source (argent sort)
      if (sourceType == tx.SourceType.source) {
        final source = await isar.sourceModels.get(sourceId);
        if (source != null) {
          source.amount = source.amount - debt.totalAmount;
          source.updatedAt = DateTime.now();
          await isar.sourceModels.put(source);
        }
      } else if (sourceType == tx.SourceType.bank) {
        final bank = await isar.bankModels.get(sourceId);
        if (bank != null) {
          bank.balance = bank.balance - debt.totalAmount;
          bank.updatedAt = DateTime.now();
          await isar.bankModels.put(bank);
        }
      }
      
      return debt;
    });
  }

  // Create debt received (borrowing money to source)
  Future<DebtModel> addDebtReceived({
    required DebtModel debt,
    required int targetId,
    required tx.SourceType targetType,
    required String targetName,
  }) async {
    return await isar.writeTxn(() async {
      final debtId = await isar.debtModels.put(debt);
      debt.id = debtId;
      
      // TRANSACTION: Emprunt (dette → source)
      final transaction = tx.TransactionModel(
        type: tx.TransactionType.income,
        incomeCategory: tx.IncomeCategory.debtReceived,
        amount: debt.totalAmount,
        currency: debt.currency,
        sourceId: debtId,
        sourceName: 'Dette ${debt.personName}',
        sourceType: tx.SourceType.debt,
        targetSourceId: targetId,
        targetSourceName: targetName,
        targetSourceType: targetType,
        relatedDebtId: debtId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Emprunt de ${debt.personName}',
      );
      await _transactionRepo.putTransaction(transaction);
      
      // AUGMENTER le solde de la destination (argent entre)
      if (targetType == tx.SourceType.source) {
        final source = await isar.sourceModels.get(targetId);
        if (source != null) {
          source.amount = source.amount + debt.totalAmount;
          source.updatedAt = DateTime.now();
          await isar.sourceModels.put(source);
        }
      } else if (targetType == tx.SourceType.bank) {
        final bank = await isar.bankModels.get(targetId);
        if (bank != null) {
          bank.balance = bank.balance + debt.totalAmount;
          bank.updatedAt = DateTime.now();
          await isar.bankModels.put(bank);
        }
      }
      
      return debt;
    });
  }

  // Read all
  Future<List<DebtModel>> getAllDebts() async {
    return await isar.debtModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }

  // Read by ID
  Future<DebtModel?> getDebtById(int id) async {
    return await isar.debtModels.get(id);
  }

  // Watch all debts (Stream)
  Stream<List<DebtModel>> watchDebts() {
    return isar.debtModels
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  // Update
  Future<void> updateDebt(DebtModel debt) async {
    final oldDebt = await getDebtById(debt.id);
    
    await isar.writeTxn(() async {
      await isar.debtModels.put(debt);
    });
    
    // TRANSACTION: Si le montant payé a changé (remboursement)
    if (oldDebt != null && oldDebt.paidAmount != debt.paidAmount) {
      final paymentAmount = debt.paidAmount - oldDebt.paidAmount;
      if (paymentAmount > 0) {
        final transaction = tx.TransactionModel(
          type: debt.type == DebtType.given ? tx.TransactionType.income : tx.TransactionType.expense,
          incomeCategory: tx.IncomeCategory.debtReceived,
          expenseCategory: tx.ExpenseCategory.debtGiven,
          amount: paymentAmount,
          currency: debt.currency,
          sourceId: debt.type == DebtType.given ? debt.id : 0,
          sourceName: debt.type == DebtType.given ? 'Dette ${debt.personName}' : 'Externe',
          sourceType: debt.type == DebtType.given ? tx.SourceType.debt : tx.SourceType.external,
          targetSourceId: debt.type == DebtType.given ? 0 : debt.id,
          targetSourceName: debt.type == DebtType.given ? 'Externe' : 'Dette ${debt.personName}',
          targetSourceType: debt.type == DebtType.given ? tx.SourceType.external : tx.SourceType.debt,
          relatedDebtId: debt.id,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: debt.type == DebtType.given 
              ? 'Remboursement de ${debt.personName}'
              : 'Remboursement à ${debt.personName}',
        );
        await _transactionRepo.addTransaction(transaction);
      }
    }
  }

  // Delete (Soft Delete)
  Future<bool> deleteDebt(int id) async {
    return await isar.writeTxn(() async {
      final debt = await isar.debtModels.get(id);
      if (debt != null) {
        debt.isDeleted = true;
        debt.updatedAt = DateTime.now();
        await isar.debtModels.put(debt);
        return true;
      }
      return false;
    });
  }

  // Get debts by type
  Future<List<DebtModel>> getDebtsByType(DebtType type) async {
    return await isar.debtModels.filter().typeEqualTo(type).findAll();
  }

  // Get active debts (not fully paid)
  Future<List<DebtModel>> getActiveDebts() async {
    return await isar.debtModels
        .filter()
        .statusEqualTo(DebtStatus.pending)
        .or()
        .statusEqualTo(DebtStatus.partiallyPaid)
        .findAll();
  }

  // Get given debts (money lent to others)
  Future<List<DebtModel>> getGivenDebts() async {
    return await isar.debtModels.filter().typeEqualTo(DebtType.given).findAll();
  }

  // Get received debts (money borrowed)
  Future<List<DebtModel>> getReceivedDebts() async {
    return await isar.debtModels.filter().typeEqualTo(DebtType.received).findAll();
  }

  // Get total given (money lent out)
  Future<double> getTotalGiven() async {
    final debts = await getGivenDebts();
    return debts.fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Get total received (money borrowed)
  Future<double> getTotalReceived() async {
    final debts = await getReceivedDebts();
    return debts.fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  // Add payment with source tracking
  Future<void> addPaymentWithSource({
    required DebtModel debt,
    required double amount,
    required int sourceId,
    required String sourceName,
    required tx.SourceType sourceType,
  }) async {
    await isar.writeTxn(() async {
      // Mettre à jour la dette
      debt.addPayment(amount);
      await isar.debtModels.put(debt);
      
      // Créer les transactions selon le type de dette
      if (debt.type == DebtType.given) {
        // Remboursement reçu : dette -> source
        final transaction = tx.TransactionModel(
          type: tx.TransactionType.income,
          incomeCategory: tx.IncomeCategory.debtReceived,
          amount: amount,
          currency: debt.currency,
          sourceId: debt.id,
          sourceName: 'Dette ${debt.personName}',
          sourceType: tx.SourceType.debt,
          targetSourceId: sourceId,
          targetSourceName: sourceName,
          targetSourceType: sourceType,
          relatedDebtId: debt.id,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Remboursement de ${debt.personName}',
        );
        await _transactionRepo.putTransaction(transaction);
        
        // Augmenter le solde de la source de destination
        if (sourceType == tx.SourceType.source) {
          final source = await isar.sourceModels.get(sourceId);
          if (source != null) {
            source.amount = source.amount + amount;
            source.updatedAt = DateTime.now();
            await isar.sourceModels.put(source);
          }
        } else if (sourceType == tx.SourceType.bank) {
          final bank = await isar.bankModels.get(sourceId);
          if (bank != null) {
            bank.balance = bank.balance + amount;
            bank.updatedAt = DateTime.now();
            await isar.bankModels.put(bank);
          }
        }
      } else {
        // Remboursement payé : source -> dette
        final transaction = tx.TransactionModel(
          type: tx.TransactionType.expense,
          expenseCategory: tx.ExpenseCategory.debtGiven,
          amount: amount,
          currency: debt.currency,
          sourceId: sourceId,
          sourceName: sourceName,
          sourceType: sourceType,
          targetSourceId: debt.id,
          targetSourceName: 'Dette ${debt.personName}',
          targetSourceType: tx.SourceType.debt,
          relatedDebtId: debt.id,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Remboursement à ${debt.personName}',
        );
        await _transactionRepo.putTransaction(transaction);
        
        // Réduire le solde de la source d'origine
        if (sourceType == tx.SourceType.source) {
          final source = await isar.sourceModels.get(sourceId);
          if (source != null) {
            source.amount = source.amount - amount;
            source.updatedAt = DateTime.now();
            await isar.sourceModels.put(source);
          }
        } else if (sourceType == tx.SourceType.bank) {
          final bank = await isar.bankModels.get(sourceId);
          if (bank != null) {
            bank.balance = bank.balance - amount;
            bank.updatedAt = DateTime.now();
            await isar.bankModels.put(bank);
          }
        }
      }
    });
  }
  Future<List<DebtModel>> getOverdueDebts() async {
    final now = DateTime.now();
    final allDebts = await getAllDebts();
    return allDebts.where((debt) {
      if (debt.status == DebtStatus.fullyPaid || debt.dueDate == null) return false;
      return debt.dueDate!.isBefore(now);
    }).toList();
  }
}

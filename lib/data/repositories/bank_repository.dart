import 'package:ikigabo/data/models/source_model.dart';
import 'package:isar/isar.dart';
import '../models/bank_model.dart';
import '../models/transaction_model.dart' as tx;
import 'transaction_repository.dart';

class BankRepository {
  final Isar isar;
  final TransactionRepository _transactionRepo;

  BankRepository(this.isar) : _transactionRepo = TransactionRepository(isar);

  // Create
  Future<BankModel> addBank(BankModel bank) async {
    final bankId = await isar.writeTxn(() async {
      return await isar.bankModels.put(bank);
    });

    bank.id = bankId;
    return bank;
  }

  // Create with initial balance from source
  Future<BankModel> addBankWithTransfer({
    required BankModel bank,
    required int sourceId,
    required tx.SourceType sourceType,
    required String sourceName,
  }) async {
    return await isar.writeTxn(() async {
      final savedBank = await isar.bankModels.put(bank);
      bank.id = savedBank;

      if (bank.balance > 0) {
        // TRANSACTION 1: Sortie de la source
        final outTransaction = tx.TransactionModel(
          type: tx.TransactionType.expense,
          expenseCategory: tx.ExpenseCategory.other,
          amount: bank.balance,
          currency: bank.currency,
          sourceId: sourceId,
          sourceName: sourceName,
          sourceType: sourceType,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Transfert vers banque "${bank.name}"',
        );
        await _transactionRepo.putTransaction(outTransaction);

        // TRANSACTION 2: Entrée vers la banque
        final inTransaction = tx.TransactionModel(
          type: tx.TransactionType.income,
          incomeCategory: tx.IncomeCategory.other,
          amount: bank.balance,
          currency: bank.currency,
          sourceId: 0,
          sourceName: 'Externe',
          sourceType: tx.SourceType.external,
          targetSourceId: savedBank,
          targetSourceName: bank.name,
          targetSourceType: tx.SourceType.bank,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Dépôt depuis "${sourceName}"',
        );
        await _transactionRepo.putTransaction(inTransaction);

        // IMPORTANT: Mettre à jour le solde de la source
        if (sourceType == tx.SourceType.source) {
          final source = await isar.sourceModels.get(sourceId);
          if (source != null) {
            source.amount = source.amount - bank.balance;
            source.updatedAt = DateTime.now();
            await isar.sourceModels.put(source);
          }
        } else if (sourceType == tx.SourceType.bank) {
          final sourceBank = await isar.bankModels.get(sourceId);
          if (sourceBank != null) {
            sourceBank.balance = sourceBank.balance - bank.balance;
            sourceBank.updatedAt = DateTime.now();
            await isar.bankModels.put(sourceBank);
          }
        }
      }

      return bank;
    });
  }

  // Create with existing balance (external source)
  Future<BankModel> addBankWithExistingBalance(BankModel bank) async {
    return await isar.writeTxn(() async {
      final savedBank = await isar.bankModels.put(bank);
      bank.id = savedBank;

      if (bank.balance > 0) {
        // TRANSACTION: Enregistrement du solde existant (externe → banque)
        final transaction = tx.TransactionModel(
          type: tx.TransactionType.income,
          incomeCategory: tx.IncomeCategory.other,
          amount: bank.balance,
          currency: bank.currency,
          sourceId: 0,
          sourceName: 'Externe',
          sourceType: tx.SourceType.external,
          targetSourceId: savedBank,
          targetSourceName: bank.name,
          targetSourceType: tx.SourceType.bank,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description:
              'Enregistrement banque "${bank.name}" avec solde existant',
        );
        await _transactionRepo.putTransaction(transaction);
      }

      return bank;
    });
  }

  // Read all
  Future<List<BankModel>> getAllBanks() async {
    return await isar.bankModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }

  // Read by ID
  Future<BankModel?> getBankById(int id) async {
    return await isar.bankModels.get(id);
  }

  // Watch all banks (Stream)
  Stream<List<BankModel>> watchBanks() {
    return isar.bankModels
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  // Update
  Future<void> updateBank(BankModel bank) async {
    final oldBank = await getBankById(bank.id);

    await isar.writeTxn(() async {
      await isar.bankModels.put(bank);
    });

    // TRANSACTION: Si le solde a changé
    if (oldBank != null && oldBank.balance != bank.balance) {
      final difference = bank.balance - oldBank.balance;
      final transaction = tx.TransactionModel(
        type: difference > 0 ? tx.TransactionType.income : tx.TransactionType.expense,
        incomeCategory: tx.IncomeCategory.other,
        expenseCategory: tx.ExpenseCategory.other,
        amount: difference.abs(),
        currency: bank.currency,
        sourceId: difference > 0 ? 0 : bank.id,
        sourceName: difference > 0 ? 'Externe' : bank.name,
        sourceType: difference > 0 ? tx.SourceType.external : tx.SourceType.bank,
        targetSourceId: difference > 0 ? bank.id : 0,
        targetSourceName: difference > 0 ? bank.name : 'Externe',
        targetSourceType: difference > 0
            ? tx.SourceType.bank
            : tx.SourceType.external,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Ajustement solde banque "${bank.name}"',
      );
      await _transactionRepo.addTransaction(transaction);
    }
  }

  // Delete (Soft Delete)
  Future<bool> deleteBank(int id) async {
    return await isar.writeTxn(() async {
      final bank = await isar.bankModels.get(id);
      if (bank != null) {
        bank.isDeleted = true;
        bank.updatedAt = DateTime.now();
        await isar.bankModels.put(bank);
        return true;
      }
      return false;
    });
  }

  // Hard Delete
  Future<bool> hardDeleteBank(int id) async {
    return await isar.writeTxn(() async {
      return await isar.bankModels.delete(id);
    });
  }

  // Get total balance across all banks
  Future<double> getTotalBalance() async {
    final banks = await getAllBanks();
    return banks.fold<double>(0.0, (sum, bank) => sum + bank.balance);
  }

  // Get banks by type
  Future<List<BankModel>> getBanksByType(BankType type) async {
    return await isar.bankModels
        .filter()
        .isDeletedEqualTo(false)
        .bankTypeEqualTo(type)
        .findAll();
  }

  // Process automatic interest deduction
  Future<void> processInterestDeductions() async {
    final banks = await isar.bankModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    for (final bank in banks) {
      if (bank.shouldDeductInterest()) {
        final interest = bank.calculateInterest();
        bank.balance = bank.balance - interest;
        bank.lastDeductionDate = DateTime.now();
        bank.nextDeductionDate = bank.calculateNextDeductionDate();
        await updateBank(bank);
      }
    }
  }
}

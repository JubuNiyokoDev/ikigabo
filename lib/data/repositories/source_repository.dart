import 'package:isar/isar.dart';
import '../models/source_model.dart';
import '../models/bank_model.dart';
import '../models/transaction_model.dart' as tx;
import 'transaction_repository.dart';

class SourceRepository {
  final Isar isar;
  final TransactionRepository _transactionRepo;

  SourceRepository(this.isar) : _transactionRepo = TransactionRepository(isar);

  // Create
  Future<SourceModel> addSource(SourceModel source) async {
    final sourceId = await isar.writeTxn(() async {
      if (source.id != Isar.autoIncrement) {
        source.id = Isar.autoIncrement;
      }
      return await isar.sourceModels.put(source);
    });

    source.id = sourceId;
    return source;
  }

  // Create with initial amount from another source
  Future<SourceModel> addSourceWithTransfer({
    required SourceModel source,
    required int fromSourceId,
    required tx.SourceType fromSourceType,
    required String fromSourceName,
  }) async {
    return await isar.writeTxn(() async {
      final sourceId = await isar.sourceModels.put(source);
      source.id = sourceId;

      if (source.amount > 0) {
        // TRANSACTION 1: Sortie de la source d'origine
        final outTransaction = tx.TransactionModel(
          type: tx.TransactionType.expense,
          expenseCategory: tx.ExpenseCategory.other,
          amount: source.amount,
          currency: source.currency,
          sourceId: fromSourceId,
          sourceName: fromSourceName,
          sourceType: fromSourceType,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Transfert vers source "${source.name}"',
        );
        await _transactionRepo.putTransaction(outTransaction);

        // TRANSACTION 2: Entrée vers la nouvelle source
        final inTransaction = tx.TransactionModel(
          type: tx.TransactionType.income,
          incomeCategory: tx.IncomeCategory.other,
          amount: source.amount,
          currency: source.currency,
          sourceId: 0,
          sourceName: 'Externe',
          sourceType: tx.SourceType.external,
          targetSourceId: sourceId,
          targetSourceName: source.name,
          targetSourceType: tx.SourceType.source,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Transfert depuis "${fromSourceName}"',
        );
        await _transactionRepo.putTransaction(inTransaction);

        // IMPORTANT: Mettre à jour le solde de la source d'origine
        if (fromSourceType == tx.SourceType.source) {
          final fromSource = await isar.sourceModels.get(fromSourceId);
          if (fromSource != null) {
            fromSource.amount = fromSource.amount - source.amount;
            fromSource.updatedAt = DateTime.now();
            await isar.sourceModels.put(fromSource);
          }
        } else if (fromSourceType == tx.SourceType.bank) {
          final fromBank = await isar.bankModels.get(fromSourceId);
          if (fromBank != null) {
            fromBank.balance = fromBank.balance - source.amount;
            fromBank.updatedAt = DateTime.now();
            await isar.bankModels.put(fromBank);
          }
        }
      }

      return source;
    });
  }

  // Create source from external income
  Future<SourceModel> addSourceFromIncome({
    required SourceModel source,
    required tx.IncomeCategory category,
  }) async {
    final savedSource = await addSource(source);

    if (source.amount > 0) {
      // TRANSACTION: Entrée externe → source
      final transaction = tx.TransactionModel(
        type: tx.TransactionType.income,
        incomeCategory: category,
        amount: source.amount,
        currency: source.currency,
        sourceId: 0,
        sourceName: 'Externe',
        sourceType: tx.SourceType.external,
        targetSourceId: savedSource.id,
        targetSourceName: source.name,
        targetSourceType: tx.SourceType.source,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Création source "${source.name}" avec entrée',
      );
      await _transactionRepo.addTransaction(transaction);
    }

    return savedSource;
  }

  // Read All
  Future<List<SourceModel>> getAllSources() async {
    return await isar.sourceModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  // Read by ID
  Future<SourceModel?> getSourceById(int id) async {
    return await isar.sourceModels.get(id);
  }

  // Read by Type
  Future<List<SourceModel>> getSourcesByType(SourceType type) async {
    return await isar.sourceModels
        .filter()
        .isDeletedEqualTo(false)
        .typeEqualTo(type)
        .sortByCreatedAtDesc()
        .findAll();
  }

  // Watch All (Stream)
  Stream<List<SourceModel>> watchSources() {
    return isar.sourceModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  // Update
  Future<void> updateSource(SourceModel source) async {
    final oldSource = await getSourceById(source.id);

    await isar.writeTxn(() async {
      source.updatedAt = DateTime.now();
      await isar.sourceModels.put(source);
    });

    // TRANSACTION: Si le montant ou la devise a changé
    if (oldSource != null && (oldSource.amount != source.amount || oldSource.currency != source.currency)) {
      if (oldSource.currency != source.currency) {
        // Changement de devise : créer transaction de sortie puis d'entrée
        final outTransaction = tx.TransactionModel(
          type: tx.TransactionType.expense,
          expenseCategory: tx.ExpenseCategory.other,
          amount: oldSource.amount,
          currency: oldSource.currency,
          sourceId: source.id,
          sourceName: source.name,
          sourceType: tx.SourceType.source,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Conversion devise ${oldSource.currency} → ${source.currency}',
        );
        await _transactionRepo.addTransaction(outTransaction);
        
        final inTransaction = tx.TransactionModel(
          type: tx.TransactionType.income,
          incomeCategory: tx.IncomeCategory.other,
          amount: source.amount,
          currency: source.currency,
          sourceId: 0,
          sourceName: 'Externe',
          sourceType: tx.SourceType.external,
          targetSourceId: source.id,
          targetSourceName: source.name,
          targetSourceType: tx.SourceType.source,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Conversion devise ${oldSource.currency} → ${source.currency}',
        );
        await _transactionRepo.addTransaction(inTransaction);
      } else {
        // Changement de montant seulement
        final difference = source.amount - oldSource.amount;
        final transaction = tx.TransactionModel(
          type: difference > 0 ? tx.TransactionType.income : tx.TransactionType.expense,
          incomeCategory: tx.IncomeCategory.other,
          expenseCategory: tx.ExpenseCategory.other,
          amount: difference.abs(),
          currency: source.currency,
          sourceId: difference > 0 ? 0 : source.id,
          sourceName: difference > 0 ? 'Externe' : source.name,
          sourceType: difference > 0 ? tx.SourceType.external : tx.SourceType.source,
          targetSourceId: difference > 0 ? source.id : 0,
          targetSourceName: difference > 0 ? source.name : 'Externe',
          targetSourceType: difference > 0
              ? tx.SourceType.source
              : tx.SourceType.external,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Ajustement montant source "${source.name}"',
        );
        await _transactionRepo.addTransaction(transaction);
      }
    }
  }

  // Delete (Soft Delete)
  Future<void> deleteSource(int id) async {
    await isar.writeTxn(() async {
      final source = await isar.sourceModels.get(id);
      if (source != null) {
        source.isDeleted = true;
        source.updatedAt = DateTime.now();
        await isar.sourceModels.put(source);
      }
    });
  }

  // Hard Delete
  Future<void> hardDeleteSource(int id) async {
    await isar.writeTxn(() async {
      await isar.sourceModels.delete(id);
    });
  }

  // Calculate Total Balance
  Future<double> getTotalBalance() async {
    final sources = await getAllSources();
    return sources.fold<double>(0.0, (sum, source) => sum + source.amount);
  }

  // Get Active Sources Balance
  Future<double> getActiveSourcesBalance() async {
    final sources = await isar.sourceModels
        .filter()
        .isDeletedEqualTo(false)
        .isActiveEqualTo(true)
        .findAll();
    return sources.fold<double>(0.0, (sum, source) => sum + source.amount);
  }

  // Search Sources
  Future<List<SourceModel>> searchSources(String query) async {
    return await isar.sourceModels
        .filter()
        .isDeletedEqualTo(false)
        .nameContains(query, caseSensitive: false)
        .or()
        .descriptionContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }
}

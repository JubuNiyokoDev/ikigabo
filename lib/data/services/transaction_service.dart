import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/bank_repository.dart';
import '../repositories/source_repository.dart';
import '../repositories/asset_repository.dart';

class TransactionService {
  final TransactionRepository _transactionRepo;
  final BankRepository _bankRepo;
  final SourceRepository _sourceRepo;

  TransactionService({
    required TransactionRepository transactionRepo,
    required BankRepository bankRepo,
    required SourceRepository sourceRepo,
    required AssetRepository assetRepo,
  }) : _transactionRepo = transactionRepo,
       _bankRepo = bankRepo,
       _sourceRepo = sourceRepo;

  /// Créer une entrée d'argent externe (salaire, vente, etc.)
  Future<void> createIncomeTransaction({
    required double amount,
    required String currency,
    required int destinationId,
    required SourceType destinationType,
    required IncomeCategory category,
    String? description,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      type: TransactionType.income,
      incomeCategory: category,
      amount: amount,
      currency: currency,
      sourceId: 0, // External source
      sourceName: 'Externe',
      sourceType: SourceType.external,
      targetSourceId: destinationId,
      targetSourceType: destinationType,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description,
    );

    await _transactionRepo.addTransaction(transaction);
    await _updateDestinationBalance(
      destinationId,
      destinationType,
      amount,
      true,
    );
  }

  /// Créer une sortie d'argent (achat, prêt, etc.)
  Future<void> createExpenseTransaction({
    required double amount,
    required String currency,
    required int sourceId,
    required SourceType sourceType,
    required ExpenseCategory category,
    int? targetId,
    SourceType? targetType,
    String? description,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      type: TransactionType.expense,
      expenseCategory: category,
      amount: amount,
      currency: currency,
      sourceId: sourceId,
      sourceType: sourceType,
      targetSourceId: targetId,
      targetSourceType: targetType,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description,
    );

    await _transactionRepo.addTransaction(transaction);
    await _updateDestinationBalance(sourceId, sourceType, amount, false);
  }

  /// Créer un transfert entre sources
  Future<void> createTransferTransaction({
    required double amount,
    required String currency,
    required int sourceId,
    required SourceType sourceType,
    required int targetId,
    required SourceType targetType,
    String? description,
    DateTime? date,
  }) async {
    // Transaction de sortie
    final outTransaction = TransactionModel(
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.withdrawal,
      amount: amount,
      currency: currency,
      sourceId: sourceId,
      sourceType: sourceType,
      targetSourceId: targetId,
      targetSourceType: targetType,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description ?? 'Transfert sortant',
    );

    // Transaction d'entrée
    final inTransaction = TransactionModel(
      type: TransactionType.income,
      incomeCategory: IncomeCategory.other,
      amount: amount,
      currency: currency,
      sourceId: sourceId,
      sourceType: sourceType,
      targetSourceId: targetId,
      targetSourceType: targetType,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description ?? 'Transfert entrant',
    );

    await _transactionRepo.addTransaction(outTransaction);
    await _transactionRepo.addTransaction(inTransaction);

    await _updateDestinationBalance(sourceId, sourceType, amount, false);
    await _updateDestinationBalance(targetId, targetType, amount, true);
  }

  /// Acheter un asset avec source spécifiée
  Future<void> buyAsset({
    required double amount,
    required String currency,
    required int sourceId,
    required SourceType sourceType,
    required int assetId,
    String? description,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      type: TransactionType.expense,
      expenseCategory: ExpenseCategory.assetPurchase,
      amount: amount,
      currency: currency,
      sourceId: sourceId,
      sourceType: sourceType,
      targetSourceId: assetId,
      targetSourceType: SourceType.asset,
      relatedAssetId: assetId,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description ?? 'Achat d\'actif',
    );

    await _transactionRepo.addTransaction(transaction);
    await _updateDestinationBalance(sourceId, sourceType, amount, false);
  }

  /// Vendre un asset vers une source spécifiée
  Future<void> sellAsset({
    required double amount,
    required String currency,
    required int assetId,
    required int targetId,
    required SourceType targetType,
    String? description,
    DateTime? date,
  }) async {
    final transaction = TransactionModel(
      type: TransactionType.income,
      incomeCategory: IncomeCategory.sale,
      amount: amount,
      currency: currency,
      sourceId: assetId,
      sourceType: SourceType.asset,
      targetSourceId: targetId,
      targetSourceType: targetType,
      relatedAssetId: assetId,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      description: description ?? 'Vente d\'actif',
    );

    await _transactionRepo.addTransaction(transaction);
    await _updateDestinationBalance(targetId, targetType, amount, true);
  }

  /// Mettre à jour le solde de la destination
  Future<void> _updateDestinationBalance(
    int id,
    SourceType type,
    double amount,
    bool isIncrease,
  ) async {
    final adjustedAmount = isIncrease ? amount : -amount;

    switch (type) {
      case SourceType.bank:
        final bank = await _bankRepo.getBankById(id);
        if (bank != null) {
          bank.balance += adjustedAmount;
          await _bankRepo.updateBank(bank);
        }
        break;
      case SourceType.source:
        final source = await _sourceRepo.getSourceById(id);
        if (source != null) {
          source.amount += adjustedAmount;
          await _sourceRepo.updateSource(source);
        }
        break;
      case SourceType.asset:
        // Les assets ne changent pas de valeur lors des transactions
        break;
      case SourceType.debt:
        // Géré par le DebtService
        break;
      case SourceType.external:
        // Pas de mise à jour nécessaire
        break;
    }
  }

  /// Obtenir l'historique complet avec source/destination
  Future<List<TransactionModel>> getTransactionHistory() async {
    return await _transactionRepo.getAllTransactions();
  }

  /// Obtenir les transactions par période
  Future<List<TransactionModel>> getTransactionsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await _transactionRepo.getTransactionsByDateRange(start, end);
  }
}

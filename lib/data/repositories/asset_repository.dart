import 'package:ikigabo/data/models/source_model.dart';
import 'package:ikigabo/data/models/bank_model.dart';
import 'package:isar/isar.dart';
import '../models/asset_model.dart';
import '../models/transaction_model.dart' as tx;
import 'transaction_repository.dart';

class AssetRepository {
  final Isar isar;
  final TransactionRepository _transactionRepo;

  AssetRepository(this.isar) : _transactionRepo = TransactionRepository(isar);

  // Create asset simple (without transaction)
  Future<AssetModel> addAsset(AssetModel asset) async {
    final assetId = await isar.writeTxn(() async {
      return await isar.assetModels.put(asset);
    });

    asset.id = assetId;
    return asset;
  }

  // Create asset with purchase from source
  Future<AssetModel> addAssetWithPurchase({
    required AssetModel asset,
    required int sourceId,
    required tx.SourceType sourceType,
    required String sourceName,
  }) async {
    return await isar.writeTxn(() async {
      final assetId = await isar.assetModels.put(asset);
      asset.id = assetId;

      // TRANSACTION 1: Achat asset (source → externe) - Sortie d'argent
      final purchaseTransaction = tx.TransactionModel(
        type: tx.TransactionType.expense,
        expenseCategory: tx.ExpenseCategory.assetPurchase,
        amount: asset.purchasePrice,
        currency: asset.currency,
        sourceId: sourceId,
        sourceName: sourceName,
        sourceType: sourceType,
        targetSourceId: 0,
        targetSourceName: 'Externe',
        targetSourceType: tx.SourceType.external,
        relatedAssetId: assetId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Achat asset "${asset.name}"',
      );
      await _transactionRepo.putTransaction(purchaseTransaction);

      // TRANSACTION 2: Acquisition de la valeur de l'asset (externe → patrimoine) - Entrée de valeur
      final valueTransaction = tx.TransactionModel(
        type: tx.TransactionType.income,
        incomeCategory: tx.IncomeCategory.investment,
        amount: asset.currentValue, // Utiliser currentValue pour refléter la vraie valeur
        currency: asset.currency,
        sourceId: 0,
        sourceName: 'Externe',
        sourceType: tx.SourceType.external,
        targetSourceId: assetId,
        targetSourceName: asset.name,
        targetSourceType: tx.SourceType.asset,
        relatedAssetId: assetId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Valeur asset "${asset.name}"',
      );
      await _transactionRepo.putTransaction(valueTransaction);

      // IMPORTANT: Mettre à jour le solde de la source
      if (sourceType == tx.SourceType.source) {
        final source = await isar.sourceModels.get(sourceId);
        if (source != null) {
          source.amount = source.amount - asset.purchasePrice;
          source.updatedAt = DateTime.now();
          await isar.sourceModels.put(source);
        }
      } else if (sourceType == tx.SourceType.bank) {
        final bank = await isar.bankModels.get(sourceId);
        if (bank != null) {
          bank.balance = bank.balance - asset.purchasePrice;
          bank.updatedAt = DateTime.now();
          await isar.bankModels.put(bank);
        }
      }

      return asset;
    });
  }

  // Create asset without purchase (gift, inheritance, etc.)
  Future<AssetModel> addAssetWithoutPurchase({
    required AssetModel asset,
    required tx.IncomeCategory category,
  }) async {
    return await isar.writeTxn(() async {
      final assetId = await isar.assetModels.put(asset);
      asset.id = assetId;

      // TRANSACTION: Acquisition asset sans achat
      final transaction = tx.TransactionModel(
        type: tx.TransactionType.income,
        incomeCategory: category,
        amount: asset.currentValue,
        currency: asset.currency,
        sourceId: 0,
        sourceName: 'Externe',
        sourceType: tx.SourceType.external,
        targetSourceId: assetId,
        targetSourceName: asset.name,
        targetSourceType: tx.SourceType.asset,
        relatedAssetId: assetId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Acquisition asset "${asset.name}"',
      );
      await _transactionRepo.putTransaction(transaction);

      return asset;
    });
  }

  // Read all
  Future<List<AssetModel>> getAllAssets() async {
    return await isar.assetModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }

  // Read by ID
  Future<AssetModel?> getAssetById(int id) async {
    return await isar.assetModels.get(id);
  }

  // Watch all assets (Stream)
  Stream<List<AssetModel>> watchAssets() {
    return isar.assetModels
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  // Update
  Future<void> updateAsset(AssetModel asset) async {
    final oldAsset = await getAssetById(asset.id);

    await isar.writeTxn(() async {
      await isar.assetModels.put(asset);
    });

    // TRANSACTION: Si la valeur a changé
    if (oldAsset != null && oldAsset.currentValue != asset.currentValue) {
      final difference = asset.currentValue - oldAsset.currentValue;
      final transaction = tx.TransactionModel(
        type: difference > 0 ? tx.TransactionType.income : tx.TransactionType.expense,
        incomeCategory: tx.IncomeCategory.investment,
        expenseCategory: tx.ExpenseCategory.other,
        amount: difference.abs(),
        currency: asset.currency,
        sourceId: difference > 0 ? 0 : asset.id,
        sourceName: difference > 0 ? 'Externe' : asset.name,
        sourceType: difference > 0 ? tx.SourceType.external : tx.SourceType.asset,
        targetSourceId: difference > 0 ? asset.id : 0,
        targetSourceName: difference > 0 ? asset.name : 'Externe',
        targetSourceType: difference > 0
            ? tx.SourceType.asset
            : tx.SourceType.external,
        relatedAssetId: asset.id,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'Réévaluation asset "${asset.name}"',
      );
      await _transactionRepo.addTransaction(transaction);
    }
  }

  // Delete (Soft Delete)
  Future<bool> deleteAsset(int id) async {
    return await isar.writeTxn(() async {
      final asset = await isar.assetModels.get(id);
      if (asset != null) {
        asset.isDeleted = true;
        asset.updatedAt = DateTime.now();
        await isar.assetModels.put(asset);
        return true;
      }
      return false;
    });
  }

  // Get total value across all assets
  Future<double> getTotalValue() async {
    final assets = await getAllAssets();
    return assets.fold<double>(0.0, (sum, asset) => sum + asset.totalValue);
  }

  // Get assets by type
  Future<List<AssetModel>> getAssetsByType(AssetType type) async {
    return await isar.assetModels.filter().typeEqualTo(type).findAll();
  }

  // Get assets by status
  Future<List<AssetModel>> getAssetsByStatus(AssetStatus status) async {
    return await isar.assetModels.filter().statusEqualTo(status).findAll();
  }

  // Get owned assets only
  Future<List<AssetModel>> getOwnedAssets() async {
    return await isar.assetModels
        .filter()
        .statusEqualTo(AssetStatus.owned)
        .findAll();
  }
}

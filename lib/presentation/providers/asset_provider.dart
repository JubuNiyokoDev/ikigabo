import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/repositories/asset_repository.dart';
import 'isar_provider.dart';
import 'currency_provider.dart';
import 'source_provider.dart';
import 'transaction_provider.dart';
import 'dashboard_provider.dart' as dashboard;
import '../../core/services/currency_conversion_service.dart';

// Repository Provider
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar is not initialized');
  }
  return AssetRepository(isar);
});

// All Assets Stream
final assetsStreamProvider = StreamProvider<List<AssetModel>>((ref) {
  final repository = ref.watch(assetRepositoryProvider);
  return repository.watchAssets();
});

// Total value across all assets - converted to display currency
final totalAssetValueProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final assetsAsync = ref.watch(assetsStreamProvider);
  
  final assets = await assetsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<AssetModel>[]),
    error: (_, __) => Future.value(<AssetModel>[]),
  );
  
  double total = 0.0;
  for (final asset in assets) {
    if (asset.status == AssetStatus.owned) {
      final converted = await CurrencyConversionService.convert(
        amount: asset.totalValue,
        fromCurrency: asset.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }
  
  return total;
});

// Owned assets only
final ownedAssetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getOwnedAssets();
});

// Assets by type
final livestockAssetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetsByType(AssetType.livestock);
});

final cropAssetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetsByType(AssetType.crop);
});

final landAssetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetsByType(AssetType.land);
});

final vehicleAssetsProvider = FutureProvider<List<AssetModel>>((ref) async {
  final repository = ref.watch(assetRepositoryProvider);
  return await repository.getAssetsByType(AssetType.vehicle);
});

// Asset statistics - converted to display currency
final assetStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final assetsAsync = ref.watch(assetsStreamProvider);
  
  final allAssets = await assetsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<AssetModel>[]),
    error: (_, __) => Future.value(<AssetModel>[]),
  );
  
  final ownedAssets = allAssets.where((a) => a.status == AssetStatus.owned).toList();
  
  double totalValue = 0.0;
  double totalPurchasePrice = 0.0;
  
  for (final asset in ownedAssets) {
    final convertedValue = await CurrencyConversionService.convert(
      amount: asset.totalValue,
      fromCurrency: asset.currency,
      toCurrency: displayCurrency.code,
    );
    final convertedPurchase = await CurrencyConversionService.convert(
      amount: asset.purchasePrice,
      fromCurrency: asset.currency,
      toCurrency: displayCurrency.code,
    );
    
    totalValue += convertedValue;
    totalPurchasePrice += convertedPurchase;
  }
  
  final totalProfitLoss = totalValue - totalPurchasePrice;
  
  return {
    'totalAssets': ownedAssets.length,
    'totalValue': totalValue,
    'totalProfitLoss': totalProfitLoss,
    'profitLossPercentage': totalPurchasePrice > 0 ? (totalProfitLoss / totalPurchasePrice) * 100 : 0.0,
  };
});

// Asset CRUD Controller
class AssetController extends StateNotifier<AsyncValue<void>> {
  final AssetRepository _repository;
  final Ref _ref;

  AssetController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addAsset(AssetModel asset) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addAsset(asset);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAssetWithPurchase({
    required AssetModel asset,
    required int sourceId,
    required tx.SourceType sourceType,
    required String sourceName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addAssetWithPurchase(
        asset: asset,
        sourceId: sourceId,
        sourceType: sourceType,
        sourceName: sourceName,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAssetWithoutPurchase({
    required AssetModel asset,
    required tx.IncomeCategory category,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addAssetWithoutPurchase(
        asset: asset,
        category: category,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAsset(AssetModel asset) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAsset(asset);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> revaluateAsset(int assetId, double newValue) async {
    state = const AsyncValue.loading();
    try {
      final asset = await _repository.getAssetById(assetId);
      if (asset != null) {
        asset.currentValue = newValue;
        asset.updatedAt = DateTime.now();
        await _repository.updateAsset(asset);
      }
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sellAsset(int assetId, double sellPrice) async {
    state = const AsyncValue.loading();
    try {
      final asset = await _repository.getAssetById(assetId);
      if (asset != null) {
        asset.status = AssetStatus.sold;
        asset.soldPrice = sellPrice;
        asset.soldDate = DateTime.now();
        asset.updatedAt = DateTime.now();
        await _repository.updateAsset(asset);
      }
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAsset(int id) async {
    state = const AsyncValue.loading();
    try {
      // Annuler les transactions liées à cet asset
      final transactionRepo = _ref.read(transactionRepositoryProvider);
      await transactionRepo.cancelTransactionsForEntity(
        entityId: id,
        entityType: tx.SourceType.asset,
      );
      
      await _repository.deleteAsset(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _invalidateAll() {
    _ref.invalidate(assetsStreamProvider);
    _ref.invalidate(totalAssetValueProvider);
    _ref.invalidate(assetStatsProvider);
    // Dashboard
    _ref.invalidate(dashboard.totalWealthProvider);
    _ref.invalidate(dashboard.thisMonthIncomeProvider);
    _ref.invalidate(dashboard.thisMonthExpenseProvider);
    // Sources (unified)
    _ref.invalidate(unifiedSourcesProvider);
    // Transactions
    _ref.invalidate(transactionsStreamProvider);
  }
}

final assetControllerProvider =
    StateNotifierProvider<AssetController, AsyncValue<void>>((ref) {
  final repository = ref.watch(assetRepositoryProvider);
  return AssetController(repository, ref);
});

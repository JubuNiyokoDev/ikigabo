import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/presentation/providers/isar_provider.dart';
import '../../data/services/transaction_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/bank_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/models/transaction_model.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final isar = ref.watch(isarProvider).value!;
  return TransactionService(
    transactionRepo: TransactionRepository(isar),
    bankRepo: BankRepository(isar),
    sourceRepo: SourceRepository(isar),
    assetRepo: AssetRepository(isar),
  );
});

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
      return TransactionController(ref.read(transactionServiceProvider));
    });

class TransactionController extends StateNotifier<AsyncValue<void>> {
  final TransactionService _transactionService;

  TransactionController(this._transactionService)
    : super(const AsyncValue.data(null));

  /// Créer une entrée d'argent externe
  Future<void> createIncome({
    required double amount,
    required String currency,
    required int destinationId,
    required SourceType destinationType,
    required IncomeCategory category,
    String? description,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionService.createIncomeTransaction(
        amount: amount,
        currency: currency,
        destinationId: destinationId,
        destinationType: destinationType,
        category: category,
        description: description,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Créer une sortie d'argent
  Future<void> createExpense({
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
    state = const AsyncValue.loading();
    try {
      await _transactionService.createExpenseTransaction(
        amount: amount,
        currency: currency,
        sourceId: sourceId,
        sourceType: sourceType,
        category: category,
        targetId: targetId,
        targetType: targetType,
        description: description,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Créer un transfert entre sources
  Future<void> createTransfer({
    required double amount,
    required String currency,
    required int sourceId,
    required SourceType sourceType,
    required int targetId,
    required SourceType targetType,
    String? description,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionService.createTransferTransaction(
        amount: amount,
        currency: currency,
        sourceId: sourceId,
        sourceType: sourceType,
        targetId: targetId,
        targetType: targetType,
        description: description,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Acheter un asset
  Future<void> buyAsset({
    required double amount,
    required String currency,
    required int sourceId,
    required SourceType sourceType,
    required int assetId,
    String? description,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionService.buyAsset(
        amount: amount,
        currency: currency,
        sourceId: sourceId,
        sourceType: sourceType,
        assetId: assetId,
        description: description,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Vendre un asset
  Future<void> sellAsset({
    required double amount,
    required String currency,
    required int assetId,
    required int targetId,
    required SourceType targetType,
    String? description,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionService.sellAsset(
        amount: amount,
        currency: currency,
        assetId: assetId,
        targetId: targetId,
        targetType: targetType,
        description: description,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

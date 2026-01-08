import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_model.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/repositories/bank_repository.dart';
import '../../data/services/bank_fees_service.dart';
import 'isar_provider.dart';
import 'transaction_provider.dart';
import 'currency_provider.dart';
import 'source_provider.dart';
import 'dashboard_provider.dart' as dashboard;
import '../../core/services/currency_conversion_service.dart';

// Repository Provider
final bankRepositoryProvider = Provider<BankRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar is not initialized');
  }
  return BankRepository(isar);
});

// Bank Fees Service Provider
final bankFeesServiceProvider = Provider<BankFeesService>((ref) {
  final bankRepo = ref.watch(bankRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return BankFeesService(bankRepo, transactionRepo);
});

// All Banks Stream
final banksStreamProvider = StreamProvider<List<BankModel>>((ref) {
  final repository = ref.watch(bankRepositoryProvider);
  return repository.watchBanks();
});

// Total balance across all banks - converted to display currency
final totalBankBalanceProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final banksAsync = ref.watch(banksStreamProvider);
  
  final banks = await banksAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<BankModel>[]),
    error: (_, __) => Future.value(<BankModel>[]),
  );

  double total = 0.0;
  for (final bank in banks) {
    if (bank.isActive) {
      final converted = await CurrencyConversionService.convert(
        amount: bank.balance,
        fromCurrency: bank.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }

  return total;
});

// Banks by type
final freeBanksProvider = FutureProvider<List<BankModel>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return await repository.getBanksByType(BankType.free);
});

final paidBanksProvider = FutureProvider<List<BankModel>>((ref) async {
  final repository = ref.watch(bankRepositoryProvider);
  return await repository.getBanksByType(BankType.paid);
});

// Banks with pending fees
final banksWithPendingFeesProvider = FutureProvider<List<BankModel>>((
  ref,
) async {
  final service = ref.watch(bankFeesServiceProvider);
  return await service.getBanksWithPendingFees();
});

// Total pending fees - converted to display currency
final totalPendingFeesProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final service = ref.watch(bankFeesServiceProvider);
  final banksWithFees = await service.getBanksWithPendingFees();

  double total = 0.0;
  for (final bank in banksWithFees) {
    final feeAmount = bank.calculateInterest();
    final converted = await CurrencyConversionService.convert(
      amount: feeAmount,
      fromCurrency: bank.currency,
      toCurrency: displayCurrency.code,
    );
    total += converted;
  }

  return total;
});

// Bank statistics - converted to display currency
final bankStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final banksAsync = ref.watch(banksStreamProvider);
  
  final allBanks = await banksAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<BankModel>[]),
    error: (_, __) => Future.value(<BankModel>[]),
  );
  
  final freeBanks = allBanks.where((b) => b.bankType == BankType.free).length;
  final paidBanks = allBanks.where((b) => b.bankType == BankType.paid).length;

  double totalBalance = 0.0;
  for (final bank in allBanks) {
    if (bank.isActive) {
      final converted = await CurrencyConversionService.convert(
        amount: bank.balance,
        fromCurrency: bank.currency,
        toCurrency: displayCurrency.code,
      );
      totalBalance += converted;
    }
  }

  return {
    'totalBanks': allBanks.length,
    'freeBanks': freeBanks,
    'paidBanks': paidBanks,
    'totalBalance': totalBalance,
    'averageBalance': allBanks.isEmpty ? 0.0 : totalBalance / allBanks.length,
  };
});

// Bank CRUD Controller
class BankController extends StateNotifier<AsyncValue<void>> {
  final BankRepository _repository;
  final Ref _ref;

  BankController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> addBank(BankModel bank) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBank(bank);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBank(BankModel bank) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBank(bank);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBank(int id) async {
    state = const AsyncValue.loading();
    try {
      // Annuler les transactions liées à cette banque
      final transactionRepo = _ref.read(transactionRepositoryProvider);
      await transactionRepo.cancelTransactionsForEntity(
        entityId: id,
        entityType: tx.SourceType.bank,
      );

      await _repository.deleteBank(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> processInterestDeductions() async {
    state = const AsyncValue.loading();
    try {
      await _repository.processInterestDeductions();
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _invalidateAll() {
    _ref.invalidate(banksStreamProvider);
    _ref.invalidate(totalBankBalanceProvider);
    _ref.invalidate(bankStatsProvider);
    _ref.invalidate(banksWithPendingFeesProvider);
    _ref.invalidate(totalPendingFeesProvider);
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

final bankControllerProvider =
    StateNotifierProvider<BankController, AsyncValue<void>>((ref) {
      final repository = ref.watch(bankRepositoryProvider);
      return BankController(repository, ref);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/source_model.dart';
import '../../data/models/bank_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/repositories/source_repository.dart';
import 'isar_provider.dart';
import 'search_provider.dart';
import 'bank_provider.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';
import 'currency_provider.dart';
import 'transaction_provider.dart' hide thisMonthIncomeProvider, thisMonthExpenseProvider;
import 'dashboard_provider.dart' as dashboard;
import '../../core/services/currency_conversion_service.dart';

// Repository Provider
final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar is not initialized');
  }
  return SourceRepository(isar);
});

// All Sources Stream
final sourcesStreamProvider = StreamProvider<List<SourceModel>>((ref) {
  final repository = ref.watch(sourceRepositoryProvider);
  return repository.watchSources();
});

// Original Sources + Banks (without conversion) for bank creation
final originalSourcesProvider = FutureProvider<List<SourceModel>>((ref) async {
  final sourcesAsync = ref.watch(sourcesStreamProvider);
  final banksAsync = ref.watch(banksStreamProvider);

  final sources = await sourcesAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<SourceModel>[]),
    error: (_, __) => Future.value(<SourceModel>[]),
  );

  final banks = await banksAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<BankModel>[]),
    error: (_, __) => Future.value(<BankModel>[]),
  );

  final List<SourceModel> allSources = [];

  // Add regular sources
  allSources.addAll(sources.where((s) => !s.isDeleted));

  // Add banks as sources
  for (final bank in banks) {
    if (!bank.isDeleted && bank.isActive) {
      final bankAsSource = SourceModel(
        name: bank.name,
        type: SourceType.custom,
        amount: bank.balance,
        currency: bank.currency, // Keep original currency
        isActive: bank.isActive,
        isPassive: false,
        createdAt: bank.createdAt,
        description: bank.description,
        iconName: 'bank',
        color: '#2196F3',
        isDeleted: false,
      );
      // Utiliser un ID unique pour éviter les conflits avec les vraies sources
      bankAsSource.id = -bank.id; // ID négatif pour les banques
      allSources.add(bankAsSource);
    }
  }

  return allSources;
});

// Unified Sources (includes banks, assets, debts) - with currency conversion
final unifiedSourcesProvider = FutureProvider<List<SourceModel>>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final sourcesAsync = ref.watch(sourcesStreamProvider);
  final banksAsync = ref.watch(banksStreamProvider);
  final assetsAsync = ref.watch(assetsStreamProvider);
  final debtsAsync = ref.watch(debtsStreamProvider);

  final sources = await sourcesAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<SourceModel>[]),
    error: (_, __) => Future.value(<SourceModel>[]),
  );

  final banks = await banksAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<BankModel>[]),
    error: (_, __) => Future.value(<BankModel>[]),
  );

  final assets = await assetsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<AssetModel>[]),
    error: (_, __) => Future.value(<AssetModel>[]),
  );

  final debts = await debtsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<DebtModel>[]),
    error: (_, __) => Future.value(<DebtModel>[]),
  );

  final List<SourceModel> allSources = [];

  // Add regular sources with conversion
  for (final source in sources.where((s) => !s.isDeleted)) {
    final convertedAmount = await CurrencyConversionService.convert(
      amount: source.amount,
      fromCurrency: source.currency,
      toCurrency: displayCurrency.code,
    );

    final convertedSource = SourceModel(
      name: source.name,
      type: source.type,
      amount: convertedAmount,
      currency: displayCurrency.code, // Use display currency
      isActive: source.isActive,
      isPassive: source.isPassive,
      createdAt: source.createdAt,
      description: source.description,
      iconName: source.iconName,
      color: source.color,
      isDeleted: source.isDeleted,
    );
    convertedSource.id = source.id; // Preserve original ID
    allSources.add(convertedSource);
  }

  // Add banks as sources with conversion
  for (final bank in banks) {
    if (!bank.isDeleted && bank.isActive) {
      final convertedAmount = await CurrencyConversionService.convert(
        amount: bank.balance,
        fromCurrency: bank.currency,
        toCurrency: displayCurrency.code,
      );

      final bankAsSource = SourceModel(
        name: bank.name,
        type: SourceType.custom,
        amount: convertedAmount,
        currency: displayCurrency.code,
        isActive: bank.isActive,
        isPassive: false,
        createdAt: bank.createdAt,
        description: bank.description,
        iconName: 'bank',
        color: '#2196F3',
        isDeleted: false,
      );
      bankAsSource.id = -bank.id;
      allSources.add(bankAsSource);
    }
  }

  // Add assets as sources with conversion
  for (final asset in assets) {
    if (!asset.isDeleted && asset.status == AssetStatus.owned) {
      final convertedAmount = await CurrencyConversionService.convert(
        amount: asset.totalValue,
        fromCurrency: asset.currency,
        toCurrency: displayCurrency.code,
      );

      final assetAsSource = SourceModel(
        name: asset.name,
        type: SourceType.custom, // Utiliser custom pour les assets
        amount: convertedAmount,
        currency: displayCurrency.code,
        isActive: true,
        isPassive: false,
        createdAt: asset.createdAt,
        description: asset.description,
        iconName: 'assets',
        color: '#FF9800',
        isDeleted: false,
      );
      // Utiliser un ID unique pour éviter les conflits
      assetAsSource.id = -(1000000 + asset.id); // ID négatif unique pour les assets
      allSources.add(assetAsSource);
    }
  }

  // Add debts as sources with conversion
  for (final debt in debts) {
    if (!debt.isDeleted && debt.status != DebtStatus.fullyPaid) {
      final convertedAmount = await CurrencyConversionService.convert(
        amount: debt.remainingAmount,
        fromCurrency: debt.currency,
        toCurrency: displayCurrency.code,
      );

      if (debt.type == DebtType.given) {
        // Debt given (money lent) - positive asset
        final debtAsSource = SourceModel(
          name: 'Dette: ${debt.personName}',
          type: SourceType.custom, // Utiliser custom pour les dettes
          amount: convertedAmount,
          currency: displayCurrency.code,
          isActive:
              debt.status == DebtStatus.pending ||
              debt.status == DebtStatus.partiallyPaid,
          isPassive: false,
          createdAt: debt.createdAt,
          description: debt.description,
          iconName: 'debt_given',
          color: '#4CAF50',
          isDeleted: false,
        );
        // Utiliser un ID unique pour éviter les conflits
        debtAsSource.id = -(2000000 + debt.id); // ID négatif unique pour les dettes données
        allSources.add(debtAsSource);
      } else {
        // Debt received (money borrowed) - negative liability
        final debtAsSource = SourceModel(
          name: 'Emprunt: ${debt.personName}',
          type: SourceType.custom, // Utiliser custom pour les dettes
          amount: -convertedAmount, // Negative for liability
          currency: displayCurrency.code,
          isActive:
              debt.status == DebtStatus.pending ||
              debt.status == DebtStatus.partiallyPaid,
          isPassive: true,
          createdAt: debt.createdAt,
          description: debt.description,
          iconName: 'debt_received',
          color: '#F44336',
          isDeleted: false,
        );
        // Utiliser un ID unique pour éviter les conflits
        debtAsSource.id = -(3000000 + debt.id); // ID négatif unique pour les dettes reçues
        allSources.add(debtAsSource);
      }
    }
  }

  // Sort by creation date (newest first)
  allSources.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allSources;
});

// Filtered Unified Sources (with search)
final filteredSourcesProvider = Provider<AsyncValue<List<SourceModel>>>((ref) {
  final sourcesAsync = ref.watch(unifiedSourcesProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return sourcesAsync.when(
    data: (sources) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(sources);
      }
      final query = searchQuery.toLowerCase();
      final filtered = sources.where((source) {
        return source.name.toLowerCase().contains(query) ||
            (source.description?.toLowerCase().contains(query) ?? false) ||
            source.currency.toLowerCase().contains(query) ||
            source.amount.toString().contains(query) ||
            _getTypeString(source.type).toLowerCase().contains(query) ||
            (source.isActive ? 'actif active' : 'inactif inactive').contains(
              query,
            );
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Helper function pour les types
String _getTypeString(SourceType type) {
  switch (type) {
    case SourceType.pocket:
      return 'poche pocket';
    case SourceType.safe:
      return 'coffre safe';
    case SourceType.cash:
      return 'argent liquide cash';
    case SourceType.custom:
      return 'personnalisé custom';
  }
}

// Total Balance (unified) - already converted in unifiedSourcesProvider
final totalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final sourcesAsync = ref.watch(unifiedSourcesProvider);

  return sourcesAsync.when(
    data: (sources) {
      final total = sources.fold<double>(
        0.0,
        (sum, source) => sum + source.amount,
      );
      return AsyncValue.data(total);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Active Sources Balance (unified) - already converted in unifiedSourcesProvider
final activeBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final sourcesAsync = ref.watch(unifiedSourcesProvider);

  return sourcesAsync.when(
    data: (sources) {
      final total = sources
          .where((s) => s.isActive)
          .fold<double>(0.0, (sum, source) => sum + source.amount);
      return AsyncValue.data(total);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Source CRUD Controller
class SourceController extends StateNotifier<AsyncValue<void>> {
  final SourceRepository _repository;
  final Ref _ref;

  SourceController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> addSource(SourceModel source) async {
    state = const AsyncValue.loading();
    try {
      // Pour une nouvelle source, s'assurer que l'ID est bien auto-généré
      final newSource = SourceModel(
        name: source.name,
        type: source.type,
        amount: source.amount,
        currency: source.currency,
        isActive: source.isActive,
        isPassive: source.isPassive,
        createdAt: source.createdAt,
        description: source.description,
        iconName: source.iconName,
        color: source.color,
        isDeleted: source.isDeleted,
      );
      await _repository.addSource(newSource);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSourceFromIncome({
    required SourceModel source,
    required tx.IncomeCategory category,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addSourceFromIncome(source: source, category: category);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSourceWithTransfer({
    required SourceModel source,
    required int fromSourceId,
    required tx.SourceType fromSourceType,
    required String fromSourceName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addSourceWithTransfer(
        source: source,
        fromSourceId: fromSourceId,
        fromSourceType: fromSourceType,
        fromSourceName: fromSourceName,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSource(SourceModel source) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSource(source);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSource(int id) async {
    state = const AsyncValue.loading();
    try {
      // Annuler les transactions liées à cette source
      final transactionRepo = _ref.read(transactionRepositoryProvider);
      await transactionRepo.cancelTransactionsForEntity(
        entityId: id,
        entityType: tx.SourceType.source,
      );
      
      await _repository.deleteSource(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _invalidateAll() {
    _ref.invalidate(sourcesStreamProvider);
    _ref.invalidate(totalBalanceProvider);
    _ref.invalidate(activeBalanceProvider);
    _ref.invalidate(unifiedSourcesProvider);
    // Dashboard
    _ref.invalidate(dashboard.totalWealthProvider);
    _ref.invalidate(dashboard.thisMonthIncomeProvider);
    _ref.invalidate(dashboard.thisMonthExpenseProvider);
    // Transactions
    _ref.invalidate(transactionsStreamProvider);
  }
}

final sourceControllerProvider =
    StateNotifierProvider<SourceController, AsyncValue<void>>((ref) {
      final repository = ref.watch(sourceRepositoryProvider);
      return SourceController(repository, ref);
    });

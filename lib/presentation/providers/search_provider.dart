import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/source_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/asset_model.dart';
import 'source_provider.dart';
import 'transaction_provider.dart';
import 'debt_provider.dart';
import 'asset_provider.dart';

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered sources based on search
final filteredSourcesProvider = Provider<AsyncValue<List<SourceModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final sourcesAsync = ref.watch(sourcesStreamProvider);
  
  return sourcesAsync.when(
    data: (sources) {
      if (query.isEmpty) return AsyncValue.data(sources);
      
      final filtered = sources.where((source) {
        return source.name.toLowerCase().contains(query.toLowerCase()) ||
               source.type.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Filtered transactions based on search
final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      if (query.isEmpty) return AsyncValue.data(transactions);
      
      final filtered = transactions.where((transaction) {
        return transaction.categoryName.toLowerCase().contains(query.toLowerCase()) ||
               (transaction.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Filtered debts based on search
final filteredDebtsProvider = Provider<AsyncValue<List<DebtModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final debtsAsync = ref.watch(debtsStreamProvider);
  
  return debtsAsync.when(
    data: (debts) {
      if (query.isEmpty) return AsyncValue.data(debts);
      
      final filtered = debts.where((debt) {
        return debt.personName.toLowerCase().contains(query.toLowerCase()) ||
               (debt.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Filtered assets based on search
final filteredAssetsProvider = Provider<AsyncValue<List<AssetModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final assetsAsync = ref.watch(assetsStreamProvider);
  
  return assetsAsync.when(
    data: (assets) {
      if (query.isEmpty) return AsyncValue.data(assets);
      
      final filtered = assets.where((asset) {
        return asset.name.toLowerCase().contains(query.toLowerCase()) ||
               asset.type.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
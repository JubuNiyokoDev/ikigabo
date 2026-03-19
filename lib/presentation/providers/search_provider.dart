import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/asset_model.dart';
import 'transaction_provider.dart';
import 'asset_provider.dart';

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered transactions based on search
final filteredTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
      final query = ref.watch(searchQueryProvider);
      final transactionsAsync = ref.watch(transactionsStreamProvider);

      return transactionsAsync.when(
        data: (transactions) {
          if (query.isEmpty) return AsyncValue.data(transactions);

          final filtered = transactions.where((transaction) {
            return transaction.categoryName.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (transaction.description?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false);
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

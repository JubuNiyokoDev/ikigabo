import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_provider.dart';
import 'transaction_provider.dart';
import '../../data/models/transaction_model.dart';

// Filter states
final dateFilterProvider = StateProvider<DateRange?>((ref) => null);
final typeFilterProvider = StateProvider<TransactionType?>((ref) => null);
final amountRangeProvider = StateProvider<AmountRange?>((ref) => null);

class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange(this.start, this.end);
}

class AmountRange {
  final double min;
  final double max;
  
  AmountRange(this.min, this.max);
}

// Filtered transactions with all filters applied
final filteredTransactionsWithFiltersProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final dateRange = ref.watch(dateFilterProvider);
  final typeFilter = ref.watch(typeFilterProvider);
  final amountRange = ref.watch(amountRangeProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      var filtered = transactions;
      
      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((t) {
          return t.categoryName.toLowerCase().contains(query.toLowerCase()) ||
                 (t.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
      
      // Apply date filter
      if (dateRange != null) {
        filtered = filtered.where((t) {
          return t.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                 t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }
      
      // Apply type filter
      if (typeFilter != null) {
        filtered = filtered.where((t) => t.type == typeFilter).toList();
      }
      
      // Apply amount range filter
      if (amountRange != null) {
        filtered = filtered.where((t) {
          return t.amount >= amountRange.min && t.amount <= amountRange.max;
        }).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Clear all filters
final clearFiltersProvider = Provider<void>((ref) {
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(dateFilterProvider.notifier).state = null;
  ref.read(typeFilterProvider.notifier).state = null;
  ref.read(amountRangeProvider.notifier).state = null;
});

// Check if any filters are active
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final query = ref.watch(searchQueryProvider);
  final dateRange = ref.watch(dateFilterProvider);
  final typeFilter = ref.watch(typeFilterProvider);
  final amountRange = ref.watch(amountRangeProvider);
  
  return query.isNotEmpty || 
         dateRange != null || 
         typeFilter != null || 
         amountRange != null;
});
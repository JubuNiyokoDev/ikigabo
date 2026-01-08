import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import 'transaction_provider.dart';

// Weekly providers
final thisWeekIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.income && 
        t.date.isAfter(weekStart) && 
        t.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
      total += t.amount;
    }
  }
  return total;
});

final thisWeekExpenseProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.expense && 
        t.date.isAfter(weekStart) && 
        t.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
      total += t.amount;
    }
  }
  return total;
});

// Yearly providers
final thisYearIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final now = DateTime.now();
  final yearStart = DateTime(now.year, 1, 1);
  final yearEnd = DateTime(now.year, 12, 31);
  
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.income && 
        t.date.isAfter(yearStart) && 
        t.date.isBefore(yearEnd.add(const Duration(days: 1)))) {
      total += t.amount;
    }
  }
  return total;
});

final thisYearExpenseProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final now = DateTime.now();
  final yearStart = DateTime(now.year, 1, 1);
  final yearEnd = DateTime(now.year, 12, 31);
  
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.expense && 
        t.date.isAfter(yearStart) && 
        t.date.isBefore(yearEnd.add(const Duration(days: 1)))) {
      total += t.amount;
    }
  }
  return total;
});

// Total providers
final totalIncomeProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      total += t.amount;
    }
  }
  return total;
});

final totalExpenseProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  double total = 0.0;
  for (final t in transactions) {
    if (t.type == TransactionType.expense) {
      total += t.amount;
    }
  }
  return total;
});

// Category statistics
final categoryStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final transactions = await ref.watch(transactionsStreamProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  
  final Map<String, double> categoryTotals = {};
  
  for (final transaction in transactions) {
    if (transaction.type == TransactionType.expense && 
        transaction.date.isAfter(monthStart) && 
        transaction.date.isBefore(monthEnd.add(const Duration(days: 1)))) {
      final category = transaction.categoryName;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + transaction.amount;
    }
  }
  
  return categoryTotals;
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/data/models/asset_model.dart';
import 'package:ikigabo/data/models/debt_model.dart';
import '../../data/models/transaction_model.dart' as tx;
import 'source_provider.dart';
import 'bank_provider.dart';
import 'asset_provider.dart';
import 'debt_provider.dart';
import 'transaction_provider.dart';
import 'currency_provider.dart';
import '../../core/services/currency_conversion_service.dart';

// Total wealth calculation based on transactions (Entrées - Sorties)
final totalWealthProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final repository = ref.watch(transactionRepositoryProvider);
  
  final allTransactions = await repository.getAllTransactions();
  
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  
  for (final transaction in allTransactions) {
    if (transaction.status == tx.TransactionStatus.active) {
      final converted = await CurrencyConversionService.convert(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: displayCurrency.code,
      );
      
      if (transaction.type == tx.TransactionType.income) {
        totalIncome += converted;
      } else if (transaction.type == tx.TransactionType.expense) {
        totalExpense += converted;
      }
    }
  }
  
  return totalIncome - totalExpense;
});

// Net balance (excluding assets which are not liquid)
final netLiquidBalanceProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);

  final sourcesTotal = await ref
      .watch(totalBalanceProvider)
      .when(
        data: (value) => Future.value(value),
        loading: () => Future.value(0.0),
        error: (_, __) => Future.value(0.0),
      );

  final banks = await ref.watch(banksStreamProvider.future);
  double banksTotal = 0.0;
  for (final bank in banks) {
    if (!bank.isDeleted && bank.isActive) {
      final converted = await CurrencyConversionService.convert(
        amount: bank.balance,
        fromCurrency: bank.currency,
        toCurrency: displayCurrency.code,
      );
      banksTotal += converted;
    }
  }

  final debts = await ref.watch(debtsStreamProvider.future);
  double debtsGiven = 0.0;
  double debtsReceived = 0.0;
  for (final debt in debts) {
    if (!debt.isDeleted && debt.status != DebtStatus.fullyPaid) {
      final converted = await CurrencyConversionService.convert(
        amount: debt.remainingAmount,
        fromCurrency: debt.currency,
        toCurrency: displayCurrency.code,
      );
      if (debt.type == DebtType.given) {
        debtsGiven += converted;
      } else {
        debtsReceived += converted;
      }
    }
  }

  return sourcesTotal + banksTotal + debtsGiven - debtsReceived;
});

// Assets vs Liabilities breakdown
final assetsVsLiabilitiesProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);

  final sourcesTotal = await ref
      .watch(totalBalanceProvider)
      .when(
        data: (value) => Future.value(value),
        loading: () => Future.value(0.0),
        error: (_, __) => Future.value(0.0),
      );

  final banks = await ref.watch(banksStreamProvider.future);
  double banksTotal = 0.0;
  for (final bank in banks) {
    if (!bank.isDeleted && bank.isActive) {
      final converted = await CurrencyConversionService.convert(
        amount: bank.balance,
        fromCurrency: bank.currency,
        toCurrency: displayCurrency.code,
      );
      banksTotal += converted;
    }
  }

  final assets = await ref.watch(assetsStreamProvider.future);
  double assetsTotal = 0.0;
  for (final asset in assets) {
    if (!asset.isDeleted && asset.status == AssetStatus.owned) {
      final converted = await CurrencyConversionService.convert(
        amount: asset.totalValue,
        fromCurrency: asset.currency,
        toCurrency: displayCurrency.code,
      );
      assetsTotal += converted;
    }
  }

  final debts = await ref.watch(debtsStreamProvider.future);
  double debtsGiven = 0.0;
  double debtsReceived = 0.0;
  for (final debt in debts) {
    if (!debt.isDeleted && debt.status != DebtStatus.fullyPaid) {
      final converted = await CurrencyConversionService.convert(
        amount: debt.remainingAmount,
        fromCurrency: debt.currency,
        toCurrency: displayCurrency.code,
      );
      if (debt.type == DebtType.given) {
        debtsGiven += converted;
      } else {
        debtsReceived += converted;
      }
    }
  }

  final totalAssets = sourcesTotal + banksTotal + assetsTotal + debtsGiven;
  final totalLiabilities = debtsReceived;

  return {'assets': totalAssets, 'liabilities': totalLiabilities};
});

// Weekly activity data for chart
final weeklyActivityProvider = FutureProvider<List<double>>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final weekData = <double>[];

  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final transactions = await repository.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
    );

    double income = 0.0;
    double expense = 0.0;

    for (final transaction in transactions) {
      if (transaction.status == tx.TransactionStatus.active) {
        final converted = await CurrencyConversionService.convert(
          amount: transaction.amount,
          fromCurrency: transaction.currency,
          toCurrency: displayCurrency.code,
        );

        if (transaction.type == tx.TransactionType.income) {
          income += converted;
        } else if (transaction.type == tx.TransactionType.expense) {
          expense += converted;
        }
      }
    }

    weekData.add(income - expense); // Net activity
  }

  return weekData;
});

// Monthly growth percentage
final monthlyGrowthProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();

  // This month
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final thisMonthTransactions = await repository.getTransactionsByDateRange(
    thisMonthStart,
    thisMonthEnd,
  );

  double thisMonthIncome = 0.0;
  double thisMonthExpense = 0.0;

  for (final transaction in thisMonthTransactions) {
    if (transaction.status == tx.TransactionStatus.active) {
      final converted = await CurrencyConversionService.convert(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: displayCurrency.code,
      );

      if (transaction.type == tx.TransactionType.income) {
        thisMonthIncome += converted;
      } else if (transaction.type == tx.TransactionType.expense) {
        thisMonthExpense += converted;
      }
    }
  }
  final thisMonthNet = thisMonthIncome - thisMonthExpense;

  // Last month
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
  final lastMonthTransactions = await repository.getTransactionsByDateRange(
    lastMonthStart,
    lastMonthEnd,
  );

  double lastMonthIncome = 0.0;
  double lastMonthExpense = 0.0;

  for (final transaction in lastMonthTransactions) {
    if (transaction.status == tx.TransactionStatus.active) {
      final converted = await CurrencyConversionService.convert(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: displayCurrency.code,
      );

      if (transaction.type == tx.TransactionType.income) {
        lastMonthIncome += converted;
      } else if (transaction.type == tx.TransactionType.expense) {
        lastMonthExpense += converted;
      }
    }
  }
  final lastMonthNet = lastMonthIncome - lastMonthExpense;

  if (lastMonthNet == 0) return 0.0;
  return ((thisMonthNet - lastMonthNet) / lastMonthNet.abs()) * 100;
});

// This month income with currency conversion
final thisMonthIncomeProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final transactions = await repository.getTransactionsByDateRange(
    thisMonthStart,
    thisMonthEnd,
  );

  double total = 0.0;
  for (final transaction in transactions) {
    if (transaction.type == tx.TransactionType.income &&
        transaction.status == tx.TransactionStatus.active) {
      final converted = await CurrencyConversionService.convert(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }
  return total;
});

// This month expense with currency conversion
final thisMonthExpenseProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final repository = ref.watch(transactionRepositoryProvider);
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final transactions = await repository.getTransactionsByDateRange(
    thisMonthStart,
    thisMonthEnd,
  );

  double total = 0.0;
  for (final transaction in transactions) {
    if (transaction.type == tx.TransactionType.expense &&
        transaction.status == tx.TransactionStatus.active) {
      final converted = await CurrencyConversionService.convert(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }
  return total;
});

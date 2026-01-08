import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/repositories/debt_repository.dart';
import '../../data/services/notification_service.dart';
import 'isar_provider.dart';
import 'currency_provider.dart';
import 'search_provider.dart';
import 'source_provider.dart';
import 'bank_provider.dart';
import 'transaction_provider.dart';
import 'dashboard_provider.dart' as dashboard;
import '../../core/services/currency_conversion_service.dart';

// Repository Provider
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar is not initialized');
  }
  return DebtRepository(isar);
});

// All Debts Stream
final debtsStreamProvider = StreamProvider<List<DebtModel>>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return repository.watchDebts();
});

// Active debts
final activeDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getActiveDebts();
});

// Given debts (money lent)
final givenDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getGivenDebts();
});

// Received debts (money borrowed)
final receivedDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  return await repository.getReceivedDebts();
});

// Total given (money lent out) - converted to display currency
final totalGivenProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final debtsAsync = ref.watch(debtsStreamProvider);
  
  final debts = await debtsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<DebtModel>[]),
    error: (_, __) => Future.value(<DebtModel>[]),
  );
  
  double total = 0.0;
  for (final debt in debts) {
    if (debt.type == DebtType.given && debt.status != DebtStatus.fullyPaid) {
      final converted = await CurrencyConversionService.convert(
        amount: debt.remainingAmount,
        fromCurrency: debt.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }
  
  return total;
});

// Total received (money borrowed) - converted to display currency
final totalReceivedProvider = FutureProvider<double>((ref) async {
  final displayCurrency = await ref.watch(displayCurrencyProvider.future);
  final debtsAsync = ref.watch(debtsStreamProvider);
  
  final debts = await debtsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<DebtModel>[]),
    error: (_, __) => Future.value(<DebtModel>[]),
  );
  
  double total = 0.0;
  for (final debt in debts) {
    if (debt.type == DebtType.received && debt.status != DebtStatus.fullyPaid) {
      final converted = await CurrencyConversionService.convert(
        amount: debt.remainingAmount,
        fromCurrency: debt.currency,
        toCurrency: displayCurrency.code,
      );
      total += converted;
    }
  }
  
  return total;
});

// Overdue debts
final overdueDebtsProvider = FutureProvider<List<DebtModel>>((ref) async {
  final debtsAsync = ref.watch(debtsStreamProvider);
  
  final debts = await debtsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<DebtModel>[]),
    error: (_, __) => Future.value(<DebtModel>[]),
  );
  
  final now = DateTime.now();
  return debts.where((debt) {
    if (debt.dueDate == null || debt.status == DebtStatus.fullyPaid) return false;
    return debt.dueDate!.isBefore(now);
  }).toList();
});

// Debts due soon (within 7 days)
final debtsDueSoonProvider = FutureProvider<List<DebtModel>>((ref) async {
  final debtsAsync = ref.watch(debtsStreamProvider);
  
  final debts = await debtsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<DebtModel>[]),
    error: (_, __) => Future.value(<DebtModel>[]),
  );
  
  final now = DateTime.now();
  final sevenDaysFromNow = now.add(const Duration(days: 7));
  
  return debts.where((debt) {
    if (debt.dueDate == null || debt.status == DebtStatus.fullyPaid) return false;
    return debt.dueDate!.isAfter(now) && debt.dueDate!.isBefore(sevenDaysFromNow);
  }).toList();
});

// Filtered debts (with search)
final filteredDebtsProvider = Provider<AsyncValue<List<DebtModel>>>((ref) {
  final debtsAsync = ref.watch(debtsStreamProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return debtsAsync.when(
    data: (debts) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(debts);
      }
      final query = searchQuery.toLowerCase();
      final filtered = debts.where((debt) {
        return debt.personName.toLowerCase().contains(query) ||
            (debt.description?.toLowerCase().contains(query) ?? false) ||
            debt.currency.toLowerCase().contains(query) ||
            debt.totalAmount.toString().contains(query) ||
            (debt.type == DebtType.given ? 'prêté lent given' : 'emprunté borrowed received').contains(query);
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Debt statistics - converted to display currency
final debtStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final totalGiven = await ref.watch(totalGivenProvider.future);
  final totalReceived = await ref.watch(totalReceivedProvider.future);
  final overdueDebts = await ref.watch(overdueDebtsProvider.future);
  final dueSoonDebts = await ref.watch(debtsDueSoonProvider.future);
  
  return {
    'totalGiven': totalGiven,
    'totalReceived': totalReceived,
    'netDebt': totalReceived - totalGiven, // Positive = we owe more, Negative = others owe us more
    'overdueCount': overdueDebts.length,
    'dueSoonCount': dueSoonDebts.length,
  };
});

// Debt CRUD Controller
class DebtController extends StateNotifier<AsyncValue<void>> {
  final DebtRepository _repository;
  final NotificationService _notificationService = NotificationService();
  final Ref _ref;

  DebtController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addDebtGiven({
    required DebtModel debt,
    required int sourceId,
    required String sourceName,
    required tx.SourceType sourceType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addDebtGiven(
        debt: debt,
        sourceId: sourceId,
        sourceType: sourceType,
        sourceName: sourceName,
      );
      
      // Programmer la notification si activée
      if (debt.hasReminder && debt.reminderDateTime != null) {
        await _notificationService.scheduleDebtReminder(debt);
      }
      
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDebtReceived({
    required DebtModel debt,
    required int targetId,
    required String targetName,
    required tx.SourceType targetType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addDebtReceived(
        debt: debt,
        targetId: targetId,
        targetType: targetType,
        targetName: targetName,
      );
      
      // Programmer la notification si activée
      if (debt.hasReminder && debt.reminderDateTime != null) {
        await _notificationService.scheduleDebtReminder(debt);
      }
      
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateDebt(DebtModel debt) async {
    state = const AsyncValue.loading();
    try {
      // Annuler l'ancienne notification
      await _notificationService.cancelDebtNotification(debt.id);
      
      await _repository.updateDebt(debt);
      
      // Programmer la nouvelle notification si activée
      if (debt.hasReminder && debt.reminderDateTime != null) {
        await _notificationService.scheduleDebtReminder(debt);
      }
      
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDebt(int id) async {
    state = const AsyncValue.loading();
    try {
      // Annuler la notification
      await _notificationService.cancelDebtNotification(id);
      
      // Annuler les transactions liées à cette dette
      final transactionRepo = _ref.read(transactionRepositoryProvider);
      await transactionRepo.cancelTransactionsForEntity(
        entityId: id,
        entityType: tx.SourceType.debt,
      );
      
      await _repository.deleteDebt(id);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPayment(DebtModel debt, double amount) async {
    state = const AsyncValue.loading();
    try {
      debt.addPayment(amount);
      await _repository.updateDebt(debt);
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPaymentWithSource({
    required DebtModel debt,
    required double amount,
    required int sourceId,
    required String sourceName,
    required tx.SourceType sourceType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addPaymentWithSource(
        debt: debt,
        amount: amount,
        sourceId: sourceId,
        sourceName: sourceName,
        sourceType: sourceType,
      );
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rescheduleAllReminders() async {
    try {
      final debts = await _repository.getAllDebts();
      for (final debt in debts) {
        if (debt.hasReminder && 
            debt.reminderDateTime != null && 
            debt.reminderDateTime!.isAfter(DateTime.now()) &&
            debt.status != DebtStatus.fullyPaid) {
          await _notificationService.scheduleDebtReminder(debt);
        }
      }
      print('✅ ${debts.where((d) => d.hasReminder).length} alarmes reprogrammées');
    } catch (e) {
      print('❌ Erreur reprogrammation: $e');
    }
  }

  void _invalidateAll() {
    _ref.invalidate(debtsStreamProvider);
    _ref.invalidate(totalGivenProvider);
    _ref.invalidate(totalReceivedProvider);
    _ref.invalidate(overdueDebtsProvider);
    _ref.invalidate(debtsDueSoonProvider);
    _ref.invalidate(debtStatsProvider);
    // Sources et Banks
    _ref.invalidate(sourcesStreamProvider);
    _ref.invalidate(banksStreamProvider);
    _ref.invalidate(unifiedSourcesProvider);
    _ref.invalidate(totalBalanceProvider);
    // Dashboard
    _ref.invalidate(dashboard.totalWealthProvider);
    _ref.invalidate(dashboard.thisMonthIncomeProvider);
    _ref.invalidate(dashboard.thisMonthExpenseProvider);
    // Transactions
    _ref.invalidate(transactionsStreamProvider);
  }
}

final debtControllerProvider =
    StateNotifierProvider<DebtController, AsyncValue<void>>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return DebtController(repository, ref);
});

// Provider pour initialiser les alarmes au démarrage
final debtAlarmsInitProvider = FutureProvider<void>((ref) async {
  final controller = ref.read(debtControllerProvider.notifier);
  await controller.rescheduleAllReminders();
});

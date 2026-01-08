import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/backup_service.dart';
import 'source_provider.dart';
import 'transaction_provider.dart' as tx;
import 'debt_provider.dart';
import 'asset_provider.dart';
import 'bank_provider.dart';
import 'dashboard_provider.dart' as dashboard;

// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    sourceRepository: ref.watch(sourceRepositoryProvider),
    transactionRepository: ref.watch(tx.transactionRepositoryProvider),
    debtRepository: ref.watch(debtRepositoryProvider),
    assetRepository: ref.watch(assetRepositoryProvider),
    bankRepository: ref.watch(bankRepositoryProvider),
  );
});

// Backup controller
class BackupController extends StateNotifier<AsyncValue<void>> {
  final BackupService _backupService;
  final Ref _ref;

  BackupController(this._backupService, this._ref) : super(const AsyncValue.data(null));

  Future<String> exportData({String? password}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _backupService.exportData(password: password);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<ImportResult> importData(String data, {String? password}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _backupService.importData(data, password: password);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> applyImport(Map<String, dynamic> data, {bool overwriteConflicts = false}) async {
    state = const AsyncValue.loading();
    try {
      await _backupService.applyImport(data, overwriteConflicts: overwriteConflicts);
      
      // Invalider tous les providers pour refresh automatique
      _ref.invalidate(sourcesStreamProvider);
      _ref.invalidate(banksStreamProvider);
      _ref.invalidate(assetsStreamProvider);
      _ref.invalidate(debtsStreamProvider);
      _ref.invalidate(tx.transactionsStreamProvider);
      _ref.invalidate(unifiedSourcesProvider);
      _ref.invalidate(originalUnifiedSourcesProvider);
      _ref.invalidate(dashboard.totalWealthProvider);
      _ref.invalidate(tx.totalIncomeProvider);
      _ref.invalidate(tx.totalExpenseProvider);
      _ref.invalidate(dashboard.weeklyActivityProvider);
      _ref.invalidate(dashboard.thisMonthIncomeProvider);
      _ref.invalidate(dashboard.thisMonthExpenseProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> saveBackupToStorage(String backupData) async {
    try {
      return await _backupService.saveBackupToStorage(backupData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final backupControllerProvider = StateNotifierProvider<BackupController, AsyncValue<void>>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupController(backupService, ref);
});
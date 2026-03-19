import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/data/models/bank_model.dart';
import 'package:ikigabo/data/models/budget_model.dart';
import 'package:ikigabo/data/models/source_model.dart';
import '../../data/services/notification_service.dart';
import 'auto_backup_provider.dart';
import 'budget_provider.dart';
import 'source_provider.dart';
import 'bank_provider.dart';
import 'debt_provider.dart';
import 'dashboard_provider.dart';

final integratedNotificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationWatcherProvider = Provider<NotificationWatcher>((ref) {
  final watcher = NotificationWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});

class NotificationWatcher {
  final Ref _ref;
  Timer? _periodicTimer;
  List<SourceModel> _lastSources = const [];
  List<BankModel> _lastBanks = const [];

  NotificationWatcher(this._ref) {
    _setupWatchers();
  }

  void _setupWatchers() {
    // Watch debt changes for overdue and upcoming alerts
    _ref.listen(debtsStreamProvider, (previous, next) {
      next.whenData((debts) async {
        final notificationService = _ref.read(integratedNotificationProvider);
        await notificationService.checkOverdueDebts(debts);
        await notificationService.checkUpcomingDebts(debts);
      });
    });

    // Watch budget changes for alerts
    _ref.listen(budgetsStreamProvider, (previous, next) {
      next.whenData((budgets) async {
        final notificationService = _ref.read(integratedNotificationProvider);
        for (final budget in budgets) {
          if (budget.status == BudgetStatus.active) {
            await notificationService.scheduleBudgetAlert(budget);
          }
        }
      });
    });

    // Watch wealth changes for milestones
    _ref.listen(totalWealthProvider, (previous, next) {
      next.whenData((wealth) async {
        final notificationService = _ref.read(integratedNotificationProvider);
        await notificationService.celebrateWealthMilestone(wealth, 'BIF');
      });
    });

    // Watch bank changes for fee alerts
    _ref.listen(banksStreamProvider, (previous, next) {
      next.whenData((banks) async {
        _lastBanks = banks;
        final notificationService = _ref.read(integratedNotificationProvider);
        for (final bank in banks) {
          await notificationService.scheduleBankFeeAlert(bank);
        }
        await notificationService.checkLowBalanceAlerts(
          _lastSources,
          _lastBanks,
        );
      });
    });

    // Watch source changes for low balance alerts
    _ref.listen(sourcesStreamProvider, (previous, next) {
      next.whenData((sources) async {
        _lastSources = sources;
        final notificationService = _ref.read(integratedNotificationProvider);
        await notificationService.checkLowBalanceAlerts(
          _lastSources,
          _lastBanks,
        );
      });
    });

    // Watch backup state for reminder logic
    _ref.listen(autoBackupProvider, (previous, next) async {
      if (previous == null ||
          previous.lastBackupDate != next.lastBackupDate ||
          previous.isEnabled != next.isEnabled) {
        final notificationService = _ref.read(integratedNotificationProvider);
        await notificationService.showBackupReminder();
      }
    });

    _runChecksFromCurrentState();
    _startPeriodicChecks();
  }

  void _startPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _runChecksFromCurrentState();
    });
  }

  Future<void> _runChecksFromCurrentState() async {
    final notificationService = _ref.read(integratedNotificationProvider);

    final debts = _ref.read(debtsStreamProvider).valueOrNull;
    if (debts != null) {
      await notificationService.checkOverdueDebts(debts);
      await notificationService.checkUpcomingDebts(debts);
    }

    final budgets = _ref.read(budgetsStreamProvider).valueOrNull;
    if (budgets != null) {
      for (final budget in budgets) {
        if (budget.status == BudgetStatus.active) {
          await notificationService.scheduleBudgetAlert(budget);
        }
      }
    }

    final wealth = _ref.read(totalWealthProvider).valueOrNull;
    if (wealth != null) {
      await notificationService.celebrateWealthMilestone(wealth, 'BIF');
    }

    final banks = _ref.read(banksStreamProvider).valueOrNull;
    if (banks != null) {
      _lastBanks = banks;
      for (final bank in banks) {
        await notificationService.scheduleBankFeeAlert(bank);
      }
    }

    final sources = _ref.read(sourcesStreamProvider).valueOrNull;
    if (sources != null) {
      _lastSources = sources;
    }

    await notificationService.checkLowBalanceAlerts(_lastSources, _lastBanks);
    await notificationService.showBackupReminder();
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}

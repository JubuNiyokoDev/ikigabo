import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/data/models/budget_model.dart';
import '../../data/services/notification_service.dart';
import 'budget_provider.dart';
import 'source_provider.dart';
import 'bank_provider.dart';
import 'debt_provider.dart';
import 'dashboard_provider.dart';

final integratedNotificationProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationWatcherProvider = Provider<NotificationWatcher>((ref) {
  return NotificationWatcher(ref);
});

class NotificationWatcher {
  final Ref _ref;

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
        if (previous?.hasValue == true) {
          final previousWealth = previous!.value!;
          if (wealth > previousWealth) {
            final notificationService = _ref.read(
              integratedNotificationProvider,
            );
            await notificationService.celebrateWealthMilestone(wealth, 'BIF');
          }
        }
      });
    });

    // Watch bank changes for fee alerts
    _ref.listen(banksStreamProvider, (previous, next) {
      next.whenData((banks) async {
        final notificationService = _ref.read(integratedNotificationProvider);
        for (final bank in banks) {
          await notificationService.scheduleBankFeeAlert(bank);
        }
      });
    });

    // Periodic checks
    _schedulePeriodicChecks();
  }

  void _schedulePeriodicChecks() {
    Future.delayed(const Duration(seconds: 10), () async {
      final sourcesAsync = _ref.read(sourcesStreamProvider);
      final banksAsync = _ref.read(banksStreamProvider);
      final debtsAsync = _ref.read(debtsStreamProvider);
      final notificationService = _ref.read(integratedNotificationProvider);

      // Check low balances
      sourcesAsync.whenData((sources) async {
        banksAsync.whenData((banks) async {
          await notificationService.checkLowBalanceAlerts(sources, banks);
        });
      });

      // Check debts again
      debtsAsync.whenData((debts) async {
        await notificationService.checkOverdueDebts(debts);
        await notificationService.checkUpcomingDebts(debts);
      });

      // Schedule next check
      _schedulePeriodicChecks();
    });
  }
}

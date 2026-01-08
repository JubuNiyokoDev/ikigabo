import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/data/models/budget_model.dart';
import '../../data/services/notification_service.dart';
import 'budget_provider.dart';
import 'source_provider.dart';
import 'bank_provider.dart';
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
            await notificationService.celebrateWealthMilestone(wealth, 'FBU');
          }
        }
      });
    });

    // Periodic low balance check
    _schedulePeriodicBalanceCheck();
  }

  void _schedulePeriodicBalanceCheck() {
    Future.delayed(const Duration(seconds: 10), () async {
      final sourcesAsync = _ref.read(sourcesStreamProvider);
      final banksAsync = _ref.read(banksStreamProvider);
      final notificationService = _ref.read(integratedNotificationProvider);

      sourcesAsync.whenData((sources) async {
        banksAsync.whenData((banks) async {
          await notificationService.checkLowBalanceAlerts(sources, banks);
        });
      });
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import 'debt_provider.dart';
import 'bank_provider.dart';
import 'source_provider.dart';
import 'dashboard_provider.dart';

final notificationManagerProvider = Provider<NotificationManager>((ref) {
  return NotificationManager(ref);
});

class NotificationManager {
  final Ref _ref;
  
  NotificationManager(this._ref);

  Future<void> updateAllNotifications() async {
    final notificationService = NotificationService();
    
    // Vérifier les dettes
    final debtsAsync = _ref.read(debtsStreamProvider);
    debtsAsync.whenData((debts) async {
      await notificationService.checkOverdueDebts(debts);
      await notificationService.checkUpcomingDebts(debts);
    });

    // Vérifier les soldes faibles
    final sourcesAsync = _ref.read(sourcesStreamProvider);
    final banksAsync = _ref.read(banksStreamProvider);
    
    sourcesAsync.whenData((sources) async {
      banksAsync.whenData((banks) async {
        await notificationService.checkLowBalanceAlerts(sources, banks);
      });
    });

    // Vérifier les frais bancaires
    banksAsync.whenData((banks) async {
      for (final bank in banks) {
        await notificationService.scheduleBankFeeAlert(bank);
      }
    });

    // Vérifier les paliers de patrimoine
    final wealthAsync = _ref.read(totalWealthProvider);
    wealthAsync.whenData((wealth) async {
      await notificationService.celebrateWealthMilestone(wealth, 'BIF');
    });
  }
}

final notificationUpdateProvider = FutureProvider<void>((ref) async {
  final manager = ref.read(notificationManagerProvider);
  await manager.updateAllNotifications();
});
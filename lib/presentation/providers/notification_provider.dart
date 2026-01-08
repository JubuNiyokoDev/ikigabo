import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ikigabo/core/services/preferences_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/bank_model.dart';
import 'debt_provider.dart';
import 'bank_provider.dart';
import 'preferences_provider.dart';

// Notification settings state
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((
      ref,
    ) {
      final prefsService = ref.watch(preferencesServiceProvider).value;
      return NotificationSettingsNotifier(prefsService);
    });

class NotificationSettings {
  final bool debtReminders;
  final bool bankFeeReminders;
  final bool wealthMilestones;
  final bool backupReminders;
  final bool overdueAlerts;

  const NotificationSettings({
    this.debtReminders = true,
    this.bankFeeReminders = true,
    this.wealthMilestones = true,
    this.backupReminders = true,
    this.overdueAlerts = true,
  });

  NotificationSettings copyWith({
    bool? debtReminders,
    bool? bankFeeReminders,
    bool? wealthMilestones,
    bool? backupReminders,
    bool? overdueAlerts,
  }) {
    return NotificationSettings(
      debtReminders: debtReminders ?? this.debtReminders,
      bankFeeReminders: bankFeeReminders ?? this.bankFeeReminders,
      wealthMilestones: wealthMilestones ?? this.wealthMilestones,
      backupReminders: backupReminders ?? this.backupReminders,
      overdueAlerts: overdueAlerts ?? this.overdueAlerts,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final PreferencesService? _prefsService;

  NotificationSettingsNotifier(this._prefsService)
    : super(const NotificationSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefsService != null) {
      state = NotificationSettings(
        debtReminders: _prefsService.getDebtRemindersEnabled(),
        bankFeeReminders: _prefsService.getBankFeesEnabled(),
        wealthMilestones: _prefsService.getWealthMilestonesEnabled(),
        backupReminders: _prefsService.getBackupRemindersEnabled(),
        overdueAlerts: _prefsService.getOverdueAlertsEnabled(),
      );
    }
  }

  void toggleDebtReminders() {
    final newValue = !state.debtReminders;
    state = state.copyWith(debtReminders: newValue);
    _prefsService?.setDebtRemindersEnabled(newValue);
  }

  void toggleBankFeeReminders() {
    final newValue = !state.bankFeeReminders;
    state = state.copyWith(bankFeeReminders: newValue);
    _prefsService?.setBankFeesEnabled(newValue);
  }

  void toggleWealthMilestones() {
    final newValue = !state.wealthMilestones;
    state = state.copyWith(wealthMilestones: newValue);
    _prefsService?.setWealthMilestonesEnabled(newValue);
  }

  void toggleBackupReminders() {
    final newValue = !state.backupReminders;
    state = state.copyWith(backupReminders: newValue);
    _prefsService?.setBackupRemindersEnabled(newValue);
  }

  void toggleOverdueAlerts() {
    final newValue = !state.overdueAlerts;
    state = state.copyWith(overdueAlerts: newValue);
    _prefsService?.setOverdueAlertsEnabled(newValue);
  }
}

// Notification controller
class NotificationController extends StateNotifier<AsyncValue<void>> {
  NotificationController() : super(const AsyncValue.data(null));

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      await NotificationService().initialize();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> scheduleDebtReminder(DebtModel debt, bool enabled) async {
    if (!enabled) return;

    try {
      await NotificationService().scheduleDebtReminder(debt);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> scheduleBankFeeAlert(BankModel bank, bool enabled) async {
    if (!enabled) return;

    try {
      await NotificationService().scheduleBankFeeAlert(bank);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> showWealthMilestone(
    double amount,
    String currency,
    bool enabled,
  ) async {
    if (!enabled) return;

    try {
      await NotificationService().showWealthMilestone(amount, currency);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> showBackupReminder(bool enabled) async {
    if (!enabled) return;

    try {
      await NotificationService().showBackupReminder();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> checkOverdueDebts(bool enabled) async {
    if (!enabled) return;

    // This will be called periodically to check for overdue debts
    // Implementation depends on how you want to trigger this check
  }

  Future<void> removeNotification(String id) async {
    try {
      NotificationService().removeNotification(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      NotificationService().clearAllNotifications();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
      return NotificationController();
    });

// Auto-schedule notifications when debts or banks are added/updated
final debtNotificationWatcherProvider = Provider<void>((ref) {
  final debts = ref.watch(debtsStreamProvider);
  final settings = ref.watch(notificationSettingsProvider);
  final controller = ref.read(notificationControllerProvider.notifier);

  debts.whenData((debtList) {
    for (final debt in debtList) {
      if (debt.dueDate != null && debt.status != DebtStatus.fullyPaid) {
        controller.scheduleDebtReminder(debt, settings.debtReminders);
      }
    }
  });
});

final bankNotificationWatcherProvider = Provider<void>((ref) {
  final banks = ref.watch(banksStreamProvider);
  final settings = ref.watch(notificationSettingsProvider);
  final controller = ref.read(notificationControllerProvider.notifier);

  banks.whenData((bankList) {
    for (final bank in bankList) {
      if (bank.bankType == BankType.paid) {
        controller.scheduleBankFeeAlert(bank, settings.bankFeeReminders);
      }
    }
  });
});

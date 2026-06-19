import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/debt_model.dart';
import '../models/bank_model.dart';
import '../models/budget_model.dart';
import '../models/source_model.dart';
import '../models/transaction_model.dart';
import '../../core/services/real_alarm_service.dart';
import '../../core/services/preferences_service.dart';

// Callback globale pour les alarmes (DOIT être en dehors de la classe)
@pragma('vm:entry-point')
void alarmCallback() {
  print('🔔🔔🔔 ALARME DÉCLENCHÉE! 🔔🔔🔔');
  // L'alarme sera gérée directement par le système
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _dueSoonDays = 3;
  static const int _backupReminderAfterDays = 3;
  static const int _smartReminderLookbackDays = 60;
  static const int _smartReminderMinEvents = 4;
  static const int _legacySmartGlobalInactivityAlarmId = 860001;
  static const int _smartInactivityAlarmBaseId = 860100;
  static const List<int> _smartInactivityReminderOffsetsDays = [3, 5, 8, 14];
  static const Duration _backupReminderCooldown = Duration(hours: 24);

  static const String _wealthLastMilestoneKey =
      'notification_state_wealth_last_milestone';
  static const String _backupLastReminderAtKey =
      'notification_state_backup_last_reminder_at';
  static const String _smartHabitAlarmIdsKey =
      'notification_state_smart_habit_alarm_ids';
  static const String _smartHabitSignatureKey =
      'notification_state_smart_habit_signature';
  static const String _smartInactivitySignatureKey =
      'notification_state_smart_inactivity_signature';

  final List<NotificationItem> _notifications = [];
  final ValueNotifier<int> _notificationCount = ValueNotifier(0);
  final FlutterLocalNotificationsPlugin _flutterNotifications =
      FlutterLocalNotificationsPlugin();
  PreferencesService? _prefsService;
  bool _notificationsLoaded = false;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  ValueNotifier<int> get notificationCount => _notificationCount;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize() async {
    if (_isInitialized) return;
    final pending = _initializationFuture;
    if (pending != null) return pending;

    final future = _initialize();
    _initializationFuture = future;
    try {
      await future;
    } finally {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _initialize() async {
    tz.initializeTimeZones();

    // Initialiser PreferencesService
    _prefsService = await PreferencesService.init();

    // Configuration Android - utiliser l'icône du launcher
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('🔔 Notification cliquée: ${response.payload}');
      },
    );

    // Créer le canal de notification AVANT de l'utiliser
    await _createNotificationChannel();
    await _requestPermissions();

    // Charger les notifications sauvegardées
    await _loadNotifications();

    _updateNotificationCount();

    // Configurer le port pour recevoir les alarmes
    _setupAlarmPort();
    _isInitialized = true;
  }

  void _setupAlarmPort() {
    // Configuration simplifiée sans IsolateNameServer
    print('📢 Configuration des alarmes initialisée');
  }

  Future<void> _createNotificationChannel() async {
    // Canal pour les vraies alarmes (avec son fort et insistant)
    const androidChannel = AndroidNotificationChannel(
      'debt_reminders',
      'Rappels de Dettes',
      description: 'Alarmes sonores pour les échéances de dettes et rappels',
      importance: Importance.max, // MAX pour le son le plus fort
      enableVibration: true,
      playSound: true,
      showBadge: true,
      // Utilise le son d'alarme par défaut du système Android
      sound: UriAndroidNotificationSound(
        'content://settings/system/alarm_alert',
      ),
    );

    await _flutterNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    print('✅ Canal de notification ALARME créé: debt_reminders');
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _flutterNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('🔔 Permission notifications: $granted');

      final exactAlarmGranted = await androidPlugin
          .requestExactAlarmsPermission();
      print('⏰ Permission alarmes exactes: $exactAlarmGranted');
    }
  }

  Future<String> scheduleDebtReminder(DebtModel debt) async {
    if (debt.reminderDateTime == null) {
      return 'Aucune alarme à programmer';
    }

    if (_prefsService?.getDebtRemindersEnabled() != true) {
      return 'Rappels de dettes désactivés dans les paramètres';
    }

    if (debt.reminderDateTime!.isBefore(DateTime.now())) {
      return 'Impossible de programmer une alarme dans le passé';
    }

    final title = debt.type == DebtType.given
        ? 'Dette à recevoir'
        : 'Dette à payer';

    final message = debt.type == DebtType.given
        ? 'Recevoir ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} de ${debt.personName}'
        : 'Payer ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} à ${debt.personName}';

    try {
      final result = await RealAlarmService.scheduleRealAlarm(
        id: debt.id,
        dateTime: debt.reminderDateTime!,
        title: title,
        message: message,
      );

      if (result.success) {
        _addNotification(
          NotificationItem(
            id: 'debt_${debt.id}_reminder',
            title: 'Rappel programmé',
            body: message,
            type: NotificationType.debtReminder,
            relatedId: debt.id,
            scheduledDate: debt.reminderDateTime!,
          ),
        );
        return 'Alarme programmée avec succès';
      } else {
        return result.error ?? 'Échec programmation alarme';
      }
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<void> scheduleBudgetAlert(BudgetModel budget) async {
    if (!budget.notificationsEnabled) return;
    // Vérifier si les notifications budget sont généralement activées
    if (_prefsService?.getOverdueAlertsEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final periodKey = _budgetPeriodKey(budget);
    final progressKey =
        'notification_state_budget_progress_${budget.id}_$periodKey';
    final previousProgress = prefs.getDouble(progressKey);
    final warningThreshold = budget.warningThreshold ?? 80.0;
    final currentProgress = budget.progressPercentage;

    // Baseline initial pour éviter un spam au premier lancement.
    if (previousProgress == null) {
      await prefs.setDouble(progressKey, currentProgress);
      return;
    }

    final crossedWarning =
        previousProgress < warningThreshold &&
        currentProgress >= warningThreshold &&
        currentProgress < 100;
    final crossedExceeded = previousProgress < 100 && currentProgress >= 100;

    if (crossedExceeded) {
      _addNotification(
        NotificationItem(
          id: 'budget_${budget.id}_exceeded',
          title: 'Budget dépassé',
          body:
              '${budget.name}: ${budget.currentAmount.toStringAsFixed(0)} ${budget.currency} (limite: ${budget.targetAmount.toStringAsFixed(0)})',
          type: NotificationType.budgetExceeded,
          relatedId: budget.id,
          scheduledDate: DateTime.now(),
        ),
      );
    } else if (crossedWarning) {
      _addNotification(
        NotificationItem(
          id: 'budget_${budget.id}_warning',
          title: 'Alerte budget',
          body:
              '${budget.name}: ${currentProgress.toInt()}% utilisé (${budget.currentAmount.toStringAsFixed(0)}/${budget.targetAmount.toStringAsFixed(0)} ${budget.currency})',
          type: NotificationType.budgetWarning,
          relatedId: budget.id,
          scheduledDate: DateTime.now(),
        ),
      );
    }

    await prefs.setDouble(progressKey, currentProgress);
  }

  Future<void> checkLowBalanceAlerts(
    List<SourceModel> sources,
    List<BankModel> banks,
  ) async {
    // Vérifier si les alertes de solde faible sont activées
    if (_prefsService?.getOverdueAlertsEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final lowBalanceThreshold =
        _prefsService?.getLowBalanceThreshold() ?? 10000.0;

    for (final source in sources) {
      final stateKey = 'notification_state_low_source_${source.id}';
      final previousIsLow = prefs.getBool(stateKey);
      final isLow = source.amount <= lowBalanceThreshold;

      if (previousIsLow == null) {
        await prefs.setBool(stateKey, isLow);
        continue;
      }

      if (!previousIsLow && isLow) {
        _addNotification(
          NotificationItem(
            id: 'low_balance_source_${source.id}',
            title: 'Solde Faible',
            body:
                '${source.name}: ${source.amount.toStringAsFixed(0)} ${source.currency} (seuil: ${lowBalanceThreshold.toStringAsFixed(0)})',
            type: NotificationType.lowBalance,
            relatedId: source.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }

      if (previousIsLow && !isLow) {
        removeNotification('low_balance_source_${source.id}');
      }

      await prefs.setBool(stateKey, isLow);
    }

    for (final bank in banks) {
      final stateKey = 'notification_state_low_bank_${bank.id}';
      final previousIsLow = prefs.getBool(stateKey);
      final isLow = bank.balance <= lowBalanceThreshold;

      if (previousIsLow == null) {
        await prefs.setBool(stateKey, isLow);
        continue;
      }

      if (!previousIsLow && isLow) {
        _addNotification(
          NotificationItem(
            id: 'low_balance_bank_${bank.id}',
            title: 'Solde Bancaire Faible',
            body:
                '${bank.name}: ${bank.balance.toStringAsFixed(0)} ${bank.currency} (seuil: ${lowBalanceThreshold.toStringAsFixed(0)})',
            type: NotificationType.lowBalance,
            relatedId: bank.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }

      if (previousIsLow && !isLow) {
        removeNotification('low_balance_bank_${bank.id}');
      }

      await prefs.setBool(stateKey, isLow);
    }
  }

  Future<void> checkOverdueDebts(List<DebtModel> debts) async {
    if (_prefsService?.getOverdueAlertsEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    for (final debt in debts) {
      final stateKey = 'notification_state_debt_${debt.id}_overdue';
      final previousIsOverdue = prefs.getBool(stateKey);
      final isOverdue =
          debt.dueDate != null &&
          debt.dueDate!.isBefore(now) &&
          debt.status != DebtStatus.fullyPaid;

      if (previousIsOverdue == null) {
        await prefs.setBool(stateKey, isOverdue);
        continue;
      }

      if (!previousIsOverdue && isOverdue) {
        final daysPastDue = now.difference(debt.dueDate!).inDays;
        _addNotification(
          NotificationItem(
            id: 'debt_${debt.id}_overdue',
            title: 'Dette en retard',
            body:
                '${debt.personName}: ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} (${daysPastDue} jours de retard)',
            type: NotificationType.debtOverdue,
            relatedId: debt.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }

      if (previousIsOverdue && !isOverdue) {
        removeNotification('debt_${debt.id}_overdue');
      }

      await prefs.setBool(stateKey, isOverdue);
    }
  }

  Future<void> checkUpcomingDebts(List<DebtModel> debts) async {
    if (_prefsService?.getDebtRemindersEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    for (final debt in debts) {
      final stateKey = 'notification_state_debt_${debt.id}_due_soon';
      final previousIsDueSoon = prefs.getBool(stateKey);
      final dueDate = debt.dueDate;
      final daysUntilDue = dueDate != null
          ? dueDate.difference(now).inDays
          : -1;
      final isDueSoon =
          dueDate != null &&
          daysUntilDue >= 0 &&
          daysUntilDue <= _dueSoonDays &&
          debt.status != DebtStatus.fullyPaid;

      if (previousIsDueSoon == null) {
        await prefs.setBool(stateKey, isDueSoon);
        continue;
      }

      if (!previousIsDueSoon && isDueSoon) {
        _addNotification(
          NotificationItem(
            id: 'debt_${debt.id}_due_soon',
            title: 'Échéance proche',
            body:
                '${debt.personName}: ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} (dans ${daysUntilDue} jours)',
            type: NotificationType.debtReminder,
            relatedId: debt.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }

      if (previousIsDueSoon && !isDueSoon) {
        removeNotification('debt_${debt.id}_due_soon');
      }

      await prefs.setBool(stateKey, isDueSoon);
    }
  }

  Future<void> celebrateWealthMilestone(
    double newWealth,
    String currency,
  ) async {
    // Vérifier si les objectifs patrimoine sont activés
    if (_prefsService?.getWealthMilestonesEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final milestones = [
      50000,
      100000,
      250000,
      500000,
      1000000,
      2500000,
      5000000,
      10000000,
    ];

    // Trouver le plus grand milestone atteint
    int? achievedMilestone;
    for (final milestone in milestones.reversed) {
      if (newWealth >= milestone) {
        achievedMilestone = milestone;
        break;
      }
    }

    if (achievedMilestone == null) return;

    final previousMilestone = prefs.getInt(_wealthLastMilestoneKey);

    // Baseline initial pour éviter un pop-up historique au premier lancement.
    if (previousMilestone == null) {
      await prefs.setInt(_wealthLastMilestoneKey, achievedMilestone);
      return;
    }

    if (achievedMilestone > previousMilestone) {
      _addNotification(
        NotificationItem(
          id: 'wealth_milestone_$achievedMilestone',
          title: 'Nouveau palier atteint !',
          body:
              'Votre patrimoine total est maintenant de ${newWealth.toStringAsFixed(0)} $currency (palier ${achievedMilestone ~/ 1000}K franchi)',
          type: NotificationType.wealthMilestone,
          scheduledDate: DateTime.now(),
        ),
      );
    }

    await prefs.setInt(_wealthLastMilestoneKey, achievedMilestone);
  }

  // Supprimer cette méthode inutile qui crée des notifications aléatoires
  // Future<void> showWealthMilestone(double amount, String currency) async {

  Future<void> scheduleBankFeeAlert(BankModel bank) async {
    if (bank.bankType == BankType.free || bank.nextDeductionDate == null) {
      return;
    }

    // Vérifier si les alertes frais bancaires sont activées
    if (_prefsService?.getBankFeesEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final nextDeduction = bank.nextDeductionDate!;
    final daysDifference = nextDeduction.difference(now).inDays;

    if (daysDifference <= 1 && daysDifference >= 0) {
      final feeDayKey = DateTime(
        nextDeduction.year,
        nextDeduction.month,
        nextDeduction.day,
      ).millisecondsSinceEpoch;
      final stateKey = 'notification_state_bank_fee_${bank.id}_last_day';
      final lastNotifiedFeeDay = prefs.getInt(stateKey);
      if (lastNotifiedFeeDay == feeDayKey) {
        return;
      }

      final fee = bank.calculateInterest();
      _addNotification(
        NotificationItem(
          id: 'bank_${bank.id}_fee_$feeDayKey',
          title: 'Frais bancaires à venir',
          body:
              'Des frais de ${fee.toStringAsFixed(0)} ${bank.currency} seront prélevés de ${bank.name} dans $daysDifference jour(s)',
          type: NotificationType.bankFee,
          relatedId: bank.id,
          scheduledDate: nextDeduction,
        ),
      );

      await prefs.setInt(stateKey, feeDayKey);
    }
  }

  Future<void> showBackupReminder() async {
    // Vérifier si les rappels sauvegarde sont activés
    if (_prefsService?.getBackupRemindersEnabled() != true) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastBackup = _prefsService?.getLastBackupDate();
    final isBackupOutdated =
        lastBackup == null ||
        now.difference(lastBackup).inDays >= _backupReminderAfterDays;

    if (!isBackupOutdated) {
      removeNotification('backup_reminder_stale');
      return;
    }

    final lastReminderAtMillis = prefs.getInt(_backupLastReminderAtKey);
    if (lastReminderAtMillis != null) {
      final lastReminderAt = DateTime.fromMillisecondsSinceEpoch(
        lastReminderAtMillis,
      );
      if (now.difference(lastReminderAt) < _backupReminderCooldown) {
        return;
      }
    }

    _addNotification(
      NotificationItem(
        id: 'backup_reminder_stale',
        title: 'Sauvegarde recommandée',
        body: 'Il est temps de sauvegarder vos données',
        type: NotificationType.backupReminder,
        scheduledDate: now,
      ),
    );

    await prefs.setInt(_backupLastReminderAtKey, now.millisecondsSinceEpoch);
  }

  Future<void> scheduleSmartBehaviorReminders(
    List<TransactionModel> transactions,
  ) async {
    if (_prefsService?.getSmartRemindersEnabled() != true) {
      await cancelSmartReminders();
      return;
    }

    final now = DateTime.now();
    final activeTransactions =
        transactions
            .where(
              (transaction) =>
                  !transaction.isDeleted &&
                  transaction.status == TransactionStatus.active &&
                  !transaction.date.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final habitScheduled = await _scheduleHabitReminders(
      activeTransactions,
      now,
    );
    if (habitScheduled) {
      await _clearSmartInactivityReminders();
      return;
    }

    await _scheduleGlobalInactivityReminder(activeTransactions, now);
  }

  Future<void> cancelSmartReminders() async {
    await _clearSmartInactivityReminders();
    await _clearSmartHabitReminders();
  }

  Future<void> recordPushNotification({
    required String id,
    required String title,
    required String body,
    DateTime? receivedAt,
    bool isRead = false,
  }) async {
    await _ensureReadyForExternalMutation();
    _addNotification(
      NotificationItem(
        id: id,
        title: _stripVisibleEmoji(title),
        body: _stripVisibleEmoji(body),
        type: NotificationType.pushNotification,
        scheduledDate: receivedAt ?? DateTime.now(),
        isRead: isRead,
      ),
    );
  }

  Future<void> _scheduleGlobalInactivityReminder(
    List<TransactionModel> transactions,
    DateTime now,
  ) async {
    await _clearSmartInactivityReminders(removeCards: false);

    if (transactions.length < 3) {
      _removeNotificationCardsByPrefix('smart_global_inactivity');
      return;
    }

    final lastTransaction = transactions.last;
    final prefs = await SharedPreferences.getInstance();
    final preferredHour = _preferredNotificationHour(transactions);
    final inactiveDays = now.difference(lastTransaction.date).inDays;
    final previousSignature = prefs.getString(_smartInactivitySignatureKey);

    int selectedIndex = -1;
    final reachedIndex = _smartInactivityReminderOffsetsDays.lastIndexWhere(
      (offset) => offset <= inactiveDays,
    );
    if (reachedIndex >= 0) {
      final reachedOffset = _smartInactivityReminderOffsetsDays[reachedIndex];
      final reachedSignature =
          '${lastTransaction.date.millisecondsSinceEpoch}:$reachedOffset';
      if (reachedSignature != previousSignature) {
        selectedIndex = reachedIndex;
      }
    }

    if (selectedIndex < 0) {
      selectedIndex = _smartInactivityReminderOffsetsDays.indexWhere(
        (offset) => offset > inactiveDays,
      );
    }

    if (selectedIndex < 0) {
      _removeNotificationCardsByPrefix('smart_global_inactivity');
      return;
    }

    final offsetDays = _smartInactivityReminderOffsetsDays[selectedIndex];
    final expectedAt = lastTransaction.date.add(Duration(days: offsetDays));
    final scheduledAt = _nextReminderTime(
      expectedAt.isBefore(now) ? now.add(const Duration(hours: 3)) : expectedAt,
      preferredHour: preferredHour,
    );
    final alarmId = _smartInactivityAlarmBaseId + selectedIndex;
    final cardId = 'smart_global_inactivity_$selectedIndex';
    final result = await RealAlarmService.scheduleRealAlarm(
      id: alarmId,
      dateTime: scheduledAt,
      title: _inactivityTitle(offsetDays),
      message: _inactivityBody(offsetDays, lastTransaction),
    );

    if (result.success) {
      _removeNotificationCardsByPrefix(
        'smart_global_inactivity',
        keepId: cardId,
      );
      _addNotification(
        NotificationItem(
          id: cardId,
          title: _inactivityTitle(offsetDays),
          body: _inactivityBody(offsetDays, lastTransaction),
          type: NotificationType.smartReminder,
          scheduledDate: scheduledAt,
        ),
      );
      await prefs.setString(
        _smartInactivitySignatureKey,
        '${lastTransaction.date.millisecondsSinceEpoch}:$offsetDays',
      );
    }
  }

  Future<bool> _scheduleHabitReminders(
    List<TransactionModel> transactions,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final cutoff = now.subtract(
      const Duration(days: _smartReminderLookbackDays),
    );
    final groups = <String, _TransactionHabit>{};

    for (final transaction in transactions.where(
      (t) => t.date.isAfter(cutoff),
    )) {
      final habit = _TransactionHabit.fromTransaction(transaction);
      groups.update(
        habit.key,
        (existing) => existing..transactions.add(transaction),
        ifAbsent: () => habit..transactions.add(transaction),
      );
    }

    final habits =
        groups.values
            .where(
              (habit) => habit.transactions.length >= _smartReminderMinEvents,
            )
            .toList()
          ..sort((a, b) => _habitScore(b).compareTo(_habitScore(a)));

    _TransactionHabit? selectedHabit;
    int? selectedGapDays;
    for (final habit in habits) {
      habit.transactions.sort((a, b) => a.date.compareTo(b.date));
      final averageGapDays = _averageGapDays(habit.transactions);
      if (averageGapDays <= 0 || averageGapDays > 10) continue;
      selectedHabit = habit;
      selectedGapDays = averageGapDays.clamp(1, 10);
      break;
    }

    if (selectedHabit == null || selectedGapDays == null) {
      await _clearSmartHabitReminders(prefs: prefs);
      return false;
    }

    final lastTransaction = selectedHabit.transactions.last;
    final alarmId = 870000 + (_stablePositiveHash(selectedHabit.key) % 20000);
    final cardId = 'smart_habit_$alarmId';
    final signature =
        '${selectedHabit.key}:${lastTransaction.date.millisecondsSinceEpoch}:$selectedGapDays';
    final previousSignature = prefs.getString(_smartHabitSignatureKey);
    final previousAlarmIds = _readSmartHabitAlarmIds(prefs);

    if (previousSignature == signature && previousAlarmIds.contains(alarmId)) {
      _removeNotificationCardsByPrefix('smart_habit_', keepId: cardId);
      return true;
    }

    await _clearSmartHabitReminders(prefs: prefs);

    final expectedAt = lastTransaction.date.add(
      Duration(days: selectedGapDays),
    );
    final scheduledAt = _nextReminderTime(
      expectedAt,
      preferredHour: _preferredNotificationHour(selectedHabit.transactions),
    );
    final result = await RealAlarmService.scheduleRealAlarm(
      id: alarmId,
      dateTime: scheduledAt,
      title: selectedHabit.title,
      message: selectedHabit.body,
    );

    if (!result.success) {
      return false;
    }

    _removeNotificationCardsByPrefix('smart_habit_', keepId: cardId);
    _addNotification(
      NotificationItem(
        id: cardId,
        title: selectedHabit.title,
        body: selectedHabit.body,
        type: NotificationType.smartReminder,
        scheduledDate: scheduledAt,
      ),
    );
    await prefs.setString(_smartHabitAlarmIdsKey, jsonEncode([alarmId]));
    await prefs.setString(_smartHabitSignatureKey, signature);
    return true;
  }

  int _averageGapDays(List<TransactionModel> transactions) {
    if (transactions.length < 2) return 0;

    var totalDays = 0;
    var gapCount = 0;
    for (var i = 1; i < transactions.length; i++) {
      final gapDays = transactions[i].date
          .difference(transactions[i - 1].date)
          .inDays
          .clamp(1, 30);
      totalDays += gapDays;
      gapCount++;
    }

    return gapCount == 0 ? 0 : (totalDays / gapCount).round();
  }

  int _habitScore(_TransactionHabit habit) {
    if (habit.transactions.isEmpty) return 0;
    final sortedTransactions = [...habit.transactions]
      ..sort((a, b) => a.date.compareTo(b.date));
    final averageGapDays = _averageGapDays(sortedTransactions);
    final frequencyScore = habit.transactions.length * 10;
    final recencyScore = averageGapDays <= 0 ? 0 : (20 - averageGapDays);
    return frequencyScore + recencyScore;
  }

  int _preferredNotificationHour(List<TransactionModel> transactions) {
    final hourCounts = <int, int>{};
    final cutoff = DateTime.now().subtract(
      const Duration(days: _smartReminderLookbackDays),
    );

    for (final transaction in transactions.where(
      (t) => t.date.isAfter(cutoff),
    )) {
      final hour = transaction.date.hour.clamp(8, 20).toInt();
      hourCounts.update(hour, (count) => count + 1, ifAbsent: () => 1);
    }

    if (hourCounts.isEmpty) return 9;

    final entries = hourCounts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });

    return entries.first.key;
  }

  DateTime _nextReminderTime(DateTime candidate, {int preferredHour = 9}) {
    final now = DateTime.now();
    final hour = preferredHour.clamp(8, 20).toInt();
    final minimum = now.add(const Duration(hours: 1));
    var date = DateTime(candidate.year, candidate.month, candidate.day, hour);

    if (date.isBefore(minimum)) {
      final soon = now.add(const Duration(hours: 3));
      if (soon.hour >= 8 && soon.hour <= 20) {
        return soon;
      }

      final today = DateTime(now.year, now.month, now.day, hour);
      if (today.isAfter(minimum)) {
        return today;
      }

      final tomorrow = now.add(const Duration(days: 1));
      date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
    }

    return date;
  }

  String _inactivityTitle(int offsetDays) {
    if (offsetDays <= 3) return 'Petit contrôle Ikigabo';
    if (offsetDays <= 5) return 'Vos comptes attendent';
    if (offsetDays <= 8) return 'Bilan rapide recommandé';
    return 'Gardez votre historique vivant';
  }

  String _inactivityBody(int offsetDays, TransactionModel lastTransaction) {
    final accountName =
        lastTransaction.targetSourceName ?? lastTransaction.sourceName;
    final suffix = accountName == null ? '' : ' pour $accountName';

    if (offsetDays <= 3) {
      return 'Vous aviez l’habitude de mettre Ikigabo à jour$suffix. Un petit mouvement à vérifier ?';
    }
    if (offsetDays <= 5) {
      return 'Quelques jours sans mouvement. Gardez vos soldes fiables avec une vérification rapide.';
    }
    if (offsetDays <= 8) {
      return 'Votre historique devient moins précis si les mouvements restent dans votre tête.';
    }
    return 'Revenez faire un point: revenus, dépenses et transferts restent plus utiles quand ils sont à jour.';
  }

  Future<void> _clearSmartInactivityReminders({bool removeCards = true}) async {
    await RealAlarmService.cancelAlarm(_legacySmartGlobalInactivityAlarmId);
    if (removeCards) {
      removeNotification('smart_global_inactivity');
    }

    for (
      var index = 0;
      index < _smartInactivityReminderOffsetsDays.length;
      index++
    ) {
      await RealAlarmService.cancelAlarm(_smartInactivityAlarmBaseId + index);
      if (removeCards) {
        removeNotification('smart_global_inactivity_$index');
      }
    }
  }

  Future<void> _clearSmartHabitReminders({
    SharedPreferences? prefs,
    bool removeCards = true,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final alarmIds = _readSmartHabitAlarmIds(preferences);

    for (final alarmId in alarmIds) {
      await RealAlarmService.cancelAlarm(alarmId);
      if (removeCards) {
        removeNotification('smart_habit_$alarmId');
      }
    }

    await preferences.remove(_smartHabitAlarmIdsKey);
    await preferences.remove(_smartHabitSignatureKey);
  }

  List<int> _readSmartHabitAlarmIds(SharedPreferences prefs) {
    final rawIds = prefs.getString(_smartHabitAlarmIdsKey);
    if (rawIds == null || rawIds.isEmpty) return const [];

    try {
      final decoded = jsonDecode(rawIds) as List<dynamic>;
      return decoded.whereType<int>().toList();
    } catch (_) {
      return const [];
    }
  }

  void _removeNotificationCardsByPrefix(String prefix, {String? keepId}) {
    final obsoleteIds = _notifications
        .where(
          (notification) =>
              notification.id.startsWith(prefix) && notification.id != keepId,
        )
        .map((notification) => notification.id)
        .toList();
    for (final id in obsoleteIds) {
      removeNotification(id);
    }
  }

  int _stablePositiveHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  String _budgetPeriodKey(BudgetModel budget) {
    final start = DateTime(
      budget.startDate.year,
      budget.startDate.month,
      budget.startDate.day,
    ).millisecondsSinceEpoch;
    final end = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    ).millisecondsSinceEpoch;
    return '${budget.period.name}_${start}_$end';
  }

  String _stripVisibleEmoji(String value) {
    return value
        .replaceAll(
          RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true),
          '',
        )
        .replaceAll(RegExp(r'[\uFE0F\u200D]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  void _addNotification(NotificationItem notification) {
    // Vérifier si le type de notification est activé avant d'ajouter
    if (!_isNotificationTypeEnabled(notification.type)) {
      return;
    }

    final existingIndex = _notifications.indexWhere(
      (n) => n.id == notification.id,
    );
    final existing = existingIndex == -1 ? null : _notifications[existingIndex];
    final nextNotification = existing == null
        ? notification.copyWith(
            title: _stripVisibleEmoji(notification.title),
            body: _stripVisibleEmoji(notification.body),
          )
        : notification.copyWith(
            title: _stripVisibleEmoji(notification.title),
            body: _stripVisibleEmoji(notification.body),
            isRead: existing.isRead,
            createdAt: existing.createdAt,
          );

    if (existingIndex == -1) {
      _notifications.add(nextNotification);
    } else {
      _notifications[existingIndex] = nextNotification;
    }
    _saveNotifications();
    _updateNotificationCount();
  }

  bool _isNotificationTypeEnabled(NotificationType type) {
    if (_prefsService == null) return false;

    switch (type) {
      case NotificationType.debtReminder:
        return _prefsService!.getDebtRemindersEnabled();
      case NotificationType.debtOverdue:
        return _prefsService!.getOverdueAlertsEnabled();
      case NotificationType.bankFee:
        return _prefsService!.getBankFeesEnabled();
      case NotificationType.wealthMilestone:
        return _prefsService!.getWealthMilestonesEnabled();
      case NotificationType.backupReminder:
        return _prefsService!.getBackupRemindersEnabled();
      case NotificationType.budgetWarning:
      case NotificationType.budgetExceeded:
        return true; // Toujours activé pour les budgets
      case NotificationType.lowBalance:
        return _prefsService!.getOverdueAlertsEnabled();
      case NotificationType.smartReminder:
      case NotificationType.pushNotification:
        return _prefsService!.getSmartRemindersEnabled();
    }
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveNotifications();
    _updateNotificationCount();
  }

  Future<void> cancelDebtNotification(int debtId) async {
    await RealAlarmService.cancelAlarm(debtId);
    removeNotification('debt_${debtId}_reminder');
  }

  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    _updateNotificationCount();
  }

  void markNotificationAsRead(String id) {
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification non trouvée'),
    );
    notification.markAsRead();
    _saveNotifications();
    _updateNotificationCount();
  }

  void markAllAsRead() {
    for (final notification in _notifications) {
      notification.markAsRead();
    }
    _saveNotifications();
    _updateNotificationCount();
  }

  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  void _updateNotificationCount() {
    _notificationCount.value = unreadNotifications.length;
  }

  int getOverdueDebtsCount() {
    return _notifications
        .where((n) => n.type == NotificationType.debtOverdue && !n.isRead)
        .length;
  }

  int getDueSoonCount() {
    return _notifications
        .where((n) => n.type == NotificationType.debtReminder && !n.isRead)
        .length;
  }

  /// Affiche une notification immédiate (sans programmation)
  Future<void> showInstantNotification(String title, String body) async {
    try {
      await _flutterNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            'Rappels de Dettes',
            channelDescription: 'Notifications instantanées',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: Color(0xFF6366F1),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur notification immédiate: $e');
    }
  }

  /// Formate le temps du rappel de manière lisible
  String _formatReminderTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'dans ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'dans ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'dans ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'maintenant';
    }
  }

  /// Reprogramme toutes les alarmes existantes (à appeler au démarrage)
  Future<void> rescheduleAllDebtReminders() async {
    try {
      // Cette méthode sera appelée depuis un provider qui a accès au repository
      print('🔄 Reprogrammation des alarmes au démarrage...');
    } catch (e) {
      print('❌ Erreur reprogrammation alarmes: $e');
    }
  }

  /// Récupère toutes les notifications programmées (pour debug)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterNotifications.pendingNotificationRequests();
  }

  // Méthodes de persistance
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('notifications', jsonEncode(notificationsJson));
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsString = prefs.getString('notifications');
    if (notificationsString != null) {
      final notificationsJson = jsonDecode(notificationsString) as List;
      _notifications.clear();
      _notifications.addAll(
        notificationsJson
            .map((json) => NotificationItem.fromJson(json))
            .toList(),
      );
    }
    _notificationsLoaded = true;
  }

  Future<void> _ensureReadyForExternalMutation() async {
    _prefsService ??= await PreferencesService.init();
    if (!_notificationsLoaded) {
      await _loadNotifications();
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final int? relatedId;
  final DateTime scheduledDate;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.scheduledDate,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  void markAsRead() {
    isRead = true;
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    int? relatedId,
    DateTime? scheduledDate,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.index,
    'relatedId': relatedId,
    'scheduledDate': scheduledDate.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values[json['type']],
        relatedId: json['relatedId'],
        scheduledDate: DateTime.fromMillisecondsSinceEpoch(
          json['scheduledDate'],
        ),
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        isRead: json['isRead'] ?? false,
      );
}

enum NotificationType {
  debtReminder,
  debtOverdue,
  bankFee,
  wealthMilestone,
  backupReminder,
  budgetWarning,
  budgetExceeded,
  lowBalance,
  smartReminder,
  pushNotification,
}

class _TransactionHabit {
  final String key;
  final String title;
  final String body;
  final List<TransactionModel> transactions = [];

  _TransactionHabit({
    required this.key,
    required this.title,
    required this.body,
  });

  factory _TransactionHabit.fromTransaction(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        final targetName =
            transaction.targetSourceName ??
            transaction.sourceName ??
            'ce compte';
        final targetId = transaction.targetSourceId ?? transaction.sourceId;
        final targetType =
            transaction.targetSourceType?.name ?? transaction.sourceType.name;
        return _TransactionHabit(
          key:
              'income:$targetType:$targetId:${transaction.incomeCategory.name}',
          title: 'Entrée à suivre',
          body:
              'Vous ajoutez souvent de l’argent sur $targetName. Pensez à mettre Ikigabo à jour.',
        );
      case TransactionType.expense:
        final sourceName = transaction.sourceName ?? 'ce compte';
        return _TransactionHabit(
          key:
              'expense:${transaction.sourceType.name}:${transaction.sourceId}:${transaction.expenseCategory.name}',
          title: 'Dépense à noter',
          body:
              'Vous notez souvent des dépenses depuis $sourceName. Gardez vos comptes à jour.',
        );
      case TransactionType.transfer:
        final targetName = transaction.targetSourceName ?? 'la destination';
        return _TransactionHabit(
          key:
              'transfer:${transaction.sourceType.name}:${transaction.sourceId}:${transaction.targetSourceId ?? 0}',
          title: 'Transfert habituel',
          body:
              'Vous faites souvent des transferts vers $targetName. Un petit contrôle aujourd’hui ?',
        );
    }
  }
}

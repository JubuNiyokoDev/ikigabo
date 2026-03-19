import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/debt_model.dart';
import '../models/bank_model.dart';
import '../models/budget_model.dart';
import '../models/source_model.dart';
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
  static const Duration _backupReminderCooldown = Duration(hours: 24);

  static const String _wealthLastMilestoneKey =
      'notification_state_wealth_last_milestone';
  static const String _backupLastReminderAtKey =
      'notification_state_backup_last_reminder_at';

  final List<NotificationItem> _notifications = [];
  final ValueNotifier<int> _notificationCount = ValueNotifier(0);
  final FlutterLocalNotificationsPlugin _flutterNotifications =
      FlutterLocalNotificationsPlugin();
  PreferencesService? _prefsService;

  ValueNotifier<int> get notificationCount => _notificationCount;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize() async {
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
          title: '🎉 Nouveau Palier Atteint !',
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

  void _addNotification(NotificationItem notification) {
    // Vérifier si le type de notification est activé avant d'ajouter
    if (!_isNotificationTypeEnabled(notification.type)) {
      return;
    }

    // Remove existing notification with same ID
    _notifications.removeWhere((n) => n.id == notification.id);

    // Add new notification
    _notifications.add(notification);
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
    this.isRead = false,
  }) : createdAt = DateTime.now();

  void markAsRead() {
    isRead = true;
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
}

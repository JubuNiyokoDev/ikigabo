import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
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

    await AndroidAlarmManager.initialize();

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
    final androidChannel = AndroidNotificationChannel(
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

  Future<void> scheduleDebtReminder(DebtModel debt) async {
    if (debt.reminderDateTime == null) return;

    // Vérifier si les rappels de dettes sont activés
    if (_prefsService?.getDebtRemindersEnabled() != true) return;

    if (debt.reminderDateTime!.isBefore(DateTime.now())) {
      return;
    }

    final title = debt.type == DebtType.given
        ? 'Dette à recevoir'
        : 'Dette à payer';

    final message = debt.type == DebtType.given
        ? 'Recevoir ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} de ${debt.personName}'
        : 'Payer ${debt.remainingAmount.toStringAsFixed(0)} ${debt.currency} à ${debt.personName}';

    try {
      await RealAlarmService.scheduleRealAlarm(
        id: debt.id,
        dateTime: debt.reminderDateTime!,
        title: title,
        message: message,
      );
    } catch (e) {
      print('Erreur programmation alarme: $e');
    }

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
  }

  Future<void> scheduleBudgetAlert(BudgetModel budget) async {
    if (!budget.notificationsEnabled) return;

    final warningThreshold = budget.warningThreshold ?? 80.0;
    final currentProgress = budget.progressPercentage;

    if (currentProgress >= warningThreshold) {
      _addNotification(
        NotificationItem(
          id: 'budget_${budget.id}_warning',
          title: 'Budget Alert',
          body: '${budget.name}: ${currentProgress.toInt()}% utilisé (${budget.currentAmount}/${budget.targetAmount} ${budget.currency})',
          type: NotificationType.budgetWarning,
          relatedId: budget.id,
          scheduledDate: DateTime.now(),
        ),
      );
    }

    if (budget.isOverBudget) {
      _addNotification(
        NotificationItem(
          id: 'budget_${budget.id}_exceeded',
          title: 'Budget Dépassé !',
          body: '${budget.name}: ${budget.currentAmount} ${budget.currency} (limite: ${budget.targetAmount})',
          type: NotificationType.budgetExceeded,
          relatedId: budget.id,
          scheduledDate: DateTime.now(),
        ),
      );
    }
  }

  Future<void> checkLowBalanceAlerts(List<SourceModel> sources, List<BankModel> banks) async {
    final lowBalanceThreshold = _prefsService?.getLowBalanceThreshold() ?? 10000.0;

    for (final source in sources) {
      if (source.amount <= lowBalanceThreshold && source.amount > 0) {
        _addNotification(
          NotificationItem(
            id: 'low_balance_source_${source.id}',
            title: 'Solde Faible',
            body: '${source.name}: ${source.amount} ${source.currency}',
            type: NotificationType.lowBalance,
            relatedId: source.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }
    }

    for (final bank in banks) {
      if (bank.balance <= lowBalanceThreshold && bank.balance > 0) {
        _addNotification(
          NotificationItem(
            id: 'low_balance_bank_${bank.id}',
            title: 'Solde Bancaire Faible',
            body: '${bank.name}: ${bank.balance} ${bank.currency}',
            type: NotificationType.lowBalance,
            relatedId: bank.id,
            scheduledDate: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> celebrateWealthMilestone(double newWealth, String currency) async {
    final milestones = [50000, 100000, 250000, 500000, 1000000, 2500000, 5000000];
    
    for (final milestone in milestones) {
      if (newWealth >= milestone) {
        final key = 'milestone_$milestone';
        final alreadyCelebrated = _prefsService?.getBool(key) ?? false;
        
        if (!alreadyCelebrated) {
          _addNotification(
            NotificationItem(
              id: 'wealth_milestone_$milestone',
              title: '🎉 Félicitations !',
              body: 'Vous avez atteint ${milestone ~/ 1000}K $currency de patrimoine !',
              type: NotificationType.wealthMilestone,
              scheduledDate: DateTime.now(),
            ),
          );
          
          await _prefsService?.setBool(key, true);
          break;
        }
      }
    }
  }

  Future<void> showWealthMilestone(double amount, String currency) async {
    // Vérifier si les objectifs patrimoine sont activés
    if (_prefsService?.getWealthMilestonesEnabled() != true) return;

    _addNotification(
      NotificationItem(
        id: 'wealth_milestone_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Félicitations',
        body:
            'Votre patrimoine a atteint ${amount.toStringAsFixed(0)} $currency',
        type: NotificationType.wealthMilestone,
        scheduledDate: DateTime.now(),
      ),
    );
  }

  Future<void> scheduleBankFeeAlert(BankModel bank) async {
    if (bank.bankType == BankType.free || bank.nextDeductionDate == null)
      return;

    // Vérifier si les alertes frais bancaires sont activées
    if (_prefsService?.getBankFeesEnabled() != true) return;

    final now = DateTime.now();
    final nextDeduction = bank.nextDeductionDate!;
    final daysDifference = nextDeduction.difference(now).inDays;

    if (daysDifference <= 1 && daysDifference >= 0) {
      final fee = bank.calculateInterest();
      _addNotification(
        NotificationItem(
          id: 'bank_${bank.id}_fee',
          title: 'Frais bancaires à venir',
          body:
              'Des frais de ${fee.toStringAsFixed(0)} ${bank.currency} seront prélevés de ${bank.name} dans $daysDifference jour(s)',
          type: NotificationType.bankFee,
          relatedId: bank.id,
          scheduledDate: nextDeduction,
        ),
      );
    }
  }

  Future<void> showBackupReminder() async {
    // Vérifier si les rappels sauvegarde sont activés
    if (_prefsService?.getBackupRemindersEnabled() != true) return;

    _addNotification(
      NotificationItem(
        id: 'backup_reminder_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sauvegarde recommandée',
        body: 'Il est temps de sauvegarder vos données',
        type: NotificationType.backupReminder,
        scheduledDate: DateTime.now(),
      ),
    );
  }

  void _addNotification(NotificationItem notification) {
    // Remove existing notification with same ID
    _notifications.removeWhere((n) => n.id == notification.id);

    // Add new notification
    _notifications.add(notification);
    _saveNotifications();
    _updateNotificationCount();
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
        .where((n) => n.type == NotificationType.debtOverdue)
        .length;
  }

  int getDueSoonCount() {
    return _notifications
        .where((n) => n.type == NotificationType.debtReminder)
        .length;
  }

  /// Affiche une notification immédiate (sans programmation)
  Future<void> showInstantNotification(String title, String body) async {
    try {
      await _flutterNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            'Rappels de Dettes',
            channelDescription: 'Notifications instantanées',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            color: const Color(0xFF6366F1),
          ),
          iOS: const DarwinNotificationDetails(
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
        notificationsJson.map((json) => NotificationItem.fromJson(json)).toList(),
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

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    title: json['title'],
    body: json['body'],
    type: NotificationType.values[json['type']],
    relatedId: json['relatedId'],
    scheduledDate: DateTime.fromMillisecondsSinceEpoch(json['scheduledDate']),
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

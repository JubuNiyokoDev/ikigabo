import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/budget_model.dart';
import 'push_notification_service.dart';

class HabitSyncService {
  static const String _serverUrl = 'https://push-notification-server-k5ev.onrender.com';
  static const String _lastSyncKey = 'habit_sync_last_at';
  static const Duration _syncCooldown = Duration(hours: 6);

  // Appelé à chaque ouverture d'app (respecte le cooldown)
  static Future<void> syncOnAppOpen(Isar isar) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastSync < _syncCooldown.inMilliseconds) return;

    await _sendHeartbeat(isar);
    await prefs.setInt(_lastSyncKey, now);
  }

  // Mise à jour forcée du token FCM (appelée quand token change)
  static Future<void> updateFcmToken(String token) async {
    final deviceId = await PushNotificationService.getDeviceId();
    try {
      await http.post(
        Uri.parse('$_serverUrl/update-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId, 'fcmToken': token}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ Token update failed: $e');
    }
  }

  static Future<void> _sendHeartbeat(Isar isar) async {
    try {
      final deviceId = await PushNotificationService.getDeviceId();
      final fcmToken = await PushNotificationService.getFcmToken();
      if (fcmToken == null) return;

      final habits = await _computeHabits(isar);

      final payload = {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': 'android',
        'lastActiveAt': DateTime.now().millisecondsSinceEpoch,
        'locale': _detectLocale(),
        'habits': habits,
      };

      final response = await http.post(
        Uri.parse('$_serverUrl/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('✅ Heartbeat envoyé au serveur push');
      }
    } catch (e) {
      debugPrint('⚠️ Heartbeat failed (offline?): $e');
    }
  }

  static Future<Map<String, dynamic>> _computeHabits(Isar isar) async {
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));

    // Transactions
    final allTx = await isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    final tx7 = allTx.where((t) => t.date.isAfter(last7Days)).toList();
    final tx30 = allTx.where((t) => t.date.isAfter(last30Days)).toList();

    // Dernière transaction
    final lastTxDate = allTx.isNotEmpty
        ? allTx.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
        : null;

    // Calcul moyenne hebdomadaire (sur 30 derniers jours = 4 semaines)
    final avgPerWeek = tx30.length / 4.0;

    // Revenus et dépenses du mois
    double incomeMonth = 0, expenseMonth = 0;
    for (final t in tx30) {
      if (t.type == TransactionType.income) incomeMonth += t.amount;
      if (t.type == TransactionType.expense) expenseMonth += t.amount;
    }

    // Dettes
    final debts = await isar.debtModels
        .filter()
        .isDeletedEqualTo(false)
        .statusEqualTo(DebtStatus.pending)
        .or()
        .statusEqualTo(DebtStatus.partiallyPaid)
        .findAll();

    int debtsDueSoon = 0, debtsOverdue = 0;
    double totalDebtRemaining = 0;
    for (final d in debts) {
      final remaining = d.totalAmount - d.paidAmount;
      totalDebtRemaining += remaining;
      if (d.dueDate != null) {
        final daysLeft = d.dueDate!.difference(now).inDays;
        if (daysLeft < 0) {
          debtsOverdue++;
        } else if (daysLeft <= 7) {
          debtsDueSoon++;
        }
      }
    }

    // Budgets
    final budgets = await isar.budgetModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final activeBudgets = budgets
        .where((b) => b.status == BudgetStatus.active)
        .toList();

    int budgetsNearLimit = 0, budgetsOverspent = 0;
    for (final b in activeBudgets) {
      if (b.targetAmount <= 0) continue;
      final pct = b.currentAmount / b.targetAmount;
      if (pct >= 1.0) {
        budgetsOverspent++;
      } else if (pct >= 0.8) {
        budgetsNearLimit++;
      }
    }

    return {
      'totalTransactions': allTx.length,
      'transactionsLast7Days': tx7.length,
      'transactionsLast30Days': tx30.length,
      'avgTransactionsPerWeek': double.parse(avgPerWeek.toStringAsFixed(1)),
      'lastTransactionAt': lastTxDate?.millisecondsSinceEpoch,
      'incomeMonth': incomeMonth.round(),
      'expenseMonth': expenseMonth.round(),
      'hasDebts': debts.isNotEmpty,
      'debtsDueSoon': debtsDueSoon,
      'debtsOverdue': debtsOverdue,
      'totalDebtRemaining': totalDebtRemaining.round(),
      'hasActiveBudgets': activeBudgets.isNotEmpty,
      'budgetsNearLimit': budgetsNearLimit,
      'budgetsOverspent': budgetsOverspent,
    };
  }

  static String _detectLocale() {
    try {
      return ui.PlatformDispatcher.instance.locale.languageCode;
    } catch (_) {
      return 'fr';
    }
  }
}

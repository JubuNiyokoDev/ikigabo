import 'package:isar/isar.dart';

part 'budget_model.g.dart';

enum BudgetType {
  expense,
  income,
  saving,
}

enum BudgetPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
}

enum BudgetStatus {
  active,
  paused,
  completed,
  exceeded,
}

@collection
class BudgetModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  late String? description;

  @enumerated
  late BudgetType type;

  @enumerated
  late BudgetPeriod period;

  late double targetAmount;

  late double currentAmount;

  late String currency;

  late String? categoryId;

  late DateTime startDate;

  late DateTime endDate;

  @enumerated
  late BudgetStatus status;

  late DateTime createdAt;

  DateTime? updatedAt;

  @Index()
  late bool isDeleted;

  late bool notificationsEnabled;

  late double? warningThreshold; // Pourcentage (ex: 80.0 pour 80%)

  BudgetModel({
    this.id = Isar.autoIncrement,
    required this.name,
    this.description,
    required this.type,
    required this.period,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.currency = 'FBU',
    this.categoryId,
    required this.startDate,
    required this.endDate,
    this.status = BudgetStatus.active,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.notificationsEnabled = true,
    this.warningThreshold = 80.0,
  });

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount) * 100;
  }

  double get remainingAmount {
    return targetAmount - currentAmount;
  }

  bool get isOverBudget {
    return currentAmount > targetAmount;
  }

  bool get isNearLimit {
    if (warningThreshold == null) return false;
    return progressPercentage >= warningThreshold!;
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }
}
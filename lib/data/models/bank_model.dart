import 'package:isar/isar.dart';

part 'bank_model.g.dart';

enum BankType {
  free,
  paid,
}

enum InterestType {
  monthly,
  annual,
}

enum InterestCalculation {
  fixedAmount,
  percentage,
}

@collection
class BankModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  late double balance;

  late String currency;

  @enumerated
  late BankType bankType;

  @Enumerated(EnumType.name)
  late InterestType interestType;

  @Enumerated(EnumType.name)
  late InterestCalculation interestCalculation;

  double? interestValue;

  DateTime? nextDeductionDate;

  DateTime? lastDeductionDate;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? description;

  String? accountNumber;

  String? iconName;

  String? color;

  @Index()
  late bool isActive;

  @Index()
  late bool isDeleted;

  BankModel({
    this.id = Isar.autoIncrement,
    required this.name,
    this.balance = 0.0,
    this.currency = 'FBU',
    this.bankType = BankType.free,
    this.interestType = InterestType.monthly,
    this.interestCalculation = InterestCalculation.fixedAmount,
    this.interestValue,
    this.nextDeductionDate,
    this.lastDeductionDate,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.accountNumber,
    this.iconName,
    this.color,
    this.isActive = true,
    this.isDeleted = false,
  });

  double calculateInterest() {
    if (bankType == BankType.free || interestValue == null) {
      return 0.0;
    }

    if (interestCalculation == InterestCalculation.fixedAmount) {
      return interestValue!;
    } else {
      return balance * (interestValue! / 100);
    }
  }

  bool shouldDeductInterest() {
    if (bankType == BankType.free || nextDeductionDate == null) {
      return false;
    }

    return DateTime.now().isAfter(nextDeductionDate!);
  }

  DateTime calculateNextDeductionDate() {
    final now = DateTime.now();
    if (interestType == InterestType.monthly) {
      return DateTime(now.year, now.month + 1, now.day);
    } else {
      return DateTime(now.year + 1, now.month, now.day);
    }
  }
}

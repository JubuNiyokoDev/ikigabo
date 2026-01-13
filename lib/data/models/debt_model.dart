import 'package:isar_community/isar.dart';

part 'debt_model.g.dart';

enum DebtType {
  given,
  received,
}

enum DebtStatus {
  pending,
  partiallyPaid,
  fullyPaid,
  cancelled,
}

@collection
class DebtModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late DebtType type;

  late String personName;

  String? personContact;

  late double totalAmount;

  late double paidAmount;

  late String currency;

  late DateTime date;

  DateTime? dueDate;

  @enumerated
  late DebtStatus status;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? description;

  String? notes;

  @Index()
  late bool isDeleted;

  int? relatedTransactionId;

  List<int>? paymentTransactionIds;

  bool hasInterest;

  double? interestRate;

  String? collateral;

  late bool hasReminder;

  DateTime? reminderDateTime;

  DebtModel({
    this.id = Isar.autoIncrement,
    required this.type,
    required this.personName,
    this.personContact,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.currency = 'FBU',
    required this.date,
    this.dueDate,
    this.status = DebtStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.notes,
    this.isDeleted = false,
    this.relatedTransactionId,
    this.paymentTransactionIds,
    this.hasInterest = false,
    this.interestRate,
    this.collateral,
    this.hasReminder = false,
    this.reminderDateTime,
  });

  double get remainingAmount => totalAmount - paidAmount;

  double get paymentProgress => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  bool get isOverdue {
    if (dueDate == null || status == DebtStatus.fullyPaid) return false;
    return DateTime.now().isAfter(dueDate!) && status != DebtStatus.fullyPaid;
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  double get totalWithInterest {
    if (!hasInterest || interestRate == null) return totalAmount;
    return totalAmount + (totalAmount * (interestRate! / 100));
  }

  void addPayment(double amount) {
    paidAmount += amount;
    if (paidAmount >= totalAmount) {
      status = DebtStatus.fullyPaid;
      paidAmount = totalAmount;
    } else if (paidAmount > 0) {
      status = DebtStatus.partiallyPaid;
    }
    updatedAt = DateTime.now();
  }
}

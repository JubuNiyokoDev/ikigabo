import 'package:isar_community/isar.dart';

part 'debt_payment_model.g.dart';

@collection
class DebtPaymentModel {
  Id id = Isar.autoIncrement;

  late int debtId;
  late double amount;
  late DateTime date;
  late DateTime createdAt;
  String? notes;
  int? transactionId;

  @Index()
  late bool isDeleted;

  DebtPaymentModel({
    this.id = Isar.autoIncrement,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.notes,
    this.transactionId,
    this.isDeleted = false,
  });
}
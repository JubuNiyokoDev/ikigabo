import 'package:isar_community/isar.dart';
import '../../core/services/currency_conversion_service.dart';
import '../../core/constants/currencies.dart';

part 'transaction_model.g.dart';

enum TransactionStatus {
  active,
  cancelled,
}

enum TransactionType {
  income,
  expense,
  transfer,
}

enum SourceType {
  external,
  bank,
  source,
  asset,
  debt,
}

enum IncomeCategory {
  salary,
  sale,
  gift,
  debtReceived,
  investment,
  other,
}

enum ExpenseCategory {
  purchase,
  withdrawal,
  giftGiven,
  debtGiven,
  bankFees,
  assetPurchase,
  food,
  transport,
  utilities,
  entertainment,
  health,
  education,
  other,
}

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late TransactionType type;

  @Enumerated(EnumType.name)
  late IncomeCategory incomeCategory;

  @Enumerated(EnumType.name)
  late ExpenseCategory expenseCategory;

  late double amount;

  late String currency;

  @Index()
  late int sourceId;

  String? sourceName;

  @Enumerated(EnumType.name)
  late SourceType sourceType;

  int? targetSourceId;

  String? targetSourceName;

  @Enumerated(EnumType.name)
  SourceType? targetSourceType;

  late DateTime date;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? description;

  String? note;

  String? attachmentPath;

  @Index()
  late bool isDeleted;

  @Enumerated(EnumType.name)
  late TransactionStatus status;

  late bool isRecurring;

  String? recurringPattern;

  DateTime? recurringEndDate;

  int? relatedDebtId;

  int? relatedAssetId;

  int? relatedBankId;

  TransactionModel({
    this.id = Isar.autoIncrement,
    required this.type,
    this.incomeCategory = IncomeCategory.other,
    this.expenseCategory = ExpenseCategory.other,
    required this.amount,
    this.currency = 'BIF',
    required this.sourceId,
    this.sourceName,
    required this.sourceType,
    this.targetSourceId,
    this.targetSourceName,
    this.targetSourceType,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.note,
    this.attachmentPath,
    this.isDeleted = false,
    this.status = TransactionStatus.active,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringEndDate,
    this.relatedDebtId,
    this.relatedAssetId,
    this.relatedBankId,
  });

  String get categoryName {
    if (type == TransactionType.income) {
      return incomeCategory.name;
    } else if (type == TransactionType.expense) {
      return expenseCategory.name;
    }
    return 'other';
  }

  String get displayDescription {
    if (type == TransactionType.transfer) {
      return 'Transfert: ${sourceName ?? 'Source'} → ${targetSourceName ?? 'Destination'}';
    }
    return description ?? categoryName;
  }

  /// Convertir le montant vers une autre devise
  Future<double> convertTo(String targetCurrency) async {
    return await CurrencyConversionService.convert(
      amount: amount,
      fromCurrency: currency,
      toCurrency: targetCurrency,
    );
  }

  /// Formater le montant avec conversion automatique
  Future<String> formatAmount(String displayCurrency) async {
    final targetCurrency = AppCurrencies.findByCode(displayCurrency);
    if (targetCurrency == null) return '$currency ${amount.toStringAsFixed(0)}';
    
    return await CurrencyConversionService.formatWithConversion(
      amount: amount,
      originalCurrency: currency,
      displayCurrency: displayCurrency,
      displaySymbol: targetCurrency.symbol,
    );
  }
}

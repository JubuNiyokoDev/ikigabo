import 'package:isar/isar.dart';
import '../../core/services/currency_conversion_service.dart';
import '../../core/constants/currencies.dart';

part 'source_model.g.dart';

enum SourceType {
  pocket,
  safe,
  cash,
  custom,
}

@collection
class SourceModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  @enumerated
  late SourceType type;

  late double amount;

  @Index()
  late String currency;

  late bool isActive;

  late bool isPassive;

  late DateTime createdAt;

  DateTime? updatedAt;

  String? description;

  String? iconName;

  String? color;

  @Index()
  late bool isDeleted;

  SourceModel({
    required this.name,
    required this.type,
    this.amount = 0.0,
    this.currency = 'BIF',
    this.isActive = true,
    this.isPassive = false,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.iconName,
    this.color,
    this.isDeleted = false,
  });

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

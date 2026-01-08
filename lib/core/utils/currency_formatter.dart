import 'package:intl/intl.dart';
import '../constants/currencies.dart';

class CurrencyFormatter {
  static String formatAmount(double amount, Currency currency) {
    final formatter = NumberFormat('#,##0.###', 'fr_FR');
    return '${formatter.format(amount)}${currency.symbol}';
  }
}
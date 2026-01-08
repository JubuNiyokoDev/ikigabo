import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CurrencyConversionService {
  static const String _baseUrl = 'https://api.yadio.io';
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  static final Map<String, CachedRate> _rateCache = {};

  /// Convertir un montant d'une devise à une autre
  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    try {
      final rate = await _getExchangeRate(fromCurrency, toCurrency);
      return amount * rate;
    } catch (e) {
      // En cas d'erreur, retourner le montant original
      return amount;
    }
  }

  /// Obtenir le taux de change entre deux devises
  static Future<double> _getExchangeRate(String from, String to) async {
    final cacheKey = '${from}_$to';
    
    // Vérifier le cache
    if (_rateCache.containsKey(cacheKey)) {
      final cached = _rateCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTimeout) {
        return cached.rate;
      }
    }

    try {
      // Appel API pour obtenir le taux
      final response = await http.get(
        Uri.parse('$_baseUrl/rate/$to/$from'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rate'] as num).toDouble();
        
        // Mettre en cache
        _rateCache[cacheKey] = CachedRate(rate: rate, timestamp: DateTime.now());
        
        return rate;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: retourner 1.0 si impossible de récupérer le taux
      return 1.0;
    }
  }

  /// Formater un montant avec conversion automatique
  static Future<String> formatWithConversion({
    required double amount,
    required String originalCurrency,
    required String displayCurrency,
    required String displaySymbol,
  }) async {
    if (originalCurrency == displayCurrency) {
      return '$displaySymbol ${_formatAmount(amount)}';
    }

    try {
      final convertedAmount = await convert(
        amount: amount,
        fromCurrency: originalCurrency,
        toCurrency: displayCurrency,
      );
      
      return '$displaySymbol ${_formatAmount(convertedAmount)}';
    } catch (e) {
      // En cas d'erreur, afficher avec la devise originale
      return '$originalCurrency ${_formatAmount(amount)}';
    }
  }

  /// Formater un montant avec séparateurs
  static String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.###', 'fr_FR');
    return formatter.format(amount);
  }

  /// Vider le cache
  static void clearCache() {
    _rateCache.clear();
  }
}

class CachedRate {
  final double rate;
  final DateTime timestamp;

  CachedRate({required this.rate, required this.timestamp});
}
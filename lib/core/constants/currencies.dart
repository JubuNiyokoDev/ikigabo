import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Modèle pour une devise
class Currency {
  final String code;
  final String symbol;
  final String flag;
  final String nameKey;

  const Currency({
    required this.code,
    required this.symbol,
    required this.flag,
    required this.nameKey,
  });

  /// Obtenir le nom localisé de la devise
  String getName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return code;

    switch (nameKey) {
      case 'burundianFranc':
        return l10n.burundianFranc;
      case 'usDollar':
        return l10n.usDollar;
      case 'euro':
        return l10n.euro;
      case 'tanzanianShilling':
        return l10n.tanzanianShilling;
      case 'kenyanShilling':
        return l10n.kenyanShilling;
      case 'ugandanShilling':
        return l10n.ugandanShilling;
      case 'rwandanFranc':
        return l10n.rwandanFranc;
      case 'congoleseFranc':
        return l10n.congoleseFranc;
      default:
        return code;
    }
  }
}

/// Liste des devises supportées
class AppCurrencies {
  static const Currency bif = Currency(
    code: 'BIF',
    symbol: 'FBu',
    flag: '🇧🇮',
    nameKey: 'burundianFranc',
  );

  static const Currency usd = Currency(
    code: 'USD',
    symbol: '\$',
    flag: '🇺🇸',
    nameKey: 'usDollar',
  );

  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    flag: '🇪🇺',
    nameKey: 'euro',
  );

  static const Currency tzs = Currency(
    code: 'TZS',
    symbol: 'TSh',
    flag: '🇹🇿',
    nameKey: 'tanzanianShilling',
  );

  static const Currency kes = Currency(
    code: 'KES',
    symbol: 'KSh',
    flag: '🇰🇪',
    nameKey: 'kenyanShilling',
  );

  static const Currency ugx = Currency(
    code: 'UGX',
    symbol: 'USh',
    flag: '🇺🇬',
    nameKey: 'ugandanShilling',
  );

  static const Currency rwf = Currency(
    code: 'RWF',
    symbol: 'FRw',
    flag: '🇷🇼',
    nameKey: 'rwandanFranc',
  );

  static const Currency cdf = Currency(
    code: 'CDF',
    symbol: 'FC',
    flag: '🇨🇩',
    nameKey: 'congoleseFranc',
  );

  /// Liste de toutes les devises
  static const List<Currency> all = [
    bif,
    usd,
    eur,
    tzs,
    kes,
    ugx,
    rwf,
    cdf,
  ];

  /// Devise par défaut
  static const Currency defaultCurrency = bif;

  /// Trouver une devise par son code
  static Currency? findByCode(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Delegate pour gérer les locales non supportées par Material (Kirundi, Swahili)
/// Utilise le français comme fallback
class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Supporter toutes les locales
    return true;
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Pour Kirundi et Swahili, charger les localisations françaises
    if (locale.languageCode == 'rn' || locale.languageCode == 'sw') {
      return await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
    }
    // Pour les autres, utiliser le delegate par défaut
    return await GlobalMaterialLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Delegate pour gérer les locales non supportées par Cupertino (Kirundi, Swahili)
/// Utilise le français comme fallback
class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Supporter toutes les locales
    return true;
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // Pour Kirundi et Swahili, charger les localisations françaises
    if (locale.languageCode == 'rn' || locale.languageCode == 'sw') {
      return await GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
    }
    // Pour les autres, utiliser le delegate par défaut
    return await GlobalCupertinoLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

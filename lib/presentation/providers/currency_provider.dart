import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/currency_conversion_service.dart';
import '../../core/constants/currencies.dart';

// Provider pour le service de préférences
final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  return await PreferencesService.init();
});

// Provider pour la devise d'affichage actuelle
final displayCurrencyProvider = FutureProvider<Currency>((ref) async {
  final prefsService = await ref.watch(preferencesServiceProvider.future);
  final currencyCode = prefsService.getSavedCurrency();
  return AppCurrencies.all.firstWhere(
    (c) => c.code == currencyCode,
    orElse: () => AppCurrencies.all.first, // BIF par défaut
  );
});

// Controller pour changer la devise d'affichage
class CurrencyController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CurrencyController(this._ref) : super(const AsyncValue.data(null));

  Future<void> setDisplayCurrency(String currencyCode) async {
    state = const AsyncValue.loading();
    try {
      final prefsService = await _ref.read(preferencesServiceProvider.future);
      await prefsService.saveCurrency(currencyCode);
      
      // Invalider le provider pour forcer le refresh
      _ref.invalidate(displayCurrencyProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final currencyControllerProvider = StateNotifierProvider<CurrencyController, AsyncValue<void>>((ref) {
  return CurrencyController(ref);
});

// Helper pour convertir un montant vers la devise d'affichage
Future<double> convertToDisplayCurrency({
  required double amount,
  required String fromCurrency,
  required Currency displayCurrency,
}) async {
  return await CurrencyConversionService.convert(
    amount: amount,
    fromCurrency: fromCurrency,
    toCurrency: displayCurrency.code,
  );
}

// Helper pour formater un montant avec conversion
Future<String> formatAmountWithConversion({
  required double amount,
  required String originalCurrency,
  required Currency displayCurrency,
}) async {
  return await CurrencyConversionService.formatWithConversion(
    amount: amount,
    originalCurrency: originalCurrency,
    displayCurrency: displayCurrency.code,
    displaySymbol: displayCurrency.symbol,
  );
}
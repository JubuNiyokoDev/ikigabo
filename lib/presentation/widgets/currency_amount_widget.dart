import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import '../../core/services/currency_conversion_service.dart';
import '../../core/utils/currency_formatter.dart';

/// Widget pour afficher un montant avec conversion automatique vers la devise d'affichage
class CurrencyAmountWidget extends ConsumerWidget {
  final double amount;
  final String originalCurrency;
  final TextStyle? style;
  final bool showSymbol;
  final bool compact;

  const CurrencyAmountWidget({
    super.key,
    required this.amount,
    required this.originalCurrency,
    this.style,
    this.showSymbol = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);

    return displayCurrencyAsync.when(
      data: (displayCurrency) {
        return FutureBuilder<String>(
          future: CurrencyConversionService.formatWithConversion(
            amount: amount,
            originalCurrency: originalCurrency,
            displayCurrency: displayCurrency.code,
            displaySymbol: showSymbol ? displayCurrency.symbol : '',
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!,
                style: style ?? Theme.of(context).textTheme.bodyMedium,
              );
            }
            
            // Fallback pendant le chargement
            final fallbackText = showSymbol 
                ? CurrencyFormatter.formatAmount(amount, displayCurrency)
                : _formatAmount(amount);
            
            return Text(
              fallbackText,
              style: style ?? Theme.of(context).textTheme.bodyMedium,
            );
          },
        );
      },
      loading: () => Text(
        showSymbol ? 'BIF ${_formatAmount(amount)}' : _formatAmount(amount),
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      error: (_, __) => Text(
        '$originalCurrency ${_formatAmount(amount)}',
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.###', 'fr_FR');
    return formatter.format(amount);
  }
}

/// Widget pour afficher un montant simple avec la devise d'affichage actuelle
class DisplayCurrencyAmountWidget extends ConsumerWidget {
  final double amount;
  final TextStyle? style;
  final bool showSymbol;
  final bool compact;

  const DisplayCurrencyAmountWidget({
    super.key,
    required this.amount,
    this.style,
    this.showSymbol = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrencyAsync = ref.watch(displayCurrencyProvider);

    return displayCurrencyAsync.when(
      data: (displayCurrency) {
        final text = showSymbol 
            ? CurrencyFormatter.formatAmount(amount, displayCurrency)
            : _formatAmount(amount);
        
        return Text(
          text,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        );
      },
      loading: () => Text(
        showSymbol ? 'BIF ${_formatAmount(amount)}' : _formatAmount(amount),
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      error: (_, __) => Text(
        showSymbol ? 'BIF ${_formatAmount(amount)}' : _formatAmount(amount),
        style: style ?? Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.###', 'fr_FR');
    return formatter.format(amount);
  }
}
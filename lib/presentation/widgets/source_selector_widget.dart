import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../data/models/transaction_model.dart' as tx;
import '../../data/models/source_model.dart' as src;
import '../providers/bank_provider.dart';
import '../providers/source_provider.dart';
import '../widgets/currency_amount_widget.dart';
import 'shimmer_widget.dart';

class MoneySource {
  final int id;
  final String name;
  final double amount;
  final tx.SourceType type;
  final String currency;
  final IconData icon;
  final bool isBankSource; // Nouveau champ pour identifier les sources banques
  final int?
  originalBankId; // ID original de la banque si c'est une source banque

  MoneySource({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.currency,
    required this.icon,
    this.isBankSource = false,
    this.originalBankId,
  });
}

class SourceSelectorWidget extends ConsumerWidget {
  final Function(MoneySource) onSourceSelected;
  final double? requiredAmount;
  final bool showExternalOption;

  const SourceSelectorWidget({
    super.key,
    required this.onSourceSelected,
    this.requiredAmount,
    this.showExternalOption = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banksAsync = ref.watch(banksStreamProvider);
    final sourcesAsync = ref.watch(sourcesStreamProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisir la source d\'argent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Option argent externe
          if (showExternalOption)
            _buildSourceItem(
              MoneySource(
                id: 0,
                name: 'Argent externe',
                amount: 0,
                type: tx.SourceType.external,
                currency: 'BIF',
                icon: AppIcons.money,
              ),
              context,
            ),

          // Banques
          banksAsync.when(
            data: (banks) => Column(
              children: banks
                  .map(
                    (bank) => _buildSourceItem(
                      MoneySource(
                        id: -bank
                            .id, // Utiliser l'ID négatif pour éviter les conflits
                        name: bank.name,
                        amount: bank.balance,
                        type: tx.SourceType.bank,
                        currency: bank.currency,
                        icon: AppIcons.bank,
                        isBankSource: true,
                        originalBankId: bank.id,
                      ),
                      context,
                    ),
                  )
                  .toList(),
            ),
            loading: () => const ShimmerWidget(width: 80, height: 16),
            error: (e, s) => const SizedBox(),
          ),

          // Sources
          sourcesAsync.when(
            data: (sources) => Column(
              children: sources
                  .where((s) => s.isActive)
                  .map(
                    (source) => _buildSourceItem(
                      MoneySource(
                        id: source.id,
                        name: source.name,
                        amount: source.amount,
                        type: tx.SourceType.source,
                        currency: source.currency,
                        icon: _getSourceIcon(source.type),
                      ),
                      context,
                    ),
                  )
                  .toList(),
            ),
            loading: () => const ShimmerWidget(width: 80, height: 16),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(MoneySource source, BuildContext context) {
    final isExternal = source.type == tx.SourceType.external;
    final hasEnoughMoney =
        isExternal ||
        requiredAmount == null ||
        source.amount >= requiredAmount!;

    return GestureDetector(
      onTap: hasEnoughMoney ? () => onSourceSelected(source) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasEnoughMoney
              ? AppColors.backgroundDark
              : AppColors.backgroundDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasEnoughMoney
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(source.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasEnoughMoney
                          ? AppColors.textDark
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                  if (!isExternal) ...[
                    const SizedBox(height: 2),
                    CurrencyAmountWidget(
                      amount: source.amount,
                      originalCurrency: source.currency,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasEnoughMoney
                            ? AppColors.textSecondaryDark
                            : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!hasEnoughMoney)
              const Icon(Icons.warning, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getSourceIcon(src.SourceType type) {
    switch (type) {
      case src.SourceType.pocket:
        return AppIcons.pocket;
      case src.SourceType.safe:
        return AppIcons.safe;
      case src.SourceType.cash:
        return AppIcons.money;
      case src.SourceType.custom:
        return AppIcons.custom;
    }
  }
}

// Fonction helper pour afficher le sélecteur
Future<MoneySource?> showSourceSelector(
  BuildContext context, {
  double? requiredAmount,
  bool showExternalOption = true,
}) async {
  return await showModalBottomSheet<MoneySource>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SourceSelectorWidget(
      onSourceSelected: (source) => Navigator.pop(context, source),
      requiredAmount: requiredAmount,
      showExternalOption: showExternalOption,
    ),
  );
}
